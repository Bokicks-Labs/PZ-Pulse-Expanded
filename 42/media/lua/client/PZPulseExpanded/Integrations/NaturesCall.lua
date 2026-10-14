-- Optional compatibility adapter for Nature's Call 1.0.15.
--
-- This module deliberately reads existing player state directly. Calling
-- NaturesCall.State.ensurePlayerData() or getDetailedSnapshot() here would
-- initialize/mutate source-mod state during a read-only PZ Pulse export.

local Adapter = {}
local StatUtils = require("PZPulseExpanded/Core/StatUtils")
local Sources = require("PZPulseExpanded/Core/Sources")

Adapter.MOD_ID = Sources.naturesCall.id
Adapter.SOURCE_NAME = Sources.naturesCall.name
Adapter.MIN_FILL = 0
Adapter.MAX_FILL = 120
local syncedPlayers = setmetatable({}, { __mode = "k" })

local function isPureMultiplayerClient()
    if isClient == nil or isServer == nil then return false end
    return isClient() and not isServer()
end

local function collectValues(player, state, snapshot, active, problem)
    local source = snapshot or state or {}
    local traits = source.traitModifiers or (state and state.traitModifiers) or {}
    if type(traits) ~= "table" then traits = {} end
    local values = {}
    local health = {}
    for _, definition in ipairs({
        { output = "bladder", field = "bladderFill", trait = "majorBladderIncontinence" },
        { output = "bowel", field = "bowelFill", trait = "majorBowelIncontinence" },
    }) do
        local raw = source[definition.field]
        local number = StatUtils.finiteNumber(raw)
        local hidden = traits[definition.trait] == true
            or (number ~= nil and number < Adapter.MIN_FILL)
        local invalid = raw ~= nil and (number == nil or number > Adapter.MAX_FILL)
        if invalid then number = nil end
        local value, status = StatUtils.sample(
            player, "natures_call:" .. definition.output,
            not hidden and number or nil, active, hidden,
            problem == true or invalid
        )
        health[definition.output == "bladder" and "natures_call_bladder"
            or "natures_call_bowel"] = status
        if value ~= nil then
            values[definition.output] = value
        elseif status == "waiting" then
            values[definition.output] = 0
        end
    end
    return values, health
end

-- Return source values plus per-bar health. Missing initial state is a
-- zero placeholder; a numeric zero from the source is reported as real data.
function Adapter.collect(player)
    if not Sources.isActive(Sources.naturesCall) then
        if player ~= nil then
            syncedPlayers[player] = nil
            collectValues(player, nil, nil, false)
        end
        return nil, { natures_call_bladder = "unavailable",
            natures_call_bowel = "unavailable" }
    end
    if player == nil then return nil, {
        natures_call_bladder = "problem", natures_call_bowel = "problem" }
    end
    if player.getModData == nil then return Adapter.missing(player, true) end

    local ok, playerModData = pcall(player.getModData, player)
    local dataProblem = not ok or type(playerModData) ~= "table"
    if not ok then playerModData = nil end
    if type(playerModData) ~= "table" then playerModData = {} end

    local state = playerModData.NaturesCall
    if type(state) ~= "table" then state = nil end

    local snapshot = nil
    if isPureMultiplayerClient() then
        -- Nature's Call initializes zero defaults before the first server
        -- snapshot. After that first authoritative view, its own UI falls back
        -- to local fills during snapshot gaps; do the same without mutating it.
        snapshot = state and type(state.ownerSnapshot) == "table"
            and state.ownerSnapshot or nil
        if snapshot ~= nil then syncedPlayers[player] = true end
        if not syncedPlayers[player] then
            return collectValues(player, nil, nil, true, dataProblem)
        end
    end
    return collectValues(player, state, snapshot, true, dataProblem)
end

function Adapter.missing(player, problem)
    local active = Sources.isActive(Sources.naturesCall)
    if not active and player ~= nil then syncedPlayers[player] = nil end
    return collectValues(player, nil, nil, active, problem)
end

local Moodles = require("PZPulseExpanded/Moodles/Utils")
local normalizeLevel, humanize, translated, addMoodle =
    Moodles.normalizeLevel, Moodles.humanize, Moodles.translated, Moodles.addMoodle

local NATURES_CALL_MOODLES = {
    { name = "NCUnknownPants", key = "unknownPants", valence = "bad", maxLevel = 1 },
    { name = "NCBladder", key = "bladder", valence = "bad", maxLevel = 3 },
    { name = "NCBowel", key = "bowel", valence = "bad", maxLevel = 3 },
    { name = "NCSoilage", key = "soilage", valence = "bad", maxLevel = 3 },
    { name = "NCSmell", key = "nearbySmell", valence = "bad", maxLevel = 3 },
    { name = "NCGut", key = "gut", signed = true, maxLevel = 3 },
    { name = "NCCramps", key = "cramps", valence = "bad", maxLevel = 3 },
    { name = "NCHeartburn", key = "heartburn", valence = "bad", maxLevel = 3 },
}

function Adapter.collectMoodles(player, result, seen)
    if not Sources.isActive(Sources.naturesCall) then return end

    local modData = player:getModData()
    local state = type(modData) == "table" and modData.NaturesCall or nil
    if type(state) ~= "table" then return end

    local snapshot = state
    if isPureMultiplayerClient() then
        if type(state.ownerSnapshot) ~= "table" then return end
        snapshot = state.ownerSnapshot
    end

    local states = snapshot.moodles
    if type(states) ~= "table" then return end

    local traits = snapshot.traitModifiers or state.traitModifiers or {}

    for _, definition in ipairs(NATURES_CALL_MOODLES) do
        local rawLevel = tonumber(states[definition.key])
        local hidden = (definition.name == "NCBladder"
                and traits.majorBladderIncontinence == true)
            or (definition.name == "NCBowel"
                and traits.majorBowelIncontinence == true)

        if rawLevel ~= nil and not hidden then
            local valence = definition.valence
            if definition.signed then
                valence = rawLevel > 0 and "good"
                    or rawLevel < 0 and "bad"
                    or nil
            end

            local level = normalizeLevel(rawLevel, definition.maxLevel)
            if level ~= nil and valence ~= nil then
                local alignment = valence == "good" and "Good" or "Bad"
                local titleKey = "Moodles_" .. definition.name .. "_"
                    .. alignment .. "_lvl" .. tostring(level)
                local descKey = "Moodles_" .. definition.name .. "_"
                    .. alignment .. "_desc_lvl" .. tostring(level)

                addMoodle(result, seen, {
                    id = Sources.naturesCall.id .. ":" .. definition.name,
                    label = translated(titleKey, humanize(definition.name)),
                    description = translated(descKey, nil),
                    level = level,
                    maxLevel = definition.maxLevel,
                    valence = valence,
                    iconKey = definition.name == "NCSmell"
                        and "mood_noxioussmell"
                        or definition.name == "NCGut"
                            and (valence == "good"
                                and "natures-call/NCGutGood"
                                or "natures-call/NCGutBad")
                            or "natures-call/" .. definition.name,
                    source = Sources.naturesCall,
                })
            end
        end
    end
end

return Adapter

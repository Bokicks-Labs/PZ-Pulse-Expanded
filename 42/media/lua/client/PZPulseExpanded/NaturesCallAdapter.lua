-- Optional compatibility adapter for Nature's Call 1.0.15.
--
-- This module deliberately reads existing player state directly. Calling
-- NaturesCall.State.ensurePlayerData() or getDetailedSnapshot() here would
-- initialize/mutate source-mod state during a read-only PZ Pulse export.

PZPulseExpanded_NaturesCallAdapter = PZPulseExpanded_NaturesCallAdapter or {}

local Adapter = PZPulseExpanded_NaturesCallAdapter
local StatUtils = require("PZPulseExpanded/StatUtils")
local Sources = require("PZPulseExpanded/ModSources")

Adapter.MOD_ID = Sources.naturesCall.id
Adapter.SOURCE_NAME = Sources.naturesCall.name
Adapter.MIN_FILL = 0
Adapter.MAX_FILL = 120
local syncedPlayers = setmetatable({}, { __mode = "k" })

local function isActive()
    return Sources.isActive(Sources.naturesCall)
end

local function isPureMultiplayerClient()
    if isClient == nil or isServer == nil then return false end
    return isClient() and not isServer()
end

local function collectValues(player, state, snapshot, active)
    local source = snapshot or state or {}
    local traits = source.traitModifiers or (state and state.traitModifiers) or {}
    if type(traits) ~= "table" then traits = {} end
    local values = {}
    for _, definition in ipairs({
        { output = "bladder", field = "bladderFill", trait = "majorBladderIncontinence" },
        { output = "bowel", field = "bowelFill", trait = "majorBowelIncontinence" },
    }) do
        local raw = source[definition.field]
        local number = StatUtils.finiteNumber(raw)
        local hidden = traits[definition.trait] == true
            or (number ~= nil and number < Adapter.MIN_FILL)
        local value = StatUtils.sample(
            player, "natures_call:" .. definition.output,
            not hidden and number or nil, active, hidden
        )
        if value ~= nil then values[definition.output] = value end
    end
    if values.bladder == nil and values.bowel == nil then return nil end
    return values
end

-- Return raw source values, or nil when the mod/state is absent or has not
-- initialized yet. A numeric zero is valid and must remain distinguishable
-- from a missing field.
function Adapter.collect(player)
    if not isActive() then
        if player ~= nil then
            syncedPlayers[player] = nil
            collectValues(player, nil, nil, false)
        end
        return nil
    end
    if player == nil then return nil end
    if player.getModData == nil then return Adapter.missing(player) end

    local ok, playerModData = pcall(player.getModData, player)
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
            return collectValues(player, nil, nil, false)
        end
    end
    return collectValues(player, state, snapshot, true)
end

function Adapter.missing(player)
    local active = isActive()
    if not active and player ~= nil then syncedPlayers[player] = nil end
    return collectValues(player, nil, nil, active)
end

return Adapter

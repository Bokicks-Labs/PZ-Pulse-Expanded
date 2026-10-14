-- Compose the Needs Expanded panel from core and optional source readers.
local Panel = {}
local NaturesCallAdapter = require("PZPulseExpanded/Integrations/NaturesCall")
local BodilyFunctionsAdapter = require("PZPulseExpanded/Integrations/BodilyFunctions")
local OptionalModStatsAdapter = require("PZPulseExpanded/Panels/OptionalStats")
local CustomMoodleAdapter = require("PZPulseExpanded/Moodles/Collector")
local StatUtils = require("PZPulseExpanded/Core/StatUtils")
local SourceAvailability = require("PZPulseExpanded/Panels/SourceAvailability")

-- Keep catches narrow. Kahlua may still print caught errors to console.txt, so
-- callers should test for missing enums/getters before relying on pcall.
local function safe(fn, default)
    local ok, v = pcall(fn)
    if ok and v ~= nil then return v end
    return default
end

-- Read a CharacterStat by enum name without assuming that every game version
-- or modded environment exposes the same enum set.
local function stat(stats, name, minimum, maximum)
    if CharacterStat == nil or CharacterStat[name] == nil or stats == nil then
        return nil, true
    end
    local ok, value = pcall(function() return stats:get(CharacterStat[name]) end)
    local number = StatUtils.finiteNumber(value)
    if not ok or number == nil or number < minimum or number > maximum then
        return nil, true
    end
    return number, false
end

-- PZ Pulse exports the active vanilla moodles without their localized
-- per-level descriptions. Read those descriptions from the game's own text
-- keys; the browser pairs them with PZ Pulse's existing moodle payload.
local VANILLA_MOODLE_TEXT = {
    { "HUNGRY", "status_hunger", "Hungry" },
    { "THIRST", "status_thirst", "Thirst" },
    { "TIRED", "mood_sleepy", "Tired" },
    { "ENDURANCE", "status_difficultybreathing", "Endurance" },
    { "BORED", "mood_bored", "Bored" },
    { "UNHAPPY", "mood_sad", "Unhappy" },
    { "STRESS", "mood_stressed", "Stress" },
    { "PANIC", "mood_panicked", "Panic" },
    { "ANGRY", "mood_angry", "Angry" },
    { "PAIN", "mood_pained", "Pain" },
    { "SICK", "mood_nauseous", "Sick" },
    { "HAS_A_COLD", "mood_ill", "HasACold" },
    { "INJURED", "status_injuredmajor", "Injured" },
    { "BLEEDING", "status_bleeding", "Bleeding" },
    { "WET", "status_wet", "Wet" },
    { "HEAVY_LOAD", "status_heavyload", "HeavyLoad" },
    { "CANT_SPRINT", "status_movementrestricted", "CantSprint" },
    { "UNCOMFORTABLE", "mood_discomfort", "Uncomfortable" },
    { "NOXIOUS_SMELL", "mood_noxioussmell", "NoxiousSmell" },
    { "DRUNK", "mood_drunk", "Drunk" },
    { "HYPERTHERMIA", "status_temperaturehot", "Hyperthermia" },
    { "HYPOTHERMIA", "status_temperaturelow", "Hypothermia" },
    { "WINDCHILL", "status_windchill", "Windchill" },
    { "FOOD_EATEN", "status_hunger", "FoodEaten", "good" },
}

local function collectVanillaMoodleDescriptions(player)
    if MoodleType == nil or getText == nil then return nil end
    local moodles = safe(function() return player:getMoodles() end)
    if moodles == nil then return nil end
    local result = {}
    local found = false
    for _, definition in ipairs(VANILLA_MOODLE_TEXT) do
        local enum = MoodleType[definition[1]]
        if enum ~= nil then
            local level = safe(function() return moodles:getMoodleLevel(enum) end, 0)
            if type(level) == "number" and level >= 1 then
                local key = "Moodles_" .. definition[3] .. "_desc_lvl" .. tostring(level)
                local description = safe(function() return getText(key) end)
                if type(description) == "string" and description ~= ""
                    and description ~= key then
                    result[definition[2] .. ":" .. (definition[4] or "bad")]
                        = description
                    found = true
                end
            end
        end
    end
    return found and result or nil
end

-- Retry unexpected adapter errors; the stat-specific history owns brief gaps.
local barHealthProblemsLogged = {}

local function recordBarHealthProblems(health)
    if type(health) ~= "table" then return end
    for id, status in pairs(health) do
        if status == "problem" and not barHealthProblemsLogged[id] then
            barHealthProblemsLogged[id] = true
            print("[PZ_Pulse_Expanded] Stat bar " .. tostring(id)
                .. " has no valid reading; check source compatibility and console errors.")
        end
    end
end

local collectionFailures = {}

local function logCollectionFailure(label, reason, action)
    if collectionFailures[label] then return end
    collectionFailures[label] = true
    local message = tostring(reason or "unknown error")
    if #message > 240 then message = message:sub(1, 240) .. "..." end
    print("[PZ_Pulse_Expanded] " .. label .. " collection " .. action .. ": " .. message)
end

local function collectStatAdapter(adapter, player, label, healthOnFailure)
    local ok, values, health = pcall(adapter.collect, player)
    if ok then return values, health end

    logCollectionFailure(label, values, "failed")
    local fallbackOk, fallback, fallbackHealth = pcall(adapter.missing, player, true)
    return fallbackOk and fallback or nil,
        fallbackOk and fallbackHealth or healthOnFailure
end

local function addStatAdapter(values, barHealth, key, adapter, player, label,
        healthOnFailure)
    local reading, health = collectStatAdapter(adapter, player, label,
        healthOnFailure)
    if type(health) == "table" then
        for id, status in pairs(health) do barHealth[id] = status end
    end
    if reading ~= nil then values[key] = reading end
end

local function collectOptional(adapter, player, label)
    if collectionFailures[label] then return nil end
    if adapter == nil or adapter.collect == nil then return nil end

    local ok, values = pcall(adapter.collect, player)
    if ok then return values end

    logCollectionFailure(label, values, "skipped")
    return nil
end

-- Expose values PZ Pulse does not already collect. The browser adapter reads
-- the existing d.needs core payload for the 12 vanilla Needs+ rows, avoiding
-- duplicate engine collection and preserving PZ Pulse's sickness semantics.
--
-- Always use the player supplied by PZ Pulse. Calling getPlayer() here can
-- select a different local survivor in splitscreen/multiplayer scenarios.
function Panel.collect(player)
    if player == nil then return nil end

    local stats = safe(function() return player:getStats() end)
    local values = {}
    local barHealth = {}
    values.vanilla_moodle_descriptions = collectVanillaMoodleDescriptions(player)

    local discomfortRaw, discomfortProblem = stat(stats, "DISCOMFORT", 0, 100)
    local discomfort, discomfortStatus = StatUtils.sample(player, "discomfort",
        discomfortRaw, true, false, discomfortProblem)
    barHealth.discomfort = discomfortStatus
    if discomfort ~= nil then
        values.discomfort = discomfort
    elseif discomfortStatus == "waiting" then
        values.discomfort = 0
    end

    local vanilla = {}
    for _, definition in ipairs({
        { "NICOTINE_WITHDRAWAL", "nicotine_withdrawal", 0, 1 },
        { "IDLENESS", "idleness", 0, 1 },
        { "POISON", "poison", 0, 100 },
    }) do
        local key = definition[2]
        local raw, problem = stat(stats, definition[1], definition[3], definition[4])
        local value, status = StatUtils.sample(player, key, raw, true, false, problem)
        barHealth[key] = status
        if value ~= nil then
            vanilla[key] = value
        elseif status == "waiting" then
            vanilla[key] = 0
        end
    end
    if vanilla.nicotine_withdrawal ~= nil
        or vanilla.idleness ~= nil or vanilla.poison ~= nil then
        values.vanilla_stats = vanilla
    end

    -- Availability is independent of a first valid stat reading. The browser
    -- uses it to disable choices for mods absent from this game's mod list.
    values.active_mods = SourceAvailability.collect()

    addStatAdapter(values, barHealth, "natures_call", NaturesCallAdapter,
        player, "Nature's Call",
        { natures_call_bladder = "problem", natures_call_bowel = "problem" })
    addStatAdapter(values, barHealth, "bodily_functions",
        BodilyFunctionsAdapter, player, "Bodily Functions",
        { bodily_functions_bladder = "problem", bodily_functions_bowel = "problem" })
    addStatAdapter(values, barHealth, "optional_mod_stats",
        OptionalModStatsAdapter, player, "optional mod stats")

    recordBarHealthProblems(barHealth)
    values.bar_health = barHealth

    local customMoodles = collectOptional(
        CustomMoodleAdapter,
        player,
        "custom moodles"
    )
    if customMoodles ~= nil then
        values.custom_moodles = customMoodles
    end

    return values
end

return Panel

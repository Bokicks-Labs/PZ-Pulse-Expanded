-- PZ Pulse exposes this shared registry as its stable extension entry point.
-- The append pattern is intentionally load-order independent: either mod may
-- create the table first.
PZ_Pulse_EXT = PZ_Pulse_EXT or {}

require("PZPulseExpanded/ModSources")
require("PZPulseExpanded/NaturesCallAdapter")
require("PZPulseExpanded/OptionalModStatsAdapter")
require("PZPulseExpanded/CustomMoodleAdapter")
require("PZPulseExpanded/StatUtils")

local NaturesCallAdapter = PZPulseExpanded_NaturesCallAdapter
local OptionalModStatsAdapter = PZPulseExpanded_OptionalModStatsAdapter
local CustomMoodleAdapter = PZPulseExpanded_CustomMoodleAdapter
local StatUtils = PZPulseExpanded_StatUtils
local ModSources = PZPulseExpanded_ModSources

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
local natureCallErrorLogged = false
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

local function collectNaturesCall(player)
    if NaturesCallAdapter == nil then return nil, {
        natures_call_bladder = "problem", natures_call_bowel = "problem" }
    end

    local ok, values, health = pcall(NaturesCallAdapter.collect, player)
    if ok then return values, health end

    if not natureCallErrorLogged then
        local reason = tostring(values or "unknown error")
        if #reason > 240 then reason = reason:sub(1, 240) .. "..." end
        print("[PZ_Pulse_Expanded] Nature's Call collection failed: " .. reason)
        natureCallErrorLogged = true
    end
    local fallbackOk, fallback, fallbackHealth = pcall(NaturesCallAdapter.missing, player, true)
    return fallbackOk and fallback or nil,
        fallbackOk and fallbackHealth or {
            natures_call_bladder = "problem", natures_call_bowel = "problem" }
end

local optionalAdapterFailures = {}

local function collectContinuousOptional(player)
    local label = "optional mod stats"
    local ok, values, health = pcall(OptionalModStatsAdapter.collect, player)
    if ok then return values, health end

    if not optionalAdapterFailures[label] then
        optionalAdapterFailures[label] = true
        local reason = tostring(values or "unknown error")
        if #reason > 240 then reason = reason:sub(1, 240) .. "..." end
        print("[PZ_Pulse_Expanded] " .. label .. " collection skipped: " .. reason)
    end
    local fallbackOk, fallback, fallbackHealth = pcall(OptionalModStatsAdapter.missing, player, true)
    return fallbackOk and fallback or nil,
        fallbackOk and fallbackHealth or nil
end

local function collectOptional(adapter, player, label)
    if optionalAdapterFailures[label] then return nil end
    if adapter == nil or adapter.collect == nil then return nil end

    local ok, values = pcall(adapter.collect, player)
    if ok then return values end

    optionalAdapterFailures[label] = true
    local reason = tostring(values or "unknown error")
    if #reason > 240 then reason = reason:sub(1, 240) .. "..." end
    print("[PZ_Pulse_Expanded] " .. label .. " collection skipped: " .. reason)
    return nil
end

-- Expose values PZ Pulse does not already collect. The browser adapter reads
-- the existing d.needs core payload for the 12 vanilla Needs+ rows, avoiding
-- duplicate engine collection and preserving PZ Pulse's sickness semantics.
--
-- Always use the player supplied by PZ Pulse. Calling getPlayer() here can
-- select a different local survivor in splitscreen/multiplayer scenarios.
local function needsExpandedCollector(player)
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
    values.active_mods = ModSources.barAvailability()

    local naturesCall, naturesHealth = collectNaturesCall(player)
    if type(naturesHealth) == "table" then
        for id, status in pairs(naturesHealth) do barHealth[id] = status end
    end
    if naturesCall ~= nil then
        values.natures_call = naturesCall
    end

    local optionalModStats, optionalHealth = collectContinuousOptional(player)
    if type(optionalHealth) == "table" then
        for id, status in pairs(optionalHealth) do barHealth[id] = status end
    end
    if optionalModStats ~= nil then
        values.optional_mod_stats = optionalModStats
    end

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

-- Register the Needs Expanded collector and browser renderer with PZ Pulse.
table.insert(PZ_Pulse_EXT, {
    api = 1,
    mod = "PZ_Pulse_Expanded",
    version = "1.4.0",
    id = "needs_expanded",
    title = "Needs Expanded",
    cls = "info",
    collect = needsExpandedCollector,
    js = "media/web/expanded-needs.js",
    css = "media/web/expanded-needs.css",
    render = "renderNeedsExpanded",
    options = {
        { name = "moodle_icon_scale", type = "number", label = "Moodle icon size (scale)", min = 1, max = 6, step = 0.5, default = 4 },
        { name = "bar_icon_scale", type = "number", label = "Bar icon size (scale)", min = 1, max = 4, step = 0.25, default = 2 },
        { name = "auto_hide_zero", type = "bool", label = "Auto-hide idle bars", default = false },
        { name = "zero_hide_delay", type = "number", label = "Hide delay (seconds)", min = 0, max = 300, step = 5, default = 10 },
        { name = "flash_increases", type = "bool", label = "Flash on reveal (auto-hide)", default = true },
        { name = "flash_seconds", type = "number", label = "Reveal flash (seconds)", min = 0, max = 10, step = 1, default = 7 }
    }
})

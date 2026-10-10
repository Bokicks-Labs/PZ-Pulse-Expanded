-- PZ Pulse exposes this shared registry as its stable extension entry point.
-- The append pattern is intentionally load-order independent: either mod may
-- create the table first.
PZ_Pulse_EXT = PZ_Pulse_EXT or {}

require("PZPulseExpanded/NaturesCallAdapter")
require("PZPulseExpanded/OptionalModStatsAdapter")
require("PZPulseExpanded/CustomMoodleAdapter")
require("PZPulseExpanded/StatUtils")

local NaturesCallAdapter = PZPulseExpanded_NaturesCallAdapter
local OptionalModStatsAdapter = PZPulseExpanded_OptionalModStatsAdapter
local CustomMoodleAdapter = PZPulseExpanded_CustomMoodleAdapter
local StatUtils = PZPulseExpanded_StatUtils

-- Helper shape adapted from PZ Pulse's reference extension.
-- Round collected floats so insignificant engine jitter does not defeat
-- PZ Pulse's serialized-payload change gate and cause unnecessary disk writes.
local function round2(number)
    number = tonumber(number)
    if number == nil or number ~= number or number == math.huge or number == -math.huge then
        return nil
    end
    return math.floor(number * 100 + 0.5) / 100
end

-- Keep catches narrow. Kahlua may still print caught errors to console.txt, so
-- callers should test for missing enums/getters before relying on pcall.
local function safe(fn, default)
    local ok, v = pcall(fn)
    if ok and v ~= nil then return v end
    return default
end

-- Read a CharacterStat by enum name without assuming that every game version
-- or modded environment exposes the same enum set.
local function stat(stats, name, default)
    local e = CharacterStat[name]
    if e == nil or stats == nil then return default end
    return safe(function() return stats:get(e) end, default)
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

local function collectNaturesCall(player)
    if NaturesCallAdapter == nil then return nil end

    local ok, values = pcall(NaturesCallAdapter.collect, player)
    if ok then return values end

    if not natureCallErrorLogged then
        local reason = tostring(values or "unknown error")
        if #reason > 240 then reason = reason:sub(1, 240) .. "..." end
        print("[PZ_Pulse_Expanded] Nature's Call collection failed: " .. reason)
        natureCallErrorLogged = true
    end
    local fallbackOk, fallback = pcall(NaturesCallAdapter.missing, player)
    return fallbackOk and fallback or nil
end

local optionalAdapterFailures = {}

local function collectContinuousOptional(player)
    local label = "optional mod stats"
    local ok, values = pcall(OptionalModStatsAdapter.collect, player)
    if ok then return values end

    if not optionalAdapterFailures[label] then
        optionalAdapterFailures[label] = true
        local reason = tostring(values or "unknown error")
        if #reason > 240 then reason = reason:sub(1, 240) .. "..." end
        print("[PZ_Pulse_Expanded] " .. label .. " collection skipped: " .. reason)
    end
    local fallbackOk, fallback = pcall(OptionalModStatsAdapter.missing, player)
    return fallbackOk and fallback or nil
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
    values.vanilla_moodle_descriptions = collectVanillaMoodleDescriptions(player)

    local discomfort = StatUtils.sample(
        player, "discomfort", round2(stat(stats, "DISCOMFORT")), true, false
    )
    if discomfort ~= nil then
        values.discomfort = discomfort
    end

    local vanilla = {}
    for _, definition in ipairs({
        { "NICOTINE_WITHDRAWAL", "nicotine_withdrawal" },
        { "IDLENESS", "idleness" },
        { "POISON", "poison" },
    }) do
        local key = definition[2]
        local value = StatUtils.sample(player, key,
            round2(stat(stats, definition[1])), true, false)
        if value ~= nil then vanilla[key] = value end
    end
    if vanilla.nicotine_withdrawal ~= nil
        or vanilla.idleness ~= nil or vanilla.poison ~= nil then
        values.vanilla_stats = vanilla
    end

    -- Availability is independent of a first valid stat reading. The browser
    -- uses it to disable choices for mods absent from this game's mod list.
    local active = {}
    local mods = getActivatedMods and getActivatedMods() or nil
    for _, modId in ipairs({
        "NC_NaturesCall", "LifestyleHobbies", "TakeABathAndShowerNew",
        "BrushYourDamnTeeth", "DrugTime89", "twbInfirmities",
        "CaffeineMakesSense",
    }) do
        active[modId] = mods ~= nil and mods.contains ~= nil
            and mods:contains(modId) or false
    end
    if active.twbInfirmities and (SandboxVars == nil
        or SandboxVars.Infirmities == nil
        or SandboxVars.Infirmities.StartAddictiveSystem ~= true) then
        active.twbInfirmities = false
    end
    values.active_mods = active

    local naturesCall = collectNaturesCall(player)
    if naturesCall ~= nil then
        values.natures_call = naturesCall
    end

    local optionalModStats = collectContinuousOptional(player)
    if optionalModStats ~= nil then
        values.optional_mod_stats = optionalModStats
    end

    local customMoodles = collectOptional(
        CustomMoodleAdapter,
        player,
        "custom moodles"
    )
    if customMoodles ~= nil then
        values.custom_moodles = customMoodles
    end

    if values.discomfort == nil
        and values.vanilla_moodle_descriptions == nil
        and values.natures_call == nil
        and values.optional_mod_stats == nil
        and values.custom_moodles == nil then
        return nil
    end
    return values
end

-- Register the Needs Expanded collector and browser renderer with PZ Pulse.
table.insert(PZ_Pulse_EXT, {
    api = 1,
    mod = "PZ_Pulse_Expanded",
    version = "1.3.0",
    id = "needs_expanded",
    title = "Needs Expanded",
    cls = "info",
    collect = needsExpandedCollector,
    js = "media/web/expanded-needs.js",
    css = "media/web/expanded-needs.css",
    render = "renderNeedsExpanded",
    options = {
        { name = "auto_hide_zero", type = "bool", label = "Auto-hide idle bars", default = false },
        { name = "zero_hide_delay", type = "number", label = "Hide delay (seconds)", min = 0, max = 300, step = 5, default = 30 },
        { name = "flash_increases", type = "bool", label = "Flash on reveal (auto-hide)", default = false },
        { name = "flash_seconds", type = "number", label = "Reveal flash (seconds)", min = 0, max = 10, step = 0.5, default = 2 }
    }
})

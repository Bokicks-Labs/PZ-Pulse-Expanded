-- PZ Pulse exposes this shared registry as its stable extension entry point.
-- The append pattern is intentionally load-order independent: either mod may
-- create the table first.
PZ_Pulse_EXT = PZ_Pulse_EXT or {}

require("PZPulseExpanded/NaturesCallAdapter")
require("PZPulseExpanded/OptionalModStatsAdapter")
require("PZPulseExpanded/CustomMoodleAdapter")

local NaturesCallAdapter = PZPulseExpanded_NaturesCallAdapter
local OptionalModStatsAdapter = PZPulseExpanded_OptionalModStatsAdapter
local CustomMoodleAdapter = PZPulseExpanded_CustomMoodleAdapter

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

-- Nature's Call is optional. Disable only its adapter after an unexpected
-- failure so a bad compatibility edge cannot remove vanilla needs or
-- Discomfort. Kahlua can print caught errors, so this path logs at most once
-- and never retries for the rest of the session.
local natureCallAdapterFailed = false

local function collectNaturesCall(player)
    if natureCallAdapterFailed or NaturesCallAdapter == nil then return nil end

    local ok, values = pcall(NaturesCallAdapter.collect, player)
    if ok then return values end

    natureCallAdapterFailed = true
    local reason = tostring(values or "unknown error")
    if #reason > 240 then reason = reason:sub(1, 240) .. "..." end
    print("[PZ_Pulse_Expanded] Nature's Call adapter disabled: " .. reason)
    return nil
end

local optionalAdapterFailures = {}

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

    local discomfort = round2(stat(stats, "DISCOMFORT"))
    if discomfort ~= nil then
        values.discomfort = discomfort
    end

    local naturesCall = collectNaturesCall(player)
    if naturesCall ~= nil then
        values.natures_call = naturesCall
    end

    local optionalModStats = collectOptional(
        OptionalModStatsAdapter,
        player,
        "optional mod stats"
    )
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
    version = "0.1.0-dev",
    id = "needs_expanded",
    title = "Needs Expanded",
    cls = "info",
    collect = needsExpandedCollector,
    js = "media/web/expanded-needs.js",
    css = "media/web/expanded-needs.css",
    render = "renderNeedsExpanded"
})

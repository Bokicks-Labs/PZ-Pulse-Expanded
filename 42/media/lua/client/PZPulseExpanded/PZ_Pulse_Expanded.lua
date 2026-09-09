-- PZ Pulse exposes this shared registry as its stable extension entry point.
-- The append pattern is intentionally load-order independent: either mod may
-- create the table first.
PZ_Pulse_EXT = PZ_Pulse_EXT or {}

-- Helper shape adapted from PZ Pulse's reference extension.
-- Round collected floats so insignificant engine jitter does not defeat
-- PZ Pulse's serialized-payload change gate and cause unnecessary disk writes.
local function round2(number)
    number = tonumber(number) or 0
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

-- Current vertical slice: expose vanilla Discomfort through the PZ Pulse
-- extension payload. The browser renderer will later wrap this raw value in
-- PZ Pulse Expanded's normalized Stat model.
--
-- Always use the player supplied by PZ Pulse. Calling getPlayer() here can
-- select a different local survivor in splitscreen/multiplayer scenarios.
local function discomfortCollector(player)
    if player == nil then return nil end

    local stats = safe(function() return player:getStats() end)

    return {
        discomfort = round2(stat(stats, "DISCOMFORT", 0))
    }
end

-- Register the Needs Expanded collector and browser renderer with PZ Pulse.
table.insert(PZ_Pulse_EXT, {
    api = 1,
    mod = "PZ_Pulse_Expanded",
    version = "0.1.0-dev",
    id = "needs_expanded",
    title = "Needs Expanded",
    cls = "info",
    collect = discomfortCollector,
    js = "media/web/expanded-needs.js",
    css = "media/web/expanded-needs.css",
    render = "renderNeedsExpanded"
})

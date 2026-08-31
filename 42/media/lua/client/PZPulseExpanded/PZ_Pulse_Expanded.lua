-- Global table provided by PZ_Pulse
PZ_Pulse_EXT = PZ_Pulse_EXT or {}

-- Helper functions from PZ_Pulse, All credit goes to the original author of PZ_Pulse (qwerto).
local function round2(number)
    number = tonumber(number) or 0
    return math.floor(number * 100 + 0.5) / 100
end

local function safe(fn, default)
    local ok, v = pcall(fn)
    if ok and v ~= nil then return v end
    return default
end

local function stat(stats, name, default)
    local e = CharacterStat[name]
    if e == nil or stats == nil then return default end
    return safe(function() return stats:get(e) end, default)
end

-- PZ_Pulse_Expanded functions
local function discomfortCollector(player)
    if player == nil then return nil end
    local stats = safe(function() return player:getStats() end)
    return {
        discomfort = round2(stat(stats, "DISCOMFORT", 0))
    }
end


-- Insert new table into pz global table
table.insert(PZ_Pulse_EXT, {
    api = 1,
    mod = "PZ_Pulse_Expanded",
    version = "0.1.0-dev",
    id = "needs_expanded",
    title = "Needs Expanded",
    cls = "info",
    collect = discomfortCollector
})

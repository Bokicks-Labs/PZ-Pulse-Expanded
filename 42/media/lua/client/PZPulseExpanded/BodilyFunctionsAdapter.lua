-- Read existing Bodily Functions 1.3.2 state from the supplied player.
-- Its own getters use getPlayer(), which may select a different local player.
PZPulseExpanded_BodilyFunctionsAdapter = PZPulseExpanded_BodilyFunctionsAdapter or {}

local Adapter = PZPulseExpanded_BodilyFunctionsAdapter
local StatUtils = require("PZPulseExpanded/StatUtils")
local Sources = require("PZPulseExpanded/ModSources")
local recentLevels = setmetatable({}, { __mode = "k" })

local function enabled(setting)
    return Sources.isActive(Sources.bodilyFunctions)
        and not (SandboxVars and SandboxVars.BF
            and SandboxVars.BF[setting] == false)
end

local function capacity(field)
    local options = SandboxVars and SandboxVars.BathroomFunctions
    local value = options and StatUtils.finiteNumber(options[field])
    return value and value > 0 and value or nil
end

-- BF_BathroomMoodles compares fill / capacity with these strict thresholds.
-- Compute from the unrounded ratio so display rounding cannot shift a color.
local function urgeLevel(fill, max)
    local ratio = fill / max
    local level = 0
    for _, threshold in ipairs({ 0.4, 0.6, 0.8, 0.9 }) do
        if ratio > threshold then level = level + 1 end
    end
    return level
end

local function read(player, data, missing, problem)
    local values, health = {}, {}
    for _, definition in ipairs({
        { "bladder", "urinateValue", "BladderMaxValue", "EnableUrination" },
        { "bowel", "defecateValue", "BowelsMaxValue", "EnableDefecation" },
    }) do
        local key = "bodily_functions_" .. definition[1]
        local active = enabled(definition[4])
        local max = active and capacity(definition[3]) or nil
        local raw = not missing and data[definition[2]] or nil
        local number = StatUtils.finiteNumber(raw)
        local invalid = raw ~= nil and (number == nil or number < 0)
        local percent = number ~= nil and not invalid and max ~= nil
            and math.min(100, number / max * 100) or nil
        local value, status = StatUtils.sample(player, key, percent,
            active, false, problem or invalid or (active and max == nil))
        health[key] = status
        local playerLevels = recentLevels[player]
        if status == "reporting" and percent ~= nil then
            if playerLevels == nil then
                playerLevels = {}
                recentLevels[player] = playerLevels
            end
            playerLevels[key] = urgeLevel(number, max)
        elseif status ~= "recent" and playerLevels ~= nil then
            playerLevels[key] = nil
        end
        if value ~= nil then
            values[definition[1]] = value
            values[definition[1] .. "_level"] = playerLevels and playerLevels[key]
        elseif status == "waiting" then
            values[definition[1]] = 0
        end
    end
    if health.bodily_functions_bladder == "unavailable"
        and health.bodily_functions_bowel == "unavailable" then
        return nil, health
    end
    return values, health
end

function Adapter.collect(player)
    if player == nil then return nil end
    if player.getModData == nil then return read(player, {}, true, true) end
    local ok, data = pcall(player.getModData, player)
    if not ok or type(data) ~= "table" then
        return read(player, {}, true, true)
    end
    return read(player, data, false, false)
end

function Adapter.missing(player, problem)
    if player == nil then return nil end
    return read(player, {}, true, problem)
end

return Adapter

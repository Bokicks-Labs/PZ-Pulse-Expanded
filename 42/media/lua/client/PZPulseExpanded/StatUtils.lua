-- Shared read-only history for continuous stat bars. Source adapters decide
-- whether a mod is active and whether a value is intentionally hidden.
PZPulseExpanded_StatUtils = PZPulseExpanded_StatUtils or {}

local Utils = PZPulseExpanded_StatUtils
local StatOptions = require("PZPulseExpanded/StatOptions")

local recent = setmetatable({}, { __mode = "k" })

function Utils.finiteNumber(value)
    if type(value) ~= "number" and type(value) ~= "string" then return nil end
    local number = tonumber(value)
    if number == nil or number ~= number
        or number == math.huge or number == -math.huge then
        return nil
    end
    return number
end

function Utils.nowMs()
    if getTimestampMs == nil then return nil end
    local ok, value = pcall(getTimestampMs)
    if not ok then return nil end
    return Utils.finiteNumber(value)
end

-- A first reading must be real. Missing reads retain only a previously valid
-- value, and only for a bounded elapsed time. Explicit source absence/hidden
-- state invalidates immediately rather than consuming the grace period.
function Utils.sample(player, key, rawValue, active, hidden)
    if player == nil then return nil end
    local entries = recent[player]
    if active ~= true or hidden == true then
        if entries ~= nil then entries[key] = nil end
        return nil
    end

    local value = Utils.finiteNumber(rawValue)
    local now = Utils.nowMs()
    if value ~= nil then
        if now ~= nil then
            if entries == nil then
                entries = {}
                recent[player] = entries
            end
            entries[key] = { value = value, at = now }
        end
        return value
    end

    local previous = entries and entries[key] or nil
    if previous ~= nil and now ~= nil and now >= previous.at
        and StatOptions.graceMs() > 0
        and now - previous.at <= StatOptions.graceMs() then
        return previous.value
    end
    if entries ~= nil then entries[key] = nil end
    return nil
end

return Utils

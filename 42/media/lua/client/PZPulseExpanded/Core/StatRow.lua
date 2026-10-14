-- Shared validation and collection health for optional continuous bars.
local StatUtils = require("PZPulseExpanded/Core/StatUtils")
local Row = {}

function Row.finite(value, minimum, maximum)
    local number = StatUtils.finiteNumber(value)
    if number == nil or number < minimum or number > maximum then return nil end
    return number
end

function Row.add(values, health, player, key, raw, active, problem, minimum, maximum)
    local parsed = StatUtils.finiteNumber(raw)
    local outOfRange = parsed ~= nil and minimum ~= nil
        and (parsed < minimum or parsed > maximum)
    if outOfRange then raw = nil end
    local value, status = StatUtils.sample(player, key, raw, active, false,
        problem == true or outOfRange
            or (raw ~= nil and StatUtils.finiteNumber(raw) == nil))
    health[key] = status
    if value ~= nil then
        values[key] = value
    elseif status == "waiting" then
        values[key] = 0
    end
    return status
end

return Row

-- DEBUG: This is a line to know this script was loaded. Remove later.
print("[PZPulseExpanded] DiscomfortProbe loaded")

local lastReportedValue = nil

local function roundForLogging(value)
    if value == nil then
        return nil
    end

    local roundedValue = math.floor(value * 100 + 0.5) / 100
    return roundedValue
end

local function onPlayerUpdate(player)
    if player == nil then
        return
    end

    local stats = player:getStats()
    local discomfortStat = CharacterStat.DISCOMFORT

    if stats == nil or discomfortStat == nil then
        return
    end

    local discomfortValue = stats:get(discomfortStat)

    if discomfortValue == nil then
        return
    end

    local roundedValue = roundForLogging(discomfortValue)

    if lastReportedValue == nil or lastReportedValue ~= roundedValue then
        lastReportedValue = roundedValue
        print("Discomfort = " .. tostring(roundedValue))
    end
end

Events.OnPlayerUpdate.Add(onPlayerUpdate)

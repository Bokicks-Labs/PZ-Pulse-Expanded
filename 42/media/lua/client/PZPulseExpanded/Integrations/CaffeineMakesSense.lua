-- Source-owned optional stat reader. Reads existing state only.
local Sources = require("PZPulseExpanded/Core/Sources")
local Row = require("PZPulseExpanded/Core/StatRow")
local add, finite = Row.add, Row.finite
local Integration = {}
Integration.source = Sources.caffeine
Integration.statKeys = { "caffeine_load" }
local StatUtils = require("PZPulseExpanded/Core/StatUtils")
local caffeineMaximums = setmetatable({}, { __mode = "k" })

function Integration.isAvailable()
    return Sources.isActive(Sources.caffeine)
end

function Integration.collectStats(player, modData, missing, sourceProblem, values, health)
    local caffeineActive = Integration.isAvailable()
    local caffeineState = type(modData.CaffeineMakesSenseState) == "table"
        and modData.CaffeineMakesSenseState or nil
    local runtime = CaffeineMakesSense and CaffeineMakesSense.Runtime
    local caffeine = nil
    local caffeineProblem = sourceProblem == true
    local pureClient = isClient ~= nil and isClient()
        and (isServer == nil or not isServer())
    if not missing and caffeineActive and pureClient then
        local client = CaffeineMakesSense and CaffeineMakesSense.MPClient
        if client and type(client.getSnapshot) == "function" then
            local ok, snapshot = pcall(client.getSnapshot)
            if ok and type(snapshot) == "table" then
                caffeine = finite(snapshot.rawStimLoad, 0, 100)
                caffeineProblem = snapshot.rawStimLoad ~= nil and caffeine == nil
                if caffeine ~= nil then
                    values.caffeine_load_max = StatUtils.round2(
                        finite(snapshot.maxCaffeine, 0.01, 100)) or 4
                end
            elseif not ok then
                caffeineProblem = true
            end
        else
            caffeineProblem = true
        end
    elseif not missing and caffeineActive and caffeineState ~= nil and runtime
        and type(runtime.getLoadTotals) == "function"
        and type(runtime.getWorldAgeMinutes) == "function"
        and type(runtime.getOptions) == "function" then
        local ok, load, maxLoad = pcall(function()
            local options = runtime.getOptions()
            return runtime.getLoadTotals(caffeineState,
                runtime.getWorldAgeMinutes(), options), options.MaxCaffeineLevel
        end)
        if ok then caffeine = finite(load, 0, 100) end
        caffeineProblem = not ok or (load ~= nil and caffeine == nil)
        if caffeine ~= nil then
            values.caffeine_load_max = StatUtils.round2(
                finite(maxLoad, 0.01, 100)) or 4
        end
    elseif not missing and caffeineActive and caffeineState ~= nil then
        caffeineProblem = true
    end
    add(values, health, player, "caffeine_load", caffeine, caffeineActive,
        caffeineProblem)
    if values.caffeine_load ~= nil then
        if values.caffeine_load_max ~= nil then
            caffeineMaximums[player] = values.caffeine_load_max
        else
            values.caffeine_load_max = caffeineMaximums[player] or 4
        end
    elseif not caffeineActive then
        caffeineMaximums[player] = nil
    end
end

return Integration

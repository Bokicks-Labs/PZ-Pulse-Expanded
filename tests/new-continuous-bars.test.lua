package.path = "42/media/lua/client/?.lua;" .. package.path
function getTimestampMs() return 100000 end
function isClient() return false end
function isServer() return false end

local active = { DrugTime89 = true, twbInfirmities = true,
    CaffeineMakesSense = true }
function getActivatedMods()
    return { contains = function(_, id) return active[id] == true end }
end
SandboxVars = { Infirmities = { StartAddictiveSystem = true } }
CaffeineMakesSense = { Runtime = {
    getWorldAgeMinutes = function() return 600 end,
    getOptions = function() return { MaxCaffeineLevel = 8 } end,
    getLoadTotals = function(state, time, options)
        assert(time == 600 and (options.MaxCaffeineLevel == 8
            or options.MaxCaffeineLevel == 8.76543))
        return state.load
    end,
} }

local modData = {
    DT_Stoned = 70, DT_HardDrug = 0,
    addictions = { alcohol = 1, nicotine = 2, caffeine = 3,
        painkillers = 4, sleepingPills = 5, amphetamines = 6 },
    CaffeineMakesSenseState = { load = 2 },
}
local player = { getModData = function() return modData end }
local adapter = require("PZPulseExpanded/OptionalModStatsAdapter")
local values = adapter.collect(player)
assert(values.drugtime_stoned == 70 and values.drugtime_hard == 0)
assert(values.addiction_alcohol == 1 and values.addiction_nicotine == 2)
assert(values.addiction_caffeine == 3 and values.addiction_painkillers == 4)
assert(values.addiction_sleeping_pills == 5 and values.addiction_amphetamines == 6)
assert(values.caffeine_load == 2 and values.caffeine_load_max == 8)

modData.addictions.nicotine = 2.34567
modData.CaffeineMakesSenseState.load = 2.34567
CaffeineMakesSense.Runtime.getOptions = function()
    return { MaxCaffeineLevel = 8.76543 }
end
values = adapter.collect(player)
assert(values.addiction_nicotine == 2.35)
assert(values.caffeine_load == 2.35 and values.caffeine_load_max == 8.77)

-- Missing source state retains a prior reading briefly; disabling the source
-- or its sandbox system invalidates that history immediately.
modData.addictions = nil
assert(adapter.collect(player).addiction_alcohol == 1)
SandboxVars.Infirmities.StartAddictiveSystem = false
assert(adapter.collect(player).addiction_alcohol == nil)
active.DrugTime89 = false
modData.DT_Stoned = nil
assert(adapter.collect(player).drugtime_stoned == nil)

function isClient() return true end
CaffeineMakesSense.MPClient = {
    getSnapshot = function() return { rawStimLoad = 1.5, maxCaffeine = 6 } end,
}
values = adapter.collect(player)
assert(values.caffeine_load == 1.5 and values.caffeine_load_max == 6)
print("New continuous bar adapter fixtures passed")

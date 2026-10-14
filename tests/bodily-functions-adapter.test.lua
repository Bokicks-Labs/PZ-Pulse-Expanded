package.path = "42/media/lua/client/?.lua;" .. package.path

local active = true
function getActivatedMods()
    return { contains = function(_, id) return active and id == "bodilyfunctions" end }
end
function getTimestampMs() return 1000 end
function getPlayer() error("adapter must use the supplied player") end

SandboxVars = {
    BF = { EnableUrination = true, EnableDefecation = true },
    BathroomFunctions = { BladderMaxValue = 800, BowelsMaxValue = 500 },
}

local Adapter = require("PZPulseExpanded/Integrations/BodilyFunctions")
local data = { urinateValue = 320, defecateValue = 0 }
local player = { getModData = function() return data end }

local values, health = Adapter.collect(player)
assert(values.bladder == 40 and values.bowel == 0)
assert(values.bladder_level == 0 and values.bowel_level == 0)
assert(health.bodily_functions_bladder == "reporting")
assert(health.bodily_functions_bowel == "reporting")
assert(data.urinateValue == 320 and data.defecateValue == 0)

data.urinateValue = 720
assert(Adapter.collect(player).bladder == 90)
data.urinateValue = 320.001
values = Adapter.collect(player)
assert(values.bladder == 40 and values.bladder_level == 1,
    "strict source threshold must survive displayed percentage rounding")
for _, case in ipairs({
    { 0.4, 0 }, { 0.40001, 1 },
    { 0.6, 1 }, { 0.60001, 2 },
    { 0.8, 2 }, { 0.80001, 3 },
    { 0.9, 3 }, { 0.90001, 4 },
}) do
    data.urinateValue = 800 * case[1]
    assert(Adapter.collect(player).bladder_level == case[2])
end
data.urinateValue = 850
values = Adapter.collect(player)
assert(values.bladder == 100 and values.bladder_level == 4)

SandboxVars.BF.EnableUrination = false
values, health = Adapter.collect(player)
assert(values.bladder == nil and health.bodily_functions_bladder == "unavailable")
assert(values.bowel == 0)

SandboxVars.BF.EnableUrination = true
data.urinateValue = -1
values, health = Adapter.collect(player)
assert(values.bladder == nil and health.bodily_functions_bladder == "problem",
    "disabled history must not survive an invalid new reading")

active = false
values, health = Adapter.collect(player)
assert(values == nil and health.bodily_functions_bowel == "unavailable")

print("Bodily Functions adapter tests passed")

package.path = "42/media/lua/client/?.lua;" .. package.path

local now = 100000
function getTimestampMs() return now end

local optionValue = 30
local option = { getValue = function() return optionValue end }
local options = { getOption = function(_, key)
    assert(key == "missingStatGraceSeconds")
    return option
end }
PZAPI = { ModOptions = {
    getOptions = function() return options end,
} }

local Utils = require("PZPulseExpanded/StatUtils")
local player = {}
assert(Utils.sample(player, "a", nil, true, false) == nil)
assert(Utils.sample(player, "a", 42, true, false) == 42)
now = now + 29000
assert(Utils.sample(player, "a", nil, true, false) == 42)
now = now + 1001
assert(Utils.sample(player, "a", nil, true, false) == nil)

assert(Utils.sample(player, "a", 43, true, false) == 43)
optionValue = 0
assert(Utils.sample(player, "a", nil, true, false) == nil,
    "zero grace must hide on the next failed read")
optionValue = 30
assert(Utils.sample(player, "a", nil, true, false) == nil,
    "expired values cannot reappear after changing the option")

assert(Utils.sample(player, "a", 44, true, false) == 44)
assert(Utils.sample(player, "a", nil, true, true) == nil)
assert(Utils.sample(player, "a", nil, true, false) == nil)
assert(Utils.sample(player, "a", 45, true, false) == 45)
assert(Utils.sample(player, "a", nil, false, false) == nil)
assert(Utils.sample(player, "a", nil, true, false) == nil)

print("Continuous stat grace fixtures passed")

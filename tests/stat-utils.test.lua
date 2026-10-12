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
local _, status = Utils.sample(player, "status_zero", 0, true, false)
assert(status == "reporting", "valid zero is a real reported value")
local _, waiting = Utils.sample(player, "status_waiting", nil, true, false)
assert(waiting == "waiting")
local _, problem = Utils.sample(player, "status_problem", "bad", true, false)
assert(problem == "problem")
assert(Utils.sample(player, "precision", 78.21247329711908, true, false) == 78.21,
    "collected stat values must have at most two decimal places")
assert(Utils.sample(player, "precision", 78.215, true, false) == 78.22)
assert(Utils.sample(player, "precision", nil, true, false) == 78.22,
    "retained values must already be rounded")
now = now + 29000
assert(Utils.sample(player, "a", nil, true, false) == 42)
local _, recent = Utils.sample(player, "a", nil, true, false)
assert(recent == "recent")
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
local _, hidden = Utils.sample(player, "a", nil, true, true)
assert(hidden == "unavailable")
assert(Utils.sample(player, "a", nil, true, false) == nil)
assert(Utils.sample(player, "a", 45, true, false) == 45)
assert(Utils.sample(player, "a", nil, false, false) == nil)
local _, unavailable = Utils.sample(player, "a", nil, false, false)
assert(unavailable == "unavailable")
assert(Utils.sample(player, "a", nil, true, false) == nil)

print("Continuous stat grace fixtures passed")

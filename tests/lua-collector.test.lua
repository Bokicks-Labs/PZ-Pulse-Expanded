package.path = "42/media/lua/client/?.lua;" .. package.path
local now = 100000
function getTimestampMs() return now end

PZ_Pulse_EXT = {}
CharacterStat = { DISCOMFORT = {}, NICOTINE_WITHDRAWAL = {}, IDLENESS = {}, POISON = {} }

local active = true

function getActivatedMods()
    return {
        contains = function(_, modId)
            return active and modId == "NC_NaturesCall"
        end,
    }
end

function isClient()
    return false
end

function isServer()
    return false
end

function getPlayer()
    error("collector must use the supplied player")
end

local sourceState = {
    bladderFill = 60,
    bowelFill = 0,
    traitModifiers = {},
}

local player = {
    getStats = function()
        return {
            get = function(_, enum)
                local readings = {
                    [CharacterStat.DISCOMFORT] = 12.345,
                    [CharacterStat.NICOTINE_WITHDRAWAL] = 0.25,
                    [CharacterStat.IDLENESS] = 0,
                    [CharacterStat.POISON] = 5,
                }
                assert(readings[enum] ~= nil)
                return readings[enum]
            end,
        }
    end,
    getModData = function()
        return { NaturesCall = sourceState }
    end,
}

dofile("42/media/lua/client/PZPulseExpanded/PZ_Pulse_Expanded.lua")

assert(#PZ_Pulse_EXT == 1, "extension should register exactly once")
local spec = PZ_Pulse_EXT[1]
assert(spec.mod == "PZ_Pulse_Expanded")
assert(spec.id == "needs_expanded")
assert(spec.render == "renderNeedsExpanded")

local collected = spec.collect(player)
assert(collected.discomfort == 12.35, "Discomfort should be rounded, not rescaled")
assert(collected.vanilla_stats.nicotine_withdrawal == 0.25)
assert(collected.vanilla_stats.idleness == 0)
assert(collected.vanilla_stats.poison == 5)
assert(collected.active_mods.NC_NaturesCall == true)
assert(collected.active_mods.DrugTime89 == false)
assert(collected.natures_call.bladder == 60)
assert(collected.natures_call.bowel == 0, "valid Nature's Call zero should survive")
assert(sourceState.bladderFill == 60 and sourceState.bowelFill == 0,
    "collector must not mutate source state")

-- The game's localized, level-specific moodle text supplements PZ Pulse's
-- vanilla moodle payload without altering the game's moodle state.
MoodleType = { HUNGRY = {}, FOOD_EATEN = {} }
player.getMoodles = function()
    return { getMoodleLevel = function(_, enum)
        return enum == MoodleType.HUNGRY and 3 or 4
    end }
end
getText = function(key)
    if key == "Moodles_Hungry_desc_lvl3" then return "Hunger makes you weak." end
    if key == "Moodles_FoodEaten_desc_lvl4" then return "You feel full." end
    return key
end
local described = spec.collect(player)
assert(described.vanilla_moodle_descriptions["status_hunger:bad"] == "Hunger makes you weak.")
assert(described.vanilla_moodle_descriptions["status_hunger:good"] == "You feel full.")
MoodleType, getText, player.getMoodles = nil, nil, nil

active = false
local withoutNature = spec.collect(player)
assert(withoutNature.discomfort == 12.35)
assert(withoutNature.natures_call == nil, "inactive optional mod must not erase Discomfort")

-- Exceptions retain a recent result briefly and collection retries.
local calls = 0
local originalCollect = PZPulseExpanded_NaturesCallAdapter.collect
PZPulseExpanded_NaturesCallAdapter.collect = function()
    calls = calls + 1
    error("fixture adapter failure")
end
active = true

local firstFailure = spec.collect(player)
assert(firstFailure.discomfort == 12.35 and firstFailure.natures_call == nil)
for _ = 2, 10 do
    spec.collect(player)
end
assert(calls == 10,
    "failed adapter must remain retryable")
PZPulseExpanded_NaturesCallAdapter.collect = originalCollect
sourceState.bladderFill = 61
sourceState.bowelFill = 2
assert(spec.collect(player).natures_call.bladder == 61,
    "adapter recovers after exceptions")
PZPulseExpanded_NaturesCallAdapter.collect = function()
    error("fixture intermittent failure")
end
assert(spec.collect(player).natures_call.bladder == 61,
    "one exception retains a recently valid reading")
now = now + 90001
assert(spec.collect(player).natures_call == nil,
    "repeated exceptions beyond grace period hide stale Nature's Call values")

PZPulseExpanded_NaturesCallAdapter.collect = originalCollect
assert(spec.collect(player).discomfort == 12.35)
local originalStats = player.getStats
player.getStats = function() error("temporary stat failure") end
assert(spec.collect(player).discomfort == 12.35,
    "a failed Discomfort read should retain its last valid value")
now = now + 90001
assert(spec.collect(player).discomfort == nil,
    "persistently failed Discomfort reads should expire")
player.getStats = originalStats
assert(spec.collect(player).discomfort == 12.35,
    "Discomfort should recover after a valid reading")

print("Needs Expanded Lua collector fixtures passed")

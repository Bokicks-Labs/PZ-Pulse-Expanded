package.path = "42/media/lua/client/?.lua;" .. package.path
local now = 100000
function getTimestampMs() return now end

PZ_Pulse_EXT = {}
CharacterStat = { DISCOMFORT = {}, NICOTINE_WITHDRAWAL = {}, IDLENESS = {}, POISON = {} }

local active = true
local bodilyActive = true
SandboxVars = { BF = { EnableUrination = true, EnableDefecation = true },
    BathroomFunctions = { BladderMaxValue = 800, BowelsMaxValue = 500 } }

function getActivatedMods()
    return {
        contains = function(_, modId)
            return (active and modId == "NC_NaturesCall")
                or (bodilyActive and modId == "bodilyfunctions")
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
        return { NaturesCall = sourceState, urinateValue = 320,
            defecateValue = 250 }
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
assert(collected.bar_health.nicotine_withdrawal == "reporting")
assert(collected.bar_health.idleness == "reporting",
    "a real zero from a vanilla stat is reported, not treated as missing")
assert(collected.active_mods.NC_NaturesCall == true)
assert(collected.active_mods.DrugTime89 == false)
assert(collected.bar_health.discomfort == "reporting")
assert(collected.bar_health.natures_call_bladder == "reporting")
assert(collected.natures_call.bladder == 60)
assert(collected.natures_call.bowel == 0, "valid Nature's Call zero should survive")
assert(collected.active_mods.bodilyfunctions == true)
assert(collected.bodily_functions.bladder == 40
    and collected.bodily_functions.bowel == 50,
    "two excretion sources remain independent")
assert(collected.bodily_functions.bladder_level == 0)
bodilyActive = false
local withoutBodily = spec.collect(player)
assert(withoutBodily.bodily_functions == nil
    and withoutBodily.natures_call.bladder == 60)
bodilyActive = true
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
active = true
assert(spec.collect(player).natures_call.bladder == 60,
    "valid source data is restored before the simulated failure")
PZPulseExpanded_NaturesCallAdapter.collect = function()
    calls = calls + 1
    error("fixture adapter failure")
end

local firstFailure = spec.collect(player)
assert(firstFailure.discomfort == 12.35
    and firstFailure.natures_call.bladder == 60)
assert(firstFailure.bar_health.natures_call_bladder == "recent")
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
local expiredNature = spec.collect(player)
assert(expiredNature.natures_call.bladder == nil
    and expiredNature.bar_health.natures_call_bladder == "problem",
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

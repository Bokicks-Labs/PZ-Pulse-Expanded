package.path = "42/media/lua/client/?.lua;" .. package.path

PZ_Pulse_EXT = {}
CharacterStat = { DISCOMFORT = {} }

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
                assert(enum == CharacterStat.DISCOMFORT)
                return 12.345
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
assert(collected.natures_call.bladder == 60)
assert(collected.natures_call.bowel == 0, "valid Nature's Call zero should survive")
assert(sourceState.bladderFill == 60 and sourceState.bowelFill == 0,
    "collector must not mutate source state")

active = false
local withoutNature = spec.collect(player)
assert(withoutNature.discomfort == 12.35)
assert(withoutNature.natures_call == nil, "inactive optional mod must not erase Discomfort")

-- Exceptions retain a recent result briefly and collection retries.
local calls = 0
PZPulseExpanded_NaturesCallAdapter.collect = function()
    calls = calls + 1
    error("fixture adapter failure")
end
active = true

local firstFailure = spec.collect(player)
assert(firstFailure.discomfort == 12.35 and firstFailure.natures_call == nil)
for _ = 2, PZPulseExpanded_NaturesCallAdapter.MAX_MISSED_READS do
    spec.collect(player)
end
assert(calls == PZPulseExpanded_NaturesCallAdapter.MAX_MISSED_READS,
    "failed adapter must remain retryable")
PZPulseExpanded_NaturesCallAdapter.collect = function()
    return { bladder = 61, bowel = 2 }
end
assert(spec.collect(player).natures_call.bladder == 61,
    "adapter recovers after exceptions")
PZPulseExpanded_NaturesCallAdapter.collect = function()
    error("fixture intermittent failure")
end
assert(spec.collect(player).natures_call.bladder == 61,
    "one exception retains a recently valid reading")

print("Needs Expanded Lua collector fixtures passed")

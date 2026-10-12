package.path = "42/media/lua/client/?.lua;" .. package.path
local adapterPath = "42/media/lua/client/PZPulseExpanded/NaturesCallAdapter.lua"
local now = 100000
function getTimestampMs() return now end

local active = true
local client = false
local server = false

function getActivatedMods()
    return {
        contains = function(_, modId)
            return active and modId == "NC_NaturesCall"
        end,
    }
end

function isClient()
    return client
end

function isServer()
    return server
end

function getPlayer()
    error("adapter must use the supplied player")
end

local Adapter = dofile(adapterPath)

local function playerWith(modData)
    return {
        getModData = function()
            return modData
        end,
    }
end

local function assertNil(value, message)
    assert(value == nil, message or "expected nil")
end

local function assertEqual(actual, expected, message)
    assert(actual == expected, (message or "values differ")
        .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

active = false
local inactiveValues, inactiveHealth = Adapter.collect(playerWith({
    NaturesCall = { bladderFill = 10, bowelFill = 20 },
}))
assertNil(inactiveValues, "inactive mod must not expose stale state")
assertEqual(inactiveHealth.natures_call_bladder, "unavailable")

active = true
local absentValues, absentHealth = Adapter.collect(playerWith({}))
assertEqual(absentValues.bladder, 0, "missing source state gets a visible placeholder")
assertEqual(absentValues.bowel, 0, "missing source state gets a visible placeholder")
assertEqual(absentHealth.natures_call_bladder, "waiting")
local uninitializedValues, uninitializedHealth = Adapter.collect(playerWith({ NaturesCall = {} }))
assertEqual(uninitializedValues.bladder, 0)
assertEqual(uninitializedHealth.natures_call_bladder, "waiting")

local localState = {
    bladderFill = 0,
    bowelFill = 120,
    traitModifiers = {},
}
local localModData = { NaturesCall = localState }
local localValues = Adapter.collect(playerWith(localModData))
assertEqual(localValues.bladder, 0, "valid local zero must remain visible")
assertEqual(localValues.bowel, 120, "source maximum must remain raw")
assertEqual(localModData.NaturesCall, localState, "adapter must not replace source state")
assertEqual(localState.bladderFill, 0, "adapter must not mutate source values")

local preciseState = { bladderFill = 78.21247329711908, bowelFill = 0 }
local preciseValues = Adapter.collect(playerWith({ NaturesCall = preciseState }))
assertEqual(preciseValues.bladder, 78.21, "Nature's Call payload must be rounded")
assertEqual(preciseState.bladderFill, 78.21247329711908,
    "rounding must not mutate source state")

local partialValues = Adapter.collect(playerWith({
    NaturesCall = { bladderFill = "bad", bowelFill = 0 },
}))
assertNil(partialValues.bladder, "malformed individual fill must be omitted")
assertEqual(partialValues.bowel, 0, "another valid fill must survive")

local hiddenLocal = Adapter.collect(playerWith({
    NaturesCall = {
        bladderFill = 50,
        bowelFill = 60,
        traitModifiers = { majorBladderIncontinence = true },
    },
}))
assertNil(hiddenLocal.bladder, "source-hidden local meter must be omitted")
assertEqual(hiddenLocal.bowel, 60, "unrelated local meter must survive")

client = true
server = false
local unsyncedValues, unsyncedHealth = Adapter.collect(playerWith({
    NaturesCall = { bladderFill = 0, bowelFill = 0 },
}))
assertEqual(unsyncedValues.bladder, 0,
    "unsynchronized state gets a zero placeholder")
assertEqual(unsyncedHealth.natures_call_bladder, "waiting")

local syncedState = {
    bladderFill = 0,
    bowelFill = 0,
    ownerSnapshot = {
        bladderFill = 0,
        bowelFill = 60,
        traitModifiers = {},
    },
}
local syncedValues = Adapter.collect(playerWith({ NaturesCall = syncedState }))
assertEqual(syncedValues.bladder, 0, "synced zero must remain visible")
assertEqual(syncedValues.bowel, 60, "synced bowel fill")

local hiddenSynced = Adapter.collect(playerWith({
    NaturesCall = {
        ownerSnapshot = { bladderFill = -1, bowelFill = 25 },
    },
}))
assertNil(hiddenSynced.bladder, "negative source-hidden snapshot must be omitted")
assertEqual(hiddenSynced.bowel, 25, "unrelated synchronized meter must survive")

local intermittentState = {
    ownerSnapshot = { bladderFill = 45, bowelFill = 70 },
}
local intermittentPlayer = playerWith({ NaturesCall = intermittentState })
assertEqual(Adapter.collect(intermittentPlayer).bladder, 45)
intermittentState.ownerSnapshot = { bladderFill = "bad", bowelFill = 71 }
for _ = 1, 10 do
    local values, health = Adapter.collect(intermittentPlayer)
    assertEqual(values.bladder, 45, "many brief invalid reads retain last valid fill")
    assertEqual(values.bowel, 71, "good fills continue to update")
    assertEqual(health.natures_call_bladder,
        "recent", "retained readings have an explicit health state")
end
now = now + 90001
local expiredValues, expiredHealth = Adapter.collect(intermittentPlayer)
assertNil(expiredValues.bladder,
    "invalid reads past the grace period hide the broken meter")
assertEqual(expiredHealth.natures_call_bladder, "problem")
intermittentState.ownerSnapshot = { bladderFill = 46, bowelFill = 72 }
assertEqual(Adapter.collect(intermittentPlayer).bladder, 46,
    "recovered fill becomes visible again")
intermittentState.ownerSnapshot = { bladderFill = -1, bowelFill = 73 }
assertNil(Adapter.collect(intermittentPlayer).bladder,
    "explicit source-hidden fill must hide immediately")

intermittentState.ownerSnapshot = nil
assertEqual(Adapter.collect(intermittentPlayer).bowel, 73,
    "brief owner snapshot loss retains synced values")
active = false
assertNil(Adapter.collect(intermittentPlayer), "inactive mod clears retained values")
active = true
local reactivatedValues, reactivatedHealth = Adapter.collect(intermittentPlayer)
assertEqual(reactivatedValues.bladder, 0,
    "reactivation shows zero until a fresh snapshot arrives")
assertEqual(reactivatedHealth.natures_call_bladder, "waiting")

print("Nature's Call adapter fixtures passed")

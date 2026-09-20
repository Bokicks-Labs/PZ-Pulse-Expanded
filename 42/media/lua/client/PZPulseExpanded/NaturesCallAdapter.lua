-- Optional compatibility adapter for Nature's Call 1.0.15.
--
-- This module deliberately reads existing player state directly. Calling
-- NaturesCall.State.ensurePlayerData() or getDetailedSnapshot() here would
-- initialize/mutate source-mod state during a read-only PZ Pulse export.

PZPulseExpanded_NaturesCallAdapter = PZPulseExpanded_NaturesCallAdapter or {}

local Adapter = PZPulseExpanded_NaturesCallAdapter

Adapter.MOD_ID = "NC_NaturesCall"
Adapter.SOURCE_NAME = "Nature's Call"
Adapter.MIN_FILL = 0
Adapter.MAX_FILL = 120

local function finiteNumber(value)
    if type(value) ~= "number" and type(value) ~= "string" then
        return nil
    end

    local number = tonumber(value)
    if number == nil or number ~= number or number == math.huge or number == -math.huge then
        return nil
    end

    return number
end

local function isActive()
    if getActivatedMods == nil then return false end

    local activeMods = getActivatedMods()
    if activeMods == nil or activeMods.contains == nil then return false end

    return activeMods:contains(Adapter.MOD_ID)
end

local function isPureMultiplayerClient()
    if isClient == nil or isServer == nil then return false end
    return isClient() and not isServer()
end

local function visibleFill(snapshot, key, hiddenByTrait)
    if hiddenByTrait then return nil end

    local value = finiteNumber(snapshot[key])
    if value == nil or value < Adapter.MIN_FILL then return nil end

    return value
end

-- Return raw source values, or nil when the mod/state is absent or has not
-- initialized yet. A numeric zero is valid and must remain distinguishable
-- from a missing field.
function Adapter.collect(player)
    if not isActive() then return nil end
    if player == nil or player.getModData == nil then return nil end

    local playerModData = player:getModData()
    if type(playerModData) ~= "table" then return nil end

    local state = playerModData.NaturesCall
    if type(state) ~= "table" then return nil end

    local snapshot = state
    if isPureMultiplayerClient() then
        -- Nature's Call initializes a client-side table with zeroes before the
        -- server sends authoritative state. ownerSnapshot is the source mod's
        -- explicit synchronization-ready marker and avoids inventing zeroes.
        if type(state.ownerSnapshot) ~= "table" then return nil end
        snapshot = state.ownerSnapshot
    end

    local traitModifiers = snapshot.traitModifiers or state.traitModifiers or {}
    local bladder = visibleFill(
        snapshot,
        "bladderFill",
        traitModifiers.majorBladderIncontinence == true
    )
    local bowel = visibleFill(
        snapshot,
        "bowelFill",
        traitModifiers.majorBowelIncontinence == true
    )

    if bladder == nil and bowel == nil then return nil end

    local values = {}
    if bladder ~= nil then values.bladder = bladder end
    if bowel ~= nil then values.bowel = bowel end
    return values
end

return Adapter

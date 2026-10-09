-- Read-only compatibility adapters for optional continuous mod stats.
--
-- Every value is independent: a missing mod, uninitialized ModData table, or
-- malformed field omits only that one stat from the PZ Pulse payload.

PZPulseExpanded_OptionalModStatsAdapter =
    PZPulseExpanded_OptionalModStatsAdapter or {}

local Adapter = PZPulseExpanded_OptionalModStatsAdapter
local StatUtils = require("PZPulseExpanded/StatUtils")

local function isActive(modId)
    if getActivatedMods == nil then return false end

    local mods = getActivatedMods()
    if mods == nil or mods.contains == nil then return false end

    return mods:contains(modId)
end

local function add(values, player, key, raw, active)
    local value = StatUtils.sample(player, key, raw, active, false)
    if value ~= nil then values[key] = value end
end

local function lifestyleHygieneHidden()
    if not (isActive("CWModpackCompatibility")
        or isActive("CWModpackCompatibility_dev")) then
        return false
    end
    local ownership = CWModpackCompatibility and CWModpackCompatibility.LifestyleOwnership
    if not (ownership and type(ownership.isLifestyleHygieneDisabled) == "function") then
        return false
    end
    local ok, disabled = pcall(ownership.isLifestyleHygieneDisabled)
    return ok and disabled == true
end

local function collectValues(player, modData, missing)
    local values = {}
    local teeth = type(modData.BrushYourDamnTeeth) == "table"
        and modData.BrushYourDamnTeeth or {}
    add(values, player, "lifestyle_hygiene_need",
        not missing and modData.hygieneNeed or nil,
        isActive("LifestyleHobbies") and not lifestyleHygieneHidden())
    add(values, player, "tasab_body_grime",
        not missing and modData.tabas_BodyGrime or nil, isActive("TakeABathAndShowerNew"))
    add(values, player, "bydt_dental_hygiene",
        not missing and teeth.dentalHygiene or nil, isActive("BrushYourDamnTeeth"))
    if values.lifestyle_hygiene_need == nil
        and values.tasab_body_grime == nil
        and values.bydt_dental_hygiene == nil then
        return nil
    end
    return values
end

function Adapter.collect(player)
    if player == nil then return nil end
    local modData = nil
    if player.getModData ~= nil then
        local ok, data = pcall(player.getModData, player)
        if ok and type(data) == "table" then modData = data end
    end
    return collectValues(player, modData or {}, false)
end

function Adapter.missing(player)
    if player == nil then return nil end
    return collectValues(player, {}, true)
end

return Adapter

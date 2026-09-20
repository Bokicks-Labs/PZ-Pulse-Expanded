-- Read-only compatibility adapters for optional continuous mod stats.
--
-- Every value is independent: a missing mod, uninitialized ModData table, or
-- malformed field omits only that one stat from the PZ Pulse payload.

PZPulseExpanded_OptionalModStatsAdapter =
    PZPulseExpanded_OptionalModStatsAdapter or {}

local Adapter = PZPulseExpanded_OptionalModStatsAdapter

local function finiteNumber(value)
    if type(value) ~= "number" and type(value) ~= "string" then return nil end

    local number = tonumber(value)
    if number == nil or number ~= number
        or number == math.huge or number == -math.huge then
        return nil
    end

    return number
end

local function isActive(modId)
    if getActivatedMods == nil then return false end

    local mods = getActivatedMods()
    if mods == nil or mods.contains == nil then return false end

    return mods:contains(modId)
end

local function add(values, key, value)
    value = finiteNumber(value)
    if value == nil then return false end

    values[key] = value
    return true
end

function Adapter.collect(player)
    if player == nil or player.getModData == nil then return nil end

    local modData = player:getModData()
    if type(modData) ~= "table" then return nil end

    local values = {}
    local hasValues = false

    if isActive("LifestyleHobbies") then
        hasValues = add(values, "lifestyle_hygiene_need", modData.hygieneNeed)
            or hasValues
    end

    if isActive("TakeABathAndShowerNew") then
        hasValues = add(values, "tasab_body_grime", modData.tabas_BodyGrime)
            or hasValues
    end

    if isActive("BrushYourDamnTeeth")
        and type(modData.BrushYourDamnTeeth) == "table" then
        hasValues = add(
            values,
            "bydt_dental_hygiene",
            modData.BrushYourDamnTeeth.dentalHygiene
        ) or hasValues
    end

    if not hasValues then return nil end
    return values
end

return Adapter

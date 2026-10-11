-- Read-only compatibility adapters for optional continuous mod stats.
--
-- Every value is independent: a missing mod, uninitialized ModData table, or
-- malformed field omits only that one stat from the PZ Pulse payload.

PZPulseExpanded_OptionalModStatsAdapter =
    PZPulseExpanded_OptionalModStatsAdapter or {}

local Adapter = PZPulseExpanded_OptionalModStatsAdapter
local StatUtils = require("PZPulseExpanded/StatUtils")
local Sources = require("PZPulseExpanded/ModSources")
local caffeineMaximums = setmetatable({}, { __mode = "k" })

local function finite(value, minimum, maximum)
    local number = StatUtils.finiteNumber(value)
    if number == nil or number < minimum or number > maximum then return nil end
    return number
end

local function add(values, player, key, raw, active)
    local value = StatUtils.sample(player, key, raw, active, false)
    if value ~= nil then values[key] = value end
end

local function lifestyleHygieneHidden()
    if not (Sources.isActive("CWModpackCompatibility")
        or Sources.isActive("CWModpackCompatibility_dev")) then
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
        Sources.isActive(Sources.lifestyle) and not lifestyleHygieneHidden())
    local lifestyle = Sources.isActive(Sources.lifestyle)
    local moodles = type(modData.LSMoodles) == "table" and modData.LSMoodles or {}
    local embarrassed = type(moodles.Embarrassed) == "table"
        and moodles.Embarrassed or {}
    add(values, player, "lifestyle_embarrassment",
        not missing and finite(embarrassed.Value, 0, 1) or nil, lifestyle)
    add(values, player, "lifestyle_comfort_need",
        not missing and finite(modData.ComfortNeed, 0, 1) or nil, lifestyle)
    add(values, player, "lifestyle_beauty_need",
        not missing and finite(modData.BeautyNeed, 0, 100) or nil, lifestyle)
    add(values, player, "tasab_body_grime",
        not missing and modData.tabas_BodyGrime or nil, Sources.isActive(Sources.tasab))
    add(values, player, "bydt_dental_hygiene",
        not missing and teeth.dentalHygiene or nil, Sources.isActive(Sources.teeth))
    local drugTime = Sources.isActive(Sources.drugtime)
    add(values, player, "drugtime_stoned",
        not missing and finite(modData.DT_Stoned, 0, 140) or nil, drugTime)
    add(values, player, "drugtime_hard",
        not missing and finite(modData.DT_HardDrug, 0, 160) or nil, drugTime)

    local infirmities = Sources.isActive(Sources.infirmities)
        and SandboxVars ~= nil and SandboxVars.Infirmities ~= nil
        and SandboxVars.Infirmities.StartAddictiveSystem == true
    local addictions = type(modData.addictions) == "table" and modData.addictions or {}
    for _, definition in ipairs({
        { "alcohol", "addiction_alcohol" },
        { "nicotine", "addiction_nicotine" },
        { "caffeine", "addiction_caffeine" },
        { "painkillers", "addiction_painkillers" },
        { "sleepingPills", "addiction_sleeping_pills" },
        { "amphetamines", "addiction_amphetamines" },
    }) do
        add(values, player, definition[2],
            not missing and finite(addictions[definition[1]], 0, 100) or nil,
            infirmities)
    end

    local caffeineActive = Sources.isActive(Sources.caffeine)
    local caffeineState = type(modData.CaffeineMakesSenseState) == "table"
        and modData.CaffeineMakesSenseState or nil
    local runtime = CaffeineMakesSense and CaffeineMakesSense.Runtime
    local caffeine = nil
    local pureClient = isClient ~= nil and isClient()
        and (isServer == nil or not isServer())
    if not missing and caffeineActive and pureClient then
        local client = CaffeineMakesSense and CaffeineMakesSense.MPClient
        if client and type(client.getSnapshot) == "function" then
            local ok, snapshot = pcall(client.getSnapshot)
            if ok and type(snapshot) == "table" then
                caffeine = finite(snapshot.rawStimLoad, 0, 100)
                if caffeine ~= nil then
                    values.caffeine_load_max = StatUtils.round2(
                        finite(snapshot.maxCaffeine, 0.01, 100)) or 4
                end
            end
        end
    elseif not missing and caffeineActive and caffeineState ~= nil and runtime
        and type(runtime.getLoadTotals) == "function"
        and type(runtime.getWorldAgeMinutes) == "function"
        and type(runtime.getOptions) == "function" then
        local ok, load, maxLoad = pcall(function()
            local options = runtime.getOptions()
            return runtime.getLoadTotals(caffeineState,
                runtime.getWorldAgeMinutes(), options), options.MaxCaffeineLevel
        end)
        if ok then caffeine = finite(load, 0, 100) end
        if caffeine ~= nil then
            values.caffeine_load_max = StatUtils.round2(
                finite(maxLoad, 0.01, 100)) or 4
        end
    end
    add(values, player, "caffeine_load", caffeine, caffeineActive)
    if values.caffeine_load ~= nil then
        if values.caffeine_load_max ~= nil then
            caffeineMaximums[player] = values.caffeine_load_max
        else
            values.caffeine_load_max = caffeineMaximums[player] or 4
        end
    elseif not caffeineActive then
        caffeineMaximums[player] = nil
    end
    local casualties = Sources.isActive(Sources.casualties)
    local drugs = CasualtiesUndead and CasualtiesUndead.Drugs
    if not missing and casualties and drugs
        and type(drugs.euphoria) == "function" then
        local ok, euphoria = pcall(drugs.euphoria, player)
        if ok and (type(modData.CU_Drug) == "table"
            or (type(euphoria) == "number" and euphoria > 0)) then
            add(values, player, "casualties_euphoria",
                finite(euphoria, 0, 1), true)
        end
    end
    if values.lifestyle_hygiene_need == nil
        and values.lifestyle_embarrassment == nil
        and values.lifestyle_comfort_need == nil
        and values.lifestyle_beauty_need == nil
        and values.tasab_body_grime == nil
        and values.bydt_dental_hygiene == nil
        and values.drugtime_stoned == nil
        and values.drugtime_hard == nil
        and values.addiction_alcohol == nil
        and values.addiction_nicotine == nil
        and values.addiction_caffeine == nil
        and values.addiction_painkillers == nil
        and values.addiction_sleeping_pills == nil
        and values.addiction_amphetamines == nil
        and values.caffeine_load == nil
        and values.casualties_euphoria == nil then
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

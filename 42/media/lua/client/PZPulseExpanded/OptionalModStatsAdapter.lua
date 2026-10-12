-- Read-only compatibility adapters for optional continuous mod stats.
--
-- Every value is independent: unavailable mods stay hidden, while active
-- sources publish per-bar health and a zero placeholder until first data.

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

local function add(values, health, player, key, raw, active, problem, minimum, maximum)
    local parsed = StatUtils.finiteNumber(raw)
    local outOfRange = parsed ~= nil and minimum ~= nil
        and (parsed < minimum or parsed > maximum)
    if outOfRange then raw = nil end
    local value, status = StatUtils.sample(player, key, raw, active, false,
        problem == true or outOfRange
            or (raw ~= nil and StatUtils.finiteNumber(raw) == nil))
    health[key] = status
    if value ~= nil then
        values[key] = value
    elseif status == "waiting" then
        values[key] = 0
    end
    return status
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

local function collectValues(player, modData, missing, sourceProblem)
    local values = {}
    local health = {}
    local teeth = type(modData.BrushYourDamnTeeth) == "table"
        and modData.BrushYourDamnTeeth or {}
    local hygieneRaw = not missing and modData.hygieneNeed or nil
    add(values, health, player, "lifestyle_hygiene_need",
        hygieneRaw,
        Sources.isActive(Sources.lifestyle) and not lifestyleHygieneHidden(),
        sourceProblem, 0, 100)
    local lifestyle = Sources.isActive(Sources.lifestyle)
    local moodles = type(modData.LSMoodles) == "table" and modData.LSMoodles or {}
    local embarrassed = type(moodles.Embarrassed) == "table"
        and moodles.Embarrassed or {}
    local embarrassedRaw = not missing and embarrassed.Value or nil
    local embarrassedValue = finite(embarrassedRaw, 0, 1)
    add(values, health, player, "lifestyle_embarrassment",
        embarrassedValue, lifestyle, sourceProblem
            or (embarrassedRaw ~= nil and embarrassedValue == nil))
    local comfortRaw = not missing and modData.ComfortNeed or nil
    local comfortValue = finite(comfortRaw, 0, 1)
    add(values, health, player, "lifestyle_comfort_need",
        comfortValue, lifestyle, sourceProblem
            or (comfortRaw ~= nil and comfortValue == nil))
    local beautyRaw = not missing and modData.BeautyNeed or nil
    local beautyValue = finite(beautyRaw, 0, 100)
    add(values, health, player, "lifestyle_beauty_need",
        beautyValue, lifestyle, sourceProblem
            or (beautyRaw ~= nil and beautyValue == nil))
    add(values, health, player, "tasab_body_grime",
        not missing and modData.tabas_BodyGrime or nil, Sources.isActive(Sources.tasab), sourceProblem,
        0, 100)
    add(values, health, player, "bydt_dental_hygiene",
        not missing and teeth.dentalHygiene or nil, Sources.isActive(Sources.teeth), sourceProblem,
        0, 1)
    local drugTime = Sources.isActive(Sources.drugtime)
    local stoned = not missing and finite(modData.DT_Stoned, 0, 140) or nil
    local hard = not missing and finite(modData.DT_HardDrug, 0, 160) or nil
    add(values, health, player, "drugtime_stoned", stoned, drugTime,
        sourceProblem or (modData.DT_Stoned ~= nil and stoned == nil))
    add(values, health, player, "drugtime_hard", hard, drugTime,
        sourceProblem or (modData.DT_HardDrug ~= nil and hard == nil))

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
        local raw = addictions[definition[1]]
        local value = not missing and finite(raw, 0, 100) or nil
        add(values, health, player, definition[2], value, infirmities,
            sourceProblem or (raw ~= nil and value == nil))
    end

    local caffeineActive = Sources.isActive(Sources.caffeine)
    local caffeineState = type(modData.CaffeineMakesSenseState) == "table"
        and modData.CaffeineMakesSenseState or nil
    local runtime = CaffeineMakesSense and CaffeineMakesSense.Runtime
    local caffeine = nil
    local caffeineProblem = sourceProblem == true
    local pureClient = isClient ~= nil and isClient()
        and (isServer == nil or not isServer())
    if not missing and caffeineActive and pureClient then
        local client = CaffeineMakesSense and CaffeineMakesSense.MPClient
        if client and type(client.getSnapshot) == "function" then
            local ok, snapshot = pcall(client.getSnapshot)
            if ok and type(snapshot) == "table" then
                caffeine = finite(snapshot.rawStimLoad, 0, 100)
                caffeineProblem = snapshot.rawStimLoad ~= nil and caffeine == nil
                if caffeine ~= nil then
                    values.caffeine_load_max = StatUtils.round2(
                        finite(snapshot.maxCaffeine, 0.01, 100)) or 4
                end
            elseif not ok then
                caffeineProblem = true
            end
        else
            caffeineProblem = true
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
        caffeineProblem = not ok or (load ~= nil and caffeine == nil)
        if caffeine ~= nil then
            values.caffeine_load_max = StatUtils.round2(
                finite(maxLoad, 0.01, 100)) or 4
        end
    elseif not missing and caffeineActive and caffeineState ~= nil then
        caffeineProblem = true
    end
    add(values, health, player, "caffeine_load", caffeine, caffeineActive,
        caffeineProblem)
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
    local euphoria, euphoriaProblem
    if not missing and casualties and drugs and type(drugs.euphoria) == "function" then
        local ok, rawEuphoria = pcall(drugs.euphoria, player)
        if ok then
            euphoria = finite(rawEuphoria, 0, 1)
            euphoriaProblem = euphoria == nil
        else
            euphoriaProblem = true
        end
    elseif casualties then
        euphoriaProblem = true
    end
    add(values, health, player, "casualties_euphoria", euphoria, casualties,
        euphoriaProblem or sourceProblem)
    for _, status in pairs(health) do
        if status ~= "unavailable" then return values, health end
    end
    return nil, health
end

function Adapter.collect(player)
    if player == nil then return nil end
    local modData, problem = nil, false
    if player.getModData ~= nil then
        local ok, data = pcall(player.getModData, player)
        if ok and type(data) == "table" then modData = data else problem = true end
    else
        problem = true
    end
    return collectValues(player, modData or {}, false, problem)
end

function Adapter.missing(player, problem)
    if player == nil then return nil end
    return collectValues(player, {}, true, problem)
end

return Adapter

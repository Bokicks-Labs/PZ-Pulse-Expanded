-- Read-only collector for active moodles exposed by installed optional mods.
--
-- The collector never creates a moodle or initializes source-mod state. It
-- reads existing tables only and omits inactive, missing, or malformed items.

PZPulseExpanded_CustomMoodleAdapter =
    PZPulseExpanded_CustomMoodleAdapter or {}

local Adapter = PZPulseExpanded_CustomMoodleAdapter
local ModSources = require("PZPulseExpanded/ModSources")

local SOURCES = {
    lifestyle = ModSources.lifestyle,
    tasab = ModSources.tasab,
    infirmities = ModSources.infirmities,
    medicine = ModSources.medicine,
    teeth = ModSources.teeth,
    mutants = ModSources.mutants,
    drugtime = ModSources.drugtime,
    casualties = ModSources.casualties,
    natures_call = ModSources.naturesCall,
    bodily_functions = ModSources.bodilyFunctions,
    moodle_framework = ModSources.moodleFramework,
}

local MOODLE_FRAMEWORK_SOURCES = {
    Defecation = SOURCES.bodily_functions,
    Urination = SOURCES.bodily_functions,
    PoopedSelf = SOURCES.bodily_functions,
    PeedSelf = SOURCES.bodily_functions,
    BodilyFumes = SOURCES.bodily_functions,
    Wet_Bathing = SOURCES.tasab,
    CoolingBody = SOURCES.tasab,
    WarmingBody = SOURCES.tasab,
    FeelingGaze = SOURCES.tasab,
    BodyGrime = SOURCES.tasab,

    PanicAttack = SOURCES.infirmities,
    Tremors = SOURCES.infirmities,
    AddictedToAlcohol = SOURCES.infirmities,
    AddictedToNicotine = SOURCES.infirmities,
    AddictedToPainkillers = SOURCES.infirmities,
    AddictedToCaffeine = SOURCES.infirmities,
    AddictedToSleepingPills = SOURCES.infirmities,
    AddictedToAmp = SOURCES.infirmities,
    Withdrawal = SOURCES.infirmities,

    Antibiotics = SOURCES.medicine,
    Antidepressants = SOURCES.medicine,
    BetaBlockers = SOURCES.medicine,
    Painkillers = SOURCES.medicine,
    SleepingTablets = SOURCES.medicine,
    LemonGrass = SOURCES.medicine,

    BYDT_MouthState = SOURCES.teeth,
    PZTheMutants_Puked = SOURCES.mutants,
}

local NATURES_CALL_MOODLES = {
    { name = "NCUnknownPants", key = "unknownPants", valence = "bad", maxLevel = 1 },
    { name = "NCBladder", key = "bladder", valence = "bad", maxLevel = 3 },
    { name = "NCBowel", key = "bowel", valence = "bad", maxLevel = 3 },
    { name = "NCSoilage", key = "soilage", valence = "bad", maxLevel = 3 },
    { name = "NCSmell", key = "nearbySmell", valence = "bad", maxLevel = 3 },
    { name = "NCGut", key = "gut", signed = true, maxLevel = 3 },
    { name = "NCCramps", key = "cramps", valence = "bad", maxLevel = 3 },
    { name = "NCHeartburn", key = "heartburn", valence = "bad", maxLevel = 3 },
}

local function isActive(modId)
    return ModSources.isActive(modId)
end

local function normalizeLevel(value, maxLevel)
    local level = tonumber(value)
    if level == nil or level ~= level then return nil end

    level = math.floor(math.abs(level))
    maxLevel = tonumber(maxLevel) or 4
    if level < 1 then return nil end
    if level > maxLevel then level = maxLevel end
    return level
end

local function humanize(name)
    local text = tostring(name or "")
    text = text:gsub("_", " ")
    text = text:gsub("(%l)(%u)", "%1 %2")
    text = text:gsub("^NC", "")
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    return text ~= "" and text or "Modded Moodle"
end

local function translated(key, fallback)
    if getText == nil then return fallback end

    local ok, value = pcall(getText, key)
    if not ok or type(value) ~= "string" or value == "" or value == key then
        return fallback
    end

    return value
end

local function tableText(root, valence, level)
    if type(root) ~= "table" then return nil end

    local alignment = valence == "good" and 1 or 2
    local values = root[alignment]
    if type(values) ~= "table" then return nil end

    local value = values[level]
    if type(value) ~= "string" or value == "" then return nil end
    return value
end

local function addMoodle(result, seen, moodle)
    if type(moodle) ~= "table" or type(moodle.source) ~= "table" then return end

    local id = tostring(moodle.id or "")
    local label = tostring(moodle.label or "")
    local level = normalizeLevel(moodle.level, moodle.maxLevel)
    local maxLevel = tonumber(moodle.maxLevel) or 4

    if id == "" or label == "" or level == nil then return end
    if moodle.valence ~= "good" and moodle.valence ~= "bad" then return end
    if seen[id] then return end

    seen[id] = true
    result[#result + 1] = {
        id = id,
        label = label,
        description = moodle.description,
        level = level,
        maxLevel = maxLevel,
        valence = moodle.valence,
        iconKey = moodle.iconKey,
        source = moodle.source,
    }
end

local function lifestyleIconKey(name, state, level)
    local filename = tostring(name)
    local tiers = tonumber(state.Tiers) or 0
    local iconMode = tonumber(state.Icon) or 0

    if iconMode ~= 1 and iconMode ~= 3 then
        if level == 4 and tiers == 3 then
            filename = filename .. "3"
        elseif level >= 3 and tiers >= 2 then
            filename = filename .. "2"
        elseif level >= 2 and tiers >= 1 then
            filename = filename .. "1"
        end
    end
    return "lifestyle/" .. filename
end

local function moodleFrameworkIconKey(source, name)
    local folders = {
        [SOURCES.bodily_functions.id] = "bodily-functions",
        [SOURCES.tasab.id] = "tasab",
        [SOURCES.infirmities.id] = "infirmities",
        [SOURCES.medicine.id] = "medicine",
        [SOURCES.teeth.id] = "teeth",
        [SOURCES.mutants.id] = "mutants",
    }
    local folder = folders[source.id]
    if folder == nil then return nil end
    return folder .. "/" .. tostring(name)
end

local function collectLifestyle(player, result, seen)
    if not isActive(SOURCES.lifestyle.id) then return end

    local modData = player:getModData()
    local moodles = type(modData) == "table" and modData.LSMoodles or nil
    if type(moodles) ~= "table" then return end

    for name, state in pairs(moodles) do
        if type(state) == "table" then
            local level = normalizeLevel(state.Level, 4)
            local alignment = state.Alignment
            local valence = alignment == "Good" and "good"
                or alignment == "Bad" and "bad"
                or nil

            if level ~= nil and valence ~= nil then
                local labelKey = "Moodles_" .. tostring(name) .. "_L" .. tostring(level)
                local descKey = labelKey .. "_desc"
                addMoodle(result, seen, {
                    id = SOURCES.lifestyle.id .. ":" .. tostring(name),
                    label = translated(labelKey, humanize(name)),
                    description = translated(descKey, nil),
                    level = level,
                    maxLevel = 4,
                    valence = valence,
                    iconKey = lifestyleIconKey(name, state, level),
                    source = SOURCES.lifestyle,
                })
            end
        end
    end
end

local function collectMoodleFramework(player, result, seen)
    if not isActive("MoodleFramework") or type(MF) ~= "table" then return end
    if type(MF.MoodlesStorage) ~= "table" or type(MF.MoodleData) ~= "table" then return end

    local playerNum = player:getPlayerNum()
    local objects = MF.MoodlesStorage[playerNum]
    local dataRoot = MF.MoodleData[tostring(player)]
    local states = type(dataRoot) == "table" and dataRoot.Moodles or nil
    if type(objects) ~= "table" or type(states) ~= "table" then return end

    for name, object in pairs(objects) do
        local state = states[name]
        if type(state) == "table" and not (type(object) == "table" and object.disable) then
            local level = normalizeLevel(state.Level, 4)
            local alignment = tonumber(state.GoodBadNeutral)
            local valence = alignment == 1 and "good"
                or alignment == 2 and "bad"
                or nil

            if level ~= nil and valence ~= nil then
                local source = MOODLE_FRAMEWORK_SOURCES[name]
                    or SOURCES.moodle_framework
                local alignmentText = valence == "good" and "Good" or "Bad"
                local titleKey = "Moodles_" .. tostring(name) .. "_"
                    .. alignmentText .. "_lvl" .. tostring(level)
                local descKey = "Moodles_" .. tostring(name) .. "_"
                    .. alignmentText .. "_desc_lvl" .. tostring(level)
                local objectTitle = type(object) == "table"
                    and tableText(object.title, valence, level)
                    or nil
                local objectDescription = type(object) == "table"
                    and tableText(object.desc, valence, level)
                    or nil

                addMoodle(result, seen, {
                    id = source.id .. ":" .. tostring(name),
                    label = objectTitle or translated(titleKey, humanize(name)),
                    description = objectDescription or translated(descKey, nil),
                    level = level,
                    maxLevel = 4,
                    valence = valence,
                    iconKey = moodleFrameworkIconKey(source, name),
                    source = source,
                })
            end
        end
    end
end

local function collectMedicineMoodles(player, result, seen)
    if not isActive(SOURCES.medicine.id) then return end
    if type(ModMedicineMoodles) ~= "table"
        or type(ModMedicineMoodles.PlayerMoodles) ~= "table" then return end

    local objects = ModMedicineMoodles.PlayerMoodles[player:getPlayerNum()]
    if type(objects) ~= "table" then return end

    for name, object in pairs(objects) do
        if type(object) == "table"
            and type(object.getLevel) == "function"
            and type(object.getGoodBadNeutral) == "function" then
            local level = normalizeLevel(object:getLevel(), 4)
            local alignment = tonumber(object:getGoodBadNeutral())
            local valence = alignment == 1 and "good"
                or alignment == 2 and "bad"
                or nil

            if level ~= nil and valence ~= nil then
                local title = type(object.getTitle) == "function"
                    and object:getTitle(alignment, level)
                    or nil
                local description = type(object.getDescription) == "function"
                    and object:getDescription(alignment, level)
                    or nil
                addMoodle(result, seen, {
                    id = SOURCES.medicine.id .. ":" .. tostring(name),
                    label = title or humanize(name),
                    description = description,
                    level = level,
                    maxLevel = 4,
                    valence = valence,
                    iconKey = "medicine/" .. tostring(name),
                    source = SOURCES.medicine,
                })
            end
        end
    end
end

local function collectDrugTime(player, result, seen)
    if not isActive(SOURCES.drugtime.id) then return end

    local modData = player:getModData()
    if type(modData) ~= "table" then return end

    local definitions = {
        { name = "Stoned", level = modData.DT_StonedStage, valence = "good" },
        { name = "Hard", level = modData.DT_HardStage, valence = "bad" },
    }

    for _, definition in ipairs(definitions) do
        local level = normalizeLevel(definition.level, 3)
        if level ~= nil then
            local alignment = definition.valence == "good" and "Good" or "Bad"
            local titleKey = "Moodles_" .. definition.name .. "_"
                .. alignment .. "_lvl" .. tostring(level)
            local descKey = "Moodles_" .. definition.name .. "_"
                .. alignment .. "_desc_lvl" .. tostring(level)

            addMoodle(result, seen, {
                id = SOURCES.drugtime.id .. ":" .. definition.name,
                label = translated(titleKey, humanize(definition.name)),
                description = translated(descKey, nil),
                level = level,
                maxLevel = 3,
                valence = definition.valence,
                iconKey = "drugtime/DT_" .. definition.name .. "_" .. tostring(level),
                source = SOURCES.drugtime,
            })
        end
    end
end

local function isPureMultiplayerClient()
    if isClient == nil or isServer == nil then return false end
    return isClient() and not isServer()
end

local function collectNaturesCall(player, result, seen)
    if not isActive(SOURCES.natures_call.id) then return end

    local modData = player:getModData()
    local state = type(modData) == "table" and modData.NaturesCall or nil
    if type(state) ~= "table" then return end

    local snapshot = state
    if isPureMultiplayerClient() then
        if type(state.ownerSnapshot) ~= "table" then return end
        snapshot = state.ownerSnapshot
    end

    local states = snapshot.moodles
    if type(states) ~= "table" then return end

    local traits = snapshot.traitModifiers or state.traitModifiers or {}

    for _, definition in ipairs(NATURES_CALL_MOODLES) do
        local rawLevel = tonumber(states[definition.key])
        local hidden = (definition.name == "NCBladder"
                and traits.majorBladderIncontinence == true)
            or (definition.name == "NCBowel"
                and traits.majorBowelIncontinence == true)

        if rawLevel ~= nil and not hidden then
            local valence = definition.valence
            if definition.signed then
                valence = rawLevel > 0 and "good"
                    or rawLevel < 0 and "bad"
                    or nil
            end

            local level = normalizeLevel(rawLevel, definition.maxLevel)
            if level ~= nil and valence ~= nil then
                local alignment = valence == "good" and "Good" or "Bad"
                local titleKey = "Moodles_" .. definition.name .. "_"
                    .. alignment .. "_lvl" .. tostring(level)
                local descKey = "Moodles_" .. definition.name .. "_"
                    .. alignment .. "_desc_lvl" .. tostring(level)

                addMoodle(result, seen, {
                    id = SOURCES.natures_call.id .. ":" .. definition.name,
                    label = translated(titleKey, humanize(definition.name)),
                    description = translated(descKey, nil),
                    level = level,
                    maxLevel = definition.maxLevel,
                    valence = valence,
                    iconKey = definition.name == "NCSmell"
                        and "mood_noxioussmell"
                        or definition.name == "NCGut"
                            and (valence == "good"
                                and "natures-call/NCGutGood"
                                or "natures-call/NCGutBad")
                            or "natures-call/" .. definition.name,
                    source = SOURCES.natures_call,
                })
            end
        end
    end
end

local function collectCasualtiesUndead(player, result, seen)
    if not isActive(SOURCES.casualties.id) then return end
    local cu = CasualtiesUndead
    if type(cu) ~= "table" then return end
    if cu.Options and type(cu.Options.showMoodles) == "function" then
        local ok, shown = pcall(cu.Options.showMoodles)
        if not ok or not shown then return end
    end

    local drugs = cu.Drugs
    if type(drugs) == "table" and type(drugs.highLevel) == "function" then
        local ok, level = pcall(drugs.highLevel, player)
        if ok then
            level = normalizeLevel(level, 4)
            if level ~= nil then
                local key = "IGUI_CU_Moodle_High_" .. tostring(level)
                addMoodle(result, seen, {
                    id = SOURCES.casualties.id .. ":High",
                    label = translated(key, "High"),
                    description = translated(key .. "_Desc", nil),
                    level = level, maxLevel = 4, valence = "good",
                    iconKey = "casualties-undead/High",
                    source = SOURCES.casualties,
                })
            end
        end
    end

    local mind = cu.Mind
    if type(mind) == "table" and type(mind.isMiserable) == "function" then
        local ok, miserable = pcall(mind.isMiserable, player)
        if ok and miserable then
            addMoodle(result, seen, {
                id = SOURCES.casualties.id .. ":Miserable",
                label = translated("IGUI_CU_Moodle_Miserable", "Miserable"),
                description = translated("IGUI_CU_Moodle_Miserable_Desc", nil),
                level = 1, maxLevel = 1, valence = "bad",
                iconKey = "casualties-undead/Miserable",
                source = SOURCES.casualties,
            })
        end
    end

    local conditions = cu.Conditions
    if type(conditions) ~= "table"
        or type(conditions.enabled) ~= "function"
        or type(conditions.worst) ~= "function" then return end
    local enabledOk, enabled = pcall(conditions.enabled)
    if not enabledOk or not enabled then return end
    local worstOk, worst = pcall(conditions.worst, player)
    if not worstOk or type(worst) ~= "table"
        or type(worst.id) ~= "string" then return end
    local level = normalizeLevel(worst.grade, 3)
    if level == nil then return end
    local modData = player:getModData()
    local known = type(modData) == "table" and modData.CU_Terms or nil
    local clinical = type(known) == "table" and known[worst.id] == true
    local terms = cu.Terms
    if type(terms) == "table" and type(terms.enabled) == "function" then
        local ok, termSystem = pcall(terms.enabled)
        if ok and not termSystem then clinical = true end
    end
    local labelPrefix = clinical and "IGUI_CU_Cond_" or "IGUI_CU_Lay_"
    local descPrefix = clinical and "IGUI_CU_Why_" or "IGUI_CU_LayWhy_"
    local organ = "Blood"
    if type(conditions.organOf) == "function" then
        local ok, resultOrgan = pcall(conditions.organOf, worst.id)
        if ok and type(resultOrgan) == "string" then organ = resultOrgan end
    end
    addMoodle(result, seen, {
        id = SOURCES.casualties.id .. ":Condition",
        label = translated(labelPrefix .. worst.id, humanize(worst.id)),
        description = translated(descPrefix .. worst.id, nil),
        level = level, maxLevel = 3, valence = "bad",
        iconKey = "casualties-undead/Organ_" .. organ,
        source = SOURCES.casualties,
    })
end

local COLLECTORS = {
    collectLifestyle,
    collectMoodleFramework,
    collectMedicineMoodles,
    collectDrugTime,
    collectNaturesCall,
    collectCasualtiesUndead,
}

function Adapter.collect(player)
    if player == nil or player.getModData == nil then return nil end

    local result = {}
    local seen = {}

    -- A compatibility edge in one source must not suppress moodles from the
    -- other installed mods. These catches stay source-local and read-only.
    for _, collector in ipairs(COLLECTORS) do
        pcall(collector, player, result, seen)
    end

    if #result == 0 then return nil end

    table.sort(result, function(left, right)
        return left.id < right.id
    end)
    return result
end

return Adapter

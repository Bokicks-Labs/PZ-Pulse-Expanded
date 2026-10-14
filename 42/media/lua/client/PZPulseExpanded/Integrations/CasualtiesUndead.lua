-- Source-owned optional stat reader. Reads existing state only.
local Sources = require("PZPulseExpanded/Core/Sources")
local Row = require("PZPulseExpanded/Core/StatRow")
local add, finite = Row.add, Row.finite
local Integration = {}
Integration.source = Sources.casualties
Integration.statKeys = { "casualties_euphoria" }

function Integration.isAvailable()
    return Sources.isActive(Sources.casualties)
end

function Integration.collectStats(player, modData, missing, sourceProblem, values, health)
    local casualties = Integration.isAvailable()
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
end

local Moodles = require("PZPulseExpanded/Moodles/Utils")
local normalizeLevel, humanize, translated, addMoodle =
    Moodles.normalizeLevel, Moodles.humanize, Moodles.translated, Moodles.addMoodle

function Integration.collectMoodles(player, result, seen)
    if not Integration.isAvailable() then return end
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
                    id = Integration.source.id .. ":High",
                    label = translated(key, "High"),
                    description = translated(key .. "_Desc", nil),
                    level = level, maxLevel = 4, valence = "good",
                    iconKey = "casualties-undead/High",
                    source = Integration.source,
                })
            end
        end
    end

    local mind = cu.Mind
    if type(mind) == "table" and type(mind.isMiserable) == "function" then
        local ok, miserable = pcall(mind.isMiserable, player)
        if ok and miserable then
            addMoodle(result, seen, {
                id = Integration.source.id .. ":Miserable",
                label = translated("IGUI_CU_Moodle_Miserable", "Miserable"),
                description = translated("IGUI_CU_Moodle_Miserable_Desc", nil),
                level = 1, maxLevel = 1, valence = "bad",
                iconKey = "casualties-undead/Miserable",
                source = Integration.source,
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
        id = Integration.source.id .. ":Condition",
        label = translated(labelPrefix .. worst.id, humanize(worst.id)),
        description = translated(descPrefix .. worst.id, nil),
        level = level, maxLevel = 3, valence = "bad",
        iconKey = "casualties-undead/Organ_" .. organ,
        source = Integration.source,
    })
end


return Integration

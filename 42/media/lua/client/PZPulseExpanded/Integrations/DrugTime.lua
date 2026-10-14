-- Source-owned optional stat reader. Reads existing state only.
local Sources = require("PZPulseExpanded/Core/Sources")
local Row = require("PZPulseExpanded/Core/StatRow")
local add, finite = Row.add, Row.finite
local Integration = {}
Integration.source = Sources.drugtime
Integration.statKeys = { "drugtime_stoned", "drugtime_hard" }

function Integration.isAvailable()
    return Sources.isActive(Sources.drugtime)
end

function Integration.collectStats(player, modData, missing, sourceProblem, values, health)
    local drugTime = Integration.isAvailable()
    local stoned = not missing and finite(modData.DT_Stoned, 0, 140) or nil
    local hard = not missing and finite(modData.DT_HardDrug, 0, 160) or nil
    add(values, health, player, "drugtime_stoned", stoned, drugTime,
        sourceProblem or (modData.DT_Stoned ~= nil and stoned == nil))
    add(values, health, player, "drugtime_hard", hard, drugTime,
        sourceProblem or (modData.DT_HardDrug ~= nil and hard == nil))
end

local Moodles = require("PZPulseExpanded/Moodles/Utils")
local normalizeLevel, humanize, translated, addMoodle =
    Moodles.normalizeLevel, Moodles.humanize, Moodles.translated, Moodles.addMoodle

function Integration.collectMoodles(player, result, seen)
    if not Integration.isAvailable() then return end

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
                id = Integration.source.id .. ":" .. definition.name,
                label = translated(titleKey, humanize(definition.name)),
                description = translated(descKey, nil),
                level = level,
                maxLevel = 3,
                valence = definition.valence,
                iconKey = "drugtime/DT_" .. definition.name .. "_" .. tostring(level),
                source = Integration.source,
            })
        end
    end
end


return Integration

-- Source-owned optional stat reader. Reads existing state only.
local Sources = require("PZPulseExpanded/Core/Sources")
local Row = require("PZPulseExpanded/Core/StatRow")
local add = Row.add
local Integration = {}
Integration.source = Sources.teeth
Integration.statKeys = { "bydt_dental_hygiene" }

function Integration.isAvailable()
    return Sources.isActive(Sources.teeth)
end

function Integration.collectStats(player, modData, missing, sourceProblem, values, health)
    local teeth = type(modData.BrushYourDamnTeeth) == "table"
        and modData.BrushYourDamnTeeth or {}
    add(values, health, player, "bydt_dental_hygiene",
        not missing and teeth.dentalHygiene or nil, Integration.isAvailable(), sourceProblem,
        0, 1)
end

Integration.iconFolder = "teeth"
Integration.frameworkMoodles = { "BYDT_MouthState" }

return Integration

-- Source-owned optional stat reader. Reads existing state only.
local Sources = require("PZPulseExpanded/Core/Sources")
local Row = require("PZPulseExpanded/Core/StatRow")
local add = Row.add
local Integration = {}
Integration.source = Sources.tasab
Integration.statKeys = { "tasab_body_grime" }

function Integration.isAvailable()
    return Sources.isActive(Sources.tasab)
end

function Integration.collectStats(player, modData, missing, sourceProblem, values, health)
    add(values, health, player, "tasab_body_grime",
        not missing and modData.tabas_BodyGrime or nil, Integration.isAvailable(), sourceProblem,
        0, 100)
end

Integration.iconFolder = "tasab"
Integration.frameworkMoodles = { "Wet_Bathing", "CoolingBody", "WarmingBody", "FeelingGaze", "BodyGrime" }

return Integration

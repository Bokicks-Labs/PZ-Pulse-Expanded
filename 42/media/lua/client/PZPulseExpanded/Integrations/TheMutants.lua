-- The Mutants currently exposes one Moodle Framework registration.
local Sources = require("PZPulseExpanded/Core/Sources")
return { source = Sources.mutants, iconFolder = "mutants",
    frameworkMoodles = { "PZTheMutants_Puked" } }

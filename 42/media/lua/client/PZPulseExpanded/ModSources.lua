-- Canonical source-mod metadata for the built-in compatibility adapters.
-- Bar availability is listed here so the collector can publish it to the
-- browser even when a source currently has no valid stat reading.
PZPulseExpanded_ModSources = PZPulseExpanded_ModSources or {}

local Sources = PZPulseExpanded_ModSources

Sources.naturesCall = Sources.naturesCall or {
    type = "mod", id = "NC_NaturesCall", name = "Nature's Call",
}
Sources.bodilyFunctions = Sources.bodilyFunctions or {
    type = "mod", id = "bodilyfunctions", name = "Bodily Functions",
}
Sources.lifestyle = Sources.lifestyle or {
    type = "mod", id = "LifestyleHobbies", name = "Lifestyle: Hobbies",
}
Sources.tasab = Sources.tasab or {
    type = "mod", id = "TakeABathAndShowerNew", name = "Take A Bath And Shower",
}
Sources.teeth = Sources.teeth or {
    type = "mod", id = "BrushYourDamnTeeth", name = "Brush Your Damn Teeth",
}
Sources.drugtime = Sources.drugtime or {
    type = "mod", id = "DrugTime89", name = "DrugTime 89",
}
Sources.infirmities = Sources.infirmities or {
    type = "mod", id = "twbInfirmities", name = "Infirmities",
}
Sources.caffeine = Sources.caffeine or {
    type = "mod", id = "CaffeineMakesSense", name = "Caffeine Makes Sense",
}
Sources.casualties = Sources.casualties or {
    type = "mod", id = "CasualtiesUndead", name = "Casualties Undead",
}
Sources.medicine = Sources.medicine or {
    type = "mod", id = "MedicineMoodlesB42", name = "Medicine Moodles",
}
Sources.mutants = Sources.mutants or {
    type = "mod", id = "PZTheMutants", name = "The Mutants",
}
Sources.moodleFramework = Sources.moodleFramework or {
    type = "mod", id = "MoodleFramework", name = "Moodle Framework add-on",
}
Sources.barSources = Sources.barSources or {
    Sources.naturesCall,
    Sources.bodilyFunctions,
    Sources.lifestyle,
    Sources.tasab,
    Sources.teeth,
    Sources.drugtime,
    Sources.infirmities,
    Sources.caffeine,
    Sources.casualties,
}

local function activatedMods()
    if getActivatedMods == nil then return nil end
    return getActivatedMods()
end

function Sources.isActive(source)
    local modId = type(source) == "table" and source.id or source
    local mods = activatedMods()
    return modId ~= nil and mods ~= nil and mods.contains ~= nil
        and mods:contains(modId) or false
end

function Sources.barAvailability()
    local active = {}
    for _, source in ipairs(Sources.barSources) do
        active[source.id] = Sources.isActive(source)
    end

    local infirmities = Sources.infirmities
    if active[Sources.bodilyFunctions.id] then
        active[Sources.bodilyFunctions.id] = SandboxVars == nil
            or SandboxVars.BF == nil
            or SandboxVars.BF.EnableUrination ~= false
            or SandboxVars.BF.EnableDefecation ~= false
    end
    if active[infirmities.id] then
        active[infirmities.id] = SandboxVars ~= nil
            and SandboxVars.Infirmities ~= nil
            and SandboxVars.Infirmities.StartAddictiveSystem == true
    end
    return active
end

return Sources

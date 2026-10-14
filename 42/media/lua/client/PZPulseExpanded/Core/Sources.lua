-- Canonical source-mod metadata for the built-in compatibility adapters.
-- The panel publishes availability even when a source has no valid reading.
local Sources = {}

Sources.naturesCall = {
    type = "mod", id = "NC_NaturesCall", name = "Nature's Call",
}
Sources.bodilyFunctions = {
    type = "mod", id = "bodilyfunctions", name = "Bodily Functions",
}
Sources.lifestyle = {
    type = "mod", id = "LifestyleHobbies", name = "Lifestyle: Hobbies",
}
Sources.tasab = {
    type = "mod", id = "TakeABathAndShowerNew", name = "Take A Bath And Shower",
}
Sources.teeth = {
    type = "mod", id = "BrushYourDamnTeeth", name = "Brush Your Damn Teeth",
}
Sources.drugtime = {
    type = "mod", id = "DrugTime89", name = "DrugTime 89",
}
Sources.infirmities = {
    type = "mod", id = "twbInfirmities", name = "Infirmities",
}
Sources.caffeine = {
    type = "mod", id = "CaffeineMakesSense", name = "Caffeine Makes Sense",
}
Sources.casualties = {
    type = "mod", id = "CasualtiesUndead", name = "Casualties Undead",
}
Sources.medicine = {
    type = "mod", id = "MedicineMoodlesB42", name = "Medicine Moodles",
}
Sources.mutants = {
    type = "mod", id = "PZTheMutants", name = "The Mutants",
}
Sources.moodleFramework = {
    type = "mod", id = "MoodleFramework", name = "Moodle Framework add-on",
}
Sources.barSources = {
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

function Sources.isActive(source)
    local modId = type(source) == "table" and source.id or source
    local mods = getActivatedMods and getActivatedMods() or nil
    return modId ~= nil and mods ~= nil and mods.contains ~= nil
        and mods:contains(modId) or false
end

return Sources

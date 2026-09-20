package.path = "42/media/lua/client/?.lua;" .. package.path

local active = {
    LifestyleHobbies = true,
    TakeABathAndShowerNew = true,
    BrushYourDamnTeeth = true,
    MoodleFramework = true,
    DrugTime89 = true,
    NC_NaturesCall = true,
}

function getActivatedMods()
    return {
        contains = function(_, modId)
            return active[modId] == true
        end,
    }
end

function getText(key)
    local translations = {
        Moodles_MindfulState_L2 = "Mindful",
        Moodles_MindfulState_L2_desc = "Calm and focused.",
        Moodles_BodyGrime_Bad_lvl3 = "Body Grime",
        Moodles_BodyGrime_Bad_desc_lvl3 = "Time to wash.",
        Moodles_Stoned_Good_lvl1 = "Lightly Stoned",
        Moodles_Stoned_Good_desc_lvl1 = "Relaxed.",
        Moodles_NCGut_Bad_lvl2 = "Poor Gut Health",
        Moodles_NCGut_Bad_desc_lvl2 = "Your gut is struggling.",
    }
    return translations[key] or key
end

function isClient() return false end
function isServer() return false end

local modData = {
    hygieneNeed = 67,
    tabas_BodyGrime = 38,
    BrushYourDamnTeeth = { dentalHygiene = 0.82 },
    LSMoodles = {
        MindfulState = { Level = 2, Alignment = "Good", Value = 0.4 },
        Hidden = { Level = 0, Alignment = "Bad", Value = 0 },
        Malformed = { Level = 3, Value = 0.6 },
    },
    DT_StonedStage = 1,
    DT_HardStage = 0,
    NaturesCall = {
        traitModifiers = {},
        moodles = {
            bladder = 0,
            bowel = 0,
            soilage = 0,
            nearbySmell = 0,
            gut = -2,
            cramps = 0,
            heartburn = 0,
            unknownPants = 0,
        },
    },
}

local player = {
    getPlayerNum = function() return 0 end,
    getModData = function() return modData end,
}

MF = {
    MoodlesStorage = {
        [0] = {
            BodyGrime = {},
            UnknownAddonMoodle = {},
            Neutral = {},
        },
    },
    MoodleData = {},
}

MF.MoodleData[tostring(player)] = {
    Moodles = {
        BodyGrime = { Level = 3, GoodBadNeutral = 2, Value = 0.2 },
        UnknownAddonMoodle = { Level = 1, GoodBadNeutral = 1, Value = 0.6 },
        Neutral = { Level = 0, GoodBadNeutral = 0, Value = 0.5 },
    },
}

local statsAdapter = require("PZPulseExpanded/OptionalModStatsAdapter")
local moodleAdapter = require("PZPulseExpanded/CustomMoodleAdapter")

local stats = statsAdapter.collect(player)
assert(stats.lifestyle_hygiene_need == 67)
assert(stats.tasab_body_grime == 38)
assert(stats.bydt_dental_hygiene == 0.82)

local moodles = moodleAdapter.collect(player)
assert(type(moodles) == "table")

local byId = {}
for _, moodle in ipairs(moodles) do
    byId[moodle.id] = moodle
end

assert(byId["LifestyleHobbies:MindfulState"].label == "Mindful")
assert(byId["LifestyleHobbies:Hidden"] == nil)
assert(byId["LifestyleHobbies:Malformed"] == nil)
assert(byId["TakeABathAndShowerNew:BodyGrime"].level == 3)
assert(byId["TakeABathAndShowerNew:BodyGrime"].source.id == "TakeABathAndShowerNew")
assert(byId["MoodleFramework:UnknownAddonMoodle"].source.name == "Moodle Framework add-on")
assert(byId["DrugTime89:Stoned"].valence == "good")
assert(byId["DrugTime89:Hard"] == nil)
assert(byId["NC_NaturesCall:NCGut"].level == 2)
assert(byId["NC_NaturesCall:NCGut"].valence == "bad")

active.LifestyleHobbies = false
active.TakeABathAndShowerNew = false
active.BrushYourDamnTeeth = false

assert(statsAdapter.collect(player) == nil,
    "inactive optional stat mods should yield no values")

print("Optional mod stat and moodle adapter fixtures passed")

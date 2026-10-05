package.path = "42/media/lua/client/?.lua;" .. package.path
local now = 100000
function getTimestampMs() return now end

local active = {
    LifestyleHobbies = true,
    TakeABathAndShowerNew = true,
    BrushYourDamnTeeth = true,
    MoodleFramework = true,
    DrugTime89 = true,
    NC_NaturesCall = true,
    MedicineMoodlesB42 = true,
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
        MindfulState = { Level = 2, Alignment = "Good", Value = 0.4, Tiers = 2, Icon = 0 },
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

ModMedicineMoodles = {
    PlayerMoodles = {
        [0] = {
            LemonGrass = {
                getLevel = function() return 2 end,
                getGoodBadNeutral = function() return 2 end,
                getTitle = function() return "Lemongrass" end,
                getDescription = function() return "The medicine is active." end,
            },
        },
    },
}

local statsAdapter = require("PZPulseExpanded/OptionalModStatsAdapter")
local moodleAdapter = require("PZPulseExpanded/CustomMoodleAdapter")

local stats = statsAdapter.collect(player)
assert(stats.lifestyle_hygiene_need == 67)
assert(stats.tasab_body_grime == 38)
assert(stats.bydt_dental_hygiene == 0.82)

modData.hygieneNeed = nil
modData.tabas_BodyGrime = "bad"
modData.BrushYourDamnTeeth.dentalHygiene = nil
local retained = statsAdapter.collect(player)
assert(retained.lifestyle_hygiene_need == 67)
assert(retained.tasab_body_grime == 38)
assert(retained.bydt_dental_hygiene == 0.82)
now = now + 90001
assert(statsAdapter.collect(player) == nil,
    "persistently missing optional stats should expire")
modData.hygieneNeed = 68
assert(statsAdapter.collect(player).lifestyle_hygiene_need == 68)
active.LifestyleHobbies = false
assert(statsAdapter.collect(player) == nil, "disabled source must clear history")
active.LifestyleHobbies = true
assert(statsAdapter.collect(player).lifestyle_hygiene_need == 68)

local moodles = moodleAdapter.collect(player)
assert(type(moodles) == "table")

local byId = {}
for _, moodle in ipairs(moodles) do
    byId[moodle.id] = moodle
end

assert(byId["LifestyleHobbies:MindfulState"].label == "Mindful")
assert(byId["LifestyleHobbies:MindfulState"].iconKey == "lifestyle/MindfulState1")
assert(byId["LifestyleHobbies:Hidden"] == nil)
assert(byId["LifestyleHobbies:Malformed"] == nil)
assert(byId["TakeABathAndShowerNew:BodyGrime"].level == 3)
assert(byId["TakeABathAndShowerNew:BodyGrime"].source.id == "TakeABathAndShowerNew")
assert(byId["TakeABathAndShowerNew:BodyGrime"].iconKey == "tasab/BodyGrime")
assert(byId["MoodleFramework:UnknownAddonMoodle"].source.name == "Moodle Framework add-on")
assert(byId["MedicineMoodlesB42:LemonGrass"].label == "Lemongrass")
assert(byId["MedicineMoodlesB42:LemonGrass"].iconKey == "medicine/LemonGrass")
assert(byId["DrugTime89:Stoned"].valence == "good")
assert(byId["DrugTime89:Stoned"].iconKey == "drugtime/DT_Stoned_1")
assert(byId["DrugTime89:Hard"] == nil)
assert(byId["NC_NaturesCall:NCGut"].level == 2)
assert(byId["NC_NaturesCall:NCGut"].valence == "bad")
assert(byId["NC_NaturesCall:NCGut"].iconKey == "natures-call/NCGutBad")

active.LifestyleHobbies = false
active.TakeABathAndShowerNew = false
active.BrushYourDamnTeeth = false
active.MedicineMoodlesB42 = false

assert(statsAdapter.collect(player) == nil,
    "inactive optional stat mods should yield no values")

print("Optional mod stat and moodle adapter fixtures passed")

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
    ComfortNeed = 0.72,
    BeautyNeed = 74,
    tabas_BodyGrime = 38,
    BrushYourDamnTeeth = { dentalHygiene = 0.82 },
    LSMoodles = {
        Embarrassed = { Level = 2, Alignment = "Bad", Value = 0.38, Tiers = 0, Icon = 1 },
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

-- The reported multiplayer runtime had no callable next() global.
next = nil
local stats = statsAdapter.collect(player)
assert(stats.lifestyle_hygiene_need == 67)
assert(stats.lifestyle_embarrassment == 0.38)
assert(stats.lifestyle_comfort_need == 0.72)
assert(stats.lifestyle_beauty_need == 74)
assert(stats.tasab_body_grime == 38)
assert(stats.bydt_dental_hygiene == 0.82)

active.CWModpackCompatibility = true
assert(statsAdapter.collect(player).lifestyle_hygiene_need == 67,
    "older CW versions must not hide Lifestyle hygiene")
CWModpackCompatibility = {
    LifestyleOwnership = { isLifestyleHygieneDisabled = function() return true end },
}
local hidden = statsAdapter.collect(player)
assert(hidden.lifestyle_hygiene_need == nil)
assert(hidden.tasab_body_grime == 38)
assert(hidden.bydt_dental_hygiene == 0.82)
CWModpackCompatibility.LifestyleOwnership.isLifestyleHygieneDisabled = function() return false end
active.CWModpackCompatibility = false
assert(statsAdapter.collect(player).lifestyle_hygiene_need == 67)

modData.hygieneNeed = nil
modData.ComfortNeed = nil
modData.BeautyNeed = nil
modData.LSMoodles.Embarrassed = nil
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

active.CasualtiesUndead = true
modData.CU_Drug = { id = "morphine" }
modData.CU_Terms = { concussion = true }
CasualtiesUndead = {
    Drugs = {
        euphoria = function() return modData.CU_Drug and 0.64 or 0 end,
        highLevel = function() return 3, 0.64 end,
    },
    Mind = { isMiserable = function() return true end },
    Options = { showMoodles = function() return true end },
    Conditions = {
        enabled = function() return true end,
        worst = function() return { id = "concussion", grade = 2 } end,
        organOf = function() return "Brain" end,
    },
    Terms = { enabled = function() return true end },
}
assert(statsAdapter.collect(player).casualties_euphoria == 0.64)
modData.CU_Drug = nil
assert(statsAdapter.collect(player).casualties_euphoria == nil,
    "absent drug data must not create a euphoria bar")
CasualtiesUndead.Drugs.euphoria = function() return 0.5 end
assert(statsAdapter.collect(player).casualties_euphoria == 0.5,
    "an active overdose can produce euphoria without stored drug data")

local moodles = moodleAdapter.collect(player)
assert(type(moodles) == "table")

local byId = {}
for _, moodle in ipairs(moodles) do
    byId[moodle.id] = moodle
end

assert(byId["LifestyleHobbies:MindfulState"].label == "Mindful")
assert(byId["CasualtiesUndead:High"].level == 3)
assert(byId["CasualtiesUndead:Miserable"].iconKey == "casualties-undead/Miserable")
assert(byId["CasualtiesUndead:Condition"].iconKey == "casualties-undead/Organ_Brain")
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
active.CasualtiesUndead = false
active.MedicineMoodlesB42 = false

assert(statsAdapter.collect(player) == nil,
    "inactive optional stat mods should yield no values")

print("Optional mod stat and moodle adapter fixtures passed")

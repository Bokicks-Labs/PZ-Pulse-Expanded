-- Traverse existing Moodle Framework state once; registrations stay source-owned.
local Sources = require("PZPulseExpanded/Core/Sources")
local Utils = require("PZPulseExpanded/Moodles/Utils")
local Framework = {}

local OWNERS = {
    require("PZPulseExpanded/Integrations/BodilyFunctions"),
    require("PZPulseExpanded/Integrations/TakeABathAndShower"),
    require("PZPulseExpanded/Integrations/Infirmities"),
    require("PZPulseExpanded/Integrations/MedicineMoodles"),
    require("PZPulseExpanded/Integrations/BrushYourDamnTeeth"),
    (require("PZPulseExpanded/Integrations/TheMutants")),
}

local ownerByName = {}
for _, owner in ipairs(OWNERS) do
    for _, name in ipairs(owner.frameworkMoodles or {}) do
        ownerByName[name] = owner
    end
end

function Framework.collectMoodles(player, result, seen)
    if not Sources.isActive(Sources.moodleFramework) or type(MF) ~= "table" then return end
    if type(MF.MoodlesStorage) ~= "table" or type(MF.MoodleData) ~= "table" then return end

    local playerNum = player:getPlayerNum()
    local objects = MF.MoodlesStorage[playerNum]
    local dataRoot = MF.MoodleData[tostring(player)]
    local states = type(dataRoot) == "table" and dataRoot.Moodles or nil
    if type(objects) ~= "table" or type(states) ~= "table" then return end

    for name, object in pairs(objects) do
        local state = states[name]
        if type(state) == "table" and not (type(object) == "table" and object.disable) then
            local level = Utils.normalizeLevel(state.Level, 4)
            local alignment = tonumber(state.GoodBadNeutral)
            local valence = alignment == 1 and "good"
                or alignment == 2 and "bad"
                or nil

            if level ~= nil and valence ~= nil then
                local owner = ownerByName[name]
                local source = owner and owner.source or Sources.moodleFramework
                local alignmentText = valence == "good" and "Good" or "Bad"
                local titleKey = "Moodles_" .. tostring(name) .. "_"
                    .. alignmentText .. "_lvl" .. tostring(level)
                local descKey = "Moodles_" .. tostring(name) .. "_"
                    .. alignmentText .. "_desc_lvl" .. tostring(level)
                local objectTitle = type(object) == "table"
                    and Utils.tableText(object.title, valence, level)
                    or nil
                local objectDescription = type(object) == "table"
                    and Utils.tableText(object.desc, valence, level)
                    or nil

                Utils.addMoodle(result, seen, {
                    id = source.id .. ":" .. tostring(name),
                    label = objectTitle or Utils.translated(titleKey, Utils.humanize(name)),
                    description = objectDescription or Utils.translated(descKey, nil),
                    level = level,
                    maxLevel = 4,
                    valence = valence,
                    iconKey = owner and owner.iconFolder
                        and owner.iconFolder .. "/" .. tostring(name) or nil,
                    source = source,
                })
            end
        end
    end
end

return Framework

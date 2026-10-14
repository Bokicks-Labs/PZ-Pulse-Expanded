-- Medicine Moodle Framework registrations and per-player moodle objects.
local Sources = require("PZPulseExpanded/Core/Sources")
local Integration = { source = Sources.medicine, iconFolder = "medicine",
    frameworkMoodles = { "Antibiotics", "Antidepressants", "BetaBlockers",
        "Painkillers", "SleepingTablets", "LemonGrass" } }
local Moodles = require("PZPulseExpanded/Moodles/Utils")
local normalizeLevel, humanize, translated, addMoodle =
    Moodles.normalizeLevel, Moodles.humanize, Moodles.translated, Moodles.addMoodle

function Integration.collectMoodles(player, result, seen)
    if not Sources.isActive(Integration.source.id) then return end
    if type(ModMedicineMoodles) ~= "table"
        or type(ModMedicineMoodles.PlayerMoodles) ~= "table" then return end

    local objects = ModMedicineMoodles.PlayerMoodles[player:getPlayerNum()]
    if type(objects) ~= "table" then return end

    for name, object in pairs(objects) do
        if type(object) == "table"
            and type(object.getLevel) == "function"
            and type(object.getGoodBadNeutral) == "function" then
            local level = normalizeLevel(object:getLevel(), 4)
            local alignment = tonumber(object:getGoodBadNeutral())
            local valence = alignment == 1 and "good"
                or alignment == 2 and "bad"
                or nil

            if level ~= nil and valence ~= nil then
                local title = type(object.getTitle) == "function"
                    and object:getTitle(alignment, level)
                    or nil
                local description = type(object.getDescription) == "function"
                    and object:getDescription(alignment, level)
                    or nil
                addMoodle(result, seen, {
                    id = Integration.source.id .. ":" .. tostring(name),
                    label = title or humanize(name),
                    description = description,
                    level = level,
                    maxLevel = 4,
                    valence = valence,
                    iconKey = "medicine/" .. tostring(name),
                    source = Integration.source,
                })
            end
        end
    end
end

return Integration

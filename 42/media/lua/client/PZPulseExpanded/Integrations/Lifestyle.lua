-- Source-owned optional stat reader. Reads existing state only.
local Sources = require("PZPulseExpanded/Core/Sources")
local Row = require("PZPulseExpanded/Core/StatRow")
local add, finite = Row.add, Row.finite
local Integration = {}
Integration.source = Sources.lifestyle
Integration.statKeys = { "lifestyle_hygiene_need", "lifestyle_embarrassment", "lifestyle_comfort_need", "lifestyle_beauty_need" }

local function lifestyleHygieneHidden()
    if not (Sources.isActive("CWModpackCompatibility")
        or Sources.isActive("CWModpackCompatibility_dev")) then
        return false
    end
    local ownership = CWModpackCompatibility and CWModpackCompatibility.LifestyleOwnership
    if not (ownership and type(ownership.isLifestyleHygieneDisabled) == "function") then
        return false
    end
    local ok, disabled = pcall(ownership.isLifestyleHygieneDisabled)
    return ok and disabled == true
end
function Integration.isAvailable()
    return Sources.isActive(Sources.lifestyle)
end

function Integration.collectStats(player, modData, missing, sourceProblem, values, health)
    local lifestyle = Integration.isAvailable()
    local hygieneRaw = not missing and modData.hygieneNeed or nil
    add(values, health, player, "lifestyle_hygiene_need",
        hygieneRaw,
        lifestyle and not lifestyleHygieneHidden(),
        sourceProblem, 0, 100)
    local moodles = type(modData.LSMoodles) == "table" and modData.LSMoodles or {}
    local embarrassed = type(moodles.Embarrassed) == "table"
        and moodles.Embarrassed or {}
    local embarrassedRaw = not missing and embarrassed.Value or nil
    local embarrassedValue = finite(embarrassedRaw, 0, 1)
    add(values, health, player, "lifestyle_embarrassment",
        embarrassedValue, lifestyle, sourceProblem
            or (embarrassedRaw ~= nil and embarrassedValue == nil))
    local comfortRaw = not missing and modData.ComfortNeed or nil
    local comfortValue = finite(comfortRaw, 0, 1)
    add(values, health, player, "lifestyle_comfort_need",
        comfortValue, lifestyle, sourceProblem
            or (comfortRaw ~= nil and comfortValue == nil))
    local beautyRaw = not missing and modData.BeautyNeed or nil
    local beautyValue = finite(beautyRaw, 0, 100)
    add(values, health, player, "lifestyle_beauty_need",
        beautyValue, lifestyle, sourceProblem
            or (beautyRaw ~= nil and beautyValue == nil))
end

local Moodles = require("PZPulseExpanded/Moodles/Utils")
local normalizeLevel, humanize, translated, addMoodle =
    Moodles.normalizeLevel, Moodles.humanize, Moodles.translated, Moodles.addMoodle

local function lifestyleIconKey(name, state, level)
    local filename = tostring(name)
    local tiers = tonumber(state.Tiers) or 0
    local iconMode = tonumber(state.Icon) or 0

    if iconMode ~= 1 and iconMode ~= 3 then
        if level == 4 and tiers == 3 then
            filename = filename .. "3"
        elseif level >= 3 and tiers >= 2 then
            filename = filename .. "2"
        elseif level >= 2 and tiers >= 1 then
            filename = filename .. "1"
        end
    end
    return "lifestyle/" .. filename
end

function Integration.collectMoodles(player, result, seen)
    if not Integration.isAvailable() then return end

    local modData = player:getModData()
    local moodles = type(modData) == "table" and modData.LSMoodles or nil
    if type(moodles) ~= "table" then return end

    for name, state in pairs(moodles) do
        if type(state) == "table" then
            local level = normalizeLevel(state.Level, 4)
            local alignment = state.Alignment
            local valence = alignment == "Good" and "good"
                or alignment == "Bad" and "bad"
                or nil

            if level ~= nil and valence ~= nil then
                local labelKey = "Moodles_" .. tostring(name) .. "_L" .. tostring(level)
                local descKey = labelKey .. "_desc"
                addMoodle(result, seen, {
                    id = Integration.source.id .. ":" .. tostring(name),
                    label = translated(labelKey, humanize(name)),
                    description = translated(descKey, nil),
                    level = level,
                    maxLevel = 4,
                    valence = valence,
                    iconKey = lifestyleIconKey(name, state, level),
                    source = Integration.source,
                })
            end
        end
    end
end


return Integration

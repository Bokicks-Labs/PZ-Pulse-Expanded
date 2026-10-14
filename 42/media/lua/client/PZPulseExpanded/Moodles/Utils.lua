-- Shared normalization for every source-owned moodle reader.
local Utils = {}

function Utils.normalizeLevel(value, maxLevel)
    local level = tonumber(value)
    if level == nil or level ~= level then return nil end

    level = math.floor(math.abs(level))
    maxLevel = tonumber(maxLevel) or 4
    if level < 1 then return nil end
    if level > maxLevel then level = maxLevel end
    return level
end

function Utils.humanize(name)
    local text = tostring(name or "")
    text = text:gsub("_", " ")
    text = text:gsub("(%l)(%u)", "%1 %2")
    text = text:gsub("^NC", "")
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    return text ~= "" and text or "Modded Moodle"
end

function Utils.translated(key, fallback)
    if getText == nil then return fallback end

    local ok, value = pcall(getText, key)
    if not ok or type(value) ~= "string" or value == "" or value == key then
        return fallback
    end

    return value
end

function Utils.tableText(root, valence, level)
    if type(root) ~= "table" then return nil end

    local alignment = valence == "good" and 1 or 2
    local values = root[alignment]
    if type(values) ~= "table" then return nil end

    local value = values[level]
    if type(value) ~= "string" or value == "" then return nil end
    return value
end

function Utils.addMoodle(result, seen, moodle)
    if type(moodle) ~= "table" or type(moodle.source) ~= "table" then return end

    local id = tostring(moodle.id or "")
    local label = tostring(moodle.label or "")
    local level = Utils.normalizeLevel(moodle.level, moodle.maxLevel)
    local maxLevel = tonumber(moodle.maxLevel) or 4

    if id == "" or label == "" or level == nil then return end
    if moodle.valence ~= "good" and moodle.valence ~= "bad" then return end
    if seen[id] then return end

    seen[id] = true
    result[#result + 1] = {
        id = id,
        label = label,
        description = moodle.description,
        level = level,
        maxLevel = maxLevel,
        valence = moodle.valence,
        iconKey = moodle.iconKey,
        source = moodle.source,
    }
end

return Utils

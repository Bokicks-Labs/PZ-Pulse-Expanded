-- Compose independent source-owned stat readers into the existing payload.
local Sources = require("PZPulseExpanded/Core/Sources")
local Row = require("PZPulseExpanded/Core/StatRow")
local Adapter = {}

local INTEGRATIONS = {
    require("PZPulseExpanded/Integrations/Lifestyle"),
    require("PZPulseExpanded/Integrations/TakeABathAndShower"),
    require("PZPulseExpanded/Integrations/BrushYourDamnTeeth"),
    require("PZPulseExpanded/Integrations/DrugTime"),
    require("PZPulseExpanded/Integrations/Infirmities"),
    require("PZPulseExpanded/Integrations/CaffeineMakesSense"),
    (require("PZPulseExpanded/Integrations/CasualtiesUndead")),
}

local failuresLogged = {}

local function collectValues(player, modData, missing, sourceProblem)
    local values, health = {}, {}
    for _, integration in ipairs(INTEGRATIONS) do
        local sourceValues, sourceHealth = {}, {}
        local ok, reason = pcall(integration.collectStats, player, modData,
            missing, sourceProblem, sourceValues, sourceHealth)
        if ok then
            for key, value in pairs(sourceValues) do values[key] = value end
            for key, status in pairs(sourceHealth) do health[key] = status end
        else
            local id = integration.source.id
            if not failuresLogged[id] then
                local message = tostring(reason or "unknown error")
                if #message > 240 then message = message:sub(1, 240) .. "..." end
                print("[PZ_Pulse_Expanded] " .. id .. " stat collection failed: " .. message)
                failuresLogged[id] = true
            end
            -- One source failure must not prevent the remaining integrations
            -- from reporting their current values and health.
            local availableOk, available = pcall(integration.isAvailable)
            if not availableOk then available = Sources.isActive(integration.source) end
            for _, key in ipairs(integration.statKeys) do
                Row.add(values, health, player, key, nil, available, true)
            end
        end
    end
    for _, status in pairs(health) do
        if status ~= "unavailable" then return values, health end
    end
    return nil, health
end

function Adapter.collect(player)
    if player == nil then return nil end
    local modData, problem = nil, false
    if player.getModData ~= nil then
        local ok, data = pcall(player.getModData, player)
        if ok and type(data) == "table" then modData = data else problem = true end
    else
        problem = true
    end
    return collectValues(player, modData or {}, false, problem)
end

function Adapter.missing(player, problem)
    if player == nil then return nil end
    return collectValues(player, {}, true, problem)
end

return Adapter

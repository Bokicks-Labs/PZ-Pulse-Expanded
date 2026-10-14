-- Compose active moodles without creating or changing source-mod state.
local Adapter = {}

local COLLECTORS = {
    require("PZPulseExpanded/Integrations/Lifestyle"),
    require("PZPulseExpanded/Moodles/Framework"),
    require("PZPulseExpanded/Integrations/MedicineMoodles"),
    require("PZPulseExpanded/Integrations/DrugTime"),
    require("PZPulseExpanded/Integrations/NaturesCall"),
    (require("PZPulseExpanded/Integrations/CasualtiesUndead")),
}

function Adapter.collect(player)
    if player == nil or player.getModData == nil then return nil end

    local result, seen = {}, {}
    -- Keep each source isolated: malformed state in one mod must not hide
    -- valid moodles from the remaining mods.
    for _, collector in ipairs(COLLECTORS) do
        pcall(collector.collectMoodles, player, result, seen)
    end

    if #result == 0 then return nil end
    table.sort(result, function(left, right) return left.id < right.id end)
    return result
end

return Adapter

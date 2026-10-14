-- Publish each source's availability using its own sandbox rules.
local Sources = require("PZPulseExpanded/Core/Sources")
local BodilyFunctions = require("PZPulseExpanded/Integrations/BodilyFunctions")
local Infirmities = require("PZPulseExpanded/Integrations/Infirmities")
local Availability = {}

local sourceReaders = {
    [Sources.bodilyFunctions.id] = BodilyFunctions,
    [Sources.infirmities.id] = Infirmities,
}

function Availability.collect()
    local active = {}
    for _, source in ipairs(Sources.barSources) do
        local reader = sourceReaders[source.id]
        if reader then
            local ok, available = pcall(reader.isAvailable)
            active[source.id] = ok and available or false
        else
            active[source.id] = Sources.isActive(source)
        end
    end
    return active
end

return Availability

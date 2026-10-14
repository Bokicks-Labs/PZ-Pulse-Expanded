-- Source-owned optional stat reader. Reads existing state only.
local Sources = require("PZPulseExpanded/Core/Sources")
local Row = require("PZPulseExpanded/Core/StatRow")
local add, finite = Row.add, Row.finite
local Integration = {}
Integration.source = Sources.infirmities
Integration.statKeys = { "addiction_alcohol", "addiction_nicotine", "addiction_caffeine", "addiction_painkillers", "addiction_sleeping_pills", "addiction_amphetamines" }

function Integration.isAvailable()
    return Sources.isActive(Sources.infirmities)
        and SandboxVars ~= nil and SandboxVars.Infirmities ~= nil
        and SandboxVars.Infirmities.StartAddictiveSystem == true
end

function Integration.collectStats(player, modData, missing, sourceProblem, values, health)
    local infirmities = Integration.isAvailable()
    local addictions = type(modData.addictions) == "table" and modData.addictions or {}
    for _, definition in ipairs({
        { "alcohol", "addiction_alcohol" },
        { "nicotine", "addiction_nicotine" },
        { "caffeine", "addiction_caffeine" },
        { "painkillers", "addiction_painkillers" },
        { "sleepingPills", "addiction_sleeping_pills" },
        { "amphetamines", "addiction_amphetamines" },
    }) do
        local raw = addictions[definition[1]]
        local value = not missing and finite(raw, 0, 100) or nil
        add(values, health, player, definition[2], value, infirmities,
            sourceProblem or (raw ~= nil and value == nil))
    end
end

Integration.iconFolder = "infirmities"
Integration.frameworkMoodles = { "PanicAttack", "Tremors", "AddictedToAlcohol", "AddictedToNicotine", "AddictedToPainkillers", "AddictedToCaffeine", "AddictedToSleepingPills", "AddictedToAmp", "Withdrawal" }

return Integration

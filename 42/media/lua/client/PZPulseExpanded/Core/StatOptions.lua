-- One setting shared by every continuous stat bar collected by this mod.
local Options = {}

Options.ID = "PZ_Pulse_Expanded"
Options.KEY = "missingStatGraceSeconds"
Options.DEFAULT_SECONDS = 90
Options.MAX_SECONDS = 300

if PZAPI and PZAPI.ModOptions then
    local options = PZAPI.ModOptions:getOptions(Options.ID)
    if options == nil then
        options = PZAPI.ModOptions:create(Options.ID, "PZ Pulse Expanded")
        options:addDescription("Keep continuous stat bars visible during brief missing or invalid readings. Active bars with no first reading show zero and are marked Waiting for Data; disabled mods and intentionally hidden stats remain unavailable.")
        options:addSlider(Options.KEY, "Missing stat grace period (seconds)",
            0, Options.MAX_SECONDS, 5, Options.DEFAULT_SECONDS,
            "How long to retain the last valid bar value after a failed read. Set to 0 to hide it immediately.")
    end
end

function Options.graceMs()
    local options = PZAPI and PZAPI.ModOptions
        and PZAPI.ModOptions:getOptions(Options.ID)
    local setting = options and options:getOption(Options.KEY)
    local value = tonumber(setting and setting:getValue()) or Options.DEFAULT_SECONDS
    if value < 0 then value = 0 end
    if value > Options.MAX_SECONDS then value = Options.MAX_SECONDS end
    return value * 1000
end

return Options

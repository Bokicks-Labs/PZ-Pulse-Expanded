-- PZ Pulse exposes this shared registry as its stable extension entry point.
-- The append pattern is intentionally load-order independent: either mod may
-- create the table first.
PZ_Pulse_EXT = PZ_Pulse_EXT or {}

local NeedsExpanded = require("PZPulseExpanded/Panels/NeedsExpanded")

-- Register the Needs Expanded collector and browser renderer with PZ Pulse.
table.insert(PZ_Pulse_EXT, {
    api = 1,
    mod = "PZ_Pulse_Expanded",
    version = "1.5.0",
    id = "needs_expanded",
    title = "Needs Expanded",
    cls = "info",
    collect = NeedsExpanded.collect,
    js = "media/web/expanded-needs.js",
    css = "media/web/expanded-needs.css",
    render = "renderNeedsExpanded",
    options = {
        { name = "moodle_icon_scale", type = "number", label = "Moodle icon size (scale)", min = 1, max = 6, step = 0.5, default = 4 },
        { name = "bar_icon_scale", type = "number", label = "Bar icon size (scale)", min = 1, max = 4, step = 0.25, default = 2 },
        { name = "auto_hide_zero", type = "bool", label = "Auto-hide idle bars", default = false },
        { name = "zero_hide_delay", type = "number", label = "Hide delay (seconds)", min = 0, max = 300, step = 5, default = 10 },
        { name = "flash_increases", type = "bool", label = "Flash on reveal (auto-hide)", default = true },
        { name = "flash_seconds", type = "number", label = "Reveal flash (seconds)", min = 0, max = 10, step = 1, default = 7 }
    }
})

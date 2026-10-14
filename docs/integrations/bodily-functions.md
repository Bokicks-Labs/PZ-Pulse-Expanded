# Bodily Functions compatibility

The built-in adapter targets the locally inspected Build 42 Workshop item
`3396456841`, version **1.3.2**, mod ID `bodilyfunctions`. Its required mods are
Starlit Library and Moodle Framework. Bodily Functions is optional for PZ Pulse
Expanded.

The adapter reads `urinateValue` and `defecateValue` from the player supplied by
PZ Pulse. It never calls Bodily Functions' `BF.GetUrinateValue()` or
`BF.GetDefecateValue()`, since those functions call `getPlayer()` internally.
It divides each existing value by its corresponding sandbox capacity
(`BathroomFunctions.BladderMaxValue` or `BowelsMaxValue`) and exports a 0–100
percentage. The installed defaults are 800 and 500, respectively. Invalid or
missing capacities cannot produce a valid reading. The display caps overfill at
100%, while its severity stays at level four. A disabled urination or
defecation mechanic hides its corresponding bar immediately.

The installed source registers five Moodle Framework moodles: `Urination`,
`Defecation`, `PeedSelf`, `PoopedSelf`, and `BodilyFumes`. Needs Expanded assigns
their provenance to Bodily Functions. The bladder and bowel bars follow active
urge moodles when present; otherwise the fallback level is calculated from the
unrounded fill/capacity ratio using the source's strictly-above 40%, 60%, 80%,
and 90% thresholds. This keeps the color correct even when the displayed
percentage rounds to a breakpoint. Zero is a valid reading.
Existing stat-bar waiting, recent-value, and problem states apply independently
to both bars.

Nature's Call and Bodily Functions remain independent sources. If both mods are
enabled, their bladder and bowel values appear as separate bars with distinct
IDs and provenance. This integration does not resolve conflicts between their
gameplay systems. Validate each mod on a disposable save; do not add both to a
valued save to test this adapter.

The five source moodle glyphs are copied from the installed Workshop mod and
embedded in Needs Expanded's icon map. The Urination and Defecation glyphs
also appear on their corresponding bars. See
[`third-party-art.md`](../third-party-art.md) for exact files and attribution.
The source data fields and Moodle Framework registrations are private mod
internals and should be rechecked when Bodily Functions updates.

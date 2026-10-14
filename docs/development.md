# Developer guide

This is the working map for changing PZ Pulse Expanded yourself. Start with
[`architecture.md`](architecture.md) for design boundaries and
[`pulse/data-model.md`](pulse/data-model.md) for the normalized browser model.
The third-party API in `pulse/provider-api.md` is still a draft; built-in
integrations use internal modules.

## Where a change belongs

| Change | Edit |
| --- | --- |
| Source ID, display name, or list of mods with bars | `42/media/lua/client/PZPulseExpanded/Core/Sources.lua` |
| Mod-owned fields, ranges, sandbox switches, snapshots, or moodles | That mod's file in `42/media/lua/client/PZPulseExpanded/Integrations/` |
| Shared continuous-value validation, history, and health | `Core/StatUtils.lua` and `Core/StatRow.lua` |
| Missing-reading grace setting and its PZAPI option | `Core/StatOptions.lua` |
| Which sources contribute optional stat bars | `Panels/OptionalStats.lua` |
| Source availability in the bar chooser | `Panels/SourceAvailability.lua` |
| Moodle Framework ownership or traversal | `Moodles/Framework.lua` and the owner's `frameworkMoodles` list |
| Which sources contribute direct moodles | `Moodles/Collector.lua` |
| Shared moodle validation and translation helpers | `Moodles/Utils.lua` |
| Needs payload, vanilla stats, or PZ Pulse registration | `Panels/NeedsExpanded.lua` or root `PZ_Pulse_Expanded.lua`, respectively |
| Bar definitions, colors, tooltips, saved choices, or HTML | `42/media/web/expanded-needs.js` |
| Layout and visual styling | `42/media/web/expanded-needs.css` |
| Copied moodle art and attribution | `third-party-assets/moodle-icons/`, `Scripts/build-moodle-icon-map.ps1`, and `docs/third-party-art.md` |

The old root-level adapter files were removed. Import modules through their
current paths, for example
`require("PZPulseExpanded/Integrations/BodilyFunctions")`. Do not add a global
or forwarding file for an internal caller.

## Runtime path

1. Root `PZ_Pulse_Expanded.lua` appends a Needs Expanded entry to
   `PZ_Pulse_EXT`. It declares the Lua collector and browser JS/CSS paths.
2. `Panels/NeedsExpanded.lua` receives the player from PZ Pulse. It reads a
   few vanilla stats, asks `Panels/SourceAvailability.lua` for chooser state,
   and calls optional stat and moodle collectors. It returns the existing
   extension payload, including `natures_call`, `bodily_functions`,
   `optional_mod_stats`, `custom_moodles`, `active_mods`, and `bar_health`.
3. `Panels/OptionalStats.lua` calls each listed integration's `collectStats`.
   A source error is caught at that boundary: partial output from the failed
   source is discarded, its bar health is marked, and later sources still run.
4. `Moodles/Collector.lua` calls direct readers and `Moodles/Framework.lua`.
   Framework registrations belong to the declaring integration through its
   `frameworkMoodles` and `iconFolder` fields. Unknown registrations retain
   the generic Moodle Framework source.
5. `expanded-needs.js` adapts these payload fields and PZ Pulse's own private
   `d.needs` and `d.moodles`, validates rows, then renders and manages choices.
   It does not read a source mod's Lua state.

The Lua `require` path is relative to `42/media/lua/client` and omits `.lua`.
Source and panel modules return tables. A `require` call caches that table.
The PZ Pulse extension registry is the intentional global in this path.

## Existing contracts to preserve

- Use the player passed to a collector. Avoid `getPlayer()` inside an
  integration: it may select a different player in split-screen or multiplayer.
- Read another mod's existing state. Do not call its initialization or
  mutation functions during a PZ Pulse collection pass.
- Keep source mod IDs and stat IDs stable. The browser uses stat IDs for saved
  visibility, pins, and order. Moodle IDs have the form `source-id:name`.
- Values, health, source availability, and moodles answer different questions.
  An active mod can have no first reading; a valid numeric zero is a real
  reading. Do not infer a mod's availability from a bar's current value.
- `Core/StatUtils.sample` reports `reporting`, `recent`, `waiting`,
  `problem`, or `unavailable`. `Core/StatRow.add` supplies the waiting zero
  placeholder for optional bars. Recent values are bounded by
  `Core/StatOptions.lua` and clear immediately when inactive or hidden.
- Keep a source's actual range and moodle-level rules in its integration.
  The browser's `BAR_LEVELS` supplies a fallback when there is no active
  matching moodle; `BAR_MOODLE_IDS` connects a bar to source moodles. Maintain
  the common bar color palette even when source thresholds differ.
- Supported source mods can conflict with each other. Nature's Call and
  Bodily Functions remain separate readings; this mod does not reconcile
  their gameplay systems.

## Change an existing integration

1. Read its file in `Integrations/` and its relevant document under
   `docs/integrations/`. Confirm the source mod's current field names,
   formulas, and sandbox options before changing thresholds or ranges.
2. Follow the value through `collectStats` or `collectMoodles`, the appropriate
   collector, the Needs payload, and `expanded-needs.js`. Search the stable ID
   with `rg -n 'your_id' 42 tests docs`.
3. Keep `isAvailable()` as the source-specific activation rule. Simple
   integrations call `Core/Sources.isActive`; integrations with sandbox
   switches add those checks. Individual bars may need finer enable checks.
4. Keep `statKeys` aligned with every health key the integration emits so an
   exception can mark all of that source's bars. Use `StatRow.add` and
   `StatRow.finite` for continuous values; use `Moodles/Utils.addMoodle` for
   direct moodles. Preserve existing multiplayer snapshot behavior.
5. Update the corresponding fixture. Cover absent, disabled, first missing,
   valid zero, malformed, and recovered readings when the change affects
   collection health. Check a source failure does not hide another source.
6. If the display changes, update `STAT_EFFECTS`, `MOODLE_EFFECTS`, icon keys,
   `BAR_LEVELS`, or `BAR_MOODLE_IDS` as appropriate and run browser tests.

For a concrete single-stat example, `Integrations/TakeABathAndShower.lua`
declares `statKeys = { "tasab_body_grime" }`. Its reader passes the source's
existing `tabas_BodyGrime` value to `StatRow.add`, with its activation result
and the source's 0–100 range. `Panels/OptionalStats.lua` calls that reader;
`OPTIONAL_MOD_STAT_DEFINITIONS.tasab_body_grime` in `expanded-needs.js` defines
its label, direction, icon, and display range. Follow the same ID across all
three locations when editing a bar.

## Add a built-in source mod

1. Investigate its installed source and document its version, data ownership,
   ranges, moodle levels, options, multiplayer behavior, and art permission.
   Record the contract under `docs/integrations/`.
2. Add its canonical `source` object to `Core/Sources.lua`. Add it to
   `Sources.barSources` if it supplies chooser-visible bars.
3. Add one `Integrations/ModName.lua` returning a table with `source`. For
   continuous stats, provide `statKeys`, `isAvailable()`, and
   `collectStats(player, modData, missing, sourceProblem, values, health)`.
   Put its field reads and conversions there. For direct moodles, add
   `collectMoodles(player, result, seen)`; for Moodle Framework registrations,
   declare `frameworkMoodles` and `iconFolder` instead.
4. Register a stat reader in `Panels/OptionalStats.lua` or a direct moodle
   reader in `Moodles/Collector.lua`. For Framework moodles, register the owner
   in `Moodles/Framework.lua`. If sandbox settings affect whether a source
   appears in the bar chooser, add it to `Panels/SourceAvailability.lua`.
5. Add stable bar definitions and source attribution in
   `expanded-needs.js`. Add `BAR_MOODLE_IDS` and source-derived fallback
   `BAR_LEVELS` where applicable; keep the shared palette. Define tooltip
   effects from verified gameplay behavior.
6. If using copied art, place PNGs in `third-party-assets/moodle-icons/`,
   update `docs/third-party-art.md`, and run
   `./Scripts/build-moodle-icon-map.ps1`. Keep the generated icon-map section
   in `expanded-needs.js` generated.
7. Add Lua and browser fixtures, build the dev bundle, and test in a
   disposable save with relevant mod combinations. Supporting two source
   mods does not imply that those mods work together in one game.

## Checks and local test build

From the repository root, with Node.js and Python plus `lupa` available:

```powershell
node --test tests/expanded-needs.test.js
@'
from pathlib import Path
from lupa import LuaRuntime

for path in sorted(Path('tests').glob('*.test.lua')):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(path.read_text())
    print('PASS', path.name)
'@ | python -
git diff --check
./Scripts/build-dev-bundle.ps1
```

The Lua fixtures use a fresh runtime each because each fixture defines its own
fake game globals. Browser tests use Node's built-in test runner. The dev
bundle is written under ignored `artifacts/dev`; it changes the copied mod ID
to `PZ_Pulse_Expanded_Dev` and does not touch Workshop staging. See
[`multiplayer-development.md`](multiplayer-development.md) for installation.
Enable the dev ID and disable the public ID when testing. Automated fixtures
and a successful bundle build do not verify Project Zomboid behavior: use a
disposable save before publishing runtime claims.

For a release polish pass, compare the changes since the last Workshop upload
with the top plain-text entry in `docs/steam-changelog.txt`; update that entry
before staging. The version bump and Workshop staging steps are in the root
README. Neither script uploads to Steam.

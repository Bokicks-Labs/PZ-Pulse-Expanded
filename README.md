# PZ Pulse Expanded

PZ Pulse Expanded extends [PZ Pulse](https://github.com/PZ-Pulse/API) with richer player-state information and replacement panels designed to support both vanilla and modded data.

The project is currently in early development. **Needs Expanded** renders
PZ Pulse's vanilla Needs+ stats, active moodles from supported installed mods,
the underlying vanilla **Discomfort** stat, and independently nullable
continuous stats from Nature's Call, Lifestyle: Hobbies, Take A Bath And
Shower, Brush Your Damn Teeth, DrugTime 89, Infirmities, and Caffeine Makes
Sense. Players can choose, pin, and reorder bars in the panel gear menu.

## Goals

- Rebuild PZ Pulse's player-state panels around normalized data models.
- Show useful underlying Project Zomboid stats that are not normally exposed in the UI.
- Support modded player stats, moodles, and skills through built-in compatibility adapters.
- Provide a stable PZ Pulse Expanded provider API so other mod authors can add support directly.
- Preserve provenance for displayed data so tooltips can identify whether a value comes from Project Zomboid or another mod.
- Allow players to hide stats they do not want to see.

## Planned panels

### Needs Expanded

A replacement for PZ Pulse's Moodles & Needs+ panel.

It will contain:

- active vanilla and modded moodles
- vanilla player-state bars
- additional underlying Project Zomboid stats
- modded player-state stats registered through adapters or the public provider API

### Skills Expanded

A replacement skills panel designed to support:

- vanilla skills
- modded skills
- modified skill caps
- alternate XP/progression rules where required

## Current milestone

The current Needs Expanded panel uses one normalized rendering path:

```text
PZ Pulse vanilla moodles + supported mod moodles ─────────→ icon badges

PZ Pulse d.needs ───────────────────────────────┐
Project Zomboid Discomfort ─────────────────────┼─→ normalized PlayerStat rows
Optional compatible mod stats (when readable) ─┘
                         ↓
              Needs Expanded renderer
```

Every optional item fails closed by itself: when its source mod is inactive or
its state cannot be read, that row is omitted without affecting the rest of
the panel. See the installed-mod inventory in
[`docs/integrations/installed-mod-moodles.md`](docs/integrations/installed-mod-moodles.md).

## Documentation

- [`docs/architecture.md`](docs/architecture.md) — project architecture, scope, and stability boundaries.
- [`docs/workshop-description.md`](docs/workshop-description.md) — player-facing Steam Workshop description.
- [`docs/steam-changelog.txt`](docs/steam-changelog.txt) — ready-to-paste Steam BBCode changelog.
- [`docs/pulse/data-model.md`](docs/pulse/data-model.md) — normalized browser-side data models.
- [`docs/pulse/provider-api.md`](docs/pulse/provider-api.md) — draft third-party provider API.
- [`docs/pulse/panels.md`](docs/pulse/panels.md) — panel responsibilities and rendering behavior.
- [`docs/integrations/natures-call.md`](docs/integrations/natures-call.md) — verified compatibility-adapter contract and limits.
- [`docs/integrations/installed-mod-moodles.md`](docs/integrations/installed-mod-moodles.md) — local installed-mod moodle/stat inventory and supported sources.
- [`docs/third-party-art.md`](docs/third-party-art.md) — exact copied moodle-art inventory, attribution, and removal policy.
- [`docs/decisions/0001-normalized-provider-model.md`](docs/decisions/0001-normalized-provider-model.md) — rationale for normalizing provider data before rendering.

## Scope note: PZ Map

PZ Map integration is not currently planned. PZ Map does not expose a stable public extension API for the functionality this project would require, so integrating against its private internals would create an intentionally unstable dependency.

This can be revisited if an appropriate public API becomes available.

## Version bumps

Choose the release impact yourself: `patch` for a compatible fix, `minor` for a
compatible feature, or `major` for a breaking change. From this repo, run:

```powershell
.\Scripts\bump-version.ps1 -Bump patch -Title 'Optional Stat Fix' -Notes @('Keep supported stat bars visible after transient read failures.') -WhatIf
```

Remove `-WhatIf` to write the next version. The script updates `42/mod.info`,
the PZ Pulse registration version, and the Steam changelog. It refuses to
bump when those version fields disagree. Review and edit the generated
changelog before publishing.

## Workshop staging

After testing the current source, stage a verified Workshop upload with:

```powershell
.\Scripts\publish-to-pz-workshop.ps1
```

The script mirrors only the `42` and `common` payload folders into
`%UserProfile%\Zomboid\Workshop\PZ-Pulse-Expanded`, copies the Workshop
metadata and preview, removes retired files only inside that staging mod, and
verifies the staged payload by SHA-256. It also rebuilds the embedded moodle
icon map from the committed third-party PNG sources before copying. It does not
upload to Steam. `workshop.txt` targets the existing Workshop item
`3804774101`. On the Workshop item page, also add
[PZ Pulse](https://steamcommunity.com/sharedfiles/filedetails/?id=3753700423)
as a required item so subscribers receive the dependency automatically.

## Multiplayer development builds

For local single-player testing, run `Scripts/toggle-pz-junction.ps1`. It creates
`%UserProfile%\Zomboid\mods\PZPulseExpandedLocalDev` pointing at a copied dev bundle
with mod ID `PZ_Pulse_Expanded_Dev`. Run it again to remove the junction; each
new activation creates a fresh copy under the ignored `artifacts/dev` folder.
Enable the dev ID and disable the public ID in the test mod list.

Use `Scripts/build-dev-bundle.ps1` to create a separate local test mod and ZIP
without touching the public Workshop staging folder or publishing to Steam.
See [`docs/multiplayer-development.md`](docs/multiplayer-development.md) for
server and client installation steps.

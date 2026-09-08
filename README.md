# PZ Pulse Expanded

PZ Pulse Expanded extends [PZ Pulse](https://github.com/PZ-Pulse/API) with richer player-state information and replacement panels designed to support both vanilla and modded data.

The project is currently in early development. The first vertical slice is **Discomfort** in a custom **Needs Expanded** panel.

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

The current feature branch proves the data flow with the vanilla `CharacterStat.DISCOMFORT` value:

```text
Project Zomboid player
        ↓
Lua collector
        ↓
PZ Pulse extension payload
        ↓
normalized Stat model
        ↓
Needs Expanded renderer
```

## Documentation

- [`docs/architecture.md`](docs/architecture.md) — project architecture, scope, and stability boundaries.
- [`docs/pulse/data-model.md`](docs/pulse/data-model.md) — normalized browser-side data models.
- [`docs/pulse/provider-api.md`](docs/pulse/provider-api.md) — draft third-party provider API.
- [`docs/pulse/panels.md`](docs/pulse/panels.md) — panel responsibilities and rendering behavior.
- [`docs/decisions/0001-normalized-provider-model.md`](docs/decisions/0001-normalized-provider-model.md) — rationale for normalizing provider data before rendering.

## Scope note: PZ Map

PZ Map integration is not currently planned. PZ Map does not expose a stable public extension API for the functionality this project would require, so integrating against its private internals would create an intentionally unstable dependency.

This can be revisited if an appropriate public API becomes available.

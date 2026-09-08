# ADR 0001: Normalize provider data before rendering

## Status

Accepted.

## Context

PZ Pulse Expanded needs to display data from multiple sources:

- Project Zomboid
- PZ Pulse core payloads
- compatibility adapters maintained by this project
- third-party mods integrating through a future public API

Each source may expose its data in a different shape.

If renderers understand source-specific details, every new mod integration increases renderer complexity and couples the UI to external implementation details.

## Decision

All source-specific data is converted into normalized PZ Pulse Expanded models before it reaches a panel renderer.

For example, both vanilla Discomfort and a modded Urination value should become normalized Stat objects before `renderStatRow()` receives them.

Renderers must not contain mod-specific integration branches.

## Consequences

### Positive

- Built-in adapters and third-party providers share the same rendering path.
- Renderers remain focused on presentation.
- Tooltips and provenance work consistently.
- New integrations can be added without modifying core row rendering.
- Public API contracts can be documented independently from private UI implementation.

### Cost

- PZ Pulse Expanded must maintain explicit normalized model contracts.
- Provider/adapter code must translate source data before rendering.
- Schema changes require deliberate versioning once the public API is frozen.

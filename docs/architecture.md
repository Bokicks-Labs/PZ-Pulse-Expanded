# Architecture

## Purpose

PZ Pulse Expanded is an extension for PZ Pulse that rebuilds selected PZ Pulse panels around normalized, extensible data models.

The project has two primary goals:

1. expose useful Project Zomboid player information that PZ and PZ Pulse do not currently show
2. allow modded player information to participate in those panels without requiring renderer-specific integrations

## High-level data flow

```text
Project Zomboid
Built-in compatibility adapters
Third-party providers
        │
        ▼
collection / provider layer
        │
        ▼
normalized PZ Pulse Expanded models
        │
        ├───────────────┬───────────────────┐
        ▼               ▼                   ▼
Needs Expanded      Health Expanded    Skills Expanded
        │               │                   │
        ▼               ▼                   ▼
        PZ Pulse extension renderers
```

## Layer responsibilities

### Collection and providers

This layer knows how to obtain data.

Sources may include:

- Project Zomboid itself
- PZ Pulse's core payload, read defensively where necessary
- compatibility adapters maintained by PZ Pulse Expanded
- third-party mods that register through the future PZ Pulse Expanded provider API

Collection code should convert source-specific data into normalized models before rendering.

### Normalized models

Normalized objects define what the UI needs to know, not how a source stores the data.

The renderer should not contain logic such as:

```text
if Nature's Call ...
if TASA ...
if Beyond 10 ...
```

Instead, all integrations produce the same normalized object shapes.

See [`pulse/data-model.md`](pulse/data-model.md).

### Rendering

Rendering code receives normalized objects and owns:

- validation required for safe display
- normalization into presentation values
- semantic bar state
- icons
- escaped HTML
- tooltips
- panel layout

Rendering code does not own:

- mod-specific data access
- source-mod detection
- compatibility logic

## Panels

### Needs Expanded

Needs Expanded is intended to replace PZ Pulse's Moodles & Needs+ panel.

It contains two conceptual sections:

```text
Needs Expanded
├── active moodles
└── live player stats
```

The player-stat section may contain both familiar needs and other useful live character telemetry. Users should eventually be able to hide individual stats they do not care about.

### Skills Expanded

Skills Expanded is intended to replace the PZ Pulse skills panel where necessary to support:

- modded skills
- skill caps above vanilla limits
- alternate XP/progression behavior

### Health Expanded (planned)

Health Expanded is a planned dedicated panel for detailed health state, with
Casualties Undead as a priority integration. Its exact data set and UI remain
to be designed against the source mod's current APIs and multiplayer behavior.
See [`pulse/panels.md`](pulse/panels.md) for the initial scope.

## Source-owned integration layout

The Lua collector now keeps source metadata, validation, stat history, and
options in `Core/`. Each supported optional source has a reader in
`Integrations/`; source-specific sandbox checks and moodles live with that
source. `Moodles/Framework.lua` traverses Moodle Framework registrations once,
and `Moodles/Collector.lua` composes source moodles. `Panels/OptionalStats.lua`
combines independent stat readers, while `Panels/NeedsExpanded.lua` builds the
Needs payload. The root `PZ_Pulse_Expanded.lua` registers the panel with PZ
Pulse. In-repo callers import these modules directly.

The ownership rules and remaining runtime validation are recorded in
[`decisions/0002-source-owned-integrations.md`](decisions/0002-source-owned-integrations.md).

## Stability boundaries

### Public / intended stable surface

When API v1 is published, the intended stable surface is:

- provider registration schema
- normalized public data-model schema
- documented provider lifecycle/behavior

Breaking changes to a published public API should require an API version bump.

### Private / unstable implementation

The following remain implementation details:

- renderer helper function names
- CSS class names
- internal PZ Pulse Expanded payload organization
- adapter implementation details
- PZ Pulse private/core payload shapes
- PZ Pulse private icon maps or other undocumented browser globals

PZ Pulse private surfaces may be used defensively when necessary, but PZ Pulse Expanded must not present them as stable contracts.

### Current Needs Expanded adapters

The current panel composes normalized rows from independent inputs:

1. PZ Pulse's private `d.needs` and `d.moodles` arrays are adapted in the
   browser. PZ Pulse 1.1.3 does not provide stable need IDs, so the needs
   adapter owns an explicit mapping to its verified collector order. Both
   adapters validate individual items before use.
2. The extension Lua collector reads vanilla `CharacterStat.DISCOMFORT`.
3. The optional Nature's Call adapter reads existing per-player source-mod
   state without initializing it. See
   [`integrations/natures-call.md`](integrations/natures-call.md).
   The Bodily Functions adapter separately reads its own existing per-player
   fill values and configured capacities. See
   [`integrations/bodily-functions.md`](integrations/bodily-functions.md).
4. `Panels/OptionalStats.lua` composes continuous values from source modules
   for Lifestyle: Hobbies, Take A Bath And Shower, Brush Your Damn Teeth,
   DrugTime 89, Infirmities, Caffeine Makes Sense, and Casualties Undead.
5. `Moodles/Collector.lua` composes source-owned active moodles and the shared
   Moodle Framework traversal. Medicine Moodles' existing per-player objects
   are read by its own integration. The collectors never create moodles or
   initialize another mod's state.

Each stat reports its collection health independently. Inactive mods and
disabled source settings remain unavailable. An active source with no initial
reading supplies a zero placeholder marked **Waiting for Data**; invalid reads
and adapter failures are identified without erasing valid rows from other
sources. The shared payload is never mutated. For edit locations, module
contracts, and testing steps, see the [`developer guide`](development.md).

Continuous Lua stat bars retain each player's last valid value through a
configurable real-time grace period when a read fails. The setting is in
Options → Mods → PZ Pulse Expanded. A bar needs one valid reading before it
can be retained; disabled source mods and intentionally hidden stats clear
immediately. Moodles and PZ Pulse's private vanilla `d.needs` collection keep
their own behavior.

## Error philosophy

Expected missing or invalid data should degrade predictably.

Examples:

```text
missing extension payload
    → panel renderer returns ""

invalid optional stat
    → mark that bar as a problem while isolating other stats

known unstable upstream read fails
    → log useful context
    → return "" when panel output is no longer trustworthy
```

Unexpected bugs in PZ Pulse Expanded's own renderer should generally be allowed to throw so PZ Pulse's renderer fault diagnostics remain useful.

Broad catch-all exception handling around an entire renderer should be avoided.

## Scope: PZ Map

A PZ Map companion submod is not currently planned.

The PZ Map mod does not expose a stable public extension API for the changes this project would require. Building against its private internals would create an intentionally unstable dependency and conflict with this project's stability goals.

This decision may be revisited if PZ Map exposes an appropriate public API in the future.

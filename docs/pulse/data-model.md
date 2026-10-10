# PZ Pulse Expanded Data Model

PZ Pulse Expanded normalizes player information before it reaches a renderer.

The renderer should not need to know whether a value came from Project Zomboid, a compatibility adapter maintained by this project, or a third-party mod using the public provider API.

This document describes the normalized browser-side models. These models are the intended contract between provider/adapter code and panel-rendering code.

> Status: early design. Stat and active Moodle vertical slices are implemented.
> The Skill shape remains a placeholder until that vertical slice begins.

## Common conventions

### Required provenance

Every displayed item must have a `source` object.

This is not only diagnostic metadata. PZ Pulse Expanded intends to surface provenance in hover tooltips so players can see where a value came from.

### Numeric inputs

Numeric fields may be supplied as either:

- a finite JavaScript number
- a non-empty string that converts to a finite JavaScript number

Arrays, objects, booleans, empty strings, `NaN`, and infinities are invalid.

### Invalid normalized data

Render helpers return `null` when an individual normalized object is unusable.

Panel renderers decide whether that means:

- skip one optional item, or
- return an empty body (`""`) so PZ Pulse displays its standard **No data** state

Unexpected programming errors should not be broadly swallowed. PZ Pulse already isolates renderer exceptions and reports them through its own diagnostics.

---

# Stat

A **Stat** represents live numeric state about the current player.

Examples include:

- Hunger
- Thirst
- Fatigue
- Stress
- Discomfort
- Urination -----|
- Bowel state ---|-> from Nature'sCall
- other useful underlying Project Zomboid player values

Stats are displayed as rows in **Needs Expanded**.

## Shape

```js
{
    id: "discomfort",
    label: "Discomfort",
    description: "Current underlying discomfort level.",

    value: 27.42,
    min: 0,
    max: 100,
    badHigh: true,

    iconKey: "mood_discomfort",
    visibleByDefault: true,

    source: {
        type: "base_game",
        id: "project_zomboid",
        name: "Project Zomboid"
    }
}
```

## Field contract

| Field | Type | Required | Description |
|---|---|---:|---|
| `id` | `string` | yes | Stable machine-readable identifier for the stat. |
| `label` | `string` | yes | Player-facing display name. Must be non-empty. |
| `description` | `string` | no | Player-facing tooltip description. |
| `value` | `number \| numeric string` | yes | Current raw value before normalization. |
| `min` | `number \| numeric string` | yes | Minimum value of the stat's numeric range. |
| `max` | `number \| numeric string` | yes | Maximum value of the stat's numeric range. Must be greater than `min` for percentage normalization. |
| `badHigh` | `boolean` | yes | `true` when larger normalized values represent a worse state; `false` when smaller normalized values represent a worse state. |
| `iconKey` | `string` | no | Preferred icon lookup key. Every built-in stat supplies one; missing third-party icons must not prevent a row from rendering. |
| `visibleByDefault` | `boolean` | no | Whether the stat should initially be visible when stat-level visibility configuration is available. Default intent is `true`. |
| `source` | `StatSource` | yes | Provenance metadata for tooltips and diagnostics. |

## StatSource

```js
{
    type: "base_game",
    id: "project_zomboid",
    name: "Project Zomboid"
}
```

or:

```js
{
    type: "mod",
    id: "NC_NaturesCall",
    name: "Nature's Call"
}
```

The Nature's Call example reflects the currently verified installed mod ID;
the separate provider API remains a draft rather than a frozen contract.

### Field contract

| Field | Type | Required | Description |
|---|---|---:|---|
| `type` | `"base_game" \| "mod"` | yes | Provenance category. API v1 should whitelist known values rather than accepting arbitrary strings. |
| `id` | `string` | yes | Stable source identifier. For mods, prefer the source mod's actual mod ID. |
| `name` | `string` | yes | Player-facing source name used in tooltips. |

## Percentage normalization

Stats are normalized to a `0..100` percentage for bar width and semantic status:

```text
(value - min)
------------- × 100
(max - min)
```

The raw value is clamped to `[min, max]` before normalization.

Examples:

```text
value=50,  min=0,  max=100 → 50%
value=0.5, min=0,  max=1   → 50%
value=15,  min=10, max=20  → 50%
value=60,  min=0,  max=120 → 50%
```

Formatting is intentionally separate from normalization:

```text
raw numeric value
        ↓
normalizePercent(stat)
        ↓
numeric percentage
        ↓
formatStatValue(stat)
        ↓
player-facing string
```

The current Needs Expanded implementation formats stat values as whole percentages.

## Semantic bar state

The renderer first uses a matching active moodle level, when one is present.
Directly related bars use source-matched numeric thresholds while their moodle
is absent. Bars without a direct moodle use a five-step severity scale based on
`badHigh`. The exact mappings and their limits are documented in
[`panels.md`](panels.md#bar-colors).

---

# Moodle

A **Moodle** represents an active status indicator.

Needs Expanded displays active vanilla and modded moodles above the stat rows.
Inactive or neutral moodles are represented by absence, not by a level-zero
object.

## Shape

```js
{
    id: "TakeABathAndShowerNew:BodyGrime",
    label: "Body Grime",
    description: "Time to wash.",
    level: 3,
    maxLevel: 4,
    valence: "bad",
    iconKey: "tasab/BodyGrime",
    source: {
        type: "mod",
        id: "TakeABathAndShowerNew",
        name: "Take A Bath And Shower"
    }
}
```

| Field | Type | Required | Description |
|---|---|---:|---|
| `id` | `string` | yes | Stable source-qualified moodle identifier. |
| `label` | `string` | yes | Localized player-facing active-state title. |
| `description` | `string` | no | Localized active-state tooltip description. |
| `level` | positive integer | yes | Current source-defined active level. |
| `maxLevel` | positive integer | yes | Maximum level reported by the source. |
| `valence` | `"good" \| "bad"` | yes | Whether the active state is beneficial or harmful. |
| `iconKey` | `string` | no | Base PZ Pulse or bundled source-mod glyph key. |
| `source` | `StatSource` | yes | Provenance metadata shared with Stats. |

Moodles use PZ Pulse's circle-and-glyph badge design. `valence` and `level`
select the colored circle, `iconKey` selects the glyph, and the current level
appears in the bottom-right corner. A missing glyph degrades to a compact text
chip rather than a numeric stat bar.

---

# Skill

A **Skill** represents player progression information for the future **Skills Expanded** panel.

The normalized Skill shape is not frozen yet.

Expected concerns include:

- stable ID
- label
- current level
- maximum level
- current XP/progress
- progression semantics
- provenance

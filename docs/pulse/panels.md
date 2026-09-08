# Panels

## Needs Expanded

Needs Expanded is a custom PZ Pulse extension panel intended to replace the built-in **Moodles & Needs+** panel for users who want the expanded data set.

The panel should preserve the same broad visual model:

```text
active moodles
──────────────
player-stat rows
```

## Moodle section

Active moodles appear above the stat rows.

Long-term goals include:

- vanilla moodles
- positive moodles
- modded moodles such as those exposed by Moodle frameworks
- provenance tooltips

The Moodle normalized model is not yet frozen.

## Stat section

Each normalized Stat renders as a row:

```text
[icon] Label        [bar]        27%
```

The shared row grid is expected to align:

1. icon
2. label
3. bar
4. formatted value

## Stat visibility

Needs Expanded is intentionally allowed to contain a broad set of live player stats.

The player should eventually be able to hide individual stats they do not want.

PZ Pulse supports extension-defined panel options, but its current public API limits an extension panel to a small fixed number of options. PZ Pulse Expanded should therefore keep visibility as an internal stat-level concept rather than coupling the renderer directly to one PZ Pulse option per stat.

Normalized Stats include the intended field:

```js
visibleByDefault: true
```

The final configuration mechanism can change without changing the renderer's conceptual contract.

## Tooltips

Rows should eventually expose hover tooltips containing useful context without cluttering the panel.

For example:

```text
Discomfort

Current underlying discomfort level.

Value: 27%
Source: Project Zomboid
```

A modded stat may show:

```text
Urination

Current bladder level.

Value: 63%
Source: Nature's Call
```

Provenance is therefore part of the normalized model rather than a separate debugging-only feature.

## Icon behavior

PZ Pulse's browser Moodle icon map is not part of its documented stable extension API.

Needs Expanded may use it defensively when available, but:

- missing icon globals must not break the panel
- missing individual icon keys must not break the panel
- an invisible icon spacer should preserve row alignment

## Skills Expanded

Skills Expanded is a separate panel because skills have different progression semantics from live player-state stats.

Its long-term goals include:

- vanilla skills
- modded skills
- level caps above vanilla limits
- correct XP/progress behavior for mods that change progression

The normalized Skill model is not yet frozen.

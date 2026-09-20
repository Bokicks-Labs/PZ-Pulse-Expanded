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

The implemented panel includes PZ Pulse's active vanilla moodles plus active
positive and negative moodles from supported source mods, including moodles
exposed through Moodle Framework. Level zero is omitted. Each moodle is a PZ
Pulse-style layered icon badge with the current level in its bottom-right
corner; its tooltip includes source provenance. The moodle-to-stat gap is 4px,
which is intentionally tighter than PZ Pulse's 10px default.

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

The implemented deterministic row order is:

1. PZ Pulse Needs+ vanilla stats: Hunger, Thirst, Fatigue, Stamina, Boredom,
   Stress, Panic, Unhappiness, Pain, Sickness, Wetness, and Drunkenness
2. vanilla Discomfort
3. optional Nature's Call Bladder and Bowel fills
4. optional continuous mod stats: Lifestyle Hygiene Need, TASAB Body Grime,
   and Brush Your Damn Teeth Dental Hygiene

PZ Pulse's `d.needs` shape is a private dependency. The current adapter targets
the exact ordered collector contract verified in PZ Pulse 1.1.3 and validates
individual rows before normalization. Missing or invalid rows are skipped
without affecting the other sources. This applies per stat: an installed but
uninitialized mod does not create a zero bar.

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
- missing vanilla glyphs should degrade to compact text moodle chips
- known supported mods use embedded copies of their source glyphs
- missing stat-row icons still use an invisible spacer to preserve alignment

## Skills Expanded

Skills Expanded is a separate panel because skills have different progression semantics from live player-state stats.

Its long-term goals include:

- vanilla skills
- modded skills
- level caps above vanilla limits
- correct XP/progress behavior for mods that change progression

The normalized Skill model is not yet frozen.

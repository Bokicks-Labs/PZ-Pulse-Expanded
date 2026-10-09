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

Every built-in stat definition supplies an icon. Vanilla bars reuse PZ Pulse's
existing moodle glyph map; optional mod bars reuse the matching embedded
source-mod moodle glyph.

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
4. vanilla Nicotine Withdrawal, Idleness, and Poison
5. optional continuous mod stats: Lifestyle Hygiene Need, TASAB Body Grime,
   Brush Your Damn Teeth Dental Hygiene, DrugTime 89 intensities, Infirmities
   addiction levels, and Caffeine Makes Sense caffeine load

PZ Pulse's `d.needs` shape is a private dependency. The current adapter targets
the exact ordered collector contract verified in PZ Pulse 1.1.3 and validates
individual rows before normalization. Missing or invalid rows are skipped
without affecting the other sources. This applies per stat: an installed but
uninitialized mod does not create a zero bar.

## Stat visibility

Needs Expanded's PZ Pulse gear menu contains a **Choose bars** button. It opens
a flat, alphabetical list with one checkbox per continuous bar. Choices apply
immediately and persist in this browser's local storage. An inactive source mod
leaves its choices visible but dimmed and disabled; their saved values remain
available if the mod becomes active later. Infirmities choices are also disabled
when its addiction system is off. Missing per-player state does not make an
active mod's checkbox unavailable.

The button is a narrow integration with PZ Pulse 1.1.3's private `.panel-settings`
markup. PZ Pulse's public extension options accept only `bool`, `number`, and
`choice` entries (eight at most), so there is no action-button declaration.
PZ Pulse Expanded restores its button if PZ Pulse rebuilds the gear contents.
An upstream action-button option would replace this private integration.

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

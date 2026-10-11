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
corner; its tooltip includes source provenance. At the default controls,
moodle badges use 87.5% of PZ Pulse's default moodle icon size, while stat
icons use 120% of its default need icon size. Needs Expanded has its own icon
size controls, so changing the original Needs+ panel's sizes does not change it.
The moodle-to-stat gap is 10px. Moodle badges have a larger hover area than
their artwork. Stat and moodle tooltips use one persistent overlay outside the
panel body so frequent data updates do not restart the browser's hover timer.
They open after a 650 ms hover delay; leaving before then cancels the tooltip.

## Stat section

Each normalized Stat renders as a row:

```text
[icon] Label        [bar]        27%
```

Every built-in stat definition supplies an icon. Vanilla bars reuse PZ Pulse's
existing moodle glyph map; optional mod bars reuse the matching embedded
source-mod moodle glyph. Caffeine Level uses an original steaming coffee cup
icon stored in `assets/moodle-icons/pz-pulse-expanded/CaffeineLevel.png` and
embedded by the icon-map build script.
Brush Your Damn Teeth uses separate glyphs for its long-term Dental Hygiene
bar and its short-term Mouth State moodle.

The shared row grid is expected to align:

1. icon
2. label
3. bar
4. formatted value

### Bar colors

Bar fill colors follow the active matching moodle level whenever that moodle
is present in the payload. This takes precedence over numeric thresholds, so
runtime threshold changes and delayed or latched mod moodles stay visually in
step with the displayed moodle. Level 0 uses PZ Pulse's green. The stat bar for
a level-one negative moodle blends PZ Pulse's green and yellow, including when
that moodle has only one level. Levels 2, 3, and 4 then use PZ Pulse's yellow,
an orange blend of yellow and PZ Pulse's red, and PZ Pulse's red. Positive
moodle levels use progressively stronger green shades, ending in dark green.
Three-level negative moodles use green-yellow, yellow, and red. Moodle badge
artwork and colors still come directly from PZ Pulse.
Dental Hygiene is deliberately not paired with the Mouth State moodle: the
former changes with long-term hygiene, while the latter tracks time since
brushing. Its bar follows the source mod's hygiene-effect bands instead.

When a matching moodle is absent, the following value thresholds come from
the installed Build 42.20 `MoodleStat` class and source-mod moodle code.
Vanilla Needs+ thresholds use the percentage in PZ Pulse's payload;
Discomfort uses its own 0..100 value. `>` means the color changes just above
the listed value.

| Bars | Level-change thresholds |
|---|---|
| Hunger | >15, >25, >45, >70 |
| Thirst | >12, >25, >70, >84 |
| Fatigue | >60, >70, >80, >90 |
| Stamina | ≤75, ≤50, ≤25, ≤10 remaining |
| Boredom | >25, >50, >75, >90 |
| Panic | >6, >30, >65, >80 |
| Unhappiness | >20, >45, >60, >80 |
| Pain | >10, >20, >50, >75 |
| Sickness | >25, >50, >75, >90 |
| Wetness | >15, >40, >70, >90 |
| Drunkenness | >10, >30, >50, >70 |
| Discomfort | ≥20, ≥40, ≥60, ≥80 |
| Nature's Call bladder and bowel | ≥70, ≥95, >100 of 120 fill |
| Lifestyle Hygiene | good: <40, <30, <20, <10; bad: >60, >70, >80, >90 |
| TASAB Body Grime | ≥45 (level 2), ≥75 (level 3), ≥90 (level 4) |
| DrugTime 89 Stoned / Hard | >0, ≥70 / ≥80, ≥105 / ≥120 |

The vanilla Stress moodle reads the game's nicotine stress value, which is not
the same as the exported Stress bar. Its color follows the active moodle level.
Infirmities addiction moodles latch after source-specific thresholds, so their
current level is read from the active moodle rather than inferred from the
addiction number. Brush Your Damn Teeth's mouth moodle is based on time since
brushing, not Dental Hygiene; its active level controls the bar color. Nicotine
Withdrawal, Idleness, Poison, and Caffeine Level have no direct moodle level
for their displayed value, so they use a general five-step severity scale.

The default row order is:

1. PZ Pulse Needs+ vanilla stats: Hunger, Thirst, Fatigue, Stamina, Boredom,
   Stress, Panic, Unhappiness, Pain, Sickness, Wetness, and Drunkenness
2. vanilla Discomfort
3. vanilla Nicotine Withdrawal, Idleness, and Poison
4. optional Nature's Call Bladder and Bowel fills
5. optional continuous mod stats: Lifestyle Hygiene Need, TASAB Body Grime,
   Brush Your Damn Teeth Dental Hygiene, DrugTime 89 intensities, Infirmities
   addiction levels, and Caffeine Makes Sense Caffeine Level

The **Order bars…** view in the chooser moves each bar up or down one position,
including hidden or currently unavailable bars. Order is stored by stable stat
ID in a separate browser local-storage key. Saved IDs are validated, duplicates
and unknown IDs are discarded, and newly added bars append in default order.
**Reset order** restores the default. Visibility and pin choices are independent
of order.

PZ Pulse's `d.needs` shape is a private dependency. The current adapter targets
the exact ordered collector contract verified in PZ Pulse 1.1.3 and validates
individual rows before normalization. Missing or invalid rows are skipped
without affecting the other sources. This applies per stat: an installed but
uninitialized mod does not create a zero bar.

## Stat visibility

Needs Expanded's PZ Pulse gear menu contains a **Manage Stat Bars…** button. It opens
a source-organized list with one checkbox for each source and one for every
continuous bar. A source checkbox switches all of that source's bars together;
individual checkboxes remain independent. Choices apply immediately and persist
in this browser's local storage. Each bar shows its stat icon in the visibility
and order views. An inactive source mod
leaves its choices visible but dimmed and disabled; their saved values remain
available if the mod becomes active later. Infirmities choices are also disabled
when its addiction system is off. Missing per-player state does not make an
active mod's checkbox unavailable.
Each bar also has a **Pin** checkbox. A pinned bar remains visible at zero
when auto-hide is enabled. Pinning does not turn on a manually hidden bar.

The button is a narrow integration with PZ Pulse 1.1.3's private `.panel-settings`
markup. PZ Pulse's public extension options accept only `bool`, `number`, and
`choice` entries (eight at most), so there is no action-button declaration.
PZ Pulse Expanded restores its button if PZ Pulse rebuilds the gear contents.
An upstream action-button option would replace this private integration.

The same gear menu has **Moodle icon size (scale)** and **Bar icon size
(scale)** controls. They use a 1–6 range in half steps for moodles and a 1–4
range in quarter steps for bar icons. The bar thickness stays half the icon
height as its scale changes. These options belong to Needs Expanded alone.
Their default scales are 4 and 2 respectively. The gear menu also offers
**Auto-hide idle bars**, **Hide delay
(seconds)**, **Flash on reveal (auto-hide)**, and **Reveal flash (seconds)**.
Auto-hide starts disabled. When enabled, bars where a low value is beneficial
hide if they start at zero. After a visible bar returns to zero, it remains
visible for the chosen delay (10 seconds by default), then hides. Bars such as
Stamina and Dental Hygiene remain visible at zero. The flash toggle starts
enabled and only works with auto-hide. When a hidden zero bar first becomes
positive, its white outline pulses for the selected time (7 seconds by
default). The slower 1.6-second pulse finishes its current cycle and fades to
no outline before stopping, so the actual flash may last up to one cycle longer
than the selected time. Panel updates keep the pulse phase. Later stat changes
do not restart it. Individual and source visibility
choices still take precedence. The timing controls are PZ Pulse panel options;
the bar and pin choices continue to use browser local storage.

Normalized Stats include the intended field:

```js
visibleByDefault: true
```

The final configuration mechanism can change without changing the renderer's conceptual contract.

## Tooltips

Rows expose hover tooltips with gameplay context, current value, and source.
Vanilla moodles use the game's localized description for their current level;
modded moodles retain descriptions supplied by their source mod. Both add an
authored effect summary for recognized conditions. Unknown mod moodles get a
cautious fallback instead of an invented specific penalty.

All authored stat tooltip text is in `STAT_EFFECTS` in
`42/media/web/expanded-needs.js`. Authored moodle effect text is in
`MOODLE_EFFECTS` in the same file. `formatStatTooltip` and
`formatMoodleTooltip` compose those descriptions with value, level, and
source. Vanilla level-specific text is read by `collectVanillaMoodleDescriptions`
in `42/media/lua/client/PZPulseExpanded/PZ_Pulse_Expanded.lua` from the game's
`Moodles_*_desc_lvl*` translation keys. Modded source descriptions are collected
in `42/media/lua/client/PZPulseExpanded/CustomMoodleAdapter.lua`; edit a source
mod's translation or the authored effect summary for those.

For example:

```text
Discomfort

Underlying physical discomfort. Tight or unsuitable clothing and other
irritants can contribute. Persistent discomfort can worsen mood.

Value: 27%
Source: Project Zomboid
```

A modded stat may show:

```text
Bladder

Nature's Call bladder fill, including overfill beyond the normal range.

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

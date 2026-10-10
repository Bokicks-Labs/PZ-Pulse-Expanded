# PZ Pulse Expanded

PZ Pulse Expanded is a Build 42 add-on for **PZ Pulse** that replaces its
Moodles & Needs+ panel with a richer, mod-aware **Needs Expanded** view.

Keep the dashboard useful without turning optional integrations into hard
dependencies: every added moodle and stat is nullable. If its source mod is not
enabled, its data has not synchronized, or its value cannot be read safely,
that individual row simply does not appear. The rest of the panel continues to
work.

## Required mod

- [PZ Pulse](https://steamcommunity.com/sharedfiles/filedetails/?id=3753700423)

Load **PZ Pulse Expanded after PZ Pulse**. Optional supported mods may load
before PZ Pulse Expanded. Fully restart Project Zomboid after changing the mod
list.

## Needs Expanded

The replacement panel includes:

- PZ Pulse's existing vanilla Needs+ bars
- active vanilla moodles
- the underlying vanilla **Discomfort** stat
- active moodles discovered from supported installed mods
- optional continuous meters from supported mods
- a corresponding vanilla or source-mod moodle icon beside every stat bar
- source-aware tooltips so modded rows identify where their data came from
- bar colors that follow matching active moodle levels where available

Open the panel gear menu and select **Manage Stat Bars** to show or hide each
bar, toggle a whole source, pin a bar, or change its order. Unavailable mod
controls are dimmed and keep their saved choices for later. The gear menu also
offers optional auto-hide for idle bars, a hide delay, and a brief white outline
flash when an auto-hidden bar first appears. Stat and moodle tooltips describe
their gameplay effects and show after a short hover delay.
The flash completes its final blink and fades out after the chosen duration.
Moodle and bar icon sizes have separate controls in Needs Expanded's gear menu;
the original Needs+ panel's size settings do not change them.

Inactive moodles stay hidden, matching the compact behavior of the original
panel. Stats with no safe value are also hidden independently, so one missing
integration never empties or breaks the whole panel.

The moodle area matches PZ Pulse's original design: each active state is shown
as its original glyph on PZ Pulse's colored moodle circle, with the current
level in the bottom-right corner. The moodle badges are slightly smaller, the
stat icons are slightly larger, and the two areas have a clear gap.

## Optional mod integrations

No mod in this section is required.

### Lifestyle: Hobbies

- Discovers active entries from Lifestyle's current `LSMoodles` registry,
  including Lifestyle moodles added now or in future versions through that
  registry.
- Adds the continuous **Hygiene Need** meter when Lifestyle exposes a readable
  value.

### Take A Bath And Shower

- Supports registered Moodle Framework states such as bathing, body
  temperature effects, feeling watched, and body grime.
- Adds the continuous **Body Grime** meter when available.

### Caffeine Makes Sense

- Adds a **Caffeine Level** meter with a coffee cup icon when its state is
  readable.

### Nature's Call

- Supports its active bladder, bowel, soilage, smell, gut, and related moodle
  states.
- Adds independently nullable **Bladder** and **Bowel** meters when the source
  data is safe to read. Hidden source-mod meters remain hidden here as well.

### Other supported moodle sources

- **Moodle Framework:** displays active registered moodles from installed
  add-ons, including unrecognized registrations under a generic Moodle
  Framework source label.
- **DrugTime 89:** supports its active Stoned and Hard states and adds their
  intensity meters when readable.
- **Medicine Moodles:** supports its registered medicine-effect moodles.
- **Brush Your Damn Teeth:** supports its mouth-state moodle and an optional
  **Dental Hygiene** meter.
- **Infirmities:** supports panic attacks, tremors, addictions, and withdrawal,
  plus individual addiction meters when its addiction system is enabled and the
  values are readable.
- **The Mutants:** supports the Puked moodle.

Integrations are read-only. PZ Pulse Expanded does not create, initialize, or
mutate another mod's player data just to display it.

## Third-party artwork and removal requests

To reproduce each supported mod's in-game moodles faithfully, this add-on
includes only the moodle glyph artwork used by **Lifestyle: Hobbies**, **Take A
Bath And Shower**, **Infirmities**, **Medicine Moodles**, **Brush Your Damn
Teeth**, **The Mutants**, **DrugTime 89**, and **Nature's Call**. PZ Pulse's
colored circles and vanilla moodle glyphs are reused from the required PZ Pulse
mod at runtime and are not copied into this add-on.

The exact copied filenames, source paths, Workshop IDs, and known author names
are documented in `docs/third-party-art.md` in the project repository. All
third-party artwork remains the property of its respective creator; no
ownership is claimed. If any mod author or rights holder asks for their
artwork or integration to be removed, contact me and I will remove it promptly.

## Compatibility and multiplayer

- Made for Project Zomboid Build **42.20+**.
- PZ Pulse is the only declared mod dependency.
- Optional integrations activate only when their mod is active and readable.
- In multiplayer, the client can display only state that the source mod makes
  available locally or synchronizes to that player.
- Clients and servers should use matching mod lists and versions where a
  server-side source mod is involved.

## Current scope

The current release focuses on **Needs Expanded**. A broader **Skills Expanded**
panel and the public third-party provider API are planned work and are not
advertised as complete features in this release.

Back up important saves before changing any mod list. If a supported mod
changes its private data format, that integration is designed to disappear
safely rather than stop the rest of PZ Pulse from rendering.

Created and maintained with Codex.

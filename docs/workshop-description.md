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
- source-aware tooltips so modded rows identify where their data came from

Inactive moodles stay hidden, matching the compact behavior of the original
panel. Stats with no safe value are also hidden independently, so one missing
integration never empties or breaks the whole panel.

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

### Nature's Call

- Supports its active bladder, bowel, soilage, smell, gut, and related moodle
  states.
- Adds independently nullable **Bladder** and **Bowel** meters when the source
  data is safe to read. Hidden source-mod meters remain hidden here as well.

### Other supported moodle sources

- **Moodle Framework:** displays active registered moodles from installed
  add-ons, including unrecognized registrations under a generic Moodle
  Framework source label.
- **DrugTime 89:** supports its active Stoned and Hard states.
- **Medicine Moodles:** supports its registered medicine-effect moodles.
- **Brush Your Damn Teeth:** supports its mouth-state moodle and an optional
  **Dental Hygiene** meter.

Integrations are read-only. PZ Pulse Expanded does not create, initialize, or
mutate another mod's player data just to display it.

## Compatibility and multiplayer

- Made for Project Zomboid Build **42.20+**.
- PZ Pulse is the only declared mod dependency.
- Optional integrations activate only when their mod is active and readable.
- In multiplayer, the client can display only state that the source mod makes
  available locally or synchronizes to that player.
- Clients and servers should use matching mod lists and versions where a
  server-side source mod is involved.

## Current scope

This first release focuses on **Needs Expanded**. A broader **Skills Expanded**
panel and the public third-party provider API are planned work and are not
advertised as complete features in this release.

Back up important saves before changing any mod list. If a supported mod
changes its private data format, that integration is designed to disappear
safely rather than stop the rest of PZ Pulse from rendering.

Created and maintained with Codex.

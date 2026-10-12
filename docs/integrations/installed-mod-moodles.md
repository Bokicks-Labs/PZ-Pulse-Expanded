# Installed-mod moodle and stat inventory

This inventory was built from the locally installed Project Zomboid Workshop
sources for Build 42.20. It records moodle-producing mods that Needs Expanded
can read without initializing or mutating their state.

The 2026-10-11 follow-up checked the 342 IDs in the newest save's `mods.txt`
(`Saves/Sandbox/2026-10-11_04-08-30`). Workshop source was mapped for 338 IDs;
the remaining four are vehicle/viewpoint IDs whose Workshop `mod.info` did not
match the preset literally. The source sweep checked
character-stat references and custom moodle registrations, then traced likely
player-owned continuous values to their writers and consumers.

## Continuous stat bars

| Source mod | Mod ID | Stat | Source range | Direction |
|---|---|---|---:|---|
| Lifestyle: Hobbies | `LifestyleHobbies` | Hygiene Need | `0..100` | higher is worse |
| Lifestyle: Hobbies | `LifestyleHobbies` | Embarrassment | `0..1` | higher is worse |
| Lifestyle: Hobbies | `LifestyleHobbies` | Comfort Need | `0..1` | higher is better |
| Lifestyle: Hobbies | `LifestyleHobbies` | Beauty Need | `0..100` | higher is better |
| Take A Bath And Shower | `TakeABathAndShowerNew` | Body Grime | `0..100` | higher is worse |
| Brush Your Damn Teeth | `BrushYourDamnTeeth` | Dental Hygiene | `0..1` | higher is better |
| DrugTime 89 | `DrugTime89` | Stoned Intensity | `0..140` | higher is worse |
| DrugTime 89 | `DrugTime89` | Hard Drug Intensity | `0..160` | higher is worse |
| Infirmities | `twbInfirmities` | Alcohol, nicotine, caffeine, painkiller, sleeping-pill, and amphetamine addiction | `0..100` each | higher is worse |
| Caffeine Makes Sense | `CaffeineMakesSense` | Caffeine Level | `0..MaxCaffeineLevel` | higher is worse |
| Casualties Undead | `CasualtiesUndead` | Drug Euphoria | `0..1` | higher is a stronger high |

The panel also reads vanilla Nicotine Withdrawal (`0..1`), Idleness (`0..1`),
and Poison (`0..100`). These have active gameplay writers or consumers in the
installed Build 42 game and mod sources and are absent from PZ Pulse's other
panels. Infirmities bars require its addiction sandbox system to be enabled.
Caffeine Makes Sense uses an existing server snapshot on a multiplayer client;
other contexts calculate the load from its existing dose state without
initializing it.
Brush Your Damn Teeth's mouth-state moodle has four bad levels driven by days
since brushing (sandbox configurable), independent of its long-term Dental
Hygiene value. The Dental Hygiene bar instead changes severity at the mod's
actual hygiene-effect bands: below `0.50`, `0.30`, and `0.10`.

The collector preserves numeric zero. Inactive or disabled sources remain
unavailable; an active source with no initial value supplies a zero placeholder
marked **Waiting for Data** in Manage Stat Bars. Invalid values and adapter
failures are marked as problems, while a prior valid value can remain visible
during the configured grace period.
The Lifestyle Hygiene Need row is also omitted when CW Modpack Compatibility's
**Disable Lifestyle personal hygiene need** sandbox option is enabled. TASAB
Body Grime and BYDT Dental Hygiene remain independent.

## Active moodles

Only active source-defined levels are exported. Neutral/hidden level zero is
omitted, so this section stays compact during normal play.

### Lifestyle: Hobbies

The adapter reads the mod-owned `LSMoodles` table dynamically, so all current
and future Lifestyle entries in that table participate without a hard-coded
allowlist. The installed 0.4.0.3 source currently defines 35 moodles:

`HygieneGood`, `MintFresh`, `HygieneBad`, `Nauseous`, `BathCold`, `BathHot`,
`BladderNeed`, `AtHouse`, `HomeSick`, `MindfulState`, `MusicGood`, `MusicBad`,
`DJAudience`, `PartyGood`, `PartyBad`, `Embarrassed`, `Uncomfortable`,
`Comfort`, `BeautyNeg`, `TaughtSkill`, `AdviceWasted`, `Attractive`,
`SmellGood`, `FTGood`, `FTBad`, `ElDoradoGood`, `ElDoradoBad`, `BeautyGood`,
`Zen`, `WasTaughtSkill`, `Eureka`, `Gloomy`, `MintCurio`, `NeuralHat`, and
`Dunce`.

### Moodle Framework sources

The adapter enumerates the current player's existing Moodle Framework storage.
Known installed registrations retain their actual source provenance:

| Source mod | Registered moodles |
|---|---|
| Take A Bath And Shower | `Wet_Bathing`, `CoolingBody`, `WarmingBody`, `FeelingGaze`, `BodyGrime` |
| Infirmities | `PanicAttack`, `Tremors`, six `AddictedTo...` moodles, `Withdrawal` |
| Medicine Moodles | `Antibiotics`, `Antidepressants`, `BetaBlockers`, `Painkillers`, `SleepingTablets`, `LemonGrass` |
| Brush Your Damn Teeth | `BYDT_MouthState` |
| The Mutants | `PZTheMutants_Puked` |

An active unrecognized Moodle Framework registration is still displayed and is
identified as a `Moodle Framework add-on` rather than being silently discarded.
Medicine Moodles keeps its `MF.ISMoodle` objects in its own per-player table,
so the adapter also observes that already-initialized table without creating or
updating any medicine moodles.

Known installed sources use exact copied source-mod glyphs. An unknown Moodle
Framework registration still appears as a compact text moodle chip if no
matching bundled glyph is available; it never falls back to a stat bar.

### Other installed moodle systems

- DrugTime 89: `Stoned` and `Hard`
- Nature's Call: unknown soilage, bladder, bowel, soilage, nearby smell, gut
  health, cramps, and heartburn
- Casualties Undead: High, Miserable, and the worst active clinical condition

Casualties Undead uses its own moodle UI. Its public drug high and condition
readers are observed without creating state. Its blood pressure, oxygen,
bleeding, organs, and condition details belong to the health panel rather than
Needs Expanded; only its continuous drug euphoria becomes a bar here.

Other reviewed active systems stayed out of Needs Expanded: Companion Dogs'
animal needs belong to its companion panel, and its dog-specific moodles have
no exposed read-only active registry; HydeCo Bees'
swelling belongs to body-part health while its poison already feeds the Poison
bar; Fitness Workout Overhaul changes existing vanilla bars; Immersive
Blackouts tracks world utilities; and Scar System records individual injury
scars. `ANGER` and `SANITY` appeared only as reductions or a bath benefit in
the reviewed mod code, without evidence of an active accumulating need.

Nature's Call bladder and bowel remain available as continuous bars as well as
their active threshold moodles. Trait-hidden and unsynchronized values remain
absent.

## Runtime availability

Installation alone does not force a row to exist. A source mod must be active
for the current game, and its player state must already be readable. This is
intentional: Needs Expanded is an observer and does not create missing moodles,
seed ModData, or call source APIs that mutate state during export.

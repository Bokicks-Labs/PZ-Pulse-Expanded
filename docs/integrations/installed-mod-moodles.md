# Installed-mod moodle and stat inventory

This inventory was built from the locally installed Project Zomboid Workshop
sources for Build 42.20. It records moodle-producing mods that Needs Expanded
can read without initializing or mutating their state.

## Continuous stat bars

| Source mod | Mod ID | Stat | Source range | Direction |
|---|---|---|---:|---|
| Lifestyle: Hobbies | `LifestyleHobbies` | Hygiene Need | `0..100` | higher is worse |
| Take A Bath And Shower | `TakeABathAndShowerNew` | Body Grime | `0..100` | higher is worse |
| Brush Your Damn Teeth | `BrushYourDamnTeeth` | Dental Hygiene | `0..1` | higher is better |

Each field is nullable. The collector preserves numeric zero but omits the row
when the mod is inactive, its state table has not initialized, or the individual
value is not finite.

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
| Medicine Moodles | `Antibiotics`, `Antidepressants`, `BetaBlockers`, `Painkillers`, `SleepingTablets` |
| Brush Your Damn Teeth | `BYDT_MouthState` |
| The Mutants | `PZTheMutants_Puked` |

An active unrecognized Moodle Framework registration is still displayed and is
identified as a `Moodle Framework add-on` rather than being silently discarded.

### Other installed moodle systems

- DrugTime 89: `Stoned` and `Hard`
- Nature's Call: unknown soilage, bladder, bowel, soilage, nearby smell, gut
  health, cramps, and heartburn

Nature's Call bladder and bowel remain available as continuous bars as well as
their active threshold moodles. Trait-hidden and unsynchronized values remain
absent.

## Runtime availability

Installation alone does not force a row to exist. A source mod must be active
for the current game, and its player state must already be readable. This is
intentional: Needs Expanded is an observer and does not create missing moodles,
seed ModData, or call source APIs that mutate state during export.

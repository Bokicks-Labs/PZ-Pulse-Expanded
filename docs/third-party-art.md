# Third-party moodle artwork

PZ Pulse Expanded copies the moodle glyphs listed below solely so the PZ Pulse
browser panel can display the same artwork players see in the source mods. The
committed PNG files are embedded as PNG data URIs in `expanded-needs.js`; the
source PNGs themselves are not included twice in the staged Workshop payload.

All third-party artwork remains the property of its respective creator. No
ownership is claimed. If a mod author or rights holder asks for their artwork
or integration to be removed, contact the maintainer and it will be removed
promptly.

## Exact copied files

All source paths below are relative to the named mod. The destination names
are under `third-party-assets/moodle-icons/` in this repository.

### Lifestyle: Hobbies — Workshop 3403870858, author Angry

Copied every PNG in `common/media/ui/moodles/` (63 files):

`AdviceWasted`, `AtHouse`, `Attractive`, `BathCold`, `BathHot`, `BeautyGood`,
`BeautyGood1`, `BeautyGood2`, `BeautyGood3`, `BeautyNeg`, `BeautyNeg1`,
`BeautyNeg2`, `BeautyNeg3`, `BladderNeed`, `Comfort`, `DJAudience`,
`DJAudience1`, `DJAudience2`, `Dunce`, `ElDoradoBad`, `ElDoradoBad1`,
`ElDoradoBad2`, `ElDoradoBad3`, `ElDoradoGood`, `ElDoradoGood1`,
`ElDoradoGood2`, `ElDoradoGood3`, `Embarrassed`, `Eureka`, `FTBad`, `FTGood`,
`Gloomy`, `HomeSick`, `HomeSick1`, `HomeSick2`, `HomeSick3`, `HygieneBad`,
`HygieneBad1`, `HygieneBad2`, `HygieneBad3`, `HygieneGood`, `MindfulState`,
`MindfulState1`, `MindfulState2`, `MintCurio`, `MintFresh`, `MusicBad`,
`MusicBad1`, `MusicGood`, `MusicGood1`, `Nauseous`, `NeuralHat`, `PartyBad`,
`PartyBad1`, `PartyBad2`, `PartyGood`, `PartyGood1`, `PartyGood2`, `SmellGood`,
`TaughtSkill`, `Uncomfortable`, `WasTaughtSkill`, and `Zen` (all `.png`).

### Take A Bath And Shower — Workshop 3592172476, author si-cafe

Copied from `common/media/ui/`: `BodyGrime.png`, `CoolingBody.png`,
`FeelingGaze.png`, `WarmingBody.png`, and `Wet_Bathing.png`.

### Infirmities — Workshop 3579088411, author Twuben

Copied from `common/media/ui/`: `AddictedToAlcohol.png`, `AddictedToAmp.png`,
`AddictedToCaffeine.png`, `AddictedToNicotine.png`,
`AddictedToPainkillers.png`, `AddictedToSleepingPills.png`, `PanicAttack.png`,
`Tremors.png`, and `Withdrawal.png`.

### Medicine Moodles — Workshop 3778856579

Copied from `common/media/ui/`: `Antibiotics.png`, `Antidepressants.png`,
`BetaBlockers.png`, `LemonGrass.png`, `Painkillers.png`, and
`SleepingTablets.png`.

### Brush Your Damn Teeth — Workshop 3794105078, author Cam3

Copied `42/media/ui/BYDT_mouth_state.png` as `teeth/BYDT_MouthState.png`
for the active mouth-state moodle. The earlier mouth glyph is retained as
`teeth/BYDT_DentalHygiene.png` for the separate long-term hygiene bar.

### The Mutants — Workshop 3796669056

Copied `common/media/ui/PZTheMutants_Puked.png`.

### Casualties Undead — Workshop 3805748433

Copied `High.png`, `Miserable.png`, and the eight `Organ_*.png` glyphs from
`common/media/textures/CasualtiesUndead/` into `casualties-undead/` for its
custom moodles and Drug Euphoria bar.

### DrugTime 89 — Workshop 3632964785

Copied from `42/media/ui/`: `DT_Hard_1.png`, `DT_Hard_2.png`,
`DT_Hard_3.png`, `DT_Stoned_1.png`, `DT_Stoned_2.png`, and
`DT_Stoned_3.png`.

### Nature's Call — Workshop 3709126801, author RedChili

Copied from `42.20/media/textures/moodles/`: `CheckPants.png`,
`PissBladder.png`, `StoolIcon.png`, `SoiledClothing.png`,
`Gut_Health_Good.png`, `Gut_Health_Bad.png`, `Stomach_Cramp.png`, and
`AcidReflux.png`. They are stored using the matching runtime moodle names:
`NCUnknownPants.png`, `NCBladder.png`, `NCBowel.png`, `NCSoilage.png`,
`NCGutGood.png`, `NCGutBad.png`, `NCCramps.png`, and `NCHeartburn.png`.

Nature's Call's nearby-smell moodle uses PZ Pulse's existing vanilla noxious
smell glyph, so no additional Nature's Call file is copied for that state.

### Bodily Functions — Workshop 3396456841, creators MonkeyShark and RSilience

Copied from `42/media/ui/`: `Urination.png`, `Defecation.png`,
`PeedSelf.png`, `PoopedSelf.png`, and `BodilyFumes.png` into
`bodily-functions/`. The Urination and Defecation glyphs are also used for
their corresponding Needs Expanded stat bars.

## PZ Pulse artwork

PZ Pulse Expanded does not copy PZ Pulse's vanilla glyphs or colored moodle
circles into this repository. At runtime it reuses the icon map already exposed
by the required PZ Pulse mod.

# ADR 0002: Source-owned integrations and panel composition

## Status

Planned for the update after the Bodily Functions integration is tested and
published. This records the intended refactor; it does not describe the current
file layout.

## Context

`OptionalModStatsAdapter.lua` currently collects values from several unrelated
mods, while Nature's Call and Bodily Functions have dedicated adapters.
`CustomMoodleAdapter.lua` also combines source-specific moodles with a shared
Moodle Framework reader. Adding more mods and panels would make ownership and
failure isolation harder to see.

## Proposed organization

Give each built-in source mod one integration module, even if it initially
exports only one value. Keep shared collection mechanics and panel composition
separate. A target layout is:

```text
PZPulseExpanded/
  Core/                 source registry, validation, stat history, options
  Integrations/         one module per supported source mod
  Moodles/              shared Moodle Framework reader
  Panels/               Needs, Health, and future panel collectors
```

The exact filenames and Lua return shape can be settled during the refactor.
The public provider API remains a draft; this internal move must not silently
publish or freeze it.

## Ownership rules

- An integration owns its mod ID, activation and sandbox checks, source field
  reads, source-specific ranges, multiplayer rules, and conversion to normalized
  values. It may supply stats, moodles, health details, or skills to more than
  one panel.
- Core owns reusable validation, collection health, recent-value policy, and
  source metadata. It does not know a particular mod's private field names.
- The Moodle Framework reader traverses existing framework state once and
  attributes registrations to the owning integration. It does not create or
  update another mod's moodles.
- A panel collector composes source results for that panel. A failure in one
  integration is caught and reported at that source boundary, without removing
  another source's valid values.
- Renderers consume normalized models and own layout, tooltips, and the common
  color palette. Source-derived thresholds or levels retain source provenance;
  the renderer does not read another mod's runtime tables.

## Migration and acceptance

1. Characterize the current collector payload, bar IDs, moodle IDs, source
   labels, saved bar choices and ordering, colors, and failure states in tests.
2. Move one source at a time out of `OptionalModStatsAdapter.lua` and move
   source-specific moodle logic out of `CustomMoodleAdapter.lua` where useful.
3. Keep PZ Pulse extension registration and browser payload compatibility while
   changing internal ownership. Do not reset existing players' panel settings.
4. Run Lua and browser fixtures after each move, including absent, disabled,
   malformed, and multiplayer snapshot cases. Validate the resulting Dev bundle
   in a disposable save before describing the refactor as runtime verified.

This refactor should be a separate update from the Bodily Functions release.

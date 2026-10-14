# ADR 0002: Source-owned integrations and panel composition

## Status

Implemented in the source-owned Lua layout. Fixture validation is complete;
disposable-save runtime validation remains pending.

## Context

Previously, `OptionalModStatsAdapter.lua` collected values from several
unrelated mods, while Nature's Call and Bodily Functions had dedicated
adapters. `CustomMoodleAdapter.lua` also combined source-specific moodles with
a shared Moodle Framework reader.

## Organization

Give each built-in source mod one integration module, even if it initially
exports only one value. Keep shared collection mechanics and panel composition
separate. The implemented layout is:

```text
PZPulseExpanded/
  Core/                 source registry, validation, stat history, options
  Integrations/         source-owned stat and moodle readers
  Moodles/              shared Moodle Framework traversal and composition
  Panels/               Needs collector and optional stat composition
```

Old adapter paths were removed after their in-repo references were updated.
The public provider API remains a draft; this internal move does not publish
or freeze it.

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

The payload, stable IDs, saved choices and order, colors, and failure states
are covered by Lua and browser fixtures. Source logic moved out of the former
combined stat and moodle adapters. The registration and browser payload were
kept compatible; internal callers now use the new paths directly.

Disposable-save validation of the resulting Dev bundle is still required
before describing the refactor as runtime verified. The current edit and
validation workflow is in [`../development.md`](../development.md).

This refactor should be a separate update from the Bodily Functions release.

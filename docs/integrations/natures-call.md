# Nature's Call compatibility

## Supported source

The built-in adapter targets the locally verified release:

- Workshop item: `3709126801`
- mod name: **Nature's Call**
- mod ID: `NC_NaturesCall`
- mod version: `1.0.15`
- Build 42 folder inspected: `mods/NaturesCall/42.20`

Nature's Call remains optional. PZ Pulse Expanded does not declare it as a
dependency.

## Data contract

Nature's Call stores existing per-player state beneath:

```text
player:getModData().NaturesCall
├── bladderFill
├── bowelFill
└── ownerSnapshot        (authoritative synchronized view on a pure MP client)
```

The source definitions declare both fill values as `0..120`:

- `0` is empty and is a valid visible value.
- `70` is the warning threshold.
- `95` is the critical threshold.
- `100` is overflow.
- `120` is the stored maximum, allowing overfill.

Both values are high-is-bad. PZ Pulse Expanded preserves the source's complete
`0..120` range, then uses the shared normalized-stat renderer to convert it to
a `0..100` bar percentage.

The sandbox `BladderRateMult` and `BowelRateMult` settings change how quickly
the values accumulate. They do not change the fill range or its units.

## Read-only lifecycle and multiplayer behavior

The adapter reads the player supplied by PZ Pulse and never calls
`getPlayer()`. It does not call Nature's Call's `ensurePlayerData()`,
`getSnapshot()`, or `getDetailedSnapshot()` because those paths may initialize
or update source-mod state.

In single-player/server-authoritative contexts, the adapter reads the existing
`NaturesCall` table. On a pure multiplayer client, it requires the first
`NaturesCall.ownerSnapshot`; the source mod creates local zero defaults before
the first server synchronization. After that snapshot, the adapter follows
Nature's Call's own fallback to local fills when the owner snapshot disappears.

Nature's Call intentionally hides a bladder or bowel meter for the matching
major-incontinence trait. Its synchronized snapshot represents that as a
negative fill. The adapter omits negative values and also respects the stored
major-trait flags in local/server-authoritative state.

## Failure behavior and icons

Before the first valid reading, missing mod state or an unsynchronized owner
snapshot omits the unavailable row. After a valid reading, each meter retains
its last value during brief missing or invalid reads. The duration is set by
**Missing stat grace period (seconds)** in Options → Mods → PZ Pulse Expanded
(90 seconds by default, 0 to disable retention). A fresh valid reading resets
the timer. Negative fills and major
incontinence flags explicitly hide their meter immediately; an inactive mod
also clears retained readings. The history belongs to the supplied player and
does not modify Nature's Call state.

An unexpected adapter error is retried on the next export. The collector
briefly retains its last successful result under the same grace period
and emits one bounded diagnostic per session. Vanilla Needs+ rows and
Discomfort continue rendering.

PZ Pulse's browser icon map is a private, vanilla-oriented surface and no
Nature's Call keys were verified there. These two rows therefore use the
renderer’s existing aligned icon spacer rather than claiming an unverified
browser icon.

## Compatibility boundary

This integration is based on Nature's Call 1.0.15 source fields and sync
behavior. Those are source-mod internals, not a public provider contract. A
future source-mod change may require updating this adapter. The separate PZ
Pulse Expanded provider API remains a design draft.

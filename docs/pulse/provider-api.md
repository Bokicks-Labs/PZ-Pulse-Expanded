# Provider API

> Status: design draft. This is not yet a published or frozen API.

PZ Pulse Expanded plans to expose a small registration API so other mod authors can add support directly without requiring PZ Pulse Expanded to maintain a compatibility adapter for every mod.

## Design goals

The provider API should let another mod describe its player information semantically without depending on PZ Pulse Expanded's HTML, CSS, or renderer internals.

A provider should answer questions like:

> My mod has a stat called Urination. Its current value is 63, its range is 0–100, and higher values are worse.

PZ Pulse Expanded should own:

- validation
- normalization
- formatting
- bar colors
- panel layout
- HTML escaping
- tooltip behavior
- visibility behavior

## Registration direction

The likely pattern is a shared Lua registry, similar to PZ Pulse's extension API:

```lua
PZ_Expanded_EXT = PZ_Expanded_EXT or {}

table.insert(PZ_Expanded_EXT, {
    api = 1,
    mod = "Some_Mod_Id",
    id = "some_mod",

    collect = function(player)
        return {
            stats = {
                -- normalized provider data
            },
            moodles = {
                -- future
            },
            skills = {
                -- future
            }
        }
    end
})
```

This exact schema is not frozen yet.

## Why a provider instead of renderer hooks

Third-party mods should not need to know:

- PZ Pulse Expanded CSS classes
- panel HTML
- PZ Pulse renderer internals
- tooltip markup
- settings implementation

Providers supply data. PZ Pulse Expanded renders it.

## Built-in adapters and native providers

There are two supported integration strategies.

### Compatibility adapter maintained by PZ Pulse Expanded

```text
source mod
    ↓
PZ Pulse Expanded adapter
    ↓
normalized model
```

This is useful when another mod has no native integration.

### Native provider maintained by the source mod

```text
source mod
    ↓
PZ Pulse Expanded public API
    ↓
normalized model
```

This is preferred because the source mod author understands their own internals and can update the integration alongside their mod.

Both paths must converge on the same normalized models.

## Provenance

Provider identity is required so every displayed item can preserve where it came from.

The normalized item should ultimately carry source metadata such as:

```js
source: {
    type: "mod",
    id: "NaturesCall",
    name: "Nature's Call"
}
```

PZ Pulse Expanded intends to display this in hover tooltips.

## Versioning

The public provider registration should include an API version from its first release:

```lua
api = 1
```

Once API v1 is declared stable, breaking schema changes require a new API version rather than silently changing existing integrations.

## Player object

Provider collectors should receive and use the player object supplied by PZ Pulse Expanded/PZ Pulse.

They should not independently call `getPlayer()` when a supplied player is available, because multiplayer and splitscreen subject selection must remain consistent with the rest of the dashboard.

## Failure behavior

The final API should explicitly document:

- when a provider is called
- what `nil` means
- how invalid items are handled
- how provider exceptions are isolated
- whether repeated failures disable a provider
- what is logged for diagnostics

This behavior is intentionally not frozen until the first provider vertical slice is implemented.

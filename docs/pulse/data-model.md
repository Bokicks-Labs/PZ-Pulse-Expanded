# PZ Expanded Pulse Data Model

## Stat

A Stat represents live numeric state about the current player.

Examples:

- Hunger
- Thirst
- Fatigue
- Discomfort
- Urination
- Bowel state

### Shape

```js
{
    id: "discomfort",
    label: "Discomfort",
    description: "Current underlying discomfort level.",

    value: 27.42,
    min: 0,
    max: 100,
    badHigh: true,

    iconKey: "mood_discomfort",
    visibleByDefault: true,

    source: {
        type: "base_game",
        id: "project_zomboid",
        name: "Project Zomboid"
    }
}

# Architecture Guide

## Scene Hierarchy

### Main Scene
`scenes/outdoor.tscn` — Primary gameplay scene (world exploration)

### Player
- `scenes/player.tscn` — Player character
  - Extends `Character` class
  - Has `SurvivalStats` resource
  - Has `Inventory` resource
  - Uses `LPCAnimatedSprite` for 8-direction animation

### NPCs
- `scenes/npc.tscn` — Base NPC template
  - Has `CharacterStats` for skill checks
  - Has `rapport` per-player relationship
  - Interaction via `Bubble` nodes

---

## Class Inheritance

```
Node
├── FishingGame
└── (Singletons via Autoload)

CharacterBody2D
└── Character (scripts/character.gd)
    ├── Player (scripts/player.gd)
    └── NPC (scripts/npc.gd)

Resource
├── CharacterStats
├── SurvivalStats
├── Inventory
├── Item
├── CrewMember
└── ShipCrew
```

---

## Signal Bus Pattern

Key global signals flow through autoloads:

### GameTime Signals
```gdscript
signal hour_passed(hour: int, day: int)
signal day_passed(day: int)
signal time_updated(hour: int, minute: int, day: int)
```

### SurvivalStats Signals
```gdscript
signal stat_critical(stat_name: String)
signal stat_depleted(stat_name: String)
```

### ShipCrew Signals
```gdscript
signal crew_member_died(member: CrewMember, cause: String)
signal mutiny_warning(mutiny_level: int)
signal mutiny_triggered
```

---

## Resource Files

### Player Resources (`resources/`)
| File | Type | Purpose |
|------|------|---------|
| `player_stats.tres` | CharacterStats | Player's 4 attributes |
| `player_survival.tres` | SurvivalStats | Player's 5 survival needs |
| `player_inventory.tres` | Inventory | Player's carried items |

### Item Resources (`resources/items/`)
All items are `Item` resources with properties:
- `name`, `description`, `icon`
- `belly_restore`, `hydration_restore`, `sobriety_change`
- `vitamin_c`, `value`, `weight`

---

## Interaction System

1. Player has `RayCast2D` (`Target`) for detecting interactables
2. Interactable objects have `Bubble` child node
3. On `interact` action, `Bubble.interact(player)` is called
4. Dialogue uses `DialogueManager` addon with `.dialogue` files

---

## Physics Layers

| Layer | Name | Purpose |
|-------|------|---------|
| 1 | world | Collision with world geometry |
| 2 | interaction | Interactable detection |

---

## Input Actions

| Action | Default Key | Purpose |
|--------|-------------|---------|
| `walk_up/down/left/right` | WASD | Movement |
| `interact` | E | Interact with objects |
| `inventory` | I | Toggle inventory |
| `stealth` | C | Toggle stealth mode (WIP) |

---

## File Naming Conventions

- Scripts: `snake_case.gd`
- Scenes: `snake_case.tscn` or `kebab-case.tscn`
- Resources: `snake_case.tres` or `kebab-case.tres`
- Classes: `PascalCase` via `class_name`

---

## Adding New Features

### New Item
1. Create `.tres` in `resources/items/`
2. Set `script` to `item.gd`
3. Fill in properties (name, effects, icon path)

### New NPC
1. Duplicate `scenes/npc.tscn`
2. Create custom script extending `NPC`
3. Configure `CharacterStats`
4. Add dialogue file in `dialogs/`

### New Mini-game
1. Create game logic script (`scripts/xxx_game.gd`)
2. Create UI script (`scripts/xxx_ui.gd`)
3. Create scene (`scenes/xxx.tscn`)
4. Integrate with player via `Bubble` interaction

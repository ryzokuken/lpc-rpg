# Salt & Scoundrels (lpc-rpg)

## Project Overview

| Property | Value |
|----------|-------|
| **Engine** | Godot 4.6 (GL Compatibility) |
| **Art Style** | 2D Top-Down, LPC 32x32 sprites |
| **Genre** | Survival RPG with turn-based tactical combat |
| **Setting** | Atlantic/Caribbean, Golden Age of Piracy (1650-1730) |
| **Inspiration** | Kingdom Come: Deliverance (grounded realism) |

## Design Pillars

1. **Grounded Realism** -- No magic. Danger comes from scurvy, starvation, and steel.
2. **Democratic Chaos** -- The crew has a voice. Reputation with crewmates matters.
3. **Survival First** -- Success is measured in days survived, not gold hoarded.
4. **Simple Surface, Deep Choices** -- Easy to learn, rich in consequence.

## Godot 4.6 Rules

- Use `@export`, `@onready` (not `export`, `onready`)
- Use `func name() -> ReturnType:` syntax
- Use `super()` not `._ready()` for parent calls
- Typed arrays: `Array[Type]` not `Array`
- Use `Signal.emit()` not `emit_signal()`

## Common Pitfalls

- Don't create new autoloads without updating `project.godot`
- Don't use `preload()` for resources that may not exist yet
- Don't forget to connect signals in `_ready()`
- Don't use `$Path` without `@onready` decorator

## Project Patterns

- Resources use `class_name` and extend `Resource`
- All game logic scripts are in `scripts/`
- All items are `.tres` files in `resources/items/`
- Autoloads: `GameTime`, `ItemRegistry`, `DialogueManager`
- Addons: `DialogueManager` (v3.9.0), `LPCAnimatedSprite` (v4.4.0.1)

## GDScript Conventions

### File structure order

```gdscript
class_name ClassName extends ParentClass
## Brief description

signal something_happened(param: Type)
const MAX_VALUE := 100
enum State {IDLE, ACTIVE, DONE}
@export var config_value: int = 5
@onready var child_node := $ChildNode
var internal_state: State = State.IDLE

func _ready() -> void: ...
func _process(delta: float) -> void: ...
func public_method() -> void: ...
func _private_method() -> void: ...
```

### Naming

| Type | Convention | Example |
|------|------------|---------|
| Variables | `snake_case` | `player_health` |
| Constants | `SCREAMING_SNAKE_CASE` | `MAX_HEALTH` |
| Functions | `snake_case` | `calculate_damage()` |
| Signals | `snake_case` (past tense) | `damage_taken` |
| Classes | `PascalCase` | `CharacterStats` |
| Enums | `PascalCase` enum, `SCREAMING_SNAKE` values | `enum State {IDLE}` |
| Files | `snake_case.gd` | `character_stats.gd` |

### Signal handlers

Use `_on_<source>_<signal_name>` naming. Connect with callables:
```gdscript
some_node.health_changed.connect(_on_player_health_changed)
```

### Antipatterns

- Don't use `$NodePath` without `@onready`
- Don't connect signals in `_init()`
- Don't use `get_node()` when `$` or `%` works
- Don't use untyped arrays where typed arrays work
- Don't create Resources without `class_name`
- Do use `%UniqueName` for UI nodes
- Do prefer signals over direct method calls

## Architecture

### Autoloads

| Name | Script | Purpose |
|------|--------|---------|
| `GameTime` | `scripts/game_time.gd` | In-game time, drives survival/metabolic processing |
| `ItemRegistry` | `scripts/item_registry.gd` | Global item lookup |
| `DialogueManager` | (addon) | Dialogue system |

### Class Hierarchy

```
CharacterBody2D
  Character (scripts/character.gd)
    Player (scripts/player.gd)
    NPC (scripts/npc.gd)

Resource
  CharacterStats, SurvivalStats, Inventory, Item, CrewMember, ShipCrew
```

### Key Signals

```gdscript
# GameTime
signal hour_passed(hour: int, day: int)
signal day_passed(day: int)
signal time_updated(hour: int, minute: int, day: int)

# SurvivalStats
signal stat_critical(stat_name: String)
signal stat_depleted(stat_name: String)

# ShipCrew
signal crew_member_died(member: CrewMember, cause: String)
signal mutiny_warning(mutiny_level: int)
signal mutiny_triggered
```

### Core Data Classes

**CharacterStats** -- 4 attributes (1-10 scale): Brawn, Finesse, Wits, Swagger

**SurvivalStats** -- 5 needs (0-100, 100=healthy): Belly, Hydration, Vigor, Nerve, Sobriety

**CrewMember** -- Per-crew metabolic tracking: hunger, thirst, vitamin_c, morale, drunkenness, health

**ShipCrew** -- Collective management: food/water/rum/citrus supplies, daily rations, mutiny meter

### Interaction System

1. Player has `RayCast2D` (`Target`) for detecting interactables
2. Interactable objects have `Bubble` child node
3. On `interact` action, `Bubble.interact(player)` is called
4. Dialogue uses `DialogueManager` addon with `.dialogue` files

### Physics Layers

| Layer | Name | Purpose |
|-------|------|---------|
| 1 | world | Collision with world geometry |
| 2 | interaction | Interactable detection |

### Input Actions

| Action | Key | Purpose |
|--------|-----|---------|
| `walk_up/down/left/right` | WASD | Movement |
| `interact` | E | Interact with objects |
| `inventory` | I | Toggle inventory |
| `stealth` | C | Toggle stealth mode (WIP) |

## Entry Points

| To modify... | Look at... |
|--------------|------------|
| Player movement | `scripts/player.gd` |
| Survival mechanics | `scripts/survival_stats.gd` |
| Time/clocks | `scripts/game_time.gd` |
| Item effects | `scripts/item.gd` + `resources/items/*.tres` |
| NPC behavior | `scripts/npc.gd` |
| Dialogue | `dialogs/*.dialogue` |
| Crew systems | `scripts/crew_member.gd`, `scripts/ship_crew.gd` |
| Character stats | `scripts/character_stats.gd` |
| Fishing | `scripts/fishing_game.gd`, `scripts/fishing_ui.gd` |
| Liar's Dice | `scripts/liars_dice.gd`, `scripts/liars_dice_ui.gd` |

## Testing

- Main scene: `scenes/outdoor.tscn`
- Player is in `"player"` group
- Use `GameTime.skip_hours(n)` for time testing

### Commands

| Command | What it does |
|---------|-------------|
| `/check` | Validate all GDScript files via `godot --check-only` (fast, no build) |
| `/test-web` | Full build → serve → `preview_screenshot` to verify the game loads |

### How the pipeline works

1. `bash .agent/scripts/build-web.sh` — Godot headless export to `exports/web/`
2. `preview_start "web-game"` — starts `serve.mjs` on port 8080 with COOP/COEP headers
3. `preview_screenshot` — captures the running game for visual verification

The server (`serve.mjs`) sets `Cross-Origin-Opener-Policy: same-origin` and
`Cross-Origin-Embedder-Policy: require-corp`, which browsers require before
allowing SharedArrayBuffer (used by Godot's web threading). A plain file server
will produce a black screen with a SharedArrayBuffer console error.

### Godot executable path

Scripts default to:
`/e/Godot Project/Godot_v4.6-stable_win64.exe/Godot_v4.6-stable_win64_console.exe`

Override with `GODOT_PATH` env var if the path changes.

## Reference Documents

For deeper context beyond what's in this file:
- `.agent/ROADMAP.md` -- 5-phase development plan and open design questions
- `.agent/PROJECT.md` -- Full game context, implemented features, key formulas
- `.agent/ARCHITECTURE.md` -- Detailed scene hierarchy, resource files
- `.agent/CONVENTIONS.md` -- Full GDScript convention examples

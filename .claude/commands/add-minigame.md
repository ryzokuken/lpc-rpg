Add a new mini-game to the game: $ARGUMENTS

## Existing Pattern Reference

See `fishing_game.gd` + `fishing_ui.gd` + `fishing.tscn` for the established pattern.

## Architecture

```
Mini-game
  Logic Script (xxx_game.gd)    # Pure game logic, no UI
  UI Script (xxx_ui.gd)         # Connects UI to logic
  Scene (xxx.tscn)              # Visual layout
```

## Steps

### 1. Create game logic script

Create `scripts/<game>_game.gd`:

```gdscript
class_name XxxGame extends Node
## Brief description of the mini-game

signal game_started
signal game_ended(success: bool, result: Variant)

const SOME_CONSTANT := 100

enum Phase {IDLE, PLAYING, COMPLETE}

var current_phase: Phase = Phase.IDLE
var player_skill: int = 5

func start_game(skill: int = 5) -> void:
    player_skill = skill
    current_phase = Phase.PLAYING
    game_started.emit()

func process_game(delta: float) -> bool:
    if current_phase != Phase.PLAYING:
        return false
    # Game logic here
    return false  # Return true when phase changes

func _end_game(success: bool) -> void:
    current_phase = Phase.COMPLETE
    game_ended.emit(success, null)

func reset() -> void:
    current_phase = Phase.IDLE

func is_active() -> bool:
    return current_phase == Phase.PLAYING
```

### 2. Create UI script

Create `scripts/<game>_ui.gd`:

```gdscript
extends Control

@onready var game: XxxGame = $XxxGame
@onready var start_button: Button = $StartButton
@onready var result_label: Label = $ResultLabel

func _ready() -> void:
    game.game_started.connect(_on_game_started)
    game.game_ended.connect(_on_game_ended)
    start_button.pressed.connect(_on_start_pressed)

func _process(delta: float) -> void:
    if game.is_active():
        game.process_game(delta)
        _update_ui()

func _on_start_pressed() -> void:
    var player = get_tree().current_scene.get_node("Player")
    var skill = player.stats.finesse if player.stats else 5
    game.start_game(skill)

func _on_game_started() -> void:
    start_button.hide()

func _on_game_ended(success: bool, _result: Variant) -> void:
    result_label.text = "Success!" if success else "Failed!"
    start_button.show()

func _update_ui() -> void:
    pass
```

### 3. Create scene

Create `scenes/<game>.tscn`:
1. Root: `Control` (or `Node2D` if positional)
2. Add child `XxxGame` node with game script
3. Add UI elements (buttons, labels, progress bars)
4. Assign UI script to root

### 4. Integrate with world

Trigger via interaction spot:
```gdscript
func interact(player: Player) -> void:
    var mini_game = preload("res://scenes/<game>.tscn").instantiate()
    add_child(mini_game)
    await mini_game.game.game_ended
    mini_game.queue_free()
```

### 5. Connect to survival/rewards

After `game_ended` signal, apply results:
- Modify survival stats
- Add items to inventory
- Grant currency
- Affect reputation

## Validation Checklist

- [ ] Game logic separated from UI
- [ ] All phases have clear transitions
- [ ] Game can be reset and replayed
- [ ] Player stats affect difficulty/outcomes
- [ ] UI responds to all signals
- [ ] Results affect game world appropriately
- [ ] Game handles interruption gracefully

## Existing Examples

| Game | Logic | UI | Scene |
|------|-------|-----|-------|
| Fishing | `fishing_game.gd` | `fishing_ui.gd` | `fishing.tscn` |
| Liar's Dice | `liars_dice.gd` | `liars_dice_ui.gd` | `liars_dice.tscn` |

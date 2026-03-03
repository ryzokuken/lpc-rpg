# GDScript Conventions

## File Structure

Every `.gd` file follows this order:

```gdscript
class_name ClassName extends ParentClass
## Brief description of what this class does

# Signals
signal something_happened(param: Type)

# Constants
const MAX_VALUE := 100

# Enums
enum State {IDLE, ACTIVE, DONE}

# @export variables
@export var config_value: int = 5

# @onready variables
@onready var child_node := $ChildNode

# Regular variables
var internal_state: State = State.IDLE

# Lifecycle methods
func _ready() -> void:
    pass

func _process(delta: float) -> void:
    pass

# Public methods (API)
func do_something() -> void:
    pass

# Private methods (prefixed with _)
func _internal_helper() -> void:
    pass
```

---

## Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Variables | `snake_case` | `player_health` |
| Constants | `SCREAMING_SNAKE_CASE` | `MAX_HEALTH` |
| Functions | `snake_case` | `calculate_damage()` |
| Signals | `snake_case` (past tense) | `damage_taken` |
| Classes | `PascalCase` | `CharacterStats` |
| Enums | `PascalCase` enum, `SCREAMING_SNAKE` values | `enum State {IDLE, ACTIVE}` |
| Files | `snake_case.gd` | `character_stats.gd` |

---

## Type Hints

Always use static typing:

```gdscript
# Good
var health: int = 100
func take_damage(amount: int) -> void:
    health -= amount

# Bad
var health = 100
func take_damage(amount):
    health -= amount
```

---

## Comments & Documentation

```gdscript
## Doc comment for class or exported var (shows in editor)
@export var speed: float = 100.0

# Regular comment for implementation notes
var _internal: int = 0

# Section headers with separators
# ============================================================================
# SECTION NAME
# ============================================================================
```

---

## Signal Patterns

```gdscript
# Define with types
signal health_changed(new_value: int, old_value: int)

# Emit with values
func take_damage(amount: int) -> void:
    var old := health
    health -= amount
    health_changed.emit(health, old)

# Connect (prefer callables)
some_node.health_changed.connect(_on_health_changed)

# Handler naming: _on_<source>_<signal_name>
func _on_player_health_changed(new_val: int, old_val: int) -> void:
    pass
```

---

## Resource Patterns

```gdscript
# Define as class
class_name MyResource extends Resource

# Use @export for editor
@export var value: int = 0

# Static factory methods
static func create_default() -> MyResource:
    var res := MyResource.new()
    res.value = 50
    return res
```

---

## Common Antipatterns to Avoid

❌ **Don't** use `$NodePath` in `_ready()` without `@onready`
❌ **Don't** connect signals in `_init()`
❌ **Don't** use `get_node()` when `$` or `%` works
❌ **Don't** use untyped arrays where typed arrays work
❌ **Don't** create Resources without `class_name`

✅ **Do** use `@onready` for node references
✅ **Do** use `%UniqueName` for UI nodes
✅ **Do** use typed arrays: `Array[Item]`
✅ **Do** prefer signals over direct method calls
✅ **Do** use `class_name` for all reusable classes

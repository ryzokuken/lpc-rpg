# Agent Instructions

> **Superseded by project-level `CLAUDE.md`.** Claude Code loads `CLAUDE.md` automatically. This file is kept for reference.

> Read this first before any task.

## Context Loading Order

1. **This file** — Execution rules
2. **PROJECT.md** — Game context (read for ANY task)
3. **ARCHITECTURE.md** — Read if touching scripts/scenes
4. **CONVENTIONS.md** — Read before writing code
5. **Relevant workflow** — If task matches a `/slash-command`

## Critical Rules

### Godot 4.6 Specifics
- Use `@export`, `@onready` (not `export`, `onready`)
- Use `func name() -> ReturnType:` syntax
- Use `super()` not `._ready()` for parent calls
- Typed arrays: `Array[Type]` not `Array`
- Use `Signal.emit()` not `emit_signal()`

### Project Patterns
- Resources use `class_name` and extend `Resource`
- All game logic scripts are in `scripts/`
- All items are `.tres` files in `resources/items/`
- Autoloads: `GameTime`, `ItemRegistry`, `DialogueManager`

### Testing
- Run game from `scenes/outdoor.tscn` (main scene)
- Player exists in "player" group
- Use `GameTime.skip_hours(n)` for time testing
- **Run `/test-web` workflow after every major feature change** to verify web build compatibility

## Common Pitfalls

❌ Don't create new autoloads without updating `project.godot`
❌ Don't use `preload()` for resources that may not exist yet
❌ Don't forget to connect signals in `_ready()`
❌ Don't use `$Path` without `@onready` decorator

## When Stuck

1. Check existing similar implementation (fishing, liars_dice)
2. Check if signal exists in target class
3. Verify resource script assignment in `.tres`
4. Run Godot to see actual error messages

# Task Index

> **Superseded by project-level `CLAUDE.md` and `.claude/commands/`.** Entry points are in `CLAUDE.md`. Workflows are now slash commands: `/add-item`, `/add-npc`, `/add-minigame`, `/test-web`, `/roadmap`.

Quick reference for common development tasks. Each links to detailed workflows.

---

## Feature Development

| Task | Complexity | Workflow |
|------|------------|----------|
| Add new consumable item | Low | [add-item.md](workflows/add-item.md) |
| Create new NPC | Medium | [add-npc.md](workflows/add-npc.md) |
| Add new mini-game | High | [add-minigame.md](workflows/add-minigame.md) |
| **Test Web Build** | Low | [test-web.md](workflows/test-web.md) |
| Add new survival stat | Medium | See `survival_stats.gd` |


---

## Bug Fixing

1. Check if issue is in scripts or scene configuration
2. Use Godot debugger to trace execution
3. Check signal connections in scene tree
4. Verify resource assignments (@export vars)

---

## Testing

```bash
# Run Godot from command line with scene
godot --path . res://scenes/outdoor.tscn

# Run specific test scene (if created)
godot --path . res://scenes/test/test_survival.tscn
```

---

## Common Entry Points

| To modify... | Look at... |
|--------------|------------|
| Player movement | `scripts/player.gd` |
| Survival mechanics | `scripts/survival_stats.gd` |
| Time/clocks | `scripts/game_time.gd` |
| Item effects | `scripts/item.gd` + `.tres` files |
| NPC behavior | `scripts/npc.gd` |
| Dialogue | `dialogs/*.dialogue` |
| Crew systems | `scripts/crew_member.gd`, `scripts/ship_crew.gd` |

---

## Quick Code Snippets

### Add survival penalty effect
```gdscript
# In survival_stats.gd, add to get_skill_penalty()
if my_new_stat < THRESHOLD_MODERATE:
    penalty += 10
```

### Create item that affects survival
```gdscript
# In item.gd, add to consume()
if item.belly_restore > 0:
    survival.modify_belly(item.belly_restore)
```

### Connect to time signals
```gdscript
func _ready() -> void:
    GameTime.hour_passed.connect(_on_hour_passed)

func _on_hour_passed(hour: int, day: int) -> void:
    # React to time
    pass
```

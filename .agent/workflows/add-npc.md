---
description: Create a new interactive NPC with dialogue
migrated: .claude/commands/add-npc.md
---

> **Migrated to `.claude/commands/add-npc.md`.** Use `/add-npc` in Claude Code.

// turbo-all

# Add New NPC Workflow

## Prerequisites
- NPC concept (name, role, dialogue purpose)
- Character sprite (or use existing LPC base)

## Steps

### 1. Create dialogue file

Create `dialogs/<npc-name>.dialogue`:

```dialogue
~ start

NPC Name: Hello there, traveler.
- Greetings. => greeting
- What do you sell? => trade
- Farewell. => END

~ greeting

NPC Name: Good day to you as well.
=> END

~ trade

NPC Name: I have wares if you have coin.
=> END
```

### 2. Create NPC script (if custom behavior needed)

Create `scripts/<npc-name>.gd`:

```gdscript
extends NPC

func _ready() -> void:
    super._ready()
    character_name = "NPC Name"
    dialogue_file = preload("res://dialogs/<npc-name>.dialogue")
```

### 3. Create NPC scene

Option A: Duplicate existing NPC
1. Right-click `scenes/npc.tscn` → Duplicate
2. Rename to `<npc-name>.tscn`
3. Assign custom script

Option B: Create new inherited scene
1. Scene → New Inherited Scene → `npc.tscn`
2. Configure overrides

### 4. Configure CharacterStats

In the NPC scene, set the `stats` resource:
- Reasonable attribute values for the character type
- Consider: Will player intimidate/persuade this NPC?

| NPC Type | Brawn | Finesse | Wits | Swagger |
|----------|-------|---------|------|---------|
| Merchant | 3 | 4 | 7 | 6 |
| Sailor | 6 | 5 | 4 | 5 |
| Captain | 7 | 4 | 6 | 8 |
| Thief | 3 | 8 | 6 | 4 |

### 5. Place in scene

1. Open target scene (e.g., `outdoor.tscn`)
2. Instance `<npc-name>.tscn`
3. Position on map
4. Verify interaction Bubble is positioned correctly

### 6. Test interaction

1. Run game
2. Approach NPC until interaction tooltip appears
3. Press E to interact
4. Verify dialogue plays correctly
5. Test all dialogue branches

## Validation Checklist

- [ ] Dialogue file has no syntax errors
- [ ] NPC script extends `NPC` class
- [ ] CharacterStats assigned
- [ ] LPC sprite configured
- [ ] Bubble collision on correct layer (interaction)
- [ ] Dialogue plays when interacting
- [ ] All dialogue branches work

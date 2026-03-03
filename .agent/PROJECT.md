# Salt & Scoundrels — Project Context

> A grounded, gritty survival RPG about the life of an ordinary pirate during the Golden Age of Piracy (1650–1730)

## Quick Facts

| Property | Value |
|----------|-------|
| **Engine** | Godot 4.6 |
| **Art Style** | 2D Top-Down, LPC 32x32 sprites |
| **Genre** | Survival RPG with turn-based tactical combat |
| **Setting** | Atlantic/Caribbean, Golden Age of Piracy |
| **Inspiration** | Kingdom Come: Deliverance (grounded realism) |

---

## Design Pillars

1. **Grounded Realism** — No magic. Danger comes from scurvy, starvation, and steel.
2. **Democratic Chaos** — The crew has a voice. Reputation with crewmates matters.
3. **Survival First** — Success is measured in days survived, not gold hoarded.
4. **Simple Surface, Deep Choices** — Easy to learn, rich in consequence.

---

## Project Structure

```
lpc-rpg/
├── scripts/          # GDScript files (core logic)
├── scenes/           # .tscn scene files
├── resources/        # .tres resources (items, stats)
├── sprites/          # LPC character and tile sprites
├── sounds/           # Audio files
├── dialogs/          # Dialogue Manager dialogue files
├── fonts/            # Font resources
├── themes/           # UI themes
├── tilesets/         # TileSet resources
└── addons/           # LPCAnimatedSprite, DialogueManager
```

---

## Autoload Singletons

| Name | Script | Purpose |
|------|--------|---------|
| `GameTime` | `scripts/game_time.gd` | In-game time, drives survival/metabolic processing |
| `ItemRegistry` | `scripts/item_registry.gd` | Global item lookup |
| `DialogueManager` | (addon) | Dialogue system |

---

## Core Data Classes

### CharacterStats (`scripts/character_stats.gd`)
4 attributes (1-10 scale):
- **Brawn** — Physical strength, melee, intimidation
- **Finesse** — Dexterity, ranged, pickpocket, crafting
- **Wits** — Intelligence, deception, navigation, gambling
- **Swagger** — Charisma, persuasion, leadership, bartering

### SurvivalStats (`scripts/survival_stats.gd`)
5 survival needs (0-100 scale, 100=healthy):
- **Belly** — Nourishment
- **Hydration** — Thirst
- **Vigor** — Energy/stamina
- **Nerve** — Mental stability
- **Sobriety** — Alcohol effects (100=sober)

### CrewMember (`scripts/crew_member.gd`)
Per-crew metabolic tracking:
- Hunger, Thirst, Vitamin C, Morale, Drunkenness
- Ship roles (Captain, Quartermaster, Gunner, Cook, etc.)
- Scurvy system, death signals

### ShipCrew (`scripts/ship_crew.gd`)
Collective ship management:
- Supply stores (food, water, rum, citrus)
- Daily ration processing
- Mutiny meter tracking

---

## Implemented Features

| Feature | Scripts | Scenes |
|---------|---------|--------|
| Fishing Mini-game | `fishing_game.gd`, `fishing_ui.gd` | `fishing.tscn`, `fishing_spot.tscn` |
| Liar's Dice | `liars_dice.gd`, `liars_dice_ai.gd`, `liars_dice_ui.gd` | `liars_dice.tscn` |
| Time System | `game_time.gd`, `clock_ui.gd` | `clock_ui.tscn` |
| Inventory | `inventory.gd`, `inventoryui.gd`, `item.gd` | `inventory.tscn` |
| Dialogue | `balloon.gd` | `balloon.tscn` |
| NPC Interaction | `npc.gd`, `bubble.gd` | `npc.tscn` |

---

## Item System

Items are `.tres` resources in `resources/items/`:

| Category | Examples |
|----------|----------|
| **Food** | hardtack, salt-beef, bread, fresh-fish, dried-fish, fruit |
| **Drinks** | water, grog, rum, wine, small-beer |
| **Valuables** | necklace-diamond, ring-engraved, etc. |

Food/drink items affect survival stats (belly, hydration, sobriety, vitamin_c).

---

## Time System

- 1 real second = 1 game minute (configurable)
- Time periods: Dawn, Morning, Afternoon, Evening, Night
- Signals: `hour_passed`, `day_passed`, `time_updated`
- Drives hourly survival drain and daily crew rations

---

## Key Formulas

### Skill Check
```gdscript
check_value = (primary * 4) + (secondary * 2) + (skill_level / 2)
success = roll(1-100) <= check_value - difficulty + modifiers
```

### Survival Penalties
| Stat Level | Penalty |
|------------|---------|
| 75%+ | Normal |
| 50-74% | -5% skill checks |
| 25-49% | -15% skill checks |
| 1-24% | -30% skill checks |
| 0% | Death/Collapse/Breakdown |

---

## Open Development Areas

Refer to `.agent/ROADMAP.md` for detailed next steps.

class_name StatusEffect extends Resource
## Simple status effect system
## Effects are defined as static data, applied via IDs

# Effect definitions with modifiers
const EFFECTS: Dictionary = {
	# === SURVIVAL DEBUFFS (auto-applied based on stat thresholds) ===
	"hungry": {"name": "Hungry", "skill_mod": - 5, "speed_mod": - 10},
	"starving": {"name": "Starving", "skill_mod": - 15, "speed_mod": - 25},
	"thirsty": {"name": "Thirsty", "skill_mod": - 10, "speed_mod": - 15},
	"dehydrated": {"name": "Dehydrated", "skill_mod": - 25, "speed_mod": - 40, "cant_run": true},
	"tired": {"name": "Tired", "skill_mod": - 5, "accuracy_mod": - 10},
	"exhausted": {"name": "Exhausted", "skill_mod": - 15, "accuracy_mod": - 20, "cant_run": true},
	"anxious": {"name": "Anxious", "skill_mod": - 5, "swagger_mod": - 2},
	"breaking": {"name": "Breaking", "skill_mod": - 15, "swagger_mod": - 3},
	"tipsy": {"name": "Tipsy", "accuracy_mod": - 15, "swagger_mod": + 1},
	"drunk": {"name": "Drunk", "accuracy_mod": - 30, "swagger_mod": + 2, "wits_mod": - 2},
	"blackout": {"name": "Blackout", "accuracy_mod": - 50, "swagger_mod": + 3, "wits_mod": - 4, "cant_run": true},

	# === PERMANENT TRAITS ===
	"missing_eye": {"name": "Missing Eye", "accuracy_mod": - 15, "finesse_mod": - 1, "permanent": true},
	"missing_hand": {"name": "Missing Hand", "finesse_mod": - 3, "brawn_mod": - 1, "permanent": true},
	"peg_leg": {"name": "Peg Leg", "speed_mod": - 30, "finesse_mod": - 2, "cant_run": true, "permanent": true},
	"scarred": {"name": "Scarred", "swagger_mod": - 1, "permanent": true},
	"veteran": {"name": "Veteran", "skill_mod": + 5, "wits_mod": + 1, "permanent": true},
	"quick": {"name": "Quick Reflexes", "finesse_mod": + 1, "accuracy_mod": + 10, "permanent": true},
	"hardy": {"name": "Hardy", "brawn_mod": + 1, "max_hp_mod": + 15, "permanent": true},
	"charming": {"name": "Charming", "swagger_mod": + 2, "permanent": true},
}

## Get effect data by ID
static func get_effect(id: String) -> Dictionary:
	return EFFECTS.get(id, {})

## Get display name
static func get_display_name(id: String) -> String:
	return EFFECTS.get(id, {}).get("name", id)

## Check if effect is permanent (trait)
static func is_permanent(id: String) -> bool:
	return EFFECTS.get(id, {}).get("permanent", false)

## Calculate aggregate modifier from a list of effect IDs
static func calculate_modifier(effect_ids: Array, modifier_name: String) -> int:
	var total: int = 0
	for id in effect_ids:
		total += EFFECTS.get(id, {}).get(modifier_name, 0)
	return total

## Get random positive trait
static func get_random_positive_trait() -> String:
	var traits: Array[String] = ["veteran", "quick", "hardy", "charming"]
	return traits[randi() % traits.size()]

## Get random negative trait
static func get_random_negative_trait() -> String:
	var traits: Array[String] = ["missing_eye", "missing_hand", "peg_leg", "scarred"]
	return traits[randi() % traits.size()]

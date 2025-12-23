class_name CharacterStats extends Resource
## Core attributes for characters (Player and NPCs)
## 4 attributes: 2 body (Brawn, Finesse), 2 mind (Wits, Swagger)

# ============================================================================
# CORE ATTRIBUTES (1-10 scale)
# ============================================================================

## Physical strength, toughness, intimidating presence
## Used for: Melee damage, blocking, HP, intimidation, labor, carrying capacity
@export_range(1, 10) var brawn: int = 5

## Dexterity, precision, agility, sleight of hand
## Used for: Ranged accuracy, dodge, crit chance, pickpocket, crafting, surgery
@export_range(1, 10) var finesse: int = 5

## Intelligence, perception, cunning, problem-solving
## Used for: Initiative, spotting, deception, navigation, gambling, appraisal
@export_range(1, 10) var wits: int = 5

## Charisma, confidence, leadership, social force
## Used for: Persuasion, leadership, bartering, crew morale, recruitment
@export_range(1, 10) var swagger: int = 5

# ============================================================================
# DERIVED STATS
# ============================================================================

## Maximum health points (base 50 + brawn bonus)
func get_max_health() -> int:
	return 50 + (brawn * 10)

## How much weight the character can carry
func get_carry_capacity() -> int:
	return 10 + (brawn * 5)

## Combat initiative (who acts first)
func get_initiative() -> int:
	return wits + finesse

## Base melee damage modifier
func get_melee_damage_bonus() -> int:
	return brawn - 5 # -4 to +5 range

## Base ranged accuracy modifier
func get_ranged_accuracy_bonus() -> int:
	return finesse - 5 # -4 to +5 range

## Base dodge chance (percentage)
func get_dodge_chance() -> int:
	return 5 + (finesse * 2) # 7% to 25%

## Base critical hit chance (percentage)
func get_crit_chance() -> int:
	return (finesse + wits) / 2 # 1% to 10%

# ============================================================================
# SKILL CHECK CALCULATIONS
# ============================================================================

## Calculate the base check value for a skill attempt
## primary: Main attribute (1-10)
## secondary: Supporting attribute (1-10)
## skill_level: Trained skill level (0-100)
## Returns: A value from ~10 to ~100 representing success chance
func calculate_check_value(primary: int, secondary: int, skill_level: int = 0) -> int:
	return (primary * 4) + (secondary * 2) + floori(skill_level / 2.0)

## Attempt a skill check against a difficulty
## Returns true if successful
func attempt_check(primary: int, secondary: int, difficulty: int, skill_level: int = 0, modifiers: int = 0) -> bool:
	var check_value: int = calculate_check_value(primary, secondary, skill_level) + modifiers - difficulty
	check_value = clampi(check_value, 5, 95) # Always 5-95% chance
	var roll: int = randi_range(1, 100)
	return roll <= check_value

# ============================================================================
# SOCIAL INTERACTION CHECKS
# ============================================================================

## Intimidation check value (Brawn + Swagger)
## Modifiers: +10 if armed, +5 per ally present, -5 if target is brave
func get_intimidation_value(modifiers: int = 0) -> int:
	return calculate_check_value(brawn, swagger) + modifiers

## Persuasion check value (Swagger + Wits)
## Modifiers: scaled by rapport (-20 to +20 based on -100 to +100 rapport)
func get_persuasion_value(rapport: int = 0, modifiers: int = 0) -> int:
	var rapport_mod: int = rapport / 5 # -20 to +20
	return calculate_check_value(swagger, wits) + rapport_mod + modifiers

## Deception check value (Wits + Finesse)
## Modifiers: +10 vs strangers, -10 vs those who know you well
func get_deception_value(modifiers: int = 0) -> int:
	return calculate_check_value(wits, finesse) + modifiers

## Pickpocket check value (Finesse + Wits)
## Modifiers: -20 if target is alert, +10 in crowds
func get_pickpocket_value(modifiers: int = 0) -> int:
	return calculate_check_value(finesse, wits) + modifiers

# ============================================================================
# UTILITY METHODS
# ============================================================================

## Create default balanced stats
static func create_balanced() -> CharacterStats:
	var stats := CharacterStats.new()
	stats.brawn = 5
	stats.finesse = 5
	stats.wits = 5
	stats.swagger = 5
	return stats

## Create stats for a specific archetype
static func create_archetype(archetype: String) -> CharacterStats:
	var stats := CharacterStats.new()
	match archetype:
		"brute": # Strong fighter
			stats.brawn = 8
			stats.finesse = 4
			stats.wits = 3
			stats.swagger = 5
		"thief": # Sneaky pickpocket
			stats.brawn = 3
			stats.finesse = 8
			stats.wits = 6
			stats.swagger = 3
		"captain": # Charismatic leader
			stats.brawn = 5
			stats.finesse = 4
			stats.wits = 5
			stats.swagger = 8
		"navigator": # Smart planner
			stats.brawn = 3
			stats.finesse = 5
			stats.wits = 8
			stats.swagger = 4
		_: # Balanced default
			stats.brawn = 5
			stats.finesse = 5
			stats.wits = 5
			stats.swagger = 5
	return stats

## Get a text description of the character's strongest trait
func get_dominant_trait() -> String:
	var max_val: int = maxi(maxi(brawn, finesse), maxi(wits, swagger))
	if brawn == max_val:
		return "Strong"
	elif finesse == max_val:
		return "Dexterous"
	elif wits == max_val:
		return "Cunning"
	else:
		return "Charismatic"

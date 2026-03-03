class_name CrewMember extends Resource
## Individual crew member with metabolic stats tracked per-person
## Used for both player companion crew and enemy crews

signal metabolic_warning(member: CrewMember, stat: String, value: int)
signal scurvy_onset(member: CrewMember)
signal death(member: CrewMember, cause: String)

# ============================================================================
# IDENTITY
# ============================================================================

@export var member_name: String = "Sailor"
@export var portrait_index: int = 0 # Index into LPC sprite sheet

# Ship Role (provides passive buffs when assigned)
enum ShipRole {NONE, CAPTAIN, QUARTERMASTER, BOATSWAIN, GUNNER, CARPENTER, COOK, NAVIGATOR, SURGEON}
@export var role: ShipRole = ShipRole.NONE

# ============================================================================
# CORE ATTRIBUTES (1-10, scales with player progression)
# ============================================================================

@export_range(1, 10) var brawn: int = 5
@export_range(1, 10) var finesse: int = 5
@export_range(1, 10) var wits: int = 5
@export_range(1, 10) var swagger: int = 5

## Calculate crew "level" for scaling purposes (1-10 based on average stats)
func get_level() -> int:
	return ceili((brawn + finesse + wits + swagger) / 4.0)

# ============================================================================
# METABOLIC STATS (0-100 scale)
# Per-crew as specified in manifesto
# ============================================================================

## Hunger: 100 = full, 0 = starving
@export_range(0, 100) var hunger: int = 100

## Thirst: 100 = hydrated, 0 = dehydrated
@export_range(0, 100) var thirst: int = 100

## Vitamin C: 100 = healthy, 0 = scurvy (Max HP/Speed debuff)
@export_range(0, 100) var vitamin_c: int = 100

## Drunkenness: 0 = sober, 100 = blackout (affects accuracy)
@export_range(0, 100) var drunkenness: int = 0

## Morale: 100 = loyal, 0 = mutinous
@export_range(0, 100) var morale: int = 75

## Health: 100 = full, 0 = dead
@export_range(0, 100) var health: int = 100

## Is this crew member alive?
var is_alive: bool = true

# ============================================================================
# METABOLIC DECAY RATES (per in-game hour)
# Balanced for ~2 meals/day, water more frequently
# ============================================================================

const HUNGER_DECAY_PER_HOUR: float = 2.0 # ~50 hours to starve from full
const THIRST_DECAY_PER_HOUR: float = 3.0 # ~33 hours to dehydrate
const VITAMIN_C_DECAY_PER_DAY: float = 5.0 # ~20 days to get scurvy
const DRUNKENNESS_DECAY_PER_HOUR: float = 8.0 # Sobering up

# Scurvy threshold
const SCURVY_THRESHOLD: int = 25
var has_scurvy: bool = false

# ============================================================================
# METABOLIC PROCESSING
# ============================================================================

## Process one hour of metabolic decay
func process_hour() -> void:
	if not is_alive:
		return

	# Hunger decay
	hunger = maxi(0, hunger - int(HUNGER_DECAY_PER_HOUR))
	if hunger <= 10:
		metabolic_warning.emit(self, "hunger", hunger)

	# Thirst decay
	thirst = maxi(0, thirst - int(THIRST_DECAY_PER_HOUR))
	if thirst <= 10:
		metabolic_warning.emit(self, "thirst", thirst)

	# Vitamin C decays slower (per day, called 24x so divide)
	var vc_decay: float = VITAMIN_C_DECAY_PER_DAY / 24.0
	vitamin_c = maxi(0, vitamin_c - int(vc_decay))

	# Check for scurvy onset
	if vitamin_c <= SCURVY_THRESHOLD and not has_scurvy:
		has_scurvy = true
		scurvy_onset.emit(self)
	elif vitamin_c > SCURVY_THRESHOLD:
		has_scurvy = false

	# Drunkenness fades over time
	drunkenness = maxi(0, drunkenness - int(DRUNKENNESS_DECAY_PER_HOUR))

	# Health damage from starvation/dehydration
	if hunger == 0:
		health -= 2
	if thirst == 0:
		health -= 3

	# Morale affected by hunger/thirst
	if hunger < 25 or thirst < 25:
		morale = maxi(0, morale - 1)

	# Check for death
	if health <= 0:
		_die(_determine_death_cause())

func _determine_death_cause() -> String:
	if thirst == 0:
		return "dehydration"
	elif hunger == 0:
		return "starvation"
	elif has_scurvy:
		return "scurvy"
	else:
		return "unknown"

func _die(cause: String) -> void:
	is_alive = false
	health = 0
	death.emit(self, cause)

# ============================================================================
# CONSUMPTION (FOOD & DRINK)
# ============================================================================

## Eat food - restores hunger, may affect thirst
func eat(food_data: Dictionary) -> void:
	var nutrition: int = food_data.get("nutrition", 20)
	var thirst_cost: int = food_data.get("thirst_cost", 0) # Salt beef increases thirst
	var vitamin_c_value: int = food_data.get("vitamin_c", 0) # Citrus!

	hunger = mini(100, hunger + nutrition)
	thirst = maxi(0, thirst - thirst_cost) # Salty food costs thirst
	vitamin_c = mini(100, vitamin_c + vitamin_c_value)

## Drink water/grog
func drink(drink_data: Dictionary) -> void:
	var hydration: int = drink_data.get("hydration", 30)
	var alcohol: int = drink_data.get("alcohol", 0) # Rum/grog
	var morale_boost: int = drink_data.get("morale_boost", 0)

	thirst = mini(100, thirst + hydration)
	drunkenness = mini(100, drunkenness + alcohol)
	morale = mini(100, morale + morale_boost)

# ============================================================================
# COMBAT MODIFIERS (affected by metabolics)
# ============================================================================

## Get accuracy modifier (drunkenness penalty)
func get_accuracy_modifier() -> float:
	# Drunkenness causes accuracy penalty
	# 0 drunk = 1.0x, 50 drunk = 0.75x, 100 drunk = 0.5x
	return 1.0 - (drunkenness * 0.005)

## Get max HP modifier (scurvy penalty)
func get_max_hp_modifier() -> float:
	if has_scurvy:
		return 0.7 # 30% HP reduction
	return 1.0

## Get speed modifier (hunger/thirst/scurvy penalties)
func get_speed_modifier() -> float:
	var modifier: float = 1.0
	if hunger < 25:
		modifier -= 0.15
	if thirst < 25:
		modifier -= 0.20
	if has_scurvy:
		modifier -= 0.25
	return maxf(0.3, modifier)

## Get effective max health
func get_max_health() -> int:
	var base_hp: int = 50 + (brawn * 10) # 60-150 range
	return int(base_hp * get_max_hp_modifier())

# ============================================================================
# SCALING & GENERATION
# ============================================================================

## Generate a random crew member scaled to a target level (1-10)
static func generate_random(target_level: int, variance: int = 2) -> CrewMember:
	var member := CrewMember.new()

	# Random name from pool
	const NAMES := ["Jack", "William", "Thomas", "John", "Edward", "Henry", "Charles",
	                "Anne", "Mary", "Elizabeth", "Grace", "Sarah", "Catherine", "Margaret"]
	const SURNAMES := ["Sparrow", "Rackham", "Bonny", "Teach", "Roberts", "Kidd", "Morgan",
	                   "Flint", "Silver", "Hawkins", "Bones", "Hands", "Merry", "Trelawny"]
	member.member_name = NAMES[randi() % NAMES.size()] + " " + SURNAMES[randi() % SURNAMES.size()]

	# Generate stats around target level with variance
	var min_stat: int = maxi(1, target_level - variance)
	var max_stat: int = mini(10, target_level + variance)

	member.brawn = randi_range(min_stat, max_stat)
	member.finesse = randi_range(min_stat, max_stat)
	member.wits = randi_range(min_stat, max_stat)
	member.swagger = randi_range(min_stat, max_stat)

	# Random role (most are NONE)
	if randf() < 0.2:
		member.role = randi_range(1, ShipRole.size() - 1) as ShipRole

	# Start with healthy metabolics
	member.hunger = randi_range(70, 100)
	member.thirst = randi_range(70, 100)
	member.vitamin_c = randi_range(80, 100)
	member.morale = randi_range(60, 90)
	member.drunkenness = 0
	member.health = 100

	return member

## Generate an enemy crew scaled to player's average level
static func generate_enemy(player_level: int, difficulty_mod: int = 0) -> CrewMember:
	var target_level: int = clampi(player_level + difficulty_mod, 1, 10)
	return generate_random(target_level, 1)

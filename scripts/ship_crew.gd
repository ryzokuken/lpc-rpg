class_name ShipCrew extends Resource
## Manages a ship's entire crew with collective metabolic processing
## Used for player ship and enemy ships

signal crew_member_died(member: CrewMember, cause: String)
signal mutiny_warning(mutiny_level: int)
signal mutiny_triggered
signal supplies_depleted(supply_type: String)

# ============================================================================
# CREW ROSTER
# ============================================================================

@export var members: Array[CrewMember] = []

## Get living crew count
func get_crew_count() -> int:
	var count: int = 0
	for member in members:
		if member.is_alive:
			count += 1
	return count

## Get average crew level (for scaling encounters)
func get_average_level() -> int:
	if members.is_empty():
		return 1
	var total: int = 0
	var count: int = 0
	for member in members:
		if member.is_alive:
			total += member.get_level()
			count += 1
	return ceili(float(total) / maxf(1, count))

# ============================================================================
# SHIP SUPPLIES (Shared resources)
# ============================================================================

## Food supplies (rations per day per crew)
@export var food_stores: int = 100 # Units of food
@export var water_stores: int = 100 # Units of water
@export var rum_stores: int = 20 # Units of rum/grog
@export var citrus_stores: int = 10 # Precious! Prevents scurvy

# Consumption rates per crew member per day
const FOOD_PER_CREW_PER_DAY: int = 2
const WATER_PER_CREW_PER_DAY: int = 3
const RUM_OPTIONAL_PER_DAY: float = 0.5 # Optional but boosts morale

# ============================================================================
# MUTINY TRACKING
# ============================================================================

## Mutiny meter (0-100, at 100 triggers mutiny)
var mutiny_meter: int = 0
const MUTINY_THRESHOLD: int = 100

# ============================================================================
# COLLECTIVE METABOLIC PROCESSING
# ============================================================================

## Process one day of crew metabolics (call from GameTime on day_passed)
func process_day() -> void:
	var crew_count: int = get_crew_count()
	if crew_count == 0:
		return

	# Calculate daily supply consumption
	var food_needed: int = crew_count * FOOD_PER_CREW_PER_DAY
	var water_needed: int = crew_count * WATER_PER_CREW_PER_DAY

	# Consume from stores
	var food_available: float = minf(1.0, float(food_stores) / food_needed)
	var water_available: float = minf(1.0, float(water_stores) / water_needed)

	food_stores = maxi(0, food_stores - food_needed)
	water_stores = maxi(0, water_stores - water_needed)

	if food_stores == 0:
		supplies_depleted.emit("food")
	if water_stores == 0:
		supplies_depleted.emit("water")

	# Process each crew member
	for member in members:
		if not member.is_alive:
			continue

		# Feed based on available rations
		if food_available >= 1.0:
			member.eat({"nutrition": 40, "thirst_cost": 10}) # Salt beef increases thirst
		elif food_available >= 0.5:
			member.eat({"nutrition": 20, "thirst_cost": 5}) # Half rations
		# else: starvation - member.hunger will decay via process_hour

		# Hydrate based on available water
		if water_available >= 1.0:
			member.drink({"hydration": 50})
		elif water_available >= 0.5:
			member.drink({"hydration": 25}) # Half rations

		# Connect death signal if not already
		if not member.death.is_connected(_on_member_death):
			member.death.connect(_on_member_death)

	# Optional: Issue rum ration for morale (costs rum but boosts morale)
	_process_rum_ration()

	# Process citrus (if available, prevents scurvy)
	_process_citrus_ration()

	# Update mutiny meter
	_update_mutiny()

## Process hourly metabolic decay for all crew
func process_hour() -> void:
	for member in members:
		if member.is_alive:
			member.process_hour()

func _process_rum_ration() -> void:
	# If we have rum, issue it to boost morale
	var crew_count: int = get_crew_count()
	if rum_stores > 0 and crew_count > 0:
		var rum_per_member: float = RUM_OPTIONAL_PER_DAY
		var rum_needed: int = ceili(crew_count * rum_per_member)

		if rum_stores >= rum_needed:
			rum_stores -= rum_needed
			for member in members:
				if member.is_alive:
					member.drink({"hydration": 5, "alcohol": 15, "morale_boost": 10})
		elif rum_stores > 0:
			# Partial ration - some get rum, some don't (breeds resentment)
			rum_stores = 0
			# Only half get morale boost
			var lucky_ones: int = 0
			for member in members:
				if member.is_alive and lucky_ones < crew_count / 2:
					member.drink({"hydration": 5, "alcohol": 15, "morale_boost": 5})
					lucky_ones += 1

func _process_citrus_ration() -> void:
	# Weekly citrus ration prevents scurvy
	if citrus_stores > 0:
		var crew_count: int = get_crew_count()
		# Use 1 citrus per 5 crew per day
		var citrus_needed: int = maxi(1, ceili(float(crew_count) / 5.0))

		if citrus_stores >= citrus_needed:
			citrus_stores -= citrus_needed
			for member in members:
				if member.is_alive:
					member.vitamin_c = mini(100, member.vitamin_c + 10)

func _update_mutiny() -> void:
	var total_morale: int = 0
	var total_hunger: int = 0
	var count: int = 0

	for member in members:
		if member.is_alive:
			total_morale += member.morale
			total_hunger += member.hunger
			count += 1

	if count == 0:
		return

	var avg_morale: int = total_morale / count
	var avg_hunger: int = total_hunger / count

	# Mutiny rises when morale/hunger are low
	if avg_morale < 30 or avg_hunger < 30:
		mutiny_meter += 5
	elif avg_morale < 50 or avg_hunger < 50:
		mutiny_meter += 2
	elif avg_morale > 70 and avg_hunger > 70:
		mutiny_meter = maxi(0, mutiny_meter - 3) # Good conditions reduce mutiny

	mutiny_meter = clampi(mutiny_meter, 0, MUTINY_THRESHOLD)

	if mutiny_meter >= 75:
		mutiny_warning.emit(mutiny_meter)

	if mutiny_meter >= MUTINY_THRESHOLD:
		mutiny_triggered.emit()

func _on_member_death(member: CrewMember, cause: String) -> void:
	crew_member_died.emit(member, cause)
	# Death affects morale of remaining crew
	for m in members:
		if m.is_alive:
			m.morale = maxi(0, m.morale - 10)

# ============================================================================
# CREW MANAGEMENT
# ============================================================================

## Add a new crew member
func add_member(member: CrewMember) -> void:
	members.append(member)

## Remove a crew member (deserted, sold, etc.)
func remove_member(member: CrewMember) -> void:
	members.erase(member)

## Get crew member by role
func get_member_by_role(role: CrewMember.ShipRole) -> CrewMember:
	for member in members:
		if member.is_alive and member.role == role:
			return member
	return null

## Get all living crew
func get_living_crew() -> Array[CrewMember]:
	var living: Array[CrewMember] = []
	for member in members:
		if member.is_alive:
			living.append(member)
	return living

# ============================================================================
# SUPPLY MANAGEMENT
# ============================================================================

## Add supplies (from purchase, loot, fishing, etc.)
func add_supplies(food: int = 0, water: int = 0, rum: int = 0, citrus: int = 0) -> void:
	food_stores += food
	water_stores += water
	rum_stores += rum
	citrus_stores += citrus

## Get days of supplies remaining
func get_days_of_supplies() -> Dictionary:
	var crew_count: int = get_crew_count()
	if crew_count == 0:
		return {"food": 999, "water": 999}

	return {
		"food": food_stores / (crew_count * FOOD_PER_CREW_PER_DAY),
		"water": water_stores / (crew_count * WATER_PER_CREW_PER_DAY),
		"rum": rum_stores,
		"citrus": citrus_stores,
	}

# ============================================================================
# SCALING GENERATION
# ============================================================================

## Generate a crew scaled to player level
static func generate_scaled_crew(player_level: int, crew_size: int, difficulty_mod: int = 0) -> ShipCrew:
	var crew := ShipCrew.new()

	for i in range(crew_size):
		var member := CrewMember.generate_enemy(player_level, difficulty_mod)
		crew.members.append(member)

	# Supplies scaled to crew size
	crew.food_stores = crew_size * 10
	crew.water_stores = crew_size * 10
	crew.rum_stores = crew_size * 2
	crew.citrus_stores = crew_size / 2

	return crew

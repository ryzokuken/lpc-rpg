class_name SurvivalStats extends Resource
## Survival needs for any character (Player, NPC, Crew)
## 5 stats: Belly, Hydration, Vigor, Nerve, Sobriety
## All stats: 100 = healthy/good, 0 = critical/bad

# ============================================================================
# SIGNALS
# ============================================================================

signal stat_changed(stat_name: String, old_value: int, new_value: int)
signal stat_critical(stat_name: String) # Emitted when stat drops below 25
signal stat_depleted(stat_name: String) # Emitted when stat hits 0

# ============================================================================
# SURVIVAL STATS (0-100 scale)
# ============================================================================

## Nourishment level (100 = full, 0 = starving)
@export_range(0, 100) var belly: int = 100

## Hydration (100 = hydrated, 0 = dehydrated)
@export_range(0, 100) var hydration: int = 100

## Energy/stamina (100 = rested, 0 = exhausted)
@export_range(0, 100) var vigor: int = 100

## Mental stability (100 = calm, 0 = breaking)
@export_range(0, 100) var nerve: int = 100

## Sobriety (100 = sober, 0 = blackout)
@export_range(0, 100) var sobriety: int = 100

# ============================================================================
# ACTIVE EFFECTS (simple list of effect IDs)
# ============================================================================

var active_effects: Array[String] = []

# ============================================================================
# DECAY RATES (per in-game hour)
# ============================================================================

const BELLY_DECAY_PER_HOUR: float = 2.0
const HYDRATION_DECAY_PER_HOUR: float = 3.0
const VIGOR_DECAY_PER_HOUR: float = 1.5
const NERVE_DECAY_PER_HOUR: float = 0.3
const SOBRIETY_RESTORE_PER_HOUR: float = 5.0 # Sobering up

# ============================================================================
# THRESHOLD CONSTANTS
# ============================================================================

const THRESHOLD_GOOD: int = 75
const THRESHOLD_MODERATE: int = 50
const THRESHOLD_LOW: int = 25

# ============================================================================
# STAT MODIFICATION
# ============================================================================

func modify_belly(amount: int) -> void:
	var old_value: int = belly
	belly = clampi(belly + amount, 0, 100)
	_check_thresholds("belly", old_value, belly)

func modify_hydration(amount: int) -> void:
	var old_value: int = hydration
	hydration = clampi(hydration + amount, 0, 100)
	_check_thresholds("hydration", old_value, hydration)

func modify_vigor(amount: int) -> void:
	var old_value: int = vigor
	vigor = clampi(vigor + amount, 0, 100)
	_check_thresholds("vigor", old_value, vigor)

func modify_nerve(amount: int) -> void:
	var old_value: int = nerve
	nerve = clampi(nerve + amount, 0, 100)
	_check_thresholds("nerve", old_value, nerve)

func modify_sobriety(amount: int) -> void:
	var old_value: int = sobriety
	sobriety = clampi(sobriety + amount, 0, 100)
	_check_thresholds("sobriety", old_value, sobriety)

func _check_thresholds(stat_name: String, old_val: int, new_val: int) -> void:
	stat_changed.emit(stat_name, old_val, new_val)
	if old_val > THRESHOLD_LOW and new_val <= THRESHOLD_LOW:
		stat_critical.emit(stat_name)
	if old_val > 0 and new_val == 0:
		stat_depleted.emit(stat_name)

# ============================================================================
# TIME-BASED PROCESSING
# ============================================================================

enum ActivityLevel {RESTING, IDLE, WORKING, LABORING, COMBAT}

func process_hour(activity: ActivityLevel = ActivityLevel.IDLE) -> void:
	# Belly drain
	var belly_drain: float = BELLY_DECAY_PER_HOUR
	if activity == ActivityLevel.RESTING:
		belly_drain *= 0.5
	elif activity >= ActivityLevel.LABORING:
		belly_drain *= 1.5
	modify_belly(-int(belly_drain))

	# Hydration drain (faster than hunger)
	var hydration_drain: float = HYDRATION_DECAY_PER_HOUR
	if activity >= ActivityLevel.LABORING:
		hydration_drain *= 1.5
	modify_hydration(-int(hydration_drain))

	# Vigor (activity-dependent)
	var vigor_change: float = 0.0
	match activity:
		ActivityLevel.RESTING:
			vigor_change = 8.0
		ActivityLevel.IDLE:
			vigor_change = - VIGOR_DECAY_PER_HOUR * 0.5
		ActivityLevel.WORKING:
			vigor_change = - VIGOR_DECAY_PER_HOUR
		ActivityLevel.LABORING:
			vigor_change = - VIGOR_DECAY_PER_HOUR * 2.0
		ActivityLevel.COMBAT:
			vigor_change = - VIGOR_DECAY_PER_HOUR * 3.0
	modify_vigor(int(vigor_change))

	# Nerve (slow passive drain)
	modify_nerve(-int(NERVE_DECAY_PER_HOUR))

	# Sobriety restores over time
	if sobriety < 100:
		modify_sobriety(int(SOBRIETY_RESTORE_PER_HOUR))

	# Cascade effects
	if belly < THRESHOLD_MODERATE:
		modify_vigor(-1)
	if vigor < THRESHOLD_MODERATE:
		modify_nerve(-1)

# ============================================================================
# PENALTIES & EFFECTS
# ============================================================================

## Get total skill check penalty from survival stats
func get_skill_penalty() -> int:
	var penalty: int = 0

	# Belly penalties
	if belly < THRESHOLD_GOOD:
		penalty += 5
	if belly < THRESHOLD_MODERATE:
		penalty += 10
	if belly < THRESHOLD_LOW:
		penalty += 15

	# Vigor penalties
	if vigor < THRESHOLD_GOOD:
		penalty += 5
	if vigor < THRESHOLD_MODERATE:
		penalty += 10
	if vigor < THRESHOLD_LOW:
		penalty += 15

	# Nerve penalties (mainly affects social)
	if nerve < THRESHOLD_MODERATE:
		penalty += 5
	if nerve < THRESHOLD_LOW:
		penalty += 10

	return penalty

## Get movement speed multiplier (1.0 = normal)
func get_speed_multiplier() -> float:
	if vigor < THRESHOLD_LOW:
		return 0.5 # Can barely move
	elif vigor < THRESHOLD_MODERATE:
		return 0.75
	elif vigor < THRESHOLD_GOOD:
		return 0.9
	return 1.0

## Check if character can run
func can_run() -> bool:
	return vigor >= THRESHOLD_LOW

## Check if character can perform strenuous actions
func can_do_heavy_labor() -> bool:
	return vigor >= THRESHOLD_MODERATE and belly >= THRESHOLD_LOW

## Get a status description for UI
func get_status_description() -> String:
	var issues: Array[String] = []

	if belly < THRESHOLD_LOW:
		issues.append("Starving")
	elif belly < THRESHOLD_MODERATE:
		issues.append("Hungry")

	if vigor < THRESHOLD_LOW:
		issues.append("Exhausted")
	elif vigor < THRESHOLD_MODERATE:
		issues.append("Tired")

	if nerve < THRESHOLD_LOW:
		issues.append("Breaking")
	elif nerve < THRESHOLD_MODERATE:
		issues.append("Anxious")

	if issues.is_empty():
		return "Healthy"
	return ", ".join(issues)

# ============================================================================
# SPECIAL EVENTS
# ============================================================================

## Called when eating food
func eat(nutrition_value: int) -> void:
	modify_belly(nutrition_value)
	# Good food also slightly restores nerve
	if nutrition_value >= 20:
		modify_nerve(2)

## Called when drinking alcohol
func drink_alcohol(strength: int = 10) -> void:
	# Alcohol restores nerve but slightly drains vigor next day
	modify_nerve(strength)
	# Could track "drunk" status separately

## Called when sleeping (hours of sleep)
func sleep(hours: int) -> void:
	for i in range(hours):
		process_hour(ActivityLevel.RESTING)

## Called when witnessing death/trauma
func witness_trauma(severity: int = 10) -> void:
	modify_nerve(-severity)

## Called during shore leave/safe rest
func shore_leave() -> void:
	modify_nerve(25)
	modify_vigor(20)

# ============================================================================
# UTILITY
# ============================================================================

## Create fully healthy survival stats
static func create_healthy() -> SurvivalStats:
	var stats := SurvivalStats.new()
	stats.belly = 100
	stats.vigor = 100
	stats.nerve = 100
	return stats

## Create somewhat depleted stats (mid-voyage)
static func create_mid_voyage() -> SurvivalStats:
	var stats := SurvivalStats.new()
	stats.belly = 70
	stats.vigor = 60
	stats.nerve = 80
	return stats

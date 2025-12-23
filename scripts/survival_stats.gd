class_name SurvivalStats extends Resource
## Survival needs for characters (primarily Player)
## 3 stats: Belly (nourishment), Vigor (energy), Nerve (mental stability)
## All scale from 100 (full/healthy) to 0 (critical/depleted)

# ============================================================================
# SIGNALS
# ============================================================================

signal stat_changed(stat_name: String, old_value: int, new_value: int)
signal stat_critical(stat_name: String) # Emitted when stat drops below 25
signal stat_depleted(stat_name: String) # Emitted when stat hits 0

# ============================================================================
# SURVIVAL STATS (0-100 scale, 100 = healthy)
# ============================================================================

## Nourishment level - how well-fed the character is
## Historical note: Pirates typically ate 2 meals per day when supplies allowed
@export_range(0, 100) var belly: int = 100

## Energy/stamina level - how rested the character is
## Drains from activity, restores from sleep
@export_range(0, 100) var vigor: int = 100

## Mental stability - psychological wellness
## Drains from trauma, restores from positive experiences
@export_range(0, 100) var nerve: int = 100

# ============================================================================
# DRAIN RATES (per in-game hour)
# Calibrated so: Belly needs ~2 meals/day, Vigor needs ~8hrs sleep
# Assuming 24 in-game hours per day
# ============================================================================

## Base belly drain per hour (50/24 ≈ 2 per hour means ~2 meals needed)
const BELLY_DRAIN_PER_HOUR: float = 2.0

## Base vigor drain per hour (resting = 0 drain, working = faster drain)
const VIGOR_DRAIN_PER_HOUR: float = 1.5

## Base nerve drain per hour (very slow passive drain)
const NERVE_DRAIN_PER_HOUR: float = 0.3

# ============================================================================
# THRESHOLD CONSTANTS
# ============================================================================

const THRESHOLD_GOOD: int = 75 # Above this = no penalties
const THRESHOLD_MODERATE: int = 50 # Below this = noticeable penalties
const THRESHOLD_LOW: int = 25 # Below this = severe penalties
const THRESHOLD_CRITICAL: int = 10 # Below this = critical state

# ============================================================================
# STAT MODIFICATION
# ============================================================================

## Modify belly (positive = eating, negative = drain)
func modify_belly(amount: int) -> void:
	var old_value: int = belly
	belly = clampi(belly + amount, 0, 100)
	_check_thresholds("belly", old_value, belly)

## Modify vigor (positive = resting, negative = activity)
func modify_vigor(amount: int) -> void:
	var old_value: int = vigor
	vigor = clampi(vigor + amount, 0, 100)
	_check_thresholds("vigor", old_value, vigor)

## Modify nerve (positive = good experience, negative = trauma)
func modify_nerve(amount: int) -> void:
	var old_value: int = nerve
	nerve = clampi(nerve + amount, 0, 100)
	_check_thresholds("nerve", old_value, nerve)

func _check_thresholds(stat_name: String, old_val: int, new_val: int) -> void:
	stat_changed.emit(stat_name, old_val, new_val)

	# Check for crossing into critical
	if old_val > THRESHOLD_LOW and new_val <= THRESHOLD_LOW:
		stat_critical.emit(stat_name)

	# Check for depletion
	if old_val > 0 and new_val == 0:
		stat_depleted.emit(stat_name)

# ============================================================================
# TIME-BASED DRAIN (call once per in-game hour)
# ============================================================================

enum ActivityLevel {
	RESTING, # Sleeping or sitting idle
	IDLE, # Standing around, light activity
	WORKING, # Normal ship duties
	LABORING, # Heavy physical work
	COMBAT # Fighting
}

## Process one hour of time passing
func process_hour(activity: ActivityLevel = ActivityLevel.IDLE) -> void:
	# Belly always drains (slightly less when resting)
	var belly_drain: float = BELLY_DRAIN_PER_HOUR
	if activity == ActivityLevel.RESTING:
		belly_drain *= 0.5
	elif activity == ActivityLevel.LABORING or activity == ActivityLevel.COMBAT:
		belly_drain *= 1.5
	modify_belly(-int(belly_drain))

	# Vigor depends heavily on activity
	var vigor_change: float
	match activity:
		ActivityLevel.RESTING:
			vigor_change = 8.0 # Restore ~64 vigor in 8 hours sleep
		ActivityLevel.IDLE:
			vigor_change = - VIGOR_DRAIN_PER_HOUR * 0.5
		ActivityLevel.WORKING:
			vigor_change = - VIGOR_DRAIN_PER_HOUR
		ActivityLevel.LABORING:
			vigor_change = - VIGOR_DRAIN_PER_HOUR * 2.0
		ActivityLevel.COMBAT:
			vigor_change = - VIGOR_DRAIN_PER_HOUR * 3.0
	modify_vigor(int(vigor_change))

	# Nerve drains very slowly over time (boredom, isolation)
	modify_nerve(-int(NERVE_DRAIN_PER_HOUR))

	# Low belly accelerates vigor drain
	if belly < THRESHOLD_MODERATE:
		modify_vigor(-1)

	# Low vigor accelerates nerve drain
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

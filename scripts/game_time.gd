extends Node
## Manages in-game time, drives survival stats, and provides time scale control
## Add as autoload singleton named "GameTime"

signal hour_passed(hour: int, day: int)
signal day_passed(day: int)
signal time_updated(hour: int, minute: int, day: int)

# ============================================================================
# TIME CONFIGURATION
# ============================================================================

## How many real seconds = 1 in-game minute
## Default: 1 real second = 1 game minute (1 hour = 60 seconds, 1 day = 24 minutes)
@export var seconds_per_game_minute: float = 1.0

## Time scale multiplier (1.0 = normal, 10.0 = 10x faster for testing)
@export var time_scale: float = 1.0

## Whether time is currently passing
@export var time_flowing: bool = true

# ============================================================================
# CURRENT TIME STATE
# ============================================================================

var current_minute: int = 0 # 0-59
var current_hour: int = 8 # 0-23 (start at 8 AM)
var current_day: int = 1 # Day count

# Accumulated time for minute tracking
var _accumulated_seconds: float = 0.0

# Reference to player for survival processing
var _player: Player = null

# ============================================================================
# TIME CONSTANTS
# ============================================================================

const MINUTES_PER_HOUR := 60
const HOURS_PER_DAY := 24

# Time of day periods
enum TimePeriod {DAWN, MORNING, AFTERNOON, EVENING, NIGHT}

const TIME_PERIODS := {
	TimePeriod.DAWN: {"start": 5, "end": 7, "name": "Dawn"},
	TimePeriod.MORNING: {"start": 7, "end": 12, "name": "Morning"},
	TimePeriod.AFTERNOON: {"start": 12, "end": 17, "name": "Afternoon"},
	TimePeriod.EVENING: {"start": 17, "end": 21, "name": "Evening"},
	TimePeriod.NIGHT: {"start": 21, "end": 5, "name": "Night"},
}

# ============================================================================
# LIFECYCLE
# ============================================================================

func _ready() -> void:
	# Find player in scene tree (will be set properly when player spawns)
	_find_player()

func _process(delta: float) -> void:
	if not time_flowing:
		return

	_accumulated_seconds += delta * time_scale

	# Check if a minute has passed
	while _accumulated_seconds >= seconds_per_game_minute:
		_accumulated_seconds -= seconds_per_game_minute
		_advance_minute()

func _find_player() -> void:
	# Try to find player in current scene
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0] as Player

## Register the player (call this when player spawns)
func register_player(player: Player) -> void:
	_player = player

# ============================================================================
# TIME ADVANCEMENT
# ============================================================================

func _advance_minute() -> void:
	current_minute += 1

	if current_minute >= MINUTES_PER_HOUR:
		current_minute = 0
		_advance_hour()

	time_updated.emit(current_hour, current_minute, current_day)

func _advance_hour() -> void:
	var old_hour := current_hour
	current_hour += 1

	if current_hour >= HOURS_PER_DAY:
		current_hour = 0
		_advance_day()

	hour_passed.emit(current_hour, current_day)

	# Process survival stats each hour
	_process_survival_hour()

func _advance_day() -> void:
	current_day += 1
	day_passed.emit(current_day)

func _process_survival_hour() -> void:
	if _player == null:
		_find_player()

	if _player and _player.survival:
		# Determine activity level based on player state
		var activity: SurvivalStats.ActivityLevel = SurvivalStats.ActivityLevel.IDLE
		if _player.character_state == Character.CharacterState.WALKING:
			activity = SurvivalStats.ActivityLevel.WORKING

		_player.survival.process_hour(activity)

# ============================================================================
# TIME QUERIES
# ============================================================================

## Get current time as formatted string (HH:MM)
func get_time_string() -> String:
	return "%02d:%02d" % [current_hour, current_minute]

## Get current time period
func get_time_period() -> TimePeriod:
	for period in TIME_PERIODS:
		var data: Dictionary = TIME_PERIODS[period]
		if data.start <= data.end:
			# Normal range (e.g., 7-12)
			if current_hour >= data.start and current_hour < data.end:
				return period
		else:
			# Wrapping range (e.g., 21-5 for night)
			if current_hour >= data.start or current_hour < data.end:
				return period
	return TimePeriod.NIGHT

## Get time period name
func get_time_period_name() -> String:
	var period := get_time_period()
	return TIME_PERIODS[period].name

## Check if it's daytime (for lighting, NPC schedules, etc.)
func is_daytime() -> bool:
	return current_hour >= 6 and current_hour < 20

## Get total hours elapsed
func get_total_hours() -> int:
	return (current_day - 1) * HOURS_PER_DAY + current_hour

# ============================================================================
# TIME CONTROL
# ============================================================================

## Pause time
func pause_time() -> void:
	time_flowing = false

## Resume time
func resume_time() -> void:
	time_flowing = true

## Set time scale (for testing or special events)
func set_time_scale(scale: float) -> void:
	time_scale = maxf(0.1, scale)

## Skip forward by hours
func skip_hours(hours: int) -> void:
	for i in range(hours):
		_advance_hour()
		if current_minute > 0:
			current_minute = 0

## Set specific time (useful for testing or story events)
func set_time(hour: int, minute: int = 0, day: int = -1) -> void:
	current_hour = clampi(hour, 0, 23)
	current_minute = clampi(minute, 0, 59)
	if day > 0:
		current_day = day
	time_updated.emit(current_hour, current_minute, current_day)

## Rest until a specific hour (for sleeping mechanics)
func rest_until(target_hour: int) -> int:
	var hours_rested := 0
	while current_hour != target_hour:
		# Override to resting activity
		if _player and _player.survival:
			_player.survival.process_hour(SurvivalStats.ActivityLevel.RESTING)
		current_hour += 1
		hours_rested += 1
		if current_hour >= HOURS_PER_DAY:
			current_hour = 0
			_advance_day()
		hour_passed.emit(current_hour, current_day)
	time_updated.emit(current_hour, current_minute, current_day)
	return hours_rested

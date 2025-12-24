class_name FishingGame extends Node
## Fishing mini-game logic
## Phases: Cast → Wait → Hook → Reel → Catch

signal game_started
signal fish_hooked(fish_type: String, difficulty: int)
signal tension_changed(tension: float)
signal fish_caught(fish_type: String, value: int)
signal fish_escaped(reason: String)
signal game_ended(success: bool, fish_type: String)

# ============================================================================
# FISH DATA
# ============================================================================

enum FishRarity {COMMON, UNCOMMON, RARE, LEGENDARY}

const FISH_TYPES := {
	"small_fish": {
		"name": "Small Fish",
		"rarity": FishRarity.COMMON,
		"nutrition": 15,
		"value": 2,
		"difficulty": 20,
		"fight_strength": 0.3,
		"weight": 0.5,
	},
	"mackerel": {
		"name": "Mackerel",
		"rarity": FishRarity.COMMON,
		"nutrition": 20,
		"value": 5,
		"difficulty": 30,
		"fight_strength": 0.4,
		"weight": 1.0,
	},
	"cod": {
		"name": "Cod",
		"rarity": FishRarity.UNCOMMON,
		"nutrition": 35,
		"value": 10,
		"difficulty": 45,
		"fight_strength": 0.5,
		"weight": 3.0,
	},
	"tuna": {
		"name": "Tuna",
		"rarity": FishRarity.RARE,
		"nutrition": 50,
		"value": 25,
		"difficulty": 60,
		"fight_strength": 0.7,
		"weight": 8.0,
	},
	"shark": {
		"name": "Shark",
		"rarity": FishRarity.LEGENDARY,
		"nutrition": 80,
		"value": 50,
		"difficulty": 80,
		"fight_strength": 0.9,
		"weight": 20.0,
	},
	"sea_turtle": {
		"name": "Sea Turtle",
		"rarity": FishRarity.RARE,
		"nutrition": 60,
		"value": 30,
		"difficulty": 50,
		"fight_strength": 0.4,
		"weight": 15.0,
	},
	"treasure": {
		"name": "Sunken Treasure",
		"rarity": FishRarity.LEGENDARY,
		"nutrition": 0,
		"value": 100,
		"difficulty": 30,
		"fight_strength": 0.2,
		"weight": 5.0,
	},
}

# Spawn weights by rarity (affects what fish appear)
const RARITY_WEIGHTS := {
	FishRarity.COMMON: 60,
	FishRarity.UNCOMMON: 25,
	FishRarity.RARE: 12,
	FishRarity.LEGENDARY: 3,
}

# ============================================================================
# GAME STATE
# ============================================================================

enum Phase {IDLE, CASTING, WAITING, HOOKED, REELING, COMPLETE}

var current_phase: Phase = Phase.IDLE
var current_fish: String = ""
var current_fish_data: Dictionary = {}

# Reeling mini-game state
var tension: float = 0.5 # 0.0 to 1.0 (too low = escapes, too high = line breaks)
var fish_stamina: float = 1.0 # 0.0 to 1.0 (depletes as you reel)
var is_reeling: bool = false

# Player stats (injected)
var player_finesse: int = 5
var player_wits: int = 5

# Timing
var wait_timer: float = 0.0
var hook_window_timer: float = 0.0
const HOOK_WINDOW_DURATION := 1.5 # Seconds to react when fish bites

# ============================================================================
# GAME FLOW
# ============================================================================

func start_game(p_finesse: int = 5, p_wits: int = 5) -> void:
	player_finesse = p_finesse
	player_wits = p_wits
	current_phase = Phase.IDLE
	game_started.emit()

## Player casts the line
func cast_line() -> void:
	if current_phase != Phase.IDLE:
		return
	current_phase = Phase.CASTING
	# Short delay for casting animation
	await get_tree().create_timer(0.5).timeout
	_start_waiting()

func _start_waiting() -> void:
	current_phase = Phase.WAITING
	# Random wait time, reduced by player's Wits (better spots)
	var base_wait := randf_range(3.0, 8.0)
	var wits_bonus := (player_wits - 5) * 0.3 # -1.5 to +1.5 seconds
	wait_timer = maxf(1.0, base_wait - wits_bonus)

## Called each frame during waiting phase
func process_waiting(delta: float) -> bool:
	if current_phase != Phase.WAITING:
		return false

	wait_timer -= delta
	if wait_timer <= 0:
		_fish_bites()
		return true
	return false

func _fish_bites() -> void:
	current_phase = Phase.HOOKED
	current_fish = _select_random_fish()
	current_fish_data = FISH_TYPES[current_fish]
	hook_window_timer = HOOK_WINDOW_DURATION
	fish_hooked.emit(current_fish_data.name, current_fish_data.difficulty)

## Player must call this during hook window
func hook_fish() -> bool:
	if current_phase != Phase.HOOKED:
		return false
	_start_reeling()
	return true

## Called each frame during hook window
func process_hook_window(delta: float) -> bool:
	if current_phase != Phase.HOOKED:
		return false

	hook_window_timer -= delta
	if hook_window_timer <= 0:
		# Missed the hook!
		fish_escaped.emit("Too slow - the fish got away!")
		_end_game(false)
		return true
	return false

func _start_reeling() -> void:
	current_phase = Phase.REELING
	tension = 0.5
	fish_stamina = 1.0
	is_reeling = false

## Player holds reel button
func set_reeling(reeling: bool) -> void:
	is_reeling = reeling

## Called each frame during reeling phase
func process_reeling(delta: float) -> bool:
	if current_phase != Phase.REELING:
		return false

	var fight_strength: float = current_fish_data.fight_strength
	var finesse_mod: float = (player_finesse - 5) * 0.02 # -0.08 to +0.1

	if is_reeling:
		# Reeling increases tension and depletes fish stamina
		tension += delta * (0.8 + fight_strength - finesse_mod)
		fish_stamina -= delta * (0.15 + finesse_mod)
	else:
		# Not reeling decreases tension but fish recovers slightly
		tension -= delta * 0.5
		fish_stamina += delta * 0.03 * fight_strength

	# Fish fights back randomly
	if randf() < fight_strength * delta:
		tension += randf_range(0.05, 0.15)

	# Clamp values
	tension = clampf(tension, 0.0, 1.0)
	fish_stamina = clampf(fish_stamina, 0.0, 1.0)

	tension_changed.emit(tension)

	# Check win/lose conditions
	if tension >= 1.0:
		fish_escaped.emit("Line snapped!")
		_end_game(false)
		return true
	elif tension <= 0.0:
		fish_escaped.emit("Fish escaped - too much slack!")
		_end_game(false)
		return true
	elif fish_stamina <= 0.0:
		# Caught!
		fish_caught.emit(current_fish_data.name, current_fish_data.value)
		_end_game(true)
		return true

	return false

func _select_random_fish() -> String:
	# Build weighted list based on rarity
	var weighted_fish: Array[Dictionary] = []
	for fish_id in FISH_TYPES:
		var fish: Dictionary = FISH_TYPES[fish_id]
		var rarity_weight: int = RARITY_WEIGHTS[fish.rarity]
		# Higher Wits slightly increases rare fish chance
		if fish.rarity == FishRarity.RARE or fish.rarity == FishRarity.LEGENDARY:
			rarity_weight += player_wits - 5
		weighted_fish.append({"id": fish_id, "weight": rarity_weight})

	# Calculate total weight
	var total_weight: int = 0
	for entry in weighted_fish:
		total_weight += entry.weight

	# Random selection
	var roll: int = randi_range(1, total_weight)
	var cumulative: int = 0
	for entry in weighted_fish:
		cumulative += entry.weight
		if roll <= cumulative:
			return entry.id

	return "small_fish" # Fallback

func _end_game(success: bool) -> void:
	current_phase = Phase.COMPLETE
	game_ended.emit(success, current_fish)

## Get current fish nutrition value (for eating)
func get_fish_nutrition() -> int:
	if current_fish_data.is_empty():
		return 0
	return current_fish_data.nutrition

## Get current fish sell value
func get_fish_value() -> int:
	if current_fish_data.is_empty():
		return 0
	return current_fish_data.value

## Check if game is in progress
func is_active() -> bool:
	return current_phase != Phase.IDLE and current_phase != Phase.COMPLETE

## Reset for another round
func reset() -> void:
	current_phase = Phase.IDLE
	current_fish = ""
	current_fish_data = {}
	tension = 0.5
	fish_stamina = 1.0
	is_reeling = false

class_name FishingUI extends CanvasLayer
## UI controller for the fishing mini-game

signal fishing_completed(caught: bool, fish_data: Dictionary)

@export var mini_game_duration: float = 30.0 # Max time for reeling

# Node references
@onready var panel: PanelContainer = $Panel
@onready var phase_label: Label = $Panel/VBox/PhaseLabel
@onready var fish_label: Label = $Panel/VBox/FishLabel
@onready var tension_bar: ProgressBar = $Panel/VBox/TensionBar
@onready var stamina_bar: ProgressBar = $Panel/VBox/StaminaBar
@onready var hint_label: Label = $Panel/VBox/HintLabel
@onready var cast_button: Button = $Panel/VBox/Buttons/CastButton
@onready var reel_button: Button = $Panel/VBox/Buttons/ReelButton
@onready var close_button: TextureButton = $Panel/CloseButton

# Game instance
var game: FishingGame
var player_finesse: int = 5
var player_wits: int = 5

func _ready() -> void:
	visible = false
	_connect_buttons()

func _connect_buttons() -> void:
	cast_button.pressed.connect(_on_cast_pressed)
	reel_button.button_down.connect(_on_reel_down)
	reel_button.button_up.connect(_on_reel_up)
	close_button.pressed.connect(_on_close_pressed)

## Start fishing session with player stats
func start_fishing(p_finesse: int = 5, p_wits: int = 5) -> void:
	player_finesse = p_finesse
	player_wits = p_wits

	# Create game instance
	game = FishingGame.new()
	add_child(game)

	# Connect signals
	game.game_started.connect(_on_game_started)
	game.fish_hooked.connect(_on_fish_hooked)
	game.tension_changed.connect(_on_tension_changed)
	game.fish_caught.connect(_on_fish_caught)
	game.fish_escaped.connect(_on_fish_escaped)
	game.game_ended.connect(_on_game_ended)

	# Reset UI
	_update_phase_ui(FishingGame.Phase.IDLE)
	tension_bar.value = 50
	stamina_bar.value = 100
	fish_label.text = ""
	hint_label.text = "Press Cast to throw your line"

	visible = true
	game.start_game(player_finesse, player_wits)

func _process(delta: float) -> void:
	if not game or not game.is_active():
		return

	match game.current_phase:
		FishingGame.Phase.WAITING:
			game.process_waiting(delta)
			# Show waiting animation hint
			var dots: int = int(Time.get_ticks_msec() / 500) % 4
			hint_label.text = "Waiting for a bite" + ".".repeat(dots)
		FishingGame.Phase.HOOKED:
			game.process_hook_window(delta)
			hint_label.text = "FISH ON! Press HOOK! (%.1fs)" % game.hook_window_timer
		FishingGame.Phase.REELING:
			game.process_reeling(delta)
			stamina_bar.value = game.fish_stamina * 100
			_update_tension_color()

func _update_phase_ui(phase: FishingGame.Phase) -> void:
	match phase:
		FishingGame.Phase.IDLE:
			phase_label.text = "Ready to Fish"
			cast_button.visible = true
			cast_button.disabled = false
			reel_button.visible = false
		FishingGame.Phase.CASTING:
			phase_label.text = "Casting..."
			cast_button.disabled = true
		FishingGame.Phase.WAITING:
			phase_label.text = "Waiting..."
			cast_button.visible = false
		FishingGame.Phase.HOOKED:
			phase_label.text = "FISH ON!"
			cast_button.text = "HOOK!"
			cast_button.visible = true
			cast_button.disabled = false
		FishingGame.Phase.REELING:
			phase_label.text = "Reeling In..."
			cast_button.visible = false
			reel_button.visible = true
			reel_button.disabled = false
		FishingGame.Phase.COMPLETE:
			cast_button.visible = false
			reel_button.visible = false

func _update_tension_color() -> void:
	# Green in middle, red at extremes
	var t: float = game.tension
	if t < 0.3 or t > 0.7:
		tension_bar.modulate = Color.RED
	elif t < 0.4 or t > 0.6:
		tension_bar.modulate = Color.YELLOW
	else:
		tension_bar.modulate = Color.GREEN

# Signal handlers
func _on_game_started() -> void:
	_update_phase_ui(FishingGame.Phase.IDLE)

func _on_fish_hooked(fish_type: String, difficulty: int) -> void:
	fish_label.text = "Something's biting!"
	_update_phase_ui(FishingGame.Phase.HOOKED)

func _on_tension_changed(tension: float) -> void:
	tension_bar.value = tension * 100

func _on_fish_caught(fish_type: String, value: int) -> void:
	phase_label.text = "CAUGHT!"
	fish_label.text = "You caught: %s (worth %d silver)" % [fish_type, value]
	hint_label.text = "Great catch!"
	_update_phase_ui(FishingGame.Phase.COMPLETE)

func _on_fish_escaped(reason: String) -> void:
	phase_label.text = "Got Away!"
	hint_label.text = reason
	_update_phase_ui(FishingGame.Phase.COMPLETE)

func _on_game_ended(success: bool, fish_type: String) -> void:
	var fish_data: Dictionary = {}
	if success and game:
		fish_data = {
			"type": fish_type,
			"nutrition": game.get_fish_nutrition(),
			"value": game.get_fish_value(),
		}

	# Wait a moment before allowing close
	await get_tree().create_timer(1.5).timeout
	fishing_completed.emit(success, fish_data)

# Button handlers
func _on_cast_pressed() -> void:
	if not game:
		return

	if game.current_phase == FishingGame.Phase.IDLE:
		game.cast_line()
		_update_phase_ui(FishingGame.Phase.CASTING)
		await get_tree().create_timer(0.5).timeout
		_update_phase_ui(FishingGame.Phase.WAITING)
	elif game.current_phase == FishingGame.Phase.HOOKED:
		game.hook_fish()
		_update_phase_ui(FishingGame.Phase.REELING)

func _on_reel_down() -> void:
	if game:
		game.set_reeling(true)

func _on_reel_up() -> void:
	if game:
		game.set_reeling(false)

func _on_close_pressed() -> void:
	_cleanup()

func _cleanup() -> void:
	if game:
		game.queue_free()
		game = null
	visible = false

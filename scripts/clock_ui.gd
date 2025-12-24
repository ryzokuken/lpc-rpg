class_name ClockUI extends Control
## On-screen clock display showing current time, day, and survival status
## Add to player's CanvasLayer HUD

@onready var time_label: Label = $Panel/VBox/TimeLabel
@onready var day_label: Label = $Panel/VBox/DayLabel
@onready var period_label: Label = $Panel/VBox/PeriodLabel
@onready var survival_container: VBoxContainer = $Panel/VBox/SurvivalBars
@onready var belly_bar: ProgressBar = $Panel/VBox/SurvivalBars/BellyBar
@onready var vigor_bar: ProgressBar = $Panel/VBox/SurvivalBars/VigorBar
@onready var nerve_bar: ProgressBar = $Panel/VBox/SurvivalBars/NerveBar

# Reference to game time singleton
var game_time: GameTime = null

# Reference to player for survival display
var player: Player = null

# ============================================================================
# SETTINGS
# ============================================================================

@export var show_survival_bars: bool = true
@export var compact_mode: bool = false # Just time, no day/period

func _ready() -> void:
	# Find GameTime singleton
	if Engine.has_singleton("GameTime"):
		game_time = Engine.get_singleton("GameTime")
	else:
		# Try as node in tree (autoload)
		game_time = get_node_or_null("/root/GameTime")

	if game_time:
		game_time.time_updated.connect(_on_time_updated)
		game_time.hour_passed.connect(_on_hour_passed)

	# Find player
	_find_player()

	# Initial update
	_update_display()

	# Configure visibility
	if survival_container:
		survival_container.visible = show_survival_bars
	if compact_mode:
		if day_label: day_label.visible = false
		if period_label: period_label.visible = false

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0] as Player

func _process(_delta: float) -> void:
	# Update survival bars if visible
	if show_survival_bars and player and player.survival:
		_update_survival_bars()

# ============================================================================
# DISPLAY UPDATES
# ============================================================================

func _update_display() -> void:
	if not game_time:
		return

	if time_label:
		time_label.text = game_time.get_time_string()

	if day_label and not compact_mode:
		day_label.text = "Day %d" % game_time.current_day

	if period_label and not compact_mode:
		period_label.text = game_time.get_time_period_name()
		_update_period_color()

func _update_period_color() -> void:
	if not period_label or not game_time:
		return

	var period := game_time.get_time_period()
	match period:
		GameTime.TimePeriod.DAWN:
			period_label.modulate = Color(1.0, 0.8, 0.6) # Warm orange
		GameTime.TimePeriod.MORNING:
			period_label.modulate = Color(1.0, 1.0, 0.8) # Bright yellow
		GameTime.TimePeriod.AFTERNOON:
			period_label.modulate = Color(1.0, 1.0, 1.0) # White
		GameTime.TimePeriod.EVENING:
			period_label.modulate = Color(1.0, 0.7, 0.5) # Orange
		GameTime.TimePeriod.NIGHT:
			period_label.modulate = Color(0.6, 0.6, 0.9) # Blue

func _update_survival_bars() -> void:
	if not player or not player.survival:
		return

	if belly_bar:
		belly_bar.value = player.survival.belly
		_color_bar(belly_bar, player.survival.belly)

	if vigor_bar:
		vigor_bar.value = player.survival.vigor
		_color_bar(vigor_bar, player.survival.vigor)

	if nerve_bar:
		nerve_bar.value = player.survival.nerve
		_color_bar(nerve_bar, player.survival.nerve)

func _color_bar(bar: ProgressBar, value: int) -> void:
	if value < 25:
		bar.modulate = Color.RED
	elif value < 50:
		bar.modulate = Color.ORANGE
	elif value < 75:
		bar.modulate = Color.YELLOW
	else:
		bar.modulate = Color.GREEN

# ============================================================================
# SIGNAL HANDLERS
# ============================================================================

func _on_time_updated(_hour: int, _minute: int, _day: int) -> void:
	_update_display()

func _on_hour_passed(_hour: int, _day: int) -> void:
	# Could add hour chime or visual flash here
	pass

# ============================================================================
# PUBLIC METHODS
# ============================================================================

## Register player for survival display
func set_player(p: Player) -> void:
	player = p

## Toggle survival bar visibility
func toggle_survival_bars() -> void:
	show_survival_bars = not show_survival_bars
	if survival_container:
		survival_container.visible = show_survival_bars

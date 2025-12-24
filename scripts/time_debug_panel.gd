class_name TimeDebugPanel extends Control
## Debug panel for controlling time during development
## Toggle with F9, allows speeding up time to test survival mechanics

@onready var time_scale_slider: HSlider = $Panel/VBox/TimeScaleSlider
@onready var time_scale_label: Label = $Panel/VBox/TimeScaleLabel
@onready var skip_button: Button = $Panel/VBox/SkipHourButton
@onready var set_time_container: HBoxContainer = $Panel/VBox/SetTimeContainer
@onready var hour_spinbox: SpinBox = $Panel/VBox/SetTimeContainer/HourSpin
@onready var set_button: Button = $Panel/VBox/SetTimeContainer/SetButton

var game_time: GameTime = null

func _ready() -> void:
	visible = false

	# Find GameTime
	game_time = get_node_or_null("/root/GameTime")

	if time_scale_slider:
		time_scale_slider.value = 1.0
		time_scale_slider.value_changed.connect(_on_time_scale_changed)

	if skip_button:
		skip_button.pressed.connect(_on_skip_hour)

	if set_button:
		set_button.pressed.connect(_on_set_time)

	_update_label()

func _input(event: InputEvent) -> void:
	# F9 toggles debug panel
	if event.is_action_pressed("toggle_time_debug"):
		visible = not visible
	# Handle by keycode if action not defined
	elif event is InputEventKey and event.pressed and event.keycode == KEY_F9:
		visible = not visible

func _on_time_scale_changed(value: float) -> void:
	if game_time:
		game_time.set_time_scale(value)
	_update_label()

func _on_skip_hour() -> void:
	if game_time:
		game_time.skip_hours(1)

func _on_set_time() -> void:
	if game_time and hour_spinbox:
		game_time.set_time(int(hour_spinbox.value))

func _update_label() -> void:
	if time_scale_label and time_scale_slider:
		time_scale_label.text = "Time Scale: %.1fx" % time_scale_slider.value

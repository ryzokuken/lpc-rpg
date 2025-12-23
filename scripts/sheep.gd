class_name Sheep extends Character

@export var is_roaming := true
@export var move_speed := 50

@onready var destination := position

func _physics_process(_delta: float) -> void:
	if is_roaming and destination != position:
		character_state = CharacterState.WALKING
		velocity = direction * move_speed
	else:
		character_state = CharacterState.IDLE
		velocity = Vector2.ZERO

func _on_timer_timeout() -> void:
	if destination == position and is_roaming:
		direction = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT].pick_random()
		destination = position + (direction * randf())
		$Timer.start()

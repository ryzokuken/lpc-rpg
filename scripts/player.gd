extends CharacterBody2D

@export var move_speed = 300
@export var inventory: Inventory

var direction = Vector2.ZERO
var is_moving = false

@onready var player = $Sprite as LPCAnimatedSprite2D
@onready var inventoryUI = $Inventory

func _ready() -> void:
	inventoryUI.update(inventory.items)

func _process(_delta: float) -> void:
	var dir: String
	match direction:
		Vector2.LEFT:
			dir = "west"
		Vector2.RIGHT:
			dir = "east"
		Vector2.UP:
			dir = "north"
		Vector2.DOWN:
			dir = "south"
		_:
			dir = "south"
	player.play_animation("walk" if is_moving else "idle", dir)

func _physics_process(_delta: float) -> void:
	var input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input != Vector2.ZERO:
		direction = input.normalized()
		is_moving = true
	else:
		is_moving = false
	velocity = input * move_speed
	move_and_slide()

class_name Player extends Character

@export var inventory: Inventory
@export var survival: SurvivalStats

var base_move_speed := 150
var is_interacting := false

#enum PlayerState {
	#NORMAL,
	#STEALTH,
	#INTERACTING
#}
#var player_state := PlayerState.NORMAL

@onready var inventoryUI := $Inventory
@onready var target := $Target
@onready var interact_tooltip := $InteractTooltip
@onready var stealth_vingenette: ColorRect = $Stealth/ColorRect

func _ready() -> void:
	inventoryUI.update(inventory.items)
	character_name = "Player"
	# Initialize survival stats if not set
	if survival == null:
		survival = SurvivalStats.create_healthy()

func _process(_delta: float) -> void:
	animate()

func interact():
	if target.is_colliding():
		interact_tooltip.show()
		if Input.is_action_just_pressed("interact"):
			var bubble = target.get_collider() as Bubble
			assert(bubble is Bubble)
			#player_state = PlayerState.INTERACTING
			is_interacting = true
			await bubble.interact(self)
			is_interacting = false
			inventoryUI.update(inventory.items)
			#player_state = PlayerState.NORMAL
	else:
		interact_tooltip.hide()

func move(speed: int):
	var input = Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
	if input != Vector2.ZERO:
		direction = input.normalized()
		target.target_position = direction * 50
		character_state = CharacterState.WALKING
	else:
		character_state = CharacterState.IDLE
	velocity = input * speed
	move_and_slide()

func _physics_process(_delta: float) -> void:
	if not is_interacting:
		interact()
		# Apply survival speed modifier
		var speed_modifier: float = 1.0
		if survival:
			speed_modifier = survival.get_speed_multiplier()
		move(int(base_move_speed * speed_modifier))
	#match player_state:
		#PlayerState.NORMAL:
		#PlayerState.STEALTH:
			#interact()
			#move(move_speed * 0.5) # FIXME: For now, stealth speed is simply half of the base move speed

#func _unhandled_input(event: InputEvent) -> void:
	#if event.is_action_released("stealth"):
		#toggle_stealth()

#func toggle_stealth() -> void:
	#var tween = create_tween()
	#var target_intesity: float
	#var target_modulate: Color
	#if player_state == PlayerState.STEALTH:
		#player_state = PlayerState.NORMAL
		#target_intesity = 0.0
		#target_modulate = Color(1, 1, 1, 1)
	#elif player_state == PlayerState.NORMAL:
		#player_state = PlayerState.STEALTH
		#target_intesity = 1.0
		#target_modulate = Color(1, 1, 1, 0.5)
	#else:
		#push_error("can't toggle stealth")
	#tween.tween_property(stealth_vingenette.material, "shader_parameter/intensity", target_intesity, 0.5)
	#tween.parallel().tween_property(sprite, "self_modulate", target_modulate, 0.5)

@abstract
class_name Character extends CharacterBody2D

enum CharacterState {
	IDLE,
	WALKING,
}

@export var character_name := ""
@export var stats: CharacterStats

var direction: Vector2
var character_state := CharacterState.IDLE

@onready var sprite := $Sprite

func _vector2direction(v: Vector2 = Vector2.ZERO) -> String:
	match v:
		Vector2.LEFT:
			return "west"
		Vector2.RIGHT:
			return "east"
		Vector2.UP:
			return "north"
		Vector2.DOWN:
			return "south"
		_:
			return "south"

func _compute_animation() -> String:
	return "%s_%s" % ["idle" if character_state == CharacterState.IDLE else "walk", _vector2direction(direction)]

var last_animation: String
func animate():
	var animation = _compute_animation()
	if animation != last_animation:
		sprite.play(animation)
		last_animation = animation

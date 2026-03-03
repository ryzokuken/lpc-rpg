extends Node

@onready var turns := $Turns
@onready var actions := $Actions

var player_turn: bool

func start(player: Player, enemy: Character) -> void:
	# Setup combat
	player_turn = player.stats.get_initiative() > enemy.stats.get_initiative()

func _on_attack_pressed() -> void:
	# Handle player attack
	pass

func _on_escape_pressed() -> void:
	# Handle player escape
	pass

func process_turn():
	turns.text = "Player's Turn" if player_turn else "Enemy's Turn"
	actions.visible = player_turn

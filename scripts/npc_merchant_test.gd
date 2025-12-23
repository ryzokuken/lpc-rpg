extends Node2D

@onready var npc = $NPC

func _ready() -> void:
	npc.open_inventory()

func _on_kill_npc_button_up() -> void:
	npc.alive = false

func _on_revive_npc_button_up() -> void:
	npc.alive = true

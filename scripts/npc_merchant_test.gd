extends Node2D

@onready var npc = $NPC

func _ready() -> void:
	npc.open_inventory()

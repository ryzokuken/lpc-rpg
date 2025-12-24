class_name FishingSpot extends Node2D
## Interactive fishing spot that triggers the fishing mini-game

const FishingScene = preload("res://scenes/fishing.tscn")

@onready var bubble: Bubble = $Bubble

func _ready() -> void:
	bubble.register("Fish", _start_fishing)

func _start_fishing(player: Player) -> void:
	# Create fishing UI
	var fishing_ui: FishingUI = FishingScene.instantiate()
	add_child(fishing_ui)

	# Get player stats
	var player_finesse: int = 5
	var player_wits: int = 5
	if player.stats:
		player_finesse = player.stats.finesse
		player_wits = player.stats.wits

	fishing_ui.start_fishing(player_finesse, player_wits)

	# Wait for fishing to complete
	var result = await fishing_ui.fishing_completed
	var caught: bool = result[0]
	var fish_data: Dictionary = result[1]

	if caught and not fish_data.is_empty():
		# Add fish to player inventory
		# For now, just add nutrition directly to belly
		if player.survival:
			player.survival.eat(fish_data.nutrition)
		# Could also add silver for selling
		# player.inventory.silver += fish_data.value

	fishing_ui.queue_free()

extends Resource

class_name Item

enum ItemType {ARMOR, WEAPON, CONSUMABLE, MISC}

@export var name: String = ""
@export var icon: Texture2D
@export var type: ItemType
@export_multiline var description: String = ""
@export var weight: int = 0
@export var value: int = 0

# Consumable effects (positive = benefit, negative = cost)
@export var belly_delta: int = 0
@export var hydration_delta: int = 0
@export var vigor_delta: int = 0
@export var nerve_delta: int = 0
@export var sobriety_delta: int = 0

func consume(survival: SurvivalStats) -> void:
	if type != ItemType.CONSUMABLE:
		return
	survival.modify_belly(belly_delta)
	survival.modify_hydration(hydration_delta)
	survival.modify_vigor(vigor_delta)
	survival.modify_nerve(nerve_delta)
	survival.modify_sobriety(sobriety_delta)

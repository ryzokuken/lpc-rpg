extends Resource

class_name Item

enum ItemType { ARMOR, WEAPON, MISC }

@export var name: String = ""
@export var icon: Texture2D
@export var type: ItemType
@export_multiline var description: String = ""
@export var weight: int = 0
@export var value: int = 0

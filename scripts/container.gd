extends StaticBody2D

@onready var bubble: Bubble = $Bubble
@onready var items: Items = $Items

var _items: Array[Item] = []

func _search(player: Player) -> void:
	await items.search(player)

func _ready() -> void:
	_items.append(ItemRegistry.random_item())
	_items.append(ItemRegistry.random_item())
	_items.append(ItemRegistry.random_item())
	_items.append(ItemRegistry.random_item())
	_items.append(ItemRegistry.random_item())
	items.set_items(_items)
	bubble.register("Search", _search)

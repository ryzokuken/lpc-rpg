@tool
extends Resource

class_name Inventory

@export var items: Array[Item] = []
@export var silver: int = 0
# @export var stolen_items: Array[Item] = []

# func add_item(item: Item, stolen: bool = false) -> void:
# 	items.append(item)
# 	if stolen:
# 		stolen_items.append(item)

# func remove_item(item: Item) -> bool:
# 	if item in items:
# 		items.erase(item)
# 		if item in stolen_items:
# 			stolen_items.erase(item)
# 		return true
# 	return false

# func is_stolen(item: Item) -> bool:
# 	return item in stolen_items

#signal items_updated

extends CanvasLayer

@onready var list = $VBoxContainer/HBoxContainer/Backpack/MarginContainer/VBoxContainer/ItemList
@onready var details = $VBoxContainer/HBoxContainer/Details
@onready var details_name = $VBoxContainer/HBoxContainer/Details/MarginContainer/VBoxContainer/Name
@onready var details_icon = $VBoxContainer/HBoxContainer/Details/MarginContainer/VBoxContainer/Icon

var items_cache: Array[Item]

func _ready() -> void:
	hide()
	list.clear()
	details.hide()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("inventory"):
		if visible:
			hide()
		else:
			show()

func _on_close_button_button_up() -> void:
	hide()

func update(items: Array[Item]):
	items_cache.clear()
	for item in items:
		if item:
			list.add_item(item.name, item.icon)
			items_cache.append(item)


func _on_item_list_item_selected(index: int) -> void:
	var item = items_cache[index]
	details_name.text = item.name
	details_icon.texture = item.icon
	details.show()

extends Control

@onready var list = $VBoxContainer/HBoxContainer/Backpack/MarginContainer/VBoxContainer/ItemList
@onready var details = $VBoxContainer/HBoxContainer/Details
@onready var details_name = $VBoxContainer/HBoxContainer/Details/MarginContainer/VBoxContainer/Name
@onready var details_icon = $VBoxContainer/HBoxContainer/Details/MarginContainer/VBoxContainer/Icon

var is_open = false
var items_cache: Array[Item]

func _ready() -> void:
	close()
	list.clear()
	details.visible = false
	
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("inventory"):
		if is_open:
			close()
		else:
			open()

func open():
	is_open = true
	visible = true

func close():
	is_open = false
	visible = false 

func _on_close_button_button_up() -> void:
	close()

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
	details.visible = true

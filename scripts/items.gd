class_name Items extends CanvasLayer

@onready var buy := $Panel/VBoxContainer/Buy/BuyButtons
@onready var silver := $Panel/VBoxContainer/Buy/Silver
@onready var keep_buttons := $Panel/VBoxContainer/KeepButtons
@onready var steal_buttons := $Panel/VBoxContainer/StealButtons
@onready var close_button := $Panel/CloseButton
@onready var list: ItemList = $Panel/VBoxContainer/List

var _items_cache: Array[Item] = []
var _player: Player

func _ready() -> void:
	assert(not visible)

func set_items(items: Array[Item]) -> void:
	list.clear()
	for item in items:
		list.add_item(item.name, item.icon)
	_items_cache = items

func trade(player: Player, _reputation: float) -> void:
	buy.show()
	silver.text = "Silver %s" % player.inventory.silver
	keep_buttons.hide()
	steal_buttons.hide()
	show()
	await close_button.pressed
	hide()

func search(player: Player) -> void:
	_player = player
	buy.hide()
	keep_buttons.show()
	steal_buttons.hide()
	show()
	await close_button.pressed
	_player = null
	hide()

func steal() -> void:
	buy.hide()
	keep_buttons.hide()
	steal_buttons.show()
	show()
	await close_button.pressed
	hide()

#func _on_list_item_selected(index: int) -> void:
	#buy_button.text = "Buy (%s)" % inventory.items[index].value
	#buy_button.disabled = false

func _on_buy_pressed() -> void:
	pass # Replace with function body.

func _on_keep_pressed() -> void:
	assert(_player)
	var item = list.selected_item
	_player.inventory.items.append(item)
	_items_cache.erase(item)
	list.remove_item(item)

func _on_keep_all_pressed() -> void:
	assert(_player)
	_player.inventory.items.append_array(_items_cache)
	_items_cache.clear()
	list.clear()

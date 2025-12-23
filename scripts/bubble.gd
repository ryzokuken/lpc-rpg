class_name Bubble extends Area2D

@onready var menu: PopupMenu = $Menu

var _is_interacting := false
var _player: Player = null
var _verbs: Array[String] = []
var _interactions: Dictionary[String, Callable]

func _ready() -> void:
	assert(_interactions.is_empty())
	menu.clear()
	_verbs.clear()

func clear() -> void:
	menu.clear()
	_verbs.clear()
	_interactions.clear()

func register(verb: String, action: Callable):
	var index := _verbs.size()
	assert(index == _interactions.size())
	_verbs.append(verb)
	_interactions.set(verb, action)
	menu.add_item(verb, index)

func interact(player: Player):
	menu.show()
	_player = player
	await interaction_over

func _on_menu_id_pressed(id: int) -> void:
	_is_interacting = true
	var verb := _verbs[id]
	await _interactions[verb].call(_player)
	interaction_over.emit()
	_is_interacting = false

func _on_menu_popup_hide() -> void:
	await get_tree().process_frame
	if not _is_interacting:
		interaction_over.emit()

signal interaction_over

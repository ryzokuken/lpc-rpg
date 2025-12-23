extends Node

var _items_by_type := {}
var _all_items := []

func _ready() -> void:
	_load_items()

func _load_items() -> void:
	const path := "res://resources/items/"
	var dir := DirAccess.open(path)
	assert(dir)
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		var item := load("%s//%s" % [path, file_name]) as Item
		_register_item(item)
		file_name = dir.get_next()
		
func _register_item(item: Item) -> void:
	_all_items.append(item)
	var type := item.type
	if not _items_by_type.has(type):
		_items_by_type.set(type, [])
	_items_by_type.get(type).append(item)
	
func random_item() -> Item:
	return _all_items.pick_random()

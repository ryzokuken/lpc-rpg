@tool
extends AnimatableBody2D

const merchant_dialog = preload("res://dialogs/merchant.dialogue")

@onready var sprite = $Sprite as LPCAnimatedSprite2D
@onready var exclamation = $Exclamation
@onready var inventoryui = $Items
@onready var itemlist = $Items/VBoxContainer/List
@onready var buy_button = $Items/VBoxContainer/Buttons/Buy

@export var default_animation = "idle"
@export var default_direction = "south"
@export var inventory: Inventory
@export var character_name: String = "NPC":
	set(value):
		character_name = value
		$Label.text = value

var player_nearby = false
var dialog_in_progress = false

func _ready() -> void:
	sprite.play_animation(default_animation, default_direction)
	exclamation.visible = false
	DialogueManager.dialogue_started.connect(func(_dialog): dialog_in_progress = true)
	DialogueManager.dialogue_ended.connect(func(_dialog): dialog_in_progress = false)
	inventoryui.visible = false
	itemlist.clear()
	buy_button.disabled = true
	for item in inventory.items:
		if item:
			var index = itemlist.add_item(item.name, item.icon)
			itemlist.set_item_tooltip(index, item.description)

func _process(_delta: float) -> void:
	if !inventoryui.visible and !dialog_in_progress and player_nearby and Input.is_action_just_pressed("ui_accept"):
		DialogueManager.show_dialogue_balloon(merchant_dialog, "", [self])

func _on_bubble_area_entered(_area: Area2D) -> void:
	player_nearby = true
	exclamation.visible = true

func _on_bubble_area_exited(_area: Area2D) -> void:
	player_nearby = false
	exclamation.visible = false

func open_inventory():
	inventoryui.visible = true

func _on_list_item_selected(_index: int) -> void:
	buy_button.disabled = false

func _on_close_button_button_up() -> void:
	inventoryui.visible = false

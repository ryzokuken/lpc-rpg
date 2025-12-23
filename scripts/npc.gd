class_name NPC extends Character

@onready var bubble: Bubble = $Bubble
@onready var item_list: Items = $ItemList
@onready var detected_dialog: DialogueResource = preload("res://dialogs/detected.dialogue")

# Liar's Dice scene for gambling
const LiarsDiceScene = preload("res://scenes/liars_dice.tscn")

enum NPCType {
	MERCHANT,
	GENERIC,
	GAMBLER # NPCs who will play dice with you
}

enum NPCState {
	NORMAL,
	KNOCKED_OUT,
	DEAD
}

@export var npc_type: NPCType = NPCType.GENERIC
@export var inventory: Inventory
@export_file var dialog_path: String = ""
@export_range(0, 3) var gambler_personality: int = 2 # 0=Cautious, 1=Aggressive, 2=Balanced, 3=Reckless

var _dialog: DialogueResource = null
var rapport: float = 0.0 # Player's rapport with this NPC, from -100 to 100
var npc_state: NPCState = NPCState.NORMAL

# ============================================================================
# STAT-BASED DIFFICULTY CALCULATIONS
# ============================================================================

## Calculate base detection difficulty when player commits crimes
## Higher = harder to avoid detection (NPC is perceptive)
func _get_detection_difficulty() -> int:
	if stats:
		return 30 + (stats.wits * 3) # 33-60 range
	return 50

## Calculate difficulty for intimidation attempts
## Player needs: Brawn + Swagger, NPC resists with: Brawn + Wits
func get_intimidation_difficulty() -> int:
	if stats:
		return 20 + (stats.brawn * 2) + (stats.wits * 2) # 24-60 range
	return 40

## Calculate difficulty for persuasion attempts
## Player needs: Swagger + Wits, modulated by rapport
func get_persuasion_difficulty() -> int:
	var base: int = 50
	if stats:
		base = 30 + (stats.wits * 2)
	# Good rapport makes persuasion easier
	var rapport_mod: int = - floori(rapport / 5.0) # -20 to +20
	return base + rapport_mod

## Calculate difficulty for deception attempts
## Player needs: Wits + Finesse, NPC resists with: Wits
func get_deception_difficulty() -> int:
	if stats:
		return 25 + (stats.wits * 4) # 29-65 range
	return 45

## Calculate difficulty for knockout attempts
## Player needs: Brawn + Finesse, NPC resists with: Brawn
func get_knockout_difficulty() -> int:
	if stats:
		return 20 + (stats.brawn * 4) # 24-60 range
	return 40

## Calculate difficulty for pickpocket attempts
## Player needs: Finesse + Wits, NPC resists with: Wits
func get_pickpocket_difficulty() -> int:
	if stats:
		return 30 + (stats.wits * 3) # 33-60 range
	return 50

# ============================================================================
# INTERACTION FUNCTIONS
# ============================================================================

func _detect_crime(player: Player) -> void:
	if npc_state != NPCState.NORMAL:
		return
	# Detection based on player's Finesse vs NPC's Wits
	var player_stealth: int = 0
	if player.stats:
		player_stealth = player.stats.get_pickpocket_value()
	var difficulty: int = _get_detection_difficulty()
	var detected: bool = randi_range(1, 100) > (player_stealth - difficulty + 50)
	if detected:
		DialogueManager.show_dialogue_balloon(detected_dialog, "", [self])
		await DialogueManager.dialogue_ended

func _talk(_player: Player) -> void:
	DialogueManager.show_dialogue_balloon(_dialog, "", [self])
	await DialogueManager.dialogue_ended

func _knock_out(player: Player) -> void:
	var player_check: int = 50
	if player.stats:
		player_check = player.stats.calculate_check_value(player.stats.brawn, player.stats.finesse)
	var difficulty: int = get_knockout_difficulty()
	var success: bool = randi_range(1, 100) <= (player_check - difficulty + 50)
	if success:
		npc_state = NPCState.KNOCKED_OUT
		_populate_menu()
	await _detect_crime(player)

func _pickpocket(player: Player) -> void:
	var player_check: int = 50
	if player.stats:
		player_check = player.stats.get_pickpocket_value()
	var difficulty: int = get_pickpocket_difficulty()
	var success: bool = randi_range(1, 100) <= (player_check - difficulty + 50)
	if success:
		item_list.steal()
	await _detect_crime(player)

func _trade(player: Player) -> void:
	await item_list.trade(player, rapport)

func _search(player: Player) -> void:
	if npc_state == NPCState.NORMAL:
		return
	item_list.search(player)

func _play_dice(player: Player) -> void:
	# Create dice game UI
	var dice_game: LiarsDiceUI = LiarsDiceScene.instantiate()
	add_child(dice_game)

	# Get player's Wits and Swagger from stats system
	var player_wits: int = 3
	var player_swagger: int = 3
	if player.stats:
		player_wits = player.stats.wits
		player_swagger = player.stats.swagger

	# Start game with this NPC's personality
	var personality: LiarsDiceAI.Personality = gambler_personality as LiarsDiceAI.Personality
	dice_game.start_game(character_name, personality, player_wits, player_swagger)

	# Wait for game to end
	var result = await dice_game.game_closed
	var player_won: bool = result[0]
	var silver_change: int = result[1]

	# Update player's silver
	player.inventory.silver += silver_change

	# Update rapport based on outcome
	if player_won:
		rapport -= 5.0 # They lost, slightly annoyed
	else:
		rapport += 2.0 # They won, slightly happier

	dice_game.queue_free()

func _ready() -> void:
	character_name = "NPC"
	if dialog_path != "":
		_dialog = load(dialog_path)
	item_list.set_items(inventory.items)
	_populate_menu()

func _populate_menu() -> void:
	if npc_state == NPCState.NORMAL:
		if _dialog != null:
			bubble.register("Talk", _talk)
		if npc_type == NPCType.MERCHANT:
			bubble.register("Trade", _trade)
		if npc_type == NPCType.GAMBLER:
			bubble.register("Play Dice", _play_dice)
		bubble.register("Pickpocket", _pickpocket)
		bubble.register("Knock out", _knock_out)
	else:
		bubble.register("Search", _search)

#func calculate_total_price():
	#var total = inventory.items.reduce(func(acc, item): return acc + item.value, 0)
	#buy_all_button.text = "Buy All (%s)" % total
#
#func _on_close_button_pressed() -> void:
	#inventoryui.hide()
	#inventory_closed.emit()
#
#signal inventory_closed

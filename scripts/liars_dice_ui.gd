## UI controller for the Liar's Dice mini-game
class_name LiarsDiceUI extends CanvasLayer

signal game_closed(player_won: bool, silver_change: int)

const DICE_TEXTURES := {
	1: preload("res://sprites/interface/kenney_boardgame-pack/PNG/Dice/dieWhite1.png"),
	2: preload("res://sprites/interface/kenney_boardgame-pack/PNG/Dice/dieWhite2.png"),
	3: preload("res://sprites/interface/kenney_boardgame-pack/PNG/Dice/dieWhite3.png"),
	4: preload("res://sprites/interface/kenney_boardgame-pack/PNG/Dice/dieWhite4.png"),
	5: preload("res://sprites/interface/kenney_boardgame-pack/PNG/Dice/dieWhite5.png"),
	6: preload("res://sprites/interface/kenney_boardgame-pack/PNG/Dice/dieWhite6.png"),
}

const DICE_HIDDEN_TEXTURE := preload("res://sprites/interface/kenney_boardgame-pack/PNG/Dice/dieRed1.png")

@export var wager_amount: int = 10

# Node references
@onready var panel: PanelContainer = $Panel
@onready var opponent_name_label: Label = $Panel/VBox/OpponentArea/OpponentName
@onready var opponent_dice_container: HBoxContainer = $Panel/VBox/OpponentArea/OpponentDice
@onready var player_dice_container: HBoxContainer = $Panel/VBox/PlayerArea/PlayerDice
@onready var stats_hint_label: Label = $Panel/VBox/PlayerArea/StatsHint
@onready var current_bid_label: Label = $Panel/VBox/BidArea/CurrentBid
@onready var quantity_spinbox: SpinBox = $Panel/VBox/BidArea/BidControls/QuantitySpinner
@onready var face_option: OptionButton = $Panel/VBox/BidArea/BidControls/FaceSelector
@onready var make_bid_button: Button = $Panel/VBox/BidArea/MakeBidButton
@onready var call_liar_button: Button = $Panel/VBox/ActionButtons/CallLiarButton
@onready var fold_button: Button = $Panel/VBox/ActionButtons/FoldButton
@onready var message_log: RichTextLabel = $Panel/VBox/MessageLog
@onready var close_button: TextureButton = $Panel/CloseButton

# Game state
var game: LiarsDice
var ai: LiarsDiceAI
var player_name := "Player"
var opponent_name := "Opponent"
var player_wits: int = 1 # Injected from player stats
var player_swagger: int = 1 # Injected from player stats
var is_player_turn := false

func _ready() -> void:
	visible = false
	_setup_face_selector()
	_connect_signals()

func _setup_face_selector() -> void:
	face_option.clear()
	for i in range(1, 7):
		face_option.add_item(str(i), i)
	face_option.selected = 1 # Default to "2"

func _connect_signals() -> void:
	make_bid_button.pressed.connect(_on_make_bid_pressed)
	call_liar_button.pressed.connect(_on_call_liar_pressed)
	fold_button.pressed.connect(_on_fold_pressed)
	close_button.pressed.connect(_on_close_pressed)

## Start a new game against an NPC
func start_game(npc_name: String, npc_personality: LiarsDiceAI.Personality, p_wits: int = 1, p_swagger: int = 1) -> void:
	opponent_name = npc_name
	player_wits = p_wits
	player_swagger = p_swagger

	# Create game instance
	game = LiarsDice.new()
	add_child(game)

	# Connect game signals
	game.game_started.connect(_on_game_started)
	game.round_started.connect(_on_round_started)
	game.dice_rolled.connect(_on_dice_rolled)
	game.bid_made.connect(_on_bid_made)
	game.challenge_made.connect(_on_challenge_made)
	game.challenge_resolved.connect(_on_challenge_resolved)
	game.dice_lost.connect(_on_dice_lost)
	game.player_eliminated.connect(_on_player_eliminated)
	game.game_ended.connect(_on_game_ended)
	game.turn_changed.connect(_on_turn_changed)

	# Create AI opponent
	ai = LiarsDiceAI.new(npc_personality, game, opponent_name)

	# Update UI
	opponent_name_label.text = opponent_name
	message_log.clear()
	_log_message("Game started! Wager: %d silver" % wager_amount)

	visible = true

	# Start the game
	game.start_game([player_name, opponent_name])

## Display player's dice
func _display_player_dice(dice: Array[int]) -> void:
	# Clear existing dice
	for child in player_dice_container.get_children():
		child.queue_free()

	# Add dice sprites
	for die_value in dice:
		var tex_rect := TextureRect.new()
		tex_rect.texture = DICE_TEXTURES[die_value]
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.custom_minimum_size = Vector2(64, 64)
		player_dice_container.add_child(tex_rect)

## Display opponent's hidden dice
func _display_opponent_dice(count: int) -> void:
	# Clear existing dice
	for child in opponent_dice_container.get_children():
		child.queue_free()

	# Add hidden dice sprites
	for i in range(count):
		var tex_rect := TextureRect.new()
		tex_rect.texture = DICE_HIDDEN_TEXTURE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.custom_minimum_size = Vector2(48, 48)
		tex_rect.modulate = Color(0.5, 0.5, 0.5, 1) # Dimmed to show they're hidden
		opponent_dice_container.add_child(tex_rect)

## Reveal all dice (after a challenge)
func _reveal_all_dice() -> void:
	# Reveal opponent's dice
	for child in opponent_dice_container.get_children():
		child.queue_free()

	var opp_dice: Array[int] = game.get_player_dice(opponent_name)
	for die_value in opp_dice:
		var tex_rect := TextureRect.new()
		tex_rect.texture = DICE_TEXTURES[die_value]
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.custom_minimum_size = Vector2(48, 48)
		opponent_dice_container.add_child(tex_rect)

## Update skill-based hints
func _update_hints() -> void:
	var hints := []

	# Wits hint: probability
	if player_wits >= 3:
		var bid := game.get_current_bid()
		if bid.quantity > 0:
			var prob := game.calculate_bid_probability(bid.quantity, bid.face)
			if player_wits >= 6:
				hints.append("Probability: ~%d%%" % int(prob * 100))
			else:
				if prob > 0.6:
					hints.append("This bid seems likely...")
				elif prob < 0.4:
					hints.append("This bid seems risky...")

	# Swagger hint: tell
	if player_swagger >= 3 and not is_player_turn:
		var bid := game.get_current_bid()
		if bid.quantity > 0:
			# Check if AI is bluffing (has less than bid amount)
			var opp_dice: Array[int] = game.get_player_dice(opponent_name)
			var opp_matching := 0
			for die in opp_dice:
				if die == bid.face or (die == 1 and bid.face != 1):
					opp_matching += 1
			var is_bluffing: bool = opp_matching < bid.quantity / 2

			if player_swagger >= 6 or randf() > 0.5:
				hints.append(ai.get_tell_hint(is_bluffing))

	stats_hint_label.text = "\n".join(hints) if hints.size() > 0 else ""

## Update UI for current turn
func _update_turn_ui() -> void:
	var is_first_bid: bool = game.get_current_bid().quantity == 0

	make_bid_button.disabled = not is_player_turn
	call_liar_button.disabled = not is_player_turn or not game.can_challenge()
	fold_button.disabled = not is_player_turn

	if is_player_turn:
		current_bid_label.text = "Your turn!" if is_first_bid else "Current bid: %d × %d" % [game.get_current_bid().quantity, game.get_current_bid().face]
	else:
		current_bid_label.text = "%s is thinking..." % opponent_name

	# Update quantity spinner range
	var total_dice := game.get_player_dice(player_name).size() + game.get_player_dice_count(opponent_name)
	quantity_spinbox.max_value = total_dice
	if is_first_bid:
		quantity_spinbox.min_value = 1
		quantity_spinbox.value = 1
	else:
		quantity_spinbox.min_value = game.get_current_bid().quantity
		quantity_spinbox.value = game.get_current_bid().quantity

	_update_hints()

## Log a message
func _log_message(text: String) -> void:
	message_log.append_text(text + "\n")

# Signal handlers
func _on_game_started(_players: Array[String]) -> void:
	pass

func _on_round_started(_current_player: String, all_dice_count: int) -> void:
	_log_message("--- New round! %d dice in play ---" % all_dice_count)
	_display_opponent_dice(game.get_player_dice_count(opponent_name))

func _on_dice_rolled(rolled_player: String, dice: Array[int]) -> void:
	if rolled_player == player_name:
		_display_player_dice(dice)

func _on_bid_made(bidder: String, quantity: int, face: int) -> void:
	_log_message("%s bids: %d × %d" % [bidder, quantity, face])

func _on_challenge_made(challenger: String, challenged: String) -> void:
	_log_message("%s calls LIAR on %s!" % [challenger, challenged])
	_reveal_all_dice()

func _on_challenge_resolved(bid_was_true: bool, loser: String, actual_count: int) -> void:
	if bid_was_true:
		_log_message("The bid was TRUE! (%d found)" % actual_count)
	else:
		_log_message("The bid was FALSE! (only %d found)" % actual_count)
	_log_message("%s loses a die!" % loser)

func _on_dice_lost(who: String, remaining: int) -> void:
	_log_message("%s now has %d dice" % [who, remaining])

func _on_player_eliminated(who: String) -> void:
	_log_message("%s is eliminated!" % who)

func _on_game_ended(winner: String) -> void:
	_log_message("=== %s WINS! ===" % winner)
	is_player_turn = false
	_update_turn_ui()

	var player_won := winner == player_name
	var silver_change := wager_amount if player_won else -wager_amount

	# Delay before showing result
	await get_tree().create_timer(2.0).timeout
	game_closed.emit(player_won, silver_change)

func _on_turn_changed(current_player: String) -> void:
	is_player_turn = current_player == player_name
	_update_turn_ui()

	# If it's AI's turn, let them act after a delay
	if not is_player_turn:
		await get_tree().create_timer(1.0).timeout
		_do_ai_turn()

## Execute AI's turn
func _do_ai_turn() -> void:
	if not game.game_active:
		return

	var decision := ai.decide_action()

	if decision.action == "challenge":
		game.challenge(opponent_name)
	else:
		game.make_bid(opponent_name, decision.quantity, decision.face)

# Button handlers
func _on_make_bid_pressed() -> void:
	var quantity := int(quantity_spinbox.value)
	var face := face_option.get_item_id(face_option.selected)

	if game.is_valid_bid(quantity, face):
		game.make_bid(player_name, quantity, face)
	else:
		_log_message("Invalid bid! Must raise quantity or face.")

func _on_call_liar_pressed() -> void:
	if game.can_challenge():
		game.challenge(player_name)

func _on_fold_pressed() -> void:
	_log_message("You fold...")
	game_closed.emit(false, -wager_amount)
	_cleanup()

func _on_close_pressed() -> void:
	if game.game_active:
		# Folding during active game
		_on_fold_pressed()
	else:
		_cleanup()

func _cleanup() -> void:
	if game:
		game.queue_free()
		game = null
	ai = null
	visible = false

class_name LiarsDice extends Node
## Liar's Dice game logic - handles bidding, challenging, and game state

signal game_started(player_names: Array[String])
signal round_started(current_player: String, all_dice_count: int)
signal dice_rolled(player_name: String, dice: Array[int]) # Only emitted for player's own dice
signal bid_made(player_name: String, quantity: int, face: int)
signal challenge_made(challenger: String, challenged: String)
signal challenge_resolved(bid_was_true: bool, loser: String, actual_count: int)
signal dice_lost(player_name: String, remaining: int)
signal player_eliminated(player_name: String)
signal game_ended(winner: String)
signal turn_changed(current_player: String)

const STARTING_DICE := 5
const MIN_FACE := 1
const MAX_FACE := 6

# Game state
var players: Array[String] = []
var player_dice: Dictionary = {} # player_name -> Array[int]
var current_player_index: int = 0
var current_bid: Dictionary = {"quantity": 0, "face": 0} # Empty bid
var last_bidder: String = ""
var game_active: bool = false
var wilds_enabled: bool = true # 1s count as wild unless someone bids on 1s

## Initialize a new game with player names
func start_game(player_names: Array[String]) -> void:
	players = player_names.duplicate()
	player_dice.clear()
	for player in players:
		player_dice[player] = []
		_roll_dice_for_player(player, STARTING_DICE)

	current_player_index = 0
	current_bid = {"quantity": 0, "face": 0}
	last_bidder = ""
	game_active = true
	wilds_enabled = true

	game_started.emit(players)
	_start_new_round()

## Roll dice for a player
func _roll_dice_for_player(player_name: String, count: int) -> void:
	var dice: Array[int] = []
	for i in range(count):
		dice.append(randi_range(MIN_FACE, MAX_FACE))
	player_dice[player_name] = dice

## Start a new round (after a challenge is resolved)
func _start_new_round() -> void:
	# Re-roll all remaining dice
	for player in players:
		if player_dice[player].size() > 0:
			_roll_dice_for_player(player, player_dice[player].size())
			# Only emit dice for this player (hidden from others in UI)
			dice_rolled.emit(player, player_dice[player])

	# Reset bid
	current_bid = {"quantity": 0, "face": 0}
	last_bidder = ""
	wilds_enabled = true

	var total_dice := _count_all_dice()
	round_started.emit(get_current_player(), total_dice)
	turn_changed.emit(get_current_player())

## Get current player name
func get_current_player() -> String:
	if players.is_empty():
		return ""
	return players[current_player_index]

## Count all dice still in play
func _count_all_dice() -> int:
	var total := 0
	for player in players:
		total += player_dice[player].size()
	return total

## Check if a bid is valid (higher than current bid)
func is_valid_bid(quantity: int, face: int) -> bool:
	if face < MIN_FACE or face > MAX_FACE:
		return false
	if quantity < 1:
		return false
	if quantity > _count_all_dice():
		return false # Can't bid more dice than exist

	# First bid of round - any valid bid works
	if current_bid.quantity == 0:
		return true

	# Must raise: more qty, OR same qty + higher face
	if quantity > current_bid.quantity:
		return true
	if quantity == current_bid.quantity and face > current_bid.face:
		return true

	return false

## Make a bid
func make_bid(player_name: String, quantity: int, face: int) -> bool:
	if not game_active:
		return false
	if player_name != get_current_player():
		return false
	if not is_valid_bid(quantity, face):
		return false

	current_bid = {"quantity": quantity, "face": face}
	last_bidder = player_name

	# If someone bids on 1s, wilds are disabled for this round
	if face == 1:
		wilds_enabled = false

	bid_made.emit(player_name, quantity, face)
	_advance_turn()
	turn_changed.emit(get_current_player())

	return true

## Challenge the previous bid (call "Liar!")
func challenge(challenger_name: String) -> bool:
	if not game_active:
		return false
	if challenger_name != get_current_player():
		return false
	if last_bidder == "":
		return false # No bid to challenge

	challenge_made.emit(challenger_name, last_bidder)

	# Count actual dice matching the bid
	var actual_count: int = _count_matching_dice(current_bid.face)
	var bid_was_true: bool = actual_count >= current_bid.quantity

	# Determine loser
	var loser: String
	if bid_was_true:
		loser = challenger_name # Bid was true, challenger loses
	else:
		loser = last_bidder # Bid was false, bidder loses

	challenge_resolved.emit(bid_was_true, loser, actual_count)

	# Loser loses one die
	_remove_die_from_player(loser)

	# Check for elimination
	if player_dice[loser].size() == 0:
		player_eliminated.emit(loser)
		players.erase(loser)

		# Check for game end
		if players.size() == 1:
			game_active = false
			game_ended.emit(players[0])
			return true

	# Loser starts next round
	current_player_index = players.find(loser)
	if current_player_index == -1:
		current_player_index = 0 # Loser was eliminated, next player starts

	_start_new_round()
	return true

## Count dice matching a face value (including wilds if enabled)
func _count_matching_dice(face: int) -> int:
	var count := 0
	for player in players:
		for die in player_dice[player]:
			if die == face:
				count += 1
			elif wilds_enabled and die == 1 and face != 1:
				count += 1 # 1s are wild (unless bidding on 1s)
	return count

## Remove one die from a player
func _remove_die_from_player(player_name: String) -> void:
	if player_dice[player_name].size() > 0:
		player_dice[player_name].pop_back()
		dice_lost.emit(player_name, player_dice[player_name].size())

## Advance to next player's turn
func _advance_turn() -> void:
	current_player_index = (current_player_index + 1) % players.size()

## Get a player's dice (for UI - only show to that player)
func get_player_dice(player_name: String) -> Array[int]:
	if player_dice.has(player_name):
		return player_dice[player_name]
	return []

## Get dice count for a player (public info)
func get_player_dice_count(player_name: String) -> int:
	if player_dice.has(player_name):
		return player_dice[player_name].size()
	return 0

## Get current bid info
func get_current_bid() -> Dictionary:
	return current_bid.duplicate()

## Check if there's an active bid that can be challenged
func can_challenge() -> bool:
	return game_active and last_bidder != "" and last_bidder != get_current_player()

## Calculate probability of a bid being true (for Wits skill hint)
func calculate_bid_probability(quantity: int, face: int) -> float:
	var total_dice := _count_all_dice()
	var own_dice: Array[int] = get_player_dice(get_current_player())
	var own_matching := 0

	for die in own_dice:
		if die == face:
			own_matching += 1
		elif wilds_enabled and die == 1 and face != 1:
			own_matching += 1

	var unknown_dice := total_dice - own_dice.size()
	var needed := quantity - own_matching

	if needed <= 0:
		return 1.0 # Already have enough
	if needed > unknown_dice:
		return 0.0 # Impossible

	# Rough probability: each unknown die has ~1/3 chance (1/6 for face + 1/6 for wild)
	var prob_per_die := 1.0 / 6.0
	if wilds_enabled and face != 1:
		prob_per_die = 2.0 / 6.0 # Face OR 1

	# Binomial probability approximation (simplified)
	var expected := unknown_dice * prob_per_die
	if needed <= expected:
		return clampf(0.5 + (expected - needed) * 0.15, 0.1, 0.9)
	else:
		return clampf(0.5 - (needed - expected) * 0.15, 0.1, 0.9)

class_name LiarsDiceAI extends RefCounted
## AI opponent for Liar's Dice with different personality types

enum Personality {
	CAUTIOUS, # Conservative bids, rarely bluffs, challenges quickly
	AGGRESSIVE, # Pushes bids high, bluffs often, reluctant to challenge
	BALANCED, # Probability-based decisions
	RECKLESS # Unpredictable, frequent bluffs and challenges
}

var personality: Personality
var game: Node # LiarsDice instance
var player_name: String
var _rng := RandomNumberGenerator.new()

func _init(p_personality: Personality, p_game: Node, p_name: String) -> void:
	personality = p_personality
	game = p_game
	player_name = p_name
	_rng.randomize()

## Decide what action to take (returns a Dictionary with action info)
## Returns: {"action": "bid", "quantity": N, "face": N} or {"action": "challenge"}
func decide_action() -> Dictionary:
	var current_bid: Dictionary = game.get_current_bid()
	var my_dice: Array[int] = game.get_player_dice(player_name)
	var can_challenge: bool = game.can_challenge()

	# First bid of round - always bid
	if current_bid.quantity == 0:
		return _make_opening_bid(my_dice)

	# Decide whether to challenge or raise
	var should_challenge := _should_challenge(current_bid, my_dice)

	if should_challenge and can_challenge:
		return {"action": "challenge"}
	else:
		return _make_raised_bid(current_bid, my_dice)

## Make an opening bid based on personality
func _make_opening_bid(my_dice: Array[int]) -> Dictionary:
	# Count what we have
	var face_counts := _count_faces(my_dice)
	var best_face := _get_most_common_face(face_counts)
	var best_count: int = face_counts.get(best_face, 0)

	var quantity: int
	var face: int

	match personality:
		Personality.CAUTIOUS:
			# Bid exactly what we have
			quantity = best_count
			face = best_face
		Personality.AGGRESSIVE:
			# Bid higher than what we have
			quantity = best_count + _rng.randi_range(1, 2)
			face = best_face
		Personality.BALANCED:
			# Bid slightly optimistic
			quantity = best_count + (1 if _rng.randf() > 0.5 else 0)
			face = best_face
		Personality.RECKLESS:
			# Random bid
			quantity = _rng.randi_range(1, my_dice.size() + 2)
			face = _rng.randi_range(2, 6) # Avoid 1s (disables wilds)

	# Ensure valid
	quantity = maxi(1, quantity)
	face = clampi(face, 2, 6)

	return {"action": "bid", "quantity": quantity, "face": face}

## Make a raised bid
func _make_raised_bid(current_bid: Dictionary, my_dice: Array[int]) -> Dictionary:
	var face_counts := _count_faces(my_dice)
	var current_qty: int = current_bid.quantity
	var current_face: int = current_bid.face

	# Count how many we have of the current face (including wilds)
	var my_matching: int = face_counts.get(current_face, 0)
	if current_face != 1:
		my_matching += face_counts.get(1, 0) # Add wilds

	var new_qty: int
	var new_face: int

	match personality:
		Personality.CAUTIOUS:
			# Try to raise face first if we have support
			if current_face < 6 and face_counts.get(current_face + 1, 0) >= current_qty:
				new_qty = current_qty
				new_face = current_face + 1
			else:
				# Minimal quantity raise
				new_qty = current_qty + 1
				new_face = 2
		Personality.AGGRESSIVE:
			# Always raise quantity
			new_qty = current_qty + _rng.randi_range(1, 2)
			new_face = current_face if _rng.randf() > 0.5 else _get_most_common_face(face_counts)
		Personality.BALANCED:
			# Probability-informed bid
			if my_matching >= current_qty:
				# We can support this, raise slightly
				new_qty = current_qty + 1
				new_face = current_face
			else:
				# Switch to something we have
				var best_face := _get_most_common_face(face_counts)
				new_qty = current_qty + 1
				new_face = best_face if best_face > current_face else (current_face + 1 if current_face < 6 else current_face)
		Personality.RECKLESS:
			# Wild swings
			new_qty = current_qty + _rng.randi_range(0, 3)
			new_face = _rng.randi_range(current_face, 6)

	# Ensure valid raise
	if not game.is_valid_bid(new_qty, new_face):
		# Fallback: minimal valid raise
		if current_face < 6:
			new_qty = current_qty
			new_face = current_face + 1
		else:
			new_qty = current_qty + 1
			new_face = 2

	new_face = clampi(new_face, 2, 6)

	return {"action": "bid", "quantity": new_qty, "face": new_face}

## Decide whether to challenge the current bid
func _should_challenge(current_bid: Dictionary, my_dice: Array[int]) -> bool:
	var prob: float = game.calculate_bid_probability(current_bid.quantity, current_bid.face)

	# Count how many we can confirm
	var face_counts: Dictionary = _count_faces(my_dice)
	var confirmed: int = face_counts.get(current_bid.face, 0)
	if current_bid.face != 1:
		confirmed += face_counts.get(1, 0)

	var needed_from_others: int = current_bid.quantity - confirmed
	var total_other_dice := 0
	for player in game.players:
		if player != player_name:
			total_other_dice += game.get_player_dice_count(player)

	# Probability other dice provide what's needed
	var impossible: bool = needed_from_others > total_other_dice
	var very_unlikely: bool = needed_from_others > (total_other_dice * 0.6)

	match personality:
		Personality.CAUTIOUS:
			# Challenge if it seems unlikely
			return impossible or very_unlikely or prob < 0.35
		Personality.AGGRESSIVE:
			# Only challenge if obviously impossible
			return impossible or (prob < 0.15 and _rng.randf() > 0.5)
		Personality.BALANCED:
			# Challenge based on probability
			return prob < 0.30
		Personality.RECKLESS:
			# Random challenge
			return _rng.randf() > 0.6

	return false

## Count occurrences of each face in dice
func _count_faces(dice: Array[int]) -> Dictionary:
	var counts := {}
	for die in dice:
		counts[die] = counts.get(die, 0) + 1
	return counts

## Get the most common face (prefer higher faces as tiebreaker)
func _get_most_common_face(face_counts: Dictionary) -> int:
	var best_face := 2
	var best_count := 0
	for face in range(2, 7): # Start at 2 to avoid bidding on wilds
		var count: int = face_counts.get(face, 0)
		if count >= best_count: # >= so higher faces win ties
			best_count = count
			best_face = face
	return best_face

## Generate a "tell" hint based on personality (for Swagger skill)
func get_tell_hint(is_bluffing: bool) -> String:
	var tells_bluffing := [
		"They hesitate before speaking...",
		"Their eyes dart away briefly.",
		"They tap the table nervously.",
		"A slight tremor in their voice.",
		"They seem overly confident.",
	]
	var tells_honest := [
		"They meet your gaze steadily.",
		"They seem relaxed.",
		"Their voice is calm and even.",
		"They lean back confidently.",
		"A slight smile crosses their face.",
	]
	var tells_neutral := [
		"Their expression is unreadable.",
		"They stare at their cup.",
		"They wait patiently.",
	]

	# Personality affects how obvious tells are
	var show_true_tell: bool
	match personality:
		Personality.CAUTIOUS, Personality.BALANCED:
			show_true_tell = _rng.randf() > 0.3 # Usually shows true tell
		Personality.AGGRESSIVE:
			show_true_tell = _rng.randf() > 0.5 # 50/50
		Personality.RECKLESS:
			show_true_tell = _rng.randf() > 0.7 # Often misleading

	if show_true_tell:
		if is_bluffing:
			return tells_bluffing[_rng.randi() % tells_bluffing.size()]
		else:
			return tells_honest[_rng.randi() % tells_honest.size()]
	else:
		return tells_neutral[_rng.randi() % tells_neutral.size()]

extends Node2D

var round := 0

@export_range(0.0, 10.0, 0.01) var flip_duration := 1.0

var dice := ["copy", "d3", "d6", "fibonacci", "pi", "turncount"]

func _ready() -> void:
	start_game()

func start_game():
	start_round()

func start_round():
	GameState.is_player_turn = true
	GameState.turn_count = 0
	GameState.goal_turn_count = 6
	start_turn()

func distribute_dice():
	var available_dice = dice.duplicate()
	while not available_dice.is_empty():
		var picked = available_dice.pick_random()
		
		if available_dice.size() > dice.size() * 0.5:
			$LoverL.add_to_dice_inventory(picked)
		else:
			$LoverR.add_to_dice_inventory(picked)
		
		available_dice.erase(picked)

func start_turn():
	find_child("TurnCountLabel").text = str(GameState.turn_count, "/", GameState.goal_turn_count)
	GameState.turn_count += 1
	if not $LoverL.has_dice_left() and not $LoverR.has_dice_left():
		distribute_dice()
	if GameState.is_player_turn:
		pass
	else:
		$LoverL.evaluate_gamestate()

func is_even(a:int):
	return a % 2 == 0

func roll_dice(techId:String, toRight:bool):
	var dice : Dice = load(str("res://game/dice/", techId, "/", techId, ".tscn")).instantiate()
	var topL:Vector2
	var bottomR:Vector2
	if toRight:
		topL = find_child("BoundsLeft").get_child(0).global_position
		bottomR = find_child("BoundsLeft").get_child(1).global_position
	else:
		topL = find_child("BoundsRight").get_child(0).global_position
		bottomR = find_child("BoundsRight").get_child(1).global_position
	var startPos : Vector2 = lerp(topL, bottomR, randf())
	dice.global_position = startPos
	add_child(dice)
	dice.connect("rolled", spin_knife)
	dice.roll(toRight)
	GameState.dice_played_this_round.append(techId)

func use_item(techId:String):
	pass

func is_knife_pointing_right() -> bool:
	return $Knife.rotation == 0 # at player

func spin_knife(flip_count:int):
	var t = create_tween()
	var rolling_delay := 0.5
	t.set_parallel(true)
	var start_pointing_right = is_knife_pointing_right()
	if GameState.all_or_nothing:
		if is_even(flip_count):
			if not start_pointing_right:
				t.tween_property($Knife, "rotation", 0, flip_duration).set_delay(rolling_delay)
		else:
			if start_pointing_right:
				t.tween_property($Knife, "rotation", -PI, flip_duration).set_delay(rolling_delay)
	else:
		for i in flip_count:
			if start_pointing_right:
				if is_even(i):
					t.tween_property($Knife, "rotation", -PI, flip_duration).set_delay(rolling_delay)
				else:
					t.tween_property($Knife, "rotation", 0, flip_duration).set_delay(rolling_delay)
			else:
				if is_even(i):
					t.tween_property($Knife, "rotation", 0, flip_duration).set_delay(rolling_delay)
				else:
					t.tween_property($Knife, "rotation", -PI, flip_duration).set_delay(rolling_delay)
			rolling_delay += 2 * flip_duration
	t.tween_callback(post_spin_evaluation.bind(flip_count)).set_delay(rolling_delay)

func post_spin_evaluation(flip_count:int):
	printt(flip_count, sign($Knife.rotation))
	if not GameState.possession: # 
		GameState.is_player_turn = GameState.turn_count % 2 == 0
	else:
		GameState.is_player_turn = GameState.turn_count % 2 != 0
	# fuck I think I mixed up turns and rounds
	# 1 turn = 1 roll
	# 1 round = 6 turns
	# 1 game = 3 rounds
	
	if GameState.turn_count >= GameState.goal_turn_count:
		stab()
	else:
		start_turn()

func stab():
	var goalPos :Vector2= $Knife.position
	if is_knife_pointing_right():
		goalPos.x += 350
	else:
		goalPos.x -= 350
	var t = create_tween()
	t.tween_property($Knife, "position", goalPos, 1.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
	t.finished.connect(start_round)

func _on_delete_dice_button_pressed() -> void:
	for c in get_children():
		if c is Dice:
			c.queue_free()

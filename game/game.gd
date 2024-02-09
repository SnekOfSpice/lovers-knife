extends Control

var round := 0

@export_range(0.0, 10.0, 0.01) var flip_duration := 1.0

var dice := ["copy", "d3", "d6", "fibonacci", "pi", "turncount"]
var items := ["all_or_nothing", "grasp_of_fate", "escape_velocity", "possession", "candle"]

func _ready() -> void:
	Data.listen(self, "gamestate.turn_count")
	Data.listen(self, "gamestate.goal_turn_count")
	Data.listen(self, "items.possession", true)
	Data.listen(self, "items.all_or_nothing", true)
	Data.listen(self, "items.grasp_of_fate", true)
	Data.listen(self, "items.escape_velocity", true)
	Data.listen(self, "damage_right")
	Data.listen(self, "damage_left")
	
	start_game()
	$EndTexture.visible = false

func restart():
	start_game()
	$EndTexture.visible = false

func property_change(property: String, new_value, old_value):
	printt(property, new_value, old_value)
	match property:
		"gamestate.turn_count":
			update_label()
		"gamestate.goal_turn_count":
			update_label()
		"items.possession":
			update_label()
			find_child("StatusContainer").find_child("Possession").visible = new_value
		"items.all_or_nothing":
			find_child("StatusContainer").find_child("AllOrNothing").visible = new_value
		"items.escape_velocity":
			find_child("StatusContainer").find_child("EscapeVelocity").visible = new_value
		"items.grasp_of_fate":
			find_child("StatusContainer").find_child("GraspOfFate").visible = new_value
		"damage_right":
			update_label()
			if new_value >= 2:
				end_game()
		"damage_left":
			update_label()
			if new_value >= 2:
				end_game()

func get_current_lover():
	if Data.of("gamestate.turn_count") % 2 == 0:
		if Data.of("items.possessed"):
			return $LoverR
		else:
			return $LoverL
	else:
		if Data.of("items.possessed"):
			return $LoverL
		else:
			return $LoverR

func update_label():
	find_child("TurnCountLabel").text = str(Data.of("gamestate.turn_count"), "/", Data.of("gamestate.goal_turn_count"))
	find_child("TurnCountLabel").text += "\n"
	find_child("TurnCountLabel").text += "Player on Evens" if Data.of("items.possession") else "Player on Odds"
	find_child("TurnCountLabel").text += "\n"
	var damage_string := ""
	for i in Data.of("damage_left"):
		damage_string += "X"
	damage_string += "|"
	for i in Data.of("damage_right"):
		damage_string += "X"
	find_child("TurnCountLabel").text += damage_string

func end_game():
	$EndTexture.visible = true
	if Data.of("damage_left") >= 2:
		$EndTexture.texture = load("res://game/visuals/end_kill.png")
	elif Data.of("damage_right") >= 2:
		$EndTexture.texture = load("res://game/visuals/end_die.png")

func prepare_next_round():
	Data.change_by_int("gamestate.round_count", 1)
	GameState.reset_between_rounds()
	$Knife.position = $KnifeCenterPosition.position
	$LoverL.erase_all_items()
	$LoverR.erase_all_items()

func start_game():
	GameState.reset_between_rounds()
	# auto start in first round, in subsequent rounds the transition will call this instead
	prepare_next_round()
	start_round()
		

func start_round():
	Data.apply("gamestate.turn_count", 0)
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
	Data.change_by_int("gamestate.turn_count", 1)
	if not $LoverL.has_dice_left() and not $LoverR.has_dice_left():
		distribute_dice()
	
	if not get_current_lover().has_dice():
		refill_dice(get_current_lover())
	
	distribute_items($LoverL, 2)
	distribute_items($LoverR, 2)
	#if Data.of("round_count") == 1:
		#distribute_items($LoverL, 2)
		#distribute_items($LoverR, 2)
	#elif Data.of("round_count") >= 2:
		#distribute_items($LoverL, 4)
		#distribute_items($LoverR, 4)
	
	if Data.of("gamestate.is_player_turn"):
		pass
	else:
		$LoverL.evaluate_gamestate()

func refill_dice(lover:Lover):
	var unheld = get_unheld_dice_ids()
	for i in 3:
		var new_dice = unheld.pick_random()
		unheld.erase(new_dice)
		lover.add_to_dice_inventory(new_dice)

func get_unheld_dice_ids() -> Array:
	var result := []
	
	var held_dice := []
	held_dice.append_array($LoverL.get_held_dice_ids())
	held_dice.append_array($LoverR.get_held_dice_ids())
	
	for die in dice:
		if not die in held_dice:
			result.append(die)
	
	return result

func distribute_items(lover: Lover, item_count):
	for i in item_count:
		if lover.is_item_inventory_full():
			break
		lover.add_to_item_inventory(items.pick_random())

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
	prints("using ", techId)
	prints("xsing ", "possession", techId == "possession")
	match techId:
		"possession":
			Data.apply("items.possession", not Data.of("items.possession", false))
		"all_or_nothing":
			Data.apply("items.all_or_nothing", true)
		"escape_velocity":
			pass
		"candle":
			Data.change_by_int("gamestate.goal_turn_count", 1)
		"grasp_of_fate":
			Data.apply("items.grasp_of_fate", true)

func is_knife_pointing_right() -> bool:
	return $Knife.rotation == 0 # at player

func spin_knife(flip_count:int):
	var t = create_tween()
	var rolling_delay := 0.5
	t.set_parallel(true)
	var start_pointing_right = is_knife_pointing_right()
	if Data.of("items.all_or_nothing"):
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

func reset_after_spin():
	Data.apply("items.grasp_of_fate", false)
	Data.apply("items.all_or_nothing", false)

func post_spin_evaluation(flip_count:int):
	if not Data.of("items.possession"):
		Data.apply("gamestate.is_player_turn", Data.of("gamestate.turn_count") % 2 == 0)
	else:
		Data.apply("gamestate.is_player_turn", Data.of("gamestate.turn_count") % 2 != 0)
	# fuck I think I mixed up turns and rounds
	# 1 turn = 1 roll
	# 1 round = 6 turns
	# 1 game = 3 rounds
	
	reset_after_spin()
	
	if Data.of("gamestate.turn_count") >= Data.of("gamestate.goal_turn_count"):
		stab()
	else:
		start_turn()

func stab():
	var goalPos :Vector2= $Knife.position
	var t = create_tween()
	if is_knife_pointing_right():
		goalPos.x += 350
		t.finished.connect(Data.change_by_int.bind("damage_right", 1))
	else:
		goalPos.x -= 350
		t.finished.connect(Data.change_by_int.bind("damage_left", 1))
	
	t.tween_property($Knife, "position", goalPos, 1.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
	t.finished.connect($RoundTransition.start_transition)
	

func _on_delete_dice_button_pressed() -> void:
	for c in get_children():
		if c is Dice:
			c.queue_free()


func _on_round_transition_end_reached() -> void:
	start_round()


func _on_round_transition_middle_reached() -> void:
	prepare_next_round()

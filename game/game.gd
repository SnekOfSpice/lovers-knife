extends Control
class_name Game

var round := 0

@export_range(0.0, 10.0, 0.01) var flip_duration := 1.0

var dice := ["copy", "d3", "d6", "fibonacci", "pi", "turncount"]
var items := ["all_or_nothing", "grasp_of_fate", "escape_velocity", "possession", "candle"]

var knife_rotation_tween:Tween

func _ready() -> void:
	GameState.game = self
	Data.listen(self, "gamestate.turn_count")
	Data.listen(self, "gamestate.goal_turn_count")
	Data.listen(self, "items.possession", true)
	Data.listen(self, "items.all_or_nothing", true)
	Data.listen(self, "items.grasp_of_fate", true)
	Data.listen(self, "items.escape_velocity", true)
	Data.listen(self, "damage_right")
	Data.listen(self, "damage_left")
	Data.listen(self, "gamestate.can_input", true)
	Data.listen(self, "knife.rotations", true)
	
	start_game()
	$EndTexture.visible = false
	
	

func restart():
	$EndTexture.visible = false
	$LoverL.erase_all_items()
	$LoverR.erase_all_items()
	$LoverL.erase_all_dice()
	$LoverR.erase_all_dice()
	start_game()

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
			update_label()
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
		"knife.rotations":
			update_label()
			if Data.of("items.escape_velocity") and new_value >= GameState.EscapeVelocityGoal:
				if knife_rotation_tween:
					knife_rotation_tween.stop()
				#if Data.of("gamestate.is_player_turn"):
				$Knife.connect("finish_rotation", stab)
				$Knife.set_pointing(Data.of("gamestate.escape_velocity_points_at_player"))
				#else:
					#$Knife.connect("finish_rotation", stab)
					#$Knife.set_pointing(true)
				#print("escape")
		"gamestate.can_input":
			pass

func get_current_lover():
	if Data.of("gamestate.is_player_turn"):
		return $LoverR
	else:
		return $LoverL
	#if Data.of("gamestate.turn_count") % 2 == 0:
		#if Data.of("items.possessed"):
			#return $LoverR
		#else:
			#return $LoverL
	#else:
		#if Data.of("items.possessed"):
			#return $LoverL
		#else:
			#return $LoverR

func update_label():
	var label :Label= find_child("TurnCountLabel")
	label.text = str(Data.of("gamestate.turn_count"), "/", Data.of("gamestate.goal_turn_count"))
	label.text += "\n"
	label.text += "Odds | Evens" if Data.of("items.possession") else "Evens | Odds"
	label.text += "\n"
	if Data.of("gamestate.round_count") > 0:
		label.text += str(Data.of("knife.rotations"))
	if Data.of("items.escape_velocity"):
		var direction:String
		if Data.of("gamestate.escape_velocity_points_at_player"):
			direction = ">>"
		else:
			direction = "<<"
		label.text += str(" (", "Terminal at ", GameState.EscapeVelocityGoal, ")")
		label.text += str("\n", direction)
	label.text += "\n"
	var damage_string := ""
	for i in Data.of("damage_left"):
		damage_string += "X"
	if Data.of("damage_left") > 0 or Data.of("damage_right") > 0:
		damage_string += "|"
	for i in Data.of("damage_right"):
		damage_string += "X"
	label.text += damage_string

func end_game():
	$EndTexture.visible = true
	if Data.of("damage_left") >= 2:
		$EndTexture.texture = load("res://game/visuals/end_kill.png")
	elif Data.of("damage_right") >= 2:
		$EndTexture.texture = load("res://game/visuals/end_die.png")

func prepare_next_round():
	Data.apply("gamestate.turn_count", 0)
	Data.apply("knife.rotations", 0)
	GameState.reset_between_rounds()
	$Knife.position = $KnifeCenterPosition.position
	$LoverL.erase_all_items()
	$LoverL.erase_all_dice()
	$LoverR.erase_all_items()
	$LoverR.erase_all_dice()
	update_label()

func start_game():
	Data.apply("damage_left", 0)
	Data.apply("damage_right", 0)
	Data.apply("gamestate.round_count", 0)
	GameState.reset_between_rounds()
	# auto start in first round, in subsequent rounds the transition will call this instead
	prepare_next_round()
	start_round()
		

func start_round():
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
	if $LoverL.is_dice_inventory_empty() and $LoverR.is_dice_inventory_empty():
		distribute_dice()
	
	if get_current_lover().is_dice_inventory_empty():
		refill_dice(get_current_lover())
	
	#distribute_items($LoverL, 2)
	#distribute_items($LoverR, 2)
	if Data.of("gamestate.round_count") == 1:
		distribute_items($LoverL, 1)
		distribute_items($LoverR, 1)
	elif Data.of("gamestate.round_count") >= 2:
		distribute_items($LoverL, 3)
		distribute_items($LoverR, 3)
	
	if Data.of("gamestate.is_player_turn"):
		Data.apply("gamestate.can_input", true)
	else:
		if Data.of("game.singleplayer"):
			await get_tree().create_timer(2.0).timeout
			$LoverL.do_stuff()
		else:
			Data.apply("gamestate.can_input", true)

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

func roll_dice(tech_id:String, fromRight:bool):
	var dice : Dice = load(str("res://game/dice/", tech_id, "/", tech_id, ".tscn")).instantiate()
	var topL:Vector2
	var bottomR:Vector2
	if not fromRight:
		topL = find_child("BoundsLeft").get_child(0).global_position
		bottomR = find_child("BoundsLeft").get_child(1).global_position
	else:
		topL = find_child("BoundsRight").get_child(0).global_position
		bottomR = find_child("BoundsRight").get_child(1).global_position
	var startPos : Vector2 = lerp(topL, bottomR, randf())
	dice.global_position = startPos
	add_child(dice)
	dice.connect("rolled", spin_knife)
	dice.roll(fromRight)
	GameState.dice_played_this_round.append(tech_id)

func use_item(tech_id:String):
	match tech_id:
		"possession":
			Data.apply("items.possession", not Data.of("items.possession", false))
		"all_or_nothing":
			Data.apply("items.all_or_nothing", true)
		"escape_velocity":
			Data.apply("gamestate.escape_velocity_points_at_player", not Data.of("gamestate.is_player_turn"))
			Data.apply("items.escape_velocity", true)
		"candle":
			Data.change_by_int("gamestate.goal_turn_count", 1)
		"grasp_of_fate":
			Data.apply("items.grasp_of_fate", true)

func is_knife_pointing_right() -> bool:
	return $Knife.is_pointing_right()

func set_info_text(text:String):
	$InfoTextLabel.text = str("[center]", text, "[/center]")

func clear_info_text():
	set_info_text("")
	$DiceInfoL.text = ""
	$DiceInfoR.text = ""

func set_dice_info_texts(tech_id:String):
	$InfoTextLabel.text = str("[center]", Data.dice_descriptions.get(tech_id, ""), "[/center]")
	
	var eval = GameState.get_evaluated_faces(tech_id)
	var text_l := ""
	var text_r := ""
	for e in eval:
		if (is_knife_pointing_right() and e % 2 == 0) or (not is_knife_pointing_right() and e % 2 == 1):
			text_r += str(" [", e, "] ")
		elif (is_knife_pointing_right() and e % 2 == 1) or (not is_knife_pointing_right() and e % 2 == 0):
			text_l += str(" [", e, "] ")
	$DiceInfoL.text = str("[center]", text_l, "[/center]")
	$DiceInfoR.text = str("[center]", text_r, "[/center]")

func spin_knife(flip_count:int):
	var call_escape_velocity:=false
	if Data.of("items.escape_velocity"):
		if Data.of("knife.rotations") + flip_count >= GameState.EscapeVelocityGoal:
			flip_count = GameState.EscapeVelocityGoal - Data.of("knife.rotations")
			call_escape_velocity = true
			if flip_count <= 0:
				if Data.of("gamestate.escape_velocity_points_at_player") and is_knife_pointing_right():
					stab()
					return
				elif not Data.of("gamestate.escape_velocity_points_at_player") and not is_knife_pointing_right():
					stab()
					return
				$Knife.connect("finish_rotation", stab)
				$Knife.set_pointing(Data.of("gamestate.escape_velocity_points_at_player"))
				return
	
	knife_rotation_tween = create_tween()
	var rolling_delay := 0.5 # rolling float to offset flips beyond the first
	knife_rotation_tween.set_parallel(true)
	var start_pointing_right = is_knife_pointing_right()
	if Data.of("items.all_or_nothing"):
		if is_even(flip_count):
			if not start_pointing_right:
				knife_rotation_tween.tween_callback($Knife.set_pointing.bind(true)).set_delay(rolling_delay)
				#t.tween_property($Knife, "rotation", 0, flip_duration).set_delay(rolling_delay)
		else:
			if start_pointing_right:
				knife_rotation_tween.tween_callback($Knife.set_pointing.bind(false)).set_delay(rolling_delay)
				#t.tween_property($Knife, "rotation", -PI, flip_duration).set_delay(rolling_delay)
	else:
		for i in flip_count:
			if start_pointing_right:
				if is_even(i):
					knife_rotation_tween.tween_callback($Knife.set_pointing.bind(false)).set_delay(rolling_delay)
					#t.tween_property($Knife, "rotation", -PI, flip_duration).set_delay(rolling_delay)
				else:
					knife_rotation_tween.tween_callback($Knife.set_pointing.bind(true)).set_delay(rolling_delay)
					#t.tween_property($Knife, "rotation", 0, flip_duration).set_delay(rolling_delay)
			else:
				if is_even(i):
					knife_rotation_tween.tween_callback($Knife.set_pointing.bind(true)).set_delay(rolling_delay)
					#t.tween_property($Knife, "rotation", 0, flip_duration).set_delay(rolling_delay)
				else:
					knife_rotation_tween.tween_callback($Knife.set_pointing.bind(false)).set_delay(rolling_delay)
					#t.tween_property($Knife, "rotation", -PI, flip_duration).set_delay(rolling_delay)
			rolling_delay += 2 * $Knife.get_flip_duration_sec()
	knife_rotation_tween.tween_callback(post_spin_evaluation.bind(flip_count)).set_delay(rolling_delay)

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
	if $Knife.is_connected("finish_rotation", stab):
		$Knife.disconnect("finish_rotation", stab)
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
	Data.change_by_int("gamestate.round_count", 1)
	prepare_next_round()


func _on_main_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://systems/main_menu.tscn")

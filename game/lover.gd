extends Node2D
class_name Lover

@export var is_player:bool

signal start_rolling_dice(tech_id:String, on_right:bool)
signal start_use_item(tech_id:String)

func get_held_dice() -> Array:
	return find_child("DiceContainer").get_children()

func get_held_items() -> Array:
	return find_child("ItemContainer").get_children()

func get_held_dice_ids() -> Array:
	var held := get_held_dice()
	var result := []
	for h in held:
		result.append(h.tech_id)
	return result

func get_held_item_ids() -> Array:
	var held := get_held_items()
	var result := []
	for h in held:
		result.append(h.tech_id)
	return result

func has_item(tech_id:String) -> bool:
	return get_held_item_ids().has(tech_id)

func erase_all_items():
	for c in find_child("ItemContainer").get_children():
		c.queue_free()

func erase_all_dice():
	for c in find_child("DiceContainer").get_children():
		c.queue_free()

func _ready() -> void:
	if is_player:
		find_child("DiceContainer").alignment = BoxContainer.ALIGNMENT_END

func roll_dice(action_button:ActionButton):
	var tech_id = action_button.tech_id
	action_button.queue_free()
	emit_signal("start_rolling_dice", tech_id, is_player)

func has_dice(tech_id:String) -> bool:
	return get_held_dice_ids().has(tech_id)

func add_to_dice_inventory(tech_id:String):
	var button = preload("res://game/action_button.tscn").instantiate()
	button.set_id(tech_id, button.Actions.Dice)
	button.connect("pressed", roll_dice.bind(button))
	button.connect("dice_mouse_entered", GameState.game.set_dice_info_texts)
	button.connect("dice_mouse_exited", GameState.game.clear_info_text)
	button.owned_by_player = is_player
	find_child("DiceContainer").add_child(button)

func is_item_inventory_full() -> bool:
	return get_held_items().size() >= 8

func add_to_item_inventory(tech_id:String):
	var button = preload("res://game/action_button.tscn").instantiate()
	button.set_id(tech_id, button.Actions.Item)
	button.connect("pressed", use_item.bind(button))
	button.connect("set_info_text", GameState.game.set_info_text)
	button.owned_by_player = is_player
	find_child("ItemContainer").add_child(button)

func use_item(action_button:Node):
	var tech_id = action_button.tech_id
	action_button.queue_free()
	emit_signal("start_use_item", tech_id)

func use_item_by_id(tech_id:String):
	var button_to_use
	for button in get_held_items():
		if button.tech_id == tech_id:
			button_to_use = button
			break
	if not button_to_use:
		return
	use_item(button_to_use)

func use_dice_by_id(tech_id:String):
	var button_to_use
	for button in get_held_dice():
		if button.tech_id == tech_id:
			button_to_use = button
			break
	if not button_to_use:
		return
	roll_dice(button_to_use)

func is_dice_inventory_empty() -> bool:
	return get_held_dice().size() == 0

func chances_to_reach_escape_velocity() -> Dictionary:
	var rotation_count_to_escape_velocity = GameState.EscapeVelocityGoal - Data.of("knife.rotations")
	var chances := {}
	
	for dice_id in get_held_dice_ids():
		var faces = GameState.get_evaluated_faces(dice_id)
		var chance := 0.0
		for face in faces:
			if face >= rotation_count_to_escape_velocity:
				chance += 1.0
		chance /= faces.size()
		chances[dice_id] = chance
	
	return chances

func chances_for_even() -> Dictionary:
	var chances := {}
	
	for dice_id in get_held_dice_ids():
		var faces = GameState.get_evaluated_faces(dice_id)
		var chance := 0.0
		for face in faces:
			if face % 2 == 0:
				chance += 1.0
		chance /= faces.size()
		chances[dice_id] = chance
	
	return chances

## returns an action plan. the last item will be a dice, all others will be items
func get_action_plan_from_gamestate() -> Array:
	var action_plan := []
	# TODO: replace with actual logic
	
	var aim_for_even : bool = GameState.game.is_knife_pointing_right()
	
	# if escape velocity in favor, find the one dice with the highest expected value
	if Data.of("gamestate.escape_velocity_points_at_player"):
		var highest_ev := 0
		var best_dice
		for dice in get_held_dice_ids():
			var ev = GameState.get_expected_value(dice)
			if ev > highest_ev:
				best_dice = dice
		action_plan.append(best_dice)
		return action_plan
	
	if aim_for_even and has_item("grasp_of_fate"):
		action_plan.append("grasp_of_fate")
		action_plan.append(get_held_dice_ids().pick_random())
		return action_plan
	
	if has_item("escape_velocity"):
		var chances = chances_to_reach_escape_velocity()
		var likely_dice:String
		var best_chance := 0.0
		for dice in chances:
			if chances.get(dice) >= 0.5 and best_chance < chances.get(dice):
				likely_dice = dice
		if likely_dice:
			action_plan.append("escape_velocity")
			action_plan.append(likely_dice)
			return action_plan
		# iterate over all die, see if any of them have >50% chance to reach it
		# pick the one with the highest chance
	
	
	
	# if has turncount dice and is possessed rn, try to unpossess depending on uhhh
	if has_item("possession"):
		if randf() < 0.6:
			action_plan.append("possession")
	
	# if candle in inventory, and all held dice are <50% to result in desired outcome, use candle
	# aka: if you have one dice that is >50% likely to have the desired directional outcome, don't use a candle
	if has_item("candle"):
		var use_candle := true
		var chances = chances_for_even()
		if aim_for_even:
			for dice in chances:
				if chances.get(dice) > 0.5:
					use_candle = false
					break
		else:
			for dice in chances:
				if chances.get(dice) < 0.5:
					use_candle = false
					break
		if use_candle:
			action_plan.append("candle")
	
	if has_item("all_or_nothing") and not action_plan.has("candle"):
		var chances = chances_for_even()
		var best_chance := 0.0
		var best_dice:String
		for dice in chances:
			if chances.get(dice) < 0.5:
				best_dice = dice
				if chances.get(dice) < best_chance:
					best_chance = chances.get(dice)
		if best_dice:
			action_plan.append("all_or_nothing")
			action_plan.append(best_dice)
			return action_plan
	
	action_plan.append(get_held_dice_ids().pick_random())
	
	var chances = chances_for_even()
	if aim_for_even:
		for dice in chances:
			if chances.get(dice) > 0.5:
				action_plan.append(dice)
				break
	else:
		for dice in chances:
			if chances.get(dice) < 0.5:
				action_plan.append(dice)
				break
	return action_plan

func do_stuff():
	var i := 0
	var action_plan = get_action_plan_from_gamestate()
	while i < action_plan.size() - 1:
		await get_tree().create_timer(0.5).timeout
		use_item_by_id(action_plan[i])
		i += 1
	await get_tree().create_timer(0.5).timeout
	use_dice_by_id(action_plan.back())

func get_best_dice_id(for_even:bool):
	pass

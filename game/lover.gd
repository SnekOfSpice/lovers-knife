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

func show_action_label(action_button:ActionButton):
	if action_button.action_type == ActionButton.Actions.Dice:
		var description := ""
		
		var eval = GameState.get_evaluated_faces(action_button.tech_id)
		for e in eval:
			description += str(" [", e, "] ")
		
		description += str("\n", Data.dice_descriptions.get(action_button.tech_id, ""))
		
		find_child("ActionInfoLabel").text = description
	elif action_button.action_type == ActionButton.Actions.Item:
		find_child("ActionInfoLabel").text = Data.item_descriptions.get(action_button.tech_id, "")

func hide_action_label():
	find_child("ActionInfoLabel").text = ""

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
	button.connect("mouse_entered", show_action_label.bind(button))
	button.connect("mouse_exited", hide_action_label)
	button.connect("pressed", hide_action_label)
	button.connect("set_info_text", GameState.game.set_info_text)
	button.owned_by_player = is_player
	find_child("DiceContainer").add_child(button)

func is_item_inventory_full() -> bool:
	return get_held_items().size() >= 8

func add_to_item_inventory(tech_id:String):
	var button = preload("res://game/action_button.tscn").instantiate()
	button.set_id(tech_id, button.Actions.Item)
	button.connect("pressed", use_item.bind(button))
	button.connect("mouse_entered", show_action_label.bind(button))
	button.connect("mouse_exited", hide_action_label)
	button.connect("pressed", hide_action_label)
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

## returns an action plan. the last item will be a dice, all others will be items
func get_action_plan_from_gamestate() -> Array:
	var action_plan := []
	# TODO: replace with actual logic
	
	var aim_for_even : bool = GameState.game.is_knife_pointing_right()
	
	if aim_for_even and has_item("grasp_of_fate"):
		action_plan.append("grasp_of_fate")
		action_plan.append(get_held_dice_ids().pick_random())
		return action_plan
	
	action_plan.append(get_held_dice_ids().pick_random())
	
	# if has turncount dice and is possessed rn, try to unpossess depending on uhhh
	
	# if candle in inventory, and the next dice is <50% to result in desired outcome, use candle
	
	# chance to reach escape velocity
	
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

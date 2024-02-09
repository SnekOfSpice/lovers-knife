extends Node2D
class_name Lover

@export var is_player:bool

signal start_rolling_dice(techId:String, on_right:bool)
signal start_use_item(techId:String)

func get_held_dice() -> Array:
	return find_child("DiceContainer").get_children()

func get_held_items() -> Array:
	return find_child("ItemContainer").get_children()

func get_held_dice_ids() -> Array:
	var held := get_held_dice()
	var result := []
	for h in held:
		result.append(h.techId)
	return result

func erase_all_items():
	for c in find_child("ItemContainer").get_children():
		c.queue_free()

func _ready() -> void:
	if is_player:
		find_child("DiceContainer").alignment = BoxContainer.ALIGNMENT_END

func add_to_dice_inventory(techId:String):
	var button = preload("res://game/action_button.tscn").instantiate()
	button.texture_normal = load(str("res://game/dice/",techId,"/",techId,".png"))
	button.action_type = button.Actions.Dice
	button.connect("pressed", roll_dice.bind(button))
	button.connect("mouse_entered", show_action_label.bind(button))
	button.connect("mouse_exited", hide_action_label)
	button.connect("pressed", hide_action_label)
	button.techId = techId
	find_child("DiceContainer").add_child(button)
	button.disabled = not is_player

func show_action_label(action_button:ActionButton):
	if action_button.action_type == ActionButton.Actions.Dice:
		var description := ""
		
		var eval = GameState.get_evaluated_faces(Data.faces.get(action_button.techId, []))
		for e in eval:
			description += str(" [", e, "] ")
		
		description += str("\n", Data.dice_descriptions.get(action_button.techId, ""))
		
		find_child("ActionInfoLabel").text = description
	elif action_button.action_type == ActionButton.Actions.Item:
		find_child("ActionInfoLabel").text = Data.item_descriptions.get(action_button.techId, "")

func hide_action_label():
	find_child("ActionInfoLabel").text = ""

func roll_dice(action_button:ActionButton):
	var techId = action_button.techId
	action_button.queue_free()
	emit_signal("start_rolling_dice", techId, is_player)

func has_dice() -> bool:
	return get_held_dice().size() > 0

func is_item_inventory_full() -> bool:
	return get_held_items().size() >= 8

func add_to_item_inventory(techId:String):
	var button = preload("res://game/action_button.tscn").instantiate()
	button.texture_normal = load(str("res://game/items/",techId,"/",techId,".png"))
	button.action_type = button.Actions.Item
	button.connect("pressed", use_item.bind(button))
	button.connect("mouse_entered", show_action_label.bind(button))
	button.connect("mouse_exited", hide_action_label)
	button.connect("pressed", hide_action_label)
	button.techId = techId
	find_child("ItemContainer").add_child(button)
	button.disabled = not is_player

func use_item(action_button:Node):
	var techId = action_button.techId
	action_button.queue_free()
	emit_signal("start_use_item", techId)

func has_dice_left() -> bool:
	return get_held_dice().size() > 0

func evaluate_gamestate():
	# TODO: replace with actual logic
	roll_dice(get_held_dice().pick_random())
	
	# if has turncount dice and is possessed rn, try to unpossess depending on uhhh

extends Node2D

var round := 0
var turn := 0
var is_player_turn := true

var dice := ["copy", "d3", "d6", "fibonacci", "pi", "turncount"]

var all_or_nothing := false

func _ready() -> void:
	start_game()

func start_game():
	start_round()

func start_round():
	is_player_turn = true
	start_turn()

func start_turn():
	turn += 1
	# distribute dice
	var available_dice = dice.duplicate()
	while not available_dice.is_empty():
		var picked = available_dice.pick_random()
		
		if available_dice.size() > dice.size() * 0.5:
			$LoverL.add_to_dice_inventory(picked)
		else:
			$LoverR.add_to_dice_inventory(picked)
		
		available_dice.erase(picked)

func is_even(a:int):
	return a % 2 == 0

func roll_dice(techId:String, toRight:bool):
	var dice : Dice = load(str("res://game/dice/", techId, "/", techId.capitalize().replace(" ", ""), ".tscn")).instantiate()
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

func use_item(techId:String):
	pass

func spin_knife(flip_count:int):
	var t = create_tween()
	var rolling_delay := 0.0
	t.set_parallel(true)
	var startPointingRight=$Knife.rotation == 0
	for i in flip_count:
		if startPointingRight:
			if is_even(i):
				t.tween_property($Knife, "rotation", -PI, 1).set_delay(rolling_delay)
			else:
				t.tween_property($Knife, "rotation", 0, 1).set_delay(rolling_delay)
		else:
			if is_even(i):
				t.tween_property($Knife, "rotation", 0, 1).set_delay(rolling_delay)
			else:
				t.tween_property($Knife, "rotation", -PI, 1).set_delay(rolling_delay)
		rolling_delay += 2.0
	t.tween_callback(post_spin_evaluation.bind(flip_count)).set_delay(rolling_delay)

func post_spin_evaluation(flip_count:int):
	printt(flip_count, sign($Knife.rotation))
	if all_or_nothing:
		pass

func _on_delete_dice_button_pressed() -> void:
	for c in get_children():
		if c is Dice:
			c.queue_free()

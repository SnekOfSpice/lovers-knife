extends Node2D
class_name Lover

@export var is_player:bool

var dice := []
var items := []

signal start_rolling_dice(techId:String, on_right:bool)

func add_to_dice_inventory(techId:String):
	dice.append(techId)
	var button = preload("res://game/dice/dice_button.tscn").instantiate()
	button.texture_normal = load(str("res://game/dice/",techId,"/",techId,".png"))
	button.connect("pressed", roll_dice.bind(techId))
	button.techId = techId
	$DiceContainer.add_child(button)
	button.disabled = not is_player

func roll_dice(techId:String):
	dice.erase(techId)
	for d in $DiceContainer.get_children():
		if d.techId == techId:
			d.queue_free()
	emit_signal("start_rolling_dice", techId, is_player)

func has_dice_left() -> bool:
	return dice.size() > 0

func evaluate_gamestate():
	# TODO: replace with actual logic
	roll_dice(dice.pick_random())

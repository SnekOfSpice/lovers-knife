extends Button
class_name ActionButton

enum Actions {
	Dice,
	Item
}

var tech_id := ""
var action_type:int
var owned_by_player := false

signal set_info_text(text:String)
signal dice_mouse_entered(tech_id)
signal dice_mouse_exited()

func _ready() -> void:
	Data.listen(self, "gamestate.can_input", true)

func property_change(property: String, new_value, old_value):
	match property:
		"gamestate.can_input":
			if Data.of("game.singleplayer"):
				disabled = not new_value or not owned_by_player
			else:
				if owned_by_player:
					disabled = not Data.of("gamestate.is_player_turn") or not new_value
				else:
					disabled = Data.of("gamestate.is_player_turn") or not new_value

func set_id(tech_id:String, action_type:int):
	self.tech_id = tech_id
	self.action_type = action_type
	if action_type == Actions.Dice:
		icon = load(str("res://game/dice/",tech_id,"/",tech_id,".png"))
	elif action_type == Actions.Item:
		icon = load(str("res://game/items/",tech_id,"/",tech_id,".png"))
	


func _on_pressed() -> void:
	if action_type == Actions.Dice:
		Data.apply("gamestate.can_input", false)


func _on_mouse_entered() -> void:
	var text := ""
	if action_type == ActionButton.Actions.Dice:
		
		var eval = GameState.get_evaluated_faces(tech_id)
		for e in eval:
			text += str(" [", e, "] ")
		
		text += str("\n", Data.dice_descriptions.get(tech_id, ""))
	elif action_type == ActionButton.Actions.Item:
		text = Data.item_descriptions.get(tech_id, "")
	
	emit_signal("set_info_text", text)
	if action_type == Actions.Dice:
		emit_signal("dice_mouse_entered", tech_id)
	elif action_type == Actions.Item:
		emit_signal("set_info_text", text)


func _on_mouse_exited() -> void:
	if action_type == Actions.Dice:
		emit_signal("dice_mouse_exited")
	elif action_type == Actions.Item:
		emit_signal("set_info_text", "")
	

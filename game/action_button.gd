extends TextureButton
class_name ActionButton

enum Actions {
	Dice,
	Item
}

var tech_id := ""
var action_type:int
var owned_by_player := false

func _ready() -> void:
	Data.listen(self, "gamestate.can_input", true)

func property_change(property: String, new_value, old_value):
	match property:
		"gamestate.can_input":
			disabled = not new_value or not owned_by_player

func set_id(tech_id:String, action_type:int):
	self.tech_id = tech_id
	self.action_type = action_type
	if action_type == Actions.Dice:
		$IconTexture.texture = load(str("res://game/dice/",tech_id,"/",tech_id,".png"))
	elif action_type == Actions.Item:
		$IconTexture.texture = load(str("res://game/items/",tech_id,"/",tech_id,".png"))
	


func _on_pressed() -> void:
	if action_type == Actions.Dice:
		Data.apply("gamestate.can_input", false)

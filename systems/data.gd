extends Node

var item_descriptions := {
	"escape_velocity":"Reaching terminal velocity stabs your lover.",
	"grasp_of_fate":"Replaces all dice faces with 0 on the next roll.",
	"all_or_nothing":"Evens: Knife points at you.\nOdds: Knife points at lover.",
	"possession":"Changes who takes even turns.\nActivate again to dispel possession.",
	"candle":"Prolongs the round by one turn. Dice are redistributed when the last one is rolled."
}

var dice_descriptions := {
	"copy":"Copies last rolled dice. Defaults to D6.",
	"d3":"D3.",
	"d6":"D6.",
	"fibonacci":"It's the fibonacci sequence!",
	"pi":"Pi's decimal digits.",
	"turncount":"Replaces all odds with the turn count."
}

var faces := {
	"copy":["copy","copy","copy","copy","copy","copy"],
	"d3":[1,2,3,1,2,3],
	"d6":[1,2,3,4,5,6],
	"fibonacci":[0,1,1,2,3,5],
	"pi":[1,4,1,5,9,2],
	"turncount":["turncount",2,"turncount",4,"turncount",6]
}

var properties := {}
var listeners := {}

func _ready() -> void:
	apply("items.possession", false)
	apply("items.all_or_nothing", false)
	apply("items.grasp_of_fate", false)
	apply("items.escape_velocity", false)
	apply("gamestate.can_input", false)
	apply("gamestate.right_active", false)
	apply("gamestate.left_active", false)
	apply("knife.rotations", 0)

func listen(listener:Node, property:String, immediate_callback:=false):
	if listeners.has(property):
		listeners.get(property).append(listener)
	else:
		listeners[property] = [listener]
	
	if immediate_callback:
		listener.property_change(property, of(property), of(property))

func of(property:String, default=0):
	if not properties.get(property):
		properties[property] = default
	return properties.get(property)

# func property_change(property: String, new_value, old_value):
func apply(property:String, value):
	var old_value = of(property, property)
	properties[property] = value
	var property_listeners : Array = listeners.get(property, [])
	for listener in property_listeners:
		if not is_instance_valid(listener):
			continue
		listener.property_change(property, value, old_value)
	

func change_by_int(property:String, change:int):
	if typeof(of(property)) != TYPE_INT:
		return
	apply(property, of(property) + change)

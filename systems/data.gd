extends Node

var item_descriptions := {
	"escape_velocity":"When the knife reaches escape velocity, point it at your lover.",
	"grasp_of_fate":"Replaces all dice faces with 0 on the next roll.",
	"all_or_nothing":"evens: knife points at you. odds: knife points at lover.",
	"possession":"change when you go",
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
	for listener in listeners.get(property, []):
		listener.property_change(property, value, old_value)
	

func change_by_int(property:String, change:int):
	if typeof(of(property)) != TYPE_INT:
		return
	apply(property, of(property) + change)

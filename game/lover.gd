extends Node2D
class_name Lover

@export var is_player:bool

var dice := []
var items := []


func add_to_dice_inventory(techId:String):
	dice.append(techId)
	print(dice)

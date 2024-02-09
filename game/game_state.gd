extends Node

# items
var all_or_nothing := false
var grasp_of_fate := false
var possession := false # dictates if you go during odds (default) or evens (posession)

var turn_count := 0
var goal_turn_count := 3
var last_faces := []
var is_player_turn := true
var dice_played_this_round := []

extends Node

var game:Game

var last_faces := []
var dice_played_this_round := []


func reset_between_rounds():
	# items
	Data.apply("items.all_or_nothing", false)
	Data.apply("items.grasp_of_fate", false)
	Data.apply("items.possession", false)
	Data.apply("items.escape_velocity", false)
	
	# timing
	Data.apply("gamestate.is_player_turn", true)
	Data.apply("gamestate.turn_count", 0)
	Data.apply("gamestate.goal_turn_count", 6)
	
	last_faces.clear()
	dice_played_this_round.clear()


## returns an Array based on the current gamestate
func get_evaluated_faces(tech_id:String) -> Array:
	var faces = Data.faces.get(tech_id)
	var evaluated_faces : = []
	var face_count := 0
	for face in faces:
		if Data.of("items.grasp_of_fate"):
			evaluated_faces.append(0)
			continue
		if face is int:
			evaluated_faces.append(face)
		elif face is String:
			match face:
				"turncount":
					evaluated_faces.append(Data.of("gamestate.turn_count"))
				"copy":
					if GameState.last_faces.is_empty():
						evaluated_faces.append(face_count + 1)
					else:
						evaluated_faces.append(last_faces[face_count])
		face_count += 1
	
	return evaluated_faces

func get_expected_value(tech_id:String) -> float:
	var faces = get_evaluated_faces(tech_id)
	var ev:float
	for face in faces:
		ev += face
	ev /= float(faces.size())
	return ev

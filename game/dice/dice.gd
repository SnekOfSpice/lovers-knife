extends RigidBody2D
class_name Dice

@export var techId:String
@export var faces := []

var rolling := false

signal rolled(result:int)

## returns an Array based on the current gamestate
func get_evaluated_faces() -> Array:
	var evaluated_faces : = []
	
	var face_count := 0
	for face in faces:
		if GameState.grasp_of_fate:
			evaluated_faces.append(0)
			continue
		if face is int:
			evaluated_faces.append(face)
		elif face is String:
			match face:
				"turncount":
					evaluated_faces.append(GameState.turn_count)
				"copy":
					if GameState.last_faces.is_empty():
						evaluated_faces.append(face_count + 1)
					else:
						evaluated_faces.append(GameState.last_faces[face_count])
		face_count += 1
		
	
	return evaluated_faces

#var roll_time:float
#var slowdown:=Vector2.ZERO
#func _physics_process(delta: float) -> void:
	#slowdown.x += delta
	#slowdown.y += delta
	#if rolling:
		#roll_time -= delta
	#if roll_time <= 0:
		#rolling = false
		#emit_signal("rolled", get_evaluated_faces().pick_random())
#
#func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	#if slowdown.length() > state.linear_velocity.length():
		#state.linear_velocity = Vector2.ZERO
	#else:
		#state.linear_velocity = state.linear_velocity - slowdown

func emit_roll():
	var faces = get_evaluated_faces()
	var result = faces.pick_random()
	GameState.last_faces = faces
	emit_signal("rolled", result)
	$Label.text = str(result)
	var t = create_tween()
	t.tween_property(self, "modulate:a", 0.0, 2.0)
	t.tween_callback(queue_free)

func roll(right:bool):
	$Label.text = "?"
	var t = get_tree().create_timer(1)
	t.connect("timeout", emit_roll)
	#slowdown = Vector2.ZERO
	#apply_central_impulse((Vector2(300 if right else -300, 50 if right else -50)))
	#apply_impulse(Vector2.ONE * 700, find_child("SpinPosition").position)
	##apply_torque_impulse(20000)
	#roll_time = 10
	#rolling = true
	

extends RigidBody2D
class_name Dice

@export var tech_id:String
@export var faces := []

var rolling := false
var start_right := false

signal rolled(result:int)

var launch := false
var finished_roll := false
var launch_force:float
var evaluated_faces:Array

func _ready() -> void:
	launch_force = randf_range(250, 450)
	set_process(false)

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

var jitter_cooldown := 0.1
func _process(delta: float) -> void:
	#$Label.global_rotation = 0.0
	if linear_velocity.length() == 0:
		if finished_roll:
			return
		emit_roll()
	else:
		jitter_cooldown -= delta
		if jitter_cooldown <= 0:
			$Label.text = str(evaluated_faces.pick_random())
			jitter_cooldown = 0.1
		

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if launch:
		if start_right:
			linear_velocity = Vector2(-launch_force, randf_range(-30, 30))
		else:
			linear_velocity = Vector2(launch_force, randf_range(-30, 30))
		angular_velocity = randf_range(-60, 60)
		set_process(true)
		launch = false
	if linear_velocity.length() <= 35:
		linear_velocity *= 0.5
	elif linear_velocity.length() <= 85:
		linear_velocity *= 0.9

func emit_roll():
	finished_roll = true
	var result = evaluated_faces.pick_random()
	GameState.last_faces = evaluated_faces
	emit_signal("rolled", result)
	$Label.text = str(result)
	$Label.scale = Vector2(1.4, 1.4)
	var t = create_tween()
	t.tween_property(self, "modulate:a", 0.0, 2.0)
	t.tween_callback(queue_free)

func roll(right:bool):
	evaluated_faces = GameState.get_evaluated_faces(tech_id)
	launch = true
	start_right = right
	

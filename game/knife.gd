extends AnimatedSprite2D

var goingRight:bool

signal finish_rotation()

func is_pointing_right() -> bool:
	return frame < 3

func set_pointing(right:bool):
	if frame < 3 and right:
		frame = 0
		emit_signal("finish_rotation")
		return
	if frame > 3 and not right:
		frame = 6
		emit_signal("finish_rotation")
		return
	goingRight = not right
	if right:
		play_backwards("default")
	else:
		play("default")

func get_flip_duration_sec() -> float:
	return sprite_frames.get_frame_count("default") / sprite_frames.get_animation_speed("default")


func _on_frame_changed() -> void:
	if (frame == 5 and goingRight) or (frame == 1 and not goingRight):
		Data.change_by_int("knife.rotations", 1)
	if frame == 0 or frame == 6:
		emit_signal("finish_rotation")

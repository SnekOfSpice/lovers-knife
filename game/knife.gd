extends AnimatedSprite2D


func is_pointing_right() -> bool:
	return frame < 3

func set_pointing(right:bool):
	if frame == 0 and right:
		return
	if frame == 6 and not right:
		return
	if right:
		play_backwards("default")
	else:
		play("default")

func get_flip_duration_sec() -> float:
	return sprite_frames.get_frame_count("default") / sprite_frames.get_animation_speed("default")

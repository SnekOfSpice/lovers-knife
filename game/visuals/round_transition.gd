extends ColorRect

signal middle_reached()
signal end_reached()

func _ready() -> void:
	modulate.a = 0.0
	visible = true

func start_transition():
	var t = create_tween()
	t.tween_property(self, "modulate:a", 1.0, 3.0).from(0.0)
	t.tween_callback($Label.set_text.bind("Next round")).set_delay(3.0)
	t.tween_callback(emit_signal.bind("middle_reached")).set_delay(3.0)
	t.tween_property(self, "modulate:a", 0.0, 3.0)
	t.finished.connect(emit_signal.bind("end_reached"))

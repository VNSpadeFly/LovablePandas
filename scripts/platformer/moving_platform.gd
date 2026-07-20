extends AnimatableBody2D
## Platform that glides back and forth between its start position and
## start + move_offset. Runs on the physics tick so the panda is carried
## along correctly while standing on it.

@export var move_offset := Vector2(400, 0)
@export var cycle_seconds := 2.2

func _ready() -> void:
	var start := position
	var tween := create_tween()
	tween.set_loops()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(self, "position", start + move_offset, cycle_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position", start, cycle_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

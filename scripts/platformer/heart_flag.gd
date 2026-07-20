extends Node2D
## Goal marker: a pole with a pink heart on top, drawn procedurally.

const HEART_COLOR := Color("ff6f9c")
const POLE_COLOR := Color("8a6552")

func _ready() -> void:
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _draw() -> void:
	draw_line(Vector2(0, 0), Vector2(0, -230), POLE_COLOR, 8.0)
	var top := Vector2(0, -245)
	draw_circle(top + Vector2(-14, -8), 20, HEART_COLOR)
	draw_circle(top + Vector2(14, -8), 20, HEART_COLOR)
	var tip := PackedVector2Array([
		top + Vector2(-32, 2), top + Vector2(32, 2), top + Vector2(0, 42)
	])
	draw_colored_polygon(tip, HEART_COLOR)

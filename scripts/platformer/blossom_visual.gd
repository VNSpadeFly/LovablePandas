extends Node2D
## Procedural placeholder cherry blossom -- swap for a sprite later.

const PETAL_COLOR := Color("ffb3d1")
const CENTER_COLOR := Color("ffe066")

func _draw() -> void:
	for i in range(5):
		var angle := TAU / 5.0 * i
		var offset := Vector2(cos(angle), sin(angle)) * 9.0
		draw_set_transform(offset, angle, Vector2.ONE)
		_draw_petal(9.0, 6.0, PETAL_COLOR)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(Vector2.ZERO, 5.0, CENTER_COLOR)

func _draw_petal(rx: float, ry: float, color: Color) -> void:
	var points := PackedVector2Array()
	var segments := 16
	for i in range(segments):
		var t := TAU / segments * i
		points.append(Vector2(cos(t) * rx, sin(t) * ry))
	draw_colored_polygon(points, color)

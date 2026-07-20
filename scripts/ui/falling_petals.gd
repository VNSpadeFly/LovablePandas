class_name FallingPetals
extends Node2D
## Gentle stream of cherry-blossom petals drifting down the screen.
## Pure Labels with the blossom emoji -- no textures needed. Petals
## ignore mouse input, so they never block taps.

@export var area := Vector2(720, 1280)
@export var max_petals := 14
@export var spawn_interval := 0.8

var _time := 0.0
var _spawn_accum := 0.0

func _process(delta: float) -> void:
	_time += delta
	_spawn_accum += delta
	if _spawn_accum >= spawn_interval and get_child_count() < max_petals:
		_spawn_accum = 0.0
		_spawn_petal()

	for petal in get_children():
		var speed: float = petal.get_meta("speed")
		var sway: float = petal.get_meta("sway")
		var phase: float = petal.get_meta("phase")
		petal.position.y += speed * delta
		petal.position.x += sin(_time * sway + phase) * 22.0 * delta
		if petal.position.y > area.y + 40.0:
			petal.queue_free()

func _spawn_petal() -> void:
	var petal := Label.new()
	petal.text = "🌸"
	petal.add_theme_font_size_override("font_size", randi_range(14, 30))
	petal.modulate = Color(1, 1, 1, randf_range(0.45, 0.9))
	petal.position = Vector2(randf_range(-20.0, area.x), -40.0)
	petal.set_meta("speed", randf_range(40.0, 90.0))
	petal.set_meta("sway", randf_range(0.6, 1.6))
	petal.set_meta("phase", randf_range(0.0, TAU))
	add_child(petal)

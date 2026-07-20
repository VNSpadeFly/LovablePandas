extends Area2D
## A cherry blossom the player can walk into to collect. Bobs gently in
## place; pops with a little scale/fade animation when collected.

var _collected := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var tween := create_tween()
	tween.set_loops()
	var offset := randf_range(4.0, 8.0)
	tween.tween_property(self, "position:y", position.y - offset, randf_range(0.9, 1.4)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position:y", position.y, randf_range(0.9, 1.4)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_body_entered(body: Node) -> void:
	if _collected or not body.is_in_group("player"):
		return
	_collected = true
	set_deferred("monitoring", false)
	GameState.add_flowers(1)
	Sfx.play("collect")
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.8, 1.8), 0.25).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(queue_free)

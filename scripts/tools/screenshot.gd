extends Node

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	var img := get_viewport().get_texture().get_image()
	var out := OS.get_environment("SHOT_OUT")
	if out == "":
		out = "user://shot.png"
	img.save_png(out)
	print("Saved screenshot to ", out)
	get_tree().quit()

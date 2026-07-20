extends Control
## Level select: one big button per adventure level. A level unlocks
## once the previous one is completed; finished levels get a wreath.

@onready var list: VBoxContainer = $CenterContainer/LevelList
@onready var back_button: Button = $BackButton

func _ready() -> void:
	back_button.pressed.connect(func(): SceneRouter.go_to(SceneRouter.HOME))
	_populate()

func _populate() -> void:
	for child in list.get_children():
		child.queue_free()

	var previous_done := true
	for i in SceneRouter.LEVELS.size():
		var level: Dictionary = SceneRouter.LEVELS[i]
		var done: bool = GameState.is_level_completed(level.id)
		var unlocked := previous_done
		previous_done = done

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(480, 96)
		btn.add_theme_font_size_override("font_size", 24)
		if unlocked:
			var badge := "💮 " if done else ""
			btn.text = "%sLevel %d – %s" % [badge, i + 1, level.name]
			btn.pressed.connect(func(): SceneRouter.go_to(level.path))
		else:
			btn.text = "🔒 Level %d" % (i + 1)
			btn.disabled = true
		list.add_child(btn)

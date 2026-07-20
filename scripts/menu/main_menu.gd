extends Control

@onready var start_button: Button = $StartButton

func _ready() -> void:
	start_button.pressed.connect(func(): SceneRouter.go_to(SceneRouter.HOME))

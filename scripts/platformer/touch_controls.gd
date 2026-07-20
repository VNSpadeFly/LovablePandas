class_name TouchControls
extends Control
## On-screen left/right/jump buttons for mobile. Assign `player` after
## instancing (level_01.gd does this) -- keeps this scene reusable
## across future levels without hardcoding a player path.

var player: PlatformerPlayer

var _left_held := false
var _right_held := false

@onready var left_button: Button = $LeftButton
@onready var right_button: Button = $RightButton
@onready var jump_button: Button = $JumpButton

func _ready() -> void:
	left_button.button_down.connect(func(): _set_held(true, false))
	left_button.button_up.connect(func(): _set_held(false, false))
	right_button.button_down.connect(func(): _set_held(true, true))
	right_button.button_up.connect(func(): _set_held(false, true))
	# button_down (not the default "pressed") fires the instant a finger
	# touches the button, not on release -- matters a lot for players who
	# instinctively hold the button down instead of tapping it.
	jump_button.button_down.connect(_on_jump_pressed)

func _set_held(is_held: bool, is_right: bool) -> void:
	if is_right:
		_right_held = is_held
	else:
		_left_held = is_held
	var direction := 0.0
	if _right_held:
		direction += 1.0
	if _left_held:
		direction -= 1.0
	if player:
		player.set_touch_direction(direction)

func _on_jump_pressed() -> void:
	if player:
		player.request_jump()

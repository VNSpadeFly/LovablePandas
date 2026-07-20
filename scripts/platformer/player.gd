class_name PlatformerPlayer
extends CharacterBody2D
## Panda movement for the platformer mode: run + jump, no fail state.
## Keyboard input works for desktop testing; touch_controls.gd drives
## touch_direction / request_jump() for on-device play.
##
## Coyote time + jump buffering keep jumps forgiving: you can still jump
## a moment after leaving a ledge, and a tap just before landing counts.

@export var is_female: bool = false
@export var speed: float = 260.0
@export var jump_velocity: float = -620.0

const COYOTE_TIME := 0.12
const JUMP_BUFFER := 0.15

var touch_direction: float = 0.0
var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _coyote_left := 0.0
var _buffer_left := 0.0
var _was_on_floor := false
var _anim_state := "idle"

@onready var visual: PandaVisual = $PandaVisual

func _ready() -> void:
	visual.is_female = is_female
	visual.mood = PandaVisual.Mood.HAPPY

func _physics_process(delta: float) -> void:
	var direction := touch_direction
	if direction == 0.0:
		direction = Input.get_axis("move_left", "move_right")

	if is_on_floor():
		_coyote_left = COYOTE_TIME
	else:
		_coyote_left = maxf(0.0, _coyote_left - delta)
		velocity.y += _gravity * delta

	if Input.is_action_just_pressed("jump"):
		_buffer_left = JUMP_BUFFER
	else:
		_buffer_left = maxf(0.0, _buffer_left - delta)

	if _buffer_left > 0.0 and _coyote_left > 0.0:
		velocity.y = jump_velocity
		_buffer_left = 0.0
		_coyote_left = 0.0

	velocity.x = direction * speed
	move_and_slide()

	if is_on_floor() and not _was_on_floor:
		Sfx.play("land")
	_was_on_floor = is_on_floor()

	if direction != 0.0:
		visual.scale.x = -absf(visual.scale.x) if direction < 0.0 else absf(visual.scale.x)

	_update_animation(direction)

func _update_animation(direction: float) -> void:
	var new_state := "jump" if not is_on_floor() else ("run" if direction != 0.0 else "idle")
	if new_state != _anim_state:
		_anim_state = new_state
		visual.play(new_state)

func set_touch_direction(value: float) -> void:
	touch_direction = value

func request_jump() -> void:
	_buffer_left = JUMP_BUFFER

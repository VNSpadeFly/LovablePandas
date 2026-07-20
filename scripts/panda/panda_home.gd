class_name HomePanda
extends Area2D
## A panda living in the Tamagotchi home screen. Reflects GameState.pandas[panda_id]
## and reports taps so Home can open the feed/play/sleep menu for this panda.

signal tapped(panda_id: String)

@export var panda_id: String = "male"

@onready var visual: PandaVisual = $PandaVisual

func _ready() -> void:
	visual.is_female = (panda_id == "female")
	input_event.connect(_on_input_event)
	GameState.needs_changed.connect(_on_needs_changed)
	_refresh()
	_start_bobbing()

## Gentle idle bob so the pandas feel alive even while standing still.
func _start_bobbing() -> void:
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(visual, "position:y", -6.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(visual, "position:y", 0.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_needs_changed(id: String) -> void:
	if id == panda_id:
		_refresh()

func _refresh() -> void:
	var p: Dictionary = GameState.pandas[panda_id]
	if p.sleeping:
		visual.mood = PandaVisual.Mood.SLEEPY
	elif p.happiness > 60.0:
		visual.mood = PandaVisual.Mood.HAPPY
	else:
		visual.mood = PandaVisual.Mood.NEUTRAL

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	var pressed: bool = (event is InputEventScreenTouch and event.pressed) \
		or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if pressed:
		tapped.emit(panda_id)

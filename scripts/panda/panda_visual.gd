class_name PandaVisual
extends Node2D
## Animated panda: Em Yêu (female, pink bow + dress) or Anh Yêu (male,
## dark head floof, navy suit, thin glasses). Both sheets share the same
## frame layout, so idle/run/jump work identically for either.
## Callers only use set_mood() / set_is_female() / play().

enum Mood { HAPPY, NEUTRAL, SLEEPY, EATING }

const FEMALE_FRAMES := preload("res://assets/sprites/panda/panda_female_frames.tres")
const MALE_FRAMES := preload("res://assets/sprites/panda/panda_male_frames.tres")
const SLEEPY_TINT := Color(0.75, 0.8, 0.95)

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var is_female: bool = false:
	set(value):
		is_female = value
		if is_inside_tree():
			_apply_frames()
@export var mood: Mood = Mood.HAPPY:
	set(value):
		mood = value
		if is_inside_tree():
			_apply_mood()

func _ready() -> void:
	_apply_frames()
	_apply_mood()

func _apply_frames() -> void:
	animated_sprite.sprite_frames = FEMALE_FRAMES if is_female else MALE_FRAMES
	animated_sprite.play("idle")

func _apply_mood() -> void:
	animated_sprite.modulate = SLEEPY_TINT if mood == Mood.SLEEPY else Color.WHITE

## Drives locomotion animation: "idle", "run" or "jump".
func play(state: String) -> void:
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(state):
		if animated_sprite.animation != state or not animated_sprite.is_playing():
			animated_sprite.play(state)

func set_mood(value: Mood) -> void:
	mood = value

func set_is_female(value: bool) -> void:
	is_female = value

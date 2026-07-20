extends CanvasLayer
## Central place for scene paths and switching so no other script
## hardcodes a res:// path. Autoloaded as "SceneRouter".
## Wraps every switch in a soft blush-colored fade.

const MAIN_MENU := "res://scenes/menu/main_menu.tscn"
const HOME := "res://scenes/home/home.tscn"
const LEVEL_SELECT := "res://scenes/platformer/level_select.tscn"
const PLATFORMER_LEVEL_01 := "res://scenes/platformer/level_01.tscn"
const MAILBOX := "res://scenes/mailbox/mailbox.tscn"

## Adventure levels in order. The level select builds its buttons from
## this list; a level unlocks once the previous one is completed.
const LEVELS := [
	{"id": "level_01", "name": "Kirschblüten-Wald", "path": "res://scenes/platformer/level_01.tscn"},
	{"id": "level_02", "name": "Über die Abgründe", "path": "res://scenes/platformer/level_02.tscn"},
	{"id": "level_03", "name": "Schwebende Pfade", "path": "res://scenes/platformer/level_03.tscn"},
	{"id": "level_04", "name": "Strandspaziergang", "path": "res://scenes/platformer/level_04.tscn"},
	{"id": "level_05", "name": "Frankfurter Lichter", "path": "res://scenes/platformer/level_05.tscn"},
	{"id": "level_06", "name": "Alpengipfel", "path": "res://scenes/platformer/level_06.tscn"},
]

const FADE_SECONDS := 0.25

var _fade_rect: ColorRect
var _busy := false

func _ready() -> void:
	layer = 100
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(1.0, 0.93, 0.95, 0.0)
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade_rect)

func go_to(scene_path: String) -> void:
	if _busy:
		return
	_busy = true
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", 1.0, FADE_SECONDS)
	await tween.finished
	get_tree().change_scene_to_file(scene_path)
	var tween_in := create_tween()
	tween_in.tween_property(_fade_rect, "color:a", 0.0, FADE_SECONDS)
	await tween_in.finished
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false

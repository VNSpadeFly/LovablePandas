class_name PlatformLevel
extends Node2D
## Shared logic for every adventure level: flower HUD, completion panel,
## and gentle pit respawn. Levels stay fail-free -- falling into a hole
## just floats the panda back to the start, nothing is lost.
##
## Expected scene structure (see level_01.tscn as template):
##   Player, LevelEnd (level_end.gd), UI/TouchControls, UI/FlowerHud,
##   UI/CompletePanel/VBox/{FlowersLine,NextButton,HomeButton}, UI/MenuButton
##   Optional: FallZone (Area2D below the level) for levels with pits.

## SceneRouter path of the next level; empty on the last level.
@export var next_level_path := ""

@onready var player: PlatformerPlayer = $Player
@onready var touch_controls: TouchControls = $UI/TouchControls
@onready var flower_hud: Label = $UI/FlowerHud
@onready var complete_panel: PanelContainer = $UI/CompletePanel
@onready var complete_flowers: Label = $UI/CompletePanel/VBox/FlowersLine
@onready var next_button: Button = $UI/CompletePanel/VBox/NextButton
@onready var home_button: Button = $UI/CompletePanel/VBox/HomeButton
@onready var menu_button: Button = $UI/MenuButton
@onready var level_end: Area2D = $LevelEnd

var _collected := 0
var _total := 0
var _spawn_position := Vector2.ZERO

func _ready() -> void:
	touch_controls.player = player
	complete_panel.visible = false
	_spawn_position = player.position
	_total = get_tree().get_nodes_in_group("flowers").size()
	_update_hud()
	GameState.flowers_changed.connect(_on_flowers_changed)
	level_end.reached.connect(_on_level_end_reached)
	menu_button.pressed.connect(func(): SceneRouter.go_to(SceneRouter.LEVEL_SELECT))
	home_button.pressed.connect(func(): SceneRouter.go_to(SceneRouter.HOME))
	next_button.visible = next_level_path != ""
	if next_button.visible:
		next_button.pressed.connect(func(): SceneRouter.go_to(next_level_path))
	if has_node("FallZone"):
		($FallZone as Area2D).body_entered.connect(_on_fall_zone_entered)

func _on_fall_zone_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	player.velocity = Vector2.ZERO
	player.position = _spawn_position
	var camera: Camera2D = player.get_node_or_null("Camera2D")
	if camera:
		camera.reset_smoothing()
	# Soft blink instead of any punishment -- just "oops, try again".
	var tween := player.create_tween()
	tween.tween_property(player, "modulate:a", 0.3, 0.12)
	tween.tween_property(player, "modulate:a", 1.0, 0.35)

func _on_flowers_changed(_total_count: int) -> void:
	_collected += 1
	_update_hud()

func _update_hud() -> void:
	flower_hud.text = "🌸 %d / %d" % [_collected, _total]

func _on_level_end_reached() -> void:
	if complete_panel.visible:
		return
	complete_flowers.text = "Du hast %d von %d Blüten gesammelt!" % [_collected, _total]
	complete_panel.visible = true

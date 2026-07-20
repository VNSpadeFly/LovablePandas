extends Node2D

@onready var male_panda: HomePanda = $MalePanda
@onready var female_panda: HomePanda = $FemalePanda
@onready var action_menu: PandaActionMenu = $UI/ActionMenu
@onready var flower_label: Label = $UI/FlowerLabel
@onready var max_stats_label: Label = $UI/StreakLabel
@onready var adventure_button: Button = $UI/AdventureButton
@onready var mailbox_button: Button = $UI/MailboxButton

var _current_panda_id: String = ""

func _ready() -> void:
	male_panda.tapped.connect(_on_panda_tapped)
	female_panda.tapped.connect(_on_panda_tapped)
	action_menu.feed_pressed.connect(_on_feed)
	action_menu.play_pressed.connect(_on_play)
	action_menu.kiss_pressed.connect(_on_kiss)
	action_menu.sleep_toggled.connect(_on_sleep_toggled)
	GameState.flowers_changed.connect(_on_flowers_changed)
	GameState.max_stats_reached.connect(_on_max_stats_reached)
	adventure_button.pressed.connect(func(): SceneRouter.go_to(SceneRouter.LEVEL_SELECT))
	mailbox_button.pressed.connect(func(): SceneRouter.go_to(SceneRouter.MAILBOX))
	_on_flowers_changed(GameState.flower_count)
	_update_max_stats_label(GameState.max_stats_count)

func _on_panda_tapped(panda_id: String) -> void:
	_current_panda_id = panda_id
	var panda: HomePanda = _panda_node(panda_id)
	action_menu.position = panda.global_position + Vector2(-100, -300)
	action_menu.set_panda(panda_id, GameState.pandas[panda_id].sleeping)
	action_menu.visible = true

func _on_feed() -> void:
	GameState.feed(_current_panda_id)
	_spawn_reaction(GameState.PANDA_FOOD[_current_panda_id].emoji, _current_panda_id)

func _on_play() -> void:
	GameState.play_with(_current_panda_id)
	_spawn_reaction(GameState.PANDA_PLAY[_current_panda_id].emoji, _current_panda_id)

func _on_kiss() -> void:
	GameState.kiss_both()
	Sfx.play("note")
	_spawn_heart_burst("male")
	_spawn_heart_burst("female")

func _on_sleep_toggled() -> void:
	var sleeping: bool = GameState.pandas[_current_panda_id].sleeping
	GameState.set_sleeping(_current_panda_id, not sleeping)
	_spawn_reaction("⏰" if sleeping else "💤", _current_panda_id)

func _panda_node(panda_id: String) -> HomePanda:
	return male_panda if panda_id == "male" else female_panda

## Floating emoji that drifts up from the panda and fades -- small
## feedback so actions feel alive.
func _spawn_reaction(emoji: String, panda_id: String) -> void:
	var label := Label.new()
	label.text = emoji
	label.add_theme_font_size_override("font_size", 42)
	label.position = _panda_node(panda_id).position + Vector2(-20, -150)
	add_child(label)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 90.0, 1.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 1.1).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(label.queue_free)

## A little shower of hearts for the kiss action -- three hearts drifting
## up on staggered, slightly diverging paths.
func _spawn_heart_burst(panda_id: String) -> void:
	var hearts := ["💕", "💗", "💖"]
	var base_pos: Vector2 = _panda_node(panda_id).position + Vector2(-20, -150)
	for i in hearts.size():
		var label := Label.new()
		label.text = hearts[i]
		label.add_theme_font_size_override("font_size", 38)
		label.position = base_pos + Vector2((i - 1) * 26.0, 0.0)
		add_child(label)
		var delay := i * 0.12
		var drift_x := (i - 1) * 18.0
		var tween := label.create_tween()
		tween.tween_interval(delay)
		tween.set_parallel(true)
		tween.tween_property(label, "position:y", label.position.y - 100.0, 1.2).set_ease(Tween.EASE_OUT)
		tween.tween_property(label, "position:x", label.position.x + drift_x, 1.2).set_ease(Tween.EASE_OUT)
		tween.tween_property(label, "modulate:a", 0.0, 1.2).set_ease(Tween.EASE_IN)
		tween.chain().tween_callback(label.queue_free)

func _on_flowers_changed(total: int) -> void:
	flower_label.text = "🌸 %d" % total

func _on_max_stats_reached(count: int) -> void:
	_update_max_stats_label(count)
	Notifier.toast("💯 Alles auf Maximum! (%d. Mal)" % count)

func _update_max_stats_label(count: int) -> void:
	max_stats_label.text = "💯 %d× alles maximiert" % count

extends CanvasLayer
## Global toast notifications, most importantly "new love note unlocked!".
## Autoloaded as "Notifier" -- lives above all scenes so unlocks are
## celebrated no matter where they happen (platformer, home, ...).

const TOAST_SECONDS := 3.5

var _stack: VBoxContainer

func _ready() -> void:
	layer = 90
	_stack = VBoxContainer.new()
	_stack.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_stack.offset_left = 40.0
	_stack.offset_right = -40.0
	_stack.offset_top = 100.0
	_stack.add_theme_constant_override("separation", 10)
	_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stack)
	call_deferred("_connect_signals")

func _connect_signals() -> void:
	LoveNotes.note_unlocked.connect(_on_note_unlocked)

func _on_note_unlocked(note: LoveNote) -> void:
	Sfx.play("note")
	toast("💌 Neuer Liebesbrief: „%s“" % note.title)

func toast(text: String) -> void:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.95)
	style.border_color = Color("ff9ebb")
	style.set_border_width_all(3)
	style.set_corner_radius_all(20)
	style.content_margin_left = 20.0
	style.content_margin_right = 20.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color("b04a6e"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)

	_stack.add_child(panel)
	panel.modulate.a = 0.0
	var tween := panel.create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.3)
	tween.tween_interval(TOAST_SECONDS)
	tween.tween_property(panel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(panel.queue_free)

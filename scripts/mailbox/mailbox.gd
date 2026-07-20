extends Control

@onready var list_container: VBoxContainer = $ScrollContainer/VBoxContainer
@onready var counter_label: Label = $CounterLabel
@onready var detail_panel: PanelContainer = $DetailPanel
@onready var detail_title: Label = $DetailPanel/VBox/Title
@onready var detail_message: Label = $DetailPanel/VBox/Message
@onready var back_button: Button = $BackButton
@onready var close_detail_button: Button = $DetailPanel/VBox/CloseButton

func _ready() -> void:
	back_button.pressed.connect(func(): SceneRouter.go_to(SceneRouter.HOME))
	close_detail_button.pressed.connect(func(): detail_panel.visible = false)
	detail_panel.visible = false
	LoveNotes.note_unlocked.connect(func(_note): _populate())
	_populate()

func _populate() -> void:
	for child in list_container.get_children():
		child.queue_free()

	counter_label.text = "%d von %d freigeschaltet" % [LoveNotes.get_unlocked_count(), LoveNotes.get_total_count()]

	for note in LoveNotes.get_all_notes():
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 64)
		if LoveNotes.is_unlocked(note.id):
			btn.text = "💌 " + note.title
			btn.pressed.connect(_show_detail.bind(note))
		else:
			btn.text = "🔒 " + note.get_hint()
			btn.disabled = true
		list_container.add_child(btn)

func _show_detail(note: LoveNote) -> void:
	detail_title.text = note.title
	detail_message.text = note.message
	detail_panel.visible = true

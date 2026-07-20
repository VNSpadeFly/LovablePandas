class_name NeedsDisplay
extends PanelContainer
## Shows one panda's name and hunger/happiness/sleep bars, live-updated
## from GameState.

@export var panda_id: String = "male":
	set(value):
		panda_id = value
		if is_inside_tree():
			_refresh()

@onready var name_label: Label = $VBox/NameLabel
@onready var hunger_bar: ProgressBar = $VBox/Hunger/Bar
@onready var happiness_bar: ProgressBar = $VBox/Happiness/Bar
@onready var sleep_bar: ProgressBar = $VBox/Sleep/Bar

func _ready() -> void:
	GameState.needs_changed.connect(_on_needs_changed)
	_refresh()

func _on_needs_changed(id: String) -> void:
	if id == panda_id:
		_refresh()

func _refresh() -> void:
	var p: Dictionary = GameState.pandas[panda_id]
	var icon := "🎀" if panda_id == "female" else "🐼"
	var suffix := " 💤" if p.sleeping else ""
	name_label.text = "%s %s%s" % [icon, GameState.PANDA_NAMES.get(panda_id, "Panda"), suffix]
	hunger_bar.value = p.hunger
	happiness_bar.value = p.happiness
	sleep_bar.value = p.sleep

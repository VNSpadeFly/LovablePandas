class_name PandaActionMenu
extends PanelContainer
## Small popup with Feed/Play/Kiss/Sleep actions for whichever panda was
## tapped. Home decides *which* panda_id these apply to and hides/shows/
## positions this.

signal feed_pressed
signal play_pressed
signal kiss_pressed
signal sleep_toggled

@onready var feed_button: Button = $VBox/FeedButton
@onready var play_button: Button = $VBox/PlayButton
@onready var kiss_button: Button = $VBox/KissButton
@onready var sleep_button: Button = $VBox/SleepButton
@onready var close_button: Button = $VBox/CloseButton

func _ready() -> void:
	feed_button.pressed.connect(func():
		feed_pressed.emit()
		visible = false)
	play_button.pressed.connect(func():
		play_pressed.emit()
		visible = false)
	kiss_button.pressed.connect(func():
		kiss_pressed.emit()
		visible = false)
	sleep_button.pressed.connect(func():
		sleep_toggled.emit()
		visible = false)
	close_button.pressed.connect(func(): visible = false)

## Personalizes the menu for the tapped panda: favorite food, hobby,
## the OTHER panda's name for the kiss action (this panda kisses them),
## and current sleep state.
func set_panda(panda_id: String, is_sleeping: bool) -> void:
	var food: Dictionary = GameState.PANDA_FOOD[panda_id]
	var hobby: Dictionary = GameState.PANDA_PLAY[panda_id]
	var partner_id := "female" if panda_id == "male" else "male"
	var partner_name: String = GameState.PANDA_NAMES[partner_id]
	feed_button.text = "%s %s" % [food.emoji, food.label]
	play_button.text = "%s %s" % [hobby.emoji, hobby.label]
	kiss_button.text = "😘 Kuss %s" % partner_name
	sleep_button.text = "⏰ Aufwecken" if is_sleeping else "😴 Schlafen legen"

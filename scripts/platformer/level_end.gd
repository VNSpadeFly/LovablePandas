extends Area2D
## Marks a level complete when the panda reaches it. No fail state --
## this only ever adds progress, never takes it away.

signal reached

@export var level_id: String = "level_01"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		GameState.mark_level_completed(level_id)
		LoveNotes.check_level(level_id)
		reached.emit()

class_name LoveNote
extends Resource
## A single hidden message, unlocked once its requirement is met.
## Create new notes as .tres files in res://resources/love_notes/ via
## the Godot editor Inspector -- no code changes needed.

enum Requirement {
	LEVEL_COMPLETE,   ## requirement_string = level_id
	MAX_STATS_COUNT,  ## requirement_value = times both pandas hit 100% on all needs at once
	FLOWER_COUNT,     ## requirement_value = total flowers collected
}

@export var id: String = ""
@export var requirement: Requirement = Requirement.FLOWER_COUNT
@export var requirement_value: int = 0
@export var requirement_string: String = "" ## used for LEVEL_COMPLETE
@export var title: String = "A little note"
@export_multiline var message: String = ""
## Shown on locked entries in the mailbox so she knows what to chase.
## Leave empty to auto-generate from the requirement.
@export var hint: String = ""

func get_hint() -> String:
	if hint != "":
		return hint
	match requirement:
		Requirement.LEVEL_COMPLETE:
			var num := requirement_string.trim_prefix("level_").lstrip("0")
			return "Schaffe Abenteuer-Level %s" % num
		Requirement.MAX_STATS_COUNT:
			if requirement_value <= 1:
				return "Bring beide Pandas einmal gleichzeitig auf 100%% bei allem"
			return "Bring beide Pandas %d mal gleichzeitig auf 100%% bei allem" % requirement_value
		Requirement.FLOWER_COUNT:
			return "Sammle %d Kirschblüten" % requirement_value
	return "???"

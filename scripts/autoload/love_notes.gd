extends Node
## Loads all LoveNote resources and tracks which are unlocked.
## Autoloaded as "LoveNotes". Add new notes as .tres files in
## res://resources/love_notes/ -- they are picked up automatically.

signal note_unlocked(note: LoveNote)

const NOTES_DIR := "res://resources/love_notes/"

var _notes_by_id: Dictionary = {} ## id -> LoveNote
var _unlocked: Dictionary = {} ## id -> true

func _ready() -> void:
	_load_notes()
	call_deferred("_connect_game_state")

func _connect_game_state() -> void:
	GameState.flowers_changed.connect(_on_flowers_changed)
	GameState.max_stats_reached.connect(_on_max_stats_reached)

func _load_notes() -> void:
	_notes_by_id.clear()
	var dir := DirAccess.open(NOTES_DIR)
	if not dir:
		push_warning("LoveNotes: could not open %s" % NOTES_DIR)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		# In exported builds resources appear as .remap (and text resources
		# may be converted to binary) -- normalize before matching.
		var clean := file_name.trim_suffix(".remap")
		if clean.ends_with(".tres") or clean.ends_with(".res"):
			var note: LoveNote = load(NOTES_DIR + clean)
			if note and note.id != "":
				_notes_by_id[note.id] = note
		file_name = dir.get_next()
	dir.list_dir_end()

func get_all_notes() -> Array:
	var notes := _notes_by_id.values()
	notes.sort_custom(func(a, b):
		if a.requirement != b.requirement:
			return a.requirement < b.requirement
		if a.requirement_value != b.requirement_value:
			return a.requirement_value < b.requirement_value
		return a.id < b.id)
	return notes

func is_unlocked(id: String) -> bool:
	return _unlocked.get(id, false)

func get_unlocked_ids() -> Array:
	return _unlocked.keys()

func get_unlocked_count() -> int:
	return _unlocked.size()

func get_total_count() -> int:
	return _notes_by_id.size()

func unlock(id: String, notify: bool = true) -> void:
	if _unlocked.get(id, false):
		return
	if not _notes_by_id.has(id):
		return
	_unlocked[id] = true
	if notify:
		note_unlocked.emit(_notes_by_id[id])
		GameState.save_game()

func check_level(level_id: String) -> void:
	for note in _notes_by_id.values():
		if note.requirement == LoveNote.Requirement.LEVEL_COMPLETE and note.requirement_string == level_id:
			unlock(note.id)

## Re-evaluates every requirement against current GameState. Called once
## after load so notes added in an update unlock retroactively.
func recheck_all() -> void:
	_on_flowers_changed(GameState.flower_count)
	_on_max_stats_reached(GameState.max_stats_count)
	for level_id in GameState.levels_completed.keys():
		if GameState.levels_completed[level_id]:
			check_level(level_id)

func _on_flowers_changed(total: int) -> void:
	for note in _notes_by_id.values():
		if note.requirement == LoveNote.Requirement.FLOWER_COUNT and total >= note.requirement_value:
			unlock(note.id)

func _on_max_stats_reached(count: int) -> void:
	for note in _notes_by_id.values():
		if note.requirement == LoveNote.Requirement.MAX_STATS_COUNT and count >= note.requirement_value:
			unlock(note.id)

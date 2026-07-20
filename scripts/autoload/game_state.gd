extends Node
## Central game state: panda needs, flower count, max-stats-moment tracking,
## save/load. Autoloaded as "GameState".
##
## Max-stats design: whenever BOTH pandas simultaneously have hunger,
## happiness AND sleep all at 100%, that's a "perfect moment" and the
## counter goes up once. It only counts again after the state drops below
## max and climbs back up -- so it rewards actively topping them back up,
## not just sitting at max forever.
##
## Offline decay is capped and floored so coming back after a long absence
## never greets the player with miserable pandas -- cozy, not punishing.

signal needs_changed(panda_id: String)
signal max_stats_reached(count: int)
signal flowers_changed(total: int)

const SAVE_PATH := "user://savegame.json"

## Live decay rates while the app is running.
const DECAY_PER_SECOND := {
	"hunger": 100.0 / (6.0 * 60.0 * 60.0), ## empty in ~6h
	"happiness": 100.0 / (10.0 * 60.0 * 60.0), ## empty in ~10h
	"sleep": 100.0 / (8.0 * 60.0 * 60.0), ## empty in ~8h
}

## Offline absence only counts up to this long, and needs never drop below
## OFFLINE_FLOOR from it -- pandas miss you, but they're never in a bad state.
const OFFLINE_MAX_SECONDS := 4.0 * 60.0 * 60.0
const OFFLINE_FLOOR := 20.0

const FEED_RESTORE := 35.0
const PLAY_RESTORE := 30.0
const SLEEP_RESTORE_PER_SECOND := 100.0 / (30.0 * 60.0) ## full rest in ~30min asleep
const KISS_RESTORE := 15.0 ## smaller per-stat bump since it touches all three at once

const PANDA_NAMES := {
	"male": "Anh Yêu",
	"female": "Em Yêu",
}

## Each panda has their own favorite food and hobby -- shown in the
## action menu and as floating reactions.
const PANDA_FOOD := {
	"male": {"emoji": "🍗", "label": "Hähnchen"},
	"female": {"emoji": "🍵", "label": "Matcha"},
}
const PANDA_PLAY := {
	"male": {"emoji": "⛳", "label": "Golf"},
	"female": {"emoji": "🛍️", "label": "Shopping"},
}

const DEFAULT_PANDA := {"hunger": 80.0, "happiness": 80.0, "sleep": 80.0, "sleeping": false}

var pandas := {
	"male": DEFAULT_PANDA.duplicate(),
	"female": DEFAULT_PANDA.duplicate(),
}

var flower_count := 0
var max_stats_count := 0
var levels_completed := {}

var _last_tick_unix: int = 0
var _all_max_active := false ## true while currently sustained at 100/100/100 for both
var _tick_accum := 0.0
var _pending_note_ids: Array = []

func _ready() -> void:
	var now := int(Time.get_unix_time_from_system())
	load_game()
	if _last_tick_unix > 0:
		_apply_offline_decay(float(now - _last_tick_unix))
	_last_tick_unix = now
	call_deferred("_post_load")

func _post_load() -> void:
	# Restore previously unlocked notes first (silently), then let LoveNotes
	# re-evaluate everything so criteria added later unlock retroactively.
	for id in _pending_note_ids:
		LoveNotes.unlock(id, false)
	_pending_note_ids.clear()
	LoveNotes.recheck_all()

func _notification(what: int) -> void:
	# Mobile apps get killed without warning -- persist on backgrounding.
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()

func _process(delta: float) -> void:
	_tick_accum += delta
	if _tick_accum < 1.0:
		return
	_tick_accum = 0.0
	var now := int(Time.get_unix_time_from_system())
	var elapsed := float(now - _last_tick_unix)
	if elapsed <= 0.0:
		return
	_last_tick_unix = now
	_advance_needs(elapsed)

func _advance_needs(elapsed: float) -> void:
	for panda_id in pandas.keys():
		var p: Dictionary = pandas[panda_id]
		if p.sleeping:
			p.sleep = minf(100.0, p.sleep + SLEEP_RESTORE_PER_SECOND * elapsed)
			p.hunger = maxf(0.0, p.hunger - DECAY_PER_SECOND.hunger * elapsed * 0.3)
			if p.sleep >= 100.0:
				p.sleeping = false ## fully rested pandas wake up on their own
		else:
			p.hunger = maxf(0.0, p.hunger - DECAY_PER_SECOND.hunger * elapsed)
			p.sleep = maxf(0.0, p.sleep - DECAY_PER_SECOND.sleep * elapsed)
		p.happiness = maxf(0.0, p.happiness - DECAY_PER_SECOND.happiness * elapsed)
		needs_changed.emit(panda_id)
	_check_max_stats()

func _apply_offline_decay(elapsed: float) -> void:
	if elapsed < 60.0:
		return
	var capped := minf(elapsed, OFFLINE_MAX_SECONDS)
	_advance_needs(capped)
	for panda_id in pandas.keys():
		var p: Dictionary = pandas[panda_id]
		p.hunger = maxf(p.hunger, OFFLINE_FLOOR)
		p.happiness = maxf(p.happiness, OFFLINE_FLOOR)
		p.sleep = maxf(p.sleep, OFFLINE_FLOOR)

## Counts a "perfect moment" once whenever both pandas transition INTO
## having all three needs at 100% together. Won't recount while they stay
## there -- only after dropping below max and climbing back up again.
func _check_max_stats() -> void:
	var all_max := true
	for panda_id in pandas.keys():
		var p: Dictionary = pandas[panda_id]
		if p.hunger < 100.0 or p.happiness < 100.0 or p.sleep < 100.0:
			all_max = false
			break
	if all_max and not _all_max_active:
		_all_max_active = true
		max_stats_count += 1
		max_stats_reached.emit(max_stats_count)
		save_game()
	elif not all_max:
		_all_max_active = false

func feed(panda_id: String) -> void:
	if not pandas.has(panda_id):
		return
	var p: Dictionary = pandas[panda_id]
	p.hunger = minf(100.0, p.hunger + FEED_RESTORE)
	p.happiness = minf(100.0, p.happiness + 5.0)
	needs_changed.emit(panda_id)
	_check_max_stats()
	save_game()

func play_with(panda_id: String) -> void:
	if not pandas.has(panda_id):
		return
	var p: Dictionary = pandas[panda_id]
	p.happiness = minf(100.0, p.happiness + PLAY_RESTORE)
	p.sleep = maxf(0.0, p.sleep - 5.0)
	needs_changed.emit(panda_id)
	_check_max_stats()
	save_game()

## A kiss between the two pandas nudges all three needs for BOTH of them
## at once -- smaller than a dedicated feed/play/sleep top-up each, but a
## sweet gesture that makes the whole couple happy.
func kiss_both() -> void:
	for panda_id in pandas.keys():
		var p: Dictionary = pandas[panda_id]
		p.hunger = minf(100.0, p.hunger + KISS_RESTORE)
		p.happiness = minf(100.0, p.happiness + KISS_RESTORE)
		p.sleep = minf(100.0, p.sleep + KISS_RESTORE)
		needs_changed.emit(panda_id)
	_check_max_stats()
	save_game()

func set_sleeping(panda_id: String, sleeping: bool) -> void:
	if not pandas.has(panda_id):
		return
	pandas[panda_id].sleeping = sleeping
	needs_changed.emit(panda_id)
	_check_max_stats()
	save_game()

func add_flowers(amount: int) -> void:
	flower_count += amount
	flowers_changed.emit(flower_count)
	save_game()

func mark_level_completed(level_id: String) -> void:
	levels_completed[level_id] = true
	save_game()

func is_level_completed(level_id: String) -> bool:
	return levels_completed.get(level_id, false)

func save_game() -> void:
	var data := {
		"pandas": pandas,
		"flower_count": flower_count,
		"max_stats_count": max_stats_count,
		"all_max_active": _all_max_active,
		"levels_completed": levels_completed,
		"last_tick_unix": _last_tick_unix,
		"unlocked_notes": LoveNotes.get_unlocked_ids(),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var content := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(content)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var saved_pandas: Dictionary = parsed.get("pandas", {})
	for panda_id in pandas.keys():
		if saved_pandas.has(panda_id):
			# Merge so saves from older versions gain newly added fields.
			var merged: Dictionary = DEFAULT_PANDA.duplicate()
			merged.merge(saved_pandas[panda_id], true)
			pandas[panda_id] = merged
	flower_count = int(parsed.get("flower_count", 0))
	max_stats_count = int(parsed.get("max_stats_count", 0))
	_all_max_active = bool(parsed.get("all_max_active", false))
	levels_completed = parsed.get("levels_completed", {})
	_last_tick_unix = int(parsed.get("last_tick_unix", 0))
	_pending_note_ids = parsed.get("unlocked_notes", [])

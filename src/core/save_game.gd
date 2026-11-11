class_name SaveGame
extends RefCounted
## Permanent progress in one of 3 save slots (user://save_slot_N.json, each
## with a _backup.json). Nothing saves by itself on the main screen: the game
## saves at Start (before the stage), when a stage is done, from the gear menu,
## and on "Save before leaving?". Not an autoload (like GameSettings), so tests and -s scripts work.

signal changed

const VERSION := 1
const SLOTS := 3
const DEFAULT_PREFIX := "user://save_slot_"
const CLASSIC := &"classic"
## The skill Senna teaches in Act 1: its first level is in the tree once Act 1
## is cleared.
const ACT_1_SKILL := &"skill_e"

static var _instance: SaveGame

var prefix := DEFAULT_PREFIX
## The current slot: every save writes to it. The title screen picks it.
var slot := 1
var essences := Essences.new()
## Evolution Tree levels.
var tree := EvolutionTree.new()
var owned_skins: Array[StringName] = [CLASSIC]
var skin := CLASSIC
## Spell ids on D and F (&"" for none), picked in Journey.
var loadout: Array[StringName] = [&"", &""]
## Endless's map choice in the Journey (a Journey.ENDLESS_MAPS index; 0 is
## Random), so the Journey opens on it again.
var endless_map := EndlessPlan.RANDOM
## Stage ids ("1-1" ... "6-5") cleared at least once.
var cleared: Array[String] = []
## Resolve: stage id -> how many times Lucian fell there, for story stages
## not yet cleared. A stage leaves it when it is cleared.
var defeats := {}
var endless_best := 0
## Endless's milestone waves (EndlessPlan.MILESTONES) already paid, in the
## order they were won.
var endless_milestones: Array[int] = []
## Bosses and mini bosses with a first-time purple reward, by id (some
## before their data files exist).
const BOSS_IDS: Array[String] = ["thresh_1", "akshan", "infernal_drake", "ocean_drake", "elder_dragon", "dark_lucian", "maokai", "elise", "karthus", "karthus_revived", "hecarim", "thresh_final"]

## Boss ids that already gave their first-time purple.
var bosses: Array[String] = []
## Seconds played in this slot (title screen and pauses not counted).
var play_time := 0.0
## Difficulty.EASY ... EXTREME: picked with the new game and fixed after that.
var difficulty := Difficulty.NORMAL
## The End screen was shown in this slot. Until it is, every clear of the
## last stage shows it (a clear saved from its result panel, by closing the
## window, has not seen it yet). A save from before the flag has not.
var ending_seen := false


## The running game's progress: slot 1 until the title screen loads another.
static func instance() -> SaveGame:
	if _instance == null:
		_instance = SaveGame.new()
		_instance.load_slot(1)
	return _instance


func _init(file_prefix := DEFAULT_PREFIX) -> void:
	prefix = file_prefix


func path(of_slot: int) -> String:
	return "%s%d.json" % [prefix, of_slot]


func backup_path(of_slot: int) -> String:
	return "%s%d_backup.json" % [prefix, of_slot]


func slot_exists(of_slot: int) -> bool:
	return FileAccess.file_exists(path(of_slot)) or FileAccess.file_exists(backup_path(of_slot))


## A slot whose files exist but can't be read, neither the main file nor
## its backup: it can't be loaded, only overwritten by a new game.
func slot_broken(of_slot: int) -> bool:
	if not slot_exists(of_slot):
		return false
	for file in [path(of_slot), backup_path(of_slot)]:
		if not _read(file, true).is_empty():
			return false
	return true


## Makes `of_slot` current and loads it: the main file, else its backup.
## False, with a new game in memory, when neither can be read (an empty or
## broken slot): the title screen never loads a broken slot.
func load_slot(of_slot: int) -> bool:
	slot = of_slot
	reset()
	for file in [path(of_slot), backup_path(of_slot)]:
		var data := _read(file)
		if not data.is_empty():
			_apply(data)
			return true
	return false


func save() -> bool:
	return _write(slot)


## Copies the current progress into another slot; the current slot stays.
func copy_to(of_slot: int) -> bool:
	return _write(of_slot)


## A stage is done (cleared, left or failed): the only auto-save.
func finish_stage(result: StringName, stage_id := "") -> bool:
	if result == &"cleared" and stage_id != "" and not stage_id in cleared:
		cleared.append(stage_id)
		defeats.erase(stage_id)
		_update_acts_cleared()
		changed.emit()
	return save()


## The "saved_at" written in `of_slot`, or "" when it has none.
func saved_at(of_slot: int) -> String:
	for file in [path(of_slot), backup_path(of_slot)]:
		var data := _read(file)
		if not data.is_empty():
			return str(data.get("saved_at", ""))
	return ""


## A new game, in memory only.
func reset() -> void:
	essences.from_dict({})
	tree.clear()
	owned_skins = [CLASSIC]
	skin = CLASSIC
	loadout = [&"", &""]
	endless_map = EndlessPlan.RANDOM
	cleared = []
	defeats = {}
	endless_best = 0
	endless_milestones = []
	bosses = []
	play_time = 0.0
	difficulty = Difficulty.NORMAL
	ending_seen = false
	tree.acts_cleared = 0
	changed.emit()


## A new game on `level` (a Difficulty level) in slot `of_slot`, which
## becomes current and is written at once (it replaces what was there). If
## the write fails the slot and the progress held before come back, so
## memory is never left as a half-made new game.
func start_new(of_slot: int, level := Difficulty.NORMAL) -> bool:
	var before := to_dict()
	var before_slot := slot
	slot = of_slot
	reset()
	difficulty = level if Difficulty.is_level(level) else Difficulty.NORMAL
	if save():
		return true
	_apply(before)
	slot = before_slot
	changed.emit()
	return false


func any_slot_exists() -> bool:
	for n in range(1, SLOTS + 1):
		if slot_exists(n):
			return true
	return false


## A boss (or mini boss) was beaten: the purple due (`first` the first time,
## `repeat` after), and it is marked as paid. The caller adds the essence.
## A boss missing from BOSS_IDS warns: loading drops it from `bosses`.
func award_boss(id: String, first: int, repeat: int) -> int:
	if not id in BOSS_IDS:
		push_warning("Boss %s is not in SaveGame.BOSS_IDS: its first-time purple comes back after a reload" % id)
	if id in bosses:
		return repeat
	bosses.append(id)
	changed.emit()
	return first


## Lucian fell on `stage_id`: counted for a story stage not yet cleared
## (Resolve), in memory (the stage-done save writes it).
func record_defeat(stage_id: String) -> void:
	if not Journey.is_stage_id(stage_id) or stage_id in cleared:
		return
	defeats[stage_id] = defeats_on(stage_id) + 1
	changed.emit()


## How many times Lucian fell on `stage_id` before clearing it; 0 once it is
## cleared.
func defeats_on(stage_id: String) -> int:
	return defeats.get(stage_id, 0)


## An Endless run has cleared `waves`: kept when it beats the best, in memory
## (the next save writes it). True for a new best.
func record_endless(waves: int) -> bool:
	if waves <= endless_best:
		return false
	endless_best = waves
	changed.emit()
	return true


## An Endless run has won wave `w`: true the first time the save wins a
## milestone wave (EndlessPlan.MILESTONES), which is then marked as paid in
## memory (the next save writes it). The caller adds the essence.
func claim_endless_milestone(w: int) -> bool:
	if not EndlessPlan.MILESTONES.has(w) or w in endless_milestones:
		return false
	endless_milestones.append(w)
	changed.emit()
	return true


## Debug: every boss gives its first-time purple again.
func forget_bosses() -> void:
	bosses = []
	changed.emit()


## Seconds played in this slot. Game adds to it; nothing saves by itself.
func add_play_time(seconds: float) -> void:
	play_time += maxf(seconds, 0.0)


## The play time written in `of_slot` (main file, else backup), in whole seconds.
func play_time_of(of_slot: int) -> int:
	for file in [path(of_slot), backup_path(of_slot)]:
		var data := _read(file)
		if not data.is_empty():
			var seconds: Variant = data.get("play_time", 0)
			return maxi(int(seconds), 0) if (seconds is int or seconds is float) else 0
	return 0


## "1h 23m", or "23m" under an hour.
static func play_time_text(seconds: int) -> String:
	var minutes := seconds / 60
	return "%dh %02dm" % [minutes / 60, minutes % 60] if minutes >= 60 else "%dm" % minutes


## Debug: replaces the cleared stages (unknown ids are dropped). A cleared
## stage's defeats go.
func set_cleared(ids: Array[String]) -> void:
	cleared = []
	for id in ids:
		if Journey.is_stage_id(id) and not id in cleared:
			cleared.append(id)
			defeats.erase(id)
	_update_acts_cleared()
	changed.emit()


## Keeps the tree's acts cleared in step. When Act 1 becomes cleared, Lucian
## knows E (Senna taught him): its first level is put in the tree, free. A
## tree reset takes it back like any level, and it is free to buy again.
func _update_acts_cleared() -> void:
	var before := tree.acts_cleared
	tree.acts_cleared = Journey.acts_cleared(cleared)
	if before < 1 and tree.acts_cleared >= 1 and tree.level(ACT_1_SKILL) == 0:
		tree.buy(ACT_1_SKILL, essences)


## Puts spell `id` on D (0) or F (1); if it was on the other key, they swap.
func set_loadout(index: int, id: StringName) -> void:
	if id != &"" and loadout[1 - index] == id:
		loadout[1 - index] = loadout[index]
	loadout[index] = id
	changed.emit()


## Chooses Endless's map (a Journey.ENDLESS_MAPS index; anything else is
## Random), in memory: the next save writes it (Start makes one). It emits no
## `changed`, so the Journey doesn't refresh for a chip it already shows.
func set_endless_map(index: int) -> void:
	endless_map = index if index >= 0 and index < Journey.ENDLESS_MAPS.size() else EndlessPlan.RANDOM


## Buys skin `id` with purple essence (it is not equipped). False when it is
## unknown, already owned or too expensive.
func buy_skin(id: StringName) -> bool:
	var data := Skins.find(id)
	if data.id != id or id in owned_skins or not essences.spend(0, 0, data.cost):
		return false
	owned_skins.append(id)
	changed.emit()
	return true


## Equips an owned skin. False when it is not owned.
func equip_skin(id: StringName) -> bool:
	if not id in owned_skins:
		return false
	skin = id
	changed.emit()
	return true


func to_dict() -> Dictionary:
	return {
		"version": VERSION,
		"saved_at": Time.get_datetime_string_from_system(false, true),
		"essences": essences.to_dict(),
		"tree": tree.to_dict(),
		"skins": {"owned": owned_skins.map(func(id: StringName) -> String: return String(id)), "equipped": String(skin)},
		"loadout": loadout.map(func(id: StringName) -> String: return String(id)),
		"endless_map": endless_map,
		"cleared": cleared.duplicate(),
		"defeats": defeats.duplicate(),
		"endless_best": endless_best,
		"endless_milestones": endless_milestones.duplicate(),
		"bosses": bosses.duplicate(),
		"play_time": int(play_time),
		"difficulty": Difficulty.KEYS[difficulty],
		"ending_seen": ending_seen,
	}


## Writes `<file>.tmp` first. Once it is written, the file being replaced
## becomes the backup (only when it still reads, so a broken file never
## replaces a good backup), then the temp file takes its place. On any
## failure the old file and backup stay as they were.
func _write(of_slot: int) -> bool:
	var file_path := path(of_slot)
	var temp_path := file_path + ".tmp"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return _write_failed(file_path, temp_path)
	var written := file.store_string(JSON.stringify(to_dict(), "\t")) and file.get_error() == OK
	file.close()
	if not written:
		return _write_failed(file_path, temp_path)
	var main := ProjectSettings.globalize_path(file_path)
	if not _read(file_path).is_empty() and DirAccess.copy_absolute(main, ProjectSettings.globalize_path(backup_path(of_slot))) != OK:
		return _write_failed(file_path, temp_path)
	# Replaces the old file (checked on Windows too).
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), main) != OK:
		return _write_failed(file_path, temp_path)
	return true


func _write_failed(file_path: String, temp_path: String) -> bool:
	push_warning("Could not save to %s" % file_path)
	if FileAccess.file_exists(temp_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
	return false


## The file's data, or {} when it is missing or broken (with a warning,
## unless `quiet`).
func _read(file_path: String, quiet := false) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(file_path)) != OK or not json.data is Dictionary:
		if not quiet:
			push_warning("Save file %s is broken" % file_path)
		return {}
	return json.data


## Each key is type-checked and falls back to the new-game value. Unknown
## skin, spell and stage ids are dropped.
func _apply(data: Dictionary) -> void:
	var saved_tree: Variant = data.get("tree", {})
	tree.from_dict(saved_tree if saved_tree is Dictionary else {})
	var saved_essences: Variant = data.get("essences", {})
	essences.from_dict(saved_essences if saved_essences is Dictionary else {})
	var skins: Variant = data.get("skins", {})
	var skin_data: Dictionary = skins if skins is Dictionary else {}
	var owned: Array[StringName] = [CLASSIC]
	var saved_owned: Variant = skin_data.get("owned", [])
	if saved_owned is Array:
		for id: Variant in saved_owned:
			if id is String and Skins.find(StringName(id)).id == StringName(id) and not StringName(id) in owned:
				owned.append(StringName(id))
	owned_skins = owned
	var equipped: Variant = skin_data.get("equipped", "")
	skin = StringName(equipped) if equipped is String and StringName(equipped) in owned else CLASSIC
	# Each key keeps a known spell id; anything else, or F repeating D, is none.
	var saved_loadout: Variant = data.get("loadout", [])
	loadout = [&"", &""]
	if saved_loadout is Array and saved_loadout.size() == 2:
		for i in 2:
			var id: Variant = saved_loadout[i]
			if id is String and StringName(id) in StageSetup.SPELL_IDS and not StringName(id) in loadout:
				loadout[i] = StringName(id)
	# A whole number in range; anything else, or a save from before the choice
	# was kept, is Random.
	var map: Variant = data.get("endless_map", EndlessPlan.RANDOM)
	var whole := (map is int or map is float) and float(map) == float(int(map))
	set_endless_map(int(map) if whole else EndlessPlan.RANDOM)
	cleared = []
	var saved_cleared: Variant = data.get("cleared", [])
	if saved_cleared is Array:
		for id: Variant in saved_cleared:
			if id is String and Journey.is_stage_id(id) and not id in cleared:
				cleared.append(id)
	# A whole count, 1 or more, for each story stage not yet cleared; a save
	# from before Resolve has none.
	defeats = {}
	var saved_defeats: Variant = data.get("defeats", {})
	if saved_defeats is Dictionary:
		for id: Variant in saved_defeats:
			var count: Variant = saved_defeats[id]
			var counted := (count is int or count is float) and float(count) == float(int(count)) and int(count) > 0
			if id is String and Journey.is_stage_id(id) and not id in cleared and counted:
				defeats[id] = int(count)
	var best: Variant = data.get("endless_best", 0)
	endless_best = maxi(int(best), 0) if (best is int or best is float) else 0
	# Each milestone wave once, as a whole number; a save from before the
	# milestones has none paid.
	endless_milestones = []
	var saved_milestones: Variant = data.get("endless_milestones", [])
	if saved_milestones is Array:
		for w: Variant in saved_milestones:
			if (w is int or w is float) and float(w) == float(int(w)) and EndlessPlan.MILESTONES.has(int(w)) and not int(w) in endless_milestones:
				endless_milestones.append(int(w))
	bosses = []
	var saved_bosses: Variant = data.get("bosses", [])
	if saved_bosses is Array:
		for id: Variant in saved_bosses:
			if id is String and id in BOSS_IDS and not id in bosses:
				bosses.append(id)
	var seconds: Variant = data.get("play_time", 0)
	play_time = maxf(float(seconds), 0.0) if (seconds is int or seconds is float) else 0.0
	# A save from before difficulties plays on Normal.
	difficulty = Difficulty.from_key(data.get("difficulty", ""))
	var seen: Variant = data.get("ending_seen", false)
	ending_seen = seen if seen is bool else false
	tree.acts_cleared = Journey.acts_cleared(cleared)
	changed.emit()

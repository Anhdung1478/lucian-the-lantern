class_name SaveGame
extends RefCounted
## Permanent progress in one of 3 save slots (user://save_slot_N.json, each
## with a _backup.json). Nothing saves by itself on the main screen: the game
## saves when a stage is done, from the gear menu, and on "Save before
## leaving?". Not an autoload (like GameSettings), so tests and -s scripts work.

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
## Stage ids ("1-1" ... "6-5") cleared at least once.
var cleared: Array[String] = []
var endless_best := 0
## Bosses and mini bosses with a first-time purple reward, by id (some
## before their data files exist).
const BOSS_IDS: Array[String] = ["thresh_1", "akshan", "infernal_drake", "ocean_drake", "elder_dragon", "dark_lucian", "maokai", "elise", "karthus"]

## Boss ids that already gave their first-time purple.
var bosses: Array[String] = []
## Seconds played in this slot (title screen and pauses not counted).
var play_time := 0.0


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


## Makes `of_slot` current and loads it: the main file, else its backup,
## else a new game.
func load_slot(of_slot: int) -> void:
	slot = of_slot
	reset()
	for file in [path(of_slot), backup_path(of_slot)]:
		var data := _read(file)
		if not data.is_empty():
			_apply(data)
			return


func save() -> bool:
	return _write(slot)


## Copies the current progress into another slot; the current slot stays.
func copy_to(of_slot: int) -> bool:
	return _write(of_slot)


## A stage is done (cleared, left or failed): the only auto-save.
func finish_stage(result: StringName, stage_id := "") -> bool:
	if result == &"cleared" and stage_id != "" and not stage_id in cleared:
		cleared.append(stage_id)
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
	cleared = []
	endless_best = 0
	bosses = []
	play_time = 0.0
	tree.acts_cleared = 0
	changed.emit()


## A new game in slot `of_slot`, which becomes current and is written at
## once (it replaces what was there).
func start_new(of_slot: int) -> bool:
	slot = of_slot
	reset()
	return save()


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


## Debug: replaces the cleared stages (unknown ids are dropped).
func set_cleared(ids: Array[String]) -> void:
	cleared = []
	for id in ids:
		if Journey.is_stage_id(id) and not id in cleared:
			cleared.append(id)
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
		"cleared": cleared.duplicate(),
		"endless_best": endless_best,
		"bosses": bosses.duplicate(),
		"play_time": int(play_time),
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


func _read(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(file_path)) != OK or not json.data is Dictionary:
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
	cleared = []
	var saved_cleared: Variant = data.get("cleared", [])
	if saved_cleared is Array:
		for id: Variant in saved_cleared:
			if id is String and Journey.is_stage_id(id) and not id in cleared:
				cleared.append(id)
	var best: Variant = data.get("endless_best", 0)
	endless_best = maxi(int(best), 0) if (best is int or best is float) else 0
	bosses = []
	var saved_bosses: Variant = data.get("bosses", [])
	if saved_bosses is Array:
		for id: Variant in saved_bosses:
			if id is String and id in BOSS_IDS and not id in bosses:
				bosses.append(id)
	var seconds: Variant = data.get("play_time", 0)
	play_time = maxf(float(seconds), 0.0) if (seconds is int or seconds is float) else 0.0
	tree.acts_cleared = Journey.acts_cleared(cleared)
	changed.emit()

class_name GameSettings
extends RefCounted
## The player's settings: volumes, graphics, gameplay options and key
## bindings. Saved to user://settings.json (shared by every save slot) on
## every change, with a "version" field. Missing or unknown entries fall back
## to the defaults, and a broken file loads as all defaults.
##
## Not an autoload: the game uses the shared instance(); tests make their own
## with a scratch path. Nothing touches the engine until an apply_* call.

signal changed(key: StringName)

const VERSION := 1
const DEFAULT_PATH := "user://settings.json"
const DEFAULTS := {
	&"master_volume": 80,
	&"music_volume": 70,
	&"sfx_volume": 80,
	## "windowed", "borderless" or "fullscreen".
	&"window_mode": "windowed",
	&"vsync": true,
	## 0 is unlimited.
	&"max_fps": 0,
	## "low", "medium" or "high".
	&"quality": "high",
	&"show_fps": false,
	&"queue_casts": true,
}
const WINDOW_MODES := ["windowed", "borderless", "fullscreen"]
const QUALITIES := ["low", "medium", "high"]
const FPS_CAPS := [30, 60, 120, 144, 0]
## Actions the player can rebind, in the order the Controls tab lists them.
## ESC (open_menu) and the F3 + Q debug toggle stay fixed.
const REBINDABLE: Array[StringName] = [
	&"move", &"attack", &"attack_move",
	&"skill_q", &"skill_w", &"skill_e", &"skill_r",
	&"summoner_d", &"summoner_f",
	&"item_1", &"item_2", &"item_3", &"item_4", &"item_5", &"item_6",
	&"open_backpack", &"toggle_stats", &"toggle_camera",
]
const ACTION_NAMES := {
	&"move": "Move", &"attack": "Attack", &"attack_move": "Attack-move",
	&"skill_q": "Skill Q", &"skill_w": "Skill W", &"skill_e": "Skill E", &"skill_r": "Skill R",
	&"summoner_d": "Summoner spell 1", &"summoner_f": "Summoner spell 2",
	&"item_1": "Item slot 1", &"item_2": "Item slot 2", &"item_3": "Item slot 3",
	&"item_4": "Item slot 4", &"item_5": "Item slot 5", &"item_6": "Item slot 6",
	&"open_backpack": "Backpack", &"toggle_stats": "Stats panel", &"toggle_camera": "Camera mode",
}
const MOUSE_LABELS := {
	MOUSE_BUTTON_LEFT: "LMB", MOUSE_BUTTON_RIGHT: "RMB", MOUSE_BUTTON_MIDDLE: "MMB",
	MOUSE_BUTTON_XBUTTON1: "Mouse 4", MOUSE_BUTTON_XBUTTON2: "Mouse 5",
	MOUSE_BUTTON_WHEEL_UP: "Wheel up", MOUSE_BUTTON_WHEEL_DOWN: "Wheel down",
}
const MSAA := {"low": Viewport.MSAA_DISABLED, "medium": Viewport.MSAA_2X, "high": Viewport.MSAA_4X}

static var _instance: GameSettings

var path := DEFAULT_PATH

var _values := {}
## Action -> InputEvent.
var _bindings := {}


## The game's shared settings, loaded on first use.
static func instance() -> GameSettings:
	if _instance == null:
		_instance = GameSettings.new()
	return _instance


func _init(file_path := DEFAULT_PATH) -> void:
	path = file_path
	_values = DEFAULTS.duplicate()
	_bindings = default_bindings()
	_load()


func get_value(key: StringName) -> Variant:
	return _values.get(key)


## Stores, saves and announces a setting. Unknown keys are ignored.
func set_value(key: StringName, value: Variant) -> void:
	if not DEFAULTS.has(key):
		return
	_values[key] = value
	save()
	changed.emit(key)


## Effects that cost the most (dash trails, muzzle flashes) are skipped on low.
func low_effects() -> bool:
	return _values[&"quality"] == "low"


func binding(action: StringName) -> InputEvent:
	return _bindings.get(action)


## The key or mouse button shown for an action, e.g. "Q" or "RMB".
func key_label(action: StringName) -> String:
	return event_label(binding(action))


## Binds `event` to `action`. An action that had the same input gets the
## action's old one, so no two actions ever share an input.
func rebind(action: StringName, event: InputEvent) -> void:
	var clean := _clean(event)
	for other: StringName in _bindings:
		if other != action and _same_input(_bindings[other], clean):
			_bindings[other] = _bindings[action]
	_bindings[action] = clean
	save()
	changed.emit(&"bindings")


func reset_bindings() -> void:
	_bindings = default_bindings()
	save()
	changed.emit(&"bindings")


func save() -> void:
	var saved_bindings := {}
	for action: StringName in _bindings:
		saved_bindings[String(action)] = event_to_dict(_bindings[action])
	var saved_values := {}
	for key: StringName in _values:
		saved_values[String(key)] = _values[key]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("Could not save settings to %s" % path)
		return
	file.store_string(JSON.stringify({"version": VERSION, "values": saved_values, "bindings": saved_bindings}, "\t"))


## Pushes every setting into the engine.
func apply() -> void:
	apply_audio()
	apply_input()
	apply_display()


func apply_audio() -> void:
	for pair in [["Master", &"master_volume"], ["Music", &"music_volume"], ["SFX", &"sfx_volume"]]:
		var bus := AudioServer.get_bus_index(pair[0])
		if bus < 0:
			continue
		var volume: float = clampf(float(_values[pair[1]]) / 100.0, 0.0, 1.0)
		AudioServer.set_bus_mute(bus, volume <= 0.0)
		AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(volume, 0.0001)))


func apply_input() -> void:
	for action: StringName in _bindings:
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, _bindings[action])


func apply_display() -> void:
	if DisplayServer.get_name() == "headless":
		return
	match _values[&"window_mode"]:
		"fullscreen":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		"borderless":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		_:
			# A maximized window counts as windowed and stays as it is.
			if DisplayServer.window_get_mode() not in [DisplayServer.WINDOW_MODE_WINDOWED, DisplayServer.WINDOW_MODE_MAXIMIZED]:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if _values[&"vsync"] else DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = int(_values[&"max_fps"])
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		tree.root.msaa_2d = MSAA.get(_values[&"quality"], Viewport.MSAA_4X)


## The bindings in project.godot, one per action.
static func default_bindings() -> Dictionary:
	var result := {}
	for action in REBINDABLE:
		var setting: Dictionary = ProjectSettings.get_setting("input/%s" % action, {})
		var events: Array = setting.get("events", [])
		if not events.is_empty():
			result[action] = _clean(events[0])
	return result


static func event_label(event: InputEvent) -> String:
	if event is InputEventKey:
		var code := (event as InputEventKey).physical_keycode
		if code == KEY_NONE:
			code = (event as InputEventKey).keycode
		return OS.get_keycode_string(code)
	if event is InputEventMouseButton:
		var index := (event as InputEventMouseButton).button_index
		return MOUSE_LABELS.get(index, "Mouse %d" % index)
	return "-"


static func event_to_dict(event: InputEvent) -> Dictionary:
	if event is InputEventMouseButton:
		return {"type": "mouse", "button": (event as InputEventMouseButton).button_index}
	var key := event as InputEventKey
	return {"type": "key", "code": key.physical_keycode if key else 0}


static func dict_to_event(data: Dictionary) -> InputEvent:
	if data.get("type") == "mouse":
		var mouse := InputEventMouseButton.new()
		mouse.button_index = int(data.get("button", MOUSE_BUTTON_LEFT)) as MouseButton
		return mouse
	if data.get("type") == "key" and int(data.get("code", 0)) != 0:
		var key := InputEventKey.new()
		key.physical_keycode = int(data.code) as Key
		return key
	return null


func _load() -> void:
	if not FileAccess.file_exists(path):
		return
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not json.data is Dictionary:
		push_warning("Settings file %s is broken; using defaults" % path)
		return
	var data: Dictionary = json.data
	var values: Dictionary = data.get("values", {})
	for key: String in values:
		var name := StringName(key)
		if DEFAULTS.has(name):
			var value: Variant = values[key]
			# JSON numbers load as floats.
			if DEFAULTS[name] is int and value is float:
				value = int(value)
			if typeof(value) == typeof(DEFAULTS[name]):
				_values[name] = value
	var bindings: Dictionary = data.get("bindings", {})
	for key: String in bindings:
		var action := StringName(key)
		if REBINDABLE.has(action) and bindings[key] is Dictionary:
			var event := dict_to_event(bindings[key])
			if event:
				_bindings[action] = event


## A plain copy of the input: only the key or button, no modifiers, so a
## binding never depends on Ctrl or Shift (Ctrl + skill is the rank-up).
static func _clean(event: InputEvent) -> InputEvent:
	if event is InputEventMouseButton:
		var mouse := InputEventMouseButton.new()
		mouse.button_index = (event as InputEventMouseButton).button_index
		return mouse
	var key := InputEventKey.new()
	var source := event as InputEventKey
	if source:
		key.physical_keycode = source.physical_keycode if source.physical_keycode != KEY_NONE else source.keycode
	return key


static func _same_input(a: InputEvent, b: InputEvent) -> bool:
	if a is InputEventMouseButton and b is InputEventMouseButton:
		return (a as InputEventMouseButton).button_index == (b as InputEventMouseButton).button_index
	if a is InputEventKey and b is InputEventKey:
		return (a as InputEventKey).physical_keycode == (b as InputEventKey).physical_keycode
	return false

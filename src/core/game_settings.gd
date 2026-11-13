class_name GameSettings
extends RefCounted
## The player's settings: volumes, graphics, gameplay options, the camera's
## zoom, the language and key bindings. Saved to user://settings.json (shared by every save slot) on
## every change (a slider being dragged: once, when let go), with a
## "version" field. Missing or unknown entries fall back to the defaults. A
## missing or broken file loads "<path>.tmp" instead, a save whose rename
## failed; with neither, all defaults.
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
	## Window size in windowed mode, "WIDTHxHEIGHT".
	&"resolution": "1600x900",
	&"vsync": true,
	## 0 is unlimited.
	&"max_fps": 0,
	## "low", "medium" or "high".
	&"quality": "high",
	&"show_fps": false,
	&"queue_casts": true,
	## Resolve (Resolve.SETTING): each defeat on a stage makes it a little
	## easier. Off, the defeats are still counted.
	&"resolve": true,
	## Key (action name) -> "indicator" or "normal". Keys not listed use quick
	## cast. See CAST_MODES.
	&"cast_modes": {},
	## The stage camera's view (StageCamera.SETTING): 1.0 is the plain one,
	## less is wider. The mouse wheel sets it; no Settings row does.
	&"camera_zoom": 1.0,
	## The language of the game's text: a code in Lang.CODES.
	&"language": Lang.ENGLISH,
}
const WINDOW_MODES := ["windowed", "borderless", "fullscreen"]
const RESOLUTIONS := ["1280x720", "1366x768", "1600x900", "1920x1080", "2560x1440", "3840x2160"]
const QUALITIES := ["low", "medium", "high"]
const FPS_CAPS := [30, 60, 120, 144, 0]
## "quick" casts on press. "indicator" shows the range while the key is held
## and casts on release. "normal" shows it on press and casts on left-click.
const CAST_MODES := ["quick", "indicator", "normal"]
## Keys that cast toward the cursor, each with its own cast mode.
const CASTABLE: Array[StringName] = [
	&"skill_q", &"skill_w", &"skill_e", &"skill_r",
	&"summoner_d", &"summoner_f",
	&"item_1", &"item_2", &"item_3", &"item_4", &"item_5", &"item_6",
]
## Actions the player can rebind, in the order the Controls tab lists them.
## ESC (open_menu) and the F3 + Q debug toggle stay fixed.
const REBINDABLE: Array[StringName] = [
	&"move", &"attack", &"attack_move",
	&"skill_q", &"skill_w", &"skill_e", &"skill_r",
	&"summoner_d", &"summoner_f",
	&"item_1", &"item_2", &"item_3", &"item_4", &"item_5", &"item_6",
	&"potion_hp", &"potion_mp",
	&"open_backpack", &"toggle_stats", &"toggle_camera", &"center_camera",
]
const ACTION_NAMES := {
	&"move": "Move", &"attack": "Attack", &"attack_move": "Attack-move",
	&"skill_q": "Skill Q", &"skill_w": "Skill W", &"skill_e": "Skill E", &"skill_r": "Skill R",
	&"summoner_d": "Summoner spell 1", &"summoner_f": "Summoner spell 2",
	&"item_1": "Item slot 1", &"item_2": "Item slot 2", &"item_3": "Item slot 3",
	&"item_4": "Item slot 4", &"item_5": "Item slot 5", &"item_6": "Item slot 6",
	&"potion_hp": "Health potion", &"potion_mp": "Mana potion",
	&"open_backpack": "Backpack", &"toggle_stats": "Stats panel (Ctrl: toggle, hold: more)", &"toggle_camera": "Camera mode",
	&"center_camera": "Center camera on Lucian",
}
const MOUSE_LABELS := {
	MOUSE_BUTTON_LEFT: "LMB", MOUSE_BUTTON_RIGHT: "RMB", MOUSE_BUTTON_MIDDLE: "MMB",
	MOUSE_BUTTON_XBUTTON1: "Mouse 4", MOUSE_BUTTON_XBUTTON2: "Mouse 5",
	MOUSE_BUTTON_WHEEL_UP: "Wheel up", MOUSE_BUTTON_WHEEL_DOWN: "Wheel down",
}
## Short forms of key names, for the HUD and backpack where a full name wouldn't fit.
const SHORT_KEY_LABELS := {
	"Backspace": "Bcksp", "Space": "Spc", "Escape": "Esc", "Enter": "Ent", "Delete": "Del",
	"Insert": "Ins", "PageUp": "PgUp", "PageDown": "PgDn", "CapsLock": "Caps",
	"Up": "Up", "Down": "Dn", "Left": "Lt", "Right": "Rt", "QuoteLeft": "`",
	"BracketLeft": "[", "BracketRight": "]", "BackSlash": "\\", "Slash": "/",
	"Kp Multiply": "Num*", "Kp Divide": "Num/", "Kp Subtract": "Num-", "Kp Add": "Num+",
	"Kp Period": "Num.", "Kp Enter": "NumEn",
}
const SHORT_MOUSE_LABELS := {
	MOUSE_BUTTON_LEFT: "LMB", MOUSE_BUTTON_RIGHT: "RMB", MOUSE_BUTTON_MIDDLE: "MMB",
	MOUSE_BUTTON_XBUTTON1: "M4", MOUSE_BUTTON_XBUTTON2: "M5",
	MOUSE_BUTTON_WHEEL_UP: "WhU", MOUSE_BUTTON_WHEEL_DOWN: "WhD",
}
const SHORT_LABEL_MAX := 5
const MSAA := {"low": Viewport.MSAA_DISABLED, "medium": Viewport.MSAA_2X, "high": Viewport.MSAA_4X}

static var _instance: GameSettings
## False forbids every change to the OS window: its mode, size and place.
## The screenshot tool's window sits off-screen and must stay there.
static var owns_window := true

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


## Stores, saves and announces a setting. Unknown keys are ignored. With
## `save_now` false it is stored and announced (so it applies at once) but
## not saved: a slider's steps while it is dragged, saved once when it is
## let go (save()).
func set_value(key: StringName, value: Variant, save_now := true) -> void:
	if not DEFAULTS.has(key):
		return
	_values[key] = value
	if save_now:
		save()
	changed.emit(key)


func cast_mode(action: StringName) -> String:
	return (_values[&"cast_modes"] as Dictionary).get(String(action), "quick")


func set_cast_mode(action: StringName, mode: String) -> void:
	# A copy, so the default dictionary is never changed.
	var modes: Dictionary = (_values[&"cast_modes"] as Dictionary).duplicate()
	if mode == "quick":
		modes.erase(String(action))
	else:
		modes[String(action)] = mode
	set_value(&"cast_modes", modes)


## Effects that cost the most (dash trails, muzzle flashes) are skipped on low.
func low_effects() -> bool:
	return _values[&"quality"] == "low"


func binding(action: StringName) -> InputEvent:
	return _bindings.get(action)


## The key or mouse button shown for an action, e.g. "Q" or "RMB".
func key_label(action: StringName) -> String:
	return event_label(binding(action))


## The short name shown in tight spots (HUD slots and their hover cards,
## backpack cells), e.g. "M4". Sentences use key_label's full name.
func short_key_label(action: StringName) -> String:
	return short_label(binding(action))


## Binds `event` to `action`. An action that had the same input gets the
## action's old one (none if it had none), so no two actions ever share an
## input.
func rebind(action: StringName, event: InputEvent) -> void:
	var clean := _clean(event)
	for other: StringName in _bindings.keys():
		if other != action and _same_input(_bindings[other], clean):
			if _bindings.has(action):
				_bindings[other] = _bindings[action]
			else:
				_bindings.erase(other)
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
	# Written to "<path>.tmp" first, then renamed over the old file, so a crash
	# mid-write leaves the old settings (and key bindings) whole.
	var temp_path := _temp_path()
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		# Not opened, so not ours to remove.
		_save_failed(false)
		return
	var written := file.store_string(JSON.stringify({"version": VERSION, "values": saved_values, "bindings": saved_bindings}, "\t")) \
		and file.get_error() == OK
	file.close()
	if not written:
		_save_failed(true)
	elif DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), ProjectSettings.globalize_path(path)) != OK:
		# The rename can fail with the old file already gone (on Windows it is
		# removed first): the whole temp file stays, and _load reads it.
		_save_failed(false)


## Warns. A half-written temp file (`drop_temp`) goes; any other stays: after
## a failed rename it may be the only whole copy.
func _save_failed(drop_temp: bool) -> void:
	push_warning("Could not save settings to %s" % path)
	if drop_temp and FileAccess.file_exists(_temp_path()):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_temp_path()))


func _temp_path() -> String:
	return path + ".tmp"


## Pushes every setting into the engine, the window's size and place too.
func apply() -> void:
	apply_engine()
	apply_resolution()


## Every setting but the window's size and place (apply_resolution): audio,
## input, display and the language. A stage under the Game uses this, so
## starting one never un-maximizes, resizes or re-centers the window.
func apply_engine() -> void:
	apply_audio()
	apply_input()
	apply_display()
	apply_language()


## Turns the game's text to the language chosen. Screens already built keep
## their text; the Game builds the title or the main screen again.
func apply_language() -> void:
	Lang.use(_values[&"language"])


func apply_audio() -> void:
	for pair in [["Master", &"master_volume"], ["Music", &"music_volume"], ["SFX", &"sfx_volume"]]:
		var bus := AudioServer.get_bus_index(pair[0])
		if bus < 0:
			continue
		var volume: float = clampf(float(_values[pair[1]]) / 100.0, 0.0, 1.0)
		AudioServer.set_bus_mute(bus, volume <= 0.0)
		AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(volume, 0.0001)))


## An action without a binding gets no input at all.
func apply_input() -> void:
	for action in REBINDABLE:
		InputMap.action_erase_events(action)
		if _bindings.has(action):
			InputMap.action_add_event(action, _bindings[action])


func apply_display() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if owns_window:
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


## Sizes and centers the window in windowed mode (a maximized window is
## restored first). A size too big for the screen shrinks to fit, title bar
## included. Fullscreen modes keep the screen's own size.
func apply_resolution() -> void:
	if not owns_window or DisplayServer.get_name() == "headless" or _values[&"window_mode"] != "windowed":
		return
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var size := parse_resolution(_values[&"resolution"])
	if size == Vector2i.ZERO:
		size = parse_resolution(DEFAULTS[&"resolution"])
	size = size.min(max_window_size())
	# Sizes and positions are the inside of the window; center it with its frame.
	var frame := DisplayServer.window_get_size_with_decorations() - DisplayServer.window_get_size()
	var inset := DisplayServer.window_get_position() - DisplayServer.window_get_position_with_decorations()
	var usable := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	DisplayServer.window_set_size(size)
	DisplayServer.window_set_position(usable.position + (usable.size - size - frame) / 2 + inset)


## The biggest window inside its frame (title bar, borders) that fits on the
## screen it is on.
static func max_window_size() -> Vector2i:
	var usable := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	var frame := DisplayServer.window_get_size_with_decorations() - DisplayServer.window_get_size()
	return usable.size - frame


## "1920x1080" -> (1920, 1080); (0, 0) when it isn't a size.
static func parse_resolution(text: String) -> Vector2i:
	var parts := text.split("x")
	if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
		return Vector2i.ZERO
	return Vector2i(int(parts[0]), int(parts[1]))


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


## A short form of `event_label`: "M4" for Mouse 4, "Bcksp" for BackSpace, "Num 1"
## for Kp 1, "[" and "]" for the brackets, "Num+" for the keypad operators, and
## anything else cut to five characters.
static func short_label(event: InputEvent) -> String:
	if event is InputEventMouseButton:
		var index := (event as InputEventMouseButton).button_index
		return SHORT_MOUSE_LABELS.get(index, "M%d" % index)
	var label := event_label(event)
	if SHORT_KEY_LABELS.has(label):
		return SHORT_KEY_LABELS[label]
	if label.begins_with("Kp "):
		return ("Num " + label.substr(3)).left(SHORT_LABEL_MAX)
	return SHORT_KEY_LABELS.get(label, label.left(SHORT_LABEL_MAX))


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


## The file's settings, or the temp file's when the file is missing or
## broken (a save whose rename failed); with neither, the defaults stay.
## A temp file that loads becomes the file again at once, so the next save,
## which writes the temp file first, can't spoil the only whole copy.
func _load() -> void:
	var data := _read(path)
	if data.is_empty():
		data = _read(_temp_path())
		if not data.is_empty():
			DirAccess.rename_absolute(ProjectSettings.globalize_path(_temp_path()), ProjectSettings.globalize_path(path))
	if data.is_empty():
		return
	var values: Dictionary = data.get("values", {})
	for key: String in values:
		var name := StringName(key)
		if DEFAULTS.has(name):
			var value: Variant = values[key]
			# JSON numbers load as floats.
			if DEFAULTS[name] is int and value is float:
				value = int(value)
			if name == &"resolution" and not RESOLUTIONS.has(value):
				continue
			if name == &"language" and not Lang.CODES.has(value):
				continue
			if typeof(value) == typeof(DEFAULTS[name]):
				_values[name] = value
	# Only castable keys with a known mode.
	var modes := {}
	for action: Variant in _values[&"cast_modes"]:
		var mode: Variant = _values[&"cast_modes"][action]
		if action is String and CASTABLE.has(StringName(action)) and mode is String and CAST_MODES.has(mode) and mode != "quick":
			modes[action] = mode
	_values[&"cast_modes"] = modes
	var bindings: Dictionary = data.get("bindings", {})
	for key: String in bindings:
		var action := StringName(key)
		if REBINDABLE.has(action) and bindings[key] is Dictionary:
			var event := dict_to_event(bindings[key])
			if event:
				_bindings[action] = event
	# An action newer than the file keeps its default input only while no
	# saved action uses it, so no two actions ever share one.
	for action in REBINDABLE:
		if bindings.has(String(action)) or not _bindings.has(action):
			continue
		for saved: String in bindings:
			var other := StringName(saved)
			if other != action and _bindings.has(other) and _same_input(_bindings[other], _bindings[action]):
				_bindings.erase(action)
				break


## The settings in `file`, or {} when it is missing or broken (with a
## warning).
func _read(file: String) -> Dictionary:
	if not FileAccess.file_exists(file):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(file)) != OK or not json.data is Dictionary:
		push_warning("Settings file %s is broken" % file)
		return {}
	return json.data


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

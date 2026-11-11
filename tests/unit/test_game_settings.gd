extends GutTest

const PATH := "user://test_settings.json"

var settings: GameSettings


func before_each() -> void:
	_delete()
	settings = GameSettings.new(PATH)


func after_each() -> void:
	_delete()


func _delete() -> void:
	for file in [PATH, PATH + ".tmp"]:
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(file))


func key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	return event


func mouse(index: MouseButton) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = index
	return event


func test_defaults_without_a_file() -> void:
	assert_eq(settings.get_value(&"sfx_volume"), 80)
	assert_eq(settings.get_value(&"queue_casts"), true)
	assert_eq(settings.get_value(&"quality"), "high")
	assert_false(FileAccess.file_exists(PATH), "nothing is written until a change")


func test_default_bindings_come_from_the_project() -> void:
	assert_eq(settings.key_label(&"skill_q"), "Q")
	assert_eq(settings.key_label(&"item_1"), "1")
	assert_eq(settings.key_label(&"move"), "RMB")
	assert_eq(settings.key_label(&"attack"), "LMB")
	assert_eq(settings.key_label(&"center_camera"), "Space")


func test_short_labels_fit_tight_spots() -> void:
	assert_eq(GameSettings.short_label(mouse(MOUSE_BUTTON_XBUTTON1)), "M4")
	assert_eq(GameSettings.short_label(mouse(MOUSE_BUTTON_XBUTTON2)), "M5")
	assert_eq(GameSettings.short_label(mouse(MOUSE_BUTTON_WHEEL_UP)), "WhU")
	assert_eq(GameSettings.short_label(mouse(MOUSE_BUTTON_WHEEL_DOWN)), "WhD")
	assert_eq(GameSettings.short_label(mouse(MOUSE_BUTTON_RIGHT)), "RMB")
	assert_eq(GameSettings.short_label(key(KEY_BACKSPACE)), "Bcksp")
	assert_eq(GameSettings.short_label(key(KEY_SPACE)), "Spc")
	assert_eq(GameSettings.short_label(key(KEY_PAGEDOWN)), "PgDn")
	assert_eq(GameSettings.short_label(key(KEY_KP_1)), "Num 1")
	assert_eq(GameSettings.short_label(key(KEY_DOWN)), "Dn")
	assert_eq(GameSettings.short_label(key(KEY_QUOTELEFT)), "`")
	assert_eq(GameSettings.short_label(key(KEY_Q)), "Q")
	assert_eq(GameSettings.short_label(key(KEY_PRINT)).length(), 5, "long names are cut to 5")
	assert_eq(GameSettings.short_label(null), "-")


func test_short_labels_keep_brackets_slashes_and_keypad_keys_apart() -> void:
	var expected := {
		KEY_BRACKETLEFT: "[", KEY_BRACKETRIGHT: "]", KEY_BACKSLASH: "\\", KEY_SLASH: "/",
		KEY_KP_MULTIPLY: "Num*", KEY_KP_DIVIDE: "Num/", KEY_KP_SUBTRACT: "Num-",
		KEY_KP_ADD: "Num+", KEY_KP_PERIOD: "Num.", KEY_KP_ENTER: "NumEn",
	}
	var seen := {}
	for code in expected:
		var label := GameSettings.short_label(key(code))
		assert_eq(label, expected[code], OS.get_keycode_string(code))
		assert_false(seen.has(label), "%s is its own label" % label)
		seen[label] = true


func test_short_key_label_follows_the_binding_and_key_label_stays_full() -> void:
	settings.rebind(&"skill_e", mouse(MOUSE_BUTTON_XBUTTON1))
	assert_eq(settings.short_key_label(&"skill_e"), "M4")
	assert_eq(settings.key_label(&"skill_e"), "Mouse 4")
	settings.rebind(&"skill_q", key(KEY_BACKSPACE))
	assert_eq(settings.short_key_label(&"skill_q"), "Bcksp")
	assert_eq(settings.key_label(&"skill_q"), "Backspace")


func test_changes_are_saved_with_a_version() -> void:
	watch_signals(settings)
	settings.set_value(&"music_volume", 35)
	assert_signal_emitted_with_parameters(settings, "changed", [&"music_volume"])
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	assert_eq(int(data.version), GameSettings.VERSION)
	assert_eq(GameSettings.new(PATH).get_value(&"music_volume"), 35)


func test_a_save_goes_through_a_temp_file_and_leaves_none() -> void:
	settings.set_value(&"music_volume", 35)
	assert_true(FileAccess.file_exists(PATH))
	assert_false(FileAccess.file_exists(PATH + ".tmp"), "renamed over the file")
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	assert_true(data is Dictionary, "a whole file")
	assert_eq(GameSettings.new(PATH).get_value(&"music_volume"), 35)


func test_a_leftover_temp_file_is_replaced() -> void:
	var file := FileAccess.open(PATH + ".tmp", FileAccess.WRITE)
	file.store_string("{half a fil")
	file.close()
	settings.set_value(&"sfx_volume", 12)
	assert_false(FileAccess.file_exists(PATH + ".tmp"))
	assert_eq(GameSettings.new(PATH).get_value(&"sfx_volume"), 12)


func test_a_failed_save_warns_and_leaves_no_temp_file() -> void:
	var nowhere := GameSettings.new("user://no_such_dir/test_settings.json")
	nowhere.set_value(&"sfx_volume", 12)
	assert_push_warning_count(1)
	assert_false(FileAccess.file_exists("user://no_such_dir/test_settings.json.tmp"))


## Settings with sfx 12 and Q on Backspace, left as `file` alone (the main
## file is moved there).
func _saved_as(file: String) -> void:
	settings.set_value(&"sfx_volume", 12)
	settings.rebind(&"skill_q", key(KEY_BACKSPACE))
	DirAccess.rename_absolute(ProjectSettings.globalize_path(PATH), ProjectSettings.globalize_path(file))
	assert_false(FileAccess.file_exists(PATH))


## B19: a rename that failed with the old file gone left only the temp file:
## its settings load, key bindings and all.
func test_with_only_the_temp_file_left_its_settings_load() -> void:
	_saved_as(PATH + ".tmp")
	var loaded := GameSettings.new(PATH)
	assert_eq(loaded.get_value(&"sfx_volume"), 12)
	assert_eq(loaded.key_label(&"skill_q"), "Backspace")


## The temp file that loaded is the file again, so the next save writes a new
## temp file instead of emptying the only whole copy.
func test_a_temp_file_that_loads_becomes_the_file() -> void:
	_saved_as(PATH + ".tmp")
	var loaded := GameSettings.new(PATH)
	assert_true(FileAccess.file_exists(PATH), "renamed back")
	assert_false(FileAccess.file_exists(PATH + ".tmp"))
	loaded.set_value(&"music_volume", 35)
	var again := GameSettings.new(PATH)
	assert_eq(again.get_value(&"sfx_volume"), 12)
	assert_eq(again.get_value(&"music_volume"), 35)
	assert_eq(again.key_label(&"skill_q"), "Backspace")


func test_a_broken_file_falls_back_to_the_temp_file() -> void:
	_saved_as(PATH + ".tmp")
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("{not json")
	file.close()
	assert_eq(GameSettings.new(PATH).get_value(&"sfx_volume"), 12)
	assert_push_warning_count(1)
	assert_false(FileAccess.file_exists(PATH + ".tmp"), "renamed over the broken file")
	assert_eq(GameSettings.new(PATH).get_value(&"sfx_volume"), 12)
	assert_push_warning_count(1, "the file is whole again")


## A folder in the file's place makes the rename fail: the whole temp file
## stays, and the next load reads it.
func test_a_failed_rename_keeps_the_temp_file() -> void:
	var blocker := ProjectSettings.globalize_path(PATH)
	DirAccess.make_dir_absolute(blocker)
	var inside := FileAccess.open(PATH + "/keep", FileAccess.WRITE)
	inside.store_string("x")
	inside.close()
	settings.set_value(&"sfx_volume", 12)
	DirAccess.remove_absolute(blocker + "/keep")
	DirAccess.remove_absolute(blocker)
	assert_push_warning_count(1)
	assert_true(FileAccess.file_exists(PATH + ".tmp"), "kept")
	assert_eq(GameSettings.new(PATH).get_value(&"sfx_volume"), 12)


func test_loaded_numbers_stay_ints() -> void:
	settings.set_value(&"max_fps", 144)
	assert_typeof(GameSettings.new(PATH).get_value(&"max_fps"), TYPE_INT)


func test_a_broken_file_gives_defaults() -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("{not json")
	file.close()
	assert_eq(GameSettings.new(PATH).get_value(&"sfx_volume"), 80)


func test_unknown_values_are_ignored() -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 1, "values": {"bogus": 3, "sfx_volume": 10}}))
	file.close()
	var loaded := GameSettings.new(PATH)
	assert_eq(loaded.get_value(&"sfx_volume"), 10)
	assert_null(loaded.get_value(&"bogus"))


func test_rebinding_saves_and_loads() -> void:
	settings.rebind(&"skill_q", key(KEY_Z))
	assert_eq(settings.key_label(&"skill_q"), "Z")
	assert_eq(GameSettings.new(PATH).key_label(&"skill_q"), "Z")


func test_rebinding_a_used_key_swaps() -> void:
	settings.rebind(&"skill_q", key(KEY_W))
	assert_eq(settings.key_label(&"skill_q"), "W")
	assert_eq(settings.key_label(&"skill_w"), "Q")


func test_mouse_buttons_can_be_bound() -> void:
	settings.rebind(&"skill_e", mouse(MOUSE_BUTTON_XBUTTON1))
	assert_eq(settings.key_label(&"skill_e"), "Mouse 4")
	var loaded := GameSettings.new(PATH)
	assert_true(loaded.binding(&"skill_e") is InputEventMouseButton)


func test_reset_bindings() -> void:
	settings.rebind(&"skill_q", key(KEY_Z))
	settings.reset_bindings()
	assert_eq(settings.key_label(&"skill_q"), "Q")


func test_only_listed_actions_are_rebindable() -> void:
	assert_false(GameSettings.REBINDABLE.has(&"open_menu"))
	assert_true(GameSettings.REBINDABLE.has(&"open_backpack"))
	for action in GameSettings.REBINDABLE:
		assert_true(InputMap.has_action(action), str(action))
		assert_true(GameSettings.ACTION_NAMES.has(action), str(action))


func test_apply_input_sets_the_input_map() -> void:
	settings.rebind(&"toggle_stats", key(KEY_V))
	settings.apply_input()
	var events := InputMap.action_get_events(&"toggle_stats")
	assert_eq(events.size(), 1)
	assert_eq((events[0] as InputEventKey).physical_keycode, KEY_V)
	settings.reset_bindings()
	settings.apply_input()
	assert_eq((InputMap.action_get_events(&"toggle_stats")[0] as InputEventKey).physical_keycode, KEY_C)


func test_the_test_run_uses_a_scratch_settings_file() -> void:
	# Set by tests/pre_run.gd, so the player's settings never change the tests.
	assert_eq(GameSettings.instance().path, "user://test_run_settings.json")


func test_resolution_defaults_to_1600x900() -> void:
	assert_eq(settings.get_value(&"resolution"), "1600x900")


func test_parse_resolution() -> void:
	assert_eq(GameSettings.parse_resolution("1920x1080"), Vector2i(1920, 1080))
	assert_eq(GameSettings.parse_resolution("big"), Vector2i.ZERO)


func test_resolution_round_trip_and_unknown_sizes_fall_back() -> void:
	settings.set_value(&"resolution", "1920x1080")
	assert_eq(GameSettings.new(PATH).get_value(&"resolution"), "1920x1080")
	settings.set_value(&"resolution", "123x45")
	assert_eq(GameSettings.new(PATH).get_value(&"resolution"), "1600x900")


func test_a_new_action_never_takes_a_key_an_older_file_already_uses() -> void:
	# A Phase 3 file had no center_camera, and here Space is on the camera toggle.
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 1, "values": {},
		"bindings": {"toggle_camera": {"type": "key", "code": KEY_SPACE}}}))
	file.close()
	var loaded := GameSettings.new(PATH)
	assert_eq(loaded.key_label(&"toggle_camera"), "Space")
	assert_eq(loaded.key_label(&"center_camera"), "-")
	loaded.apply_input()
	assert_eq(InputMap.action_get_events(&"center_camera").size(), 0)
	settings.apply_input()


func test_binding_an_unbound_action_takes_the_key_from_its_owner() -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 1, "values": {},
		"bindings": {"toggle_camera": {"type": "key", "code": KEY_SPACE}}}))
	file.close()
	var loaded := GameSettings.new(PATH)
	loaded.rebind(&"center_camera", key(KEY_SPACE))
	assert_eq(loaded.key_label(&"center_camera"), "Space")
	assert_eq(loaded.key_label(&"toggle_camera"), "-")


func test_cast_modes_default_to_quick_cast() -> void:
	for action in GameSettings.CASTABLE:
		assert_eq(settings.cast_mode(action), "quick", str(action))


func test_cast_modes_are_saved_per_key() -> void:
	settings.set_cast_mode(&"skill_q", "normal")
	settings.set_cast_mode(&"item_1", "indicator")
	var loaded := GameSettings.new(PATH)
	assert_eq(loaded.cast_mode(&"skill_q"), "normal")
	assert_eq(loaded.cast_mode(&"item_1"), "indicator")
	assert_eq(loaded.cast_mode(&"skill_w"), "quick")
	settings.set_cast_mode(&"skill_q", "quick")
	assert_eq(GameSettings.new(PATH).cast_mode(&"skill_q"), "quick")
	assert_eq(GameSettings.DEFAULTS[&"cast_modes"], {}, "the default is never changed")


func test_unknown_cast_modes_and_keys_are_dropped() -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 1, "values": {"cast_modes": {"skill_q": "normal", "skill_w": "sideways", "open_backpack": "normal"}}}))
	file.close()
	var loaded := GameSettings.new(PATH)
	assert_eq(loaded.cast_mode(&"skill_q"), "normal")
	assert_eq(loaded.cast_mode(&"skill_w"), "quick")
	assert_eq(loaded.get_value(&"cast_modes"), {"skill_q": "normal"})


## R1: Resolve is a setting, on by default.
func test_resolve_is_on_by_default_and_is_saved() -> void:
	assert_eq(Resolve.SETTING, &"resolve")
	assert_eq(settings.get_value(Resolve.SETTING), true)
	watch_signals(settings)
	settings.set_value(Resolve.SETTING, false)
	assert_signal_emitted_with_parameters(settings, "changed", [Resolve.SETTING])
	assert_eq(GameSettings.new(PATH).get_value(Resolve.SETTING), false)

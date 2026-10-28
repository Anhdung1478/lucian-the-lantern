extends GutTest

const PATH := "user://test_settings.json"

var settings: GameSettings


func before_each() -> void:
	_delete()
	settings = GameSettings.new(PATH)


func after_each() -> void:
	_delete()


func _delete() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


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


func test_changes_are_saved_with_a_version() -> void:
	watch_signals(settings)
	settings.set_value(&"music_volume", 35)
	assert_signal_emitted_with_parameters(settings, "changed", [&"music_volume"])
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	assert_eq(int(data.version), GameSettings.VERSION)
	assert_eq(GameSettings.new(PATH).get_value(&"music_volume"), 35)


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

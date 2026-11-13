extends GutTest

const SETTINGS_PATH := "user://test_lang_settings.json"

var settings: GameSettings


func before_each() -> void:
	_delete()
	settings = GameSettings.new(SETTINGS_PATH)


func after_each() -> void:
	Lang.probe = false
	Lang.use(Lang.ENGLISH)
	GameSettings.instance().set_value(&"language", Lang.ENGLISH, false)
	_delete()


func _delete() -> void:
	for file in [SETTINGS_PATH, SETTINGS_PATH + ".tmp"]:
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(file))


func test_english_is_the_text_itself() -> void:
	assert_eq(Lang.code(), Lang.ENGLISH)
	assert_eq(Lang.t("Language"), "Language")
	assert_eq(Lang.t("A text with no translation at all"), "A text with no translation at all")


func test_vietnamese_answers_with_the_translation_and_falls_back_to_english() -> void:
	Lang.use(Lang.VIETNAMESE)
	assert_eq(Lang.code(), Lang.VIETNAMESE)
	assert_eq(Lang.t("Language"), "Ngôn ngữ")
	assert_eq(Lang.t("A text with no translation at all"), "A text with no translation at all")
	Lang.use(Lang.ENGLISH)
	assert_eq(Lang.t("Language"), "Language")


func test_an_unknown_language_is_english() -> void:
	Lang.use("xx")
	assert_eq(Lang.code(), Lang.ENGLISH)


func test_the_languages_are_english_and_vietnamese_each_named_in_itself() -> void:
	assert_eq(Lang.CODES, ["en", "vi"] as Array[String])
	assert_eq(Lang.NAMES["en"], "English")
	assert_eq(Lang.NAMES["vi"], "Tiếng Việt")


func test_the_setting_starts_in_english_survives_a_reload_and_refuses_a_code_it_does_not_know() -> void:
	assert_eq(settings.get_value(&"language"), "en")
	settings.set_value(&"language", "vi")
	assert_eq(GameSettings.new(SETTINGS_PATH).get_value(&"language"), "vi")
	settings.set_value(&"language", "xx")
	assert_eq(GameSettings.new(SETTINGS_PATH).get_value(&"language"), "en", "a code from a broken file")


func test_applying_the_settings_turns_the_text() -> void:
	settings.set_value(&"language", "vi", false)
	settings.apply_language()
	assert_eq(Lang.t("Language"), "Ngôn ngữ")


func test_a_marked_text_keeps_its_values_and_its_tags() -> void:
	assert_eq(Lang.mark("Wave"), "Ｗａｖｅ")
	assert_eq(Lang.mark("Wave %d/%d"), "Ｗａｖｅ %d/%d")
	assert_eq(Lang.mark("%.1f s, %s and 100%%"), "%.1f ｓ, %s ａｎｄ 100%%")
	assert_eq(Lang.mark("{name} hits"), "{name} ｈｉｔｓ")
	assert_eq(Lang.mark("+{v}% shield"), "+{v}% ｓｈｉｅｌｄ", "a percent sign before a word is no value")
	assert_eq(Lang.mark("[color=#ffcf5a]Gold[/color]"), "[color=#ffcf5a]Ｇｏｌｄ[/color]")
	assert_eq(Lang.mark("[img=16]res://a/b.svg[/img] Armor"), "[img=16]res://a/b.svg[/img] Ａｒｍｏｒ")
	assert_eq(Lang.mark(Lang.mark("Wave %d")), Lang.mark("Wave %d"), "marking twice changes nothing")
	assert_eq(Lang.mark("Wave %d/%d") % [1, 2], "Ｗａｖｅ 1/2", "a marked format still fills")


func test_the_probe_marks_what_goes_through_t() -> void:
	Lang.probe = true
	assert_eq(Lang.t("Skip"), "Ｓｋｉｐ")
	Lang.probe = false
	assert_eq(Lang.t("Skip"), "Skip")


func test_the_probe_finds_a_text_that_never_went_through_t() -> void:
	Lang.probe = true
	var box := VBoxContainer.new()
	add_child_autofree(box)
	box.add_child(UiStyle.label(Lang.t("Wave %d/%d") % [1, 2]))
	box.add_child(UiStyle.label("12 / 40"))
	assert_eq(LangProbe.plain_texts(box), [] as Array[String])
	box.add_child(UiStyle.label(Lang.t("Killed by %s") % "Thresh"))
	var button := Button.new()
	button.text = "Back"
	button.set_meta(&"hover_text", "No saved games yet")
	box.add_child(button)
	assert_eq(LangProbe.plain_texts(box), ["Ｋｉｌｌｅｄ ｂｙ Thresh", "Back", "No saved games yet"] as Array[String])
	assert_eq(LangProbe.plain_texts(box, ["Thresh", "Back", "No saved games yet"]), [] as Array[String], "pieces allowed by the test")


func test_the_settings_gameplay_tab_picks_the_language() -> void:
	var screen := SettingsScreen.new()
	add_child_autofree(screen)
	screen.setup(settings)
	var picker := _language_option(screen)
	assert_not_null(picker)
	assert_false(picker.disabled)
	assert_eq(picker.get_item_text(0), "English")
	assert_eq(picker.get_item_text(1), "Tiếng Việt")
	assert_eq(picker.selected, 0)
	picker.item_selected.emit(1)
	assert_eq(settings.get_value(&"language"), "vi")
	assert_eq(Lang.code(), "vi", "applied at once")


func test_a_stages_settings_lock_the_language() -> void:
	var screen := SettingsScreen.new()
	screen.language_locked = true
	add_child_autofree(screen)
	screen.setup(settings)
	assert_true(_language_option(screen).disabled)


func test_settings_open_on_the_tab_asked_for() -> void:
	var screen := SettingsScreen.new()
	add_child_autofree(screen)
	screen.setup(settings)
	screen.open()
	assert_eq(screen.tab, 0)
	screen.open(3)
	assert_eq(screen.tab, 3)
	assert_true(screen._pages[3].visible)


func test_the_picker_names_each_language_lights_the_one_in_use_and_sets_the_setting() -> void:
	var picker := LanguagePicker.new(settings)
	add_child_autofree(picker)
	assert_eq((picker.buttons["en"] as Button).text, "English")
	assert_eq((picker.buttons["vi"] as Button).text, "Tiếng Việt")
	picker.choose("vi")
	assert_eq(settings.get_value(&"language"), "vi")
	watch_signals(settings)
	picker.choose("vi")
	assert_signal_not_emitted(settings, "changed", "the language in use again: nothing")


func test_the_game_builds_the_title_again_in_the_new_language_with_settings_open_where_it_was() -> void:
	var game: Game = load("res://src/main/game.tscn").instantiate()
	game.quit_game = func() -> void: pass
	add_child_autofree(game)
	await wait_process_frames(2)
	var first := game.screen as TitleScreen
	assert_not_null(first)
	first.open_settings(3)
	first.language_picker.choose("vi")
	await wait_process_frames(3)
	var second := game.screen as TitleScreen
	assert_not_null(second)
	assert_ne(second, first, "a new title screen")
	assert_eq(Lang.code(), "vi")
	assert_true(second.settings.visible, "Settings is open again")
	assert_eq(second.settings.tab, 3)
	assert_eq(_language_option(second.settings).selected, 1)


## The Gameplay tab's language dropdown: the one that lists the languages.
func _language_option(screen: SettingsScreen) -> OptionButton:
	for option: OptionButton in screen.find_children("*", "OptionButton", true, false):
		if option.item_count == Lang.CODES.size() and option.get_item_text(1) == Lang.NAMES[Lang.VIETNAMESE]:
			return option
	return null

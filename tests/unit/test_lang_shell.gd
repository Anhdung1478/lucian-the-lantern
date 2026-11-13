extends GutTest
## The shell's texts (the title, Settings, the menus and the pop-ups) go
## through Lang.t and have their Vietnamese.

const PREFIX := "user://test_lang_shell_save_slot_"
const SETTINGS_PATH := "user://test_lang_shell_settings.json"
## Never translated: the game's name on the title.
const GAME_NAME: Array[String] = ["LUCIAN", "THE LANTERN"]
## The engine's own text: the search field of a dropdown's list.
const ENGINE: Array[String] = ["Search"]
## The default keys, shown as the keyboard names them.
const KEYS: Array[String] = ["LMB", "RMB", "Space"]

var good_prefix := ""


func before_each() -> void:
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new(PREFIX)
	good_prefix = SaveGame.instance().prefix
	SaveGame.instance().prefix = PREFIX
	_delete_slots()


func after_each() -> void:
	Lang.probe = false
	Lang.use(Lang.ENGLISH)
	SaveGame.instance().prefix = good_prefix
	_delete_slots()
	for file in [SETTINGS_PATH, SETTINGS_PATH + ".tmp"]:
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(file))


func _delete_slots() -> void:
	var save := SaveGame.instance()
	for n in range(1, SaveGame.SLOTS + 1):
		for file in [save.path(n), save.backup_path(n)]:
			if FileAccess.file_exists(file):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(file))


func _scripts() -> Array:
	var paths: Array = []
	for dir in ["res://src/ui/title", "res://src/ui/settings", "res://src/ui/menu", "res://src/main", "res://src/audio"]:
		paths.append_array(LangProbe.scripts_in(dir))
	for file in ["ui_style", "plate", "screen_fade", "screen_switcher"]:
		paths.append("res://src/ui/%s.gd" % file)
	for file in ["game_settings", "save_game", "difficulty", "layers", "pointer"]:
		paths.append("res://src/core/%s.gd" % file)
	return paths


func test_every_text_in_the_shells_scripts_has_a_vietnamese_or_is_left_in_english() -> void:
	assert_eq(LangProbe.missing_in(_scripts()), [] as Array[String])


func test_the_title_screen_in_all_its_pages_has_no_plain_text() -> void:
	Lang.probe = true
	SaveGame.instance().start_new(2, Difficulty.HARD)
	var title := TitleScreen.new()
	add_child_autofree(title)
	title.show_menu()
	title.show_slots(true)
	title.show_difficulty(1)
	title.notice_label.text = Lang.t("Could not save")
	title.error_label.text = Lang.t("Could not read slot %d") % 1
	assert_eq(LangProbe.plain_texts(title, GAME_NAME + ENGINE + KEYS), [] as Array[String])


func test_the_slot_list_with_a_used_a_broken_and_an_empty_slot_has_no_plain_text() -> void:
	Lang.probe = true
	SaveGame.instance().start_new(1, Difficulty.NORMAL)
	var broken := FileAccess.open(SaveGame.instance().path(2), FileAccess.WRITE)
	broken.store_string("{ not json")
	broken.close()
	var list := SlotList.new()
	add_child_autofree(list)
	list.refresh(0)
	list.refresh(3)
	assert_eq(LangProbe.plain_texts(list), [] as Array[String])


func test_settings_on_every_tab_has_no_plain_text() -> void:
	Lang.probe = true
	var settings := GameSettings.new(SETTINGS_PATH)
	var allowed: Array = ENGINE.duplicate()
	for action in GameSettings.REBINDABLE:
		allowed.append(settings.key_label(action))
	var screen := SettingsScreen.new()
	add_child_autofree(screen)
	screen.setup(settings)
	screen.open(3)
	assert_eq(LangProbe.plain_texts(screen, allowed), [] as Array[String])
	screen.listen(&"skill_q")
	assert_eq(LangProbe.plain_texts(screen, allowed), [] as Array[String], "while waiting for a key")
	var locked := SettingsScreen.new()
	locked.language_locked = true
	add_child_autofree(locked)
	locked.setup(settings)
	assert_eq(LangProbe.plain_texts(locked, allowed), [] as Array[String], "a stage's Settings")
	GameSettings.instance().apply_input()


func test_the_stage_menu_has_no_plain_text() -> void:
	Lang.probe = true
	var menu := GameMenu.new()
	add_child_autofree(menu)
	menu.set_leave_enabled(false)
	assert_eq(LangProbe.plain_texts(menu), [] as Array[String])


func test_the_pop_up_has_no_plain_button_in_any_form() -> void:
	Lang.probe = true
	var popup := ConfirmPopup.new()
	add_child_autofree(popup)
	for form in 3:
		match form:
			0:
				popup.ask(Lang.t("Exit the game?"), Callable())
			1:
				popup.ask_or_cancel(Lang.t("Save before leaving?"), Callable(), Callable())
			2:
				popup.tell(Lang.t("Exit the game?"))
		assert_eq(LangProbe.plain_texts(popup), [] as Array[String], "form %d" % form)


## Game's prompt is built once and outlives a language change: every button
## takes the language in use when it asks, not the one it was built in.
func test_a_pop_up_built_in_vietnamese_asks_in_english_after_a_switch() -> void:
	Lang.use(Lang.VIETNAMESE)
	var popup := ConfirmPopup.new()
	add_child_autofree(popup)
	Lang.use(Lang.ENGLISH)
	popup.ask_or_cancel(Lang.t("Save before leaving?"), Callable(), Callable())
	assert_eq([popup._yes.text, popup._no.text, popup._cancel.text], ["Yes", "No", "Cancel"])
	popup.dismiss()
	Lang.use(Lang.VIETNAMESE)
	popup.ask_or_cancel(Lang.t("Save before leaving?"), Callable(), Callable())
	assert_eq([popup._yes.text, popup._no.text, popup._cancel.text], [Lang.t("Yes"), Lang.t("No"), Lang.t("Cancel")])
	assert_ne(popup._no.text, "No", "the Vietnamese is used")


func test_the_end_screen_has_no_plain_text() -> void:
	Lang.probe = true
	SaveGame.instance().start_new(1, Difficulty.NORMAL)
	var end := TheEndScreen.new()
	add_child_autofree(end)
	assert_eq(LangProbe.plain_texts(end), [] as Array[String])


func test_the_game_roots_questions_have_no_plain_text() -> void:
	Lang.probe = true
	SaveGame.instance().load_slot(1)
	var game: Game = load("res://src/main/game.tscn").instantiate()
	game.quit_game = func() -> void: pass
	add_child_autofree(game)
	game.ask_to_exit()
	assert_eq(LangProbe.plain_texts(game.prompt, GAME_NAME), [] as Array[String], "Exit the game?")
	game.prompt.dismiss()
	game.ask_to_leave()
	assert_eq(LangProbe.plain_texts(game.prompt, GAME_NAME), [] as Array[String], "Save before leaving?")
	game.prompt.dismiss()


func test_the_title_in_vietnamese() -> void:
	Lang.use(Lang.VIETNAMESE)
	var title := TitleScreen.new()
	add_child_autofree(title)
	var buttons: Array[String] = []
	for button: Button in title.find_children("*", "Button", true, false):
		buttons.append(button.text)
	assert_has(buttons, "Bắt đầu trò chơi mới")
	assert_has(buttons, "Tải trò chơi")
	assert_has(buttons, "Cài đặt")
	assert_has(buttons, "Thoát trò chơi")


func test_a_text_with_values_in_vietnamese() -> void:
	Lang.use(Lang.VIETNAMESE)
	assert_eq(Difficulty.describe(Difficulty.HARD).get_slice("\n", 0),
		"Kẻ địch có 110% máu và gây 110% sát thương. Tinh chất xanh và cam ×1.2.")
	assert_eq(Lang.t("Overwrite slot %d? Its progress will be lost.") % 2, "Ghi đè ô 2? Tiến trình trong đó sẽ mất.")
	assert_eq(SaveGame.play_time_text(3725), "1g 02p")
	assert_eq(SaveGame.play_time_text(600), "10p")
	assert_eq(Lang.t(Difficulty.name_of(Difficulty.EXTREME)), "Cực khó")


func test_settings_and_the_pop_up_in_vietnamese() -> void:
	Lang.use(Lang.VIETNAMESE)
	var settings := GameSettings.new(SETTINGS_PATH)
	var screen := SettingsScreen.new()
	add_child_autofree(screen)
	screen.setup(settings)
	var texts: Array[String] = []
	for label: Label in screen.find_children("*", "Label", true, false):
		texts.append(label.text)
	assert_has(texts, "Di chuyển")
	assert_has(texts, "Chế độ cửa sổ")
	assert_has(texts, "CÀI ĐẶT")
	var popup := ConfirmPopup.new()
	add_child_autofree(popup)
	popup.ask_or_cancel("?", Callable(), Callable())
	var buttons: Array[String] = []
	for button: Button in popup.find_children("*", "Button", true, false):
		buttons.append(button.text)
	assert_eq(buttons, ["Có", "Không", "Hủy"] as Array[String])
	GameSettings.instance().apply_input()

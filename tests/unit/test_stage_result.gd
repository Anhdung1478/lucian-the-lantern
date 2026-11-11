extends GutTest

const NONE: Array[String] = []

var result: StageResult


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real settings.
	if GameSettings._instance == null or GameSettings._instance.path == GameSettings.DEFAULT_PATH:
		GameSettings._instance = GameSettings.new("user://test_stage_result_settings.json")
	result = StageResult.new()
	add_child_autofree(result)


func after_each() -> void:
	GameSettings.instance().set_value(&"quality", "high")


func _essences(blue := 0, orange := 0, purple := 0) -> Dictionary:
	return {Essences.BLUE: blue, Essences.ORANGE: orange, Essences.PURPLE: purple}


func _texts() -> Array:
	return result.find_children("*", "Label", true, false).map(func(label: Label) -> String: return label.text)


func test_cleared_shows_retry_next_and_main() -> void:
	result.show_result(true, "Stage 2-1", [], _essences(), NONE, false, true)
	assert_eq(result.title.text, "STAGE CLEARED")
	assert_true(result.retry_button.visible)
	assert_true(result.next_button.visible)
	assert_eq(result.main_button.text, "Main screen")


func test_next_is_hidden_when_there_is_no_next_stage_to_play() -> void:
	result.show_result(true, "Stage 2-3", [], _essences(), NONE, false, false)
	assert_false(result.next_button.visible)
	assert_true(result.retry_button.visible)


func test_defeat_hides_next_even_when_it_could_be_played() -> void:
	result.show_result(false, "Stage 2-1", [], _essences(), NONE, false, true)
	assert_eq(result.title.text, "DEFEATED")
	assert_true(result.retry_button.visible)
	assert_false(result.next_button.visible)


func test_game_over_has_only_back_to_title() -> void:
	result.show_result(false, "Stage 1-1", [], _essences(), NONE, true, true)
	assert_eq(result.title.text, "GAME OVER")
	assert_false(result.retry_button.visible)
	assert_false(result.next_button.visible)
	assert_eq(result.main_button.text, "Back to title")


## Endless's end: a title of its own over a failed result (red, Retry and
## Main screen, no Next).
func test_an_optional_title_replaces_the_outcomes() -> void:
	result.show_result(false, "Endless · Jungle", [], _essences(), NONE, false, false, "RUN OVER")
	assert_eq(result.title.text, "RUN OVER")
	assert_eq(result.title.get_theme_color(&"font_color"), UiStyle.ERROR_COLOR)
	assert_true(result.retry_button.visible)
	assert_false(result.next_button.visible)
	assert_eq(result.main_button.text, "Main screen")
	result.show_result(false, "Stage 2-1", [], _essences(), NONE)
	assert_eq(result.title.text, "DEFEATED", "without one, the outcome's")


func test_each_button_emits_its_choice() -> void:
	result.show_result(true, "Stage 2-1", [], _essences(), NONE, false, true)
	watch_signals(result)
	result.retry_button.pressed.emit()
	assert_signal_emitted_with_parameters(result, "chosen", [&"retry"])
	result.next_button.pressed.emit()
	assert_signal_emitted_with_parameters(result, "chosen", [&"next"])
	result.main_button.pressed.emit()
	assert_signal_emitted_with_parameters(result, "chosen", [&"main"])


func test_the_game_over_button_emits_title() -> void:
	result.show_result(false, "Stage 1-1", [], _essences(), NONE, true)
	watch_signals(result)
	result.main_button.pressed.emit()
	assert_signal_emitted_with_parameters(result, "chosen", [&"title"])


## The essences read their amounts once they have counted up (COUNT_TIME).
func test_essence_rows_and_reward_lines() -> void:
	result.show_result(true, "Stage 2-1", [], _essences(312, 4, 0), ["Stage 2-2 is open"] as Array[String])
	result._process(StageResult.COUNT_TIME)
	var texts := _texts()
	assert_true("+312 blue essence" in texts, str(texts))
	assert_true("+4 orange essence" in texts, str(texts))
	assert_false(texts.any(func(text: String) -> bool: return text.contains("purple")))
	assert_true("Stage 2-2 is open" in texts)
	assert_false("No essences" in texts)


func test_the_essences_count_up_from_zero() -> void:
	result.show_result(true, "Stage 2-1", [], _essences(312, 4, 0), NONE)
	assert_true("+0 blue essence" in _texts(), str(_texts()))
	assert_true("+0 orange essence" in _texts())
	assert_true(result.is_processing(), "counting")
	result._process(StageResult.COUNT_TIME * 0.5)
	var blue: String = _texts().filter(func(text: String) -> bool: return text.ends_with("blue essence"))[0]
	assert_between(int(blue), 1, 311, "on its way up")
	result._process(StageResult.COUNT_TIME * 0.5)
	assert_true("+312 blue essence" in _texts(), str(_texts()))
	assert_true("+4 orange essence" in _texts())
	assert_false(result.is_processing(), "done")


func test_low_effects_show_the_final_numbers_at_once() -> void:
	GameSettings.instance().set_value(&"quality", "low")
	result.show_result(true, "Stage 2-1", [], _essences(312, 4, 0), NONE)
	assert_true("+312 blue essence" in _texts(), str(_texts()))
	assert_true("+4 orange essence" in _texts())
	assert_false(result.is_processing())


## A second result (a retry's) counts its own amounts, from zero again.
func test_a_new_result_counts_its_own_essences() -> void:
	result.show_result(false, "Stage 2-1", [], _essences(50, 0, 0), NONE)
	result._process(StageResult.COUNT_TIME)
	result.show_result(true, "Stage 2-1", [], _essences(0, 0, 7), NONE)
	result._process(StageResult.COUNT_TIME)
	await wait_process_frames(1)
	var texts := _texts()
	assert_true("+7 purple essence" in texts, str(texts))
	assert_false(texts.any(func(text: String) -> bool: return text.contains("blue")), "the old rows are gone")


func test_no_essences_text() -> void:
	result.show_result(false, "Stage 2-1", [], _essences(), NONE)
	assert_true("No essences" in _texts())


## The lantern, the title and its glow follow the outcome: lit and gold
## after a clear, dim and red after any defeat.
func test_the_title_is_gold_after_a_clear_and_red_after_a_defeat() -> void:
	result.show_result(true, "Stage 2-1", [], _essences(), NONE)
	assert_eq(result.title.get_theme_color(&"font_color"), UiStyle.GOLD_COLOR)
	assert_eq(result._glow_color(), StageResult.CLEARED_GLOW)
	result.show_result(false, "Stage 2-1", [], _essences(), NONE)
	assert_eq(result.title.get_theme_color(&"font_color"), UiStyle.ERROR_COLOR)
	assert_eq(result._glow_color(), StageResult.DEFEATED_GLOW)
	result.show_result(false, "Stage 1-1", [], _essences(), NONE, true)
	assert_eq(result.title.get_theme_color(&"font_color"), UiStyle.ERROR_COLOR, "a game over too")


## A row is its name and its value; its icon is drawn in the name's margin.
func test_a_stats_row_is_its_name_and_its_value() -> void:
	result.show_result(true, "Stage 2-1", [["Kills", "87"], ["Waves", "2 / 3"]], _essences(), NONE)
	var rows := result._stats.get_children()
	assert_eq(rows.size(), 2)
	for i in 2:
		assert_eq(rows[i].get_child_count(), 2)
	assert_eq((rows[0].get_child(0) as Label).text, "Kills")
	assert_eq((rows[0].get_child(1) as Label).text, "87")
	assert_eq((rows[1].get_child(1) as Label).text, "2 / 3")
	assert_true(StageResult.STAT_ICONS.has("Kills"))
	assert_false(StageResult.STAT_ICONS.has("Waves"), "no art: a diamond")


func test_stats_rows_show_label_and_value() -> void:
	result.show_result(true, "Stage 2-1", [["Time", "6:42"], ["Kills", "87"]], _essences(), NONE)
	var texts := _texts()
	for text in ["Time", "6:42", "Kills", "87", "Stage 2-1"]:
		assert_true(text in texts, str(texts))

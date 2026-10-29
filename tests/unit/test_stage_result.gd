extends GutTest

const NONE: Array[String] = []

var result: StageResult


func before_each() -> void:
	result = StageResult.new()
	add_child_autofree(result)


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


func test_essence_rows_and_reward_lines() -> void:
	result.show_result(true, "Stage 2-1", [], _essences(312, 4, 0), ["Stage 2-2 is open"] as Array[String])
	var texts := _texts()
	assert_true("+312 blue essence" in texts, str(texts))
	assert_true("+4 orange essence" in texts, str(texts))
	assert_false(texts.any(func(text: String) -> bool: return text.contains("purple")))
	assert_true("Stage 2-2 is open" in texts)
	assert_false("No essences" in texts)


func test_no_essences_text() -> void:
	result.show_result(false, "Stage 2-1", [], _essences(), NONE)
	assert_true("No essences" in _texts())


func test_stats_rows_show_label_and_value() -> void:
	result.show_result(true, "Stage 2-1", [["Time", "6:42"], ["Kills", "87"]], _essences(), NONE)
	var texts := _texts()
	for text in ["Time", "6:42", "Kills", "87", "Stage 2-1"]:
		assert_true(text in texts, str(texts))

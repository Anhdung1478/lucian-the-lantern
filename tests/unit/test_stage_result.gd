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


## A clear's essences are one row of large counts (a number in the essence's
## color, its word under it); their final numbers are on at once.
func test_essence_counts_and_reward_lines() -> void:
	result.show_result(true, "Stage 2-1", [], _essences(312, 4, 0), ["Stage 2-2 is open"] as Array[String])
	var texts := _texts()
	assert_eq(result._essence_counts[Essences.BLUE].final_text(), "312")
	assert_eq(result._essence_counts[Essences.BLUE].text, "312")
	assert_eq(result._essence_counts[Essences.ORANGE].text, "4")
	assert_false(result._essence_counts.has(Essences.PURPLE), "none earned: no count")
	assert_true("blue" in texts and "orange" in texts, str(texts))
	assert_false("purple" in texts)
	assert_true("Stage 2-2 is open" in texts)
	assert_false("No essences" in texts)
	assert_eq(result._essence_counts[Essences.BLUE].get_theme_color(&"font_color"), Stage.ESSENCE_COLORS[Essences.BLUE])


func test_the_essences_count_up_from_zero_when_motion_is_on() -> void:
	UiMotion.renders = true
	result.show_result(true, "Stage 2-1", [], _essences(312, 4, 0), NONE)
	var blue: CountLabel = result._essence_counts[Essences.BLUE]
	assert_eq(blue.text, "0", "from zero")
	await wait_seconds(StageResult.REWARDS_AT + CountLabel.COUNT_MAX + 0.3)
	assert_eq(blue.text, "312")
	assert_eq(result._essence_counts[Essences.ORANGE].text, "4")
	UiMotion.renders = false


func test_low_effects_show_the_final_numbers_at_once() -> void:
	UiMotion.renders = true
	GameSettings.instance().set_value(&"quality", "low")
	result.show_result(true, "Stage 2-1", [["Kills", "87"]], _essences(312, 4, 0), NONE)
	assert_eq(result._essence_counts[Essences.BLUE].text, "312")
	assert_eq(result._essence_counts[Essences.ORANGE].text, "4")
	assert_eq((result._stats.get_child(0).get_child(1) as Label).text, "87")
	UiMotion.renders = false


## The buttons take clicks from the first frame: only their alpha waits.
func test_the_buttons_take_clicks_while_they_fade_in() -> void:
	UiMotion.renders = true
	result.show_result(true, "Stage 2-1", [], _essences(), NONE, false, true)
	watch_signals(result)
	assert_eq(result.retry_button.mouse_filter, Control.MOUSE_FILTER_STOP)
	assert_true(result.retry_button.is_visible_in_tree())
	assert_lt(result._buttons.modulate.a, 1.0, "not yet drawn whole")
	result.retry_button.pressed.emit()
	assert_signal_emitted_with_parameters(result, "chosen", [&"retry"])
	await wait_seconds(StageResult.BUTTONS_AT + UiMotion.STORY + 0.1)
	assert_almost_eq(result._buttons.modulate.a, 1.0, 0.01)
	assert_almost_eq(result._center.modulate.a, 1.0, 0.01)
	assert_almost_eq(result.title.modulate.a, 1.0, 0.01)
	UiMotion.renders = false


## A second result (a retry's) counts its own amounts, from zero again.
func test_a_new_result_counts_its_own_essences() -> void:
	result.show_result(false, "Stage 2-1", [], _essences(50, 0, 0), NONE)
	result.show_result(true, "Stage 2-1", [], _essences(0, 0, 7), NONE)
	var texts := _texts()
	assert_eq(result._essence_counts.keys(), [Essences.PURPLE])
	assert_true("purple" in texts, str(texts))
	assert_false("blue" in texts, "the old rows are gone")


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
	assert_false(StageResult.STAT_ICONS.has("Waves"), "no art: it draws wave pips")
	assert_is(rows[0].get_child(1), CountLabel, "a whole number counts up")
	assert_false(rows[1].get_child(1) is CountLabel, "2 / 3 is set at once")


func test_stats_rows_show_label_and_value() -> void:
	result.show_result(true, "Stage 2-1", [["Time", "6:42"], ["Kills", "87"]], _essences(), NONE)
	var texts := _texts()
	for text in ["Time", "6:42", "Kills", "87", "Stage 2-1"]:
		assert_true(text in texts, str(texts))


func test_the_recap_shows_on_a_defeat_and_never_on_a_clear() -> void:
	var recap := {"killed": "Killed by Gromp", "shares": ["Gromp 100%"], "tip": "A tip.", "tree": ""}
	result.show_result(false, "Stage 2-1", [], _essences(), NONE, false, false, "", recap)
	assert_true("Killed by Gromp" in _texts())
	assert_true(result.find_children("*", "Label", true, false).any(func(label: Label) -> bool: return label.text == "WHAT HIT YOU" and label.is_visible_in_tree()))
	result.show_result(true, "Stage 2-1", [], _essences(), NONE, false, false, "", recap)
	assert_false(result.find_children("*", "Label", true, false).any(func(label: Label) -> bool: return label.text == "WHAT HIT YOU" and label.is_visible_in_tree()))
	assert_false("Killed by Gromp" in _texts())


## After a defeat the right column is the recap: the killed-by line, the shares
## one per line (name left, share right), the tips; the essences earned are the
## stats' last rows, and the Resolve line joins the tips.
func test_a_defeat_puts_the_recap_in_the_right_column_and_the_essences_in_the_stats() -> void:
	var recap := {"killed": "Killed by Gromp", "shares": ["Gromp 60%", "Burning ground 40%"], "tip": "A tip.", "tree": "Buy something."}
	result.show_result(false, "Stage 2-1", [["Kills", "3"]], _essences(32, 0, 2), ["Resolve 1 / 5"] as Array[String], false, false, "", recap)
	var rows := result._stats.get_children()
	assert_eq(rows.size(), 3, "Kills, then blue and purple")
	assert_eq((rows[1].get_child(0) as Label).text, "Blue essence")
	assert_eq((rows[1].get_child(1) as Label).text, "+32")
	assert_eq((rows[2].get_child(1) as Label).text, "+2")
	assert_true(result._essence_counts.is_empty(), "no large counts on the right")
	var shares := result._rewards.get_children().filter(func(row: Node) -> bool: return row is HBoxContainer and row.get_child_count() == 2 and row.get_child(0) is Label)
	assert_eq(shares.size(), 2)
	assert_eq((shares[0].get_child(0) as Label).text, "Gromp")
	assert_eq((shares[0].get_child(1) as Label).text, "60%")
	assert_eq((shares[1].get_child(0) as Label).text, "Burning ground")
	assert_eq((shares[1].get_child(1) as Label).horizontal_alignment, HORIZONTAL_ALIGNMENT_RIGHT)
	var texts := _texts()
	for text in ["A tip.", "Buy something.", "Resolve 1 / 5"]:
		assert_true(text in texts, str(texts))
	assert_eq(result._right_head.text, "WHAT HIT YOU")
	result.show_result(true, "Stage 2-1", [], _essences(32, 0, 0), NONE)
	assert_eq(result._right_head.text, "REWARDS")


## A defeat with nothing to recap keeps the rewards column and its large counts.
func test_a_defeat_without_a_recap_keeps_the_rewards() -> void:
	result.show_result(false, "Stage 2-1", [], _essences(32, 0, 0), NONE)
	assert_eq(result._right_head.text, "REWARDS")
	assert_eq(result._essence_counts[Essences.BLUE].text, "32")


## Endless's lead stat is large and gold.
func test_the_waves_cleared_row_leads_in_gold() -> void:
	result.show_result(false, "Endless", [["Waves cleared", "22"], ["Kills", "5"]], _essences(), NONE, false, false, "RUN OVER")
	var lead := result._stats.get_child(0).get_child(1) as CountLabel
	assert_eq(lead.text, "22")
	assert_eq(lead.get_theme_color(&"font_color"), UiStyle.GOLD_COLOR)
	assert_eq(lead.get_theme_font_size(&"font_size"), StageResult.LEAD_FONT)
	var other := result._stats.get_child(1).get_child(1) as CountLabel
	assert_eq(other.get_theme_font_size(&"font_size"), StageResult.ROW_FONT)


## Endless's run over: the essences are the right column's REWARDS (after
## what hit Lucian), not rows of the stats.
func test_endless_run_over_puts_the_essences_under_a_rewards_head() -> void:
	var recap := {"killed": "Killed by Gromp", "shares": ["Gromp 100%"], "tip": "A tip.", "tree": ""}
	result.show_result(false, "Endless", [["Waves cleared", "3"]], _essences(40, 5, 0), ["New best: 3"] as Array[String], false, false, "RUN OVER", recap)
	assert_eq(result._stats.get_child_count(), 1, "no essence rows on the left")
	assert_eq(result._essence_counts[Essences.BLUE].text, "40")
	assert_true("REWARDS" in _texts() and "WHAT HIT YOU" in _texts())
	assert_true("New best: 3" in _texts())


func test_gift_and_modifier_values_are_names_in_the_text_color() -> void:
	result.show_result(true, "Stage 2-1", [["Kills", "3"], ["Gift", "Second Wind"]], _essences(), NONE)
	assert_eq((result._stats.get_child(1).get_child(1) as Label).get_theme_color(&"font_color"), UiStyle.TEXT_COLOR)
	assert_ne((result._stats.get_child(0).get_child(1) as Label).get_theme_color(&"font_color"), UiStyle.TEXT_COLOR)

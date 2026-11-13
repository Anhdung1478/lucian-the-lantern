extends GutTest
## The modifier pick's look: its title in capitals, a card for each id with
## its downside in the bad color and its reward in the good one, and a
## hovered card's gold rim and lift.

## Modifiers #3 and #5, then Nothing: as EndlessModifiers.offer gives them.
const OFFERED: Array[int] = [3, 5, EndlessModifiers.NOTHING]

var pick: ModifierPick


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real settings.
	if GameSettings._instance == null or GameSettings._instance.path == GameSettings.DEFAULT_PATH:
		GameSettings._instance = GameSettings.new("user://test_modifier_pick_settings.json")
	pick = ModifierPick.new(OFFERED)
	add_child_autofree(pick)


func after_each() -> void:
	GameSettings.instance().set_value(&"quality", "high")


func _labels(node: Node) -> Array[Label]:
	var found: Array[Label] = []
	for label in node.find_children("*", "Label", true, false):
		found.append(label as Label)
	return found


func _card(index: int) -> ModifierCard:
	return pick.cards[index] as ModifierCard


func test_the_title_is_in_capitals_over_a_card_for_each_id() -> void:
	var texts := _labels(pick).map(func(label: Label) -> String: return label.text)
	assert_has(texts, "CHOOSE A MODIFIER")
	assert_eq(pick.cards.size(), 3)
	for i in 3:
		assert_eq(_card(i).id, OFFERED[i])


func test_a_card_shows_its_downside_in_the_bad_color_and_its_reward_in_the_good_one() -> void:
	for i in 2:
		var labels := _labels(_card(i))
		assert_eq(labels.size(), 2)
		assert_eq(labels[0].text, EndlessModifiers.downside(OFFERED[i]))
		assert_eq(labels[0].get_theme_color(&"font_color"), UiStyle.BAD_COLOR)
		assert_eq(labels[1].text, EndlessModifiers.reward(OFFERED[i]))
		assert_eq(labels[1].get_theme_color(&"font_color"), UiStyle.GOOD_COLOR)


## Nothing is one dim line: no loss and gain colors on two words that are neither.
func test_the_nothing_card_is_one_dim_line() -> void:
	var labels := _labels(_card(2))
	assert_eq(labels.size(), 1)
	assert_eq(labels[0].text, "No modifier")
	assert_eq(labels[0].get_theme_color(&"font_color"), UiStyle.DIM_COLOR)
	assert_true(_card(2).is_nothing())
	assert_false(_card(0).is_nothing())


## The lines are top-aligned: the first one starts at the same height on every
## card, whatever the card holds.
func test_every_cards_first_line_starts_at_the_same_height() -> void:
	await wait_process_frames(3)
	var tops: Array[float] = []
	for i in 3:
		tops.append(_labels(_card(i))[0].global_position.y - _card(i).global_position.y)
	assert_almost_eq(tops[0], tops[1], 0.5)
	assert_almost_eq(tops[0], tops[2], 0.5)
	assert_almost_eq(tops[0], ModifierCard.MEDALLION + Ornament.RING + ModifierCard.LINES_GAP, 0.5)
	assert_eq(_card(0).size.y, 216.0)


func test_a_click_on_a_card_picks_its_id() -> void:
	watch_signals(pick)
	_card(1).pressed.emit()
	assert_signal_emitted_with_parameters(pick, "picked", [5])


func test_a_hovered_card_lifts_and_its_rim_turns_gold() -> void:
	var card := _card(0)
	var place := card.position
	assert_eq(card.lit_t, 0.0)
	assert_eq(card.rim_color(), UiStyle.BORDER_COLOR)
	card.mouse_entered.emit()
	assert_true(card.lit)
	assert_eq(card.rim_color(), UiStyle.GOLD_COLOR, "at once")
	assert_eq(_card(1).rim_color(), UiStyle.BORDER_COLOR, "only the hovered one")
	await wait_seconds(ModifierCard.LIFT_TIME + 0.1)
	assert_almost_eq(card._face.position.y, -ModifierCard.LIFT, 0.01)
	assert_eq(card.lit_t, 1.0, "the surface and rim follow the one value")
	assert_eq(card.position, place, "the button keeps its place")
	card.mouse_exited.emit()
	assert_eq(card.rim_color(), UiStyle.BORDER_COLOR)
	await wait_seconds(ModifierCard.LIFT_TIME + 0.1)
	assert_almost_eq(card._face.position.y, 0.0, 0.01, "back down")


## The pick is over a paused game: the lift still plays.
func test_a_card_lifts_while_the_game_is_paused() -> void:
	get_tree().paused = true
	_card(0).mouse_entered.emit()
	var give_up := Time.get_ticks_msec() + 2000
	while _card(0)._face.position.y > -ModifierCard.LIFT + 0.01 and Time.get_ticks_msec() < give_up:
		await wait_process_frames(1)
	get_tree().paused = false
	assert_almost_eq(_card(0)._face.position.y, -ModifierCard.LIFT, 0.01)


func test_with_low_effects_only_the_rim_changes() -> void:
	GameSettings.instance().set_value(&"quality", "low")
	var card := _card(0)
	card.mouse_entered.emit()
	assert_eq(card.rim_color(), UiStyle.GOLD_COLOR)
	await wait_seconds(ModifierCard.LIFT_TIME + 0.1)
	assert_eq(card._face.position.y, 0.0, "no lift")


func test_no_card_takes_the_keyboard_focus() -> void:
	for i in 3:
		assert_eq(_card(i).focus_mode, Control.FOCUS_NONE)


## With motion on, a card arrives from below its place and settles; the pick
## settles.
func test_the_cards_rise_in_one_after_another() -> void:
	UiMotion.renders = true
	var other := ModifierPick.new(OFFERED)
	add_child_autofree(other)
	var first := other.cards[0] as ModifierCard
	var last := other.cards[2] as ModifierCard
	assert_almost_eq(first._face.modulate.a, 0.0, 0.01, "unseen at first")
	await wait_seconds(ModifierPick.CARDS_AT + 2 * ModifierPick.CARD_STEP + UiMotion.BASE + 0.2)
	for card: ModifierCard in [first, last]:
		assert_almost_eq(card._face.modulate.a, 1.0, 0.01)
		assert_almost_eq(card._face.position.y, 0.0, 0.01, "at rest")
	UiMotion.renders = false


## A click with motion on hands the look to a layer that holds the chosen card,
## fades the others and frees itself; the pick may be freed at once.
func test_a_click_leaves_through_a_layer_of_its_own() -> void:
	UiMotion.renders = true
	var other := ModifierPick.new(OFFERED)
	add_child_autofree(other)
	await wait_process_frames(2)
	var layers := get_tree().root.get_child_count()
	other.cards[1].pressed.emit()
	assert_eq(get_tree().root.get_child_count(), layers + 1, "the exit layer")
	other.queue_free()
	await wait_seconds(ModifierPick.HOLD + ModifierPick.LEAVE_FADE + 0.3)
	assert_eq(get_tree().root.get_child_count(), layers, "and it is gone")
	UiMotion.renders = false

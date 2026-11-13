extends GutTest
## HoverTip's motion and placement: a card fades in and out (at once while
## motion is off), tooltip_anchor() moves what ABOVE and BESIDE measure from,
## BESIDE falls back left then above, and a long note wraps.

var _renders: bool
var tip: HoverTip


class Source extends Control:
	var place := HoverTip.Place.BESIDE
	var anchor := Rect2()
	var card_size := Vector2(200, 100)

	func tooltip_content() -> Control:
		var card := Control.new()
		card.custom_minimum_size = card_size
		return card

	func tooltip_place() -> HoverTip.Place:
		return place

	func tooltip_anchor() -> Rect2:
		return anchor if anchor.size != Vector2.ZERO else get_global_rect()


func before_each() -> void:
	_renders = UiMotion.renders
	tip = HoverTip.new()
	add_child_autofree(tip)
	# No real mouse here: its own hover tracking would hide the card.
	tip.set_process(false)


func after_each() -> void:
	UiMotion.renders = _renders


func _source(at: Vector2, place := HoverTip.Place.BESIDE) -> Source:
	var source := Source.new()
	source.position = at
	source.size = Vector2(40, 40)
	source.place = place
	add_child_autofree(source)
	return source


func _screen() -> Rect2:
	return tip.get_viewport().get_visible_rect()


func test_off_the_card_shows_and_goes_at_once() -> void:
	UiMotion.renders = false
	var source := _source(Vector2(100, 300))
	tip.show_for(source)
	tip._position_card()
	var card := tip.card()
	assert_eq(card.modulate.a, 1.0)
	tip._hide()
	assert_false(tip.is_showing())
	assert_true(card.is_queued_for_deletion())


func test_a_card_fades_in_rising_and_fades_out() -> void:
	UiMotion.renders = true
	var source := _source(Vector2(100, 300))
	tip.show_for(source)
	tip._position_card()
	var card := tip.card()
	assert_eq(card.modulate.a, 0.0, "starts clear")
	var low := card.position.y
	await wait_seconds(HoverTip.FADE_IN + 0.05)
	tip._position_card()
	assert_eq(card.modulate.a, 1.0)
	assert_almost_eq(low - card.position.y, HoverTip.RISE, 0.01, "rose into place")
	tip._hide()
	assert_false(tip.is_showing(), "gone at once for the code")
	assert_false(card.is_queued_for_deletion(), "kept while it fades")
	assert_eq(card.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	await wait_seconds(HoverTip.FADE_OUT + 0.05)
	assert_false(is_instance_valid(card) and not card.is_queued_for_deletion(), "then freed")


func test_a_rebuilt_card_swaps_with_no_fade() -> void:
	UiMotion.renders = true
	var source := _source(Vector2(100, 300))
	tip.show_for(source)
	tip._position_card()
	await wait_seconds(HoverTip.FADE_IN + 0.05)
	tip._rebuild()
	tip._position_card()
	assert_eq(tip.card().modulate.a, 1.0)


func test_above_measures_from_the_anchor() -> void:
	UiMotion.renders = false
	var source := _source(Vector2(400, 700), HoverTip.Place.ABOVE)
	source.anchor = Rect2(300, 650, 600, 120)
	tip.show_for(source)
	tip._position_card()
	var card := tip.card()
	assert_eq(card.position.y + card.size.y, 650.0 - HoverTip.GAP, "8 px above the anchor's top")
	assert_eq(card.position.x + card.size.x * 0.5, 600.0, "centred on the anchor")


func test_above_falls_below_without_room() -> void:
	UiMotion.renders = false
	var source := _source(Vector2(400, 20), HoverTip.Place.ABOVE)
	tip.show_for(source)
	tip._position_card()
	assert_eq(tip.card().position.y, 60.0 + HoverTip.GAP)


func test_beside_goes_right_then_left_then_above() -> void:
	UiMotion.renders = false
	var screen := _screen()
	var source := _source(Vector2(100, 400))
	tip.show_for(source)
	tip._position_card()
	assert_eq(tip.card().position.x, 140.0 + HoverTip.GAP, "right")
	var right := _source(Vector2(screen.end.x - 100, 400))
	tip.show_for(right)
	tip._position_card()
	assert_eq(tip.card().position.x, screen.end.x - 100 - HoverTip.GAP - 200, "left")
	var wide := _source(Vector2(screen.get_center().x - 20, 400))
	wide.card_size = Vector2(screen.size.x * 0.5, 100)
	tip.show_for(wide)
	tip._position_card()
	var card := tip.card()
	assert_eq(card.position.y + card.size.y, 400.0 - HoverTip.GAP, "above, never over its neighbours")


func test_a_hover_note_wraps_at_its_max_width() -> void:
	UiMotion.renders = false
	var plain := Control.new()
	plain.set_meta(&"hover_text", "A long note. ".repeat(20))
	add_child_autofree(plain)
	tip.show_for(plain)
	tip._position_card()
	assert_almost_eq(tip.card().get_combined_minimum_size().x, HoverTip.NOTE_MAX_WIDTH, 0.5)
	var short := Control.new()
	short.set_meta(&"hover_text", "Short")
	add_child_autofree(short)
	tip.show_for(short)
	assert_lt(tip.card().get_combined_minimum_size().x, 150.0, "a short note keeps its own width")


func test_a_hover_note_can_open_beside() -> void:
	UiMotion.renders = false
	var plain := Control.new()
	plain.position = Vector2(100, 300)
	plain.size = Vector2(40, 40)
	plain.set_meta(&"hover_text", "Beside")
	plain.set_meta(&"hover_place", HoverTip.Place.BESIDE)
	add_child_autofree(plain)
	tip.show_for(plain)
	tip._position_card()
	assert_eq(tip.card().position, Vector2(140 + HoverTip.GAP, 300))


func test_a_hover_note_can_hang_below_its_button() -> void:
	UiMotion.renders = false
	var plain := Control.new()
	plain.position = Vector2(300, 100)
	plain.size = Vector2(120, 40)
	plain.set_meta(&"hover_text", "Below")
	plain.set_meta(&"hover_place", HoverTip.Place.BELOW)
	add_child_autofree(plain)
	tip.show_for(plain)
	tip._position_card()
	var card := tip.card()
	assert_eq(card.position.y, 140.0 + HoverTip.GAP, "GAP under the button")
	assert_almost_eq(card.position.x + card.size.x * 0.5, 360.0, 1.0, "centred on it")


func test_a_hover_note_can_open_left_of_its_group() -> void:
	UiMotion.renders = false
	var group := Control.new()
	group.position = Vector2(600, 20)
	group.size = Vector2(300, 40)
	add_child_autofree(group)
	var button := Control.new()
	button.position = Vector2(700, 20)
	button.size = Vector2(100, 40)
	button.set_meta(&"hover_text", "Left")
	button.set_meta(&"hover_place", HoverTip.Place.LEFT)
	button.set_meta(&"hover_anchor", group)
	add_child_autofree(button)
	tip.show_for(button)
	tip._position_card()
	var card := tip.card()
	assert_almost_eq(card.position.x + card.size.x, 600.0 - HoverTip.GAP, 1.0, "GAP left of the group, not of the button")
	assert_almost_eq(card.position.y + card.size.y * 0.5, 40.0, 1.0, "centred on it")

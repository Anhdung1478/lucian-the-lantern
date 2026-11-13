extends GutTest
## UiMotion: every helper lands its end state at once while motion is off
## (headless, Low quality, `instant`), and with motion on it eases there,
## retargets from where the node is, runs while the tree is paused, and puts
## a hidden node's alpha and place back.

var _renders: bool
var root: Control


func before_each() -> void:
	_renders = UiMotion.renders
	UiMotion.instant = false
	root = Control.new()
	root.size = Vector2(800, 600)
	add_child_autofree(root)


func after_each() -> void:
	UiMotion.renders = _renders
	UiMotion.instant = false
	get_tree().paused = false
	Engine.time_scale = 1.0


func _panel(at := Vector2(100, 200)) -> Control:
	var panel := Control.new()
	panel.position = at
	panel.size = Vector2(200, 100)
	root.add_child(panel)
	return panel


func test_off_headless_and_with_instant() -> void:
	UiMotion.renders = false
	assert_true(UiMotion.off(), "headless")
	UiMotion.renders = true
	assert_false(UiMotion.off())
	UiMotion.instant = true
	assert_true(UiMotion.off(), "the screenshot tool's flag")
	UiMotion.instant = false
	var settings := GameSettings.instance()
	var quality: String = settings.get_value(&"quality")
	settings.set_value(&"quality", "low", false)
	assert_true(UiMotion.off(), "Low quality")
	settings.set_value(&"quality", quality, false)


func test_off_sets_every_end_state_at_once() -> void:
	UiMotion.renders = false
	var panel := _panel()
	panel.visible = false
	assert_null(UiMotion.enter(panel))
	assert_true(panel.visible)
	assert_eq(panel.modulate.a, 1.0)
	assert_eq(panel.position, Vector2(100, 200))
	var called := [false]
	assert_null(UiMotion.exit(panel, func() -> void: called[0] = true))
	assert_false(panel.visible)
	assert_true(called[0], "then runs at once")
	UiMotion.pop_in(panel)
	assert_true(panel.visible)
	assert_eq(panel.scale, Vector2.ONE)
	UiMotion.pop_out(panel)
	assert_false(panel.visible)
	var other := _panel()
	UiMotion.swap_body(other, panel)
	assert_false(other.visible)
	assert_true(panel.visible)
	assert_false(UiMotion.is_moving(panel))


func test_enter_rises_into_place_and_fades_in() -> void:
	UiMotion.renders = true
	var panel := _panel()
	panel.visible = false
	var tween := UiMotion.enter(panel)
	assert_not_null(tween)
	assert_true(panel.visible, "visible at once")
	assert_eq(panel.modulate.a, 0.0)
	assert_eq(panel.position.y, 200.0 + UiMotion.RISE)
	assert_true(UiMotion.is_moving(panel))
	await wait_seconds(UiMotion.BASE + 0.1)
	assert_eq(panel.modulate.a, 1.0)
	assert_eq(panel.position.y, 200.0)
	assert_false(UiMotion.is_moving(panel))


func test_exit_hides_then_puts_the_look_back() -> void:
	UiMotion.renders = true
	var panel := _panel()
	var called := [false]
	UiMotion.exit(panel, func() -> void: called[0] = true)
	assert_true(panel.visible, "still there while it fades")
	assert_eq(panel.mouse_behavior_recursive, Control.MOUSE_BEHAVIOR_DISABLED, "a leaving node ignores the mouse")
	await wait_seconds(UiMotion.EXIT + 0.1)
	assert_false(panel.visible)
	assert_true(called[0])
	assert_eq(panel.modulate.a, 1.0, "a plain visible = true later shows it whole")
	assert_eq(panel.position.y, 200.0)
	assert_eq(panel.mouse_behavior_recursive, Control.MOUSE_BEHAVIOR_INHERITED)


func test_enter_during_exit_retargets_from_where_it_is() -> void:
	UiMotion.renders = true
	var panel := _panel()
	UiMotion.exit(panel)
	_step(panel, UiMotion.EXIT * 0.5)
	var alpha := panel.modulate.a
	var y := panel.position.y
	assert_between(alpha, 0.01, 0.99)
	UiMotion.enter(panel)
	assert_eq(panel.modulate.a, alpha, "no restart from 0")
	assert_eq(panel.position.y, y)
	await wait_seconds(UiMotion.BASE + 0.1)
	assert_true(panel.visible, "the exit's hide never runs")
	assert_eq(panel.modulate.a, 1.0)
	assert_eq(panel.position.y, 200.0, "back at its own place")


func test_a_child_of_a_container_only_fades() -> void:
	UiMotion.renders = true
	var box := VBoxContainer.new()
	root.add_child(box)
	var row := Label.new()
	row.text = "Row"
	box.add_child(row)
	await wait_process_frames(2)
	var y := row.position.y
	UiMotion.pop_in(row)
	assert_eq(row.position.y, y)
	assert_eq(row.scale, Vector2.ONE)
	assert_eq(row.modulate.a, 0.0)


func test_pop_in_grows_from_its_centre() -> void:
	UiMotion.renders = true
	var card := _panel()
	card.visible = false
	UiMotion.pop_in(card)
	assert_eq(card.scale, Vector2.ONE * UiMotion.POP_SCALE)
	assert_eq(card.pivot_offset, card.size * 0.5)
	await wait_seconds(UiMotion.BASE + 0.1)
	assert_eq(card.scale, Vector2.ONE)


func test_tweens_run_while_paused_and_ignore_time_scale() -> void:
	UiMotion.renders = true
	var panel := _panel()
	panel.visible = false
	get_tree().paused = true
	Engine.time_scale = 0.1
	UiMotion.enter(panel)
	# A SceneTreeTimer that runs while paused, in real seconds: GUT's own
	# waits stop with the tree.
	await get_tree().create_timer(UiMotion.BASE + 0.15, true, false, true).timeout
	Engine.time_scale = 1.0
	get_tree().paused = false
	assert_eq(panel.modulate.a, 1.0)


func test_stagger_shows_all_at_once_and_fades_them_in_turn() -> void:
	UiMotion.renders = true
	var rows: Array = [_panel(Vector2(0, 0)), _panel(Vector2(0, 120)), _panel(Vector2(0, 240))]
	for row: Control in rows:
		row.visible = false
	UiMotion.stagger(rows, 0.1)
	for row: Control in rows:
		assert_true(row.visible, "the layout settles at once")
	for row: Control in rows:
		_step(row, 0.12)
	assert_gt(rows[0].modulate.a, rows[2].modulate.a, "reading order")
	await wait_seconds(0.4)
	for row: Control in rows:
		assert_eq(row.modulate.a, 1.0)


func test_swap_body_in_a_container_shows_the_new_page_after_the_old() -> void:
	UiMotion.renders = true
	var body := VBoxContainer.new()
	root.add_child(body)
	var old := _page(body)
	var new := _page(body)
	new.visible = false
	UiMotion.swap_body(old, new)
	assert_false(new.visible, "never two pages stacked")
	await wait_seconds(UiMotion.SWAP_OUT + 0.05)
	assert_false(old.visible)
	assert_true(new.visible)
	await wait_seconds(UiMotion.SWAP_IN + 0.05)
	assert_eq(new.modulate.a, 1.0)


func test_swap_body_in_a_plain_holder_crosses_over() -> void:
	UiMotion.renders = true
	var old := _panel()
	var new := _panel()
	new.visible = false
	UiMotion.swap_body(old, new)
	assert_true(new.visible)
	assert_true(old.visible)
	await wait_seconds(UiMotion.SWAP_IN + 0.1)
	assert_false(old.visible)
	assert_eq(new.position.y, 200.0)


## Moves `node`'s running motion on by `seconds` (frame times vary headless).
func _step(node: Object, seconds: float) -> void:
	(node.get_meta(UiMotion.TWEEN_META) as Tween).custom_step(seconds)


func _page(parent: Control) -> Control:
	var page := Control.new()
	page.custom_minimum_size = Vector2(100, 50)
	parent.add_child(page)
	return page


func _overlay() -> Array:
	var backdrop := MenuBackdrop.new()
	root.add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.add_child(center)
	var button := Button.new()
	button.text = "OK"
	center.add_child(button)
	return [backdrop, center]


func test_overlay_open_and_close_off() -> void:
	UiMotion.renders = false
	var parts := _overlay()
	var backdrop: MenuBackdrop = parts[0]
	backdrop.visible = false
	UiMotion.open_overlay(backdrop, parts[1])
	assert_true(backdrop.visible)
	assert_eq(backdrop.strength, 1.0)
	var closed := [false]
	UiMotion.close_overlay(backdrop, parts[1], func() -> void: closed[0] = true)
	assert_true(closed[0], "done at once")
	assert_eq(backdrop.mouse_filter, Control.MOUSE_FILTER_STOP)
	UiMotion.close_overlay(backdrop, parts[1])
	assert_false(backdrop.visible, "no done: the backdrop hides")


func test_overlay_fades_its_backdrop_and_pops_its_card() -> void:
	UiMotion.renders = true
	var parts := _overlay()
	var backdrop: MenuBackdrop = parts[0]
	var center: Control = parts[1]
	backdrop.visible = false
	UiMotion.open_overlay(backdrop, center)
	assert_eq(backdrop.strength, 0.0)
	assert_eq(center.modulate.a, 0.0)
	await wait_seconds(UiMotion.BACKDROP_IN + UiMotion.CARD_DELAY + UiMotion.BASE + 0.1)
	assert_eq(backdrop.strength, 1.0)
	assert_eq(center.modulate.a, 1.0)
	assert_eq(center.scale, Vector2.ONE)
	var closed := [false]
	UiMotion.close_overlay(backdrop, center, func() -> void: closed[0] = true)
	assert_false(closed[0], "the look trails")
	assert_eq(backdrop.mouse_filter, Control.MOUSE_FILTER_IGNORE, "a closing overlay ignores the mouse")
	assert_eq(backdrop.mouse_behavior_recursive, Control.MOUSE_BEHAVIOR_DISABLED)
	await wait_seconds(UiMotion.EXIT + 0.1)
	assert_true(closed[0])
	assert_eq(backdrop.strength, 1.0, "put back for the next plain show")
	assert_eq(center.modulate.a, 1.0)
	assert_eq(backdrop.mouse_filter, Control.MOUSE_FILTER_STOP)


func test_reopening_a_closing_overlay_retargets() -> void:
	UiMotion.renders = true
	var parts := _overlay()
	var backdrop: MenuBackdrop = parts[0]
	var center: Control = parts[1]
	var closed := [false]
	UiMotion.close_overlay(backdrop, center, func() -> void: closed[0] = true)
	_step(backdrop, UiMotion.EXIT * 0.5)
	var strength := backdrop.strength
	var alpha := center.modulate.a
	assert_between(strength, 0.01, 0.99)
	UiMotion.open_overlay(backdrop, center)
	assert_eq(backdrop.strength, strength, "from where it was")
	assert_eq(center.modulate.a, alpha)
	await wait_seconds(UiMotion.BASE + 0.15)
	assert_false(closed[0], "done never runs")
	assert_eq(backdrop.strength, 1.0)
	assert_eq(center.modulate.a, 1.0)


func test_backdrop_strength_fades_only_the_blur() -> void:
	var backdrop := MenuBackdrop.new()
	add_child_autofree(backdrop)
	backdrop.strength = 0.25
	assert_eq(backdrop.blur.modulate.a, 0.25)
	assert_eq(backdrop.modulate.a, 1.0, "the menu on it stays whole")
	backdrop.strength = 3.0
	assert_eq(backdrop.strength, 1.0)


class Cell extends Control:
	var lit_t := 0.0
	var draws := 0

	func _draw() -> void:
		draws += 1


func test_lit_eases_a_cells_value_and_redraws() -> void:
	UiMotion.renders = true
	var cell := Cell.new()
	root.add_child(cell)
	UiMotion.lit(cell, true)
	assert_eq(cell.lit_t, 0.0)
	(cell.get_meta(UiMotion.LIT_TWEEN_META) as Tween).custom_step(UiMotion.FAST * 0.5)
	assert_between(cell.lit_t, 0.01, 0.99)
	await wait_seconds(UiMotion.FAST)
	assert_eq(cell.lit_t, 1.0)
	assert_gt(cell.draws, 1)
	UiMotion.renders = false
	UiMotion.lit(cell, false)
	assert_eq(cell.lit_t, 0.0, "at once while off")


func test_lit_on_a_plain_node_uses_a_meta_and_a_step() -> void:
	UiMotion.renders = false
	var plain := Control.new()
	root.add_child(plain)
	var seen := []
	UiMotion.lit(plain, true, func(t: float) -> void: seen.append(t))
	assert_eq(UiMotion.lit_t(plain), 1.0)
	assert_eq(seen, [1.0])


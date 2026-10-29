extends GutTest

const PREFIX := "user://test_tree_section_save_slot_"

var section: TreeSection
var confirm: ConfirmPopup


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real save.
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new(PREFIX)
	SaveGame.instance().reset()
	SaveGame.instance().slot = 1
	_remove_files()
	confirm = ConfirmPopup.new()
	add_child_autofree(confirm)
	section = TreeSection.new()
	section.confirm = confirm
	add_child_autofree(section)


func after_each() -> void:
	_remove_files()


func _remove_files() -> void:
	for n in range(1, SaveGame.SLOTS + 1):
		for file in [SaveGame.instance().path(n), SaveGame.instance().backup_path(n)]:
			if FileAccess.file_exists(file):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(file))


func _save() -> SaveGame:
	return SaveGame.instance()


func _state(id: StringName) -> StringName:
	return section.map.views[id].state()


## Buys `id` straight from the tree, `times` times, with plenty of essence.
func _buy(id: StringName, times := 1) -> void:
	var essences := _save().essences
	essences.add(Essences.BLUE, 10000)
	essences.add(Essences.ORANGE, 100)
	for i in times:
		assert_true(_save().tree.buy(id, essences), "buy %s" % id)


## A node's center where the map's own mouse events arrive.
func _center(id: StringName) -> Vector2:
	var map := section.map
	var view: TreeNodeView = map.views[id]
	return map.layer.position + (view.position + Vector2.ONE * TreeNodeView.SIZE * 0.5) * map.zoom


func _mouse(event: InputEventMouse, at: Vector2) -> void:
	event.position = at
	section.map._gui_input(event)


func _button(at: Vector2, pressed: bool, index := MOUSE_BUTTON_LEFT) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = index
	event.pressed = pressed
	_mouse(event, at)


func _drag(from: Vector2, to: Vector2) -> void:
	_button(from, true)
	_mouse(InputEventMouseMotion.new(), from.lerp(to, 0.5))
	_mouse(InputEventMouseMotion.new(), to)
	_button(to, false)


## Every Label text under `node`, depth first.
func _texts(node: Node) -> PackedStringArray:
	var out: PackedStringArray = []
	if node is Label:
		out.append(node.text)
	for child in node.get_children():
		out.append_array(_texts(child))
	return out


func test_a_new_save_hides_q_w_e_and_the_passive() -> void:
	assert_eq(section.map.views.size(), 31)
	for id in [&"skill_q", &"skill_w", &"skill_e", &"passive"]:
		assert_eq(_state(id), &"hidden", str(id))
	assert_eq(_state(&"stat_ad"), &"poor")
	assert_false(section.info.visible)


func test_clearing_act_1_opens_q_and_w_and_puts_e_at_level_1() -> void:
	_save().set_cleared(Journey.all_stage_ids(1))
	assert_eq(_state(&"skill_q"), &"poor")
	assert_eq(_state(&"skill_w"), &"poor")
	assert_eq(_save().tree.level(&"skill_e"), 1)
	assert_eq(_state(&"skill_e"), &"bought")
	assert_eq(_save().essences.amount(Essences.BLUE), 0, "E's first level is free")


func test_nodes_sit_on_their_grid_cells() -> void:
	var view: TreeNodeView = section.map.views[&"skill_r"]
	assert_eq(view.position + Vector2.ONE * TreeNodeView.SIZE * 0.5, Vector2(160 + 2 * 150, 620 - 2 * 150))
	assert_eq(section.map.layer.size, Vector2(160 * 2 + 27 * 150, 760))


func test_the_badge_reads_the_level_and_hidden_nodes_have_none() -> void:
	_buy(&"stat_ad", 2)
	assert_eq(section.map.views[&"stat_ad"].badge.text, "2/5")
	assert_eq(section.map.views[&"stat_ap"].badge.text, "0/5")
	assert_false(section.map.views[&"passive"].badge.visible)
	assert_false(section.map.views[&"skill_q"].badge.visible, "hidden until Act 1 is cleared")


func test_a_node_with_a_level_is_never_hidden() -> void:
	# Max tree (debug) ignores requirements: E is maxed before Act 1 is cleared.
	_save().tree.max_all()
	assert_eq(_state(&"skill_e"), &"maxed")
	section.select(&"skill_e")
	assert_eq(section.info.name_label.text, "E – Relentless Pursuit")
	assert_eq(section.info.cost_bar.status.text, "MAXED")


func test_buying_q_with_the_cost_bar() -> void:
	_save().tree.acts_cleared = 1
	_save().essences.add(Essences.BLUE, 1000)
	assert_eq(_state(&"skill_q"), &"open")
	section.select(&"skill_q")
	assert_true(section.info.visible)
	assert_true(section.info.cost_bar.buy())
	assert_eq(_save().tree.level(&"skill_q"), 1)
	assert_eq(_state(&"skill_q"), &"bought")
	assert_true(_state(&"passive") in [&"poor", &"open"], str(_state(&"passive")))
	assert_eq(section.info.level_label.text, "LVL 1 / 5")
	assert_eq(_save().essences.amount(Essences.BLUE), 900)


func test_five_buys_max_q_and_the_bar_reads_maxed() -> void:
	_save().tree.acts_cleared = 1
	_save().essences.add(Essences.BLUE, 5000)
	_save().essences.add(Essences.ORANGE, 50)
	section.select(&"skill_q")
	for i in 5:
		assert_true(section.info.cost_bar.buy())
	assert_eq(_state(&"skill_q"), &"maxed")
	assert_eq(section.info.cost_bar.status.text, "MAXED")
	assert_true(section.info.cost_bar.status.visible)
	assert_true(section.info.cost_bar.disabled)
	assert_false(section.info.cost_bar.buy())
	assert_eq(_save().tree.level(&"skill_q"), 5)


func test_stat_ad_at_level_two_reads_now_and_next() -> void:
	_buy(&"stat_ad", 2)
	section.select(&"stat_ad")
	assert_string_contains(section.info.value_label.text, "+8 AD → +12 AD")
	assert_eq(section.info.name_label.text, "Attack Damage")
	assert_eq(section.info.level_label.text, "LVL 2 / 5")


func test_the_info_panel_is_opaque() -> void:
	var style := section.info.get_theme_stylebox(&"panel") as StyleBoxFlat
	assert_eq(style.bg_color.a, 1.0)


func test_a_maxed_node_shows_only_its_value_in_green() -> void:
	_buy(&"stat_ad", 5)
	section.select(&"stat_ad")
	assert_eq(section.info.value_label.text, "+20 AD")
	assert_eq(section.info.value_label.get_theme_color(&"font_color"), TreeNodeView.MAXED_COLOR)


func test_the_cost_bar_shows_owned_against_cost_red_when_short() -> void:
	_save().essences.add(Essences.BLUE, 30)
	section.select(&"stat_ad")
	var bar := section.info.cost_bar
	assert_eq(bar.amount_label(Essences.BLUE).text, "30 / 50")
	assert_eq(bar.amount_label(Essences.BLUE).get_theme_color(&"font_color"), UiStyle.ERROR_COLOR)
	assert_false(bar.amount_label(Essences.ORANGE).get_parent().visible, "no orange needed")
	assert_almost_eq(bar.fill(), 0.6, 0.001)
	assert_true(bar.disabled)
	assert_false(bar.buy())


func test_the_fill_is_the_smallest_share_over_the_kinds_needed() -> void:
	_buy(&"stat_ad", 3)
	_save().essences.set_amount(Essences.BLUE, 350)
	_save().essences.set_amount(Essences.ORANGE, 1)
	section.select(&"stat_ad")
	var bar := section.info.cost_bar
	assert_eq(bar.amount_label(Essences.BLUE).text, "350 / 350")
	assert_eq(bar.amount_label(Essences.BLUE).get_theme_color(&"font_color"), UiStyle.TEXT_COLOR)
	assert_eq(bar.amount_label(Essences.ORANGE).text, "1 / 3")
	assert_almost_eq(bar.fill(), 1.0 / 3.0, 0.001)


func test_e_after_act_one_is_free() -> void:
	_save().tree.acts_cleared = 1
	section.select(&"skill_e")
	var bar := section.info.cost_bar
	assert_eq(bar.status.text, "Free")
	assert_false(bar.disabled)
	assert_almost_eq(bar.fill(), 1.0, 0.001)
	assert_true(bar.buy())
	assert_eq(_save().tree.level(&"skill_e"), 1)


func test_a_hidden_node_reads_unknown_locked_and_its_requirements() -> void:
	section.select(&"passive")
	assert_eq(section.info.name_label.text, "???")
	assert_true(section.info.requires_label.visible)
	assert_eq(section.info.requires_label.text, "Requires: Q – Piercing Light, W – Ardent Blaze or E – Relentless Pursuit")
	assert_eq(section.info.cost_bar.status.text, "LOCKED")
	assert_true(section.info.cost_bar.disabled)
	section.select(&"skill_q")
	assert_eq(section.info.requires_label.text, "Requires: Clear Act 1")
	section.select(&"stat_ad")
	assert_false(section.info.requires_label.visible)


func test_requirement_lines_for_all_any_two_and_an_act() -> void:
	var tree := _save().tree
	assert_eq(NodeInfoPanel.requirement_text(tree, tree.node(&"skill_r")),
		"Requires: Q – Piercing Light, W – Ardent Blaze, E – Relentless Pursuit and Passive – Lightslinger")
	assert_eq(NodeInfoPanel.requirement_text(tree, tree.node(&"summoner_slot_2")),
		"Requires: any 2 of Flash, Ghost, Barrier, Heal, Clarity or Smite")
	assert_eq(NodeInfoPanel.requirement_text(tree, tree.node(&"skill_e")), "Requires: Clear Act 1")
	assert_eq(NodeInfoPanel.requirement_text(tree, tree.node(&"flash_upgrade")), "Requires: Flash")


func test_hover_card_shows_the_name_and_current_value() -> void:
	_buy(&"stat_ad", 2)
	var card: Control = section.map.views[&"stat_ad"].tooltip_content()
	assert_eq(_texts(card), PackedStringArray(["Attack Damage\n+8 AD"]))
	card.free()
	card = section.map.views[&"passive"].tooltip_content()
	assert_eq(_texts(card), PackedStringArray(["???"]))
	card.free()


func test_a_click_on_a_view_emits_chosen() -> void:
	var view: TreeNodeView = section.map.views[&"stat_mr"]
	watch_signals(view)
	view.click()
	assert_signal_emitted_with_parameters(view, "chosen", [&"stat_mr"])
	assert_eq(section.info.id, &"stat_mr")
	assert_true(view.selected)


func test_the_view_starts_on_the_skills_grove_at_zoom_one() -> void:
	var map := section.map
	assert_eq(map.zoom, 1.0)
	assert_eq(map.layer.position.x, 0.0)
	var passive := _center(&"passive")
	assert_true(Rect2(Vector2.ZERO, map.size).has_point(passive), str(passive))


func test_zoom_at_clamps_and_keeps_the_point_under_the_cursor() -> void:
	var map := section.map
	var point := Vector2(700, 500)
	var under := (point.x - map.layer.position.x) / map.zoom
	map.zoom_at(point, 1.2)
	assert_almost_eq(map.zoom, 1.2, 0.001)
	assert_almost_eq((point.x - map.layer.position.x) / map.zoom, under, 0.01)
	map.zoom_at(point, 5.0)
	assert_almost_eq(map.zoom, 1.4, 0.001)
	map.zoom_at(point, 0.1)
	assert_almost_eq(map.zoom, 0.6, 0.001)
	assert_eq(map.layer.scale, Vector2.ONE * map.zoom)


func test_the_wheel_zooms_in_steps_of_a_tenth() -> void:
	var map := section.map
	_button(Vector2(600, 400), true, MOUSE_BUTTON_WHEEL_UP)
	assert_almost_eq(map.zoom, 1.1, 0.001)
	for i in 10:
		_button(Vector2(600, 400), true, MOUSE_BUTTON_WHEEL_DOWN)
	assert_almost_eq(map.zoom, 0.6, 0.001)


func test_the_pan_is_clamped_to_the_map() -> void:
	var map := section.map
	map.pan_by(Vector2(500, 0))
	assert_eq(map.layer.position.x, 0.0)
	map.pan_by(Vector2(-100000, 0))
	assert_almost_eq(map.layer.position.x, map.size.x - map.right_room - TreeMap.MAP_SIZE.x * map.zoom, 0.01)
	assert_true(map.right_room >= NodeInfoPanel.WIDTH, "the last grove can come out from under the info panel")
	map.pan_by(Vector2(0, -100000))
	assert_true(map.layer.position.y + TreeMap.MAP_SIZE.y * map.zoom >= map.size.y - 0.01, "the ground stays on screen")


func test_a_short_drag_still_selects_the_node() -> void:
	var at := _center(&"stat_ad")
	var before := section.map.layer.position
	_drag(at, at + Vector2(4, 3))
	assert_eq(section.info.id, &"stat_ad")
	assert_true(section.info.visible)
	assert_eq(section.map.layer.position, before)


func test_a_long_drag_pans_and_does_not_select() -> void:
	var at := _center(&"stat_ad")
	var before := section.map.layer.position
	_drag(at, at + Vector2(-200, 0))
	assert_false(section.info.visible)
	assert_eq(section.info.id, &"")
	assert_almost_eq(section.map.layer.position.x, before.x - 200.0, 0.01)


func test_a_click_on_empty_ground_selects_nothing() -> void:
	_drag(Vector2(5, 5), Vector2(5, 5))
	assert_false(section.info.visible)


func test_escape_closes_the_info_panel_first() -> void:
	assert_false(section.close_popup())
	section.select(&"skill_q")
	assert_true(section.close_popup())
	assert_false(section.info.visible)
	assert_false(section.map.views[&"skill_q"].selected)
	assert_false(section.close_popup())


func test_reset_is_disabled_until_something_is_bought_and_purple_is_enough() -> void:
	assert_true(section.reset_button.disabled)
	_buy(&"stat_ad")
	assert_true(section.reset_button.disabled)
	_save().essences.add(Essences.PURPLE, EvolutionTree.RESET_COST)
	assert_false(section.reset_button.disabled)


func test_reset_asks_first_and_yes_refunds_every_node() -> void:
	_save().tree.acts_cleared = 1
	var essences := _save().essences
	essences.add(Essences.BLUE, 1000)
	essences.add(Essences.PURPLE, 5)
	section.select(&"skill_q")
	section.info.cost_bar.buy()
	section.select(&"stat_ad")
	section.info.cost_bar.buy()
	assert_eq(essences.amount(Essences.BLUE), 850)
	section.reset_button.pressed.emit()
	assert_true(confirm.is_open())
	assert_eq(_save().tree.level(&"skill_q"), 1, "nothing happens before Yes")
	confirm.answer(true)
	assert_eq(essences.amount(Essences.BLUE), 1000)
	assert_eq(essences.amount(Essences.PURPLE), 0)
	for data in _save().tree.nodes():
		assert_eq(_save().tree.level(data.id), 0, str(data.id))
	assert_eq(_state(&"skill_q"), &"open")
	assert_eq(section.info.level_label.text, "LVL 0 / 5")
	assert_true(section.reset_button.disabled)


func test_reset_no_keeps_the_tree() -> void:
	_buy(&"stat_ad")
	_save().essences.add(Essences.PURPLE, 5)
	section.reset_button.pressed.emit()
	confirm.answer(false)
	assert_eq(_save().tree.level(&"stat_ad"), 1)
	assert_eq(_save().essences.amount(Essences.PURPLE), 5)


func test_buying_and_resetting_write_no_file() -> void:
	_save().tree.acts_cleared = 1
	_save().essences.add(Essences.BLUE, 1000)
	_save().essences.add(Essences.PURPLE, 5)
	section.select(&"skill_q")
	section.info.cost_bar.buy()
	section.reset_button.pressed.emit()
	confirm.answer(true)
	for n in range(1, SaveGame.SLOTS + 1):
		assert_false(_save().slot_exists(n), "slot %d" % n)


func test_the_main_screen_shows_the_tree_and_escape_closes_its_panel() -> void:
	var main := MainScreen.new()
	add_child_autofree(main)
	var tree_section := main.sections[MainScreen.SECTION_TREE] as TreeSection
	assert_not_null(tree_section)
	assert_eq(tree_section.confirm, main.confirm)
	main.show_section(MainScreen.SECTION_TREE)
	tree_section.select(&"skill_q")
	var esc := InputEventAction.new()
	esc.action = &"open_menu"
	esc.pressed = true
	main._input(esc)
	assert_false(tree_section.info.visible)
	assert_false(main.gear.visible)


func test_no_description_repeats_a_requirement() -> void:
	for data in _save().tree.nodes():
		assert_false(data.description.contains("Needs"), str(data.id))

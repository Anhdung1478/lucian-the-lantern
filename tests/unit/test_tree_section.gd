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
	section = _new_section()


func after_each() -> void:
	_remove_files()


func _remove_files() -> void:
	for n in range(1, SaveGame.SLOTS + 1):
		for file in [SaveGame.instance().path(n), SaveGame.instance().backup_path(n)]:
			if FileAccess.file_exists(file):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(file))


func _new_section() -> TreeSection:
	var made := TreeSection.new()
	made.confirm = confirm
	add_child_autofree(made)
	return made


func _save() -> SaveGame:
	return SaveGame.instance()


func _state(id: StringName) -> StringName:
	return section.views[id].state()


## Buys `id` straight from the tree, `times` times, with plenty of essence.
func _buy(id: StringName, times := 1) -> void:
	var essences := _save().essences
	essences.add(Essences.BLUE, 10000)
	essences.add(Essences.ORANGE, 100)
	for i in times:
		assert_true(_save().tree.buy(id, essences), "buy %s" % id)


## Every Label text under `node`, depth first.
func _texts(node: Node) -> PackedStringArray:
	var out: PackedStringArray = []
	if node is Label:
		out.append(node.text)
	for child in node.get_children():
		out.append_array(_texts(child))
	return out


## What `view` draws (frame, badge and name), in its page's coordinates.
func _drawn(view: TreeNodeView) -> Rect2:
	var footprint := view.footprint()
	return Rect2(view.position + footprint.position, footprint.size)


func _tab(branch: StringName) -> Button:
	return section.tabs.buttons[EvolutionTree.BRANCHES.find(branch)]


# --- Pages and tabs ----------------------------------------------------------------


func test_35_views_across_5_pages_and_one_page_shows() -> void:
	assert_eq(section.views.size(), 35)
	assert_eq(section.pages.size(), 5)
	var shown := 0
	for branch: StringName in EvolutionTree.BRANCHES:
		var page: TreePage = section.pages[branch]
		assert_eq(page.views.size(), _save().tree.branch_nodes(branch).size(), str(branch))
		for id: StringName in page.views:
			var view: TreeNodeView = page.views[id]
			assert_eq(section.views[id], view)
			assert_eq(view.get_parent(), page)
			assert_eq(view.data.branch, branch)
		if page.visible:
			shown += 1
	assert_eq(shown, 1)


func test_only_the_page_on_screen_animates() -> void:
	assert_true(section.pages[&"skills"].is_processing())
	assert_false(section.pages[&"stats"].is_processing())
	_tab(&"stats").pressed.emit()
	assert_false(section.pages[&"skills"].is_processing())
	assert_true(section.pages[&"stats"].is_processing())
	section.visible = false
	assert_false(section.pages[&"stats"].is_processing(), "another section is shown")


func test_the_tabs_switch_pages_and_light_the_chosen_one() -> void:
	for branch: StringName in EvolutionTree.BRANCHES:
		_tab(branch).pressed.emit()
		assert_eq(section.branch, branch)
		assert_eq(section.tabs.selected, branch)
		for other: StringName in EvolutionTree.BRANCHES:
			assert_eq(section.pages[other].visible, other == branch, "%s on %s" % [other, branch])
			var border := (_tab(other).get_theme_stylebox(&"normal") as StyleBoxFlat).border_color
			assert_eq(border == UiStyle.BORDER_COLOR, other == branch, "%s lit on %s" % [other, branch])


func test_the_tabs_read_their_levels_bought() -> void:
	assert_eq(section.tabs.counts[0].text, "0 / 19")
	assert_eq(section.tabs.counts[1].text, "0 / 45")
	_buy(&"stat_ad", 2)
	_buy(&"stat_hp")
	assert_eq(section.tabs.counts[1].text, "3 / 45")
	assert_eq(section.tabs.counts[4].text, "0 / 25")


func test_a_new_save_opens_on_skills() -> void:
	assert_eq(section.branch, &"skills")
	assert_true(section.pages[&"skills"].visible)
	assert_false(_save().tree.has_free())


func test_the_tree_opens_on_the_first_branch_with_a_free_upgrade() -> void:
	# After 1-1, E's first level is put in the tree and Ghost is free to claim.
	_save().set_cleared(Journey.all_stage_ids(1))
	assert_eq(_save().tree.free_ids(), [&"ghost"] as Array[StringName])
	var opened := _new_section()
	assert_eq(opened.branch, &"summoners")
	assert_true(opened.pages[&"summoners"].visible)
	assert_false(opened.pages[&"skills"].visible)
	_save().tree.buy(&"ghost", _save().essences)
	assert_eq(_new_section().branch, &"skills", "nothing free: Skills")


func test_no_two_nodes_crowd_each_other_on_a_page() -> void:
	# Maxed, so every name shows.
	_save().tree.max_all()
	for branch: StringName in EvolutionTree.BRANCHES:
		var ids: Array = section.pages[branch].views.keys()
		for i in ids.size():
			for j in range(i + 1, ids.size()):
				assert_false(_drawn(section.views[ids[i]]).intersects(_drawn(section.views[ids[j]])), "%s and %s" % [ids[i], ids[j]])


func test_every_view_stays_inside_its_page_at_1920x1080() -> void:
	_save().tree.max_all()
	var screen := Control.new()
	screen.size = Vector2(1920, 1080)
	add_child_autofree(screen)
	var main := MainScreen.new()
	screen.add_child(main)
	var tree_section := main.sections[MainScreen.SECTION_TREE] as TreeSection
	main.show_section(MainScreen.SECTION_TREE)
	var reset := tree_section.reset_button.get_global_rect()
	for branch: StringName in EvolutionTree.BRANCHES:
		tree_section.show_branch(branch)
		var page: TreePage = tree_section.pages[branch]
		var page_rect := page.get_global_rect()
		assert_true(Rect2(Vector2.ZERO, screen.size).encloses(page_rect), str(page_rect))
		assert_true(page_rect.encloses(reset), "Reset tree is on the page")
		assert_false(page_rect.intersects(tree_section.info.get_global_rect()), "beside the info column")
		assert_false(page_rect.intersects(tree_section.tabs.get_global_rect()), "above the tabs")
		var header := Rect2(page_rect.position + TreePage.HEADER_RECT.position, TreePage.HEADER_RECT.size)
		for view: TreeNodeView in page.views.values():
			var drawn := _drawn(view)
			drawn.position += page_rect.position
			assert_true(page_rect.grow(-8.0).encloses(drawn), "%s %s" % [view.data.id, drawn])
			assert_false(drawn.intersects(reset), "%s under Reset tree" % view.data.id)
			assert_false(drawn.intersects(header), "%s under the header" % view.data.id)


# --- Nodes ----------------------------------------------------------------------------


func test_a_node_is_grey_in_silver_then_gold_then_green_with_a_crest() -> void:
	var view: TreeNodeView = section.views[&"stat_ad"]
	assert_eq(view.state(), &"poor")
	assert_true(view.is_grey(), "not bought: greyscale")
	assert_eq(TreeNodeView.state_color(&"poor"), TreeNodeView.SILVER_COLOR)
	assert_eq(TreeNodeView.state_color(&"open"), TreeNodeView.SILVER_COLOR)
	assert_eq(TreeNodeView.border_width(&"open"), TreeNodeView.THIN_BORDER)
	_buy(&"stat_ad", 2)
	assert_false(view.is_grey(), "in progress: full colour")
	assert_eq(TreeNodeView.state_color(view.state()), UiStyle.GOLD_COLOR)
	assert_eq(TreeNodeView.border_width(view.state()), TreeNodeView.BORDER)
	assert_false(view.crest.visible)
	assert_eq(view.badge.text, "2/5")
	_buy(&"stat_ad", 3)
	assert_eq(view.state(), &"maxed")
	assert_eq(TreeNodeView.state_color(view.state()), TreeNodeView.MAXED_COLOR)
	assert_true(view.crest.visible)
	assert_eq(view.badge.text, "MAX")


func test_the_ready_arrow_shows_while_the_next_level_can_be_bought() -> void:
	var view: TreeNodeView = section.views[&"stat_ad"]
	assert_false(view.ready_chip.visible, "too dear")
	_save().essences.add(Essences.BLUE, 50)
	assert_true(view.ready_chip.visible, "50 blue buys level 1")
	assert_true(_save().tree.buy(&"stat_ad", _save().essences))
	assert_false(view.ready_chip.visible, "level 2 costs 100")
	_save().tree.max_all()
	assert_false(view.ready_chip.visible, "maxed")
	assert_false(section.views[&"skill_r"].ready_chip.visible, "hidden")


func test_the_chips_stay_off_every_other_nodes_drawing() -> void:
	# First with essences to spare (the arrows), then maxed (the crests and every name).
	_save().essences.add(Essences.BLUE, 100000)
	_save().essences.add(Essences.ORANGE, 1000)
	for pass_number in 2:
		if pass_number == 1:
			_save().tree.max_all()
		var chips_seen := 0
		for branch: StringName in EvolutionTree.BRANCHES:
			var ids: Array = section.pages[branch].views.keys()
			for id in ids:
				var view: TreeNodeView = section.views[id]
				for chip: Control in [view.ready_chip, view.crest]:
					if not chip.visible:
						continue
					chips_seen += 1
					var rect := Rect2(view.position + chip.position, chip.size)
					for other in ids:
						if other != id:
							assert_false(rect.intersects(_drawn(section.views[other])), "%s chip on %s" % [id, other])
		assert_gt(chips_seen, 0, "pass %d showed chips" % pass_number)


func test_a_free_upgrade_shows_free_and_not_the_arrow() -> void:
	_save().set_cleared(Journey.all_stage_ids(1))
	var ghost: TreeNodeView = section.views[&"ghost"]
	assert_true(ghost.free_badge.visible)
	assert_false(ghost.ready_chip.visible)


func test_the_level_bar_has_a_segment_per_level_inside_the_badge() -> void:
	for count in range(1, 8):
		var segments := TreeNodeView.segment_rects(count)
		assert_eq(segments.size(), count)
		for i in count:
			assert_true(Rect2(Vector2.ZERO, TreeNodeView.BADGE_SIZE).encloses(segments[i]), "%d of %d" % [i, count])
			if i > 0:
				assert_gt(segments[i].position.x, segments[i - 1].end.x, "a gap between segments")


func test_the_info_column_greys_what_is_not_bought() -> void:
	section.show_branch(&"stats")
	var info := section.info
	var icon: TextureRect = info.rows[&"stat_ad"].get_node(^"Line/Icon")
	assert_not_null(icon.material, "not bought")
	_buy(&"stat_ad")
	assert_null(icon.material, "bought")
	section.select(&"stat_ap")
	assert_not_null(info._portrait.material, "Ability Power is not bought")
	section.select(&"stat_ad")
	assert_null(info._portrait.material)


func test_a_new_save_hides_q_w_e_and_the_passive() -> void:
	for id in [&"skill_q", &"skill_w", &"skill_e", &"passive", &"skill_r"]:
		assert_eq(_state(id), &"hidden", str(id))
	assert_eq(_state(&"stat_ad"), &"poor")


func test_clearing_act_1_opens_q_and_w_and_puts_e_at_level_1() -> void:
	_save().set_cleared(Journey.all_stage_ids(1))
	assert_eq(_state(&"skill_q"), &"poor")
	assert_eq(_state(&"skill_w"), &"poor")
	assert_eq(_save().tree.level(&"skill_e"), 1)
	assert_eq(_state(&"skill_e"), &"bought")
	assert_eq(_save().essences.amount(Essences.BLUE), 0, "E's first level is free")


func test_the_badge_reads_the_level_and_hidden_nodes_have_none() -> void:
	_buy(&"stat_ad", 2)
	assert_eq(section.views[&"stat_ad"].badge.text, "2/5")
	assert_eq(section.views[&"stat_ap"].badge.text, "0/5")
	assert_false(section.views[&"passive"].badge.visible)
	assert_false(section.views[&"skill_q"].badge.visible, "hidden until Act 1 is cleared")


func test_nodes_are_96_px_with_a_larger_badge() -> void:
	var view: TreeNodeView = section.views[&"stat_ad"]
	assert_eq(TreeNodeView.SIZE, 96.0)
	assert_eq(view.size.x, 96.0)
	assert_true(view.badge.size.x > 40.0 and view.badge.size.y > 19.0, str(view.badge.size))
	assert_eq(view.badge.get_theme_font_size(&"font_size"), TreeNodeView.BADGE_FONT)


func test_a_bought_node_whose_next_level_is_closed_shows_the_lock() -> void:
	var view: TreeNodeView = section.views[&"equip_slots"]
	assert_false(view.locked(), "level 0, open")
	_buy(&"equip_slots")
	assert_eq(view.state(), &"bought")
	assert_true(view.locked(), "slot 3 needs Act 2")
	_save().tree.acts_cleared = 2
	assert_false(view.locked())
	assert_false(section.views[&"skill_r"].locked(), "hidden nodes have no lock")
	_save().tree.max_all()
	assert_false(view.locked(), "maxed")


func test_a_node_with_a_level_is_never_hidden() -> void:
	# Max tree (debug) ignores requirements: E is maxed before Act 1 is cleared.
	_save().tree.max_all()
	assert_eq(_state(&"skill_e"), &"maxed")
	section.select(&"skill_e")
	assert_eq(section.info.name_label.text, "E – Relentless Pursuit")
	assert_eq(section.info.cost_bar.status.text, "MAXED")


func test_hover_card_shows_the_name_and_current_value() -> void:
	_buy(&"stat_ad", 2)
	var card: Control = section.views[&"stat_ad"].tooltip_content()
	assert_eq(_texts(card), PackedStringArray(["Attack Damage\n+8 AD"]))
	card.free()
	card = section.views[&"passive"].tooltip_content()
	assert_eq(_texts(card), PackedStringArray(["???"]))
	card.free()


func test_a_left_press_on_a_view_picks_it() -> void:
	section.show_branch(&"stats")
	var view: TreeNodeView = section.views[&"stat_mr"]
	watch_signals(view)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	view._gui_input(press)
	assert_signal_emitted_with_parameters(view, "chosen", [&"stat_mr"])
	assert_eq(section.info.id, &"stat_mr")
	assert_true(view.selected)


func test_picking_a_node_shows_its_page_and_a_tab_clears_the_pick() -> void:
	section.select(&"flash")
	assert_eq(section.branch, &"summoners")
	assert_true(section.pages[&"summoners"].visible)
	assert_true(section.views[&"flash"].selected)
	_tab(&"skills").pressed.emit()
	assert_eq(section.info.id, &"")
	assert_false(section.views[&"flash"].selected)
	assert_eq(section.info.name_label.text, "Skills")


# --- The info column -------------------------------------------------------------


func test_the_info_column_sums_up_the_branch_with_nothing_picked() -> void:
	var info := section.info
	assert_true(info.visible)
	assert_eq(info.id, &"")
	assert_eq(info.name_label.text, "Skills")
	assert_eq(info.blurb_label.text, TreePage.BLURBS[&"skills"])
	assert_eq(info.levels_label.text, "Levels bought 0 / 19")
	assert_eq(info.hint_label.text, "Pick a node")
	assert_true(info.hint_label.is_visible_in_tree())
	assert_false(info.cost_bar.visible)
	_buy(&"stat_ad", 2)
	_tab(&"stats").pressed.emit()
	assert_eq(info.name_label.text, "Stats")
	assert_eq(info.levels_label.text, "Levels bought 2 / 45")


func test_the_info_column_lists_the_branch_and_a_row_picks_its_node() -> void:
	var info := section.info
	assert_eq(info.rows.keys(), [&"skill_q", &"skill_w", &"skill_e", &"passive", &"skill_r"])
	assert_eq(_texts(info.rows[&"skill_q"]), PackedStringArray(["???", ""]), "hidden: no name, no level")
	_buy(&"stat_ad", 2)
	_tab(&"stats").pressed.emit()
	assert_eq(info.rows.size(), 9)
	assert_eq(_texts(info.rows[&"stat_ad"]), PackedStringArray(["Attack Damage", "2/5"]))
	info.rows[&"stat_hp"].pressed.emit()
	assert_eq(info.id, &"stat_hp")
	assert_true(section.views[&"stat_hp"].selected)


func test_picking_a_node_fills_the_info_column() -> void:
	_buy(&"stat_ad", 2)
	section.select(&"stat_ad")
	var info := section.info
	assert_eq(info.id, &"stat_ad")
	assert_eq(info.name_label.text, "Attack Damage")
	assert_eq(info.caption_label.text, "STATS")
	assert_eq(info.level_label.text, "LVL 2 / 5")
	assert_string_contains(info.value_label.text, "+8 AD → +12 AD")
	assert_true(info.cost_bar.visible)
	assert_false(info.hint_label.is_visible_in_tree())
	assert_false(info.blurb_label.is_visible_in_tree())
	assert_false(info.sum_label.visible, "only R has a rank sum")


func test_a_picked_node_lists_each_level_with_its_value_and_cost() -> void:
	_buy(&"stat_ad", 2)
	section.select(&"stat_ad")
	var ladder := section.info.ladder
	assert_eq(ladder.get_child_count(), 5)
	assert_eq(_texts(ladder.get_child(0)), PackedStringArray(["Lv 1", "+4 AD", "50", ""]))
	assert_eq(_texts(ladder.get_child(3)), PackedStringArray(["Lv 4", "+16 AD", "350", "3"]))
	assert_eq((ladder.get_child(0).get_node(^"Line/Value") as Label).get_theme_color(&"font_color"), UiStyle.TITLE_COLOR, "bought")
	assert_eq((ladder.get_child(2).get_node(^"Line/Value") as Label).get_theme_color(&"font_color"), UiStyle.TEXT_COLOR, "next")
	assert_eq((ladder.get_child(4).get_node(^"Line/Value") as Label).get_theme_color(&"font_color"), UiStyle.DIM_COLOR, "later")
	section.select(&"backpack_slots")
	assert_eq(ladder.get_child_count(), 7)
	assert_eq(_texts(ladder.get_child(6)), PackedStringArray(["Lv 7", "54 backpack slots", "1200", "25"]))


func test_r_shows_its_q_w_e_ranks() -> void:
	# R is hidden (and shows no sum) until it opens: the passive and 5 ranks.
	_save().tree.from_dict({"skill_q": 3, "skill_w": 2, "passive": 1})
	section.select(&"skill_r")
	var info := section.info
	assert_true(info.sum_label.visible)
	assert_eq(info.sum_label.text, "Q + W + E ranks: 5 / 5")
	_save().tree.from_dict({"skill_q": 3, "skill_w": 2, "skill_e": 2, "passive": 1, "skill_r": 1})
	assert_eq(info.sum_label.text, "Q + W + E ranks: 7 / 9")
	assert_eq(info.requires_label.text, "Requires: 9 levels in Q + W + E (now 7)")
	_save().tree.max_all()
	assert_eq(info.sum_label.text, "Q + W + E ranks: 15")


func test_the_info_column_is_opaque() -> void:
	var style := section.info.get_theme_stylebox(&"panel") as StyleBoxFlat
	assert_eq(style.bg_color.a, 1.0)


func test_buying_q_with_the_cost_bar() -> void:
	_save().tree.acts_cleared = 1
	_save().essences.add(Essences.BLUE, 1000)
	assert_eq(_state(&"skill_q"), &"open")
	section.select(&"skill_q")
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


# --- Buying asks first (TreePurchasePopup) -----------------------------------


## Q open and picked, with `blue` blue essence.
func _pick_q(blue := 1000) -> void:
	_save().tree.acts_cleared = 1
	_save().essences.add(Essences.BLUE, blue)
	section.select(&"skill_q")


func _open_questions() -> Array:
	return section.get_children().filter(
		func(node: Node) -> bool: return node is TreePurchasePopup and not node.is_queued_for_deletion())


func test_the_cost_bar_asks_first_and_buys_nothing() -> void:
	_pick_q()
	section.info.cost_bar.pressed.emit()
	assert_not_null(section.purchase, "a click asks first")
	assert_eq(_save().tree.level(&"skill_q"), 0, "nothing bought yet")
	assert_eq(_save().essences.amount(Essences.BLUE), 1000)


func test_buy_buys_one_level_and_closes_the_question() -> void:
	_pick_q()
	section.info.cost_bar.pressed.emit()
	section.purchase.buy_button.pressed.emit()
	assert_null(section.purchase, "the question closes")
	assert_eq(_save().tree.level(&"skill_q"), 1)
	assert_eq(_save().essences.amount(Essences.BLUE), 900)
	assert_eq(section.info.level_label.text, "LVL 1 / 5")
	assert_false(_save().slot_exists(1), "no file written")


func test_a_double_click_buys_one_level() -> void:
	_pick_q()
	var bar := section.info.cost_bar
	bar.pressed.emit()
	bar.pressed.emit()
	assert_eq(_open_questions().size(), 1, "one question")
	var buy := section.purchase.buy_button
	buy.pressed.emit()
	buy.pressed.emit()
	assert_eq(_save().tree.level(&"skill_q"), 1, "one level")
	assert_eq(_save().essences.amount(Essences.BLUE), 900)


func test_cancel_and_esc_spend_nothing() -> void:
	_pick_q()
	section.info.cost_bar.pressed.emit()
	section.purchase.cancel_button.pressed.emit()
	assert_null(section.purchase)
	section.info.cost_bar.pressed.emit()
	assert_true(section.close_popup(), "ESC closes it")
	assert_null(section.purchase)
	assert_eq(section.info.id, &"skill_q", "and keeps the pick")
	assert_eq(_save().tree.level(&"skill_q"), 0)
	assert_eq(_save().essences.amount(Essences.BLUE), 1000)


func test_the_question_shows_level_effect_price_owned_and_after() -> void:
	_save().essences.add(Essences.BLUE, 1000)
	_save().essences.add(Essences.ORANGE, 10)
	section.select(&"stat_ad")
	section.info.cost_bar.pressed.emit()
	var popup := section.purchase
	var data := _save().tree.node(&"stat_ad")
	var price := _save().tree.cost(&"stat_ad")
	assert_eq(popup.card.title_label.text, "BUY UPGRADE")
	assert_eq(popup.card.subtitle_label.text, data.display_name)
	assert_eq(popup.level_label.text, "LVL 0 → 1 / %d" % data.max_level)
	assert_eq(popup.effect_label.text, "%s → %s" % [data.value_text(0), data.value_text(1)])
	assert_false(popup.free_label.visible)
	assert_eq(popup.price_labels[Essences.BLUE].text, str(price.x))
	assert_eq(popup.owned_labels[Essences.BLUE].text, "1000")
	assert_eq(popup.after_labels[Essences.BLUE].text, str(1000 - price.x))
	assert_eq(popup.after_labels[Essences.BLUE].get_theme_color(&"font_color"), UiStyle.TITLE_COLOR)
	assert_eq(popup.price_labels[Essences.ORANGE].get_parent().visible, price.y > 0, "an essence the level doesn't need is hidden")
	assert_eq(popup.buy_button.text, "Buy")


func test_buy_is_off_while_the_level_cant_be_paid() -> void:
	_pick_q()
	section.info.cost_bar.pressed.emit()
	var popup := section.purchase
	assert_false(popup.buy_button.disabled)
	_save().essences.set_amount(Essences.BLUE, 50)
	assert_true(popup.buy_button.disabled)
	assert_eq(popup.owned_labels[Essences.BLUE].text, "50")
	assert_eq(popup.after_labels[Essences.BLUE].text, "-50")
	assert_eq(popup.after_labels[Essences.BLUE].get_theme_color(&"font_color"), UiStyle.ERROR_COLOR)
	popup.buy_button.pressed.emit()
	assert_eq(_save().tree.level(&"skill_q"), 0, "a disabled Buy buys nothing")


func test_a_free_level_asks_too_and_reads_free() -> void:
	_save().tree.acts_cleared = 1
	section.select(&"skill_e")
	section.info.cost_bar.pressed.emit()
	var popup := section.purchase
	assert_true(popup.free_label.visible)
	assert_false(popup.owned_labels[Essences.BLUE].get_parent().is_visible_in_tree(), "no You have row")
	assert_false(popup.after_labels[Essences.BLUE].get_parent().is_visible_in_tree(), "no After purchase row")
	popup.buy_button.pressed.emit()
	assert_eq(_save().tree.level(&"skill_e"), 1)


func test_a_hidden_tree_closes_the_question() -> void:
	_pick_q()
	section.info.cost_bar.pressed.emit()
	section.visible = false
	assert_null(section.purchase)


func test_the_question_s_buttons_are_clear_of_the_cost_bar() -> void:
	_pick_q()
	section.info.cost_bar.pressed.emit()
	await wait_process_frames(2)
	var bar := section.info.cost_bar.get_global_rect()
	for button: Button in [section.purchase.buy_button, section.purchase.cancel_button]:
		assert_gt(button.size.x, 0.0)
		assert_false(button.get_global_rect().intersects(bar),
			"a double-click's second click can't land on %s" % button.text)


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


func test_a_hidden_node_shows_no_value_description_or_ladder() -> void:
	section.select(&"passive")
	var info := section.info
	assert_eq(info.name_label.text, "???")
	assert_eq(info.value_label.text, "")
	assert_eq(info.description.text, "")
	assert_false(info.sum_label.visible)
	assert_eq(info.ladder.get_child_count(), 0, "no ladder rows")
	assert_true(info.requires_label.visible, "the requirement still shows")
	section.select(&"stat_ad")
	assert_gt(info.ladder.get_child_count(), 0, "a visible node has its ladder")
	assert_ne(info.description.text, "")


## The info column's content must fit its panel for every branch and every node.
func test_the_info_column_fits_its_panel_for_every_branch_and_node() -> void:
	await wait_process_frames(2)
	var limit := TreeSection.PANEL_RECT.size.y
	for state in ["fresh", "max"]:
		if state == "max":
			_save().tree.max_all()
			section.refresh()
		for branch: StringName in EvolutionTree.BRANCHES:
			section.show_branch(branch)
			await wait_process_frames(2)
			assert_lte(section.info.get_combined_minimum_size().y, limit, "%s %s" % [state, branch])
		for data in EvolutionTree.new().nodes():
			section.select(data.id)
			await wait_process_frames(2)
			assert_lte(section.info.get_combined_minimum_size().y, limit, "%s %s" % [state, data.id])


func test_requirement_lines_for_all_any_two_and_an_act() -> void:
	var tree := _save().tree
	assert_eq(tree.requirement_text(&"skill_r", 0),
		"Requires: Passive – Lightslinger and 5 levels in Q + W + E (now 0)")
	assert_eq(tree.requirement_text(&"summoner_slot_2", 0),
		"Requires: any 2 of Flash, Ghost, Barrier, Heal, Clarity or Smite")
	assert_eq(tree.requirement_text(&"skill_e", 0), "Requires: Clear Act 1")
	assert_eq(tree.requirement_text(&"flash_upgrade", 0), "Requires: Flash")


func test_no_description_repeats_a_requirement() -> void:
	for data in _save().tree.nodes():
		assert_false(data.description.contains("Needs"), str(data.id))


# --- ESC, Reset tree, the main screen ---------------------------------------------


func test_escape_clears_the_pick() -> void:
	assert_false(section.close_popup())
	section.select(&"skill_q")
	assert_true(section.close_popup())
	assert_eq(section.info.id, &"")
	assert_true(section.info.visible, "the column stays")
	assert_eq(section.info.name_label.text, "Skills")
	assert_false(section.views[&"skill_q"].selected)
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
	assert_eq(section.tabs.counts[1].text, "0 / 45")
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


func test_the_main_screen_shows_the_tree_and_escape_clears_its_pick() -> void:
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
	assert_eq(tree_section.info.id, &"")
	assert_false(tree_section.views[&"skill_q"].selected)
	assert_false(main.gear.visible)


# --- FREE badges -------------------------------------------------------------------


func _free_tabs() -> Array[StringName]:
	var out: Array[StringName] = []
	for i in EvolutionTree.BRANCHES.size():
		if section.tabs.free_badges[i].visible:
			out.append(EvolutionTree.BRANCHES[i])
	return out


func _free_nodes() -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in section.views:
		if section.views[id].free_badge.visible:
			out.append(id)
	return out


func test_a_new_save_shows_no_free_badge() -> void:
	assert_eq(_free_tabs().size(), 0)
	assert_eq(_free_nodes().size(), 0)


func test_after_1_1_the_summoners_tab_and_ghost_show_free() -> void:
	_save().set_cleared(Journey.all_stage_ids(1))
	assert_eq(_free_tabs(), [&"summoners"] as Array[StringName])
	assert_eq(_free_nodes(), [&"ghost"] as Array[StringName])


func test_claiming_ghost_clears_the_badges() -> void:
	_save().set_cleared(Journey.all_stage_ids(1))
	assert_true(_save().tree.buy(&"ghost", _save().essences))
	assert_eq(_free_tabs().size(), 0)
	assert_eq(_free_nodes().size(), 0)


func test_a_reset_shows_free_on_skills_and_summoners() -> void:
	_save().set_cleared(Journey.all_stage_ids(1))
	assert_true(_save().tree.buy(&"ghost", _save().essences))
	_save().essences.add(Essences.PURPLE, EvolutionTree.RESET_COST)
	assert_true(_save().tree.reset(_save().essences))
	assert_eq(_free_tabs(), [&"skills", &"summoners"] as Array[StringName])
	assert_true(section.views[&"skill_e"].free_badge.visible)
	assert_true(section.views[&"ghost"].free_badge.visible)


func test_the_badge_ignores_the_mouse() -> void:
	assert_eq(section.views[&"ghost"].free_badge.mouse_filter, Control.MOUSE_FILTER_IGNORE)


func test_the_free_badge_pulses_only_while_it_shows() -> void:
	var shown := FreeBadge.new()
	add_child_autofree(shown)
	assert_true(shown.is_processing(), "visible when it enters the tree")
	shown.hide()
	assert_false(shown.is_processing(), "hidden")
	shown.show()
	assert_true(shown.is_processing(), "shown again")
	var hidden := FreeBadge.new()
	hidden.visible = false
	add_child_autofree(hidden)
	assert_false(hidden.is_processing(), "hidden when it enters the tree")

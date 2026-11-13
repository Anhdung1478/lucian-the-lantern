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


func test_no_page_moves_at_rest() -> void:
	for branch: StringName in EvolutionTree.BRANCHES:
		assert_false(section.pages[branch].is_processing(), str(branch))


func test_the_tabs_switch_pages_and_light_the_chosen_one() -> void:
	for branch: StringName in EvolutionTree.BRANCHES:
		_tab(branch).pressed.emit()
		assert_eq(section.branch, branch)
		assert_eq(section.tabs.selected, branch)
		for other: StringName in EvolutionTree.BRANCHES:
			assert_eq(section.pages[other].visible, other == branch, "%s on %s" % [other, branch])
			var name_color: Color = section.tabs._names[EvolutionTree.BRANCHES.find(other)].get_theme_color(&"font_color")
			assert_eq(name_color == UiStyle.TITLE_COLOR, other == branch, "%s lit on %s" % [other, branch])
		assert_eq(section.tabs.highlight.target, _tab(branch), "the rule is under %s" % branch)


func test_the_tabs_read_their_levels_bought() -> void:
	assert_eq(section.tabs.counts[0].text, "0/19")
	assert_eq(section.tabs.counts[1].text, "0/45")
	_buy(&"stat_ad", 2)
	_buy(&"stat_hp")
	assert_eq(section.tabs.counts[1].text, "3/45")
	assert_eq(section.tabs.counts[4].text, "0/25")


func test_the_switch_is_inside_the_page_and_lighter_than_buttons() -> void:
	var page_rect := Rect2(TreeSection.PAGE_RECT.position, TreePage.SIZE)
	assert_true(page_rect.encloses(Rect2(section.tabs.position, section.tabs.size)), "inside the frame")
	for button in section.tabs.buttons:
		assert_true(button.get_theme_stylebox(&"normal") is StyleBoxEmpty, "no box")
	assert_true(section.tabs.highlight.style is StyleBoxFlat)
	assert_eq((section.tabs.highlight.style as StyleBoxFlat).bg_color.a, 0.0, "a rule, not a fill")


func test_the_switch_fits_in_vietnamese_with_two_free_pills_and_the_largest_counts() -> void:
	Lang.use(Lang.VIETNAMESE)
	var tabs := BranchTabs.new()
	add_child_autofree(tabs)
	_save().tree.max_all()
	tabs.refresh(_save().tree)
	for i in tabs.free_badges.size():
		tabs.free_badges[i].visible = i in [0, 4]
	await wait_process_frames(2)
	var width := tabs.get_combined_minimum_size().x
	Lang.use(Lang.ENGLISH)
	assert_lt(width, TreeSection.TABS_RECT.size.x, "the switch's row fits its band")


func test_the_page_and_panel_are_journeys_frame() -> void:
	assert_eq(TreeSection.PAGE_RECT, Rect2(Vector2(32, 8), JourneyMap.SIZE))
	assert_eq(TreeSection.PANEL_RECT.position.y, TreeSection.PAGE_RECT.position.y)
	assert_eq(TreeSection.PANEL_RECT.size.y, TreeSection.PAGE_RECT.size.y)


func test_the_utilities_sit_in_the_top_bar_clear_of_the_page_and_the_toast() -> void:
	await wait_process_frames(2)
	var rect := Rect2(section.utilities.position, section.utilities.size)
	assert_lt(rect.end.y, 0.0, "above the section: in the top bar")
	assert_gt(rect.position.y, -MainScreen.TOP_BAR, "inside the top bar")
	assert_almost_eq(rect.end.x, TreeSection.UTILITIES_RIGHT, 1.0, "its right end over the info column's")
	# The longest toast, in either language, centred in the top bar.
	for language: String in [Lang.ENGLISH, Lang.VIETNAMESE]:
		Lang.use(language)
		var font := section.get_theme_default_font()
		var toast := font.get_string_size(Lang.t(MainScreen.COULD_NOT_START), HORIZONTAL_ALIGNMENT_LEFT, -1, MainScreen.TOAST_FONT).x + UiStyle.INSET * 2.0
		assert_gt(rect.position.x, 960.0 + toast * 0.5 + 16.0, "%s: clear of the centred toast" % language)
	Lang.use(Lang.ENGLISH)
	assert_true(section.forge_bar.is_ancestor_of(section.forge_bar.buttons[1]))
	assert_true(section.utilities.is_ancestor_of(section.reset_button))
	assert_eq(section.forge_bar.word.text, "Forge")


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


## Every node's footprint (tile, pips, name) on every page at least 10 (8 px)
## from every other, inside the page and under the switch's band; no link
## crosses another node.
func _check_layout(language: String) -> void:
	Lang.use(language)
	var built := _new_section()
	for branch: StringName in EvolutionTree.BRANCHES:
		var page: TreePage = built.pages[branch]
		page.refresh()
		page._lay_links()
		var ids: Array = page.views.keys()
		for i in ids.size():
			var drawn := page.footprint(ids[i])
			assert_true(Rect2(Vector2.ZERO, TreePage.SIZE).grow(-24.0).encloses(drawn), "%s %s %s" % [language, ids[i], drawn])
			assert_gt(drawn.position.y, TreePage.CLEAR_TOP, "%s %s under the switch" % [language, ids[i]])
			for j in range(i + 1, ids.size()):
				assert_false(drawn.grow(10.0).intersects(page.footprint(ids[j])), "%s: %s and %s" % [language, ids[i], ids[j]])
		for link in page.links:
			var points: PackedVector2Array = link["points"]
			var line := Rect2(points[0], Vector2.ZERO).expand(points[-1])
			for id: StringName in ids:
				if id != link["to"] and id != link["from"]:
					assert_false(line.intersects(page.footprint(id)), "%s: the link %s-%s crosses %s" % [language, link["from"], link["to"], id])
	Lang.use(Lang.ENGLISH)


func test_no_two_nodes_crowd_each_other_in_either_language() -> void:
	# Maxed, so every name shows; then a new save, so every rule tag shows.
	for pass_number in 2:
		if pass_number == 0:
			_save().tree.max_all()
		else:
			_save().tree.clear()
		_check_layout(Lang.ENGLISH)
		_check_layout(Lang.VIETNAMESE)


func test_every_view_stays_inside_its_page_at_1920x1080() -> void:
	_save().tree.max_all()
	var screen := Control.new()
	screen.size = Vector2(1920, 1080)
	add_child_autofree(screen)
	var main := MainScreen.new()
	screen.add_child(main)
	var tree_section := main.sections[MainScreen.SECTION_TREE] as TreeSection
	main.show_section(MainScreen.SECTION_TREE)
	for branch: StringName in EvolutionTree.BRANCHES:
		tree_section.show_branch(branch)
		var page: TreePage = tree_section.pages[branch]
		var page_rect := page.get_global_rect()
		assert_true(Rect2(Vector2.ZERO, screen.size).encloses(page_rect), str(page_rect))
		assert_false(page_rect.intersects(tree_section.info.get_global_rect()), "beside the info column")
		assert_false(page_rect.intersects(tree_section.utilities.get_global_rect()), "the utilities are off the page")
		var tabs := tree_section.tabs.get_global_rect()
		for view: TreeNodeView in page.views.values():
			var drawn := page.footprint(view.data.id)
			drawn.position += page_rect.position
			assert_true(page_rect.grow(-8.0).encloses(drawn), "%s %s" % [view.data.id, drawn])
			assert_gt(drawn.position.y - tabs.end.y, 40.0, "%s clear of the switch" % view.data.id)


# --- Nodes ----------------------------------------------------------------------------


func test_a_node_is_grey_then_lit_then_calm() -> void:
	var view: TreeNodeView = section.views[&"stat_ad"]
	assert_eq(view.state(), &"poor")
	assert_true(view.is_grey(), "not bought: greyscale")
	assert_false(view.is_lit())
	_buy(&"stat_ad", 2)
	assert_false(view.is_grey(), "in progress: full colour")
	assert_true(view.is_lit())
	_buy(&"stat_ad", 3)
	assert_eq(view.state(), &"maxed")
	assert_true(view.is_lit())


func test_one_level_mark_a_pip_per_level_none_for_one_level() -> void:
	assert_eq(TreeNodeView.pip_centers(1).size(), 0)
	for count in range(2, 8):
		var pips := TreeNodeView.pip_centers(count)
		assert_eq(pips.size(), count)
		assert_gt(pips[0].x - TreeNodeView.PIP * 0.5, 0.0, "inside the tile's width")
		assert_lt(pips[-1].x + TreeNodeView.PIP * 0.5, TreeNodeView.SIZE)
		assert_gt(pips[0].y - TreeNodeView.PIP * 0.5, TreeNodeView.SIZE, "under the tile")
		assert_lt(pips[0].y + TreeNodeView.PIP * 0.5 + 8.0, TreeNodeView.NAME_TOP, "8 clear of the name")


func test_a_free_upgrade_shows_free_in_the_level_marks_place() -> void:
	_save().set_cleared(Journey.all_stage_ids(1))
	var ghost: TreeNodeView = section.views[&"ghost"]
	assert_true(ghost.free_badge.visible)
	assert_lt(ghost.free_badge.position.y + FreeBadge.SIZE.y, TreeNodeView.NAME_TOP, "above the name")
	assert_gt(ghost.free_badge.position.y, TreeNodeView.SIZE, "under the tile")


func test_the_next_step_is_free_first_then_the_cheapest_you_can_buy_else_none() -> void:
	var tree := _save().tree
	var essences := _save().essences
	assert_eq(TreeSection.next_step(tree, essences, &"stats"), &"", "nothing can be bought")
	essences.add(Essences.BLUE, 60)
	assert_eq(TreeSection.next_step(tree, essences, &"stats"), &"stat_ad", "level 1s cost 50: the first")
	assert_true(tree.buy(&"stat_ad", essences))
	essences.add(Essences.BLUE, 100)
	assert_eq(TreeSection.next_step(tree, essences, &"stats"), &"stat_ap", "AD's next is 100, AP's 50")
	_save().set_cleared(Journey.all_stage_ids(1))
	assert_eq(TreeSection.next_step(tree, essences, &"summoners"), &"ghost", "a free level first")


func test_only_the_next_step_wears_gold_and_only_at_rest() -> void:
	_save().essences.add(Essences.BLUE, 60)
	section.show_branch(&"stats")
	var gold := section.views.values().filter(func(view: TreeNodeView) -> bool: return view.next)
	assert_eq(gold.size(), 1)
	assert_eq(gold[0].data.id, &"stat_ad")
	section.select(&"stat_hp")
	assert_false(section.views.values().any(func(view: TreeNodeView) -> bool: return view.next), "a pick takes over")
	section.close_popup()
	assert_true(section.views[&"stat_ad"].next, "back at rest")
	_save().essences.set_amount(Essences.BLUE, 0)
	assert_false(section.views[&"stat_ad"].next, "nothing to act on: no gold")


func test_a_hidden_node_says_what_opens_it_where_its_name_goes() -> void:
	assert_eq(section.views[&"skill_q"].shown_name(), "Clear Act 1")
	assert_eq(section.views[&"passive"].shown_name(), "Any of Q, W, E")
	assert_eq(section.views[&"skill_r"].shown_name(), "Clear Act 2")
	assert_eq(section.views[&"summoner_slot_2"].shown_name(), "Any 2 spells")
	assert_eq(section.views[&"flash_upgrade"].shown_name(), "", "the link to Flash says it")
	_save().set_cleared(Journey.all_stage_ids(1))
	assert_eq(section.views[&"skill_q"].shown_name(), "Q – Piercing Light")


func test_links_only_for_all_of_requirements_lit_by_the_needed_node() -> void:
	var skills: TreePage = section.pages[&"skills"]
	var summoners: TreePage = section.pages[&"summoners"]
	skills._lay_links()
	summoners._lay_links()
	assert_eq(skills.links.size(), 1)
	assert_eq([skills.links[0]["from"], skills.links[0]["to"]], [&"passive", &"skill_r"])
	assert_eq(summoners.links.size(), 6)
	for branch: StringName in [&"stats", &"backpack", &"economy"]:
		section.pages[branch]._lay_links()
		assert_eq(section.pages[branch].links.size(), 0, str(branch))
	for link in summoners.links:
		assert_eq(link["to"], StringName(String(link["from"]) + "_upgrade"))


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


func test_nodes_are_96_px() -> void:
	var view: TreeNodeView = section.views[&"stat_ad"]
	assert_eq(TreeNodeView.SIZE, 96.0)
	assert_eq(view.size, Vector2(96, 96))


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
	assert_eq(section.info.cost_bar.status.text, "Maxed")


func test_hover_card_shows_the_name_and_current_value() -> void:
	_buy(&"stat_ad", 2)
	var card: Control = section.views[&"stat_ad"].tooltip_content()
	assert_eq(_texts(card), PackedStringArray(["+8 AD"]), "review r1 D9: the name is under the node already")
	card.free()
	card = section.views[&"passive"].tooltip_content()
	assert_eq(_texts(card), PackedStringArray([_save().tree.requirement_text(&"passive", 0)]), "a hidden node says what opens it")
	card.free()
	var view: TreeNodeView = section.views[&"stat_ad"]
	var frame := view.get_global_transform() * Rect2(Vector2.ZERO, Vector2.ONE * TreeNodeView.SIZE)
	assert_almost_eq(view.tooltip_anchor().end.x + HoverTip.GAP, frame.end.x + TreeNodeView.CARD_GAP, 0.01, "12 px off the frame")


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
	assert_eq(section.info.name_label.text, "Clear Act 1", "a new save's Skills waits for Act 1")


# --- The info column -------------------------------------------------------------


func test_at_rest_a_new_saves_skills_says_clear_act_1_and_has_no_action() -> void:
	var info := section.info
	assert_eq(info.id, &"")
	assert_eq(info.subject, &"")
	assert_eq(info.caption_label.text, "NEXT STEP")
	assert_eq(info.name_label.text, "Clear Act 1")
	assert_eq(info.value_label.text, "Opens 3 nodes on this branch.")
	assert_false(info.cost_bar.visible, "no dead button")
	assert_true(info.journey_button.visible, "the step it names is on the Journey")
	var asked := []
	section.journey_requested.connect(func() -> void: asked.append(true))
	info.journey_button.pressed.emit()
	assert_eq(asked.size(), 1)
	assert_true(info.waiting.visible)
	var rules: PackedStringArray = []
	for row in info.waiting.get_children():
		rules.append(_texts(row)[0])
	assert_eq(rules, PackedStringArray(["Any of Q, W, E",
		"Passive – Lightslinger and Clear Act 2 and 5 levels in Q + W + E (now 0)"]), "the tag's words, no Requires:")


func test_at_rest_the_branch_lists_what_its_bought_nodes_give() -> void:
	_buy(&"stat_ad", 2)
	_buy(&"stat_hp")
	_tab(&"stats").pressed.emit()
	var info := section.info
	assert_true(info.gives.visible)
	var values: PackedStringArray = []
	for row in info.gives.get_children():
		if row.visible:
			values.append(_texts(row)[-1])
	assert_eq(values, PackedStringArray(["+8", "+40"]), "the value alone beside the name")
	section.select(&"stat_ad")
	assert_true(info.gives.visible, "a pick keeps the branch's rows")
	assert_eq(NodeInfoPanel.short_value(_save().tree.node(&"skill_q"), 3), "Rank 3", "words stay when the value is not a number")


func test_at_rest_the_panel_shows_the_fact_that_chose_its_node() -> void:
	var info := section.info
	_tab(&"stats").pressed.emit()
	assert_eq(info.subject, &"stat_ad", "nothing affordable: the cheapest open level")
	assert_eq(info.caption_label.text, "SAVING FOR")
	assert_false(section.views[&"stat_ad"].next, "no gold on what can't be bought")
	_save().essences.add(Essences.BLUE, 60)
	assert_eq(info.caption_label.text, "CHEAPEST UPGRADE")
	assert_true(section.views[&"stat_ad"].next)
	assert_true(info.cost_bar.visible)
	assert_eq(info.cost_bar.id, &"stat_ad")
	_save().set_cleared(Journey.all_stage_ids(1))
	_tab(&"summoners").pressed.emit()
	assert_eq(info.subject, &"ghost")
	assert_eq(info.caption_label.text, "FREE TO CLAIM")
	assert_eq(info.cost_bar.status.text, "Claim for free")


func test_the_rest_action_picks_its_node_then_asks() -> void:
	_save().essences.add(Essences.BLUE, 60)
	_tab(&"stats").pressed.emit()
	section.info.cost_bar.pressed.emit()
	assert_eq(section.info.id, &"stat_ad", "picked, so the panel stays on it")
	assert_true(section.views[&"stat_ad"].selected)
	assert_not_null(section.purchase)
	section.purchase.buy_button.pressed.emit()
	assert_eq(_save().tree.level(&"stat_ad"), 1)
	assert_eq(section.info.subject, &"stat_ad")


func test_a_finished_branch_lists_what_it_gives() -> void:
	_save().tree.max_all()
	_tab(&"economy").pressed.emit()
	var info := section.info
	assert_eq(info.caption_label.text, "BRANCH COMPLETE")
	assert_true(info.gives.visible)
	assert_eq(info.gives.get_child_count(), 5)
	assert_false(info.cost_bar.visible)


func test_picking_a_node_fills_the_info_column() -> void:
	_buy(&"stat_ad", 2)
	section.select(&"stat_ad")
	var info := section.info
	assert_eq(info.id, &"stat_ad")
	assert_eq(info.name_label.text, "Attack Damage")
	assert_eq(info.caption_label.text, "OFFENSE", "its group, not the branch (said once, on the switch)")
	assert_eq(info.value_label.text, "+8 AD → +12 AD")
	assert_true(info.cost_bar.visible)
	assert_false(info.waiting.visible)


func test_a_picked_node_lists_each_level_and_its_price_once() -> void:
	_buy(&"stat_ad", 2)
	section.select(&"stat_ad")
	var ladder := section.info.ladder
	assert_eq(ladder.get_child_count(), 5)
	var row := func(i: int) -> PackedStringArray:
		var shown: PackedStringArray = []
		for label in [ladder.get_child(i).get_node(^"Line/Level"), ladder.get_child(i).get_node(^"Line/Value")]:
			shown.append(label.text)
		var tag: Label = ladder.get_child(i).get_node(^"Line/Next")
		if tag.visible:
			shown.append(tag.text)
		var price: Control = ladder.get_child(i).get_node(^"Line/Price")
		if price.visible:
			shown.append_array(_texts(price))
		return shown
	assert_eq(row.call(0), PackedStringArray(["Lv 1", "+4 AD", "50"]))
	assert_eq(row.call(2), PackedStringArray(["Lv 3", "+12 AD", "Next"]), "its price is on the action")
	assert_eq(row.call(3), PackedStringArray(["Lv 4", "+16 AD", "350", "3"]))
	assert_eq((ladder.get_child(0).get_node(^"Line/Value") as Label).get_theme_color(&"font_color"), UiStyle.TITLE_COLOR, "bought")
	assert_eq((ladder.get_child(2).get_node(^"Line/Value") as Label).get_theme_color(&"font_color"), UiStyle.TEXT_COLOR, "next")
	assert_eq((ladder.get_child(4).get_node(^"Line/Value") as Label).get_theme_color(&"font_color"), UiStyle.DIM_COLOR, "later")
	assert_eq(section.info.cost_bar.amount_label(Essences.BLUE).text, "200")
	section.select(&"backpack_slots")
	assert_eq(ladder.get_child_count(), 7)
	assert_true(section.info.preview.visible, "the cells' preview")
	assert_eq(section.info.preview_label.text, "5 of 54 cells open")


func test_the_backpack_previews_go_with_their_nodes() -> void:
	section.select(&"equip_slots")
	assert_eq(section.info.preview_label.text, "1 of 6 slots open")
	section.select(&"boots")
	assert_eq(section.info.preview_label.text, "No boots yet")
	_buy(&"boots")
	assert_eq(section.info.preview_label.text, "Wearing Boots of Speed")
	section.select(&"stat_ad")
	assert_false(section.info.preview.visible)


func test_r_says_what_its_next_rank_needs() -> void:
	_save().tree.acts_cleared = 2
	_save().tree.from_dict({"skill_q": 3, "skill_w": 2, "skill_e": 2, "passive": 1, "skill_r": 1})
	section.select(&"skill_r")
	assert_eq(section.info.requires_label.text, "Requires: 9 levels in Q + W + E (now 7)")
	assert_eq(section.info.cost_bar.status.text, "Locked")


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
	assert_eq(section.info.value_label.text, "Rank 1 → Rank 2")
	assert_eq(_save().essences.amount(Essences.BLUE), 900)


func test_five_buys_max_q_and_the_bar_reads_maxed() -> void:
	_save().tree.acts_cleared = 1
	_save().essences.add(Essences.BLUE, 5000)
	_save().essences.add(Essences.ORANGE, 50)
	section.select(&"skill_q")
	for i in 5:
		assert_true(section.info.cost_bar.buy())
	assert_eq(_state(&"skill_q"), &"maxed")
	assert_eq(section.info.cost_bar.status.text, "Maxed")
	assert_true(section.info.cost_bar.status.visible)
	assert_true(section.info.cost_bar.disabled)
	assert_false(section.info.cost_bar.buy())
	assert_eq(_save().tree.level(&"skill_q"), 5)


func test_a_maxed_node_shows_only_its_value_in_green() -> void:
	_buy(&"stat_ad", 5)
	section.select(&"stat_ad")
	assert_eq(section.info.value_label.text, "+20 AD")
	assert_eq(section.info.value_label.get_theme_color(&"font_color"), UiStyle.GOOD_COLOR)


func test_the_action_shows_the_price_once_red_when_short() -> void:
	_save().essences.add(Essences.BLUE, 30)
	section.select(&"stat_ad")
	var bar := section.info.cost_bar
	assert_eq(bar.amount_label(Essences.BLUE).text, "50", "the price, not owned / cost")
	assert_eq(bar.amount_label(Essences.BLUE).get_theme_color(&"font_color"), UiStyle.ERROR_COLOR)
	assert_false(bar.amount_label(Essences.ORANGE).get_parent().visible, "no orange needed")
	assert_almost_eq(bar.fill(), 0.6, 0.001)
	assert_true(bar.disabled)
	assert_false(bar.buy())
	_save().essences.add(Essences.BLUE, 20)
	assert_false(bar.disabled)
	assert_eq(bar.verb.text, "Buy")
	assert_eq(bar.amount_label(Essences.BLUE).get_theme_color(&"font_color"), UiStyle.TEXT_COLOR)


func test_the_fill_is_the_smallest_share_over_the_kinds_needed() -> void:
	_buy(&"stat_ad", 3)
	_save().essences.set_amount(Essences.BLUE, 350)
	_save().essences.set_amount(Essences.ORANGE, 1)
	section.select(&"stat_ad")
	var bar := section.info.cost_bar
	assert_eq(bar.amount_label(Essences.BLUE).text, "350")
	assert_eq(bar.amount_label(Essences.BLUE).get_theme_color(&"font_color"), UiStyle.TEXT_COLOR)
	assert_eq(bar.amount_label(Essences.ORANGE).text, "3")
	assert_eq(bar.amount_label(Essences.ORANGE).get_theme_color(&"font_color"), UiStyle.ERROR_COLOR)
	assert_almost_eq(bar.fill(), 1.0 / 3.0, 0.001)


func test_e_after_act_one_is_free() -> void:
	_save().tree.acts_cleared = 1
	section.select(&"skill_e")
	var bar := section.info.cost_bar
	assert_eq(bar.status.text, "Claim for free")
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
	return section.question_host().get_children().filter(
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
	assert_eq(section.info.value_label.text, "Rank 1 → Rank 2")
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


func _rule_rows() -> Array[PackedStringArray]:
	var out: Array[PackedStringArray] = []
	for row in section.info.rules.get_children():
		out.append(_texts(row))
	return out


func test_a_hidden_node_reads_its_rule_as_rows_met_or_not() -> void:
	section.select(&"passive")
	assert_eq(section.info.name_label.text, "Hidden node")
	assert_eq(_rule_rows(), [PackedStringArray(["Any of Q, W, E", "0 / 1"])])
	assert_eq(section.info.cost_bar.status.text, "Locked")
	assert_true(section.info.cost_bar.disabled)
	section.select(&"skill_q")
	assert_eq(_rule_rows(), [PackedStringArray(["Clear Act 1", "Not yet"])])
	_save().tree.acts_cleared = 1
	_save().tree.from_dict({"skill_q": 3, "skill_w": 1, "passive": 1})
	section.select(&"skill_r")
	assert_eq(_rule_rows(), [PackedStringArray(["Passive – Lightslinger", "Bought"]), PackedStringArray(["Clear Act 2", "Not yet"]),
		PackedStringArray(["5 levels in Q + W + E", "4 / 5"])])
	section.select(&"stat_ad")
	assert_false(section.info.rules.visible)


func test_a_hidden_node_shows_no_value_description_or_ladder() -> void:
	section.select(&"passive")
	var info := section.info
	assert_false(info.value_label.visible)
	assert_false(info.description.visible)
	assert_false(info.ladder.visible, "no ladder")
	assert_true(info.rules.visible, "its rule shows")
	section.select(&"stat_ad")
	assert_true(info.ladder.visible)
	assert_ne(info.description.text, "")


func test_the_purchase_question_covers_the_whole_screen_and_blocks_the_top_bar() -> void:
	var screen := Control.new()
	screen.size = Vector2(1920, 1080)
	add_child_autofree(screen)
	var main := MainScreen.new()
	screen.add_child(main)
	var tree_section := main.sections[MainScreen.SECTION_TREE] as TreeSection
	main.show_section(MainScreen.SECTION_TREE)
	_save().tree.acts_cleared = 1
	_save().essences.add(Essences.BLUE, 1000)
	tree_section.select(&"skill_q")
	tree_section.info.cost_bar.pressed.emit()
	await wait_process_frames(2)
	var question := tree_section.purchase
	assert_eq(question.get_parent(), main, "beside the Reset question, over everything")
	assert_eq(question.mouse_filter, Control.MOUSE_FILTER_STOP)
	for control: Control in [tree_section.forge_bar.buttons[1], tree_section.reset_button, main.section_bar]:
		assert_true(question.get_global_rect().encloses(control.get_global_rect()), "%s is under the question" % control.name)
	assert_gt(question.get_index(), main.section_bar.get_parent().get_index(), "drawn and picked after the bars")
	question.close()


func test_the_forge_and_reset_notes_hang_under_their_buttons() -> void:
	for control: Control in [section.forge_bar.buttons[1], section.forge_bar.buttons[10], section.reset_button]:
		assert_eq(control.get_meta(&"hover_place", -1), HoverTip.Place.BELOW)


func test_requirement_lines_for_all_any_two_and_an_act() -> void:
	var tree := _save().tree
	assert_eq(tree.requirement_text(&"skill_r", 0),
		"Requires: Passive – Lightslinger and Clear Act 2 and 5 levels in Q + W + E (now 0)")
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
	assert_eq(section.info.name_label.text, "Clear Act 1")
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
	assert_eq(section.info.value_label.text, "None → +4 AD", "the pick (Attack Damage) stays, at level 0")
	assert_eq(section.tabs.counts[1].text, "0/45")
	assert_true(section.reset_button.disabled)


func test_free_levels_alone_leave_reset_off_and_say_why() -> void:
	_save().set_cleared(Journey.all_stage_ids(1))
	assert_true(_save().tree.buy(&"ghost", _save().essences))
	_save().essences.add(Essences.PURPLE, EvolutionTree.RESET_COST)
	assert_true(section.reset_button.disabled, "E and Ghost were free: nothing would come back")
	assert_eq(section.reset_button.get_meta(&"hover_text", ""), "Nothing to refund: no blue or orange essence spent")
	section.reset_button.pressed.emit()
	assert_false(confirm.is_open())
	assert_eq(_save().essences.amount(Essences.PURPLE), EvolutionTree.RESET_COST)
	_buy(&"stat_ad")
	assert_false(section.reset_button.disabled)
	assert_false(section.reset_button.has_meta(&"hover_text"))
	_save().essences.set_amount(Essences.PURPLE, 0)
	assert_eq(section.reset_button.get_meta(&"hover_text", ""), "Needs 5 purple essence")


func test_the_reset_question_names_what_comes_back() -> void:
	_buy(&"stat_ad", 4)
	_save().essences.add(Essences.PURPLE, EvolutionTree.RESET_COST)
	section.reset_button.pressed.emit()
	assert_true(confirm.is_open())
	assert_eq(confirm._message.text, "Reset the Evolution Tree for 5 purple essence? 700 blue and 3 orange essence come back.")
	confirm.answer(false)
	assert_eq(section.reset_question(), "Reset the Evolution Tree for 5 purple essence? 700 blue and 3 orange essence come back.")


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


## V1.5 (P5): R's rank 1 is a free claim once Act 2 is cleared, the passive
## learned and Q + W + E at 5 ranks.
func test_after_act_2_r_shows_free_once_its_ranks_and_passive_are_there() -> void:
	_save().set_cleared(Journey.all_stage_ids(2))
	_save().tree.from_dict({"skill_q": 3, "skill_e": 1, "ghost": 1})
	assert_eq(_free_nodes().size(), 0, "no passive, 4 ranks")
	_save().tree.from_dict({"skill_q": 3, "skill_w": 1, "skill_e": 1, "passive": 1, "ghost": 1})
	assert_eq(_free_nodes(), [&"skill_r"] as Array[StringName])
	assert_eq(_free_tabs(), [&"skills"] as Array[StringName])
	section.select(&"skill_r")
	assert_eq(section.info.cost_bar.status.text, "Claim for free")
	assert_true(section.info.cost_bar.buy())
	assert_eq(_save().tree.level(&"skill_r"), 1)
	assert_eq(_free_nodes().size(), 0)


func test_claiming_ghost_clears_the_badges() -> void:
	_save().set_cleared(Journey.all_stage_ids(1))
	assert_true(_save().tree.buy(&"ghost", _save().essences))
	assert_eq(_free_tabs().size(), 0)
	assert_eq(_free_nodes().size(), 0)


func test_a_reset_shows_free_on_skills_and_summoners() -> void:
	_save().set_cleared(Journey.all_stage_ids(1))
	assert_true(_save().tree.buy(&"ghost", _save().essences))
	_buy(&"stat_ad")
	_save().essences.add(Essences.PURPLE, EvolutionTree.RESET_COST)
	assert_true(_save().tree.reset(_save().essences))
	assert_eq(_free_tabs(), [&"skills", &"summoners"] as Array[StringName])
	assert_true(section.views[&"skill_e"].free_badge.visible)
	assert_true(section.views[&"ghost"].free_badge.visible)


func test_the_badge_ignores_the_mouse() -> void:
	assert_eq(section.views[&"ghost"].free_badge.mouse_filter, Control.MOUSE_FILTER_IGNORE)


func test_the_free_badge_holds_still() -> void:
	var shown := FreeBadge.new()
	add_child_autofree(shown)
	await wait_process_frames(3)
	assert_false(shown.is_processing())
	assert_eq(shown.modulate.a, 1.0)


func test_forge_buttons_forge_one_and_ten_and_the_amounts_update() -> void:
	_save().essences.add(Essences.BLUE, 1500)
	var one: Button = section.forge_bar.buttons[1]
	var ten: Button = section.forge_bar.buttons[10]
	assert_false(one.disabled)
	assert_false(ten.disabled)
	one.pressed.emit()
	assert_eq(_save().essences.amount(Essences.BLUE), 1380)
	assert_eq(_save().essences.amount(Essences.ORANGE), 1)
	ten.pressed.emit()
	assert_eq(_save().essences.amount(Essences.BLUE), 180)
	assert_eq(_save().essences.amount(Essences.ORANGE), 11)
	assert_true(ten.disabled, "180 blue is short of 1200")
	assert_false(one.disabled)


func test_forge_is_disabled_and_says_what_it_needs_when_blue_is_short() -> void:
	var one: Button = section.forge_bar.buttons[1]
	var ten: Button = section.forge_bar.buttons[10]
	_save().essences.set_amount(Essences.BLUE, Essences.FORGE_BLUE)
	# Review r1 D13: an off forge's amounts and icons dim with it.
	for part in ten.get_node(^"Row").get_children():
		if part is Label:
			assert_eq(part.get_theme_color(&"font_color"), UiStyle.DISABLED_FONT, "off: %s" % part.text)
	for part in one.get_node(^"Row").get_children():
		if part is Label:
			assert_eq(part.get_theme_color(&"font_color"), UiStyle.TEXT_COLOR, "on: %s" % part.text)
	_save().essences.set_amount(Essences.BLUE, 0)
	assert_true(one.disabled)
	assert_eq(one.get_meta(&"hover_text", ""), "Needs 120 blue essence")
	assert_eq(ten.get_meta(&"hover_text", ""), "Needs 1200 blue essence")
	_save().essences.add(Essences.BLUE, 119)
	assert_true(one.disabled)
	_save().essences.add(Essences.BLUE, 1)
	assert_false(one.disabled)
	assert_true(ten.disabled)
	assert_string_contains(one.get_meta(&"hover_text", ""), "cannot be undone")
	one.pressed.emit()
	assert_true(one.disabled)
	assert_eq(one.get_meta(&"hover_text", ""), "Needs 120 blue essence")


func test_forge_shows_its_rate_with_both_icons() -> void:
	for count: int in ForgeBar.COUNTS:
		var texts: PackedStringArray = []
		var icons := 0
		for child in section.forge_bar.buttons[count].get_child(0).get_children():
			if child is Label:
				texts.append(child.text)
			elif child is TextureRect:
				icons += 1
		assert_eq(texts, PackedStringArray([str(count * Essences.FORGE_BLUE), "→", str(count)]))
		assert_eq(icons, 2)


func test_a_reset_keeps_forged_orange_and_refunds_as_before() -> void:
	_save().tree.acts_cleared = 1
	_save().essences.add(Essences.BLUE, 1000)
	_save().essences.add(Essences.PURPLE, 5)
	section.forge_bar.buttons[1].pressed.emit()
	section.select(&"skill_q")
	section.info.cost_bar.buy()
	var spent := _save().tree.spent()
	var blue := _save().essences.amount(Essences.BLUE)
	var orange := _save().essences.amount(Essences.ORANGE)
	section.reset_button.pressed.emit()
	confirm.answer(true)
	assert_eq(_save().essences.amount(Essences.BLUE), blue + spent.x)
	assert_eq(_save().essences.amount(Essences.ORANGE), orange + spent.y)
	assert_gte(_save().essences.amount(Essences.ORANGE), 1, "the forged orange stays")


func test_a_forge_is_kept_by_the_next_save_and_writes_no_file_itself() -> void:
	_save().essences.add(Essences.BLUE, 240)
	section.forge_bar.buttons[1].pressed.emit()
	for n in range(1, SaveGame.SLOTS + 1):
		assert_false(_save().slot_exists(n), "slot %d" % n)
	assert_true(_save().save())
	_save().essences.from_dict({})
	assert_true(_save().load_slot(1))
	assert_eq(_save().essences.amount(Essences.ORANGE), 1)
	assert_eq(_save().essences.amount(Essences.BLUE), 120)


# --- Motion ----------------------------------------------------------------------------


func test_with_motion_off_a_purchase_reaches_its_end_state_at_once() -> void:
	_save().set_cleared(Journey.all_stage_ids(1))
	_buy(&"flash")
	var upgrade: TreeNodeView = section.views[&"flash_upgrade"]
	assert_eq(upgrade.known_t, 1.0, "opened at once")
	assert_eq(section.views[&"flash"].light_t, 1.0)
	assert_eq(section.pages[&"summoners"]._link_fill["flash>flash_upgrade"], 1.0)
	assert_false(section.pages[&"summoners"].is_playing())


func test_a_purchase_plays_in_order_and_a_second_one_retargets() -> void:
	var renders := UiMotion.renders
	UiMotion.renders = true
	_save().set_cleared(Journey.all_stage_ids(1))
	section.show_branch(&"summoners")
	var page: TreePage = section.pages[&"summoners"]
	var flash: TreeNodeView = section.views[&"flash"]
	var upgrade: TreeNodeView = section.views[&"flash_upgrade"]
	_buy(&"flash")
	assert_true(page.is_playing())
	assert_lt(flash.light_t, 1.0, "the light eases in")
	assert_eq(upgrade.known_t, 0.0, "it unveils after the light arrives")
	await wait_seconds(TreePage.LINK_START + TreePage.LINK_TIME * 0.5)
	assert_eq(flash.light_t, 1.0)
	assert_eq(upgrade.known_t, 0.0, "the light is still on its way")
	# A second purchase mid-play: the upgrade's first level.
	_buy(&"flash_upgrade")
	await wait_seconds(1.0)
	UiMotion.renders = renders
	assert_false(page.is_playing(), "everything holds still")
	assert_eq(upgrade.known_t, 1.0)
	assert_eq(upgrade.light_t, 1.0, "no half-lit end state")
	assert_eq(upgrade.pips_t, 1.0)


func test_a_reset_plays_one_stagger_inside_half_a_second() -> void:
	var renders := UiMotion.renders
	UiMotion.renders = true
	_buy(&"stat_ad", 3)
	_buy(&"stat_hp", 5)
	_buy(&"stat_mana", 2)
	section.show_branch(&"stats")
	_save().essences.add(Essences.PURPLE, EvolutionTree.RESET_COST)
	section.reset_button.pressed.emit()
	confirm.answer(true)
	var page: TreePage = section.pages[&"stats"]
	assert_true(page.is_playing())
	await wait_seconds(TreeSection.POPUP_GONE + 0.5)
	UiMotion.renders = renders
	assert_false(page.is_playing(), "done within 0.5 s of the question leaving")
	for id: StringName in page.views:
		assert_eq(page.views[id].light_t, 0.0, str(id))

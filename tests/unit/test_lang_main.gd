extends GutTest
## The main screen's translations: every text in its scripts and data has a
## Vietnamese, its screens built with Lang.probe show nothing that skipped
## Lang.t(), and the most visible texts read right in Vietnamese.

const PREFIX := "user://test_lang_main_save_slot_"
const CORE_SCRIPTS: Array[String] = ["journey", "evolution_tree", "tree_node_data", "tree_catalog", "essences", "skin_data", "skins", "wallet"]

var _root: Node


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real save.
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new(PREFIX)
	SaveGame.instance().reset()
	SaveGame.instance().slot = 1
	_remove_files()


func after_each() -> void:
	Lang.probe = false
	Lang.use(Lang.ENGLISH)
	_remove_files()


func _remove_files() -> void:
	for n in range(1, SaveGame.SLOTS + 1):
		for file in [SaveGame.instance().path(n), SaveGame.instance().backup_path(n)]:
			if FileAccess.file_exists(file):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(file))


func _scripts() -> Array:
	var paths: Array = LangProbe.scripts_in("res://src/ui/main")
	for name in CORE_SCRIPTS:
		paths.append("res://src/core/%s.gd" % name)
	return paths


func _plain(root: Node) -> Array[String]:
	return LangProbe.plain_texts(root)


func _show(node: Node) -> Node:
	add_child_autofree(node)
	return node


func test_every_text_in_the_scripts_has_a_vietnamese_or_is_listed() -> void:
	assert_eq(LangProbe.missing_in(_scripts()), [] as Array[String])


func test_every_text_in_the_data_has_a_vietnamese() -> void:
	assert_eq(LangProbe.missing_data("res://data/tree"), [] as Array[String])
	assert_eq(LangProbe.missing_data("res://data/skins"), [] as Array[String])


func test_every_skin_line_has_a_vietnamese() -> void:
	for skin in Skins.ALL:
		for line in skin.bonuses + skin.weaknesses:
			assert_true(LangProbe.known().has(line), "%s: %s" % [skin.id, line])


func test_the_journey_with_every_place_shows_nothing_plain() -> void:
	Lang.probe = true
	SaveGame.instance().set_cleared(Journey.all_stage_ids(3))
	var section := _show(JourneySection.new()) as JourneySection
	assert_eq(_plain(section), [] as Array[String], "the map")
	for id in ["1-1", "3-2", "3-5", "4-1", "6-5"]:
		section.pick(section.map.node_for(id))
		assert_eq(_plain(section), [] as Array[String], "stage %s" % id)
	for node in section.map.nodes:
		if not node.is_stage():
			section.pick(node)
			assert_eq(_plain(section), [] as Array[String], String(node.kind))
	section.loadout.open_menu(0)
	assert_eq(_plain(section), [] as Array[String], "the spell menu")


func test_the_evolution_tree_shows_nothing_plain() -> void:
	Lang.probe = true
	var confirm := _show(ConfirmPopup.new()) as ConfirmPopup
	var section := TreeSection.new()
	section.confirm = confirm
	_show(section)
	for branch: StringName in EvolutionTree.BRANCHES:
		section.show_branch(branch)
		assert_eq(_plain(section), [] as Array[String], "branch %s" % branch)
		for data in section.tree.branch_nodes(branch):
			section.select(data.id)
			assert_eq(_plain(section), [] as Array[String], "node %s" % data.id)
	SaveGame.instance().essences.add(Essences.BLUE, 5000)
	SaveGame.instance().essences.add(Essences.PURPLE, 10)
	SaveGame.instance().tree.acts_cleared = 3
	section.select(&"stat_ad")
	section.ask_buy(&"stat_ad")
	assert_eq(_plain(section), [] as Array[String], "the purchase pop-up")
	section.close_popup()
	section.tree.buy(&"stat_ad", SaveGame.instance().essences)
	assert_eq(_plain(section), [] as Array[String], "after a purchase, with Reset tree open")


func test_the_skin_shop_shows_nothing_plain() -> void:
	Lang.probe = true
	SaveGame.instance().essences.add(Essences.PURPLE, 50)
	var shop := _show(SkinShop.new()) as SkinShop
	assert_eq(_plain(shop), [] as Array[String], "the cards")
	shop.ask_purchase(&"high_noon")
	assert_eq(_plain(shop), [] as Array[String], "the purchase pop-up")
	shop.close_popup()
	shop.open_preview(&"project")
	assert_eq(_plain(shop), [] as Array[String], "the preview")


func test_the_bars_and_the_gear_menu_show_nothing_plain() -> void:
	Lang.probe = true
	var bar := _show(SectionBar.new())
	assert_eq(_plain(bar), [] as Array[String], "the section bar")
	var essences := _show(EssenceBar.new()) as EssenceBar
	essences.setup(SaveGame.instance().essences)
	assert_eq(_plain(essences), [] as Array[String], "the essence bar")
	var gear := GearMenu.new()
	_show(gear)
	gear.open()
	assert_eq(_plain(gear), [] as Array[String], "the gear menu")
	gear.show_slots()
	assert_eq(_plain(gear), [] as Array[String], "the slot list")


func test_the_toasts_and_the_overwrite_question_are_translated() -> void:
	Lang.probe = true
	var main := _show(MainScreen.new()) as MainScreen
	main._on_saved(true)
	assert_eq(main.toast_text(), "Ｓａｖｅｄ ｔｏ ｓｌｏｔ 1")
	main._on_copied(2, false)
	assert_eq(main.toast_text(), "Ｃｏｕｌｄ ｎｏｔ ｓａｖｅ")


func test_the_journey_reads_in_vietnamese() -> void:
	Lang.use(Lang.VIETNAMESE)
	SaveGame.instance().set_cleared(Journey.all_stage_ids(2))
	assert_eq(Journey.stage_name(1, 1), "Hồi 1 · Mất Mát")
	assert_eq(Journey.stage_name(3, 4), "Màn 3-4 · Khu Rừng")
	assert_eq(JourneyNode.waves_line(3, 2), "6 đợt + trùm phụ")
	assert_eq(JourneyNode.waves_line(2, 1), "4 đợt")
	var section := _show(JourneySection.new()) as JourneySection
	section.pick(section.map.node_for("3-1"))
	assert_eq(section.panel.act_label.text, "HỒI 3 · KHU RỪNG")
	assert_eq(section.panel.title_label.text, "Màn 3-1")
	assert_eq(section.panel.story_label.text, "Lucian băng qua khu rừng, đối đầu các rồng và Rồng Ngàn Tuổi.")
	assert_eq(section.panel.start_button.text, "Bắt đầu màn 1")


func test_the_bars_read_in_vietnamese() -> void:
	Lang.use(Lang.VIETNAMESE)
	var bar := _show(SectionBar.new()) as SectionBar
	var names: Array[String] = []
	for button: Button in bar.find_children("*", "Button", true, false):
		names.append(button.text)
	assert_eq(names, ["Cây Tiến Hóa", "Cửa Hàng Trang Phục", "Hành Trình"] as Array[String])
	var main := _show(MainScreen.new()) as MainScreen
	main._on_saved(true)
	assert_eq(main.toast_text(), "Đã lưu vào ô lưu 1")


func test_the_tree_reads_in_vietnamese() -> void:
	Lang.use(Lang.VIETNAMESE)
	var tree := SaveGame.instance().tree
	assert_eq(tree.node(&"stat_ad").value_text(1), "+4 SMCK")
	assert_eq(tree.node(&"stat_ad").value_text(0), "Không có")
	var needs := tree.requirement_text(&"skill_r", 1)
	assert_true(needs.begins_with("Yêu cầu: "), needs)
	assert_true(needs.ends_with(" và 9 cấp ở Q + W + E (hiện 0)"), needs)
	var section := TreeSection.new()
	section.confirm = _show(ConfirmPopup.new()) as ConfirmPopup
	_show(section)
	SaveGame.instance().essences.add(Essences.BLUE, 5000)
	tree.acts_cleared = 3
	tree.buy(&"stat_ad", SaveGame.instance().essences)
	var spent := tree.spent()
	var question := section.reset_question()
	assert_true(question.contains("Đặt lại Cây Tiến Hóa với 5 tinh chất tím?"), question)
	assert_true(question.contains("%d tinh chất xanh" % spent.x), question)
	assert_eq(section.reset_button.text, "Đặt lại cây  5")

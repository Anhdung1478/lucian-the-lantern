extends GutTest

var tree: EvolutionTree
var essences: Essences


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real settings.
	if GameSettings._instance == null or GameSettings._instance.path == GameSettings.DEFAULT_PATH:
		GameSettings._instance = GameSettings.new("user://test_tree_art_settings.json")
	tree = EvolutionTree.new()
	essences = Essences.new()
	essences.add(Essences.BLUE, 10000)
	essences.add(Essences.ORANGE, 100)


func after_each() -> void:
	GameSettings.instance().set_value(&"quality", "high")


func _page(branch: StringName) -> TreePage:
	var page := TreePage.new(branch, tree, essences)
	add_child_autofree(page)
	return page


func test_a_page_lays_out_the_same_art_every_time() -> void:
	for branch: StringName in EvolutionTree.BRANCHES:
		var page := _page(branch)
		var again := TreeArt.new(page)
		assert_eq(again.filaments, page.art.filaments, str(branch))
		assert_eq(again.junctions, page.art.junctions, str(branch))
		assert_eq(again.nebulae, page.art.nebulae, str(branch))


func test_the_astrolabe_stays_clear_of_the_switch_and_fits_the_page() -> void:
	for branch: StringName in EvolutionTree.BRANCHES:
		var art := _page(branch).art
		for rect: Rect2 in TreePage.KEEP_CLEAR:
			assert_false(TreeArt.circle_hits_rect(art.astrolabe_center, art.astrolabe_radius, rect), "%s astrolabe clear of switch" % branch)
		assert_gt(art.astrolabe_radius, 250.0, "%s astrolabe has presence" % branch)
		assert_false(art.filaments.is_empty(), "%s has constellation filaments" % branch)


func test_the_art_has_no_lanterns_or_motes_of_its_own() -> void:
	var page := _page(&"stats")
	assert_false(page.is_processing(), "nothing on the page moves at rest")
	assert_false("lantern_ids" in page.art)
	assert_false("flow_paths" in page.art)

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
		assert_eq(again.clumps, page.art.clumps, str(branch))
		assert_eq(again.trunk_left, page.art.trunk_left, str(branch))


func test_the_trunk_flares_at_the_ground_and_tapers_up() -> void:
	for branch: StringName in EvolutionTree.BRANCHES:
		var art := _page(branch).art
		for i in art.trunk_left.size():
			assert_lt(art.trunk_left[i].x, art.trunk_right[i].x, "%s edge %d" % [branch, i])
		assert_gt(art.trunk_right[0].x - art.trunk_left[0].x, 140.0, "%s root flare" % branch)
		assert_lt(art.trunk_right[-1].x - art.trunk_left[-1].x, 40.0, "%s tip" % branch)


func test_the_crown_wraps_every_node_and_stays_clear_of_the_switch() -> void:
	for branch: StringName in EvolutionTree.BRANCHES:
		var page := _page(branch)
		for clump in page.art.clumps:
			for rect: Rect2 in TreePage.KEEP_CLEAR:
				assert_false(TreeArt.circle_hits_rect(Vector2(clump.x, clump.y), clump.z * TreeArt.PUFF_REACH, rect), "%s %s" % [branch, clump])
		for id: StringName in page.centers:
			# The tile's corners, a bit out, sit in the crown: never on the sky.
			var tile := Rect2(page.centers[id] - Vector2.ONE * TreeNodeView.SIZE * 0.5, Vector2.ONE * TreeNodeView.SIZE).grow(12.0)
			for corner: Vector2 in [tile.position, Vector2(tile.end.x, tile.position.y), tile.end, Vector2(tile.position.x, tile.end.y)]:
				assert_true(page.art.in_crown(corner) or corner.y > page.art.rim_y(corner.x) - 60.0,
					"%s: %s's corner %s on the sky" % [branch, id, corner])


func test_the_art_has_no_lanterns_or_motes_of_its_own() -> void:
	var page := _page(&"stats")
	assert_false(page.is_processing(), "nothing on the page moves at rest")
	assert_false("lantern_ids" in page.art)
	assert_false("flow_paths" in page.art)

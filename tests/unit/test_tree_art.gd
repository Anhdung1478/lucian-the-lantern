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
		assert_eq(again.lantern_spots, page.art.lantern_spots, str(branch))


func test_the_trunk_flares_at_the_ground_and_tapers_up() -> void:
	for branch: StringName in EvolutionTree.BRANCHES:
		var art := _page(branch).art
		for i in art.trunk_left.size():
			assert_lt(art.trunk_left[i].x, art.trunk_right[i].x, "%s edge %d" % [branch, i])
		assert_gt(art.trunk_right[0].x - art.trunk_left[0].x, 140.0, "%s root flare" % branch)
		assert_lt(art.trunk_right[-1].x - art.trunk_left[-1].x, 40.0, "%s tip" % branch)


func test_every_node_sits_in_leaves_and_none_cover_the_header_or_reset() -> void:
	for branch: StringName in EvolutionTree.BRANCHES:
		var page := _page(branch)
		for clump in page.art.clumps:
			for rect: Rect2 in TreePage.KEEP_CLEAR:
				assert_false(TreeArt.circle_hits_rect(Vector2(clump.x, clump.y), clump.z * TreeArt.PUFF_REACH, rect), "%s %s" % [branch, clump])
		for id: StringName in page.centers:
			var near := 0
			for clump in page.art.clumps:
				if Vector2(clump.x, clump.y).distance_to(page.centers[id]) < 140.0:
					near += 1
			assert_gt(near, 3, "%s: leaves around %s" % [branch, id])


func test_lanterns_hang_clear_of_the_nodes() -> void:
	var count := 0
	for branch: StringName in EvolutionTree.BRANCHES:
		var page := _page(branch)
		for i in page.art.lantern_spots.size():
			var lantern := Rect2(page.art.lantern_spots[i] - TreeArt.LANTERN_SIZE * 0.5, TreeArt.LANTERN_SIZE)
			for view: TreeNodeView in page.views.values():
				var footprint := view.footprint()
				assert_false(lantern.intersects(Rect2(view.position + footprint.position, footprint.size)),
					"%s: %s's lantern on %s" % [branch, page.art.lantern_ids[i], view.data.id])
			count += 1
	assert_gt(count, 5, "most boughs carry one")


func test_a_lantern_lights_once_its_node_has_a_level() -> void:
	var page := _page(&"stats")
	assert_true(&"stat_ad" in page.art.lantern_ids, "Attack Damage's bough carries one")
	assert_false(&"stat_ad" in page.art.lit_lanterns(tree))
	assert_true(tree.buy(&"stat_ad", essences))
	assert_true(&"stat_ad" in page.art.lit_lanterns(tree))


func test_light_climbs_only_to_bought_nodes_and_never_on_low_effects() -> void:
	var page := _page(&"stats")
	assert_eq(page.art.flow_points(tree, 1.0).size(), 0, "nothing bought")
	assert_true(tree.buy(&"stat_ad", essences))
	var points := page.art.flow_points(tree, 1.0)
	assert_eq(points.size(), TreeArt.FLOW_MOTES)
	for point in points:
		assert_true(Rect2(Vector2.ZERO, TreePage.SIZE).has_point(point), str(point))
	GameSettings.instance().set_value(&"quality", "low")
	assert_eq(page.art.flow_points(tree, 1.0).size(), 0, "Low effects")

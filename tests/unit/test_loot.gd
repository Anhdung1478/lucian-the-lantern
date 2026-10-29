extends GutTest
## What kills drop (LootTable), and picking it up off the ground.

var rng := RandomNumberGenerator.new()
var stage: Stage
var _prefix := ""


func before_each() -> void:
	rng.seed = 11
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real save.
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new("user://test_loot_save_slot_")
	_prefix = SaveGame.instance().prefix
	SaveGame.instance().reset()


func after_each() -> void:
	SaveGame.instance().prefix = _prefix
	# A stage's result pauses the tree.
	get_tree().paused = false


func _stage() -> Stage:
	stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.new())
	add_child_autofree(stage)
	return stage


func test_normal_drop_rates() -> void:
	var catalog: ItemCatalog = load("res://data/items/catalog.tres")
	var fragments := 0
	var legendaries := 0
	for i in 20000:
		for item in LootTable.roll(&"normal", catalog, rng):
			if item.kind == ItemData.Kind.LEGENDARY:
				legendaries += 1
			else:
				fragments += 1
	assert_between(fragments, 650, 950)
	assert_between(legendaries, 20, 110)


func test_a_boss_always_drops_a_fragment() -> void:
	var catalog: ItemCatalog = load("res://data/items/catalog.tres")
	for i in 200:
		var has_fragment := false
		for item in LootTable.roll(&"boss", catalog, rng):
			has_fragment = has_fragment or item.kind == ItemData.Kind.FRAGMENT
		assert_true(has_fragment)


func test_a_kill_pays_out() -> void:
	_stage()
	var enemy := stage.spawn_enemy(&"melee_minion", Vector2(1700, 600))
	enemy.take_damage(stage.lucian.make_damage(9999, DamageInfo.Type.TRUE, &"q"))
	assert_eq(stage.wallet.gold, 60)
	assert_eq(stage.lucian.progress.xp, 30)
	assert_eq(stage.collected[Essences.BLUE], 1)
	assert_eq(SaveGame.instance().essences.amount(Essences.BLUE), 1)


func _drop_on_lucian(item: ItemData) -> LootDrop:
	var drop := LootDrop.new()
	drop.item = item
	drop.lucian = stage.lucian
	drop.position = stage.lucian.global_position
	stage.get_node("World").add_child(drop)
	return drop


func test_walking_over_a_drop_picks_it_up() -> void:
	_stage()
	var sword := stage.lucian.item_catalog.find(&"bf_sword")
	var room := stage.lucian.inventory.space_for(sword)
	var drop := _drop_on_lucian(sword)
	await wait_physics_frames(2)
	assert_eq(stage.lucian.inventory.space_for(sword), room - 1)
	assert_false(is_instance_valid(drop))


func test_a_full_backpack_leaves_the_drop() -> void:
	_stage()
	var sword := stage.lucian.item_catalog.find(&"bf_sword")
	for i in Inventory.BACKPACK_SIZE:
		stage.lucian.inventory.add(sword)
	assert_eq(stage.lucian.inventory.space_for(sword), 0)
	var drop := _drop_on_lucian(sword)
	await wait_physics_frames(2)
	assert_true(is_instance_valid(drop))


func _drops() -> Array[Node]:
	return stage.get_node("World").get_children().filter(func(node: Node) -> bool: return node is LootDrop)


func test_the_kill_that_ends_the_stage_drops_nothing() -> void:
	stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_stage(SaveGame.instance(), 2, 3))
	add_child_autofree(stage)
	await wait_physics_frames(2)
	stage.jump_to_boss_wave()
	stage.runner.tick(0.1)
	stage.runner.tick(0.1)
	stage.boss_unit.take_damage(DamageInfo.create(99999.0, DamageInfo.Type.TRUE, &"test"))
	assert_true(stage.result.visible)
	assert_eq(_drops().size(), 0, "the result is up: nothing could pick it up")


func test_a_boss_that_doesnt_end_the_stage_still_drops() -> void:
	_stage()
	var boss := stage.spawn_enemy(&"akshan", Vector2(1700, 600))
	boss.take_damage(DamageInfo.create(99999.0, DamageInfo.Type.TRUE, &"test"))
	assert_gt(_drops().size(), 0)


func test_a_mini_boss_always_drops_a_fragment_and_sometimes_a_legendary() -> void:
	var catalog: ItemCatalog = load("res://data/items/catalog.tres")
	var without_fragment := 0
	var legendaries := 0
	for i in 5000:
		var has_fragment := false
		for item in LootTable.roll(&"mini_boss", catalog, rng):
			if item.kind == ItemData.Kind.LEGENDARY:
				legendaries += 1
			else:
				has_fragment = true
		if not has_fragment:
			without_fragment += 1
	assert_eq(without_fragment, 0)
	# 8% of 5000 is 400.
	assert_between(legendaries, 320, 480)

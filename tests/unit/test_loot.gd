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


## The "Backpack full" notes in the world.
func _full_notes() -> Array[Node]:
	return stage.get_node("World").get_children().filter(func(node: Node) -> bool:
		return node is FloatingText and node.text == "Backpack full")


func test_a_full_backpack_leaves_the_drop_and_says_so_now_and_then() -> void:
	_stage()
	var sword := stage.lucian.item_catalog.find(&"bf_sword")
	for i in Inventory.BACKPACK_SIZE:
		stage.lucian.inventory.add(sword)
	assert_eq(stage.lucian.inventory.space_for(sword), 0)
	var drop := _drop_on_lucian(sword)
	await wait_physics_frames(2)
	assert_true(is_instance_valid(drop))
	assert_null(stage.lucian.inventory.item_at(Inventory.EQUIP_START), "the empty equip slots take nothing")
	assert_eq(_full_notes().size(), 1)
	await wait_physics_frames(10)
	assert_eq(_full_notes().size(), 1, "at most one note every %d s" % LootDrop.FULL_NOTE_GAP)


func test_a_full_equip_row_doesnt_stop_a_pickup() -> void:
	_stage()
	var sword := stage.lucian.item_catalog.find(&"bf_sword")
	for i in Inventory.EQUIP_SIZE:
		stage.lucian.inventory.put(Inventory.EQUIP_START + i, sword)
	var drop := _drop_on_lucian(sword)
	await wait_physics_frames(2)
	assert_false(is_instance_valid(drop))
	assert_eq(stage.lucian.inventory.item_at(0), sword)


func _drops() -> Array[Node]:
	return stage.get_node("World").get_children().filter(func(node: Node) -> bool: return node is LootDrop)


## Story stage `act`-`number`, with Lucian out of harm's way.
func _story_stage(act: int, number: int) -> Stage:
	stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_stage(SaveGame.instance(), act, number))
	add_child_autofree(stage)
	await wait_process_frames(2)
	stage.lucian.invulnerable = true
	return stage


## A perched Chain Warden dies on a ledge over the abyss: its loot falls back
## onto the plateau, toward the merchant, where Lucian can reach it.
func test_loot_from_an_act_6_ledge_lands_where_lucian_can_reach_it() -> void:
	await _story_stage(6, 3)
	var map := stage.arena
	var sword := stage.lucian.item_catalog.find(&"bf_sword")
	assert_eq(map.ledge_points.size(), 4)
	for ledge in map.ledge_points:
		assert_false(map.is_walkable(ledge, 0.0), "the ledge is over the abyss")
		stage.drop_loot(sword, ledge)
	var drops := _drops()
	assert_eq(drops.size(), map.ledge_points.size())
	for drop: LootDrop in drops:
		var at := drop.global_position
		assert_true(map.is_walkable(at, LootDrop.GROUND_MARGIN), "on the ground: %s" % at)
		var stand := at.move_toward(map.merchant_point, LootDrop.PICKUP_RANGE - 5.0)
		assert_true(map.is_walkable(stand, Lucian.HIT_RADIUS + 6.0), "Lucian can stand in pickup range of %s" % at)


func test_loot_on_open_ground_stays_where_it_fell() -> void:
	_stage()
	var at := Vector2(1700, 600)
	assert_true(stage.arena.is_walkable(at, 80.0))
	stage.drop_loot(stage.lucian.item_catalog.find(&"bf_sword"), at)
	var drop: LootDrop = _drops()[0]
	assert_lt(drop.global_position.distance_to(at), 30.0 * sqrt(2.0) + 0.01, "only the scatter")


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


func test_a_drop_stays_when_the_open_cells_are_full() -> void:
	_stage()
	var sword := stage.lucian.item_catalog.find(&"bf_sword")
	stage.lucian.inventory.unlocked_backpack = 3
	for i in 3:
		stage.lucian.inventory.add(sword)
	assert_eq(stage.lucian.inventory.space_for(sword), 0)
	var drop := _drop_on_lucian(sword)
	await wait_physics_frames(2)
	assert_true(is_instance_valid(drop))
	assert_null(stage.lucian.inventory.item_at(3))
	assert_null(stage.lucian.inventory.item_at(Inventory.EQUIP_START))

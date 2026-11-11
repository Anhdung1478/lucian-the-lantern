extends GutTest
## The soft shadow under every unit: it is there, sized to the unit, drawn
## under the units, and it shrinks while the unit is in the air.

var lucian: Lucian


func before_each() -> void:
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	lucian.position = Vector2(2000, 0)
	add_child_autofree(lucian)


func _unit(radius: float, at := Vector2.ZERO) -> EnemyUnit:
	var data := EnemyData.new()
	data.id = &"test_unit"
	data.max_hp = 500.0
	data.radius = radius
	var unit := EnemyUnit.new()
	unit.setup(data, 1, 1, lucian)
	unit.position = at
	add_child_autofree(unit)
	return unit


## The one UnitShadow among `unit`'s children, or null.
func _shadow_of(unit: Node) -> UnitShadow:
	var found: Array[Node] = unit.get_children().filter(func(node: Node) -> bool: return node is UnitShadow)
	assert_eq(found.size(), 1, "one shadow under %s" % unit.name)
	return found[0] if found.size() == 1 else null


func test_an_enemys_shadow_follows_its_radius() -> void:
	var small := _unit(20.0)
	var big := _unit(64.0, Vector2(400, 0))
	assert_eq(_shadow_of(small), small.shadow)
	assert_eq(small.shadow.radius, 20.0)
	assert_eq(big.shadow.radius, 64.0)


func test_a_shadow_is_drawn_under_the_units_and_over_the_floor() -> void:
	var unit := _unit(28.0)
	assert_lt(unit.shadow.z_index, 0, "under every unit and every warning")
	assert_gt(unit.z_index + unit.shadow.z_index, StageMap.FLOOR_Z, "over the floor")
	assert_lt(unit.shadow.get_index(), unit.visuals.get_index(), "under its own art too")
	assert_eq(unit.shadow.get_parent(), unit, "on the body: it never turns with the art")


func test_lucian_the_dummy_senna_the_merchant_and_loot_have_one() -> void:
	assert_eq(_shadow_of(lucian).radius, Lucian.HIT_RADIUS)
	assert_eq(lucian.shadow, _shadow_of(lucian))
	var dummy: TrainingDummy = load("res://src/enemies/training_dummy.tscn").instantiate()
	add_child_autofree(dummy)
	assert_eq(_shadow_of(dummy).radius, dummy.radius)
	var senna := Senna.new()
	senna.lucian = lucian
	add_child_autofree(senna)
	assert_eq(_shadow_of(senna).radius, Senna.SHADOW_RADIUS)
	var merchant := Merchant.new()
	add_child_autofree(merchant)
	assert_eq(_shadow_of(merchant).radius, Merchant.BODY_RADIUS)
	var drop := LootDrop.new()
	drop.item = (load("res://data/items/catalog.tres") as ItemCatalog).items[0]
	add_child_autofree(drop)
	assert_eq(_shadow_of(drop).radius, LootDrop.SHADOW_RADIUS)


func test_a_leaping_enemys_shadow_shrinks_and_comes_back() -> void:
	var unit := _unit(28.0)
	await wait_physics_frames(1)
	unit.leap_to(Vector2(300, 0), 0.5)
	await wait_physics_frames(15)
	assert_gt(unit.shadow.lift, 0.8, "high in the arc")
	assert_lt(unit.shadow.scale.x, 0.75, "smaller")
	assert_lt(unit.shadow.self_modulate.a, 0.7, "fainter")
	await wait_physics_frames(20)
	assert_eq(unit.shadow.lift, 0.0, "down again")
	assert_eq(unit.shadow.scale, Vector2.ONE)
	assert_eq(unit.shadow.self_modulate.a, 1.0)
	assert_eq(unit.shadow.position, Vector2.ZERO)


func test_lucians_shadow_shrinks_while_he_is_thrown() -> void:
	await wait_physics_frames(1)
	lucian.launch(lucian.global_position + Vector2(400, 0), 0.5)
	await wait_physics_frames(15)
	assert_gt(lucian.shadow.lift, 0.8)
	await wait_physics_frames(20)
	assert_false(lucian.is_launched())
	assert_eq(lucian.shadow.lift, 0.0)


func test_a_throw_cut_short_puts_the_shadow_back() -> void:
	await wait_physics_frames(1)
	lucian.launch(lucian.global_position + Vector2(400, 0), 0.5)
	await wait_physics_frames(10)
	lucian.add_cc(CrowdControl.Kind.STUN, 0.5)
	lucian.enter_stasis(1.0, 100.0, 100.0)
	assert_false(lucian.is_launched())
	assert_eq(lucian.shadow.lift, 0.0)


func test_the_lift_changes_the_shadow_without_a_radius_change() -> void:
	var shadow := UnitShadow.new()
	shadow.radius = 50.0
	add_child_autofree(shadow)
	shadow.lift = 2.0
	assert_eq(shadow.lift, 1.0, "never past the top")
	assert_eq(shadow.scale, Vector2.ONE * UnitShadow.LIFT_SIZE)
	assert_almost_eq(shadow.self_modulate.a, UnitShadow.LIFT_ALPHA, 0.001)
	assert_eq(shadow.position, UnitShadow.LIFT_SHIFT * 50.0, "further from the unit, away from the light")
	assert_eq(shadow.radius, 50.0)

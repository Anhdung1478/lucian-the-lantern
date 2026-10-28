extends GutTest

var lucian: Lucian


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real save.
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new("user://test_akshan_save_slot_")
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	add_child_autofree(lucian)


func _akshan(at: Vector2) -> Akshan:
	var akshan := Akshan.new()
	akshan.setup(load("res://data/enemies/akshan.tres"), 2, 1, lucian)
	akshan.position = at
	add_child_autofree(akshan)
	return akshan


func _wall(at: Vector2) -> void:
	var wall := StaticBody2D.new()
	wall.collision_layer = Layers.WORLD
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 70.0
	shape.shape = circle
	wall.position = at
	wall.add_child(shape)
	add_child_autofree(wall)


func test_the_boomerang_hits_once_out_and_once_back() -> void:
	lucian.global_position = Vector2(450, 0)
	var thrower := Node2D.new()
	add_child_autofree(thrower)
	var boomerang := EnemyProjectile.new()
	boomerang.launch(Vector2.ZERO, Vector2.RIGHT, DamageInfo.create(10.0, DamageInfo.Type.TRUE, &"avengerang"), lucian)
	boomerang.speed = Akshan.BOOMERANG_SPEED
	boomerang.max_range = Akshan.BOOMERANG_LENGTH
	boomerang.hit_radius = 22.0
	boomerang.return_to = thrower
	add_child(boomerang)
	watch_signals(lucian)
	await wait_seconds(2.2)
	assert_signal_emit_count(lucian, "damage_received", 2)


func test_swing_bolts_fly_outward() -> void:
	var akshan := _akshan(Vector2(3000, 0))
	await wait_physics_frames(1)
	akshan.start_swing(Vector2(3000, 300))
	await wait_seconds(0.7)
	var bolts := get_children().filter(func(child: Node) -> bool: return child is EnemyProjectile)
	assert_gt(bolts.size(), 0)
	for bolt: EnemyProjectile in bolts:
		var outward := (bolt.global_position - Vector2(3000, 300)).normalized()
		assert_gt(bolt.direction.dot(outward), 0.9)


func test_a_pillar_stops_comeuppance() -> void:
	var akshan := _akshan(Vector2.ZERO)
	akshan.move_speed = 0.0
	lucian.global_position = Vector2(600, 0)
	_wall(Vector2(300, 0))
	await wait_physics_frames(2)
	var before := lucian.hp
	akshan.start_burst()
	await wait_seconds(1.2)
	assert_gte(lucian.hp, before)


func test_comeuppance_hits_in_the_open_and_misses_out_of_range() -> void:
	var akshan := _akshan(Vector2.ZERO)
	akshan.move_speed = 0.0
	lucian.global_position = Vector2(600, 0)
	await wait_physics_frames(1)
	var before := lucian.hp
	akshan.start_burst()
	await wait_seconds(1.0)
	assert_lt(lucian.hp, before)
	lucian.global_position = Vector2(1600, 0)
	before = lucian.hp
	akshan.start_burst()
	await wait_seconds(1.6)
	assert_gte(lucian.hp, before)


func test_comeuppance_waits_for_75_percent() -> void:
	var akshan := _akshan(Vector2(3000, 0))
	assert_false(akshan._can_use(&"comeuppance"))
	akshan.hp = akshan.max_hp * 0.7
	assert_true(akshan._can_use(&"comeuppance"))


func test_purple_is_10_then_2() -> void:
	var data: EnemyData = load("res://data/enemies/akshan.tres")
	var save := SaveGame.instance()
	save.reset()
	assert_eq(save.award_boss("akshan", data.purple_first, data.purple_repeat), 10)
	assert_eq(save.award_boss("akshan", data.purple_first, data.purple_repeat), 2)

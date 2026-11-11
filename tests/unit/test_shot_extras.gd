extends GutTest
## The glow and trail on shots, the spark where a hit lands and the pop of a
## damage number: all extras, off with low effects and headless.


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real settings.
	if GameSettings._instance == null or GameSettings._instance.path == GameSettings.DEFAULT_PATH:
		GameSettings._instance = GameSettings.new("user://test_shot_extras_settings.json")
	Juice.renders = true


func after_each() -> void:
	Juice.renders = false
	GameSettings.instance().set_value(&"quality", "high")


func _glows(node: Node) -> Array[Node]:
	return node.get_children().filter(func(child: Node) -> bool: return child is ShotGlow)


func test_a_plain_shot_gets_a_glow_with_a_trail() -> void:
	var shot := EnemyProjectile.new()
	add_child_autofree(shot)
	var glows := _glows(shot)
	assert_eq(glows.size(), 1)
	assert_eq(glows[0].material.blend_mode, CanvasItemMaterial.BLEND_MODE_ADD)
	glows[0]._process(0.016)
	glows[0]._process(0.016)
	assert_eq(glows[0]._count, 2)


func test_a_shot_with_a_skin_look_keeps_only_its_look() -> void:
	var shot := AttackProjectile.new()
	shot.set_look(PlainShotLook.new(ShotLook.Kind.BOLT))
	add_child_autofree(shot)
	assert_eq(_glows(shot).size(), 0)


func test_a_wave_front_has_no_glow() -> void:
	var shot := EnemyProjectile.new()
	shot.front_width = 200.0
	add_child_autofree(shot)
	assert_eq(_glows(shot).size(), 0)


func test_no_glow_with_low_effects_or_headless() -> void:
	GameSettings.instance().set_value(&"quality", "low")
	var low := LinearProjectile.new()
	add_child_autofree(low)
	assert_eq(_glows(low).size(), 0)
	GameSettings.instance().set_value(&"quality", "high")
	Juice.renders = false
	var headless := HomingMissile.new()
	add_child_autofree(headless)
	assert_eq(_glows(headless).size(), 0)


func test_a_hit_spark_lives_briefly_and_goes() -> void:
	var holder := Node2D.new()
	add_child_autofree(holder)
	HitSpark.spawn(holder, Vector2(10, 20), Color.WHITE, true)
	var spark: HitSpark = holder.get_child(0)
	assert_eq(spark.position, Vector2(10, 20))
	assert_gt(spark.scale.x, 1.0, "a crit's is bigger")
	spark._process(HitSpark.LIFETIME + 0.01)
	assert_true(spark.is_queued_for_deletion())
	GameSettings.instance().set_value(&"quality", "low")
	HitSpark.spawn(holder, Vector2.ZERO, Color.WHITE, false)
	assert_eq(holder.get_child_count(), 1)


func test_a_number_starts_small_and_settles_to_its_size() -> void:
	var number := FloatingNumber.new()
	number.setup(50.0, DamageInfo.Type.PHYSICAL, true)
	add_child_autofree(number)
	assert_almost_eq(number.scale.x, FloatingNumber.POP_FROM, 0.001)
	await get_tree().create_timer(FloatingNumber.POP_UP + FloatingNumber.POP_SETTLE + 0.15).timeout
	assert_almost_eq(number.scale.x, 1.0, 0.05)
	assert_gt(FloatingNumber.CRIT_POP_PEAK, FloatingNumber.POP_PEAK)

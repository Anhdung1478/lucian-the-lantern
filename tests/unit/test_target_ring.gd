extends GutTest
## The target ring: it sits under the enemy Lucian is ordered to attack,
## follows it, goes with the order, and is an extra.

var lucian: Lucian


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real settings.
	if GameSettings._instance == null or GameSettings._instance.path == GameSettings.DEFAULT_PATH:
		GameSettings._instance = GameSettings.new("user://test_target_ring_settings.json")
	Juice.renders = true
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	lucian.position = Vector2(2000, 0)
	add_child_autofree(lucian)


func after_each() -> void:
	Juice.renders = false
	GameSettings.instance().set_value(&"quality", "high")


func _enemy(at: Vector2) -> EnemyUnit:
	var data := EnemyData.new()
	data.id = &"test_unit"
	data.max_hp = 500.0
	data.radius = 30.0
	var unit := EnemyUnit.new()
	unit.setup(data, 1, 1, lucian)
	unit.position = at
	add_child_autofree(unit)
	return unit


func _ring() -> TargetRing:
	for child in lucian.get_children():
		if child is TargetRing:
			return child
	return null


func test_the_ring_follows_the_attack_order() -> void:
	var enemy := _enemy(Vector2(2300, 0))
	lucian.command_attack(enemy)
	_ring()._process(0.05)
	assert_eq(_ring().target(), enemy)
	enemy.global_position = Vector2(2300, 90)
	_ring()._process(0.05)
	assert_eq(_ring().global_position, Vector2(2300, 90))
	assert_gt(_ring().modulate.a, 0.0)


func test_the_ring_goes_when_the_order_goes() -> void:
	lucian.command_attack(_enemy(Vector2(2300, 0)))
	_ring()._process(0.5)
	assert_eq(_ring().modulate.a, 1.0)
	lucian.command_move(Vector2(2000, 200))
	_ring()._process(TargetRing.FADE_OUT + 0.1)
	assert_eq(_ring().modulate.a, 0.0)
	assert_null(_ring().target())


func test_no_ring_with_low_effects() -> void:
	GameSettings.instance().set_value(&"quality", "low")
	lucian.command_attack(_enemy(Vector2(2300, 0)))
	_ring()._process(0.5)
	assert_null(_ring().target())
	assert_eq(_ring().modulate.a, 0.0)

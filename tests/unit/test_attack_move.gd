extends GutTest
## A + Left-click: the enemy under the cursor, else the weakest one in range,
## else the nearest on the map. After the kill he stops.

var lucian: Lucian


func before_each() -> void:
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	var effects := Node2D.new()
	add_child_autofree(effects)
	lucian.projectile_parent = effects
	add_child_autofree(lucian)
	lucian.global_position = Vector2.ZERO


## A dummy `distance` px to the right of Lucian, at `hp_fraction` of its HP.
func _enemy(distance: float, hp_fraction := 1.0, y := 0.0) -> Enemy:
	var enemy := Enemy.new()
	enemy.radius = 20.0
	add_child_autofree(enemy)
	enemy.global_position = Vector2(distance, y)
	enemy.hp = enemy.max_hp * hp_fraction
	return enemy


func _in_range_distance() -> float:
	return lucian.attack_range() * 0.5


func test_the_enemy_under_the_cursor_wins_even_out_of_range() -> void:
	var hovered := _enemy(lucian.attack_range() + 600.0)
	var weak_near := _enemy(_in_range_distance(), 0.1)
	assert_eq(lucian.attack_move_target(hovered.global_position), hovered)
	lucian.command_attack_move(hovered.global_position)
	assert_eq(lucian._order, Lucian.Order.ATTACK)
	assert_eq(lucian._target, hovered)
	var start := lucian.global_position.x
	await wait_seconds(0.3)
	assert_gt(lucian.global_position.x, start, "walks toward it")
	assert_not_null(weak_near)


func test_no_hover_picks_the_lowest_hp_percent_in_range() -> void:
	var near_healthy := _enemy(_in_range_distance() * 0.5, 1.0)
	var far_weak := _enemy(_in_range_distance(), 0.3, 40.0)
	var point := Vector2(0, 2000)
	assert_eq(lucian.attack_move_target(point), far_weak)
	assert_not_null(near_healthy)


func test_a_tie_in_hp_percent_goes_to_the_nearer_one() -> void:
	var far := _enemy(_in_range_distance(), 0.5, 40.0)
	var near := _enemy(_in_range_distance() * 0.5, 0.5)
	assert_eq(lucian.attack_move_target(Vector2(0, 2000)), near)
	assert_not_null(far)


func test_with_none_in_range_the_nearest_on_the_map_is_chased_and_shot() -> void:
	var far := _enemy(lucian.attack_range() + 1500.0)
	var nearer := _enemy(lucian.attack_range() + 500.0, 1.0, 100.0)
	assert_eq(lucian.attack_move_target(Vector2(0, 5000)), nearer)
	lucian.command_attack_move(Vector2(0, 5000))
	assert_eq(lucian._target, nearer)
	await wait_seconds(2.5)
	assert_lt(nearer.hp, nearer.max_hp, "walked into range and shot")
	assert_eq(far.hp, far.max_hp)


func test_after_the_target_dies_he_stops() -> void:
	var first := _enemy(_in_range_distance())
	var second := _enemy(_in_range_distance() * 0.8, 1.0, 60.0)
	lucian.command_attack_move(first.global_position)
	assert_eq(lucian._target, first)
	first.hp = 0.0
	first._die()
	await wait_physics_frames(3)
	assert_eq(lucian._order, Lucian.Order.NONE)
	assert_not_null(second)


func test_with_no_enemy_he_walks_to_the_point() -> void:
	assert_null(lucian.attack_move_target(Vector2(500, 0)))
	lucian.command_attack_move(Vector2(500, 0))
	assert_eq(lucian._order, Lucian.Order.MOVE)
	assert_eq(lucian._move_point, Vector2(500, 0))


func test_a_dead_enemy_is_never_picked() -> void:
	var dead := _enemy(_in_range_distance(), 0.0)
	dead.dead = true
	var alive := _enemy(_in_range_distance() * 2.0, 1.0, 60.0)
	assert_eq(lucian.attack_move_target(dead.global_position), alive, "not hovered")
	assert_eq(lucian.attack_move_target(Vector2(0, 2000)), alive, "not weakest or nearest")
	alive.dead = true
	assert_null(lucian.attack_move_target(dead.global_position))

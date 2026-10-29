extends GutTest
## Spectral walls (Karthus's Wall of Pain, Thresh's The Box): no body, but
## Lucian's path since the last frame is checked against every piece, so a
## dash or a Flash across one is caught. Each piece touches once.

var lucian: Lucian


func before_each() -> void:
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	lucian.position = Vector2(-300, 0)
	add_child_autofree(lucian)


## `wall` on Lucian, added to the tree: the pieces it reports touched.
func _raise(wall: SpectralWall) -> Array[int]:
	var touched: Array[int] = []
	wall.target = lucian
	wall.touched.connect(func(piece: int) -> void: touched.append(piece))
	add_child_autofree(wall)
	return touched


## A wall 400 long standing across the x axis at x = 0.
func _across() -> SpectralWall:
	return SpectralWall.line(Vector2.ZERO, Vector2.DOWN, 400.0, 3.0)


func test_a_line_is_one_piece_through_its_center() -> void:
	var wall := SpectralWall.line(Vector2(500, 300), Vector2(0, 2), 400.0, 3.0)
	add_child_autofree(wall)
	assert_eq(wall.piece_count(), 1)
	var ends := wall.piece_ends(0)
	assert_almost_eq(ends[0], Vector2(500, 100), Vector2(0.01, 0.01))
	assert_almost_eq(ends[1], Vector2(500, 500), Vector2(0.01, 0.01))


func test_a_ring_is_chords_of_its_circle() -> void:
	var center := Vector2(800, 600)
	var wall := SpectralWall.ring(center, 450.0, 12, 4.0)
	add_child_autofree(wall)
	assert_eq(wall.piece_count(), 12)
	for i in 12:
		var ends := wall.piece_ends(i)
		assert_almost_eq(ends[0].distance_to(center), 450.0, 0.01, "on the circle")
		assert_almost_eq(ends[1].distance_to(center), 450.0, 0.01, "on the circle")
		assert_almost_eq(ends[1], wall.piece_ends((i + 1) % 12)[0], Vector2(0.01, 0.01), "a closed ring")


func test_it_is_no_body_and_blocks_nothing() -> void:
	var wall := _across()
	var touched := _raise(wall)
	var node: Node = wall
	assert_false(node is CollisionObject2D)
	assert_true(wall.find_children("*", "CollisionObject2D", true, false).is_empty())
	await wait_physics_frames(2)
	assert_eq(touched, [] as Array[int], "not touched from afar")
	lucian.command_move(Vector2(300, 0))
	await wait_seconds(2.0)
	assert_almost_eq(lucian.global_position, Vector2(300, 0), Vector2(2, 2), "he walked through it")
	assert_eq(touched, [0] as Array[int], "and touched it once")


func test_a_dash_across_a_piece_is_caught() -> void:
	var touched := _raise(_across())
	await wait_physics_frames(2)
	# 200 px a frame: from -300 he is at -100, then +100, never on it.
	lucian.start_dash(Vector2.RIGHT, 400.0, 12000.0)
	await wait_physics_frames(4)
	assert_gt(lucian.global_position.x, 50.0, "past it")
	assert_eq(touched, [0] as Array[int])


func test_a_flash_across_a_piece_is_caught() -> void:
	var touched := _raise(_across())
	await wait_physics_frames(2)
	lucian.global_position = Vector2(-200, 0)
	await wait_physics_frames(2)
	assert_true(lucian.use_summoner(0, Vector2(200, 0)), "Flash")
	assert_almost_eq(lucian.global_position, Vector2(200, 0), Vector2(0.5, 0.5))
	await wait_physics_frames(2)
	assert_eq(touched, [0] as Array[int])


func test_passing_beside_a_piece_is_no_touch() -> void:
	var touched := _raise(_across())
	await wait_physics_frames(2)
	lucian.global_position = Vector2(-200, 260)
	await wait_physics_frames(1)
	lucian.global_position = Vector2(200, 260)
	await wait_physics_frames(2)
	assert_eq(touched, [] as Array[int], "past its end, more than his hit radius away")


func test_each_piece_touches_once() -> void:
	lucian.global_position = Vector2.ZERO
	var wall := SpectralWall.ring(Vector2.ZERO, 450.0, 12, 4.0)
	var touched := _raise(wall)
	await wait_physics_frames(2)
	assert_eq(touched, [] as Array[int], "inside the ring, clear of it")
	# Across piece 0 (between 0 and 30 degrees) and back, three times.
	var inside := Vector2.from_angle(PI / 12.0) * 300.0
	var outside := Vector2.from_angle(PI / 12.0) * 600.0
	for i in 3:
		lucian.global_position = outside
		await wait_physics_frames(1)
		lucian.global_position = inside
		await wait_physics_frames(1)
	assert_eq(touched, [0] as Array[int], "once")
	# Standing on piece 6 for a while.
	lucian.global_position = Vector2.from_angle(PI + PI / 12.0) * 440.0
	await wait_physics_frames(10)
	assert_eq(touched, [0, 6] as Array[int])


func test_standing_on_it_when_it_rises_is_a_touch() -> void:
	lucian.global_position = Vector2(10, 50)
	var touched := _raise(_across())
	await wait_physics_frames(2)
	assert_eq(touched, [0] as Array[int])


func test_break_on_touch_takes_the_piece_away() -> void:
	lucian.global_position = Vector2.ZERO
	var wall := SpectralWall.ring(Vector2.ZERO, 450.0, 12, 4.0)
	wall.break_on_touch = true
	var touched := _raise(wall)
	await wait_physics_frames(2)
	lucian.global_position = Vector2.from_angle(PI / 12.0) * 600.0
	await wait_physics_frames(2)
	assert_eq(touched, [0] as Array[int])
	assert_true(wall.is_broken(0))
	for i in range(1, 12):
		assert_false(wall.is_broken(i), "piece %d stands" % i)


func test_a_touched_piece_stands_without_break_on_touch() -> void:
	var wall := _across()
	var touched := _raise(wall)
	await wait_physics_frames(1)
	lucian.global_position = Vector2(300, 0)
	await wait_physics_frames(2)
	assert_eq(touched, [0] as Array[int])
	assert_false(wall.is_broken(0))


func test_it_fades_out_at_the_end_then_goes() -> void:
	var wall := SpectralWall.line(Vector2(0, 500), Vector2.RIGHT, 400.0, 0.6)
	_raise(wall)
	await wait_physics_frames(6)
	assert_eq(wall.modulate.a, 1.0, "solid at first")
	await wait_seconds(0.6 - SpectralWall.FADE_TIME * 0.5 - 0.1)
	assert_between(wall.modulate.a, 0.05, 0.95, "fading over its last moments")
	await wait_seconds(0.4)
	assert_false(is_instance_valid(wall))

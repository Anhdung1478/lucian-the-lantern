extends GutTest


func test_center_jumps_to_lucian_and_stays_free() -> void:
	var target := Node2D.new()
	target.position = Vector2(2400, 1350)
	add_child_autofree(target)
	var camera := StageCamera.new()
	add_child_autofree(camera)
	camera.setup(target, Rect2(0, 0, 4800, 2700))
	camera.global_position = Vector2(1000, 1000)
	camera.center_on_target()
	assert_eq(camera.global_position, Vector2(2400, 1350))
	assert_eq(camera.mode, StageCamera.Mode.FREE)


func test_holding_center_keeps_the_camera_on_lucian() -> void:
	var target := Node2D.new()
	target.position = Vector2(2400, 1350)
	add_child_autofree(target)
	var camera := StageCamera.new()
	# No edge panning from wherever the mouse is.
	camera.edge_margin = -1.0
	add_child_autofree(camera)
	camera.setup(target, Rect2(0, 0, 4800, 2700))
	Input.action_press(&"center_camera")
	target.position = Vector2(2000, 1200)
	await wait_physics_frames(2)
	assert_eq(camera.global_position, Vector2(2000, 1200), "follows while held")
	Input.action_release(&"center_camera")
	target.position = Vector2(2600, 1500)
	await wait_physics_frames(2)
	assert_eq(camera.global_position, Vector2(2000, 1200), "free again once let go")
	assert_eq(camera.mode, StageCamera.Mode.FREE)

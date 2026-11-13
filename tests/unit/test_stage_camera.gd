extends GutTest

const SETTINGS_PATH := "user://test_camera_settings.json"
## A map with room for the widest view on any test screen.
const BOUNDS := Rect2(0, 0, 9600, 9600)

## The camera's own settings, so a zoom saved here never reaches another test.
var settings: GameSettings


func before_each() -> void:
	_delete()
	settings = GameSettings.new(SETTINGS_PATH)


func after_each() -> void:
	Pointer.pretend = null
	_delete()


func _delete() -> void:
	for file in [SETTINGS_PATH, SETTINGS_PATH + ".tmp"]:
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(file))


## A camera over a target in the middle of `bounds`, with no edge panning
## from wherever the mouse is.
func _camera(bounds := BOUNDS) -> StageCamera:
	var target := Node2D.new()
	target.position = bounds.get_center()
	add_child_autofree(target)
	var camera := StageCamera.new()
	camera.settings = settings
	camera.edge_margin = -1.0
	add_child_autofree(camera)
	camera.setup(target, bounds)
	return camera


func _wheel(button: MouseButton) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	return event


func test_center_jumps_to_lucian_and_stays_free() -> void:
	var target := Node2D.new()
	target.position = Vector2(2400, 1350)
	add_child_autofree(target)
	var camera := StageCamera.new()
	camera.settings = settings
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
	camera.settings = settings
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


func test_the_view_starts_at_one_and_the_wheel_steps_it() -> void:
	var camera := _camera()
	assert_eq(camera.zoom_level, 1.0)
	assert_eq(camera.zoom, Vector2.ONE)
	camera._unhandled_input(_wheel(MOUSE_BUTTON_WHEEL_UP))
	assert_almost_eq(camera.zoom_level, 1.1, 0.0001, "wheel up: closer")
	camera._unhandled_input(_wheel(MOUSE_BUTTON_WHEEL_DOWN))
	camera._unhandled_input(_wheel(MOUSE_BUTTON_WHEEL_DOWN))
	assert_almost_eq(camera.zoom_level, 0.9, 0.0001, "wheel down: wider")


func test_a_wheel_release_and_another_button_leave_the_view() -> void:
	var camera := _camera()
	var release := _wheel(MOUSE_BUTTON_WHEEL_UP)
	release.pressed = false
	camera._unhandled_input(release)
	camera._unhandled_input(_wheel(MOUSE_BUTTON_MIDDLE))
	assert_eq(camera.zoom_level, 1.0)


func test_a_camera_not_set_up_ignores_the_wheel() -> void:
	var camera := StageCamera.new()
	add_child_autofree(camera)
	camera._unhandled_input(_wheel(MOUSE_BUTTON_WHEEL_UP))
	assert_eq(camera.zoom_level, 1.0)
	assert_eq(camera.zoom, Vector2.ONE)


func test_the_view_stops_at_its_closest_and_its_widest() -> void:
	var camera := _camera()
	for i in 12:
		camera.zoom_by(1)
	assert_almost_eq(camera.zoom_level, StageCamera.ZOOM_MAX, 0.0001)
	for i in 12:
		camera.zoom_by(-1)
	assert_almost_eq(camera.zoom_level, StageCamera.ZOOM_MIN, 0.0001)
	assert_eq(StageCamera.ZOOM_MIN, 0.7)
	assert_eq(StageCamera.ZOOM_MAX, 1.4)


func test_the_view_eases_to_the_level_asked_for() -> void:
	var camera := _camera()
	camera.zoom_by(-3)
	assert_eq(camera.zoom, Vector2.ONE, "not at once")
	await wait_physics_frames(2)
	assert_lt(camera.zoom.x, 1.0)
	assert_gt(camera.zoom.x, 0.7)
	await wait_physics_frames(60)
	assert_eq(camera.zoom, Vector2.ONE * 0.7)


func test_a_view_set_by_hand_stays() -> void:
	# The screenshot tool and the cutscenes set `zoom` themselves.
	var camera := _camera()
	camera.zoom = Vector2.ONE * 0.5
	await wait_physics_frames(5)
	assert_eq(camera.zoom, Vector2.ONE * 0.5)


func test_the_view_never_shows_past_a_small_map() -> void:
	var view := get_viewport().get_visible_rect().size
	# A map as big as the screen at 1.0: no wider view fits.
	var camera := _camera(Rect2(Vector2.ZERO, view))
	assert_almost_eq(camera.min_zoom(), 1.0, 0.0001)
	camera.zoom_by(-2)
	assert_almost_eq(camera.zoom_level, 1.0, 0.0001)
	var roomy := _camera(Rect2(Vector2.ZERO, view * 4.0))
	assert_almost_eq(roomy.min_zoom(), StageCamera.ZOOM_MIN, 0.0001)


func test_a_wider_view_stays_inside_the_map() -> void:
	var camera := _camera()
	var view := camera.get_viewport_rect().size
	camera.global_position = camera._clamped(Vector2.ZERO)
	assert_almost_eq(camera.global_position, view * 0.5, Vector2.ONE * 0.01, "in the corner at 1.0")
	camera.zoom_by(-3)
	await wait_physics_frames(60)
	assert_almost_eq(camera.global_position, view * 0.5 / 0.7, Vector2.ONE * 0.01, "pushed in as the view grows")


func test_the_level_is_saved_once_the_wheel_rests_and_the_next_stage_starts_at_it() -> void:
	var camera := _camera()
	camera.zoom_by(2)
	assert_almost_eq(float(settings.get_value(StageCamera.SETTING)), 1.2, 0.0001, "set at once")
	assert_false(FileAccess.file_exists(SETTINGS_PATH), "not saved on the notch")
	await wait_seconds(StageCamera.SAVE_DELAY + 0.2)
	assert_true(FileAccess.file_exists(SETTINGS_PATH), "saved once the wheel rests")
	var later := GameSettings.new(SETTINGS_PATH)
	assert_almost_eq(float(later.get_value(StageCamera.SETTING)), 1.2, 0.0001)
	settings = later
	var next := _camera()
	assert_almost_eq(next.zoom_level, 1.2, 0.0001)
	assert_almost_eq(next.zoom.x, 1.2, 0.0001, "the stage opens at it, with no ease")


func test_leaving_the_stage_saves_a_level_still_waiting() -> void:
	var camera := _camera()
	camera.zoom_by(-1)
	camera.get_parent().remove_child(camera)
	assert_true(FileAccess.file_exists(SETTINGS_PATH))
	assert_almost_eq(float(GameSettings.new(SETTINGS_PATH).get_value(StageCamera.SETTING)), 0.9, 0.0001)
	camera.free()


func test_a_saved_level_out_of_range_is_brought_in() -> void:
	settings.set_value(StageCamera.SETTING, 5.0, false)
	assert_almost_eq(_camera().zoom_level, StageCamera.ZOOM_MAX, 0.0001)
	settings.set_value(StageCamera.SETTING, 0.1, false)
	assert_almost_eq(_camera().zoom_level, StageCamera.ZOOM_MIN, 0.0001)


func test_edge_panning_crosses_the_screen_as_fast_at_any_view() -> void:
	var camera := _camera()
	camera.edge_margin = 20.0
	# Stepped by hand, so the frames are counted here.
	camera.set_physics_process(false)
	Pointer.pretend = Vector2(0.0, camera.get_viewport().get_visible_rect().size.y * 0.5)
	var from := camera.global_position.x
	camera._physics_process(0.1)
	assert_almost_eq(from - camera.global_position.x, camera.pan_speed * 0.1, 0.01, "pans left, a screen pixel a world unit at 1.0")
	camera.zoom = Vector2.ONE * 0.5
	from = camera.global_position.x
	camera._physics_process(0.1)
	assert_almost_eq(from - camera.global_position.x, camera.pan_speed * 0.2, 0.01, "twice the ground at half the size")


func test_a_scene_plays_at_the_plain_view_and_the_players_returns() -> void:
	var camera := _camera()
	camera.zoom_by(3)
	await wait_physics_frames(60)
	assert_almost_eq(camera.zoom.x, 1.3, 0.0001)
	camera.plain_view(true)
	assert_eq(camera.zoom, Vector2.ONE)
	camera.plain_view(false)
	assert_almost_eq(camera.zoom.x, 1.3, 0.0001)
	assert_almost_eq(camera.zoom_level, 1.3, 0.0001)


## A stage's camera reads the game's settings: the level goes back to plain
## so no later test starts zoomed.
func _stage() -> Stage:
	SaveGame.instance().reset()
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_stage(SaveGame.instance(), 1, 1))
	add_child_autofree(stage)
	stage.camera.edge_margin = -INF
	return stage


func _plain_again() -> void:
	GameSettings.instance().set_value(StageCamera.SETTING, 1.0, false)


func _wheel_at(button: MouseButton, at: Vector2) -> InputEventMouseButton:
	var event := _wheel(button)
	event.position = at
	event.global_position = at
	return event


func test_the_wheel_zooms_in_a_stage_even_over_the_hud() -> void:
	var stage := _stage()
	await wait_process_frames(2)
	var viewport := stage.get_viewport()
	viewport.push_input(_wheel_at(MOUSE_BUTTON_WHEEL_UP, viewport.get_visible_rect().size * 0.5))
	assert_almost_eq(stage.camera.zoom_level, 1.1, 0.0001, "over the battlefield")
	viewport.push_input(_wheel_at(MOUSE_BUTTON_WHEEL_DOWN, stage.hud.bottom_panel.get_global_rect().get_center()))
	assert_almost_eq(stage.camera.zoom_level, 1.0, 0.0001, "over the HUD's bottom panel")
	_plain_again()


func test_the_wheel_leaves_the_view_while_the_backpack_is_open() -> void:
	var stage := _stage()
	await wait_process_frames(2)
	stage.screens.set_backpack_open(true)
	assert_true(get_tree().paused)
	var viewport := stage.get_viewport()
	viewport.push_input(_wheel_at(MOUSE_BUTTON_WHEEL_UP, Vector2(8, 8)))
	assert_eq(stage.camera.zoom_level, 1.0)
	stage.screens.set_backpack_open(false)
	assert_false(get_tree().paused)
	_plain_again()


func test_a_cutscene_freeze_shows_the_plain_view() -> void:
	var stage := _stage()
	await wait_process_frames(2)
	stage.camera.zoom = Vector2.ONE * 0.7
	stage.freeze(true)
	assert_eq(stage.camera.zoom, Vector2.ONE)
	stage.freeze(false)
	assert_eq(stage.camera.zoom, Vector2.ONE * 0.7)
	_plain_again()

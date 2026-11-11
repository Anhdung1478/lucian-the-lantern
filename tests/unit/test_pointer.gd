extends GutTest


func after_each() -> void:
	Pointer.pretend = null


func test_the_real_mouse_is_used_by_default() -> void:
	assert_null(Pointer.pretend, "only tools place a pretend mouse")
	var node := Node2D.new()
	add_child_autofree(node)
	assert_eq(Pointer.on_screen(node), node.get_viewport().get_mouse_position())
	assert_eq(Pointer.in_world(node), node.get_global_mouse_position())


func test_a_pretend_mouse_replaces_the_real_one() -> void:
	var node := Node2D.new()
	add_child_autofree(node)
	Pointer.pretend = Vector2(300, 200)
	assert_eq(Pointer.on_screen(node), Vector2(300, 200))


func test_a_pretend_mouse_is_mapped_into_the_world() -> void:
	# A camera moved off the origin: the world point under the mouse moves with it.
	var node := Node2D.new()
	add_child_autofree(node)
	var viewport := node.get_viewport()
	var before := viewport.canvas_transform
	viewport.canvas_transform = Transform2D(0.0, Vector2(-500, -400))
	Pointer.pretend = Vector2(300, 200)
	assert_eq(Pointer.in_world(node), Vector2(800, 600))
	viewport.canvas_transform = before


func test_the_game_owns_its_window_by_default() -> void:
	assert_true(GameSettings.owns_window, "only the screenshot tool gives it up")

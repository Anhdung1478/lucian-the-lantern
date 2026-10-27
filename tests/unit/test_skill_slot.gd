extends GutTest


func test_full_sweep_covers_whole_square() -> void:
	var points := SkillSlot.sweep_polygon(1.0, 64.0)
	# Center, top middle, four corners, back to top middle.
	assert_eq(points.size(), 7)
	assert_almost_eq(points[1], Vector2(32, 0), Vector2(0.01, 0.01))
	assert_almost_eq(points[2], Vector2(64, 0), Vector2(0.01, 0.01))


func test_quarter_sweep_is_the_top_left_quarter() -> void:
	var points := SkillSlot.sweep_polygon(0.25, 64.0)
	# Starts at 9 o'clock, passes the top-left corner, ends at 12 o'clock.
	assert_eq(points.size(), 4)
	assert_almost_eq(points[1], Vector2(0, 32), Vector2(0.01, 0.01))
	assert_almost_eq(points[2], Vector2(0, 0), Vector2(0.01, 0.01))
	assert_almost_eq(points[3], Vector2(32, 0), Vector2(0.01, 0.01))

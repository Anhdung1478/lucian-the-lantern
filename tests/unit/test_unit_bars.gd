extends GutTest
## The health bars: the ghost chunk of lost health holds, then drains; it is an
## extra, gone with low effects; Lucian's bar ticks every 100 HP and redraws
## only when it changed.


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real settings.
	if GameSettings._instance == null or GameSettings._instance.path == GameSettings.DEFAULT_PATH:
		GameSettings._instance = GameSettings.new("user://test_unit_bars_settings.json")
	Juice.renders = true


func after_each() -> void:
	Juice.renders = false
	GameSettings.instance().set_value(&"quality", "high")


func test_ghost_holds_then_drains_to_the_health() -> void:
	var ghost := BarGhost.new()
	ghost.follow(1.0, 0.6)
	assert_true(ghost.is_showing(0.6))
	ghost.step(BarGhost.HOLD * 0.5, 0.6)
	assert_eq(ghost.share, 1.0, "still held")
	ghost.step(BarGhost.HOLD, 0.6)
	ghost.step(0.2, 0.6)
	assert_almost_eq(ghost.share, 1.0 - 0.2 * BarGhost.DRAIN, 0.001)
	ghost.step(10.0, 0.6)
	assert_eq(ghost.share, 0.6)
	assert_false(ghost.is_showing(0.6))


func test_a_gain_shows_no_ghost() -> void:
	var ghost := BarGhost.new()
	ghost.follow(1.0, 0.3)
	ghost.step(10.0, 0.3)
	ghost.step(10.0, 0.3)
	ghost.follow(0.3, 0.5)
	ghost.step(0.1, 0.5)
	assert_false(ghost.is_showing(0.5))


func test_no_ghost_without_juice() -> void:
	Juice.renders = false
	var ghost := BarGhost.new()
	ghost.follow(1.0, 0.5)
	assert_false(ghost.is_showing(0.5))


func test_enemy_bar_keeps_a_ghost_after_a_hit() -> void:
	var bar := EnemyHealthBar.new()
	add_child_autofree(bar)
	bar.set_health(100.0, 100.0)
	bar.set_health(40.0, 100.0)
	assert_almost_eq(bar.ghost_share(), 1.0, 0.001)
	bar._process(BarGhost.HOLD + 10.0)
	bar._process(10.0)
	assert_almost_eq(bar.ghost_share(), 0.4, 0.001)


func test_no_ghost_on_low_quality() -> void:
	GameSettings.instance().set_value(&"quality", "low")
	var ghost := BarGhost.new()
	ghost.follow(1.0, 0.5)
	assert_false(ghost.is_showing(0.5))


func test_lucian_bar_ticks_every_100_hp() -> void:
	var marks := LucianHealthBar.tick_marks(500.0)
	assert_eq(marks.size(), 4)
	assert_almost_eq(marks[0].x, 0.2, 0.001)
	assert_almost_eq(marks[0].y, LucianHealthBar.TICK_HEIGHT, 0.001)
	var big := LucianHealthBar.tick_marks(2500.0)
	assert_eq(big[0].y, 1.0, "a full tick at 1000")
	assert_eq(big.size(), 2, "small ticks left out when crowded")


func test_lucian_bar_ghost_follows_damage() -> void:
	var lucian: Lucian = load("res://src/lucian/lucian.tscn").instantiate()
	lucian.position = Vector2(2000, 0)
	add_child_autofree(lucian)
	var bar: LucianHealthBar = lucian.get_node("HealthBar")
	bar._process(0.01)
	lucian.hp = lucian.stats.max_hp * 0.5
	bar._process(0.01)
	assert_gt(bar.ghost_share(), 0.9)
	bar._process(BarGhost.HOLD + 10.0)
	bar._process(10.0)
	assert_almost_eq(bar.ghost_share(), 0.5, 0.001)

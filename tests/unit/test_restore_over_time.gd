extends GutTest

const Fixtures := preload("res://tests/unit/item_fixtures.gd")

var restores: RestoreOverTime
var red: ItemData
var blue: ItemData


func before_each() -> void:
	restores = RestoreOverTime.new()
	red = Fixtures.potion(&"red", 200.0, 0.0)
	blue = Fixtures.potion(&"blue", 0.0, 150.0)


func test_nothing_running_restores_nothing() -> void:
	assert_eq(restores.tick(1.0), Vector2.ZERO)
	assert_true(restores.is_empty())


func test_restores_evenly_over_the_time() -> void:
	restores.start(red)
	assert_almost_eq(restores.tick(1.0).x, 40.0, 0.001)
	assert_almost_eq(restores.tick(1.5).x, 60.0, 0.001)


func test_stops_after_the_full_amount() -> void:
	restores.start(red)
	var total := restores.tick(4.0).x + restores.tick(3.0).x
	assert_almost_eq(total, 200.0, 0.001)
	assert_true(restores.is_empty())
	assert_eq(restores.tick(1.0), Vector2.ZERO)


func test_two_potions_run_at_once() -> void:
	restores.start(red)
	restores.start(red)
	assert_almost_eq(restores.tick(1.0).x, 80.0, 0.001)
	assert_eq(restores.count(&"red"), 2)


func test_mana_comes_back_as_y() -> void:
	restores.start(blue)
	var got := restores.tick(1.0)
	assert_almost_eq(got.x, 0.0, 0.001)
	assert_almost_eq(got.y, 30.0, 0.001)


func test_time_left_is_the_longest_running() -> void:
	restores.start(red)
	restores.tick(2.0)
	restores.start(red)
	assert_almost_eq(restores.time_left(&"red"), 5.0, 0.001)
	assert_almost_eq(restores.time_left(&"blue"), 0.0, 0.001)

extends GutTest

var cooldown: Cooldown


func before_each() -> void:
	cooldown = Cooldown.new()


func test_new_cooldown_is_ready() -> void:
	assert_true(cooldown.is_ready())
	assert_eq(cooldown.fraction_remaining(), 0.0)


func test_haste_formula() -> void:
	assert_almost_eq(Cooldown.hasted(10.0, 0.0), 10.0, 0.0001)
	assert_almost_eq(Cooldown.hasted(10.0, 100.0), 5.0, 0.0001)


func test_start_uses_haste() -> void:
	cooldown.start(9.0, 50.0)
	assert_almost_eq(cooldown.remaining, 6.0, 0.0001)
	assert_false(cooldown.is_ready())


func test_reduce_counts_down_and_clamps_at_zero() -> void:
	cooldown.start(4.0)
	cooldown.reduce(1.0)
	assert_almost_eq(cooldown.remaining, 3.0, 0.0001)
	assert_almost_eq(cooldown.fraction_remaining(), 0.75, 0.0001)
	cooldown.reduce(10.0)
	assert_eq(cooldown.remaining, 0.0)
	assert_true(cooldown.is_ready())


func test_zero_length_cooldown_is_ready() -> void:
	cooldown.start(0.0)
	assert_true(cooldown.is_ready())
	assert_eq(cooldown.fraction_remaining(), 0.0)


func test_clear() -> void:
	cooldown.start(5.0)
	cooldown.clear()
	assert_true(cooldown.is_ready())

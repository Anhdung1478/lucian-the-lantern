extends GutTest

var charge: EnergizeCharge


func before_each() -> void:
	charge = EnergizeCharge.new()


func test_starts_empty() -> void:
	assert_eq(charge.value, 0.0)
	assert_false(charge.is_ready())


func test_attacks_build_charge() -> void:
	charge.add_attack()
	assert_almost_eq(charge.value, EnergizeCharge.PER_ATTACK, 0.001)


func test_walking_builds_one_point_per_24_units() -> void:
	charge.add_distance(240.0, false)
	assert_almost_eq(charge.value, 10.0, 0.001)


func test_dashing_builds_twice_as_fast() -> void:
	charge.add_distance(240.0, true)
	assert_almost_eq(charge.value, 20.0, 0.001)


func test_stops_at_100_and_is_ready() -> void:
	for i in 15:
		charge.add_attack()
	assert_eq(charge.value, 100.0)
	assert_true(charge.is_ready())


func test_consume_empties_it() -> void:
	charge.add_distance(5000.0, false)
	charge.consume()
	assert_eq(charge.value, 0.0)


func test_cooldown_reduce_fraction_cuts_the_remaining_time() -> void:
	var cooldown := Cooldown.new()
	cooldown.start(10.0)
	cooldown.reduce(5.0)
	cooldown.reduce_fraction(0.12)
	assert_almost_eq(cooldown.remaining, 4.4, 0.0001)

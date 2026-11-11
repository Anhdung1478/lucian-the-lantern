extends GutTest

var shields: Shields


func before_each() -> void:
	shields = Shields.new()


func test_a_hit_goes_through_the_shields_in_order() -> void:
	shields.add(&"ichorshield", 100.0)
	shields.add(&"barrier", 50.0, 2.0)
	assert_almost_eq(shields.absorb(80.0, DamageInfo.Type.PHYSICAL), 0.0, 0.001)
	assert_false(shields.has(&"barrier"))
	assert_almost_eq(shields.amount(&"ichorshield"), 70.0, 0.001)


func test_what_is_left_gets_through() -> void:
	shields.add(&"barrier", 50.0, 2.0)
	assert_almost_eq(shields.absorb(80.0, DamageInfo.Type.PHYSICAL), 30.0, 0.001)
	assert_eq(shields.total(), 0.0)


func test_a_magic_only_shield_ignores_physical_damage() -> void:
	shields.add(&"magebane", 100.0, 0.0, true)
	assert_almost_eq(shields.absorb(40.0, DamageInfo.Type.PHYSICAL), 40.0, 0.001)
	assert_almost_eq(shields.absorb(40.0, DamageInfo.Type.MAGIC), 0.0, 0.001)
	assert_almost_eq(shields.amount(&"magebane"), 60.0, 0.001)


func test_total_for_counts_only_the_shields_that_take_the_type() -> void:
	shields.add(&"magebane", 100.0, 0.0, true)
	shields.add(&"endurance", 40.0, 0.0, false, true)
	shields.add(&"barrier", 10.0, 2.0)
	assert_almost_eq(shields.total_for(DamageInfo.Type.PHYSICAL), 50.0, 0.001)
	assert_almost_eq(shields.total_for(DamageInfo.Type.MAGIC), 110.0, 0.001)
	assert_almost_eq(shields.total_for(DamageInfo.Type.TRUE), 10.0, 0.001)
	assert_almost_eq(shields.total(), 150.0, 0.001)


func test_a_timed_shield_runs_out_and_a_lasting_one_stays() -> void:
	shields.add(&"barrier", 50.0, 1.0)
	shields.add(&"ichorshield", 20.0)
	shields.tick(1.1)
	assert_false(shields.has(&"barrier"))
	assert_true(shields.has(&"ichorshield"))


func test_set_amount_to_zero_removes_it() -> void:
	shields.add(&"ichorshield", 20.0)
	shields.set_amount(&"ichorshield", 0.0)
	assert_false(shields.has(&"ichorshield"))

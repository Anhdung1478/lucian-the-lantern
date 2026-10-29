extends GutTest
## Burns and poisons: a tick every 0.5 s, the same id refreshes.

var dots: DamageOverTime


func before_each() -> void:
	dots = DamageOverTime.new()


func _total(hits: Array[DamageInfo]) -> float:
	var total := 0.0
	for hit in hits:
		total += hit.amount
	return total


func test_nothing_running_makes_no_ticks() -> void:
	assert_eq(dots.tick(1.0).size(), 0)
	assert_false(dots.has(&"lava"))
	assert_eq(dots.time_left(&"lava"), 0.0)


func test_a_tick_every_half_second() -> void:
	var attacker: Node = autofree(Node.new())
	dots.add(&"lava", 40.0, 2.0, DamageInfo.Type.MAGIC, attacker)
	assert_eq(dots.tick(0.3).size(), 0, "not yet")
	var hits := dots.tick(0.2)
	assert_eq(hits.size(), 1)
	var hit := hits[0]
	assert_almost_eq(hit.amount, 20.0, 0.001, "40 per second for half a second")
	assert_eq(hit.type, DamageInfo.Type.MAGIC)
	assert_eq(hit.source, &"burn", "never &\"basic\", so Thornmail doesn't answer it")
	assert_true(hit.over_time)
	assert_false(hit.from_skill, "Banshee's Veil lets it through")
	assert_eq(hit.attacker, attacker)


func test_frame_steps_add_up_to_the_whole_burn() -> void:
	dots.add(&"poison", 6.0, 3.0, DamageInfo.Type.MAGIC)
	var count := 0
	var total := 0.0
	for i in 200:
		var hits := dots.tick(1.0 / 60.0)
		count += hits.size()
		total += _total(hits)
	assert_eq(count, 6)
	assert_almost_eq(total, 18.0, 0.001)
	assert_false(dots.has(&"poison"), "over once its time is up")


func test_a_long_step_makes_every_tick_due() -> void:
	dots.add(&"burn", 10.0, 1.5, DamageInfo.Type.TRUE)
	var hits := dots.tick(2.0)
	assert_eq(hits.size(), 3)
	assert_almost_eq(_total(hits), 15.0, 0.001)


func test_a_time_off_the_half_second_ends_with_a_short_tick() -> void:
	dots.add(&"burn", 10.0, 0.75, DamageInfo.Type.TRUE)
	assert_almost_eq(_total(dots.tick(0.5)), 5.0, 0.001)
	var last := dots.tick(0.5)
	assert_eq(last.size(), 1)
	assert_almost_eq(_total(last), 2.5, 0.001)
	assert_false(dots.has(&"burn"))


func test_the_same_id_refreshes_instead_of_stacking() -> void:
	dots.add(&"red", 15.0, 3.0, DamageInfo.Type.TRUE)
	assert_eq(dots.tick(1.0).size(), 2)
	assert_almost_eq(dots.time_left(&"red"), 2.0, 0.001)
	dots.add(&"red", 15.0, 3.0, DamageInfo.Type.TRUE)
	assert_almost_eq(dots.time_left(&"red"), 3.0, 0.001, "refreshed")
	var hits := dots.tick(0.5)
	assert_eq(hits.size(), 1, "one burn, not two")
	assert_almost_eq(_total(hits), 7.5, 0.001)


func test_refreshing_every_frame_keeps_ticking() -> void:
	# Standing in lava refreshes a short burn every frame.
	var count := 0
	for i in 61:
		dots.add(&"lava", 40.0, 0.5, DamageInfo.Type.MAGIC)
		count += dots.tick(1.0 / 60.0).size()
	assert_eq(count, 2, "a tick each half second, not none")


func test_different_ids_burn_side_by_side() -> void:
	dots.add(&"lava", 40.0, 1.0, DamageInfo.Type.MAGIC)
	dots.add(&"poison", 6.0, 1.0, DamageInfo.Type.MAGIC)
	var hits := dots.tick(0.5)
	assert_eq(hits.size(), 2)
	assert_almost_eq(_total(hits), 23.0, 0.001)


func test_clear_ends_every_burn() -> void:
	dots.add(&"lava", 40.0, 1.0, DamageInfo.Type.MAGIC)
	dots.add(&"poison", 6.0, 1.0, DamageInfo.Type.MAGIC)
	dots.clear()
	assert_false(dots.has(&"lava"))
	assert_false(dots.has(&"poison"))
	assert_true(dots.is_empty())
	assert_eq(dots.tick(1.0).size(), 0)


func test_a_freed_attacker_leaves_no_attacker_on_the_tick() -> void:
	var attacker := Node.new()
	dots.add(&"lava", 40.0, 1.0, DamageInfo.Type.MAGIC, attacker)
	attacker.free()
	var hits := dots.tick(0.5)
	assert_eq(hits.size(), 1)
	assert_null(hits[0].attacker)

extends GutTest
## Root, stun and fear timers: one per kind, the longer time wins, tenacity
## shortens them.

const Kind := CrowdControl.Kind

var cc: CrowdControl


func before_each() -> void:
	cc = CrowdControl.new()


func test_nothing_is_on_at_first() -> void:
	for kind in [Kind.ROOT, Kind.STUN, Kind.FEAR]:
		assert_false(cc.has(kind))
		assert_eq(cc.time_left(kind), 0.0)
		assert_eq(cc.duration(kind), 0.0)


func test_the_longer_time_wins() -> void:
	cc.add(Kind.ROOT, 1.0, 0.0)
	cc.add(Kind.ROOT, 0.5, 0.0)
	assert_almost_eq(cc.time_left(Kind.ROOT), 1.0, 0.001, "a shorter root doesn't cut it")
	cc.add(Kind.ROOT, 2.0, 0.0)
	assert_almost_eq(cc.time_left(Kind.ROOT), 2.0, 0.001)
	assert_almost_eq(cc.duration(Kind.ROOT), 2.0, 0.001, "the full time of the one that won")


func test_tenacity_shortens_the_time() -> void:
	cc.add(Kind.STUN, 1.0, 0.3)
	assert_almost_eq(cc.time_left(Kind.STUN), 0.7, 0.001)
	assert_almost_eq(cc.duration(Kind.STUN), 0.7, 0.001)


func test_tenacity_never_lengthens_it_and_full_tenacity_ignores_it() -> void:
	cc.add(Kind.ROOT, 1.0, -0.5)
	assert_almost_eq(cc.time_left(Kind.ROOT), 1.0, 0.001)
	cc.add(Kind.STUN, 1.0, 1.0)
	assert_false(cc.has(Kind.STUN))


func test_it_ticks_down_and_ends() -> void:
	cc.add(Kind.ROOT, 1.0, 0.0)
	cc.tick(0.4)
	assert_true(cc.has(Kind.ROOT))
	assert_almost_eq(cc.time_left(Kind.ROOT), 0.6, 0.001)
	assert_almost_eq(cc.duration(Kind.ROOT), 1.0, 0.001, "the full time stays, for the buff ring")
	cc.tick(0.7)
	assert_false(cc.has(Kind.ROOT))
	assert_eq(cc.time_left(Kind.ROOT), 0.0)


func test_each_kind_has_its_own_time() -> void:
	cc.add(Kind.ROOT, 1.0, 0.0)
	cc.add(Kind.STUN, 0.2, 0.0)
	cc.tick(0.3)
	assert_true(cc.has(Kind.ROOT))
	assert_false(cc.has(Kind.STUN))
	assert_false(cc.has(Kind.FEAR))


func test_a_fear_runs_from_the_fear_that_won_the_time() -> void:
	cc.add(Kind.FEAR, 1.0, 0.0, Vector2(100, 0))
	assert_eq(cc.fear_from(), Vector2(100, 0))
	cc.add(Kind.FEAR, 0.5, 0.0, Vector2(0, 100))
	assert_eq(cc.fear_from(), Vector2(100, 0), "the shorter fear doesn't move the source")
	cc.add(Kind.FEAR, 2.0, 0.0, Vector2(-50, 0))
	assert_eq(cc.fear_from(), Vector2(-50, 0))
	cc.add(Kind.ROOT, 3.0, 0.0, Vector2(999, 999))
	assert_eq(cc.fear_from(), Vector2(-50, 0), "only a fear has a source")


func test_clear_ends_everything() -> void:
	cc.add(Kind.ROOT, 1.0, 0.0)
	cc.add(Kind.STUN, 1.0, 0.0)
	cc.add(Kind.FEAR, 1.0, 0.0, Vector2(10, 0))
	cc.clear()
	for kind in [Kind.ROOT, Kind.STUN, Kind.FEAR]:
		assert_false(cc.has(kind))

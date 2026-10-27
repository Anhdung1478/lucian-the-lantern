extends GutTest
## A skill pressed during a cast lock or the E dash fires once it ends.

const Slot := ChampionProgress.Slot

var lucian: Lucian
var dummy: TrainingDummy
var hits: Array[StringName] = []


func before_each() -> void:
	hits.clear()
	dummy = load("res://src/enemies/training_dummy.tscn").instantiate()
	dummy.position = Vector2(600, 0)
	add_child_autofree(dummy)
	dummy.damage_taken.connect(func(info: DamageInfo, _final: float) -> void: hits.append(info.source))
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	add_child_autofree(lucian)
	lucian.progress.set_level(6)
	for slot in [Slot.Q, Slot.W, Slot.E, Slot.R]:
		lucian.try_rank_up(slot)


func test_w_pressed_during_the_e_dash_fires_after_it_lands() -> void:
	assert_true(lucian.try_cast(Slot.E, lucian.position + Vector2(0, -400)))
	assert_false(lucian.try_cast(Slot.W, dummy.position), "not cast yet: Lucian is dashing")
	assert_eq(lucian.queued_cast(), Slot.W)
	assert_true(lucian.skills[Slot.W].cooldown.is_ready())
	await wait_seconds(0.4)
	assert_false(lucian.is_dashing())
	assert_eq(lucian.queued_cast(), -1)
	assert_false(lucian.skills[Slot.W].cooldown.is_ready(), "W was cast after the dash")


func test_e_pressed_during_the_q_cast_fires_after_it() -> void:
	assert_true(lucian.try_cast(Slot.Q, dummy.position))
	assert_false(lucian.try_cast(Slot.E, lucian.position + Vector2(0, 300)))
	await wait_seconds(0.2)
	assert_true(lucian.skills[Slot.E].cooldown.is_ready(), "still waiting for Q's cast time")
	await wait_seconds(0.25)
	assert_false(lucian.skills[Slot.E].cooldown.is_ready())
	assert_true(&"q" in hits, "Q still fired")


func test_queued_cast_aims_where_the_key_was_pressed() -> void:
	lucian.lock_cast(0.1)
	lucian.try_cast(Slot.W, lucian.position + Vector2(0, 300))
	await wait_seconds(0.2)
	var blaze := lucian.skills[Slot.W] as ArdentBlaze
	assert_almost_eq(blaze._direction.angle(), Vector2.DOWN.angle(), 0.01)


func test_a_newer_press_replaces_the_queued_one() -> void:
	lucian.lock_cast(0.3)
	lucian.try_cast(Slot.W, dummy.position)
	lucian.try_cast(Slot.Q, dummy.position)
	assert_eq(lucian.queued_cast(), Slot.Q)


func test_turned_off_nothing_is_queued() -> void:
	lucian.queue_casts = false
	lucian.lock_cast(0.1)
	assert_false(lucian.try_cast(Slot.W, dummy.position))
	assert_eq(lucian.queued_cast(), -1)
	await wait_seconds(0.2)
	assert_true(lucian.skills[Slot.W].cooldown.is_ready())


func test_skills_that_could_not_be_cast_anyway_are_not_queued() -> void:
	lucian.lock_cast(0.3)
	lucian.skills[Slot.Q].cooldown.start(5.0)
	assert_false(lucian.try_cast(Slot.Q, dummy.position))
	assert_eq(lucian.queued_cast(), -1, "on cooldown")
	lucian.mana = 0.0
	assert_false(lucian.try_cast(Slot.W, dummy.position))
	assert_eq(lucian.queued_cast(), -1, "no mana")


func test_q_and_w_during_r_are_refused_not_queued() -> void:
	lucian.cheat_infinite_mana = true
	assert_true(lucian.try_cast(Slot.R, dummy.position))
	assert_false(lucian.try_cast(Slot.W, dummy.position))
	assert_eq(lucian.queued_cast(), -1)

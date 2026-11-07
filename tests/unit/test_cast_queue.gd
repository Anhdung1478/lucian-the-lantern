extends GutTest
## A skill, item active or summoner spell pressed during a cast lock or a
## dash fires once it ends. They share one slot: the latest press wins.

const Slot := ChampionProgress.Slot
const EQUIP := Inventory.EQUIP_START

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
	# Trails, missiles and sparks go here, so they are freed with the test.
	var effects := Node2D.new()
	add_child_autofree(effects)
	lucian.projectile_parent = effects
	add_child_autofree(lucian)
	lucian.progress.set_level(6)
	for slot in [Slot.Q, Slot.W, Slot.E, Slot.R]:
		lucian.try_rank_up(slot)


func equip(id: StringName, slot := 0) -> void:
	lucian.inventory.put(EQUIP + slot, lucian.item_catalog.find(id))


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


# --- Item actives and summoner spells ---------------------------------------


func test_gunblade_pressed_during_q_s_cast_time_fires_after_it() -> void:
	equip(&"hextech_gunblade")
	assert_true(lucian.try_cast(Slot.Q, dummy.position))
	assert_false(lucian.use_equip_slot(0, dummy.position), "not yet: Q's cast time")
	assert_eq(lucian._queued.kind, Lucian.CastKind.ITEM)
	assert_eq(lucian.queued_cast(), -1, "no skill waits")
	assert_true(lucian.item_cooldown(&"hextech_gunblade").is_ready())
	assert_does_not_have(hits, &"hextech_gunblade")
	await wait_seconds(0.5)
	assert_has(hits, &"hextech_gunblade", "cast once Q's cast time ended")
	assert_has(hits, &"q", "Q still fired")
	assert_false(lucian.item_cooldown(&"hextech_gunblade").is_ready())


func test_galeforce_pressed_during_q_s_cast_time_dashes_after_it() -> void:
	equip(&"galeforce")
	assert_true(lucian.try_cast(Slot.Q, dummy.position))
	assert_false(lucian.use_equip_slot(0, Vector2(0, -400)))
	assert_false(lucian.is_dashing(), "no dash in the cast time")
	await wait_seconds(0.8)
	assert_false(lucian.item_cooldown(&"galeforce").is_ready())
	assert_almost_eq(lucian.global_position, Vector2(0, -ItemActives.GALEFORCE_DASH), Vector2(2, 2))


func test_flash_pressed_during_q_s_cast_time_blinks_after_it() -> void:
	assert_eq(lucian.summoners.slots[0], &"flash")
	assert_true(lucian.try_cast(Slot.Q, dummy.position))
	assert_false(lucian.use_summoner(0, Vector2(0, -1000)))
	assert_eq(lucian.global_position, Vector2.ZERO, "no blink in the cast time")
	assert_eq(lucian._queued.kind, Lucian.CastKind.SUMMONER)
	await wait_seconds(0.5)
	assert_false(lucian.summoners.cooldown(&"flash").is_ready())
	assert_almost_eq(lucian.global_position, Vector2(0, -SummonerSpells.FLASH_RANGE), Vector2(1, 1))


func test_flash_pressed_during_the_e_dash_blinks_after_it_lands() -> void:
	assert_true(lucian.try_cast(Slot.E, Vector2(0, 400)))
	assert_false(lucian.use_summoner(0, Vector2(0, 2000)), "not yet: Lucian is dashing")
	assert_true(lucian.summoners.cooldown(&"flash").is_ready())
	await wait_seconds(0.4)
	assert_false(lucian.is_dashing())
	assert_false(lucian.summoners.cooldown(&"flash").is_ready(), "flashed once the dash landed")
	assert_gt(lucian.global_position.y, SummonerSpells.FLASH_RANGE + 100.0, "the dash, then the blink")


func test_the_latest_press_wins_across_skills_items_and_summoners() -> void:
	equip(&"hextech_gunblade")
	lucian.lock_cast(0.3)
	assert_false(lucian.try_cast(Slot.W, dummy.position))
	assert_eq(lucian.queued_cast(), Slot.W)
	assert_false(lucian.use_equip_slot(0, dummy.position))
	assert_eq(lucian.queued_cast(), -1, "Gunblade took W's place")
	assert_false(lucian.use_summoner(0, Vector2(0, -1000)))
	assert_eq(lucian._queued.kind, Lucian.CastKind.SUMMONER, "Flash took Gunblade's")
	await wait_seconds(0.5)
	assert_true(lucian.skills[Slot.W].cooldown.is_ready(), "W never fired")
	assert_true(lucian.item_cooldown(&"hextech_gunblade").is_ready(), "nor did Gunblade")
	assert_false(lucian.summoners.cooldown(&"flash").is_ready(), "Flash did")


func test_turned_off_no_item_or_summoner_is_queued() -> void:
	lucian.queue_casts = false
	equip(&"hextech_gunblade")
	lucian.lock_cast(0.1)
	assert_false(lucian.use_equip_slot(0, dummy.position))
	assert_false(lucian.use_summoner(0, Vector2(0, -1000)))
	assert_true(lucian._queued.is_empty())
	await wait_seconds(0.3)
	assert_true(lucian.item_cooldown(&"hextech_gunblade").is_ready())
	assert_true(lucian.summoners.cooldown(&"flash").is_ready())
	assert_eq(lucian.global_position, Vector2.ZERO)


func test_turned_off_gunblade_and_smite_out_of_reach_in_a_cast_time_are_refused_and_keep_the_attack() -> void:
	lucian.queue_casts = false
	dummy.position = Vector2(1500, 0)
	await wait_physics_frames(2)
	equip(&"hextech_gunblade")
	lucian.summoners.set_spell(1, &"smite")
	lucian.command_attack(dummy)
	assert_true(lucian.try_cast(Slot.Q, dummy.position))
	assert_false(lucian.use_equip_slot(0, dummy.position), "Gunblade: refused in Q's cast time")
	assert_eq(lucian._order, Lucian.Order.ATTACK, "the attack order is kept")
	assert_false(lucian.use_summoner(1, dummy.position), "Smite: refused too")
	assert_eq(lucian._order, Lucian.Order.ATTACK)
	assert_true(lucian._queued.is_empty())
	await wait_seconds(0.8)
	assert_true(lucian.item_cooldown(&"hextech_gunblade").is_ready(), "no Gunblade after the cast time")
	assert_true(lucian.summoners.cooldown(&"smite").is_ready(), "no Smite either")
	assert_eq(lucian._order, Lucian.Order.ATTACK)
	assert_gt(lucian.global_position.x, 0.0, "he walks on to attack")


func test_turned_off_smite_out_of_reach_during_the_e_dash_is_refused() -> void:
	lucian.queue_casts = false
	dummy.position = Vector2(1500, 0)
	await wait_physics_frames(2)
	lucian.summoners.set_spell(1, &"smite")
	lucian.command_attack(dummy)
	assert_true(lucian.try_cast(Slot.E, Vector2(0, -400)))
	assert_false(lucian.use_summoner(1, dummy.position))
	assert_eq(lucian._order, Lucian.Order.ATTACK, "the attack order is kept")
	await wait_seconds(0.5)
	assert_true(lucian.summoners.cooldown(&"smite").is_ready())


func test_items_and_summoners_on_cooldown_are_not_queued() -> void:
	equip(&"hextech_gunblade")
	lucian.item_cooldown(&"hextech_gunblade").start(5.0)
	lucian.summoners.cooldown(&"flash").start(5.0)
	lucian.lock_cast(0.3)
	assert_false(lucian.use_equip_slot(0, dummy.position))
	assert_false(lucian.use_summoner(0, Vector2(0, -1000)))
	assert_true(lucian._queued.is_empty())


func test_flash_and_item_dashes_pressed_while_rooted_are_not_queued() -> void:
	equip(&"galeforce")
	lucian.add_cc(CrowdControl.Kind.ROOT, 1.0)
	lucian.lock_cast(0.1)
	assert_false(lucian.use_summoner(0, Vector2(0, -1000)))
	assert_false(lucian.use_equip_slot(0, Vector2(0, -400)))
	assert_true(lucian._queued.is_empty())


func test_a_queued_gunblade_on_an_enemy_out_of_reach_walks_over_then_casts() -> void:
	dummy.position = Vector2(1000, 0)
	await wait_physics_frames(2)
	equip(&"hextech_gunblade")
	lucian.lock_cast(0.2)
	assert_false(lucian.use_equip_slot(0, dummy.position))
	assert_eq(lucian._queued.kind, Lucian.CastKind.ITEM)
	# 1000 - 700 - 34 (the dummy's radius) = 266 to walk at 345, after the lock.
	await wait_seconds(1.5)
	assert_eq(hits, [&"hextech_gunblade"])
	assert_almost_eq(lucian.global_position.x, 1000.0 - ItemActives.GUNBLADE_RANGE - dummy.radius, 10.0, "walked only until in reach")


func test_a_stun_drops_a_queued_summoner() -> void:
	lucian.lock_cast(0.3)
	assert_false(lucian.use_summoner(0, Vector2(0, -1000)))
	assert_false(lucian._queued.is_empty())
	lucian.add_cc(CrowdControl.Kind.STUN, 0.2)
	assert_true(lucian._queued.is_empty())
	await wait_seconds(0.5)
	assert_true(lucian.summoners.cooldown(&"flash").is_ready())
	assert_eq(lucian.global_position, Vector2.ZERO)

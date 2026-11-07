extends GutTest

var lucian: Lucian
var attacker: Enemy


func before_each() -> void:
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	add_child_autofree(lucian)
	attacker = Enemy.new()
	attacker.max_hp = 5000.0
	attacker.position = Vector2(100, 0)
	add_child_autofree(attacker)


func _equip(id: StringName) -> void:
	lucian.inventory.put(Inventory.EQUIP_START, lucian.item_catalog.find(id))


func _hit(amount: float, type := DamageInfo.Type.TRUE, from_skill := false) -> DamageInfo:
	var info := DamageInfo.create(amount, type, &"basic", attacker)
	info.from_skill = from_skill
	return info


func test_banshees_blocks_one_skill_then_waits_40_s() -> void:
	_equip(&"banshees_veil")
	var before := lucian.hp
	assert_false(lucian.take_damage(_hit(100.0, DamageInfo.Type.TRUE, true)))
	assert_eq(lucian.hp, before)
	assert_true(lucian.take_damage(_hit(100.0, DamageInfo.Type.TRUE, true)))
	assert_almost_eq(lucian.item_cooldown(&"banshees_veil").remaining, ItemPassives.ANNUL_COOLDOWN, 0.01)


func test_banshees_lets_basic_attacks_through() -> void:
	_equip(&"banshees_veil")
	assert_true(lucian.take_damage(_hit(10.0)))


func test_thornmail_hurts_and_wounds_a_basic_attacker() -> void:
	_equip(&"thornmail")
	lucian.take_damage(_hit(10.0))
	assert_lt(attacker.hp, attacker.max_hp)
	assert_true(attacker.has_status(Enemy.GRIEVOUS_WOUNDS))


func test_shieldbow_shields_before_dropping_under_30_percent() -> void:
	_equip(&"immortal_shieldbow")
	lucian.hp = lucian.stats.max_hp * 0.35
	var before := lucian.hp
	# Would leave 25%: Lifeline (300+) comes first and takes the whole hit.
	lucian.take_damage(_hit(lucian.stats.max_hp * 0.1))
	assert_almost_eq(lucian.hp, before, 0.01)
	assert_true(lucian.shields.has(&"lifeline"))
	assert_false(lucian.item_cooldown(&"immortal_shieldbow").is_ready())


func test_deaths_dance_delays_30_percent() -> void:
	_equip(&"deaths_dance")
	var before := lucian.hp
	lucian.take_damage(_hit(100.0))
	assert_almost_eq(before - lucian.hp, 70.0, 0.5)
	await wait_seconds(ItemPassives.IGNORE_PAIN_TIME + 0.2)
	assert_almost_eq(before - lucian.hp, 100.0 - lucian.stats.hp_regen * (ItemPassives.IGNORE_PAIN_TIME + 0.2), 3.0)


func test_deaths_dance_kill_clears_the_bleed() -> void:
	_equip(&"deaths_dance")
	lucian.take_damage(_hit(100.0))
	assert_false(lucian.passives._bleeds.is_empty())
	lucian.passives.on_kill()
	assert_true(lucian.passives._bleeds.is_empty())
	var after_kill := lucian.hp
	await wait_seconds(0.5)
	assert_gte(lucian.hp, after_kill)


func test_thornmail_ignores_a_freed_attacker() -> void:
	_equip(&"thornmail")
	var info := _hit(10.0)
	attacker.free()
	var before := lucian.hp
	assert_true(lucian.take_damage(info))
	assert_lt(lucian.hp, before)


func test_fimbulwinter_shields_on_a_slow() -> void:
	_equip(&"fimbulwinter")
	lucian.passives.on_enemy_slowed()
	assert_true(lucian.shields.has(&"everlasting"))
	lucian.shields.clear()
	lucian.passives.on_enemy_slowed()
	assert_false(lucian.shields.has(&"everlasting"), "8 s cooldown")


func test_guardian_angel_holds_him_then_revives() -> void:
	_equip(&"guardian_angel")
	watch_signals(lucian)
	lucian.take_damage(_hit(99999.0))
	assert_signal_not_emitted(lucian, "died")
	assert_true(lucian.in_stasis())
	assert_false(lucian.take_damage(_hit(10.0)))
	await wait_seconds(ItemPassives.REBIRTH_STASIS + 0.2)
	assert_false(lucian.in_stasis())
	assert_almost_eq(lucian.hp, lucian.base_stats.at_level(1).max_hp * ItemPassives.REBIRTH_HP, 5.0)
	lucian.take_damage(_hit(99999.0))
	assert_signal_emitted(lucian, "died")


func test_guardian_angel_clears_burns_slows_and_cc_and_refuses_new_ones() -> void:
	_equip(&"guardian_angel")
	lucian.add_burn(&"fire", 60.0, 10.0, DamageInfo.Type.TRUE)
	lucian.add_slow(&"water", 0.3, 10.0)
	lucian.add_cc(CrowdControl.Kind.STUN, 10.0)
	lucian.take_damage(_hit(99999.0))
	assert_true(lucian.in_stasis())
	assert_false(lucian._burns.has(&"fire"), "stasis puts out the burn")
	assert_eq(lucian.slow_amount(), 0.0, "and ends the slow")
	assert_false(lucian.has_cc(CrowdControl.Kind.STUN), "and the stun")
	lucian.add_burn(&"lava", 60.0, 10.0, DamageInfo.Type.TRUE)
	lucian.add_slow(&"mud", 0.5, 10.0)
	assert_false(lucian._burns.has(&"lava"), "no burn lands in stasis")
	assert_eq(lucian.slow_amount(), 0.0, "no slow lands in stasis")
	watch_signals(lucian)
	await wait_seconds(ItemPassives.REBIRTH_STASIS + 1.0)
	assert_false(lucian.in_stasis())
	assert_true(lucian.can_act(), "he comes back free to act")
	assert_false(lucian.dead)
	assert_signal_not_emitted(lucian, "died")


func test_guardian_angel_s_stasis_runs_every_cooldown_and_holds_the_buff_timers() -> void:
	_equip(&"guardian_angel")
	lucian.inventory.put(Inventory.EQUIP_START + 1, lucian.item_catalog.find(&"hextech_gunblade"))
	lucian.item_cooldown(&"hextech_gunblade").start(10.0)
	lucian.skills[ChampionProgress.Slot.Q].cooldown.start(10.0)
	lucian.summoners.cooldown(&"flash").start(10.0)
	lucian.add_speed_buff(&"test", 0.0, 0.2, 10.0)
	lucian.add_stat_buff(&"test", {&"ad": 10.0}, 10.0)
	lucian.add_barrier(100.0, 5.0)
	assert_true(lucian.passives.on_lethal(), "Guardian Angel saves him")
	assert_true(lucian.in_stasis())
	await wait_seconds(1.0)
	assert_true(lucian.in_stasis(), "still held")
	assert_almost_eq(lucian.item_cooldown(&"hextech_gunblade").remaining, 9.0, 0.1, "an item cooldown runs")
	assert_almost_eq(lucian.item_cooldown(&"guardian_angel").remaining, ItemPassives.REBIRTH_COOLDOWN - 1.0, 0.1, "Guardian Angel's own too")
	assert_almost_eq(lucian.skills[ChampionProgress.Slot.Q].cooldown.remaining, 9.0, 0.1, "a skill cooldown runs")
	assert_almost_eq(lucian.summoners.cooldown(&"flash").remaining, 9.0, 0.1, "a summoner cooldown runs")
	assert_eq(lucian._speed_buffs[&"test"].left, 10.0, "a move speed buff keeps its time")
	assert_eq(lucian._stat_buffs[&"test"].left, 10.0, "a stat buff keeps its time")
	assert_eq(lucian.shields.time_left(&"barrier"), 5.0, "Barrier keeps its time")


func test_kaenic_rookern_shields_after_15_quiet_seconds() -> void:
	_equip(&"kaenic_rookern")
	lucian.passives._magebane_wait = ItemPassives.MAGEBANE_WAIT - 0.05
	await wait_physics_frames(6)
	assert_true(lucian.shields.has(&"magebane"))
	var before := lucian.hp
	lucian.take_damage(_hit(30.0, DamageInfo.Type.PHYSICAL))
	assert_lt(lucian.hp, before, "magic only")

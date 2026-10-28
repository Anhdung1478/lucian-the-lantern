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
	lucian.passives.on_kill()
	var after_kill := lucian.hp
	await wait_seconds(0.5)
	assert_gte(lucian.hp, after_kill)


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


func test_kaenic_rookern_shields_after_15_quiet_seconds() -> void:
	_equip(&"kaenic_rookern")
	lucian.passives._magebane_wait = ItemPassives.MAGEBANE_WAIT - 0.05
	await wait_physics_frames(6)
	assert_true(lucian.shields.has(&"magebane"))
	var before := lucian.hp
	lucian.take_damage(_hit(30.0, DamageInfo.Type.PHYSICAL))
	assert_lt(lucian.hp, before, "magic only")

extends GutTest
## V1.4 boots in combat: slow resist, summoner haste, flat magic penetration,
## Plating, Slay, Now and Forever, Noxian Fervor, Noxian Haste and the two
## Noxian shields.

var lucian: Lucian
var target: Enemy


func before_each() -> void:
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	add_child_autofree(lucian)
	target = Enemy.new()
	target.max_hp = 5000.0
	target.position = Vector2(100, 0)
	add_child_autofree(target)


func _wear(id: StringName) -> void:
	lucian.inventory.set_boots(lucian.item_catalog.find(id))


func _hit(amount: float, type: DamageInfo.Type, source := &"basic") -> DamageInfo:
	return DamageInfo.create(amount, type, source, target)


## A killed enemy of `kind`, never added to the tree: its visuals and health
## bar only become its children in _ready, so they are freed by hand.
func _unit(kind: StringName) -> EnemyUnit:
	var unit: EnemyUnit = autofree(EnemyUnit.new())
	autofree(unit.visuals)
	autofree(unit.health_bar)
	unit.data = EnemyData.new()
	unit.data.kind = kind
	return unit


# --- New rules -----------------------------------------------------------------


func test_slow_resist_weakens_slows() -> void:
	lucian.add_slow(&"test", 0.4, 2.0)
	assert_almost_eq(lucian.slow_amount(), 0.4, 0.001)
	_wear(&"boots_of_swiftness")
	assert_almost_eq(lucian.slow_amount(), 0.3, 0.001, "25% slow resist")
	var slowed: Array = lucian.buffs().filter(func(buff: Dictionary) -> bool: return buff.id == Lucian.SLOWED)
	assert_string_contains(slowed[0].text, "-30%")


func test_summoner_haste_shortens_summoner_cooldowns() -> void:
	var flash := SummonerSpells.find(&"flash")
	var heal := SummonerSpells.find(&"heal")
	assert_almost_eq(lucian.summoners.cooldown_of(flash), flash.cooldown, 0.001)
	_wear(&"ionian_boots_of_lucidity")
	assert_almost_eq(lucian.summoners.cooldown_of(flash), flash.cooldown * 100.0 / 110.0, 0.001)
	_wear(&"crimson_lucidity")
	assert_almost_eq(lucian.summoners.cooldown_of(heal), heal.cooldown * 100.0 / 120.0, 0.001)


func test_flat_magic_pen_rides_on_his_hits() -> void:
	_wear(&"sorcerers_shoes")
	assert_almost_eq(lucian.make_damage(10.0, DamageInfo.Type.MAGIC, &"q").magic_pen_flat, 12.0, 0.001)
	_wear(&"spellslingers_shoes")
	var info := lucian.make_damage(10.0, DamageInfo.Type.MAGIC, &"q")
	assert_almost_eq(info.magic_pen_flat, 20.0, 0.001)
	assert_almost_eq(info.magic_pen, 0.08, 0.001)


func test_flat_magic_pen_on_an_enemy() -> void:
	_wear(&"sorcerers_shoes")
	target.mr = 62.0
	var dealt := target.take_damage(lucian.make_damage(100.0, DamageInfo.Type.MAGIC, &"q"))
	assert_almost_eq(dealt, 100.0 * 100.0 / 150.0, 0.01, "62 MR - 12 = 50")


func test_plating_lowers_basic_attacks_only() -> void:
	_wear(&"plated_steelcaps")
	var before := lucian.hp
	lucian.take_damage(_hit(100.0, DamageInfo.Type.TRUE))
	assert_almost_eq(before - lucian.hp, 90.0, 0.01, "a basic attack: -10%")
	before = lucian.hp
	lucian.take_damage(_hit(100.0, DamageInfo.Type.TRUE, &"slam"))
	assert_almost_eq(before - lucian.hp, 100.0, 0.01, "a skill")
	before = lucian.hp
	var burn := _hit(100.0, DamageInfo.Type.TRUE)
	burn.over_time = true
	lucian.take_damage(burn)
	assert_almost_eq(before - lucian.hp, 100.0, 0.01, "a burn tick")
	_wear(&"armored_advance")
	assert_almost_eq(lucian.passives.damage_taken_multiplier(_hit(1.0, DamageInfo.Type.PHYSICAL)), 0.9, 0.001, "tier 3 keeps Plating")


func test_tier_3_mercury_line_keeps_tenacity() -> void:
	_wear(&"chainlaced_crushers")
	assert_almost_eq(lucian.stats.tenacity, 0.3, 0.001)


# --- Slay and Now and Forever ----------------------------------------------------


func test_slay_stacks_on_elites_mini_bosses_and_bosses() -> void:
	_wear(&"gluttonous_greaves")
	var omnivamp := lucian.stats.omnivamp
	lucian.on_kill(_unit(&"normal"))
	assert_eq(lucian.passives.slay_stacks, 0, "a normal enemy")
	for kind in [&"elite", &"mini_boss", &"boss"]:
		lucian.on_kill(_unit(kind))
	assert_eq(lucian.passives.slay_stacks, 3)
	assert_almost_eq(lucian.stats.omnivamp, omnivamp + 3 * ItemPassives.SLAY_OMNIVAMP, 0.0001)
	for i in 20:
		lucian.passives.on_kill(_unit(&"elite"))
	assert_eq(lucian.passives.slay_stacks, ItemPassives.SLAY_MAX)


func test_slay_carries_over_to_immortal_path() -> void:
	_wear(&"gluttonous_greaves")
	for i in 4:
		lucian.passives.on_kill(_unit(&"elite"))
	var shop := Shop.new(MerchantStock.new(lucian.item_catalog, 1), lucian.inventory, Wallet.new())
	shop.wallet.add(500)
	lucian.inventory.add(lucian.item_catalog.find(&"bf_sword"))
	assert_eq(shop.craft(Inventory.BOOTS_CELL, 0), Shop.Result.OK)
	assert_eq(lucian.inventory.boots().id, &"immortal_path")
	assert_eq(lucian.passives.slay_stacks, 4)
	lucian.inventory.set_boots(lucian.item_catalog.find(&"boots_of_speed"))
	assert_eq(lucian.passives.slay_stacks, 0, "gone once neither pair is worn")


func test_now_and_forever_damage_above_half_health() -> void:
	_wear(&"immortal_path")
	lucian.hp = lucian.stats.max_hp
	var info := _hit(100.0, DamageInfo.Type.PHYSICAL, &"q")
	lucian.passives.before_damage(target, info)
	assert_almost_eq(info.amount, 104.0, 0.001)
	lucian.hp = lucian.stats.max_hp * 0.4
	info = _hit(100.0, DamageInfo.Type.PHYSICAL, &"q")
	lucian.passives.before_damage(target, info)
	assert_almost_eq(info.amount, 100.0, 0.001)


func test_now_and_forever_heals_and_shields_below_half_health() -> void:
	_wear(&"immortal_path")
	lucian.hp = lucian.stats.max_hp * 0.4
	assert_almost_eq(lucian.passives.heal_scale(), 1.12, 0.001)
	var before := lucian.hp
	lucian.heal(100.0)
	assert_almost_eq(lucian.hp - before, 112.0, 0.01)
	# The heal may have lifted him past half health.
	lucian.hp = lucian.stats.max_hp * 0.4
	lucian.add_shield(&"barrier", 100.0, 2.0)
	assert_almost_eq(lucian.shields.amount(&"barrier"), 112.0, 0.01)
	lucian.hp = lucian.stats.max_hp * 0.8
	assert_almost_eq(lucian.passives.heal_scale(), 1.0, 0.001)
	_wear(&"gluttonous_greaves")
	lucian.hp = lucian.stats.max_hp * 0.4
	assert_almost_eq(lucian.passives.heal_scale(), 1.0, 0.001, "only Immortal Path")


# --- Noxian passives ----------------------------------------------------------------


func test_noxian_fervor_gives_ad_from_move_speed() -> void:
	_wear(&"swiftmarch")
	var force := lucian.stats.move_speed * ItemPassives.NOXIAN_FERVOR
	assert_almost_eq(lucian.bonus_ad(), force * ItemPassives.ADAPTIVE_AD, 0.01)
	assert_almost_eq(lucian.stats.ap, 0.0, 0.001)


func test_noxian_fervor_gives_ap_when_bonus_ap_is_higher() -> void:
	lucian.inventory.put(Inventory.EQUIP_START, lucian.item_catalog.find(&"needlessly_large_rod"))
	var ap := lucian.stats.ap
	_wear(&"swiftmarch")
	assert_almost_eq(lucian.stats.ap, ap + lucian.stats.move_speed * ItemPassives.NOXIAN_FERVOR, 0.01)
	assert_almost_eq(lucian.bonus_ad(), 0.0, 0.01)


func test_noxian_haste_once_every_4_seconds() -> void:
	_wear(&"crimson_lucidity")
	lucian.passives.on_summoner_used()
	var speed := lucian.current_move_speed()
	assert_almost_eq(speed, lucian.stats.move_speed * 1.08, 0.01)
	assert_almost_eq(lucian.item_cooldown(&"crimson_lucidity").remaining, 4.0, 0.001)
	lucian.item_cooldown(&"crimson_lucidity").reduce(1.0)
	lucian.passives.on_damage_dealt(target, _hit(10.0, DamageInfo.Type.PHYSICAL, &"q"), 10.0)
	assert_almost_eq(lucian.item_cooldown(&"crimson_lucidity").remaining, 3.0, 0.001, "not again inside 4 s")
	lucian.item_cooldown(&"crimson_lucidity").reduce(3.0)
	lucian.passives.on_damage_dealt(target, _hit(10.0, DamageInfo.Type.PHYSICAL, &"q"), 10.0)
	assert_almost_eq(lucian.item_cooldown(&"crimson_lucidity").remaining, 4.0, 0.001, "a skill hit")
	lucian.item_cooldown(&"crimson_lucidity").reduce(4.0)
	lucian.passives.on_damage_dealt(target, _hit(10.0, DamageInfo.Type.PHYSICAL, &"basic"), 10.0)
	assert_true(lucian.item_cooldown(&"crimson_lucidity").is_ready(), "a basic attack is not a skill")


func test_a_summoner_spell_triggers_noxian_haste() -> void:
	_wear(&"crimson_lucidity")
	lucian.summoners.slots = [&"heal", &""]
	lucian.summoners.open_slots = 1
	assert_true(lucian.use_summoner(0, lucian.global_position))
	assert_false(lucian.item_cooldown(&"crimson_lucidity").is_ready())


func test_noxian_persistence_shields_against_magic() -> void:
	_wear(&"chainlaced_crushers")
	lucian.take_damage(_hit(10.0, DamageInfo.Type.PHYSICAL))
	assert_false(lucian.shields.has(&"persistence"), "physical damage doesn't raise it")
	lucian.take_damage(_hit(10.0, DamageInfo.Type.MAGIC))
	assert_almost_eq(lucian.shields.amount(&"persistence"), ItemPassives.NOXIAN_SHIELD_MIN, 0.01, "level 1, no bonus HP")
	assert_almost_eq(lucian.item_cooldown(&"chainlaced_crushers").remaining, 15.0, 0.001)
	var before := lucian.hp
	lucian.take_damage(_hit(50.0, DamageInfo.Type.TRUE))
	assert_lt(lucian.hp, before, "true damage goes past a magic shield")
	before = lucian.hp
	lucian.take_damage(_hit(50.0, DamageInfo.Type.MAGIC, &"slam"))
	assert_almost_eq(lucian.hp, before, 0.01, "magic damage is absorbed")


func test_noxian_endurance_shields_against_physical_only() -> void:
	_wear(&"armored_advance")
	lucian.take_damage(_hit(10.0, DamageInfo.Type.MAGIC))
	assert_false(lucian.shields.has(&"endurance"))
	lucian.take_damage(_hit(10.0, DamageInfo.Type.PHYSICAL))
	assert_true(lucian.shields.has(&"endurance"))
	assert_almost_eq(lucian.shields.time_left(&"endurance"), 5.0, 0.001)
	var before := lucian.hp
	lucian.take_damage(_hit(30.0, DamageInfo.Type.MAGIC, &"slam"))
	assert_lt(lucian.hp, before, "magic damage goes past a physical shield")
	assert_true(lucian.buffs().any(func(buff: Dictionary) -> bool: return buff.id == &"endurance"))


func test_the_noxian_shields_grow_with_level_and_bonus_hp() -> void:
	_wear(&"chainlaced_crushers")
	lucian.progress.set_level(ChampionProgress.MAX_LEVEL)
	lucian.inventory.put(Inventory.EQUIP_START, lucian.item_catalog.find(&"giants_belt"))
	lucian.take_damage(_hit(1.0, DamageInfo.Type.MAGIC))
	var expected := ItemPassives.NOXIAN_SHIELD_MAX + ItemPassives.NOXIAN_SHIELD_HP * lucian.bonus_hp()
	assert_gt(lucian.bonus_hp(), 0.0)
	assert_almost_eq(lucian.shields.amount(&"persistence"), expected, 0.01)


func test_the_noxian_shields_absorb_after_magebane() -> void:
	var order := Shields.ORDER
	assert_eq(order.find(&"persistence"), order.find(&"magebane") + 1)
	assert_eq(order.find(&"endurance"), order.find(&"persistence") + 1)
	var shields := Shields.new()
	shields.add(&"endurance", 50.0, 5.0, false, true)
	shields.add(&"barrier", 50.0, 2.0)
	assert_almost_eq(shields.absorb(30.0, DamageInfo.Type.PHYSICAL), 0.0, 0.001)
	assert_almost_eq(shields.amount(&"endurance"), 20.0, 0.001, "first in order")
	assert_almost_eq(shields.absorb(40.0, DamageInfo.Type.MAGIC), 0.0, 0.001)
	assert_almost_eq(shields.amount(&"barrier"), 10.0, 0.001, "magic skips the physical-only shield")
	assert_almost_eq(shields.amount(&"endurance"), 20.0, 0.001)

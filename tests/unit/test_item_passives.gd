extends GutTest
## Item passives on a real Lucian against real training dummies.

const Slot := ChampionProgress.Slot
const EQUIP := Inventory.EQUIP_START

var lucian: Lucian
var dummy: TrainingDummy
## [source, type, final_amount] per hit on any dummy.
var hits: Array[Array] = []


func before_each() -> void:
	hits.clear()
	dummy = _dummy(Vector2(600, 0))
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	add_child_autofree(lucian)
	lucian.cheat_infinite_mana = true
	lucian.cheat_crit_chance = 0.0


func _dummy(at: Vector2) -> TrainingDummy:
	var made: TrainingDummy = load("res://src/enemies/training_dummy.tscn").instantiate()
	made.position = at
	add_child_autofree(made)
	made.damage_taken.connect(func(info: DamageInfo, final_amount: float) -> void:
		hits.append([info.source, info.type, final_amount]))
	return made


func equip(id: StringName, slot := 0) -> void:
	lucian.inventory.put(EQUIP + slot, lucian.item_catalog.find(id))


func sources() -> Array:
	return hits.map(func(hit: Array) -> StringName: return hit[0])


## One basic attack landing on `target` right away (no projectile flight).
func basic_hit(target: Enemy = dummy) -> void:
	target.take_damage(lucian.basic_attack(target))


func skill_hit(source: StringName, target: Enemy = dummy, amount := 100.0) -> void:
	target.take_damage(lucian.make_damage(amount, DamageInfo.Type.PHYSICAL, source))


func test_items_in_the_backpack_do_nothing() -> void:
	lucian.inventory.add(lucian.item_catalog.find(&"kraken_slayer"))
	for i in 3:
		basic_hit()
	assert_eq(sources(), [&"basic", &"basic", &"basic"])
	assert_false(lucian.passives.has(&"kraken_slayer"))


func test_kraken_slayer_hits_harder_every_third_attack() -> void:
	equip(&"kraken_slayer")
	for i in 3:
		basic_hit()
	assert_eq(sources(), [&"basic", &"basic", &"basic", &"kraken_slayer"])
	assert_eq(lucian.passives.kraken_hits, 0)


func test_duplicates_count_once() -> void:
	equip(&"kraken_slayer", 0)
	equip(&"kraken_slayer", 1)
	basic_hit()
	assert_eq(lucian.passives.kraken_hits, 1)


func test_kraken_bonus_grows_against_low_health() -> void:
	equip(&"kraken_slayer")
	for i in 3:
		basic_hit()
	var full: float = hits[3][2]
	hits.clear()
	dummy.hp = dummy.max_hp * 0.2
	for i in 3:
		basic_hit()
	assert_gt(hits[3][2], full * 1.3)


func test_infinity_edge_raises_crit_damage() -> void:
	var before := lucian.stats.crit_damage
	equip(&"infinity_edge")
	assert_almost_eq(lucian.stats.crit_damage, before + 0.4, 0.0001)


func test_awe_items_turn_mana_into_stats() -> void:
	equip(&"archangels_staff")
	var base := lucian.base_stats.at_level(1)
	var max_mana := base.max_mana + 450.0
	assert_almost_eq(lucian.stats.max_mana, max_mana, 0.01)
	assert_almost_eq(lucian.stats.ap, 60.0 + max_mana * 0.02, 0.01)
	equip(&"muramana", 1)
	max_mana += 600.0
	assert_almost_eq(lucian.stats.ad, base.ad + 35.0 + max_mana * 0.025, 0.01)
	equip(&"fimbulwinter", 2)
	max_mana += 450.0
	assert_almost_eq(lucian.stats.max_hp, base.max_hp + max_mana * 0.08, 0.01)


func test_rabadon_multiplies_ability_power() -> void:
	equip(&"rabadons_deathcap")
	assert_almost_eq(lucian.stats.ap, 110.0 * 1.3, 0.01)


func test_spirit_visage_boosts_healing() -> void:
	equip(&"spirit_visage")
	lucian.hp = 100.0
	lucian.heal(40.0)
	assert_almost_eq(lucian.hp, 150.0, 0.01)


func test_nashors_tooth_adds_magic_on_hit() -> void:
	equip(&"nashors_tooth")
	basic_hit()
	assert_eq(sources(), [&"basic", &"nashors_tooth"])
	assert_eq(hits[1][1], DamageInfo.Type.MAGIC)


func test_on_hit_effects_also_ride_the_lightslinger_shot() -> void:
	equip(&"nashors_tooth")
	skill_hit(&"lightslinger")
	assert_eq(sources(), [&"lightslinger", &"nashors_tooth"])


func test_navori_cuts_q_w_e_cooldowns() -> void:
	equip(&"navori_flickerblade")
	var q := lucian.skills[Slot.Q].cooldown
	q.start(10.0)
	basic_hit()
	assert_almost_eq(q.remaining, 8.8, 0.001)


func test_essence_reaver_spellblade_after_a_cast() -> void:
	equip(&"essence_reaver")
	lucian.try_rank_up(Slot.Q)
	assert_true(lucian.try_cast(Slot.Q, dummy.position))
	assert_true(lucian.passives.spellblade_ready)
	lucian.cheat_infinite_mana = false
	lucian.mana = 0.0
	basic_hit()
	assert_true(sources().has(&"essence_reaver"))
	assert_gt(lucian.mana, 0.0, "restores mana")
	assert_false(lucian.item_cooldown(&"essence_reaver").is_ready())


func test_muramana_shock_on_skills_and_attacks() -> void:
	equip(&"muramana")
	skill_hit(&"q")
	basic_hit()
	assert_eq(sources(), [&"q", &"muramana", &"basic", &"muramana"])


func test_black_cleaver_carves_armor_and_grants_speed() -> void:
	equip(&"black_cleaver")
	var speed := lucian.current_move_speed()
	skill_hit(&"q")
	skill_hit(&"q")
	assert_eq(dummy.status_stacks(Enemy.CARVE), 2)
	assert_almost_eq(dummy.effective_armor(), dummy.armor * 0.9, 0.001)
	assert_almost_eq(lucian.current_move_speed(), speed + 20.0, 0.01)


func test_grievous_wounds_from_physical_and_magic() -> void:
	equip(&"mortal_reminder")
	skill_hit(&"q")
	assert_true(dummy.has_status(Enemy.GRIEVOUS_WOUNDS))
	dummy.hp = 100.0
	dummy.heal(100.0)
	assert_almost_eq(dummy.hp, 160.0, 0.01)


func test_lord_dominiks_scales_with_the_health_gap() -> void:
	var plain := dummy.take_damage(lucian.make_damage(100.0, DamageInfo.Type.TRUE, &"q"))
	equip(&"lord_dominiks_regards")
	var gap := dummy.max_hp - lucian.stats.max_hp
	var boosted := dummy.take_damage(lucian.make_damage(100.0, DamageInfo.Type.TRUE, &"q"))
	assert_almost_eq(boosted, plain * (1.0 + 0.15 * minf(gap / 1500.0, 1.0)), 0.01)


func test_shadowflame_boosts_magic_on_low_health() -> void:
	equip(&"shadowflame")
	var normal := dummy.take_damage(lucian.make_damage(100.0, DamageInfo.Type.TRUE, &"w"))
	dummy.hp = dummy.max_hp * 0.3
	var low := dummy.take_damage(lucian.make_damage(100.0, DamageInfo.Type.MAGIC, &"w"))
	var low_true := dummy.take_damage(lucian.make_damage(100.0, DamageInfo.Type.TRUE, &"w"))
	assert_almost_eq(low_true, normal, 0.01, "true damage is not magic")
	# Shadowflame also gives magic penetration.
	assert_almost_eq(low, 100.0 * 1.2 * DamageCalc.resist_multiplier(dummy.mr * (1.0 - lucian.stats.magic_pen)), 0.01)


func test_shojin_stacks_once_per_cast() -> void:
	equip(&"spear_of_shojin")
	lucian.try_rank_up(Slot.Q)
	lucian.try_cast(Slot.Q, dummy.position)
	skill_hit(&"q")
	skill_hit(&"q")
	assert_eq(lucian.passives.shojin_stacks, 1)
	var hit := lucian.make_damage(100.0, DamageInfo.Type.TRUE, &"q")
	lucian.before_damage(dummy, hit)
	assert_almost_eq(hit.amount, 103.0, 0.001)


func test_archangel_mana_charge_once_per_cast() -> void:
	equip(&"archangels_staff")
	var before := lucian.stats.max_mana
	lucian.try_rank_up(Slot.Q)
	lucian.try_cast(Slot.Q, dummy.position)
	skill_hit(&"q")
	skill_hit(&"q")
	assert_almost_eq(lucian.stats.max_mana, before + 3.0, 0.001)


func test_runaans_shoots_two_other_enemies() -> void:
	equip(&"runaans_hurricane")
	_dummy(Vector2(600, 200))
	_dummy(Vector2(600, -200))
	_dummy(Vector2(1500, 0))
	basic_hit()
	await wait_seconds(0.4)
	assert_eq(sources().count(&"runaans_hurricane"), 2)


func test_bloodthirster_turns_overheal_into_a_shield() -> void:
	equip(&"bloodthirster")
	lucian.hp = lucian.stats.max_hp
	skill_hit(&"basic", dummy, 500.0)
	assert_gt(lucian.shield, 0.0)
	assert_lte(lucian.shield, 300.0)


func test_energize_needs_an_energized_item() -> void:
	lucian.passives.on_moved(500.0, false)
	assert_eq(lucian.passives.energize.value, 0.0)
	equip(&"statikk_shiv")
	lucian.passives.on_moved(240.0, false)
	assert_almost_eq(lucian.passives.energize.value, 10.0, 0.001)
	basic_hit()
	assert_almost_eq(lucian.passives.energize.value, 19.0, 0.001)


func test_walking_builds_energize() -> void:
	equip(&"statikk_shiv")
	lucian.command_move(Vector2(-600, 0))
	await wait_seconds(0.6)
	assert_gt(lucian.passives.energize.value, 5.0)


func test_statikk_chain_hits_nearby_enemies() -> void:
	equip(&"statikk_shiv")
	_dummy(Vector2(800, 0))
	_dummy(Vector2(1000, 0))
	lucian.passives.energize.value = 100.0
	basic_hit()
	assert_eq(sources().count(&"statikk_shiv"), 3)
	assert_eq(lucian.passives.energize.value, 0.0)


func test_rapid_firecannon_reaches_further_when_energized() -> void:
	equip(&"rapid_firecannon")
	var normal := lucian.attack_range()
	lucian.passives.energize.value = 100.0
	assert_almost_eq(lucian.attack_range(), normal * 1.35, 0.01)
	basic_hit()
	assert_true(sources().has(&"rapid_firecannon"))


func test_stormrazor_energized_speed() -> void:
	equip(&"stormrazor")
	var speed := lucian.current_move_speed()
	lucian.passives.energize.value = 100.0
	basic_hit()
	assert_true(sources().has(&"stormrazor"))
	assert_almost_eq(lucian.current_move_speed(), speed * 1.35, 0.01)


func test_jaksho_stacks_while_in_combat() -> void:
	equip(&"jaksho_the_protean")
	var armor := lucian.stats.armor
	skill_hit(&"q")
	await wait_seconds(1.2)
	assert_eq(lucian.passives.jaksho_stacks, 1)
	assert_almost_eq(lucian.stats.armor, armor * 1.05, 0.01)


func test_malignance_hastes_r_and_scorches_on_r_hits() -> void:
	equip(&"malignance")
	assert_eq(lucian.passives.skill_haste(Slot.R), 20.0)
	assert_eq(lucian.passives.skill_haste(Slot.Q), 0.0)
	skill_hit(&"r")
	await wait_physics_frames(3)
	assert_true(sources().has(&"malignance"))
	assert_true(dummy.has_status(Enemy.HATEFOG))


func test_buffs_list_the_passive_states() -> void:
	equip(&"kraken_slayer")
	equip(&"statikk_shiv", 1)
	var ids := lucian.buffs().map(func(buff: Dictionary) -> StringName: return buff.id)
	assert_has(ids, &"energized")
	assert_has(ids, &"kraken_slayer")
	lucian.inventory.clear()
	ids = lucian.buffs().map(func(buff: Dictionary) -> StringName: return buff.id)
	assert_does_not_have(ids, &"energized")


func test_hatefog_ticks_three_times() -> void:
	var zone := HatefogZone.new()
	zone.setup(lucian, dummy.global_position, null)
	add_child_autofree(zone)
	await wait_seconds(3.6)
	assert_eq(sources().count(&"malignance"), 3)


func test_unequipping_mid_cast_ends_the_shojin_arming() -> void:
	equip(&"spear_of_shojin")
	lucian.try_rank_up(Slot.Q)
	lucian.try_cast(Slot.Q, dummy.position)
	lucian.inventory.clear()
	skill_hit(&"q")
	assert_eq(lucian.passives.shojin_stacks, 0)


func test_rfc_ring_shows_from_full_energize_until_the_shot_lands() -> void:
	equip(&"rapid_firecannon")
	assert_false(lucian.passives.shows_rfc_ring())
	lucian.passives.energize.value = 100.0
	assert_true(lucian.passives.shows_rfc_ring())
	var info := lucian.basic_attack(dummy)
	assert_true(lucian.passives.shows_rfc_ring(), "the Energized shot is still flying")
	dummy.take_damage(info)
	assert_false(lucian.passives.shows_rfc_ring())


func test_rfc_ring_gives_up_when_the_shot_never_lands() -> void:
	equip(&"rapid_firecannon")
	lucian.passives.energize.value = 100.0
	lucian.basic_attack(dummy)
	await wait_seconds(1.2)
	assert_false(lucian.passives.shows_rfc_ring())

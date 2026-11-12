extends GutTest
## Elite traits (D1): who gets one, what each does, what it pays and how it
## shows.

var lucian: Lucian


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real save.
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new("user://test_elite_traits_save_slot_")
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	add_child_autofree(lucian)


func _data(id: String) -> EnemyData:
	return load("res://data/enemies/%s.tres" % id)


func _run(act: int, endless := false) -> StageSetup:
	var run := StageSetup.new()
	run.act = act
	run.endless = endless
	return run


## A frozen elite siege minion (Act 3's numbers) with `trait_id`, in the tree.
func _elite(trait_id: StringName, at := Vector2(100, 0)) -> Minion:
	var minion := Minion.new()
	minion.setup(_data("siege_minion"), 3, 1, lucian)
	minion.position = at
	EliteTrait.apply(minion, trait_id)
	add_child_autofree(minion)
	minion.set_physics_process(false)
	return minion


func _story(act: int, stage_number: int) -> Stage:
	SaveGame.instance().reset()
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_stage(SaveGame.instance(), act, stage_number))
	add_child_autofree(stage)
	await wait_process_frames(2)
	stage.lucian.invulnerable = true
	stage.runner._countdown = 999.0
	return stage


func _kill(unit: Enemy) -> void:
	unit.take_damage(DamageInfo.create(9999999.0, DamageInfo.Type.TRUE, &"test"))


func test_who_gets_a_trait() -> void:
	var elite := _data("siege_minion")
	assert_false(EliteTrait.applies(elite, _run(1), 1), "Act 1")
	assert_false(EliteTrait.applies(elite, _run(2), 1), "Act 2")
	for act in [3, 4, 5, 6]:
		assert_true(EliteTrait.applies(elite, _run(act), 1), "Act %d" % act)
	assert_false(EliteTrait.applies(elite, _run(0), 1), "Training")
	assert_false(EliteTrait.applies(elite, _run(3), 1, true), "a summon")


func test_who_never_gets_a_trait() -> void:
	for id in ["melee_minion", "rift_scuttler", "infernal_drake", "elder_dragon"]:
		assert_false(EliteTrait.applies(_data(id), _run(3), 1), id)


func test_endless_starts_at_wave_11() -> void:
	var elite := _data("siege_minion")
	assert_false(EliteTrait.applies(elite, _run(0, true), 10), "wave 10")
	assert_true(EliteTrait.applies(elite, _run(0, true), 11), "wave 11")
	assert_false(EliteTrait.applies(_data("melee_minion"), _run(0, true), 30), "a normal")
	assert_false(EliteTrait.applies(_data("rift_scuttler"), _run(0, true), 30), "an escaper")


func test_the_table_has_four_traits_with_icons_and_tips() -> void:
	assert_eq(EliteTrait.IDS.size(), 4)
	for id in EliteTrait.IDS:
		assert_not_null(EliteTrait.icon(id), "%s icon" % id)
		assert_ne(EliteTrait.tip(id), "", "%s tip" % id)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var seen := {}
	for i in 60:
		seen[EliteTrait.pick(rng)] = true
	assert_eq(seen.size(), 4, "the rng reaches all four")


func test_swift_is_faster_and_attacks_sooner() -> void:
	var plain := _elite(&"")
	var swift := _elite(EliteTrait.SWIFT)
	assert_almost_eq(swift.move_speed, plain.move_speed * 1.25, 0.01)
	assert_almost_eq(swift.attack_interval, plain.attack_interval / 1.15, 0.001)
	assert_eq(swift.elite_trait, EliteTrait.SWIFT)


func test_armored_adds_armor_and_magic_resist() -> void:
	var plain := _elite(&"")
	var armored := _elite(EliteTrait.ARMORED)
	assert_eq(armored.armor, plain.armor + 40.0)
	assert_eq(armored.mr, plain.mr + 40.0)


func test_vampiric_heals_a_share_of_what_its_hit_deals() -> void:
	var vampire := _elite(EliteTrait.VAMPIRIC)
	vampire.hp = 100.0
	watch_signals(lucian)
	assert_true(lucian.take_damage(vampire.make_hit()))
	var dealt: float = get_signal_parameters(lucian, "damage_received", 0)[1]
	assert_almost_eq(vampire.hp, 100.0 + dealt * 0.3, 0.01)


func test_vampiric_heal_goes_through_heal_so_grievous_wounds_cuts_it() -> void:
	var vampire := _elite(EliteTrait.VAMPIRIC)
	vampire.hp = 100.0
	vampire.add_status(Enemy.GRIEVOUS_WOUNDS, 5.0)
	watch_signals(lucian)
	lucian.take_damage(vampire.make_hit())
	var dealt: float = get_signal_parameters(lucian, "damage_received", 0)[1]
	assert_almost_eq(vampire.hp, 100.0 + dealt * 0.3 * Enemy.GRIEVOUS_HEALING, 0.01)


func test_a_burn_tick_does_not_heal_a_vampire() -> void:
	var vampire := _elite(EliteTrait.VAMPIRIC)
	vampire.hp = 100.0
	var tick := vampire.make_hit()
	tick.over_time = true
	lucian.take_damage(tick)
	assert_eq(vampire.hp, 100.0)


func test_volatile_leaves_a_warning_that_outlives_it_and_hits_inside() -> void:
	var volatile := _elite(EliteTrait.VOLATILE, Vector2(60, 0))
	var damage := volatile.damage
	watch_signals(lucian)
	_kill(volatile)
	await wait_physics_frames(3)
	var warnings := get_children().filter(func(node: Node) -> bool: return node is GroundWarning)
	assert_eq(warnings.size(), 1, "the warning stands after its owner died")
	assert_eq((warnings[0] as GroundWarning).reach, EliteTrait.BLAST_RADIUS)
	assert_eq((warnings[0] as GroundWarning).warn_time, EliteTrait.BLAST_TIME)
	assert_eq((warnings[0] as GroundWarning).position, Vector2(60, 0))
	await wait_seconds(EliteTrait.BLAST_TIME + 0.2)
	assert_signal_emitted(lucian, "damage_received")
	var info: DamageInfo = get_signal_parameters(lucian, "damage_received", 0)[0]
	assert_eq(info.amount, damage * 2.0)
	assert_eq(info.type, DamageInfo.Type.MAGIC)
	assert_eq(info.attacker_id, &"siege_minion")


func test_volatile_blast_misses_lucian_outside_it() -> void:
	var volatile := _elite(EliteTrait.VOLATILE, Vector2(EliteTrait.BLAST_RADIUS + 100.0, 0))
	watch_signals(lucian)
	_kill(volatile)
	await wait_seconds(EliteTrait.BLAST_TIME + 0.3)
	assert_signal_not_emitted(lucian, "damage_received")


func test_the_other_traits_leave_no_blast() -> void:
	var swift := _elite(EliteTrait.SWIFT)
	_kill(swift)
	await wait_physics_frames(2)
	assert_eq(get_children().filter(func(node: Node) -> bool: return node is GroundWarning).size(), 0)


func test_an_elite_with_a_trait_pays_a_quarter_more_gold_and_xp_but_not_essence() -> void:
	var data := _data("siege_minion")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var plain := KillRewards.roll(data, 3, StageSetup.new(), rng)
	rng.seed = 7
	var traited := KillRewards.roll(data, 3, StageSetup.new(), rng, false, 1.0, false, true)
	assert_eq(traited.gold, roundi(plain.gold * 1.25))
	assert_eq(traited.xp, roundi(plain.xp * 1.25))
	assert_eq(traited.blue, plain.blue)
	assert_eq(traited.orange, plain.orange)


func test_the_icon_is_first_over_the_health_bar() -> void:
	var vampire := _elite(EliteTrait.VAMPIRIC)
	vampire.add_status(Enemy.GRIEVOUS_WOUNDS, 5.0, 1, Enemy.SLOW_ICON)
	var shown := vampire.health_bar.shown()
	assert_eq(shown.size(), 2)
	assert_eq(shown[0].icon, EliteTrait.icon(EliteTrait.VAMPIRIC))
	assert_eq(shown[1].icon, Enemy.SLOW_ICON)
	assert_eq(_elite(&"").health_bar.shown().size(), 0, "no trait, no icon")


func test_a_ring_under_the_elite_in_its_colour() -> void:
	Juice.renders = true
	var swift := _elite(EliteTrait.SWIFT)
	Juice.renders = false
	var rings := swift.get_children().filter(func(node: Node) -> bool: return node is EliteRing)
	assert_eq(rings.size(), 1)
	assert_eq((rings[0] as EliteRing).color, EliteTrait.color(EliteTrait.SWIFT))
	assert_lte((rings[0] as EliteRing).z_index, UnitShadow.Z)


func test_the_stage_gives_an_act_3_elite_a_trait_and_a_tip_once_per_trait() -> void:
	var stage := await _story(3, 1)
	var seen := {}
	for i in 14:
		var unit := stage.spawn_enemy(&"blue_sentinel", Vector2(3000, 3000 + i * 10))
		assert_true(unit.elite_trait in EliteTrait.IDS)
		assert_eq(unit.health_bar.shown()[0].icon, EliteTrait.icon(unit.elite_trait))
		seen[unit.elite_trait] = true
	assert_gt(seen.size(), 1, "the stage's rng varies")
	var tips: Array = stage.hud.tips._queue
	var trait_tips := tips.filter(func(text: String) -> bool: return text in EliteTrait.IDS.map(EliteTrait.tip))
	assert_eq(trait_tips.size(), seen.size(), "one tip per trait seen")
	for id: StringName in seen:
		assert_true(EliteTrait.tip(id) in tips)


func test_the_stage_gives_no_trait_to_normals_summons_escapers_or_act_2() -> void:
	var stage := await _story(3, 1)
	assert_eq(stage.spawn_enemy(&"raptor", Vector2(3000, 3000)).elite_trait, &"")
	assert_eq(stage.spawn_enemy(&"blue_sentinel", Vector2(3000, 3100), 1, true).elite_trait, &"", "a summon")
	assert_eq(stage.spawn_enemy(&"rift_scuttler", Vector2(3000, 3200)).elite_trait, &"", "an escaper")
	var early := await _story(2, 1)
	assert_eq(early.spawn_enemy(&"siege_minion", Vector2(3000, 3000)).elite_trait, &"")


func test_the_stage_seam_spawns_without_traits() -> void:
	var stage := await _story(3, 1)
	stage.elite_traits = false
	assert_eq(stage.spawn_enemy(&"blue_sentinel", Vector2(3000, 3000)).elite_trait, &"")


func test_an_elite_with_a_trait_pays_more_in_the_stage() -> void:
	var stage := await _story(3, 1)
	var unit := stage.spawn_enemy(&"blue_sentinel", Vector2(3000, 3000))
	assert_ne(unit.elite_trait, &"")
	var before: int = stage.stats.gold_earned
	_kill(unit)
	var plain := KillRewards.roll(unit.data, 3, stage.run, RandomNumberGenerator.new())
	assert_eq(stage.stats.gold_earned - before, roundi(plain.gold * 1.25))


func test_endless_gives_a_trait_from_wave_11() -> void:
	SaveGame.instance().reset()
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_endless(SaveGame.instance(), 3, RandomNumberGenerator.new()))
	add_child_autofree(stage)
	await wait_process_frames(2)
	stage.lucian.invulnerable = true
	stage.runner._countdown = 999.0
	assert_eq(stage.spawn_enemy(&"siege_minion", Vector2(3000, 3000), 10).elite_trait, &"")
	assert_true(stage.spawn_enemy(&"siege_minion", Vector2(3000, 3100), 11).elite_trait in EliteTrait.IDS)


## The Black Mist hides who an elite is: its trait's ring goes with its bar.
func test_the_trait_ring_hides_under_the_veil() -> void:
	var renders := Juice.renders
	Juice.renders = true
	var elite := _elite(EliteTrait.VOLATILE, Vector2(300, 0))
	var rings := elite.get_children().filter(func(node: Node) -> bool: return node is EliteRing)
	assert_eq(rings.size(), 1)
	elite.veiled = true
	assert_false(elite.health_bar.visible, "the bar hides")
	assert_false((rings[0] as EliteRing).visible, "the ring hides with it")
	elite.veiled = false
	assert_true((rings[0] as EliteRing).visible, "and comes back when Lucian is close")
	Juice.renders = renders

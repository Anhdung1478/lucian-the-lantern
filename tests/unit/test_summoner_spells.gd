extends GutTest
## Summoner spells on D and F.

var lucian: Lucian
var dummy: TrainingDummy
var sources: Array[StringName] = []
var finals: Array[float] = []


func before_each() -> void:
	sources.clear()
	finals.clear()
	dummy = load("res://src/enemies/training_dummy.tscn").instantiate()
	dummy.position = Vector2(0, -2000)
	add_child_autofree(dummy)
	dummy.damage_taken.connect(func(info: DamageInfo, final_amount: float) -> void:
		sources.append(info.source)
		finals.append(final_amount))
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	add_child_autofree(lucian)
	await wait_physics_frames(2)


func test_spell_data_is_complete() -> void:
	var ids := []
	for spell in SummonerSpells.SPELLS:
		assert_ne(spell.display_name, "", str(spell.id))
		assert_not_null(spell.icon, str(spell.id))
		assert_between(spell.cooldown, 30.0, 90.0, str(spell.id))
		assert_ne(spell.description, "", str(spell.id))
		ids.append(spell.id)
	assert_eq(ids, [&"flash", &"ghost", &"barrier", &"heal", &"clarity", &"smite"])


func test_defaults_and_swapping() -> void:
	assert_eq(lucian.summoners.slots, [&"flash", &"heal"])
	lucian.summoners.set_spell(1, &"flash")
	assert_eq(lucian.summoners.slots, [&"heal", &"flash"])


func test_flash_blinks_400_toward_the_cursor_and_keeps_its_cooldown_on_the_other_key() -> void:
	assert_true(lucian.use_summoner(0, Vector2(1000, 0)))
	assert_almost_eq(lucian.global_position, Vector2(400, 0), Vector2(0.5, 0.5))
	assert_false(lucian.use_summoner(0, Vector2(1000, 0)), "on cooldown")
	lucian.summoners.set_spell(1, &"flash")
	assert_false(lucian.use_summoner(1, Vector2(1000, 0)), "the cooldown moved with it")


func test_flash_stops_short_of_an_enemy_body() -> void:
	dummy.position = Vector2(350, 0)
	await wait_physics_frames(2)
	lucian.use_summoner(0, Vector2(400, 0))
	assert_lt(lucian.global_position.x, 350.0)
	assert_true(lucian.fits_at(lucian.global_position))


func test_ghost_speeds_up_and_passes_through_enemies() -> void:
	lucian.summoners.set_spell(0, &"ghost")
	var speed := lucian.current_move_speed()
	assert_true(lucian.use_summoner(0, Vector2.ZERO))
	assert_almost_eq(lucian.current_move_speed(), speed * 1.4, 0.01)
	assert_eq(lucian.collision_mask, Layers.WORLD)
	lucian.set_ghosted(0.1)
	await wait_seconds(0.2)
	assert_eq(lucian.collision_mask, Layers.WORLD | Layers.ENEMY_BODY)


func test_barrier_heal_and_clarity() -> void:
	lucian.summoners.slots = [&"barrier", &"heal"]
	assert_true(lucian.use_summoner(0, Vector2.ZERO))
	assert_almost_eq(lucian.total_shield(), 95.0 + 18.0, 0.01)
	lucian.hp = 100.0
	assert_true(lucian.use_summoner(1, Vector2.ZERO))
	assert_almost_eq(lucian.hp, 195.0, 0.01)
	lucian.summoners.slots = [&"clarity", &"heal"]
	lucian.mana = 0.0
	assert_true(lucian.use_summoner(0, Vector2.ZERO))
	assert_almost_eq(lucian.mana, lucian.stats.max_mana * 0.5, 0.01)


func test_barrier_runs_out() -> void:
	lucian.add_barrier(50.0, 0.1)
	await wait_seconds(0.2)
	assert_eq(lucian.total_shield(), 0.0)


func test_smite_deals_true_damage_and_heals() -> void:
	dummy.position = Vector2(400, 0)
	lucian.summoners.set_spell(0, &"smite")
	lucian.hp = 100.0
	assert_true(lucian.use_summoner(0, dummy.position))
	assert_eq(sources, [&"smite"])
	assert_almost_eq(finals[0], 450.0, 0.01)
	assert_almost_eq(lucian.hp, 100.0 + lucian.stats.max_hp * 0.1, 0.01)


func test_smite_needs_an_enemy_in_reach() -> void:
	lucian.summoners.set_spell(0, &"smite")
	assert_false(lucian.use_summoner(0, dummy.position))
	assert_true(lucian.summoners.cooldown(&"smite").is_ready())


func test_no_cooldowns_refreshes_summoners() -> void:
	lucian.use_summoner(0, Vector2(100, 0))
	lucian.cheat_no_cooldowns = true
	assert_true(lucian.summoners.cooldown(&"flash").is_ready())

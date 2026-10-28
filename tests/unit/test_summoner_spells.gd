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
	# Trails and bolts go here, so they are freed with the test.
	var effects := Node2D.new()
	add_child_autofree(effects)
	lucian.projectile_parent = effects
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


func test_flash_leaves_sparks_where_lucian_stood_and_no_trail() -> void:
	assert_true(lucian.use_summoner(0, Vector2(1000, 0)))
	var effects := lucian.projectile_parent.get_children()
	assert_eq(effects.size(), 1)
	assert_true(effects[0] is BlinkSparks, "sparks, not a dash trail")
	assert_eq((effects[0] as Node2D).position, Vector2.ZERO, "where Lucian stood")


func test_flash_stops_short_of_an_enemy_body() -> void:
	dummy.position = Vector2(350, 0)
	await wait_physics_frames(2)
	lucian.use_summoner(0, Vector2(400, 0))
	# Bodies touch at 64 (34 + 30); Flash steps back 10 at a time from 400.
	assert_almost_eq(lucian.global_position.x, 280.0, 0.5)
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


func test_heal_and_clarity_show_their_effect_on_lucian() -> void:
	lucian.summoners.slots = [&"heal", &"clarity"]
	assert_true(lucian.use_summoner(0, Vector2.ZERO))
	assert_eq(lucian.get_children().filter(func(node: Node) -> bool: return node is HealBurst).size(), 1)
	assert_true(lucian.use_summoner(1, Vector2.ZERO))
	assert_eq(lucian.get_children().filter(func(node: Node) -> bool: return node is ClarityBurst).size(), 1)
	await wait_seconds(1.0)
	assert_eq(lucian.get_children().filter(func(node: Node) -> bool: return node is HealBurst or node is ClarityBurst).size(), 0, "gone after 0.9 s")


func ghost_images() -> Array:
	return lucian.get_parent().get_children().filter(func(node: Node) -> bool: return node is GhostImage)


func test_ghost_leaves_afterimages_behind_lucian_while_he_moves() -> void:
	lucian.summoners.set_spell(0, &"ghost")
	assert_true(lucian.use_summoner(0, Vector2.ZERO))
	await wait_physics_frames(5)
	assert_eq(ghost_images().size(), 0, "none while standing")
	lucian.command_move(Vector2(1000, 0))
	await wait_seconds(0.3)
	assert_gt(ghost_images().size(), 2)
	for image: GhostImage in ghost_images():
		assert_lt(image.position.x, lucian.global_position.x, "behind him")
		assert_lt(image.get_index(), lucian.get_index(), "drawn under him")
	lucian.set_ghosted(0.0)
	# The last ones fade within 0.35 s, and no new ones come.
	await wait_seconds(0.5)
	assert_eq(ghost_images().size(), 0)


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


func test_no_summoner_while_dashing() -> void:
	lucian.start_dash(Vector2.RIGHT, 200.0, 1000.0)
	assert_false(lucian.use_summoner(0, Vector2(1000, 0)))
	assert_true(lucian.summoners.cooldown(&"flash").is_ready())


func test_barrier_shows_a_buff_and_grows_with_heal_and_shield_power() -> void:
	lucian.stats.heal_shield_power = 0.25
	lucian.add_barrier(100.0, 2.0)
	assert_almost_eq(lucian.total_shield(), 125.0, 0.01)
	var barrier: Array = lucian.buffs().filter(func(buff: Dictionary) -> bool: return buff.id == &"barrier")
	assert_eq(barrier.size(), 1)
	var card := TooltipCard.buff(barrier[0])
	assert_not_null(card)
	card.free()

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
	assert_eq(lucian.collision_mask, Layers.WORLD | Layers.CHASM)
	lucian.set_ghosted(0.1)
	await wait_seconds(0.2)
	assert_eq(lucian.collision_mask, Layers.WORLD | Layers.ENEMY_BODY | Layers.CHASM)


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


func test_barrier_shows_a_bubble_until_the_shield_is_gone() -> void:
	lucian.summoners.set_spell(0, &"barrier")
	assert_true(lucian.use_summoner(0, Vector2.ZERO))
	var bubbles := func() -> Array: return lucian.get_children().filter(func(node: Node) -> bool: return node is BarrierBubble)
	assert_eq(bubbles.call().size(), 1)
	await wait_seconds(1.0)
	assert_eq(bubbles.call().size(), 1, "still shielded")
	# Shorten the shield; the bubble fades for 0.25 s once it is gone.
	lucian.add_barrier(50.0, 0.1)
	await wait_seconds(0.5)
	assert_eq(bubbles.call().size(), 0)


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
	assert_false(lucian.use_summoner(0, Vector2(300, 300)), "no enemy under the cursor either")
	assert_true(lucian.summoners.cooldown(&"smite").is_ready())
	await wait_seconds(0.2)
	assert_eq(lucian.global_position, Vector2.ZERO, "no walking")


func test_smite_on_an_enemy_out_of_reach_walks_over_then_casts() -> void:
	dummy.position = Vector2(900, 0)
	await wait_physics_frames(2)
	lucian.summoners.set_spell(0, &"smite")
	assert_false(lucian.use_summoner(0, dummy.position), "not yet")
	assert_true(lucian.summoners.cooldown(&"smite").is_ready())
	# 900 - 500 - 34 (the dummy's radius) = 366 to walk at 345.
	await wait_seconds(1.5)
	assert_eq(sources, [&"smite"])
	assert_almost_eq(lucian.global_position.x, 900.0 - SummonerSpells.SMITE_RANGE - dummy.radius, 10.0, "walked only until in reach")


## A Blast Cone is clickable (enemy_at) but no Smite target: no walk to it.
func test_smite_aimed_at_a_blast_cone_out_of_reach_does_not_walk() -> void:
	var cone := BlastCone.new()
	cone.lucian = lucian
	cone.position = Vector2(900, 0)
	add_child_autofree(cone)
	await wait_physics_frames(2)
	lucian.summoners.set_spell(0, &"smite")
	assert_false(lucian.use_summoner(0, cone.position))
	assert_eq(lucian._order, Lucian.Order.NONE, "no walk order")
	await wait_seconds(0.3)
	assert_eq(lucian.global_position, Vector2.ZERO, "no walking")
	assert_true(lucian.summoners.cooldown(&"smite").is_ready())


func test_a_new_order_drops_the_walk_to_smite() -> void:
	dummy.position = Vector2(900, 0)
	await wait_physics_frames(2)
	lucian.summoners.set_spell(0, &"smite")
	lucian.use_summoner(0, dummy.position)
	lucian.command_move(Vector2(-200, 0))
	await wait_seconds(1.5)
	assert_eq(sources, [])
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


func test_a_locked_f_key_has_no_spell_and_cannot_cast() -> void:
	var setup := StageSetup.new()
	setup.summoner_slots = 1
	lucian.apply_setup(setup)
	assert_null(lucian.summoners.spell_in(1))
	assert_false(lucian.use_summoner(1, Vector2.ZERO))


func test_an_empty_slot_has_no_spell() -> void:
	lucian.summoners.slots = [&"flash", &""]
	assert_null(lucian.summoners.spell_in(1))
	assert_false(lucian.use_summoner(1, Vector2.ZERO))


func test_flash_upgrade_shortens_its_cooldown() -> void:
	var setup := StageSetup.new()
	setup.summoner_upgrades = {&"flash": -0.2}
	lucian.apply_setup(setup)
	assert_true(lucian.use_summoner(0, Vector2(1000, 0)))
	assert_almost_eq(lucian.summoners.cooldown(&"flash").remaining, 72.0, 0.001)


func test_the_card_shows_the_upgraded_cooldown() -> void:
	var setup := StageSetup.new()
	setup.summoner_upgrades = {&"flash": -0.2}
	lucian.apply_setup(setup)
	var slot := SummonerSlot.new(lucian, 0)
	var card := slot.tooltip_content()
	var text := ""
	for label: RichTextLabel in card.find_children("*", "RichTextLabel", true, false):
		text += TooltipText.plain(label.text) + "\n"
	assert_string_contains(text, "Cooldown: 72 s")
	assert_string_contains(text, "Upgraded: 20% shorter cooldown")
	card.free()
	slot.free()


func test_heal_upgrade_strengthens_the_heal() -> void:
	var setup := StageSetup.new()
	setup.summoner_upgrades = {&"heal": 0.3}
	lucian.apply_setup(setup)
	lucian.hp = 1.0
	lucian.stats.heal_shield_power = 0.0
	assert_true(lucian.use_summoner(1, Vector2.ZERO))
	var expected := (80.0 + 15.0 * lucian.progress.level) * 1.3
	assert_almost_eq(lucian.hp, 1.0 + expected, 0.01)


func test_upgrade_text() -> void:
	var spells := lucian.summoners
	spells.upgrades = {&"flash": -0.2, &"heal": 0.3}
	assert_eq(spells.upgrade_text(&"flash"), "Upgraded: 20% shorter cooldown")
	assert_eq(spells.upgrade_text(&"heal"), "Upgraded: 30% stronger")
	assert_eq(spells.upgrade_text(&"smite"), "")

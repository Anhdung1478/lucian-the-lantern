extends GutTest
## Root, stun and fear on Lucian (add_cc): what each one stops, tenacity,
## what refuses it, the debuffs and the word under his health bar.

const Slot := ChampionProgress.Slot
const Kind := CrowdControl.Kind

var lucian: Lucian
var effects: Node2D


func before_each() -> void:
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	# Shots and trails go here, so they are freed with the test.
	effects = Node2D.new()
	add_child_autofree(effects)
	lucian.projectile_parent = effects
	add_child_autofree(lucian)
	lucian.global_position = Vector2.ZERO
	lucian.progress.set_level(6)
	for slot in [Slot.Q, Slot.W, Slot.E, Slot.R]:
		lucian.try_rank_up(slot)
	lucian.cheat_infinite_mana = true


## A plain enemy at `at`.
func _enemy(at: Vector2, hp := 100.0) -> Enemy:
	var enemy := Enemy.new()
	enemy.radius = 20.0
	enemy.max_hp = hp
	enemy.position = at
	add_child_autofree(enemy)
	return enemy


## A wall 40 wide and 400 tall centered on `at`.
func _wall(at: Vector2) -> void:
	var wall := StaticBody2D.new()
	wall.collision_layer = Layers.WORLD
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(40, 400)
	shape.shape = box
	shape.position = at
	wall.add_child(shape)
	add_child_autofree(wall)


func _buff_ids() -> Array:
	return lucian.buffs().map(func(buff: Dictionary) -> StringName: return buff.id)


## The buff row entry `id`, or {} when it isn't shown.
func _buff(id: StringName) -> Dictionary:
	for buff in lucian.buffs():
		if buff.id == id:
			return buff
	return {}


# --- Tenacity ---------------------------------------------------------------


func test_tenacity_shortens_cc_on_lucian() -> void:
	lucian.tree_bonus = {&"tenacity": 0.3}
	lucian.refresh_stats()
	lucian.add_cc(Kind.STUN, 1.0)
	assert_almost_eq(_buff(Lucian.STUNNED).left, 0.7, 0.001)
	lucian.add_cc(Kind.STUN, 0.5)
	assert_almost_eq(_buff(Lucian.STUNNED).left, 0.7, 0.001, "the longer time wins")


# --- Root -------------------------------------------------------------------


func test_a_root_keeps_the_move_order_but_he_does_not_step() -> void:
	lucian.add_cc(Kind.ROOT, 0.3)
	assert_true(lucian.has_cc(Kind.ROOT))
	assert_false(lucian.can_move())
	assert_true(lucian.can_act(), "a root is not a stun")
	lucian.command_move(Vector2(400, 0))
	await wait_physics_frames(10)
	assert_eq(lucian.global_position, Vector2.ZERO)
	assert_eq(lucian._order, Lucian.Order.MOVE, "the order waits")
	await wait_physics_frames(20)
	assert_false(lucian.has_cc(Kind.ROOT))
	assert_true(lucian.can_move())
	assert_gt(lucian.global_position.x, 20.0, "walks on once it ends")


func test_a_root_refuses_e_and_flash_but_not_other_skills() -> void:
	lucian.add_cc(Kind.ROOT, 1.0)
	assert_false(lucian.try_cast(Slot.E, Vector2(400, 0)))
	assert_false(lucian.is_dashing())
	assert_true(lucian.skills[Slot.E].cooldown.is_ready(), "nothing spent")
	assert_true(lucian.is_skill_blocked(Slot.E), "greyed on the HUD")
	assert_eq(lucian.summoners.slots[0], &"flash")
	assert_false(lucian.use_summoner(0, Vector2(300, 0)))
	assert_eq(lucian.global_position, Vector2.ZERO)
	assert_true(lucian.summoners.cooldown(&"flash").is_ready())
	assert_true(lucian.try_cast(Slot.W, Vector2(600, 0)), "W still works")


func test_e_pressed_while_rooted_is_not_queued() -> void:
	lucian.add_cc(Kind.ROOT, 1.0)
	lucian.lock_cast(0.1)
	assert_false(lucian.try_cast(Slot.E, Vector2(400, 0)))
	assert_eq(lucian.queued_cast(), -1)


func test_an_e_queued_before_a_root_is_dropped_if_the_root_still_holds() -> void:
	lucian.lock_cast(0.1)
	assert_false(lucian.try_cast(Slot.E, Vector2(400, 0)))
	assert_eq(lucian.queued_cast(), Slot.E)
	lucian.add_cc(Kind.ROOT, 0.4)
	await wait_physics_frames(12)
	assert_eq(lucian.queued_cast(), -1)
	assert_false(lucian.is_dashing())
	await wait_physics_frames(24)
	assert_false(lucian.has_cc(Kind.ROOT))
	assert_true(lucian.skills[Slot.E].cooldown.is_ready(), "never cast, not even once the root ends")
	assert_eq(lucian.global_position, Vector2.ZERO)


func test_a_rooted_lucian_shoots_a_target_in_range_and_waits_for_one_out_of_range() -> void:
	var spawned := [0]
	effects.child_entered_tree.connect(func(node: Node) -> void:
		if node is AttackProjectile:
			spawned[0] += 1)
	var far := _enemy(Vector2(lucian.attack_range() + 300.0, 0))
	lucian.add_cc(Kind.ROOT, 2.0)
	lucian.command_attack(far)
	await wait_physics_frames(20)
	assert_eq(lucian.global_position, Vector2.ZERO, "no walking into range")
	assert_eq(lucian._order, Lucian.Order.ATTACK, "the order waits")
	var near := _enemy(Vector2(lucian.attack_range() * 0.5, 0), 5000.0)
	lucian.command_attack(near)
	await wait_physics_frames(30)
	assert_gt(spawned[0], 0, "the attack fired")
	assert_eq(lucian.global_position, Vector2.ZERO)


# --- Stun -------------------------------------------------------------------


func test_a_stun_drops_r_and_the_queued_cast() -> void:
	assert_true(lucian.try_cast(Slot.R, Vector2(600, 0)))
	var culling := lucian.skills[Slot.R] as TheCulling
	assert_true(culling.is_channeling())
	lucian.lock_cast(0.3)
	assert_false(lucian.try_cast(Slot.E, Vector2(0, 400)))
	assert_eq(lucian.queued_cast(), Slot.E, "E waits for the cast time")
	lucian.add_cc(Kind.STUN, 0.2)
	assert_false(culling.is_channeling(), "R stops")
	assert_eq(lucian.queued_cast(), -1, "the queued E is gone")
	assert_false(lucian.is_cast_locked())
	assert_false(lucian.can_act())
	assert_false(lucian.try_cast(Slot.W, Vector2(600, 0)), "no casting while stunned")
	assert_eq(lucian.queued_cast(), -1)
	await wait_physics_frames(30)
	assert_true(lucian.skills[Slot.E].cooldown.is_ready(), "E never fired")
	assert_eq(lucian.global_position, Vector2.ZERO)
	assert_true(lucian.can_act(), "free once it ends")


func test_a_stun_ends_a_dash_where_he_is() -> void:
	assert_true(lucian.try_cast(Slot.E, Vector2(1000, 0)))
	await wait_physics_frames(2)
	assert_true(lucian.is_dashing())
	lucian.add_cc(Kind.STUN, 0.3)
	assert_false(lucian.is_dashing())
	assert_eq(lucian.collision_mask, Layers.WORLD | Layers.ENEMY_BODY, "his walking mask is back")
	var stopped := lucian.global_position
	await wait_physics_frames(10)
	assert_eq(lucian.global_position, stopped)


func test_a_stun_drops_the_windup_and_the_attack_order() -> void:
	var near := _enemy(Vector2(lucian.attack_range() * 0.5, 0), 5000.0)
	lucian.command_attack(near)
	await wait_physics_frames(2)
	assert_gt(lucian._windup_left, 0.0, "winding up")
	lucian.add_cc(Kind.STUN, 0.3)
	assert_eq(lucian._windup_left, 0.0)
	assert_eq(lucian._order, Lucian.Order.NONE)
	await wait_physics_frames(30)
	assert_eq(near.hp, near.max_hp, "no shot")


func test_a_stun_during_a_pull_lets_the_pull_finish_then_holds_him() -> void:
	lucian.displace(Vector2(300, 0), 3000.0)
	lucian.add_cc(Kind.STUN, 0.5)
	assert_true(lucian.is_displaced(), "the pull goes on")
	await wait_physics_frames(12)
	assert_almost_eq(lucian.global_position, Vector2(300, 0), Vector2(1, 1))
	assert_true(lucian.has_cc(Kind.STUN))
	assert_false(lucian.can_act())


# --- Fear -------------------------------------------------------------------


func test_fear_walks_him_straight_away_from_the_source() -> void:
	assert_eq(Lucian.FEAR_SPEED, 0.6)
	lucian.command_move(Vector2(0, 400))
	lucian.add_cc(Kind.FEAR, 0.5, Vector2(-100, 0))
	assert_false(lucian.can_act())
	assert_eq(lucian._order, Lucian.Order.NONE, "the move is dropped")
	await wait_physics_frames(15)
	var expected := lucian.current_move_speed() * Lucian.FEAR_SPEED * 15.0 / 60.0
	assert_almost_eq(lucian.global_position.x, expected, 4.0, "at 60% of his speed")
	assert_almost_eq(lucian.global_position.y, 0.0, 0.5, "straight away")
	await wait_physics_frames(30)
	assert_false(lucian.has_cc(Kind.FEAR))
	var stopped := lucian.global_position
	await wait_physics_frames(5)
	assert_eq(lucian.global_position, stopped, "stands once it ends")


func test_fear_builds_no_energize() -> void:
	lucian.inventory.put(Inventory.EQUIP_START, lucian.item_catalog.find(&"statikk_shiv"))
	lucian.add_cc(Kind.FEAR, 0.5, Vector2(-100, 0))
	await wait_physics_frames(30)
	assert_gt(lucian.global_position.x, 50.0, "he ran")
	assert_eq(lucian.passives.energize.value, 0.0, "forced, like a displacement")


func test_fear_slides_along_a_wall() -> void:
	# The wall's near side is at x = 60; Lucian's body is 30 wide.
	_wall(Vector2(80, 0))
	await wait_physics_frames(1)
	lucian.add_cc(Kind.FEAR, 0.5, Vector2(-100, 100))
	await wait_physics_frames(30)
	assert_lt(lucian.global_position.x, 31.0, "the wall stops him")
	assert_lt(lucian.global_position.y, -40.0, "he slides along it")


# --- Refused and cleared ----------------------------------------------------


func test_cc_is_refused_in_stasis_while_invulnerable_and_in_flight() -> void:
	lucian.enter_stasis(0.2, 100.0, 0.0)
	lucian.add_cc(Kind.STUN, 1.0)
	assert_false(lucian.has_cc(Kind.STUN), "in stasis")
	await wait_physics_frames(20)
	assert_false(lucian.in_stasis())
	lucian.invulnerable = true
	lucian.add_cc(Kind.ROOT, 1.0)
	assert_false(lucian.has_cc(Kind.ROOT), "invulnerable")
	lucian.invulnerable = false
	lucian.launch(Vector2(300, 0), 0.3)
	lucian.add_cc(Kind.FEAR, 1.0, Vector2(-100, 0))
	assert_false(lucian.has_cc(Kind.FEAR), "thrown")
	assert_true(lucian.is_launched(), "the throw goes on")


func test_death_clears_it_and_a_dead_lucian_takes_none() -> void:
	lucian.add_cc(Kind.ROOT, 2.0)
	lucian.add_cc(Kind.STUN, 2.0)
	lucian.add_cc(Kind.FEAR, 2.0, Vector2(-100, 0))
	lucian.take_damage(DamageInfo.create(99999.0, DamageInfo.Type.TRUE, &"test"))
	assert_true(lucian.dead)
	for kind in [Kind.ROOT, Kind.STUN, Kind.FEAR]:
		assert_false(lucian.has_cc(kind))
	assert_false(_buff_ids().has(Lucian.STUNNED))
	lucian.add_cc(Kind.STUN, 1.0)
	assert_false(lucian.has_cc(Kind.STUN), "no new stun on a dead Lucian")


# --- On screen --------------------------------------------------------------


func test_the_debuffs_show_in_the_buff_row_next_to_slowed() -> void:
	lucian.add_slow(&"water", 0.3, 1.0)
	lucian.add_cc(Kind.ROOT, 1.0)
	lucian.add_cc(Kind.STUN, 0.4)
	lucian.add_cc(Kind.FEAR, 0.8, Vector2(-100, 0))
	var ids := _buff_ids()
	for id in [Lucian.SLOWED, Lucian.STUNNED, Lucian.FEARED, Lucian.ROOTED]:
		assert_true(ids.has(id), "shows %s" % id)
	var rooted := _buff(Lucian.ROOTED)
	assert_eq(rooted.name, "Rooted")
	assert_eq(rooted.icon, Lucian.ROOT_ICON)
	assert_ne(rooted.text, "")
	assert_almost_eq(rooted.left, 1.0, 0.001)
	assert_almost_eq(rooted.duration, 1.0, 0.001)
	assert_true(rooted.has_all(["count", "ready"]), "everything a buff icon reads")
	assert_eq(_buff(Lucian.STUNNED).name, "Stunned")
	assert_eq(_buff(Lucian.STUNNED).icon, Lucian.STUN_ICON)
	assert_eq(_buff(Lucian.FEARED).name, "Feared")
	assert_eq(_buff(Lucian.FEARED).icon, Lucian.FEAR_ICON)
	await wait_physics_frames(30)
	assert_false(_buff_ids().has(Lucian.STUNNED), "gone once it ends")
	assert_true(_buff_ids().has(Lucian.ROOTED))


func test_the_word_under_his_health_bar_is_the_strongest() -> void:
	var bar: LucianHealthBar = lucian.get_node("HealthBar")
	assert_eq(bar._cc_word(), "")
	lucian.add_cc(Kind.ROOT, 1.0)
	assert_eq(bar._cc_word(), "Rooted")
	lucian.add_cc(Kind.FEAR, 1.0, Vector2(-100, 0))
	assert_eq(bar._cc_word(), "Feared")
	lucian.add_cc(Kind.STUN, 1.0)
	assert_eq(bar._cc_word(), "Stunned")

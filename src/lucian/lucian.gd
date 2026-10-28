class_name Lucian
extends CharacterBody2D
## The player champion. Holds one standing order (move / attack / attack-move
## / visit the merchant) and carries it out every physics frame. Attack
## windups pause the order. Item passives and actives live in the
## ItemPassives and ItemActives children, summoner spells in SummonerSpells.

## Lucian walked into range of the merchant he was sent to.
signal merchant_reached(merchant: Merchant)

enum Order { NONE, MOVE, ATTACK, ATTACK_MOVE, VISIT }

## Share of the attack period spent winding up before the shot leaves the gun.
const WINDUP_RATIO := 0.15
const RANGE_RING_COLOR := Color(1.0, 0.91, 0.66, 0.35)
## Rapid Firecannon's Energized reach.
const RFC_RING_COLOR := Color(0.62, 0.85, 1.0, 0.45)
## Distance from Lucian's center to his gun muzzles.
const GUN_REACH := 44.0
## How far above Lucian's center his HP bar sits.
const HEALTH_BAR_HEIGHT := 62.0
const MOVE_SPEED_ICON := preload("res://assets/art/ui/buff_move_speed.svg")
const SHIELD_ICON := preload("res://assets/art/ui/buff_shield.svg")
const SPEED_BUFF_NAMES := {
	&"ardent_blaze": "Ardent Blaze", &"fervor": "Fervor", &"stormrazor": "Bolt",
	&"ghost": "Ghost", &"heal": "Heal",
}
## Bloodthirster's Ichorshield: the most it holds, and how fast it fades out
## of combat (per second).
const ICHORSHIELD_MAX := 300.0
const ICHORSHIELD_DECAY := 100.0

@export var base_stats: UnitStats
@export var item_catalog: ItemCatalog

var progress := ChampionProgress.new()
var inventory := Inventory.new()
## Potions being drunk.
var restores := RestoreOverTime.new()
var passives := ItemPassives.new()
var actives := ItemActives.new()
var summoners := SummonerSpells.new()
## Item id -> Cooldown, shared by every copy of the item.
var item_cooldowns := {}
var stats: StatBlock
var hp := 0.0
var mana := 0.0
## Absorbs damage before HP (Bloodthirster).
var shield := 0.0
## Barrier's shield, on top of `shield`, until it runs out.
var barrier := 0.0
## Where spawned shots go. Set by the stage.
var projectile_parent: Node
## Debug: values >= 0 replace Lucian's crit chance.
var cheat_crit_chance := -1.0
## Turning it on also refreshes every skill, item and summoner cooldown
## already running.
var cheat_no_cooldowns := false:
	set(value):
		cheat_no_cooldowns = value
		if value:
			for skill in skills:
				skill.cooldown.clear()
			for cooldown: Cooldown in item_cooldowns.values():
				cooldown.clear()
			summoners.clear_cooldowns()
var cheat_infinite_mana := false
## Setting: a skill pressed during a cast time or a dash is cast as soon as it
## ends, aimed where the key was pressed, like LoL's spell buffering. Only the
## latest press is kept.
var queue_casts := true

var _order := Order.NONE
var _move_point := Vector2.ZERO
var _target: Enemy
var _visit: Merchant
var _attack_cooldown := 0.0
var _windup_left := 0.0
var _show_range_ring := false
var _rfc_ring_shown := false
var _cast_lock_left := 0.0
var _dash_velocity := Vector2.ZERO
var _dash_left := 0.0
## Grows behind Lucian during a dash; null with low effects.
var _dash_trail: DashTrail
## Id -> {flat, pct, left, duration, fade}. A fading buff's percent shrinks
## to 0 over its duration.
var _speed_buffs := {}
var _last_position := Vector2.ZERO
var _queued_slot := -1
var _queued_aim := Vector2.ZERO
## Ghost: seconds left passing through enemies.
var _ghost_left := 0.0
var _barrier_left := 0.0
var _barrier_duration := 0.0

@onready var visuals: LucianVisuals = $Visuals
@onready var skills: Array[LucianSkill] = [$Skills/Q, $Skills/W, $Skills/E, $Skills/R]
@onready var passive: Lightslinger = $Skills/Passive


func _ready() -> void:
	passives.name = "ItemPassives"
	passives.setup(self)
	add_child(passives)
	actives.name = "ItemActives"
	actives.setup(self)
	add_child(actives)
	summoners.name = "SummonerSpells"
	summoners.setup(self)
	add_child(summoners)
	var health_bar := LucianHealthBar.new()
	health_bar.name = "HealthBar"
	health_bar.position = Vector2(0, -HEALTH_BAR_HEIGHT)
	add_child(health_bar)
	stats = base_stats.at_level(progress.level)
	passives.adjust_stats(stats)
	hp = stats.max_hp
	mana = stats.max_mana
	_last_position = global_position
	if projectile_parent == null:
		projectile_parent = get_parent()
	inventory.catalog = item_catalog
	progress.level_changed.connect(func(_level: int) -> void: _refresh_stats(false))
	inventory.changed.connect(_on_inventory_changed)


func command_move(point: Vector2) -> void:
	_cancel_windup()
	_order = Order.MOVE
	_move_point = point


func command_attack(target: Enemy) -> void:
	if target != _target:
		_cancel_windup()
	_order = Order.ATTACK
	_target = target


func command_attack_move(point: Vector2) -> void:
	_cancel_windup()
	_order = Order.ATTACK_MOVE
	_move_point = point
	_target = null


## Walks to `merchant`; merchant_reached fires once he is in range (right
## away if he already is).
func command_visit(merchant: Merchant) -> void:
	_cancel_windup()
	if global_position.distance_to(merchant.global_position) <= Merchant.INTERACT_RANGE:
		_order = Order.NONE
		merchant_reached.emit(merchant)
		return
	_order = Order.VISIT
	_visit = merchant


func try_rank_up(slot: ChampionProgress.Slot) -> bool:
	return progress.rank_up(slot)


## The cast gate: rank, cooldown, mana and state, then pay and cast.
## During R only E can be cast, and pressing R again stops R. A cast blocked
## only by a cast time or a dash is queued when queue_casts is on.
func try_cast(slot: ChampionProgress.Slot, aim: Vector2) -> bool:
	var culling := skills[ChampionProgress.Slot.R] as TheCulling
	if culling.is_channeling():
		if slot == ChampionProgress.Slot.R:
			culling.stop()
			return true
		if slot != ChampionProgress.Slot.E:
			return false
	var skill := skills[slot]
	if skill.rank() == 0 or not skill.cooldown.is_ready() or mana < skill.mana_cost():
		return false
	if is_cast_locked() or is_dashing():
		if queue_casts:
			_queued_slot = slot
			_queued_aim = aim
		return false
	mana -= skill.mana_cost()
	skill.cooldown.start(0.0 if cheat_no_cooldowns else skill.cooldown_seconds(), stats.ability_haste + passives.skill_haste(slot))
	_cancel_windup()
	skill.execute(aim)
	passive.charge()
	passives.on_cast(slot)
	return true


## Skills another skill holds back, greyed on the HUD: Q and W while R
## fires, E during Q's cast time.
func is_skill_blocked(slot: ChampionProgress.Slot) -> bool:
	match slot:
		ChampionProgress.Slot.Q, ChampionProgress.Slot.W:
			return (skills[ChampionProgress.Slot.R] as TheCulling).is_channeling()
		ChampionProgress.Slot.E:
			return (skills[ChampionProgress.Slot.Q] as PiercingLight).is_casting()
	return false


## The slot waiting for the current cast time or dash to end, or -1.
func queued_cast() -> int:
	return _queued_slot


## Called by an enemy just before Lucian's hit is mitigated: item damage
## multipliers.
func before_damage(target: Enemy, info: DamageInfo) -> void:
	passives.before_damage(target, info)


## Called by an enemy after it takes damage from Lucian. Life steal works on
## basic attacks (and the passive's second shot); omnivamp on every hit. With
## Bloodthirster, life steal healing past full HP becomes a shield.
func on_damage_dealt(target: Enemy, info: DamageInfo, final_amount: float) -> void:
	if stats.omnivamp > 0.0:
		heal(final_amount * stats.omnivamp)
	if stats.lifesteal > 0.0 and (info.source == &"basic" or info.source == &"lightslinger"):
		var healing := final_amount * stats.lifesteal
		var overheal := healing * (1.0 + stats.heal_shield_power) - heal(healing)
		if passives.has(&"bloodthirster") and overheal > 0.0:
			shield = minf(shield + overheal, ICHORSHIELD_MAX)
	passives.on_damage_dealt(target, info, final_amount)
	if info.source == &"lightslinger":
		skills[ChampionProgress.Slot.E].cooldown.reduce(passive.e_cooldown_reduction)
	if info.source != &"w" and target.has_mark(ArdentBlaze.MARK):
		var blaze := skills[ChampionProgress.Slot.W] as ArdentBlaze
		add_move_speed_bonus(blaze.current_move_speed_bonus(), blaze.move_speed_duration)


## Heals, made stronger by heal and shield power. Returns the HP gained.
func heal(amount: float) -> float:
	var before := hp
	hp = minf(hp + amount * (1.0 + stats.heal_shield_power), stats.max_hp)
	return hp - before


func restore_mana(amount: float) -> void:
	mana = minf(mana + amount, stats.max_mana)


## Drinks the potion in inventory cell `index`. False when there is none.
func use_item(index: int) -> bool:
	var item := inventory.item_at(index)
	if item == null or not item.is_potion():
		return false
	inventory.take_one(index)
	restores.start(item)
	Sfx.play(&"potion")
	return true


## Keys 1-6: drinks the potion, or uses the item active, in equip slot `slot`
## (0-5).
func use_equip_slot(slot: int, aim: Vector2) -> bool:
	var index := Inventory.EQUIP_START + slot
	if inventory.is_locked(index):
		return false
	var item := inventory.item_at(index)
	if ItemActives.has_active(item):
		return actives.use(item, aim)
	return use_item(index)


## D and F: casts the summoner spell on `slot` (0-1) toward `aim`.
func use_summoner(slot: int, aim: Vector2) -> bool:
	return summoners.use(slot, aim)


## The cooldown every copy of item `id` shares.
func item_cooldown(id: StringName) -> Cooldown:
	if not item_cooldowns.has(id):
		item_cooldowns[id] = Cooldown.new()
	return item_cooldowns[id]


## Recomputes the stats, keeping the HP and mana share (stat passives call it).
func refresh_stats() -> void:
	_refresh_stats(true)


## AD from the level alone, and the rest (items and passives).
func base_ad() -> float:
	return base_stats.at_level(progress.level).ad


func bonus_ad() -> float:
	return maxf(stats.ad - base_ad(), 0.0)


## Attack range, longer for a Rapid Firecannon Energized attack.
func attack_range() -> float:
	return stats.attack_range * (1.0 + passives.attack_range_bonus())


## The main shot of a basic attack, with the item procs it carries.
func basic_attack(target: Enemy) -> DamageInfo:
	var info := roll_attack(1.0, &"basic")
	passives.on_basic_attack(target, info)
	return info


## The Ichorshield and Barrier together.
func total_shield() -> float:
	return shield + barrier


## Barrier: a shield of `amount` (made stronger by heal and shield power) for
## `seconds`, replacing an older one.
func add_barrier(amount: float, seconds: float) -> void:
	barrier = amount * (1.0 + stats.heal_shield_power)
	_barrier_left = seconds
	_barrier_duration = seconds


## Ghost: Lucian passes through enemies (walls still stop him) for `seconds`.
func set_ghosted(seconds: float) -> void:
	_ghost_left = seconds
	collision_mask = _body_mask()


func is_ghosted() -> bool:
	return _ghost_left > 0.0


## Lucian's body would fit at `point` without touching a wall (or an enemy,
## unless he is ghosted).
func fits_at(point: Vector2) -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = ($CollisionShape2D as CollisionShape2D).shape
	query.transform = Transform2D(0.0, point)
	query.collision_mask = _body_mask()
	query.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


## Moves Lucian straight to `point` (Flash). A blink doesn't build Energize.
func blink_to(point: Vector2) -> void:
	global_position = point
	_last_position = point


## The enemy nearest the cursor among those within `reach` of Lucian
## (Gunblade, Smite), or null.
func enemy_near_cursor(aim: Vector2, reach: float) -> Enemy:
	var best: Enemy = null
	var best_distance := INF
	for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
		if global_position.distance_to(enemy.global_position) > reach + enemy.radius:
			continue
		var distance := aim.distance_to(enemy.global_position)
		if distance < best_distance:
			best_distance = distance
			best = enemy
	return best


## HUD buff icons: potions, move speed, shields and item passives. Each is
## {id, name, icon, text, count, left, duration, ready}.
func buffs() -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	if item_catalog:
		for potion in item_catalog.potions():
			var drinks := restores.count(potion.id)
			if drinks > 0:
				found.append({"id": potion.id, "name": potion.display_name, "icon": potion.icon,
					"text": TooltipCard.potion_text(potion), "count": str(drinks) if drinks > 1 else "",
					"left": restores.time_left(potion.id), "duration": restores.duration(potion.id), "ready": false})
	for id: StringName in _speed_buffs:
		var buff: Dictionary = _speed_buffs[id]
		var text := "+%d move speed" % roundi(buff.flat) if buff.flat > 0.0 else "+%d%% move speed" % roundi(buff.pct * 100.0)
		if buff.fade:
			text += ", fading"
		found.append({"id": id, "name": SPEED_BUFF_NAMES.get(id, "Move speed"), "icon": MOVE_SPEED_ICON,
			"text": TooltipText.colorize("[ms]%s[/ms]." % text), "count": "", "left": buff.left,
			"duration": buff.duration, "ready": false})
	if shield > 0.0:
		found.append({"id": &"ichorshield", "name": "Ichorshield", "icon": SHIELD_ICON,
			"text": "A shield from Bloodthirster's life steal past full health. Absorbs %d damage." % roundi(shield),
			"count": str(roundi(shield)), "left": 0.0, "duration": 0.0, "ready": false})
	if barrier > 0.0:
		found.append({"id": &"barrier", "name": "Barrier", "icon": SummonerSpells.find(&"barrier").icon,
			"text": "A shield that absorbs %d damage." % roundi(barrier),
			"count": str(roundi(barrier)), "left": _barrier_left, "duration": _barrier_duration, "ready": false})
	found.append_array(passives.buffs())
	return found


## Every enemy whose hurtbox overlaps `shape` placed at `xform`, found instantly.
func query_enemies(shape: Shape2D, xform: Transform2D) -> Array[Enemy]:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = xform
	query.collision_mask = Layers.ENEMY_HURTBOX
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var found: Array[Enemy] = []
	for hit in get_world_2d().direct_space_state.intersect_shape(query, 64):
		var hurtbox := hit.collider as Hurtbox
		if hurtbox and hurtbox.unit is Enemy and not found.has(hurtbox.unit):
			found.append(hurtbox.unit)
	return found


## Lucian stands still for `seconds` (a cast time); the standing order resumes after.
func lock_cast(seconds: float) -> void:
	_cast_lock_left = seconds


func is_cast_locked() -> bool:
	return _cast_lock_left > 0.0


## Dashes through enemies (walls still stop him), leaving a trail in
## `trail_color`. A move order ends here, but attack orders carry on, and the
## attack timer resets.
func start_dash(direction: Vector2, distance: float, speed: float, trail_color := DashTrail.LIGHT) -> void:
	_cancel_windup()
	_dash_velocity = direction * speed
	_dash_left = distance / speed
	_start_dash_trail(trail_color)
	_attack_cooldown = 0.0
	collision_mask = Layers.WORLD
	if _order == Order.MOVE:
		_order = Order.NONE
	visuals.face(direction)


func is_dashing() -> bool:
	return _dash_left > 0.0


func set_range_ring_visible(value: bool) -> void:
	_show_range_ring = value
	queue_redraw()


## Base move speed plus every flat bonus, then times every percent bonus.
func current_move_speed() -> float:
	var flat := 0.0
	var pct := 0.0
	for buff: Dictionary in _speed_buffs.values():
		flat += buff.flat
		pct += buff.pct * (buff.left / buff.duration if buff.fade else 1.0)
	return (stats.move_speed + flat) * (1.0 + pct)


## A flat move speed bonus for `duration` seconds (W's); a new one replaces
## the old.
func add_move_speed_bonus(amount: float, duration: float) -> void:
	add_speed_buff(&"ardent_blaze", amount, 0.0, duration)


## A named move speed buff, flat and/or percent. The same id replaces the
## old one; different ids stack. `fade` shrinks the percent to 0 over time.
func add_speed_buff(id: StringName, flat: float, pct: float, duration: float, fade := false) -> void:
	_speed_buffs[id] = {"flat": flat, "pct": pct, "left": duration, "duration": maxf(duration, 0.01), "fade": fade}


func crit_chance() -> float:
	return cheat_crit_chance if cheat_crit_chance >= 0.0 else stats.crit_chance


func roll_attack(ad_ratio: float, source: StringName) -> DamageInfo:
	var crit := DamageCalc.is_crit(crit_chance(), randf())
	var amount := stats.ad * ad_ratio * (stats.crit_damage if crit else 1.0)
	return make_damage(amount, DamageInfo.Type.PHYSICAL, source, crit)


## Every hit Lucian deals is made here, so it carries his penetration.
func make_damage(amount: float, type: DamageInfo.Type, source: StringName, crit := false) -> DamageInfo:
	var info := DamageInfo.create(amount, type, source, self, crit)
	info.armor_pen = stats.armor_pen
	info.magic_pen = stats.magic_pen
	return info


func fire_attack_projectile(gun: LucianVisuals.Gun, target: Enemy, info: DamageInfo) -> void:
	var shot := AttackProjectile.new()
	shot.launch(visuals.muzzle_position(gun), target, info)
	spawn(shot)
	flash_muzzle(gun)


## The gunshot sound and, unless the quality is Low, a muzzle flash.
func flash_muzzle(gun: LucianVisuals.Gun) -> void:
	Sfx.play(&"shot", -6.0)
	if GameSettings.instance().low_effects():
		return
	var flash := MuzzleFlash.new()
	flash.position = visuals.muzzle_position(gun)
	spawn(flash)


## Adds a projectile or effect to the stage.
func spawn(node: Node) -> void:
	projectile_parent.add_child(node)


## Direction from Lucian to `aim`; his facing if the aim is right on top of him.
func aim_direction(aim: Vector2) -> Vector2:
	var offset := aim - global_position
	return offset.normalized() if offset.length() > 1.0 else Vector2.from_angle(visuals.rotation)


func _physics_process(delta: float) -> void:
	hp = minf(hp + stats.hp_regen * delta, stats.max_hp)
	mana = stats.max_mana if cheat_infinite_mana else minf(mana + stats.mana_regen * delta, stats.max_mana)
	if not restores.is_empty():
		var restored := restores.tick(delta)
		heal(restored.x)
		restore_mana(restored.y)
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	_tick_buffs(delta)
	if passives.shows_rfc_ring() != _rfc_ring_shown:
		_rfc_ring_shown = not _rfc_ring_shown
		queue_redraw()
	var was_dashing := is_dashing()
	velocity = Vector2.ZERO
	if _queued_slot >= 0 and not is_cast_locked() and not is_dashing():
		var queued := _queued_slot as ChampionProgress.Slot
		_queued_slot = -1
		try_cast(queued, _queued_aim)
	if _dash_left > 0.0:
		_dash_step(delta)
		_track_movement(was_dashing)
		return
	if _cast_lock_left > 0.0:
		_cast_lock_left -= delta
		return
	if _windup_left > 0.0:
		_process_windup(delta)
		return
	match _order:
		Order.MOVE:
			if _step_toward(_move_point, delta):
				_order = Order.NONE
		Order.ATTACK:
			if is_instance_valid(_target):
				_pursue(_target, delta)
			else:
				_order = Order.NONE
		Order.ATTACK_MOVE:
			if not is_instance_valid(_target) or not _in_range(_target):
				_target = _nearest_enemy_in_range()
			if _target:
				_pursue(_target, delta)
			elif _step_toward(_move_point, delta):
				_order = Order.NONE
		Order.VISIT:
			if not is_instance_valid(_visit):
				_order = Order.NONE
			elif global_position.distance_to(_visit.global_position) <= Merchant.INTERACT_RANGE:
				_order = Order.NONE
				merchant_reached.emit(_visit)
			else:
				_step_toward(_visit.global_position, delta)
	_track_movement(was_dashing)


func _on_inventory_changed() -> void:
	passives.refresh()
	_refresh_stats(true)


func _tick_buffs(delta: float) -> void:
	for id in _speed_buffs.keys():
		_speed_buffs[id].left -= delta
		if _speed_buffs[id].left <= 0.0:
			_speed_buffs.erase(id)
	for cooldown: Cooldown in item_cooldowns.values():
		cooldown.reduce(delta)
	if shield > 0.0 and not passives.in_combat():
		shield = maxf(shield - ICHORSHIELD_DECAY * delta, 0.0)
	if _barrier_left > 0.0:
		_barrier_left -= delta
		if _barrier_left <= 0.0:
			barrier = 0.0
	if _ghost_left > 0.0:
		_ghost_left -= delta
		if _ghost_left <= 0.0:
			_ghost_left = 0.0
			collision_mask = _body_mask()


## Walking, dashing and moving during R all build Energize.
func _track_movement(dashing: bool) -> void:
	var moved := global_position.distance_to(_last_position)
	_last_position = global_position
	if moved > 0.0:
		passives.on_moved(moved, dashing)


## Recomputes stats from the level and the equipped items. Leveling up grants
## the max HP / mana gained, like LoL. Item changes keep the current share of
## HP and mana instead, so swapping items can never refill them.
func _refresh_stats(keep_share: bool) -> void:
	var old := stats
	stats = base_stats.at_level(progress.level, inventory.equipped_bonus())
	passives.adjust_stats(stats)
	if keep_share:
		hp = clampf(hp / old.max_hp * stats.max_hp, 1.0, stats.max_hp)
		mana = mana / old.max_mana * stats.max_mana if old.max_mana > 0.0 else 0.0
	else:
		hp = clampf(hp + stats.max_hp - old.max_hp, 1.0, stats.max_hp)
		mana = clampf(mana + stats.max_mana - old.max_mana, 0.0, stats.max_mana)
	queue_redraw()


func _draw() -> void:
	if _show_range_ring:
		draw_arc(Vector2.ZERO, attack_range(), 0.0, TAU, 96, RANGE_RING_COLOR, 3.0, true)
	elif _rfc_ring_shown:
		draw_arc(Vector2.ZERO, stats.attack_range * (1.0 + ItemPassives.RFC_RANGE), 0.0, TAU, 96, RFC_RING_COLOR, 3.0, true)


func _dash_step(delta: float) -> void:
	# The last frame only covers the distance that is left.
	velocity = _dash_velocity * minf(delta, _dash_left) / delta
	move_and_slide()
	velocity = Vector2.ZERO
	_dash_left -= delta
	if is_instance_valid(_dash_trail):
		_dash_trail.reach(global_position)
	if _dash_left <= 0.0 or get_slide_collision_count() > 0:
		_dash_left = 0.0
		collision_mask = _body_mask()
		if is_instance_valid(_dash_trail):
			_dash_trail.finish()
		_dash_trail = null


## The trail starts with the dash and grows behind Lucian. None on low effects.
func _start_dash_trail(color: Color) -> void:
	if is_instance_valid(_dash_trail):
		_dash_trail.finish()
	_dash_trail = null
	if GameSettings.instance().low_effects():
		return
	_dash_trail = DashTrail.new()
	_dash_trail.setup(global_position, color)
	spawn(_dash_trail)


## Dashing or ghosted, Lucian passes through enemies; walls always stop him.
func _body_mask() -> int:
	return Layers.WORLD if is_dashing() or is_ghosted() else Layers.WORLD | Layers.ENEMY_BODY


func _process_windup(delta: float) -> void:
	if not is_instance_valid(_target):
		_cancel_windup()
		return
	visuals.face(_target.global_position - global_position)
	_windup_left -= delta
	if _windup_left <= 0.0:
		_windup_left = 0.0
		passive.fire_basic_attack(_target)


## Walks into range of `target`, then attacks whenever the attack is ready.
## No attacks while R is firing.
func _pursue(target: Enemy, delta: float) -> void:
	if not _in_range(target):
		_step_toward(target.global_position, delta)
		return
	visuals.face(target.global_position - global_position)
	if _attack_cooldown <= 0.0 and not (skills[ChampionProgress.Slot.R] as TheCulling).is_channeling():
		var period := stats.attack_period()
		_attack_cooldown = period
		_windup_left = period * WINDUP_RATIO


## A cancelled windup refunds the attack, like LoL.
func _cancel_windup() -> void:
	if _windup_left > 0.0:
		_windup_left = 0.0
		_attack_cooldown = 0.0


func _in_range(target: Enemy) -> bool:
	return global_position.distance_to(target.global_position) <= attack_range() + target.radius


func _nearest_enemy_in_range() -> Enemy:
	var best: Enemy = null
	var best_distance := INF
	for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
		var distance := global_position.distance_to(enemy.global_position)
		if distance < best_distance and _in_range(enemy):
			best = enemy
			best_distance = distance
	return best


## Moves toward `point` this frame. Returns true once Lucian has arrived.
func _step_toward(point: Vector2, delta: float) -> bool:
	var offset := point - global_position
	var step := current_move_speed() * delta
	if offset.length() <= step:
		velocity = offset / delta
		move_and_slide()
		velocity = Vector2.ZERO
		return true
	velocity = offset.normalized() * current_move_speed()
	visuals.face(offset)
	move_and_slide()
	return false

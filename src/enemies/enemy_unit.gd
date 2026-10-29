class_name EnemyUnit
extends Enemy
## A fighting enemy built in code from an EnemyData: body, hurtbox, art and
## health bar. It walks at Lucian (on a path around a wall in the way,
## sliding along walls, sidestepping when stuck), attacks when in range,
## and stands still while he is dead or can't be hit. With the data's
## `escape_after` it gets away after that long alive; with its `summon_id`
## it calls summons. Subclasses say what an attack does (_attack), and may
## think differently (_think); they can leap (leap_to) and charge (charge),
## and nothing is thought while one runs.

## It got away (see escape): no death, no kill.
signal escaped(unit: EnemyUnit)
## It calls a summon of `id` at `at` (see the data's summon_id). The stage
## counts it in the wave at once and spawns it deferred.
signal summon_requested(unit: EnemyUnit, id: StringName, at: Vector2)
## A leap (leap_to) or a charge (charge) has ended.
signal landed

const HIT_FLASH := Color(1.8, 1.8, 1.8)
## Moving less than this share of its speed in a frame counts as stuck.
const STUCK_SHARE := 0.25
const STUCK_TIME := 0.4
const ELITE_BAR := Vector2(110, 12)
const BOSS_BAR := Vector2(140, 14)
## A super minion's Empower on the minions around it: +15% damage.
const EMPOWER := &"empower"
const EMPOWER_BONUS := 0.15
const EMPOWER_ICON := preload("res://assets/art/ui/status_empower.svg")
## Shown by the stage when it escapes; a vanish shows none.
const ESCAPED_NOTE := "Escaped!"
## A summon appears this far past the summoner's edge.
const SUMMON_GAP := 50.0
## Its walking mask: walls, the abyss, other enemies and Lucian.
const BODY_MASK := Layers.WORLD | Layers.CHASM | Layers.ENEMY_BODY | Layers.PLAYER_BODY
## A charge passes through units; walls and the abyss stop it.
const CHARGE_MASK := Layers.WORLD | Layers.CHASM
## How much bigger it looks at the top of a leap.
const LEAP_RISE := 0.35
## The freed fade (data.frees): how high it rises and how long it takes, the
## teal-white it brightens to, and its chime's volume.
const FREED_RISE := 70.0
const FREED_TIME := 0.9
const FREED_COLOR := Color(1.5, 2.0, 1.85)
const FREED_CHIME_DB := -6.0
## The veil (Black Mist): the sprite's color times this, a dark silhouette.
const VEIL_SHADE := Color(0.08, 0.09, 0.12)

var data: EnemyData
var target: Lucian
## The wave it came with (its scaling); its splits come with the same one.
var wave := 1
## It got away: out of the group and every hitbox, it can't take damage or
## die, and it is fading out.
var has_escaped := false
## What the stage shows when it escapes: ESCAPED_NOTE, "" for none (vanish).
var escape_note := ESCAPED_NOTE
## It came as a summon: a quarter of its gold and XP, no essence, no loot.
var summoned := false
## The enemy that called it (summons only); may be dead or freed since.
var summoner: EnemyUnit
## Its own summons alive or on their way (called, not spawned yet).
var summons := 0
## On a ledge in the abyss (the stage sets it): it never walks, leaps or
## charges, since a move would push its body out of the abyss's shape (or
## off its ledge). It still turns toward Lucian and attacks.
var perched := false
## Black Mist: a dark silhouette with no health bar. Still a target.
var veiled := false:
	set(on):
		veiled = on
		_paint()
## This unit's numbers, after the act and wave scaling.
var damage := 0.0
var attack_range := 0.0
var move_speed := 0.0
## Where shots and ground warnings go; the parent when not set.
var projectile_parent: Node
var warning_parent: Node
var visuals := Node2D.new()
## Its art, under visuals: the tint and the veil color it, never the hit
## flash (that tweens visuals).
var sprite: Sprite2D
var health_bar := EnemyHealthBar.new()
## Its way around walls (see walk_toward).
var path_follower := PathFollower.new()

var _attack_left := 0.0
var _stuck_left := 0.0
var _sidestep := 1.0
var _flash_tween: Tween
## Seconds alive, for `escape_after`.
var _alive_time := 0.0
## Seconds of fighting to the next summons.
var _summon_left := 0.0
## A leap in the air (leap_to): from, to, its time and the time left.
var _leap_from := Vector2.ZERO
var _leap_to := Vector2.ZERO
var _leap_time := 0.0
var _leap_left := 0.0
## A charge running (charge): its velocity, the time left, the hit it may
## still land, and the mask it walks with.
var _charging := false
var _charge_velocity := Vector2.ZERO
var _charge_left := 0.0
var _charge_hit := Callable()
var _walk_mask := 0


## Call before adding the unit to the tree.
func setup(enemy_data: EnemyData, act: int, of_wave: int, foe: Lucian) -> void:
	data = enemy_data
	target = foe
	wave = of_wave
	max_hp = data.max_hp * data.hp_scale(act, wave)
	armor = data.armor
	mr = data.mr
	radius = data.radius
	damage = data.damage * data.damage_scale(act, wave)
	attack_range = data.attack_range
	move_speed = data.move_speed


func _ready() -> void:
	super()
	collision_layer = Layers.ENEMY_BODY
	collision_mask = BODY_MASK
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_child(_circle(data.radius * 0.85))
	var hurtbox := Hurtbox.new()
	hurtbox.collision_layer = Layers.ENEMY_HURTBOX
	hurtbox.collision_mask = 0
	hurtbox.monitoring = false
	hurtbox.add_child(_circle(data.radius + 6.0))
	add_child(hurtbox)
	add_child(visuals)
	sprite = Sprite2D.new()
	sprite.texture = data.art
	visuals.add_child(sprite)
	_paint()
	if data.is_boss_kind():
		health_bar.size = BOSS_BAR
	elif data.kind == &"elite":
		health_bar.size = ELITE_BAR
		health_bar.badge = true
	health_bar.position = Vector2(0, -data.radius - 34.0)
	health_bar.z_index = 10
	add_child(health_bar)
	health_bar.set_health(hp, max_hp)
	if projectile_parent == null:
		projectile_parent = get_parent()
	if warning_parent == null:
		warning_parent = get_parent()
	_attack_left = randf_range(0.2, data.attack_interval)
	_summon_left = data.summon_every


## A leap or a charge runs first (no thinking meanwhile); else, while
## Lucian can be fought, its summons and its _think.
func _physics_process(delta: float) -> void:
	super(delta)
	if not is_alive():
		return
	if data.escape_after > 0.0:
		_alive_time += delta
		if _alive_time >= data.escape_after:
			escape()
			return
	_attack_left = maxf(_attack_left - delta, 0.0)
	if is_leaping():
		_leap_step(delta)
	elif _charging:
		_charge_step(delta)
	elif can_fight():
		_summon_step(delta)
		_think(delta)


## Alive and still here (not escaped).
func is_alive() -> bool:
	return super() and not has_escaped


## An escaped unit takes nothing: a shot already in flight can't kill it.
func take_damage(info: DamageInfo) -> float:
	return 0.0 if has_escaped else super(info)


## Gets away, once: it leaves the enemies group and every hitbox first (so
## `_die` and damage do nothing from here), says so through `escaped`, then
## fades out. Nothing for a dead unit.
func escape() -> void:
	if dead or has_escaped:
		return
	has_escaped = true
	_leave_fight()
	escaped.emit(self)
	_fade_out()


## Goes quietly (a sapling's blast, a soul freed at Thresh's fall): an
## escape with no note. No rewards, done for the wave.
func vanish() -> void:
	if is_alive():
		escape_note = ""
	escape()


## One of its summons died or vanished: room for another.
func summon_gone() -> void:
	summons = maxi(summons - 1, 0)


## Jumps to `point` in `seconds`: straight there over anything (walls, the
## abyss, units), looking bigger at the top of the arc, untargetable in the
## air, landing exactly on `point`. Then `landed`. Nothing is thought in the
## air. The caller picks a spot it can stand on. Perched, it stays.
func leap_to(point: Vector2, seconds: float) -> void:
	if not is_alive() or perched:
		return
	_leap_from = global_position
	_leap_to = point
	_leap_time = maxf(seconds, 0.01)
	_leap_left = _leap_time
	set_untargetable(true)
	face(point)


func is_leaping() -> bool:
	return _leap_left > 0.0


## Runs `distance` along `direction` at `speed`, through units (its mask is
## CHARGE_MASK meanwhile); a wall or the abyss stops it short. `on_hit` is
## called once at most, the first frame Lucian (while he can be fought) is
## within its radius plus his hit radius. Then `landed`, with its walking
## mask back. Nothing is thought while it runs. Perched, it stays.
func charge(direction: Vector2, distance: float, speed: float, on_hit := Callable()) -> void:
	if not is_alive() or perched:
		return
	if not _charging:
		_walk_mask = collision_mask
	_charging = true
	_charge_velocity = direction.normalized() * speed
	_charge_left = distance / speed if speed > 0.0 else 0.0
	_charge_hit = on_hit
	collision_mask = CHARGE_MASK
	face(global_position + direction)


func is_charging() -> bool:
	return _charging


func _die() -> void:
	if has_escaped:
		return
	super()


## Lucian is there to fight: alive, not in stasis, not untouchable.
func can_fight() -> bool:
	return is_instance_valid(target) and not target.dead and not target.invulnerable and not target.in_stasis()


func distance_to_target() -> float:
	return global_position.distance_to(target.global_position)


## Move speed after the strongest slow.
func current_speed() -> float:
	return move_speed * (1.0 - slow_amount())


## A hit from this unit (Empower included): its basic attack by default.
func make_hit(amount := -1.0, source := &"basic") -> DamageInfo:
	var dealt := damage if amount < 0.0 else amount
	if has_status(EMPOWER):
		dealt *= 1.0 + EMPOWER_BONUS
	return DamageInfo.create(dealt, data.damage_type, source, self)


## A straight shot from this unit, at Lucian unless `toward` is given; walls
## stop it. A basic attack's bolt carries the data's on-hit slow and burn.
func fire_bolt(hit: DamageInfo, speed: float, reach: float, toward := Vector2.ZERO) -> EnemyProjectile:
	var bolt := EnemyProjectile.new()
	bolt.launch(global_position, toward if toward != Vector2.ZERO else global_position.direction_to(target.global_position), hit, target)
	bolt.speed = speed
	bolt.max_range = reach
	if hit.source == &"basic":
		bolt.hit_lucian.connect(apply_on_hit)
	projectile_parent.add_child(bolt)
	return bolt


## A basic attack landed on Lucian: the data's slow and burn (of its
## burn_type), each under the data's id so one kind of enemy refreshes its own.
func apply_on_hit() -> void:
	if not is_instance_valid(target):
		return
	if data.hit_slow > 0.0:
		target.add_slow(data.id, data.hit_slow, data.hit_slow_time)
	if data.hit_burn > 0.0:
		target.add_burn(data.id, data.hit_burn, data.hit_burn_time, data.burn_type(), self)


## One step toward `point`: straight while no wall is in the way, else along
## a path around it (see PathFollower), as walk does. Within a step of a path
## point that isn't `point` itself (the path's end, when `point` is inside a
## wall) it stands: a full step would take it past that point and back.
## Perched, it only turns toward `point`.
func walk_toward(point: Vector2, delta: float) -> void:
	if perched:
		face(point)
		return
	var world := get_world_2d()
	var toward := path_follower.next_point(global_position, point, delta, world.direct_space_state, world.navigation_map)
	if toward != point and global_position.distance_to(toward) <= current_speed() * delta:
		return
	walk(global_position.direction_to(toward), delta)


## One step in `direction`, with no path, sliding along walls. A unit that
## barely moved sidesteps for a moment. Perched, it stands.
func walk(direction: Vector2, delta: float) -> void:
	if perched:
		return
	if _stuck_left > 0.0:
		_stuck_left -= delta
		direction = (direction + direction.orthogonal() * _sidestep).normalized()
	var before := global_position
	velocity = direction * current_speed()
	move_and_slide()
	velocity = Vector2.ZERO
	face(global_position + direction)
	if _stuck_left <= 0.0 and before.distance_to(global_position) < current_speed() * delta * STUCK_SHARE:
		_stuck_left = STUCK_TIME
		if randf() < 0.3:
			_sidestep = -_sidestep


func face(point: Vector2) -> void:
	if point != global_position:
		visuals.rotation = (point - global_position).angle()


## Walks into range, then attacks whenever the attack is ready.
func _think(delta: float) -> void:
	if distance_to_target() > attack_range + Lucian.HIT_RADIUS:
		walk_toward(target.global_position, delta)
		return
	face(target.global_position)
	if _attack_left <= 0.0:
		_attack_left = data.attack_interval
		_attack()


## One attack: by default a hit on Lucian at once (melee), with the data's
## on-hit effects when he takes it.
func _attack() -> void:
	if target.take_damage(make_hit()):
		apply_on_hit()


func _lose_hp(amount: float) -> void:
	super(amount)
	health_bar.set_health(hp, max_hp)


## Heals, and the bar shows it.
func heal(amount: float) -> void:
	super(amount)
	health_bar.set_health(hp, max_hp)


func _show_hit() -> void:
	visuals.modulate = HIT_FLASH
	if _flash_tween:
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_property(visuals, "modulate", Color.WHITE, 0.15)


## A `frees` enemy's end (killed or vanished): it rises, brightens into
## teal-white light and fades upward, with a soft chime. Others fade grey.
func _fade_out() -> void:
	if not data.frees:
		super()
		return
	Sfx.play(&"freed", FREED_CHIME_DB)
	var fade := create_tween().set_parallel()
	fade.tween_property(visuals, "position:y", visuals.position.y - FREED_RISE, FREED_TIME) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	fade.tween_property(sprite, "modulate", FREED_COLOR, FREED_TIME * 0.4)
	fade.tween_property(self, "modulate:a", 0.0, FREED_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fade.chain().tween_callback(queue_free)


## The sprite's color: the data's tint, darkened to a silhouette when veiled.
## The health bar hides under the veil.
func _paint() -> void:
	health_bar.visible = not veiled
	if sprite:
		sprite.modulate = data.tint * VEIL_SHADE if veiled else data.tint


## Every summon_every seconds: up to summon_count summons beside it, keeping
## its own at or under summon_cap.
func _summon_step(delta: float) -> void:
	if data.summon_id == &"" or data.summon_every <= 0.0:
		return
	_summon_left -= delta
	if _summon_left > 0.0:
		return
	_summon_left = data.summon_every
	var count := mini(data.summon_count, data.summon_cap - summons)
	for i in count:
		summons += 1
		summon_requested.emit(self, data.summon_id, _summon_spot(i, count))
		# A listener may have ended it (a shot on the same frame).
		if not is_alive():
			return


## Where the i-th of `count` summons appears: beside it, spread round it.
func _summon_spot(i: int, count: int) -> Vector2:
	var side := visuals.rotation + PI * 0.5 + TAU * i / count
	return global_position + Vector2.from_angle(side) * (radius + SUMMON_GAP)


## A leap's frame: along the straight line, growing to 1 + LEAP_RISE at the
## middle and back; on the last one, down exactly on its point.
func _leap_step(delta: float) -> void:
	_leap_left = maxf(_leap_left - delta, 0.0)
	var t := 1.0 - _leap_left / _leap_time
	global_position = _leap_from.lerp(_leap_to, t)
	visuals.scale = Vector2.ONE * (1.0 + LEAP_RISE * sin(PI * t))
	if _leap_left > 0.0:
		return
	global_position = _leap_to
	visuals.scale = Vector2.ONE
	set_untargetable(false)
	landed.emit()


## A charge's frame: the last one only covers what is left. Lucian in reach
## takes the hit (once); the distance done, a wall or the abyss ends it.
func _charge_step(delta: float) -> void:
	velocity = _charge_velocity * minf(delta, _charge_left) / delta
	move_and_slide()
	velocity = Vector2.ZERO
	_charge_left -= delta
	if _charge_hit.is_valid() and can_fight() and distance_to_target() <= radius + Lucian.HIT_RADIUS:
		var hit := _charge_hit
		_charge_hit = Callable()
		hit.call()
	if _charging and (_charge_left <= 0.0 or get_slide_collision_count() > 0):
		_charging = false
		_charge_hit = Callable()
		# Its mask first: a listener may start another charge.
		collision_mask = _walk_mask
		landed.emit()


func _circle(circle_radius: float) -> CollisionShape2D:
	var round_shape := CircleShape2D.new()
	round_shape.radius = circle_radius
	var shape := CollisionShape2D.new()
	shape.shape = round_shape
	return shape

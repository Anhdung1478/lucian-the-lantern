class_name Elise
extends Boss
## Act 5's second mini boss, a spider queen at range. Cocoon: a line warning,
## then a web bolt that stuns on a hit. Rappel (at or below 85% HP): she
## rises, untargetable; a circle warning follows Lucian for RAPPEL_FOLLOW,
## then locks, and at RAPPEL_TIME she drops there. The drop runs on her own
## timer, so she lands even if the warning is gone.

const COCOON_LENGTH := 950.0
const COCOON_WIDTH := 60.0
const COCOON_WARN := 0.7
const COCOON_SPEED := 1300.0
const COCOON_DAMAGE := 100.0
const COCOON_STUN := 1.25
const COCOON_COOLDOWN := 11.0
const COCOON_FIRST := 3.0
const RAPPEL_RADIUS := 180.0
## Seconds the circle follows Lucian, and seconds until she drops.
const RAPPEL_FOLLOW := 1.0
const RAPPEL_TIME := 1.9
const RAPPEL_DAMAGE := 160.0
const RAPPEL_COOLDOWN := 16.0
## Rappel waits until HP is at or below this share.
const RAPPEL_HP := 0.85
## Seconds her art takes to fade as she rises.
const RISE_FADE := 0.3
## Seconds she stands after a skill's warning ends, or after she drops.
const RECOVER := 0.3
const WEB := Color("e8e8f0")

var _rappel_time := -1.0
var _rappel_warning: GroundWarning
## Her Cocoon webs in the air: each counts until it leaves the tree (it hit,
## was blocked, hit a wall or ran its length).
var _webs_flying := 0
var _rappel_spot := Vector2.ZERO
var _fade: Tween
var _drop_tween: Tween


func _ready() -> void:
	super()
	# Tried first: a hurt queen climbs before she spits.
	add_skill(&"rappel", RAPPEL_COOLDOWN, INF, 0.0, rappel)
	add_skill(&"cocoon", COCOON_COOLDOWN, COCOON_LENGTH, COCOON_FIRST, cocoon)


## Up on her thread: from the rise until she drops.
func is_rappelling() -> bool:
	return _rappel_time >= 0.0


## A line warning at Lucian, then the web bolt.
func cocoon() -> float:
	var toward := global_position.direction_to(target.global_position)
	face(target.global_position)
	var warning := GroundWarning.line(global_position, toward, COCOON_LENGTH, COCOON_WIDTH, COCOON_WARN)
	warning.fired.connect(_spit_web.bind(toward))
	warning_parent.add_child(warning)
	return COCOON_WARN + RECOVER


func _spit_web(toward: Vector2) -> void:
	if not is_alive():
		return
	var bolt := fire_bolt(skill_hit(COCOON_DAMAGE, DamageInfo.Type.MAGIC, &"cocoon"), COCOON_SPEED, COCOON_LENGTH, toward)
	bolt.hit_radius = COCOON_WIDTH * 0.5
	bolt.color = WEB
	bolt.style = EnemyProjectile.Style.WEB
	bolt.hit_lucian.connect(_web_hit)
	_webs_flying += 1
	bolt.tree_exited.connect(_web_gone)


func _web_gone() -> void:
	_webs_flying -= 1


## True while one of her Cocoon webs is still in the air: its stun may yet
## land.
func web_in_flight() -> bool:
	return _webs_flying > 0


func _web_hit() -> void:
	if is_instance_valid(target):
		target.add_cc(CrowdControl.Kind.STUN, COCOON_STUN)


## Rises: untargetable, her art and her shadow fading, a circle on Lucian
## that follows him and locks (see _physics_process). Busy until she has
## dropped.
func rappel() -> float:
	set_untargetable(true)
	_rappel_time = 0.0
	_rappel_spot = target.global_position
	if _flash_tween:
		_flash_tween.kill()
	if _drop_tween:
		_drop_tween.kill()
	visuals.modulate = Color.WHITE
	visuals.position = Vector2.ZERO
	visuals.scale = Vector2.ONE
	_fade = create_tween().set_parallel()
	_fade.tween_property(visuals, "modulate:a", 0.0, RISE_FADE)
	_fade.tween_property(visuals, "position:y", -220.0, RISE_FADE).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_fade.tween_property(visuals, "scale", Vector2.ONE * 0.78, RISE_FADE)
	_fade.tween_property(health_bar, "modulate:a", 0.0, RISE_FADE)
	_fade.tween_property(shadow, "modulate:a", 0.0, RISE_FADE)
	_rappel_warning = GroundWarning.circle(_rappel_spot, RAPPEL_RADIUS, RAPPEL_TIME)
	warning_parent.add_child(_rappel_warning)
	queue_redraw()
	return RAPPEL_TIME + RECOVER


## Rappel waits for 85% HP, and never starts while Lucian is stunned or one
## of her Cocoon webs is still flying (its stun could land as the circle
## locks, and he couldn't step out); she tries something else, and Rappel
## keeps its cooldown.
func _can_use(id: StringName) -> bool:
	if id != &"rappel":
		return true
	if web_in_flight() or (is_instance_valid(target) and target.has_cc(CrowdControl.Kind.STUN)):
		return false
	return hp <= max_hp * RAPPEL_HP


## Nothing while she is up: no walking, no shots, no skills.
func _think(delta: float) -> void:
	if not is_rappelling():
		super(delta)


func _physics_process(delta: float) -> void:
	super(delta)
	if not is_alive() or not is_rappelling():
		return
	var before := _rappel_time
	_rappel_time += delta
	if before < RAPPEL_FOLLOW:
		if is_instance_valid(target):
			_rappel_spot = target.global_position
		if _rappel_time >= RAPPEL_FOLLOW:
			_rappel_spot = Boss.landing_spot(_rappel_spot, arena, radius)
		if is_instance_valid(_rappel_warning):
			_rappel_warning.global_position = _rappel_spot
	queue_redraw()
	if _rappel_time >= RAPPEL_TIME:
		_drop()


## She drops on the locked spot, seen and targetable again: a hit on Lucian
## inside the circle.
func _drop() -> void:
	_rappel_time = -1.0
	global_position = _rappel_spot
	set_untargetable(false)
	if _fade:
		_fade.kill()
	if _drop_tween:
		_drop_tween.kill()
	visuals.modulate.a = 1.0
	visuals.position = Vector2(0.0, -160.0)
	visuals.scale = Vector2(0.88, 1.15)
	_drop_tween = create_tween().set_parallel()
	_drop_tween.tween_property(visuals, "position", Vector2.ZERO, 0.12).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	_drop_tween.tween_property(visuals, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	health_bar.modulate.a = 1.0
	shadow.modulate.a = 1.0
	if Juice.on():
		var splatter := _WebSplatterVfx.new()
		splatter.setup(_rappel_spot, RAPPEL_RADIUS)
		warning_parent.add_child(splatter)
	queue_redraw()
	if is_instance_valid(target) and GroundWarning.in_circle(_rappel_spot, RAPPEL_RADIUS, target.global_position, Lucian.HIT_RADIUS):
		target.take_damage(skill_hit(RAPPEL_DAMAGE, DamageInfo.Type.MAGIC, &"rappel"))


func _draw() -> void:
	super()
	if not is_rappelling():
		return
	# Taut silver silk thread stretching straight up as she ascends off-screen.
	if _rappel_time < RISE_FADE + 0.08:
		var rise_alpha := clampf(1.0 - _rappel_time / (RISE_FADE + 0.08), 0.0, 1.0)
		draw_line(visuals.position, Vector2(0.0, -720.0), Color(WEB, rise_alpha * 0.45), 5.0, true)
		draw_line(visuals.position, Vector2(0.0, -720.0), Color(Color.WHITE, rise_alpha * 0.92), 2.0, true)
	# Shimmering gossamer vertical silk strand dangling down to the target ring.
	var spot_local := to_local(_rappel_spot)
	var top_pt := spot_local + Vector2(0.0, -700.0)
	var locked := _rappel_time >= RAPPEL_FOLLOW
	var shimmer := 0.65 + 0.35 * sin(_rappel_time * 16.0)
	var strand_alpha := (0.72 if locked else 0.46) * shimmer
	draw_line(top_pt, spot_local, Color(WEB, strand_alpha * 0.4), 5.5, true)
	draw_line(top_pt, spot_local, Color(Color.WHITE, strand_alpha), 1.8, true)
	# Subtle silk anchor cross & descending glint once the drop spot locks.
	if locked:
		var drop_frac := clampf((_rappel_time - RAPPEL_FOLLOW) / maxf(RAPPEL_TIME - RAPPEL_FOLLOW, 0.01), 0.0, 1.0)
		var glint_y := lerpf(-420.0, -18.0, drop_frac * drop_frac)
		draw_circle(spot_local + Vector2(0.0, glint_y), 5.5, Color(Color.WHITE, 0.85))
		for i in 6:
			var ang := i * TAU / 6.0
			draw_line(spot_local, spot_local + Vector2.from_angle(ang) * 26.0, Color(WEB, 0.55), 1.6, true)
		draw_arc(spot_local, 16.0, 0.0, TAU, 18, Color(Color.WHITE, 0.62), 1.5, true)


class _WebSplatterVfx extends Node2D:
	const LIFETIME := 0.44
	var _elapsed := 0.0
	var _radius := 180.0
	var _spokes := 8

	func setup(at: Vector2, splatter_radius: float) -> void:
		position = at
		_radius = splatter_radius
		z_index = 6

	func _process(delta: float) -> void:
		_elapsed += delta
		if _elapsed >= LIFETIME:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var t := clampf(_elapsed / LIFETIME, 0.0, 1.0)
		var ease_out := 1.0 - pow(1.0 - t, 2.5)
		var alpha := 1.0 - t
		var cur_r := _radius * (0.22 + 0.84 * ease_out)
		# Dark crimson impact flash at center.
		draw_circle(Vector2.ZERO, cur_r * 0.48, Color("a81c3a", alpha * 0.34))
		draw_arc(Vector2.ZERO, cur_r, 0.0, TAU, 48, Color("d93254", alpha * 0.72), lerpf(7.0, 1.5, t), true)
		# Radial silver spiderweb spokes & concentric silk rings.
		for i in _spokes:
			var ang := i * TAU / _spokes + 0.18
			var tip := Vector2.from_angle(ang) * cur_r
			draw_line(Vector2.ZERO, tip, Color("f0f2ff", alpha * 0.86), lerpf(2.8, 1.2, t), true)
			draw_circle(tip, lerpf(5.0, 2.0, t), Color("e6e8f5", alpha * 0.85))
		for ring_frac: float in [0.38, 0.68]:
			var poly := PackedVector2Array()
			for i in _spokes + 1:
				var ang := i * TAU / _spokes + 0.18
				poly.append(Vector2.from_angle(ang) * (cur_r * ring_frac))
			draw_polyline(poly, Color("e8eaf6", alpha * 0.78), 1.8, true)

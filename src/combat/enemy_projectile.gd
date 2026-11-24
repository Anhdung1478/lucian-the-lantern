class_name EnemyProjectile
extends Area2D
## An enemy's shot: flies straight and ends on Lucian (by distance, taken or
## blocked) or on a wall or pillar. A boomerang flies `max_range` out, then
## back to its thrower, and may hit once each way. It flies over the abyss.
## A wave front (front_width) stops on a wall by its whole width, not just its
## center.

## The shot hit Lucian and he took it (not blocked).
signal hit_lucian
## The shot ended without reaching Lucian: at its range, or on a wall. One
## that reached him is no miss, even when Banshee's Veil blocked it. A
## boomerang misses (once, as it turns back) only when it never reached him
## on its way out. Never emitted inside a physics callback, so a listener
## may throw again at once (Thresh's re-hook).
signal missed

enum Style {
	ORB,
	FIREBALL,
	BOOMERANG,
	HOOK,
	WEB,
	DARK_BOLT,
	GOLD_BULLET,
	WATER_WAVE,
	VINE_WAVE,
}

## A wave front: how far its crest bows forward at the middle, its depth
## behind the crest, the trailing wake's extra depth, and the points along it.
const FRONT_BOW := 22.0
const FRONT_DEPTH := 58.0
const WAKE_DEPTH := 56.0
const FRONT_POINTS := 18
const FOAM := Color("eafcff")
const GLOW_RADIUS := 22.0
## How thin the wall check across a wave's front is, along its travel.
const WALL_CHECK_DEPTH := 12.0

var info: DamageInfo
var target: Lucian
var direction := Vector2.RIGHT
var speed := 450.0
var max_range := 600.0
var hit_radius := 12.0
var color := Color("c47cff")
var style := Style.ORB
## Drawn as a wave front this wide across its travel (the Ocean Drake's Tidal
## Wave), a crest of foam bowing forward, instead of a ball. 0 = a ball. The
## look and its reach at walls: it still hits Lucian within hit_radius of its
## center, but a wall anywhere across this width stops it (once it has
## travelled hit_radius, so a wave fired beside a wall still leaves).
var front_width := 0.0
## Boomerang: flies back to this node after max_range.
var return_to: Node2D
## Draws a chain back to this node (Thresh's hook).
var tether: Node2D

var _travelled := 0.0
var _age := 0.0
var _returning := false
var _hit_this_pass := false
## It reached Lucian on its way out (taken or blocked): never a miss.
var _reached := false
var _missed := false
var _wall_check: RectangleShape2D


func launch(from: Vector2, toward: Vector2, hit: DamageInfo, foe: Lucian) -> void:
	position = from
	direction = toward.normalized()
	rotation = direction.angle()
	info = hit
	target = foe


func _ready() -> void:
	collision_layer = 0
	collision_mask = Layers.WORLD
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 6.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_wall)
	if front_width <= 0.0:
		ShotGlow.attach(self, GLOW_RADIUS)


func _physics_process(delta: float) -> void:
	_age += delta
	var step := speed * delta
	if _returning:
		if not is_instance_valid(return_to):
			queue_free()
			return
		var offset := return_to.global_position - global_position
		if offset.length() <= step:
			queue_free()
			return
		direction = offset.normalized()
	global_position += direction * step
	rotation = direction.angle()
	_travelled += step
	if _hits_wall_across_front():
		_miss.call_deferred()
		queue_free()
		return
	queue_redraw()
	if not _hit_this_pass and is_instance_valid(target) and global_position.distance_to(target.global_position) <= hit_radius + Lucian.HIT_RADIUS:
		_hit_this_pass = true
		_reached = _reached or not _returning
		if target.take_damage(info):
			hit_lucian.emit()
		if not return_to:
			queue_free()
			return
	if not _returning and _travelled >= max_range:
		_miss()
		if return_to:
			_returning = true
			_hit_this_pass = false
		else:
			queue_free()


## True when a wave front's width, a thin strip across its travel, touches a
## wall or pillar. Only once it has travelled hit_radius; never for a narrow
## shot or over the abyss (not a wall).
func _hits_wall_across_front() -> bool:
	if front_width <= 0.0 or _travelled < hit_radius:
		return false
	if _wall_check == null:
		_wall_check = RectangleShape2D.new()
	_wall_check.size = Vector2(WALL_CHECK_DEPTH, front_width)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _wall_check
	query.transform = global_transform
	query.collision_mask = Layers.WORLD
	return not get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


## A wall or pillar stops it. The miss waits for the end of the physics
## callback this comes from.
func _on_wall(_body: Node2D) -> void:
	_miss.call_deferred()
	queue_free()


## Once, and only when it never reached Lucian on its way out.
func _miss() -> void:
	if _reached or _missed:
		return
	_missed = true
	missed.emit()


func _effective_style() -> Style:
	if style != Style.ORB:
		return style
	if front_width > 0.0:
		return Style.WATER_WAVE
	if tether != null:
		return Style.HOOK
	if return_to != null:
		return Style.BOOMERANG
	return Style.ORB


func _draw() -> void:
	match _effective_style():
		Style.FIREBALL:
			_draw_fireball()
		Style.BOOMERANG:
			_draw_boomerang()
		Style.HOOK:
			_draw_hook()
		Style.WEB:
			_draw_web()
		Style.DARK_BOLT:
			_draw_dark_bolt()
		Style.GOLD_BULLET:
			_draw_gold_bullet()
		Style.WATER_WAVE:
			_draw_water_wave()
		Style.VINE_WAVE:
			_draw_vine_wave()
		_:
			_draw_orb()


## Sleek glowing tapered arcane comet / teardrop with bright core and subtle energy tail.
func _draw_orb() -> void:
	var r := maxf(hit_radius, 8.0)
	var wobble := sin(_age * 18.0) * r * 0.14
	var outer := PackedVector2Array([
		Vector2(r * 1.15, 0.0),
		Vector2(r * 0.35, -r * 0.85),
		Vector2(-r * 0.55, -r * 0.52),
		Vector2(-r * 2.4, wobble),
		Vector2(-r * 0.55, r * 0.52),
		Vector2(r * 0.35, r * 0.85),
	])
	var mid := PackedVector2Array([
		Vector2(r * 0.9, 0.0),
		Vector2(r * 0.2, -r * 0.56),
		Vector2(-r * 1.6, -wobble * 0.5),
		Vector2(r * 0.2, r * 0.56),
	])
	draw_colored_polygon(outer, Color(color, 0.3))
	draw_colored_polygon(mid, Color(color, 0.85))
	draw_circle(Vector2(r * 0.15, 0.0), r * 0.44, Color(color.lerp(Color.WHITE, 0.65), 0.95))
	draw_circle(Vector2(r * 0.24, 0.0), r * 0.22, Color(Color.WHITE, 0.98))
	draw_line(Vector2(-r * 0.5, -r * 0.22), Vector2(-r * 1.85, wobble * 0.8 - r * 0.14), Color(color.lightened(0.35), 0.55), 1.8, true)
	draw_line(Vector2(-r * 0.5, r * 0.22), Vector2(-r * 1.75, -wobble * 0.8 + r * 0.14), Color(color.lightened(0.35), 0.5), 1.6, true)


## Blazing jagged fire comet with incandescent heart, licking orange-red tail, and ember flecks.
func _draw_fireball() -> void:
	var r := maxf(hit_radius, 10.0)
	var f1 := sin(_age * 28.0) * r * 0.26
	var f2 := cos(_age * 34.0 + 1.1) * r * 0.24
	var outer := PackedVector2Array([
		Vector2(r * 1.15, 0.0),
		Vector2(r * 0.5, -r * 0.88),
		Vector2(-r * 0.35, -r * 0.95 + f1 * 0.5),
		Vector2(-r * 1.35, -r * 0.42 + f2),
		Vector2(-r * 3.1, f1),
		Vector2(-r * 1.45, r * 0.42 - f2),
		Vector2(-r * 0.35, r * 0.95 - f1 * 0.5),
		Vector2(r * 0.5, r * 0.88),
	])
	var mid := PackedVector2Array([
		Vector2(r * 0.95, 0.0),
		Vector2(r * 0.3, -r * 0.62),
		Vector2(-r * 0.85, -r * 0.34 - f2 * 0.4),
		Vector2(-r * 2.1, -f1 * 0.6),
		Vector2(-r * 0.85, r * 0.34 + f2 * 0.4),
		Vector2(r * 0.3, r * 0.62),
	])
	draw_colored_polygon(outer, Color("d9340e", 0.78))
	draw_colored_polygon(mid, Color("ff8c20", 0.94))
	draw_circle(Vector2(r * 0.15, 0.0), r * 0.5, Color("ffda66", 0.96))
	draw_circle(Vector2(r * 0.24, 0.0), r * 0.28, Color("fffbe0", 0.99))
	for i in 4:
		var phase := fposmod(_age * 4.5 + i * 0.27, 1.0)
		var ex := -r * (0.7 + phase * 2.4)
		var ey := sin(_age * 16.0 + i * 2.3) * r * 0.65
		draw_circle(Vector2(ex, ey), lerpf(2.8, 1.1, phase), Color("ffe074", 1.0 - phase))


## Continuously spinning golden Sentinel curved crescent blade with motion-arc swoosh.
func _draw_boomerang() -> void:
	var r := maxf(hit_radius, 18.0)
	var spin := _age * 16.0
	# Bright gold motion-arc swoosh rings around the spinning blade.
	draw_arc(Vector2.ZERO, r * 1.04, spin - 1.9, spin - 0.15, 16, Color(color, 0.35), 4.5, true)
	draw_arc(Vector2.ZERO, r * 0.96, spin + PI - 1.7, spin + PI - 0.1, 14, Color("fff3c4", 0.48), 2.5, true)
	draw_set_transform(Vector2.ZERO, spin)
	# Swept curved Sentinel crescent blade (two sharp gold tips + central brass hub).
	var blade := PackedVector2Array([
		Vector2(r * 1.02, -r * 0.22),
		Vector2(r * 0.48, -r * 0.74),
		Vector2(-r * 0.28, -r * 0.78),
		Vector2(-r * 0.92, -r * 0.35),
		Vector2(-r * 0.42, -r * 0.18),
		Vector2(0.0, -r * 0.34),
		Vector2(r * 0.42, -r * 0.16),
		Vector2(r * 0.42, r * 0.16),
		Vector2(0.0, r * 0.34),
		Vector2(-r * 0.42, r * 0.18),
		Vector2(-r * 0.92, r * 0.35),
		Vector2(-r * 0.28, r * 0.78),
		Vector2(r * 0.48, r * 0.74),
		Vector2(r * 1.02, r * 0.22),
		Vector2(r * 0.62, 0.0),
	])
	draw_colored_polygon(blade, Color("e8b546", 0.96))
	draw_polyline(blade + PackedVector2Array([blade[0]]), Color("fff7d6", 0.95), 2.0, true)
	draw_circle(Vector2.ZERO, r * 0.28, Color("8a5f1a"))
	draw_circle(Vector2.ZERO, r * 0.16, Color("fff6cf"))
	draw_set_transform(Vector2.ZERO, 0.0)


## Taut linked spectral iron chain + wicked curved gleaming emerald Death Sentence hook claw.
func _draw_hook() -> void:
	if is_instance_valid(tether):
		var anchor := to_local(tether.global_position)
		var start := Vector2(-12.0, 0.0)
		var seg := anchor - start
		var dist := seg.length()
		if dist > 4.0:
			var dir := seg / dist
			var perp := dir.orthogonal()
			draw_line(start, anchor, Color(color, 0.24), 10.0, true)
			var link_spacing := 14.0
			var links := maxi(int(dist / link_spacing), 1)
			for i in links:
				var p0 := start + dir * (i * link_spacing)
				var p1 := start + dir * minf((i + 1) * link_spacing, dist)
				var mid_p := (p0 + p1) * 0.5
				var half_len := p0.distance_to(p1) * 0.52
				if i % 2 == 0:
					# Broad flat elliptical iron-green link.
					var hw := 5.2
					var outer_link := PackedVector2Array([
						mid_p + dir * half_len,
						mid_p + dir * (half_len * 0.5) + perp * hw,
						mid_p - dir * (half_len * 0.5) + perp * hw,
						mid_p - dir * half_len,
						mid_p - dir * (half_len * 0.5) - perp * hw,
						mid_p + dir * (half_len * 0.5) - perp * hw,
					])
					draw_colored_polygon(outer_link, Color("192b26", 0.95))
					draw_polyline(outer_link + PackedVector2Array([outer_link[0]]), color, 1.9, true)
					draw_line(mid_p - dir * (half_len * 0.45), mid_p + dir * (half_len * 0.45), Color("101b18", 0.9), 2.2, true)
				else:
					# Edge-on interlocking link bar.
					draw_line(p0, p1, Color("1a2d28", 0.98), 4.4, true)
					draw_line(p0, p1, color.lightened(0.25), 2.0, true)
	# Wicked curved gleaming emerald Death Sentence scythe/hook claw at the head.
	var r := clampf(hit_radius * 0.82, 16.0, 32.0)
	var claw := PackedVector2Array([
		Vector2(-r * 0.52, -r * 0.18),
		Vector2(r * 0.12, -r * 0.3),
		Vector2(r * 0.72, -r * 0.72),
		Vector2(r * 1.18, -r * 0.25),
		Vector2(r * 1.05, r * 0.48),
		Vector2(r * 0.42, r * 0.92),
		Vector2(r * 0.08, r * 0.58),
		Vector2(r * 0.58, r * 0.3),
		Vector2(r * 0.64, -r * 0.14),
		Vector2(r * 0.14, -r * 0.02),
		Vector2(-r * 0.52, r * 0.18),
	])
	var glow_claw := PackedVector2Array()
	for pt: Vector2 in claw:
		glow_claw.append(pt * 1.12)
	draw_colored_polygon(glow_claw, Color(color, 0.3))
	draw_colored_polygon(claw, Color("1f3f35", 0.98))
	var edge := PackedVector2Array([
		Vector2(r * 0.12, -r * 0.3),
		Vector2(r * 0.72, -r * 0.72),
		Vector2(r * 1.18, -r * 0.25),
		Vector2(r * 1.05, r * 0.48),
		Vector2(r * 0.42, r * 0.92),
	])
	draw_polyline(edge, color.lightened(0.35), 3.0, true)
	draw_polyline(edge, Color("e8fff4", 0.95), 1.3, true)
	# Heavy iron chain-collar at the base of the hook.
	draw_circle(Vector2(-r * 0.42, 0.0), r * 0.28, Color("1a2a26"))
	draw_arc(Vector2(-r * 0.42, 0.0), r * 0.28, 0.0, TAU, 14, color, 2.0, true)
	draw_circle(Vector2(r * 0.42, r * 0.92), 3.2, Color("f0fff8", 0.95))


## Spinning translucent white-silver spiderweb silk cocoon orb with trailing gossamer strands.
func _draw_web() -> void:
	var r := maxf(hit_radius, 16.0)
	# Trailing gossamer silk strands behind the orb.
	for i in 3:
		var y_off := (i - 1) * r * 0.42
		var strand := PackedVector2Array()
		for k in 7:
			var frac := float(k) / 6.0
			var x := -r * 0.3 - frac * r * 2.1
			var y := y_off * (1.0 - frac * 0.5) + sin(_age * 14.0 + frac * 5.0 + i * 1.8) * 4.5
			strand.append(Vector2(x, y))
		draw_polyline(strand, Color(color, 0.52), 1.5, true)
	draw_set_transform(Vector2.ZERO, _age * 5.5)
	draw_circle(Vector2.ZERO, r * 0.96, Color(color, 0.22))
	# Radial spiderweb spokes and concentric octagonal silk rings.
	for i in 8:
		var ang := i * TAU / 8.0
		draw_line(Vector2.ZERO, Vector2.from_angle(ang) * r * 0.95, Color(Color.WHITE, 0.72), 1.5, true)
	for ring_scale: float in [0.48, 0.84]:
		var web_ring := PackedVector2Array()
		for i in 9:
			var ang := i * TAU / 8.0
			web_ring.append(Vector2.from_angle(ang) * r * ring_scale)
		draw_polyline(web_ring, Color(Color.WHITE, 0.78), 1.6, true)
	draw_circle(Vector2.ZERO, r * 0.34, Color(color.lightened(0.25), 0.92))
	draw_circle(Vector2(r * 0.08, -r * 0.08), r * 0.14, Color(Color.WHITE, 0.96))
	draw_set_transform(Vector2.ZERO, 0.0)


## Sleek razor-sharp tapered void-violet & black-core energy tracer bolt.
func _draw_dark_bolt() -> void:
	var r := maxf(hit_radius, 10.0)
	var outer := PackedVector2Array([
		Vector2(r * 1.95, 0.0),
		Vector2(r * 0.25, -r * 0.62),
		Vector2(-r * 3.1, 0.0),
		Vector2(r * 0.25, r * 0.62),
	])
	var mid := PackedVector2Array([
		Vector2(r * 1.65, 0.0),
		Vector2(r * 0.2, -r * 0.36),
		Vector2(-r * 2.2, 0.0),
		Vector2(r * 0.2, r * 0.36),
	])
	var core := PackedVector2Array([
		Vector2(r * 1.1, 0.0),
		Vector2(r * 0.1, -r * 0.18),
		Vector2(-r * 1.45, 0.0),
		Vector2(r * 0.1, r * 0.18),
	])
	draw_colored_polygon(outer, Color(color, 0.36))
	draw_colored_polygon(mid, Color(color.lightened(0.28), 0.94))
	draw_colored_polygon(core, Color("140926", 0.98))
	draw_circle(Vector2(r * 1.55, 0.0), 2.8, Color("f3e5ff", 0.96))


## Sleek high-velocity gleaming brass-gold tracer bolt.
func _draw_gold_bullet() -> void:
	var r := maxf(hit_radius, 10.0)
	var outer := PackedVector2Array([
		Vector2(r * 2.0, 0.0),
		Vector2(r * 0.25, -r * 0.56),
		Vector2(-r * 3.3, 0.0),
		Vector2(r * 0.25, r * 0.56),
	])
	var body := PackedVector2Array([
		Vector2(r * 1.7, 0.0),
		Vector2(r * 0.2, -r * 0.3),
		Vector2(-r * 2.2, 0.0),
		Vector2(r * 0.2, r * 0.3),
	])
	var core := PackedVector2Array([
		Vector2(r * 1.35, 0.0),
		Vector2(r * 0.15, -r * 0.14),
		Vector2(-r * 1.3, 0.0),
		Vector2(r * 0.15, r * 0.14),
	])
	draw_colored_polygon(outer, Color(color, 0.34))
	draw_colored_polygon(body, Color("f2b84b", 0.96))
	draw_colored_polygon(core, Color("fffbe6", 0.99))


## Refined Ocean Drake tidal crescent wave with multi-layer translucent aqua depth & sea-foam crest.
func _draw_water_wave() -> void:
	var half := front_width * 0.5
	var crest := PackedVector2Array()
	for i in FRONT_POINTS + 1:
		var t := lerpf(-1.0, 1.0, float(i) / FRONT_POINTS)
		var ripple := sin(_age * 14.0 + i * 0.9) * 3.2 * (1.0 - t * t)
		crest.append(Vector2(FRONT_BOW * (1.0 - t * t) + ripple, half * t))
	for layer: Array in [
		[FRONT_DEPTH + WAKE_DEPTH, 0.26, 0.0, color.darkened(0.28)],
		[FRONT_DEPTH * 1.1, 0.62, 0.12, color.darkened(0.1)],
		[FRONT_DEPTH * 0.62, 0.92, 0.3, color.lightened(0.15)],
	]:
		var depth: float = layer[0]
		var crest_alpha: float = layer[1]
		var back_alpha: float = layer[2]
		var tint: Color = layer[3]
		var points := crest.duplicate()
		var colors := PackedColorArray()
		colors.resize(points.size())
		colors.fill(Color(tint, crest_alpha))
		for i in range(FRONT_POINTS - 1, 0, -1):
			var bow := 1.0 - crest[i].y * crest[i].y / (half * half)
			points.append(crest[i] - Vector2(depth * sqrt(maxf(bow, 0.0)), 0.0))
			colors.append(Color(tint.darkened(0.4), back_alpha))
		draw_polygon(points, colors)
	draw_polyline(crest, Color(color.lightened(0.45), 0.68), 14.0, true)
	draw_polyline(crest, FOAM, 5.5, true)
	for i in range(1, FRONT_POINTS, 2):
		var back_off := 8.0 + fposmod(_age * 45.0 + i * 11.0, 26.0)
		draw_circle(crest[i] - Vector2(back_off, 0.0), lerpf(4.0, 1.8, back_off / 34.0), Color(FOAM, 0.82))


## Maokai Nature's Grasp: surging wall of gnarled dark-bark roots, writhing thorny emerald vines & glowing briar spikes.
func _draw_vine_wave() -> void:
	var half := front_width * 0.5
	var crest := PackedVector2Array()
	for i in FRONT_POINTS + 1:
		var t := lerpf(-1.0, 1.0, float(i) / FRONT_POINTS)
		var wriggle := sin(_age * 9.0 + i * 1.25) * 5.0 * (1.0 - t * t)
		crest.append(Vector2(FRONT_BOW * (1.0 - t * t) + wriggle, half * t))
	# Dark mossy earth-churn shadow base.
	var base := crest.duplicate()
	var base_colors := PackedColorArray()
	base_colors.resize(base.size())
	base_colors.fill(Color("192814", 0.72))
	for i in range(FRONT_POINTS - 1, 0, -1):
		var bow := 1.0 - crest[i].y * crest[i].y / (half * half)
		base.append(crest[i] - Vector2((FRONT_DEPTH + WAKE_DEPTH * 0.55) * sqrt(maxf(bow, 0.0)), 0.0))
		base_colors.append(Color("111b0d", 0.0))
	draw_polygon(base, base_colors)
	# Gnarled dark-bark roots & writhing thorny emerald vines creeping across the front.
	var root_count := 8
	for r_i in root_count:
		var frac := lerpf(-0.88, 0.88, float(r_i) / float(root_count - 1))
		var y_base := half * frac
		var bow := 1.0 - frac * frac
		var front_x := FRONT_BOW * bow + sin(_age * 11.0 + r_i * 1.7) * 7.0
		var tail_len := (FRONT_DEPTH + 32.0) * (0.45 + 0.55 * sqrt(maxf(bow, 0.0)))
		var root_pts := PackedVector2Array()
		for seg in 7:
			var st := float(seg) / 6.0
			var sx := lerpf(-tail_len, front_x + 8.0, st)
			var sy := y_base + sin(_age * 10.0 + st * 6.0 + r_i * 2.1) * (9.0 * (1.0 - st * 0.35))
			root_pts.append(Vector2(sx, sy))
		draw_polyline(root_pts, Color("332215", 0.94), 9.0, true)
		draw_polyline(root_pts, Color("593c23", 0.88), 4.2, true)
		# Intertwined bright thorny emerald vine coiling around each root.
		var vine_pts := PackedVector2Array()
		for seg in 7:
			var st := float(seg) / 6.0
			var vx := lerpf(-tail_len * 0.85, front_x + 4.0, st)
			var vy := y_base - sin(_age * 11.0 + st * 7.0 + r_i * 2.1) * 8.5
			vine_pts.append(Vector2(vx, vy))
		draw_polyline(vine_pts, Color("2e7d2b", 0.92), 4.6, true)
		draw_polyline(vine_pts, color, 2.2, true)
	# Woven thorny vine-tangle along the leading edge.
	draw_polyline(crest, Color("264a1c", 0.9), 11.0, true)
	draw_polyline(crest, color, 4.5, true)
	# Protruding glowing sap-green briar spikes & leaf flecks along the front.
	for i in range(1, FRONT_POINTS, 2):
		var tip_base := crest[i]
		var spike_len := 14.0 + 5.0 * sin(_age * 14.0 + i * 1.6)
		var lean := (tip_base.y / maxf(half, 1.0)) * 5.0
		var spike := PackedVector2Array([
			tip_base + Vector2(spike_len, lean),
			tip_base + Vector2(-4.0, -5.0),
			tip_base + Vector2(-4.0, 5.0),
		])
		draw_colored_polygon(spike, Color("3c9630", 0.96))
		var inner_spike := PackedVector2Array([
			tip_base + Vector2(spike_len * 0.82, lean * 0.82),
			tip_base + Vector2(0.0, -2.2),
			tip_base + Vector2(0.0, 2.2),
		])
		draw_colored_polygon(inner_spike, Color("a6ff66", 0.95))
		# Small drifting emerald leaf flecks trailing behind.
		var leaf_off := 16.0 + fposmod(_age * 42.0 + i * 13.0, 38.0)
		var leaf_pos := tip_base - Vector2(leaf_off, sin(_age * 8.0 + i) * 6.0)
		var leaf := PackedVector2Array([
			leaf_pos + Vector2(5.0, 0.0),
			leaf_pos + Vector2(0.0, -2.8),
			leaf_pos + Vector2(-5.0, 0.0),
			leaf_pos + Vector2(0.0, 2.8),
		])
		draw_colored_polygon(leaf, Color("7ee854", 0.78))

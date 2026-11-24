class_name SennaFreed
extends Cutscene
## The story's end (6-5): Thresh falls to one knee and drops the lantern.
## Lucian shoots it through; it cracks, Senna's soul comes out and Thresh
## dissolves into green smoke. The stage pays him and clears when it is done.

const KNEEL_TIME := 0.9
const KNEEL_SCALE := Vector2(1.0, 0.8)
const KNEEL_TINT := Color(0.6, 0.65, 0.6)
const LANTERN_DROP := 50.0
const LANTERN_DROP_TIME := 0.5
const LANTERN_GLOW := Color(0.45, 1.0, 0.6, 0.5)
const SHOT_COLOR := Color("fffbe0")
const SHOT_GLOW := Color(1.0, 0.88, 0.42, 0.62)
const SHOT_TIME := 0.5
const FLASH_COLOR := Color(1.0, 0.98, 0.85, 0.92)
const FLASH_RADIUS := 64.0
const FLASH_TIME := 0.3
const RING_COLOR := Color(1.0, 0.95, 0.7, 0.88)
const SHATTER_TEAL := Color(0.42, 1.0, 0.76, 0.85)
const RING_RADIUS := 50.0
const RING_GROWTH := 3.0
const CRACK_COLOR := Color(1.0, 1.0, 0.8)
const CRACKED_TINT := Color(0.8, 0.85, 0.8)
const MOTES := 12
const MOTE_COLOR := Color(0.7, 1.0, 0.9, 0.9)
const MOTE_RISE := 160.0
const MOTE_TIME := 1.4
const MOTE_SPREAD := 50.0
## Senna's soul forms this far beside the lantern.
const SENNA_OFFSET := Vector2(80, -40)
const SENNA_GLOW := Color(0.4, 1.0, 0.9, 0.38)
const SENNA_GOLD := Color(1.0, 0.9, 0.58, 0.42)
const SENNA_TIME := 1.2
const SMOKE_COLOR := Color(0.35, 0.82, 0.48, 0.62)
const SMOKE_PUFFS := 8
const DISSOLVE_TIME := 1.4
const WHITE_TIME := 1.5


func _play() -> void:
	var thresh := stage.boss_unit as Thresh
	var lucian := stage.lucian
	# The last hit's flash froze with him.
	thresh.visuals.modulate = Color.WHITE
	await pan_to(thresh.global_position)
	if skipped:
		return
	# He sinks to one knee; the lantern drops from his hand and glows.
	var kneel := animate().set_parallel()
	kneel.tween_property(thresh.visuals, "scale", KNEEL_SCALE, KNEEL_TIME)
	kneel.tween_property(thresh.visuals, "modulate", KNEEL_TINT, KNEEL_TIME)
	var lantern := Sprite2D.new()
	lantern.texture = ThreshFinal.LANTERN_ART
	lantern.scale = Vector2.ONE * ThreshFinal.LANTERN_SCALE
	var glow := Node2D.new()
	glow.draw.connect(_draw_lantern_glow.bind(glow))
	lantern.add_child(glow)
	add_prop(lantern)
	lantern.global_position = thresh.global_position + Thresh.LANTERN_OFFSET
	var ground := lantern.global_position + Vector2(0, LANTERN_DROP)
	kneel.tween_property(lantern, "global_position", ground, LANTERN_DROP_TIME).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await step(kneel)
	if skipped:
		return
	# Pan to the lantern.
	await pan_to(ground)
	if skipped:
		return
	await caption("Lucian", Lang.t("It ends here."))
	if skipped:
		return
	# Blazing Sentinel piercing light-bolt from Lucian's gun to the lantern.
	var aim := ground - lucian.global_position
	var dir := aim.normalized() if aim.length_squared() > 0.01 else Vector2.RIGHT
	lucian.visuals.face(dir)
	var muzzle_pos := lucian.global_position + dir * Lucian.GUN_REACH
	# Golden muzzle flash at Lucian's gun.
	var muzzle_flash := Node2D.new()
	muzzle_flash.rotation = dir.angle()
	muzzle_flash.draw.connect(_draw_muzzle_flash.bind(muzzle_flash))
	add_prop(muzzle_flash)
	muzzle_flash.global_position = muzzle_pos
	var flash_anim := animate().set_parallel()
	flash_anim.tween_property(muzzle_flash, "scale", Vector2(1.45, 1.25), 0.18).set_ease(Tween.EASE_OUT)
	flash_anim.tween_property(muzzle_flash, "modulate:a", 0.0, 0.2)
	# Piercing light-bolt with bright tapered white-gold streak.
	var shot := Node2D.new()
	shot.rotation = dir.angle()
	shot.draw.connect(_draw_sentinel_bolt.bind(shot))
	add_prop(shot)
	shot.global_position = muzzle_pos
	Sfx.play(&"shot")
	await move(shot, ground, SHOT_TIME)
	if skipped:
		return
	shot.queue_free()
	# Lantern shatter: golden star flash, dual expanding rings & golden-emerald shards.
	var flash := Node2D.new()
	flash.draw.connect(_draw_shatter_flash.bind(flash))
	var ring_gold := Node2D.new()
	ring_gold.draw.connect(_draw_ring.bind(ring_gold, RING_COLOR, 4.5))
	var ring_teal := Node2D.new()
	ring_teal.draw.connect(_draw_ring.bind(ring_teal, SHATTER_TEAL, 3.0))
	for node: Node2D in [flash, ring_gold, ring_teal]:
		add_prop(node)
		node.global_position = ground
	var crack := Line2D.new()
	crack.width = 4.5
	crack.default_color = CRACK_COLOR
	crack.points = PackedVector2Array([Vector2(-6, -60), Vector2(8, -20), Vector2(-8, 10), Vector2(4, 60)])
	crack.scale = Vector2.ONE / ThreshFinal.LANTERN_SCALE * 0.6
	lantern.add_child(crack)
	var branch_crack := Line2D.new()
	branch_crack.width = 3.0
	branch_crack.default_color = Color(1.0, 0.96, 0.72, 0.9)
	branch_crack.points = PackedVector2Array([Vector2(8, -20), Vector2(36, -6), Vector2(-8, 10), Vector2(-34, 24)])
	branch_crack.scale = crack.scale
	lantern.add_child(branch_crack)
	lantern.modulate = CRACKED_TINT
	var burst := animate().set_parallel()
	burst.tween_property(flash, "scale", Vector2.ONE * 1.35, FLASH_TIME).set_ease(Tween.EASE_OUT)
	burst.tween_property(flash, "modulate:a", 0.0, FLASH_TIME)
	burst.tween_property(ring_gold, "scale", Vector2.ONE * RING_GROWTH, FLASH_TIME * 2.0).set_ease(Tween.EASE_OUT)
	burst.tween_property(ring_gold, "modulate:a", 0.0, FLASH_TIME * 2.0)
	burst.tween_property(ring_teal, "scale", Vector2.ONE * (RING_GROWTH * 1.35), FLASH_TIME * 2.0).set_ease(Tween.EASE_OUT)
	burst.tween_property(ring_teal, "modulate:a", 0.0, FLASH_TIME * 2.0)
	if Juice.on():
		for i in 12:
			var shard := Node2D.new()
			var is_gold := i % 2 == 0
			var shard_size := 8.0 + (i % 3) * 3.5
			shard.draw.connect(_draw_shard.bind(shard, shard_size, RING_COLOR if is_gold else SHATTER_TEAL))
			add_prop(shard)
			shard.global_position = ground
			var angle := TAU * i / 12.0 + randf_range(-0.18, 0.18)
			shard.rotation = angle
			var travel := randf_range(75.0, 145.0)
			burst.tween_property(shard, "global_position", ground + Vector2.from_angle(angle) * travel, FLASH_TIME * 1.9).set_ease(Tween.EASE_OUT)
			burst.tween_property(shard, "rotation", angle + randf_range(-1.8, 1.8), FLASH_TIME * 1.9)
			burst.tween_property(shard, "modulate:a", 0.0, FLASH_TIME * 1.9)
	await step(burst)
	if skipped:
		return
	# Soul motes stream up; Senna forms facing Lucian with layered aura; Thresh dissolves.
	Sfx.play(&"freed")
	var rise := animate().set_parallel()
	for i in MOTES:
		var mote := Node2D.new()
		mote.draw.connect(_draw_mote.bind(mote, i % 3 == 0))
		add_prop(mote)
		var start_x := ground.x + randf_range(-MOTE_SPREAD, MOTE_SPREAD)
		mote.global_position = Vector2(start_x, ground.y)
		rise.tween_property(mote, "global_position", Vector2(start_x + randf_range(-24.0, 24.0), ground.y - MOTE_RISE), MOTE_TIME).set_delay(i * 0.05).set_ease(Tween.EASE_OUT)
		rise.tween_property(mote, "modulate:a", 0.0, MOTE_TIME).set_delay(i * 0.05)
	var senna := Node2D.new()
	var senna_pos := ground + SENNA_OFFSET
	var senna_aura := Node2D.new()
	var aura_phase := [0.0]
	senna_aura.draw.connect(_draw_senna_aura.bind(senna_aura, aura_phase))
	senna.add_child(senna_aura)
	var art := Sprite2D.new()
	art.texture = Senna.ART
	# Orient freed Senna directly toward Lucian.
	art.rotation = (lucian.global_position - senna_pos).angle()
	senna.add_child(art)
	senna.modulate.a = 0.0
	add_prop(senna)
	senna.global_position = senna_pos
	rise.tween_property(senna, "modulate:a", 1.0, SENNA_TIME)
	if Juice.on():
		animate().tween_method(func(t: float) -> void:
			if is_instance_valid(senna_aura):
				aura_phase[0] = t
				senna_aura.queue_redraw(), 0.0, 1.0, SENNA_TIME + CAPTION_TIME * 2.0)
	rise.tween_property(thresh.visuals, "modulate", Color(SMOKE_COLOR, 0.0), DISSOLVE_TIME)
	rise.tween_property(thresh.visuals, "scale", KNEEL_SCALE * 1.3, DISSOLVE_TIME)
	# All of him goes: his Phase 2 aura (drawn on the unit) and his health bar too.
	rise.tween_property(thresh, "modulate:a", 0.0, DISSOLVE_TIME)
	# Swirling translucent spectral mist wisps as Thresh dissolves.
	for i in SMOKE_PUFFS:
		var wisp := Node2D.new()
		var wisp_scale := 0.8 + (i % 3) * 0.22
		wisp.draw.connect(_draw_spectral_wisp.bind(wisp, wisp_scale))
		add_prop(wisp)
		var base_angle := TAU * i / SMOKE_PUFFS
		var origin := thresh.global_position + Vector2.from_angle(base_angle) * 28.0
		wisp.global_position = origin
		wisp.rotation = base_angle
		var swirl_to := thresh.global_position + Vector2.from_angle(base_angle + 0.9) * 58.0 + Vector2(0, -105.0 - (i % 2) * 25.0)
		rise.tween_property(wisp, "global_position", swirl_to, DISSOLVE_TIME).set_ease(Tween.EASE_OUT)
		rise.tween_property(wisp, "rotation", base_angle + 1.5, DISSOLVE_TIME)
		rise.tween_property(wisp, "scale", Vector2.ONE * 1.55, DISSOLVE_TIME)
		rise.tween_property(wisp, "modulate:a", 0.0, DISSOLVE_TIME)
	# Dissolving emerald sparks lifting off Thresh.
	if Juice.on():
		for i in 14:
			var spark := Node2D.new()
			spark.draw.connect(_draw_dissolve_spark.bind(spark, 4.5 + (i % 3) * 1.8))
			add_prop(spark)
			var start_at := thresh.global_position + Vector2(randf_range(-42.0, 42.0), randf_range(-34.0, 34.0))
			spark.global_position = start_at
			var delay := (i % 5) * 0.08
			var dur := DISSOLVE_TIME - delay
			rise.tween_property(spark, "global_position", start_at + Vector2(randf_range(-36.0, 36.0), -randf_range(85.0, 145.0)), dur).set_delay(delay).set_ease(Tween.EASE_OUT)
			rise.tween_property(spark, "modulate:a", 0.0, dur).set_delay(delay)
	await step(rise)
	if skipped:
		return
	await caption("Senna", Lang.t("Lucian… you came."))
	if skipped:
		return
	await caption("Lucian", Lang.t("Always."))
	if skipped:
		return
	# A fade to white.
	var white := ColorRect.new()
	white.color = Color.WHITE
	white.set_anchors_preset(Control.PRESET_FULL_RECT)
	white.mouse_filter = Control.MOUSE_FILTER_IGNORE
	white.modulate.a = 0.0
	add_child(white)
	var fade := animate()
	fade.tween_property(white, "modulate:a", 1.0, WHITE_TIME)
	await step(fade)


func _draw_lantern_glow(glow: Node2D) -> void:
	var inv := 1.0 / ThreshFinal.LANTERN_SCALE
	MapArt.glow(glow, Vector2.ZERO, 40.0 * inv, Color(LANTERN_GLOW, 0.35))
	MapArt.glow(glow, Vector2.ZERO, 22.0 * inv, Color(Thresh.CHAIN_COLOR, 0.55))
	glow.draw_circle(Vector2.ZERO, 8.0 * inv, Color(0.82, 1.0, 0.9, 0.7))


func _draw_muzzle_flash(node: Node2D) -> void:
	MapArt.glow(node, Vector2(6, 0), 34.0, Color(SHOT_GLOW, 0.6))
	_draw_star(node, Vector2(6, 0), 26.0, 6.0, Color(SHOT_COLOR, 0.95))
	var cone := PackedVector2Array([Vector2.ZERO, Vector2(44, -10), Vector2(56, 0), Vector2(44, 10)])
	node.draw_colored_polygon(cone, Color(SHOT_COLOR, 0.78))


func _draw_sentinel_bolt(shot: Node2D) -> void:
	# Tapered white-gold piercing light streak behind the bolt tip.
	var outer_streak := PackedVector2Array([
		Vector2(24, 0), Vector2(4, -13), Vector2(-110, -3.5), Vector2(-132, 0), Vector2(-110, 3.5), Vector2(4, 13),
	])
	shot.draw_colored_polygon(outer_streak, Color(SHOT_GLOW, 0.42))
	var mid_streak := PackedVector2Array([
		Vector2(22, 0), Vector2(6, -7.5), Vector2(-86, -2.0), Vector2(-104, 0), Vector2(-86, 2.0), Vector2(6, 7.5),
	])
	shot.draw_colored_polygon(mid_streak, Color(1.0, 0.92, 0.58, 0.8))
	var core_streak := PackedVector2Array([
		Vector2(20, 0), Vector2(6, -3.8), Vector2(-60, -0.8), Vector2(-72, 0), Vector2(-60, 0.8), Vector2(6, 3.8),
	])
	shot.draw_colored_polygon(core_streak, Color.WHITE)
	MapArt.glow(shot, Vector2(8, 0), 26.0, Color(SHOT_GLOW, 0.65))
	_draw_star(shot, Vector2(10, 0), 18.0, 4.2, Color(SHOT_COLOR, 0.95))


func _draw_shatter_flash(node: Node2D) -> void:
	MapArt.glow(node, Vector2.ZERO, FLASH_RADIUS * 1.45, Color(SHOT_GLOW, 0.55))
	MapArt.glow(node, Vector2.ZERO, FLASH_RADIUS, FLASH_COLOR)
	_draw_star(node, Vector2.ZERO, FLASH_RADIUS * 1.2, 12.0, Color.WHITE)


func _draw_shard(node: Node2D, size: float, color: Color) -> void:
	var poly := PackedVector2Array([
		Vector2(size, 0), Vector2(0, -size * 0.42), Vector2(-size * 0.75, 0), Vector2(0, size * 0.42),
	])
	MapArt.glow(node, Vector2.ZERO, size * 1.3, Color(color, 0.32))
	node.draw_colored_polygon(poly, color)
	var core := PackedVector2Array([
		Vector2(size * 0.55, 0), Vector2(0, -size * 0.18), Vector2(-size * 0.35, 0), Vector2(0, size * 0.18),
	])
	node.draw_colored_polygon(core, Color.WHITE)


func _draw_mote(node: Node2D, golden: bool) -> void:
	var color := RING_COLOR if golden else MOTE_COLOR
	MapArt.glow(node, Vector2.ZERO, 15.0, Color(color, 0.35))
	var drop := PackedVector2Array([Vector2(0, -10), Vector2(4.5, -2), Vector2(0, 11), Vector2(-4.5, -2)])
	node.draw_colored_polygon(drop, color)
	node.draw_circle(Vector2(0, -2), 2.5, Color.WHITE)


func _draw_senna_aura(node: Node2D, phase_state: Array) -> void:
	var t: float = phase_state[0]
	var pulse := 0.92 + 0.08 * sin(t * TAU * 4.0)
	# Layered radiant converging teal-gold aura halo.
	MapArt.glow(node, Vector2.ZERO, 96.0 * pulse, Color(SENNA_GLOW, 0.36))
	MapArt.glow(node, Vector2.ZERO, 68.0 * pulse, Color(SENNA_GOLD, 0.3))
	MapArt.glow(node, Vector2.ZERO, 44.0 * pulse, Color(0.82, 1.0, 0.96, 0.38))
	node.draw_arc(Vector2.ZERO, 54.0 * pulse, 0.0, TAU, 56, Color(SENNA_GLOW, 0.48), 2.2, true)
	node.draw_arc(Vector2.ZERO, 66.0 * pulse, t * 2.0, t * 2.0 + PI * 0.85, 32, Color(SENNA_GOLD, 0.45), 1.8, true)
	node.draw_arc(Vector2.ZERO, 66.0 * pulse, t * 2.0 + PI, t * 2.0 + PI * 1.85, 32, Color(SENNA_GOLD, 0.45), 1.8, true)
	# Rising ethereal teal & gold light ribbons.
	for i in 4:
		var x_base := -30.0 + i * 20.0
		var ribbon_color := SENNA_GOLD if i % 2 == 1 else SENNA_GLOW
		var pts := PackedVector2Array()
		for step_i in 7:
			var share := float(step_i) / 6.0
			var y := 34.0 - share * 110.0
			var sway := sin(t * 9.0 + share * 4.2 + i * 1.6) * (6.0 + 4.0 * share)
			pts.append(Vector2(x_base + sway, y))
		for step_i in pts.size() - 1:
			var alpha := sin(PI * float(step_i + 0.5) / (pts.size() - 1)) * 0.55
			node.draw_line(pts[step_i], pts[step_i + 1], Color(ribbon_color, alpha * 0.45), 7.5, true)
			node.draw_line(pts[step_i], pts[step_i + 1], Color(0.92, 1.0, 0.96, alpha), 2.0, true)


func _draw_spectral_wisp(node: Node2D, s: float) -> void:
	MapArt.soft_oval(node, Vector2.ZERO, Vector2(34.0, 20.0) * s, Color(SMOKE_COLOR, 0.42))
	MapArt.soft_oval(node, Vector2(14.0, -8.0) * s, Vector2(24.0, 14.0) * s, Color(Thresh.CHAIN_COLOR, 0.34))
	var curl := PackedVector2Array([
		Vector2(-24, 6) * s, Vector2(-6, -10) * s, Vector2(14, -4) * s, Vector2(28, -16) * s,
	])
	node.draw_polyline(curl, Color(Thresh.CHAIN_COLOR, 0.45), 5.0 * s, true)
	node.draw_polyline(curl, Color(0.82, 1.0, 0.88, 0.55), 1.8 * s, true)


func _draw_dissolve_spark(node: Node2D, size: float) -> void:
	MapArt.glow(node, Vector2.ZERO, size * 2.0, Color(ThreshFinal.AURA_COLOR, 0.42))
	_draw_star(node, Vector2.ZERO, size, size * 0.3, Color(0.86, 1.0, 0.9, 0.95))


func _draw_ring(ring: Node2D, color: Color, width: float) -> void:
	ring.draw_arc(Vector2.ZERO, RING_RADIUS, 0.0, TAU, 56, Color(color, color.a * 0.32), width * 2.6, true)
	ring.draw_arc(Vector2.ZERO, RING_RADIUS, 0.0, TAU, 56, color, width, true)


static func _draw_star(canvas: CanvasItem, at: Vector2, outer: float, inner: float, color: Color) -> void:
	var pts := PackedVector2Array([
		at + Vector2(0, -outer), at + Vector2(inner, -inner),
		at + Vector2(outer, 0), at + Vector2(inner, inner),
		at + Vector2(0, outer), at + Vector2(-inner, inner),
		at + Vector2(-outer, 0), at + Vector2(-inner, -inner),
	])
	canvas.draw_colored_polygon(pts, color)

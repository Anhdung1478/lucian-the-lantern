class_name ThreshTakesSenna
extends Cutscene
## Act 1's end: Thresh hooks Senna, pulls her in and takes her soul into his
## lantern, then sinks into the river. Lucian goes to her and takes up her
## gun. The stage frees Thresh and Senna when it is done. The camera frames
## the hook's whole flight, then follows Senna in to Thresh.

const CHAIN_WIDTH := 6.0
const CHAIN_TIME := 0.35
const CHAIN_IRON := Color("1c2b29")
const CHAIN_STEEL := Color("4f746b")
const CHAIN_EDGE := Color("a8ffd0")
const CHAIN_LINK_STEP := 16.0
## Senna is pulled in to this far in front of Thresh.
const CATCH_GAP := 100.0
const PULL_TIME := 0.5
## Senna after the hook: grey, tipped over.
const FALLEN_TINT := Color(0.55, 0.57, 0.6)
const FALLEN_TILT := 1.4
const SOUL_COLOR := Color("e8fffa")
const SOUL_GLOW := Color(0.45, 1.0, 0.9, 0.42)
const SOUL_RIBBON := Color(0.42, 0.98, 0.88, 0.72)
const SOUL_RISE := 70.0
const SOUL_RISE_TIME := 0.4
const SOUL_FLIGHT := 1.2
const LANTERN_GLOW := Color(0.45, 1.0, 0.6, 0.52)
const LANTERN_CORE := Color("d6ffe4")
const LANTERN_LIGHT_TIME := 0.5
const SINK_TIME := 1.2
## Thresh's size when he is gone under the water.
const SUNK_SCALE := 0.3
const RING_COLOR := Color(0.75, 0.95, 1.0, 0.85)
const RING_RADIUS := 50.0
const RING_GROWTH := 2.4
const RIVER_MIST := Color(0.38, 0.92, 0.68, 0.45)
const WALK_TIME := 1.0
## Lucian stops this short of Senna.
const KNEEL_GAP := 60.0
const CLAIM_GOLD := Color(1.0, 0.9, 0.55, 0.85)
const CLAIM_TEAL := Color(0.45, 1.0, 0.9, 0.8)


func _play() -> void:
	var thresh := stage.boss_unit as Thresh
	var senna := stage.senna
	var lucian := stage.lucian
	# The last hit's flash froze with him.
	thresh.visuals.modulate = Color.WHITE
	await pan_to((thresh.global_position + senna.global_position) * 0.5)
	if skipped:
		return
	await caption("Thresh", Lang.t("Such a bright soul... it will make a fine light."))
	if skipped:
		return
	# The spectral iron chain and curved scythe hook fly to Senna.
	thresh.face(senna.global_position)
	var chain := Node2D.new()
	var hook_state := [Vector2.ZERO]
	chain.draw.connect(_draw_hook_chain.bind(chain, hook_state))
	add_prop(chain)
	chain.global_position = thresh.global_position
	var chain_end := func(point: Vector2) -> void:
		hook_state[0] = point - chain.global_position
		chain.queue_redraw()
	var throw := animate()
	throw.tween_method(chain_end, thresh.global_position, senna.global_position, CHAIN_TIME)
	Sfx.play(&"hook")
	await step(throw)
	if skipped:
		return
	await caption("Lucian", Lang.t("SENNA!"))
	if skipped:
		return
	# Pulled in on the chain, she falls.
	var caught := thresh.global_position + thresh.global_position.direction_to(senna.global_position) * CATCH_GAP
	var fall := animate().set_parallel()
	fall.tween_method(chain_end, senna.global_position, caught, PULL_TIME)
	fall.tween_property(senna.visuals, "modulate", FALLEN_TINT, PULL_TIME)
	fall.tween_property(senna.visuals, "rotation", senna.visuals.rotation + FALLEN_TILT, PULL_TIME)
	fall.tween_property(stage.camera, "global_position", thresh.global_position, PULL_TIME).set_trans(Tween.TRANS_SINE)
	await move(senna, caught, PULL_TIME)
	if skipped:
		return
	# Her luminous teardrop soul-wisp trails teal ribbons into his lantern.
	var soul := Node2D.new()
	var soul_trail: Array[Vector2] = [caught]
	var soul_state := [0.0, Vector2.UP]
	soul.draw.connect(_draw_soul.bind(soul, soul_trail, soul_state))
	add_prop(soul)
	soul.global_position = caught
	var lantern_world := thresh.global_position + Thresh.LANTERN_OFFSET.rotated(thresh.visuals.rotation)
	var update_soul := func(progress: float) -> void:
		if not is_instance_valid(soul):
			return
		var pos := soul.global_position
		if soul_trail.is_empty() or soul_trail[soul_trail.size() - 1].distance_to(pos) > 3.0:
			var prev: Vector2 = soul_trail[soul_trail.size() - 1] if not soul_trail.is_empty() else pos
			if pos.distance_to(prev) > 0.5:
				soul_state[1] = (pos - prev).normalized()
			soul_trail.append(pos)
			if soul_trail.size() > 14:
				soul_trail.remove_at(0)
		soul_state[0] = progress
		soul.queue_redraw()
	animate().tween_method(update_soul, 0.0, 1.0, SOUL_RISE_TIME + SOUL_FLIGHT)
	var flight := animate()
	flight.tween_property(soul, "global_position", caught + Vector2(0, -SOUL_RISE), SOUL_RISE_TIME).set_ease(Tween.EASE_OUT)
	flight.tween_property(soul, "global_position", lantern_world, SOUL_FLIGHT).set_trans(Tween.TRANS_SINE)
	flight.tween_callback(soul.queue_free)
	await step(flight)
	if skipped:
		return
	# Pulsing emerald lantern flare + capture shockwave ring.
	var glow := Node2D.new()
	glow.position = Thresh.LANTERN_OFFSET
	glow.modulate.a = 0.0
	var glow_phase := [0.0]
	glow.draw.connect(_draw_glow.bind(glow, glow_phase))
	thresh.visuals.add_child(glow)
	var light_up := animate().set_parallel()
	light_up.tween_property(glow, "modulate:a", 1.0, LANTERN_LIGHT_TIME)
	if Juice.on():
		light_up.tween_method(func(t: float) -> void:
			if is_instance_valid(glow):
				glow_phase[0] = t
				glow.queue_redraw(), 0.0, 1.0, LANTERN_LIGHT_TIME + CAPTION_TIME)
	var capture_ring := Node2D.new()
	capture_ring.draw.connect(_draw_capture_ring.bind(capture_ring))
	add_prop(capture_ring)
	capture_ring.global_position = lantern_world
	var flare := animate().set_parallel()
	flare.tween_property(capture_ring, "scale", Vector2.ONE * 2.5, LANTERN_LIGHT_TIME).set_ease(Tween.EASE_OUT)
	flare.tween_property(capture_ring, "modulate:a", 0.0, LANTERN_LIGHT_TIME)
	await caption("Thresh", Lang.t("Your light is mine now."))
	if skipped:
		return
	# He sinks into the river: 3 staggered water-ripple rings + ghostly green river mist.
	chain.queue_free()
	var sink := animate().set_parallel()
	sink.tween_property(thresh.visuals, "scale", Vector2.ONE * SUNK_SCALE, SINK_TIME).set_ease(Tween.EASE_IN)
	sink.tween_property(thresh, "modulate:a", 0.0, SINK_TIME)
	for i in 3:
		var delay := i * 0.22
		var dur := SINK_TIME - delay
		var ring := Node2D.new()
		ring.scale = Vector2.ONE * (0.45 + i * 0.1)
		ring.modulate.a = 0.0
		ring.draw.connect(_draw_ring.bind(ring, i))
		add_prop(ring)
		ring.global_position = thresh.global_position
		sink.tween_property(ring, "modulate:a", 0.9, 0.08).set_delay(delay)
		sink.tween_property(ring, "scale", Vector2.ONE * (RING_GROWTH + i * 0.35), dur).set_delay(delay).set_ease(Tween.EASE_OUT)
		sink.tween_property(ring, "modulate:a", 0.0, maxf(dur - 0.08, 0.1)).set_delay(delay + 0.08)
	if Juice.on():
		for i in 6:
			var mist := Node2D.new()
			var radius := 24.0 + (i % 3) * 10.0
			mist.draw.connect(_draw_river_mist.bind(mist, radius))
			add_prop(mist)
			var angle := TAU * i / 6.0 + 0.3
			var start_at := thresh.global_position + Vector2.from_angle(angle) * 28.0
			mist.global_position = start_at
			mist.scale = Vector2.ONE * 0.55
			var mist_delay := (i % 3) * 0.12
			var mist_dur := SINK_TIME - mist_delay
			sink.tween_property(mist, "global_position", start_at + Vector2(cos(angle) * 38.0, -56.0 - (i % 2) * 22.0), mist_dur).set_delay(mist_delay).set_ease(Tween.EASE_OUT)
			sink.tween_property(mist, "scale", Vector2.ONE * 1.45, mist_dur).set_delay(mist_delay)
			sink.tween_property(mist, "modulate:a", 0.0, mist_dur).set_delay(mist_delay)
	await step(sink)
	if skipped:
		return
	# Lucian goes to her; her body fades.
	await pan_to(lucian.global_position)
	if skipped:
		return
	var kneel := caught + caught.direction_to(lucian.global_position) * KNEEL_GAP
	lucian.visuals.face(caught - lucian.global_position)
	var fade := animate().set_parallel()
	fade.tween_property(senna, "modulate:a", 0.0, WALK_TIME)
	fade.tween_property(stage.camera, "global_position", kneel, WALK_TIME)
	await move(lucian, kneel, WALK_TIME)
	if skipped:
		return
	# Her gun in his other hand: two guns from now on, with a warm gold-and-teal light shimmer.
	lucian.one_gun = false
	_spawn_gun_shimmer(lucian.global_position)
	await caption("", Lang.t("Lucian takes up Senna's gun."))


## Crisp warm gold-and-teal light flash shimmer around Lucian when he claims Senna's gun.
func _spawn_gun_shimmer(at: Vector2) -> void:
	var shimmer := Node2D.new()
	var progress := [0.0]
	shimmer.draw.connect(_draw_gun_shimmer.bind(shimmer, progress))
	add_prop(shimmer)
	shimmer.global_position = at
	var anim := animate()
	anim.tween_method(func(t: float) -> void:
		if is_instance_valid(shimmer):
			progress[0] = t
			shimmer.queue_redraw(), 0.0, 1.0, 0.75)
	anim.tween_callback(shimmer.queue_free)


func _draw_hook_chain(node: Node2D, state: Array) -> void:
	var tip: Vector2 = state[0]
	var length := tip.length()
	if length < 2.0:
		return
	var dir := tip / length
	var perp := dir.orthogonal()
	# Spectral green aura along the chain.
	node.draw_line(Vector2.ZERO, tip, Color(Thresh.CHAIN_COLOR, 0.22), CHAIN_WIDTH * 2.2, true)
	# Linked iron chain segments up to the scythe collar.
	var shaft_len := maxf(length - 14.0, 0.0)
	var dist := 6.0
	var index := 0
	while dist < shaft_len:
		var seg_end := minf(dist + CHAIN_LINK_STEP * 0.78, shaft_len)
		var p0 := dir * dist
		var p1 := dir * seg_end
		var mid := (p0 + p1) * 0.5
		if index % 2 == 0:
			# Wide forged oval link.
			var hw := 5.2
			var hl := (seg_end - dist) * 0.55
			var ring := PackedVector2Array([
				mid - dir * hl - perp * (hw * 0.55),
				mid - dir * (hl * 0.45) - perp * hw,
				mid + dir * (hl * 0.45) - perp * hw,
				mid + dir * hl - perp * (hw * 0.55),
				mid + dir * hl + perp * (hw * 0.55),
				mid + dir * (hl * 0.45) + perp * hw,
				mid - dir * (hl * 0.45) + perp * hw,
				mid - dir * hl + perp * (hw * 0.55),
				mid - dir * hl - perp * (hw * 0.55),
			])
			node.draw_polyline(ring, CHAIN_IRON, 4.2, true)
			node.draw_polyline(ring, CHAIN_STEEL, 2.2, true)
			node.draw_line(mid - dir * (hl * 0.45) - perp * (hw - 0.5), mid + dir * (hl * 0.45) - perp * (hw - 0.5), Color(CHAIN_EDGE, 0.85), 1.4, true)
		else:
			# Edge-on connecting link bar.
			node.draw_line(p0 - dir * 2.0, p1 + dir * 2.0, CHAIN_IRON, 5.2, true)
			node.draw_line(p0 - dir * 1.5, p1 + dir * 1.5, CHAIN_STEEL, 2.8, true)
			node.draw_line(p0, p1, Color(CHAIN_EDGE, 0.75), 1.2, true)
		dist += CHAIN_LINK_STEP
		index += 1
	# Curved spectral scythe-hook head at `tip`.
	var collar := tip - dir * 12.0
	node.draw_circle(collar, 6.5, CHAIN_IRON)
	node.draw_circle(collar, 4.2, CHAIN_STEEL)
	var blade_outer := PackedVector2Array([
		collar - perp * 4.5,
		tip + dir * 10.0 - perp * 11.0,
		tip + dir * 20.0 + perp * 4.0,
		tip + dir * 14.0 + perp * 22.0,
		tip - dir * 4.0 + perp * 28.0,
		tip - dir * 11.0 + perp * 18.0,
		tip + dir * 3.0 + perp * 15.0,
		tip + dir * 9.0 + perp * 3.0,
		collar + perp * 4.0,
	])
	node.draw_colored_polygon(blade_outer, CHAIN_IRON)
	var blade_steel := PackedVector2Array([
		collar - perp * 2.5,
		tip + dir * 9.0 - perp * 8.0,
		tip + dir * 17.5 + perp * 4.0,
		tip + dir * 12.0 + perp * 19.5,
		tip - dir * 3.0 + perp * 25.0,
		tip + dir * 5.0 + perp * 14.0,
		tip + dir * 10.5 + perp * 3.0,
		collar + perp * 2.0,
	])
	node.draw_colored_polygon(blade_steel, CHAIN_STEEL)
	# Gleaming spectral inner edge & tip flare.
	var gleam := PackedVector2Array([
		tip + dir * 16.0 + perp * 5.0,
		tip + dir * 11.0 + perp * 19.0,
		tip - dir * 3.5 + perp * 26.5,
		tip - dir * 10.5 + perp * 18.5,
	])
	node.draw_polyline(gleam, Color(CHAIN_EDGE, 0.45), 6.0, true)
	node.draw_polyline(gleam, Color(CHAIN_EDGE, 0.95), 2.2, true)
	var hook_tip := tip - dir * 10.5 + perp * 18.5
	MapArt.glow(node, hook_tip, 14.0, Color(CHAIN_EDGE, 0.55))
	node.draw_circle(hook_tip, 3.0, Color.WHITE)


func _draw_soul(soul: Node2D, trail: Array[Vector2], state: Array) -> void:
	var phase: float = state[0]
	var heading: Vector2 = state[1]
	if heading.length_squared() < 0.01:
		heading = Vector2.UP
	var perp := heading.orthogonal()
	# Trailing ethereal teal light ribbons along recent flight path.
	if trail.size() >= 2:
		for ribbon in 2:
			var side := -1.0 if ribbon == 0 else 1.0
			var pts := PackedVector2Array()
			for i in trail.size():
				var share := float(i) / maxf(trail.size() - 1, 1)
				var local_pt := soul.to_local(trail[i])
				var wave := sin(phase * 14.0 + i * 0.9 + ribbon * PI) * (1.0 - share) * 9.0
				pts.append(local_pt + perp * (side * (1.0 - share) * 6.0 + wave))
			for i in pts.size() - 1:
				var share := float(i + 1) / pts.size()
				var width := 1.5 + 5.5 * share
				soul.draw_line(pts[i], pts[i + 1], Color(SOUL_RIBBON, 0.16 * share), width * 2.2, true)
				soul.draw_line(pts[i], pts[i + 1], Color(SOUL_COLOR, 0.55 * share), width * 0.7, true)
	# Layered luminous halo.
	MapArt.glow(soul, Vector2.ZERO, 38.0, Color(SOUL_GLOW, 0.32))
	MapArt.glow(soul, Vector2.ZERO, 22.0, Color(SOUL_GLOW, 0.55))
	# Luminous teardrop soul-wisp core.
	var tail := -heading
	var teardrop := PackedVector2Array([
		heading * 14.0,
		heading * 6.0 + perp * 9.5,
		-heading * 4.0 + perp * 7.0,
		tail * 22.0,
		-heading * 4.0 - perp * 7.0,
		heading * 6.0 - perp * 9.5,
	])
	soul.draw_colored_polygon(teardrop, Color(SOUL_RIBBON, 0.85))
	var inner_drop := PackedVector2Array([
		heading * 10.0,
		heading * 4.0 + perp * 6.0,
		-heading * 3.0 + perp * 4.0,
		tail * 12.0,
		-heading * 3.0 - perp * 4.0,
		heading * 4.0 - perp * 6.0,
	])
	soul.draw_colored_polygon(inner_drop, SOUL_COLOR)
	soul.draw_circle(heading * 2.0, 4.5, Color.WHITE)
	# Orbiting sparkle motes.
	if Juice.on():
		for i in 4:
			var angle := phase * TAU * 2.4 + TAU * i / 4.0
			var orbit := Vector2(cos(angle) * 20.0, sin(angle) * 14.0).rotated(heading.angle())
			var sz := 3.5 + 1.5 * sin(phase * 18.0 + i * 2.1)
			_draw_sparkle(soul, orbit, sz, Color(SOUL_COLOR, 0.9))


func _draw_glow(glow: Node2D, phase_state: Array) -> void:
	var pulse := 0.88 + 0.18 * sin(phase_state[0] * TAU * 4.5)
	MapArt.glow(glow, Vector2.ZERO, 44.0 * pulse, Color(LANTERN_GLOW, 0.42))
	MapArt.glow(glow, Vector2.ZERO, 24.0 * pulse, Color(Thresh.CHAIN_COLOR, 0.65))
	_draw_sparkle(glow, Vector2.ZERO, 20.0 * pulse, Color(LANTERN_CORE, 0.85))
	glow.draw_circle(Vector2.ZERO, 8.5 * pulse, LANTERN_CORE)


func _draw_capture_ring(ring: Node2D) -> void:
	ring.draw_arc(Vector2.ZERO, 26.0, 0.0, TAU, 44, Color(Thresh.CHAIN_COLOR, 0.35), 9.0, true)
	ring.draw_arc(Vector2.ZERO, 26.0, 0.0, TAU, 44, Color(LANTERN_CORE, 0.9), 3.0, true)


func _draw_ring(ring: Node2D, index: int) -> void:
	var r := RING_RADIUS + index * 4.0
	ring.draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(RING_COLOR, 0.28), 8.0, true)
	ring.draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(RING_COLOR, 0.85), 3.2, true)
	ring.draw_arc(Vector2.ZERO, r * 0.78, 0.0, TAU, 40, Color(Thresh.CHAIN_COLOR, 0.45), 1.8, true)


func _draw_river_mist(mist: Node2D, radius: float) -> void:
	MapArt.glow(mist, Vector2.ZERO, radius * 1.4, Color(RIVER_MIST, 0.34))
	MapArt.soft_oval(mist, Vector2(-radius * 0.25, -radius * 0.12), Vector2(radius * 0.95, radius * 0.65), Color(Thresh.CHAIN_COLOR, 0.32))
	MapArt.soft_oval(mist, Vector2(radius * 0.28, radius * 0.1), Vector2(radius * 0.75, radius * 0.55), Color(LANTERN_CORE, 0.2))


func _draw_gun_shimmer(shimmer: Node2D, progress: Array) -> void:
	var t: float = progress[0]
	var fade := clampf(1.0 - t, 0.0, 1.0)
	var ease_out := 1.0 - pow(1.0 - t, 3.0)
	# Warm gold and teal converging/expanding Sentinel shimmer.
	MapArt.glow(shimmer, Vector2.ZERO, 34.0 + 42.0 * ease_out, Color(CLAIM_GOLD, 0.38 * fade))
	MapArt.glow(shimmer, Vector2.ZERO, 24.0 + 30.0 * ease_out, Color(CLAIM_TEAL, 0.32 * fade))
	shimmer.draw_arc(Vector2.ZERO, 18.0 + 58.0 * ease_out, 0.0, TAU, 48, Color(CLAIM_GOLD, 0.85 * fade), 3.5 * fade + 1.0, true)
	shimmer.draw_arc(Vector2.ZERO, 12.0 + 44.0 * ease_out, 0.0, TAU, 48, Color(CLAIM_TEAL, 0.8 * fade), 2.5 * fade + 0.8, true)
	_draw_sparkle(shimmer, Vector2.ZERO, (28.0 + 18.0 * ease_out) * fade, Color(1.0, 0.98, 0.85, 0.9 * fade))
	if Juice.on():
		for i in 6:
			var angle := TAU * i / 6.0 + t * 1.4
			var dist := 16.0 + 44.0 * ease_out
			var at := Vector2(cos(angle) * dist, sin(angle) * dist * 0.7 - t * 28.0)
			var color := CLAIM_GOLD if i % 2 == 0 else CLAIM_TEAL
			_draw_sparkle(shimmer, at, 6.0 * fade, Color(color, 0.9 * fade))


static func _draw_sparkle(canvas: CanvasItem, at: Vector2, size: float, color: Color) -> void:
	if size <= 0.4:
		return
	var narrow := size * 0.24
	var star := PackedVector2Array([
		at + Vector2(0, -size),
		at + Vector2(narrow, -narrow),
		at + Vector2(size, 0),
		at + Vector2(narrow, narrow),
		at + Vector2(0, size),
		at + Vector2(-narrow, narrow),
		at + Vector2(-size, 0),
		at + Vector2(-narrow, -narrow),
	])
	canvas.draw_colored_polygon(star, color)

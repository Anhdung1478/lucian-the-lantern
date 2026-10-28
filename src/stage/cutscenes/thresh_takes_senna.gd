class_name ThreshTakesSenna
extends Cutscene
## Act 1's end: Thresh hooks Senna, pulls her in and takes her soul into his
## lantern, then sinks into the river. Lucian goes to her and takes up her
## gun. The stage frees Thresh and Senna when it is done. The camera frames
## the hook's whole flight, then follows Senna in to Thresh.

const CHAIN_WIDTH := 6.0
const CHAIN_TIME := 0.35
## Senna is pulled in to this far in front of Thresh.
const CATCH_GAP := 100.0
const PULL_TIME := 0.5
## Senna after the hook: grey, tipped over.
const FALLEN_TINT := Color(0.55, 0.57, 0.6)
const FALLEN_TILT := 1.4
const SOUL_COLOR := Color("e8fffa")
const SOUL_GLOW := Color(0.5, 1.0, 0.9, 0.45)
const SOUL_RISE := 70.0
const SOUL_RISE_TIME := 0.4
const SOUL_FLIGHT := 1.2
const LANTERN_GLOW := Color(0.45, 1.0, 0.6, 0.5)
const LANTERN_LIGHT_TIME := 0.5
const SINK_TIME := 1.2
## Thresh's size when he is gone under the water.
const SUNK_SCALE := 0.3
const RING_COLOR := Color(0.75, 0.95, 1.0, 0.85)
const RING_RADIUS := 50.0
const RING_GROWTH := 2.4
const WALK_TIME := 1.0
## Lucian stops this short of Senna.
const KNEEL_GAP := 60.0


func _play() -> void:
	var thresh := stage.boss_unit as Thresh
	var senna := stage.senna
	var lucian := stage.lucian
	# The last hit's flash froze with him.
	thresh.visuals.modulate = Color.WHITE
	await pan_to((thresh.global_position + senna.global_position) * 0.5)
	if skipped:
		return
	await caption("Thresh", "Such a bright soul... it will make a fine light.")
	if skipped:
		return
	# The hook flies to Senna.
	thresh.face(senna.global_position)
	var chain := Line2D.new()
	chain.width = CHAIN_WIDTH
	chain.default_color = Thresh.CHAIN_COLOR
	chain.points = PackedVector2Array([Vector2.ZERO, Vector2.ZERO])
	add_prop(chain)
	chain.global_position = thresh.global_position
	var chain_end := func(point: Vector2) -> void: chain.set_point_position(1, point - chain.global_position)
	var throw := animate()
	throw.tween_method(chain_end, thresh.global_position, senna.global_position, CHAIN_TIME)
	Sfx.play(&"hook")
	await step(throw)
	if skipped:
		return
	await caption("Lucian", "SENNA!")
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
	# Her soul flies into his lantern, and it lights up.
	var soul := Node2D.new()
	soul.draw.connect(_draw_soul.bind(soul))
	add_prop(soul)
	soul.global_position = caught
	var flight := animate()
	flight.tween_property(soul, "global_position", caught + Vector2(0, -SOUL_RISE), SOUL_RISE_TIME).set_ease(Tween.EASE_OUT)
	flight.tween_property(soul, "global_position", thresh.global_position + Thresh.LANTERN_OFFSET.rotated(thresh.visuals.rotation), SOUL_FLIGHT).set_trans(Tween.TRANS_SINE)
	flight.tween_callback(soul.queue_free)
	await step(flight)
	if skipped:
		return
	var glow := Node2D.new()
	glow.position = Thresh.LANTERN_OFFSET
	glow.modulate.a = 0.0
	glow.draw.connect(_draw_glow.bind(glow))
	thresh.visuals.add_child(glow)
	animate().tween_property(glow, "modulate:a", 1.0, LANTERN_LIGHT_TIME)
	await caption("Thresh", "Your light is mine now.")
	if skipped:
		return
	# He sinks into the river.
	chain.queue_free()
	var ring := Node2D.new()
	ring.draw.connect(_draw_ring.bind(ring))
	add_prop(ring)
	ring.global_position = thresh.global_position
	var sink := animate().set_parallel()
	sink.tween_property(thresh.visuals, "scale", Vector2.ONE * SUNK_SCALE, SINK_TIME).set_ease(Tween.EASE_IN)
	sink.tween_property(thresh, "modulate:a", 0.0, SINK_TIME)
	sink.tween_property(ring, "scale", Vector2.ONE * RING_GROWTH, SINK_TIME)
	sink.tween_property(ring, "modulate:a", 0.0, SINK_TIME)
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
	await caption("", "Lucian takes up Senna's gun. Relentless Pursuit (E) is now free in the Evolution Tree.")


func _draw_soul(soul: Node2D) -> void:
	soul.draw_circle(Vector2.ZERO, 22.0, SOUL_GLOW)
	soul.draw_circle(Vector2.ZERO, 10.0, SOUL_COLOR)


func _draw_glow(glow: Node2D) -> void:
	glow.draw_circle(Vector2.ZERO, 26.0, LANTERN_GLOW)
	glow.draw_circle(Vector2.ZERO, 11.0, Thresh.CHAIN_COLOR)


func _draw_ring(ring: Node2D) -> void:
	ring.draw_arc(Vector2.ZERO, RING_RADIUS, 0.0, TAU, 48, RING_COLOR, 4.0, true)

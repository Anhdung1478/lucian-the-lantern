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
const SHOT_GLOW := Color(1.0, 0.9, 0.5, 0.55)
const SHOT_TIME := 0.5
const FLASH_COLOR := Color(1.0, 0.98, 0.85, 0.9)
const FLASH_RADIUS := 60.0
const FLASH_TIME := 0.3
const RING_COLOR := Color(1.0, 0.95, 0.7, 0.85)
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
const SENNA_GLOW := Color(0.4, 1.0, 0.9, 0.35)
const SENNA_TIME := 1.2
const SMOKE_COLOR := Color(0.35, 0.8, 0.45, 0.6)
const SMOKE_PUFFS := 6
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
	glow.draw.connect(_draw_circles.bind(glow, [[26.0 / ThreshFinal.LANTERN_SCALE, LANTERN_GLOW]]))
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
	await caption("Lucian", "It ends here.")
	if skipped:
		return
	# One bright shot from Lucian to the lantern.
	lucian.visuals.face(ground - lucian.global_position)
	var shot := Node2D.new()
	shot.draw.connect(_draw_circles.bind(shot, [[20.0, SHOT_GLOW], [8.0, SHOT_COLOR]]))
	add_prop(shot)
	shot.global_position = lucian.global_position
	Sfx.play(&"shot")
	await move(shot, ground, SHOT_TIME)
	if skipped:
		return
	shot.queue_free()
	# A flash and a ring burst; the lantern cracks.
	var flash := Node2D.new()
	flash.draw.connect(_draw_circles.bind(flash, [[FLASH_RADIUS, FLASH_COLOR]]))
	var ring := Node2D.new()
	ring.draw.connect(_draw_ring.bind(ring))
	for node: Node2D in [flash, ring]:
		add_prop(node)
		node.global_position = ground
	var crack := Line2D.new()
	crack.width = 4.0
	crack.default_color = CRACK_COLOR
	crack.points = PackedVector2Array([Vector2(-6, -60), Vector2(8, -20), Vector2(-8, 10), Vector2(4, 60)])
	crack.scale = Vector2.ONE / ThreshFinal.LANTERN_SCALE * 0.6
	lantern.add_child(crack)
	lantern.modulate = CRACKED_TINT
	var burst := animate().set_parallel()
	burst.tween_property(flash, "modulate:a", 0.0, FLASH_TIME)
	burst.tween_property(ring, "scale", Vector2.ONE * RING_GROWTH, FLASH_TIME * 2.0)
	burst.tween_property(ring, "modulate:a", 0.0, FLASH_TIME * 2.0)
	await step(burst)
	if skipped:
		return
	# Soul motes stream up; Senna forms beside the lantern; Thresh dissolves.
	Sfx.play(&"freed")
	var rise := animate().set_parallel()
	for i in MOTES:
		var mote := Node2D.new()
		mote.draw.connect(_draw_circles.bind(mote, [[8.0, MOTE_COLOR]]))
		add_prop(mote)
		mote.global_position = ground + Vector2(randf_range(-MOTE_SPREAD, MOTE_SPREAD), 0)
		rise.tween_property(mote, "global_position:y", ground.y - MOTE_RISE, MOTE_TIME).set_delay(i * 0.05)
		rise.tween_property(mote, "modulate:a", 0.0, MOTE_TIME).set_delay(i * 0.05)
	var senna := Node2D.new()
	var senna_glow := Node2D.new()
	senna_glow.draw.connect(_draw_circles.bind(senna_glow, [[70.0, SENNA_GLOW]]))
	senna.add_child(senna_glow)
	var art := Sprite2D.new()
	art.texture = Senna.ART
	senna.add_child(art)
	senna.modulate.a = 0.0
	add_prop(senna)
	senna.global_position = ground + SENNA_OFFSET
	rise.tween_property(senna, "modulate:a", 1.0, SENNA_TIME)
	rise.tween_property(thresh.visuals, "modulate", Color(SMOKE_COLOR, 0.0), DISSOLVE_TIME)
	rise.tween_property(thresh.visuals, "scale", KNEEL_SCALE * 1.3, DISSOLVE_TIME)
	for i in SMOKE_PUFFS:
		var puff := Node2D.new()
		puff.draw.connect(_draw_circles.bind(puff, [[30.0, SMOKE_COLOR]]))
		add_prop(puff)
		puff.global_position = thresh.global_position + Vector2.from_angle(TAU * i / SMOKE_PUFFS) * 30.0
		rise.tween_property(puff, "global_position:y", puff.global_position.y - 90.0, DISSOLVE_TIME)
		rise.tween_property(puff, "modulate:a", 0.0, DISSOLVE_TIME)
	await step(rise)
	if skipped:
		return
	await caption("Senna", "Lucian… you came.")
	if skipped:
		return
	await caption("Lucian", "Always.")
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


## `circles`: [radius, color] pairs, drawn at the node's origin in order.
func _draw_circles(node: Node2D, circles: Array) -> void:
	for circle: Array in circles:
		node.draw_circle(Vector2.ZERO, circle[0], circle[1])


func _draw_ring(ring: Node2D) -> void:
	ring.draw_arc(Vector2.ZERO, RING_RADIUS, 0.0, TAU, 48, RING_COLOR, 4.0, true)

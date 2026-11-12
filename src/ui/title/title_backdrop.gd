class_name TitleBackdrop
extends Control
## The title screen's night scene behind its centred column: the story at a
## glance. Under a teal-black sky, stars and a pale moon veiled by thin
## clouds at the upper left, Lucian and Senna's spirit (behind him, ghostly
## teal) stand at the left and face Thresh, who looms at the right with his
## green lantern held out. Behind them are the Shadow Isles, in three
## layers: far off, the isles on the horizon with a ruined tower, and a
## cliff at the right with the arches and spires of Helia on it; nearer,
## a ridge with dead trees, gravestones, and the chain from Thresh's
## lantern lying on the ground to Senna; in front of everything, grass and
## two near graves in dark silhouette at the bottom. The middle stays dark
## so the column reads.
## The figures are drawn in code (TitleLucian, TitleSenna, TitleThresh),
## each a bottom-anchored node: Lucian and Senna keep to the left edge and
## Thresh to the right one, so a wider screen only widens the gap between
## them. Hiding Thresh (as TheEndScreen does) takes his lantern's light off
## the others and leaves the chain broken on the ground.
## Everything still is painted once, in a few meshes (TitlePaint). Only
## `effects`, in front of it all, moves: ground mist drifting, green mist
## on Thresh's side, his lantern's glow breathing and souls rising from it,
## his eyes flickering, teal motes and a slow shimmer on Senna, lights
## running along the chain, Lucian's muzzle glinting and his relic gun's
## core pulsing. It moves only while the title shows, and not at all on
## low effects (GameSettings.low_effects).

## The screen the scene is laid out on. On a wider or taller one, whatever
## stands in its right half keeps to the right edge, and all but the stars
## keeps to the bottom.
const BASE := Vector2(1920, 1080)

## Each figure's place on the BASE screen: x is its outer edge's distance
## from its side (left for Lucian and Senna, right for Thresh), y its
## height and z how far its feet stand above the bottom.
const LUCIAN_PLACE := Vector3(190, 870, 14)
const SENNA_PLACE := Vector3(0, 790, 34)
const THRESH_PLACE := Vector3(40, 1010, 8)

## The colours: moonlight, Thresh's green (his lantern, the chain, the
## ruins' windows, the mist on his side), Senna's teal and Lucian's gold.
const MOONLIGHT := Color("cfe0ff")
const SOUL_COLOR := Color("8fe3b0")
const SOUL_CORE := Color("e4fff0")
const SENNA_COLOR := Color("b8fff0")
const GLINT_COLOR := Color("ffcf5a")
## The land, from far to near: the isles on the horizon and the far tower,
## the cliff and the ruins, the ridge the trees stand on, the gravestones,
## the ground, and the near silhouettes in front of the figures.
const ISLES_COLOR := Color("08191b")
const TOWER_COLOR := Color("07171a")
const CLIFF_COLOR := Color("0c1c1d")
const RUIN_COLOR := Color("0e1f21")
const RIDGE_COLOR := Color("081213")
const GRAVE_COLOR := Color("101f21")
const GROUND_TOP := Color("0a1617")
const GROUND_BOTTOM := Color("030607")
const NEAR_COLOR := Color("020505")
## The haze on the land, lighter the farther it is.
const HAZE_COLOR := Color(0.36, 0.6, 0.6)

## Stars over the sky's top part, and the few brightest with a glint
## (x and y as shares of the screen, glint size).
const STARS := 260
const BRIGHT_STARS: Array[Vector3] = [Vector3(0.08, 0.07, 9), Vector3(0.31, 0.04, 7), Vector3(0.47, 0.12, 6),
	Vector3(0.58, 0.05, 10), Vector3(0.71, 0.16, 6), Vector3(0.86, 0.06, 8), Vector3(0.95, 0.2, 6)]
## The moon: centre, radius, its lit and shaded sides, its halos (size,
## alpha), its darker seas (offset and size as shares of the radius) and
## its craters (offset, size).
const MOON_AT := Vector2(330, 170)
const MOON_RADIUS := 88.0
const MOON_LIT := Color("eef3f6")
const MOON_SHADE := Color("94a7ba")
const MOON_SIDES := 64
const MOON_HALOS: Array[Vector2] = [Vector2(1300, 0.14), Vector2(560, 0.26), Vector2(270, 0.38)]
const MOON_SEAS: Array[Vector3] = [Vector3(-0.3, -0.25, 0.8), Vector3(0.3, 0.05, 0.7), Vector3(-0.05, 0.4, 0.55), Vector3(0.35, -0.45, 0.35)]
const CRATERS: Array[Vector3] = [Vector3(-0.42, 0.12, 0.12), Vector3(0.12, -0.5, 0.08), Vector3(0.5, 0.36, 0.1), Vector3(-0.12, 0.62, 0.07), Vector3(0.2, 0.2, 0.06)]
## Thin clouds across the moon and the sky: each a row of soft puffs, from
## (x, y from the moon's centre) to (z, w), and how thick; lit on top, dark
## below.
const CLOUDS: Array[Vector4] = [Vector4(-260, 40, 170, 58), Vector4(-60, 86, 360, 104), Vector4(-330, -30, -100, -40), Vector4(150, -20, 420, -6)]
const CLOUD_THICKNESS: Array[float] = [16.0, 12.0, 9.0, 8.0]
const CLOUD_PUFFS := 7
const CLOUD_LIT := Color(0.62, 0.7, 0.8, 0.16)
const CLOUD_DARK := Color(0.02, 0.05, 0.08, 0.3)

## The horizon, where the isles stand, the ridge behind the figures and the
## ground's top edge, on the BASE screen.
const HORIZON := 830.0
const RIDGE := 935.0
const GROUND := 1005.0
## The far ruined tower on the isles left of the column: its foot (x, y),
## height and width.
const FAR_TOWER := Vector4(612, 836, 196, 40)
## The far isles' spires of rock (x, height, width).
const ROCK_SPIRES: Array[Vector3] = [Vector3(540, 120, 46), Vector3(700, 70, 30), Vector3(1010, 90, 34), Vector3(1100, 60, 26)]
## The cliff at the right: its foot on the horizon and its top's height.
const CLIFF_FOOT := 1130.0
const CLIFF_TOP := 520.0
## Helia's ruins on the cliff: spires (x, top, width), the broken ones, and
## the arcade (from x, to x, top) with its arch span and the broken arch.
const SPIRES: Array[Vector3] = [Vector3(1222, 330, 34), Vector3(1306, 240, 46), Vector3(1840, 290, 42), Vector3(1902, 380, 30)]
const BROKEN_SPIRES: Array[Vector3] = [Vector3(1376, 405, 28), Vector3(1772, 330, 30)]
const ARCADE := Vector3(1150, 1420, 438)
const ARCH_SPAN := 64.0
const BROKEN_ARCH := 2
const ARCH_PIECES := 12
## Dead trees (x, height, lean) on the ridge, and gravestones (x, y, kind:
## 0 a headstone, 1 a cross, 2 a slab; tilt), smaller the farther they are.
const TREES: Array[Vector3] = [Vector3(14, 500, -0.12), Vector3(700, 250, 0.1), Vector3(1170, 230, -0.08), Vector3(1912, 520, 0.14)]
const TREE_DEPTH := 5
const TREE_COLOR := Color("071012")
const GRAVES: Array[Vector4] = [Vector4(470, 985, 1, -0.06), Vector4(575, 1012, 0, -0.08), Vector4(650, 990, 1, 0.12),
	Vector4(712, 1022, 2, 0.05), Vector4(850, 945, 1, 0.04), Vector4(1075, 950, 0, -0.05), Vector4(1196, 1000, 0, 0.1),
	Vector4(1248, 1030, 1, -0.14), Vector4(1886, 1002, 0, 0.04)]
## Grass on the ground: tufts per 100 px, and a blade's height range.
const GRASS_STEP := 34.0
const GRASS_HEIGHT := Vector2(8, 22)
## The near layer, in front of the figures: tufts of tall grass along the
## bottom (height range), and two near graves (x, height, kind as GRAVES,
## tilt) at the corners.
const NEAR_GRASS_HEIGHT := Vector2(18, 64)
const NEAR_GRAVES: Array[Vector4] = [Vector4(70, 3.4, 0, -0.12), Vector4(1890, 3.0, 1, 0.1)]
## The dark at the bottom of the screen: how high it reaches and its alpha.
const BOTTOM_SHADE := Vector2(220, 0.55)
## The dark behind the centred column, so it reads: its size and alpha.
const SCRIM_SIZE := Vector2(1150, 1300)
const SCRIM_ALPHA := 0.62

## The chain from Thresh to Senna: its colour, link size and width, how far
## its middle sags towards the viewer, how many straight pieces draw it,
## the gap where it is broken once Thresh is gone, and the lights that run
## along it to Thresh (how many, and the share of it per second).
const CHAIN_COLOR := Color(0.5, 0.78, 0.62, 0.55)
const CHAIN_EDGE := Color(0.0, 0.02, 0.01, 0.6)
const CHAIN_LINK := 18.0
const CHAIN_WIDTH := 2.6
const CHAIN_SAG := 30.0
const CHAIN_PIECES := 24
const CHAIN_BREAK := Vector2(0.46, 0.53)
const CHAIN_LIGHTS := 3
const CHAIN_LIGHT_SPEED := 0.05

## Ground mist: its bands (y on the BASE screen, half thickness, alpha over
## MIST_COLOR's), a puff's width and the drift (px/s, right to left).
const MIST_COLOR := Color(0.6, 0.82, 0.86, 0.07)
const GROUND_MIST: Array[Vector3] = [Vector3(905, 46, 0.8), Vector3(985, 64, 1.3), Vector3(1060, 84, 2.0)]
const MIST_PUFF := 560.0
const MIST_SPEED := 16.0
## Green mist on Thresh's side (x, y, size), and its alpha.
const GREEN_MIST: Array[Vector3] = [Vector3(1250, 1010, 420), Vector3(1370, 880, 520), Vector3(1610, 990, 640),
	Vector3(1860, 870, 520), Vector3(1480, 690, 380)]
const GREEN_MIST_ALPHA := 0.08
## The lantern's glow (size), how much it breathes and how fast (rad/s).
const LANTERN_GLOW := 340.0
const LANTERN_PULSE := 0.14
const PULSE_RATE := 1.7
## Souls rising from the lantern towards the sky: how many, how high and
## how long each one rises (px, s), how wide it swirls, how far it drifts
## left on the wind and how many points its fading trail has.
const WISPS := 11
const WISP_RISE := 460.0
const WISP_LIFE := 8.0
const WISP_SWIRL := 34.0
const WISP_DRIFT := 90.0
const WISP_TRAIL := 8
## Thresh's eyes: how far their glow flickers, and how fast.
const EYE_GLOW := 26.0
const EYE_FLICKER := 7.0
## Senna's motes: how many, how far round her middle (x, y) and how fast;
## how solid she is, and her shimmer: how far her alpha dips under that,
## and how fast (rad/s).
const SENNA_MOTES := 22
const MOTE_REACH := Vector2(170, 330)
const MOTE_SPEED := 11.0
const SENNA_ALPHA := 0.88
const SHIMMER := 0.14
const SHIMMER_RATE := 0.9

## The figures, drawn in code.
var lucian := TitleLucian.new()
var senna := TitleSenna.new()
var thresh := TitleThresh.new()
## The grass and near graves in front of the figures: drawn once.
var foreground := Control.new()
## The mist, souls, motes and glows, in front of it all: the only layer
## drawn again every frame.
var effects := Control.new()

## Per wisp and per mote: random shares (0..1) for its place and phase.
var _wisp_seeds: Array[Vector3] = []
var _mote_seeds: Array[Vector3] = []
var _time := 0.0


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add_figure(senna, &"Senna", SENNA_PLACE, false)
	senna.modulate.a = SENNA_ALPHA
	_add_figure(lucian, &"Lucian", LUCIAN_PLACE, false)
	_add_figure(thresh, &"Thresh", THRESH_PLACE, true)
	thresh.visibility_changed.connect(_sync_thresh)
	for layer: Control in [foreground, effects]:
		layer.set_anchors_preset(Control.PRESET_FULL_RECT)
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(layer)
	foreground.name = &"Foreground"
	foreground.draw.connect(_draw_foreground)
	effects.name = &"Effects"
	effects.draw.connect(_draw_effects)
	var rng := _rng(40)
	for i in WISPS:
		_wisp_seeds.append(Vector3(rng.randf(), rng.randf(), (i + rng.randf() * 0.5) / WISPS))
	for i in SENNA_MOTES:
		_mote_seeds.append(Vector3(rng.randf(), rng.randf(), rng.randf()))


func _ready() -> void:
	GameSettings.instance().changed.connect(_on_setting_changed)
	_sync_thresh()
	_sync_motion()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_inside_tree():
		_sync_motion()


func _process(delta: float) -> void:
	_time += delta
	senna.modulate.a = SENNA_ALPHA - SHIMMER * (0.5 + 0.5 * sin(_time * SHIMMER_RATE))
	effects.queue_redraw()


## The effects move only while the scene shows, and never on low effects:
## then they are hidden and Senna stands still.
func _sync_motion() -> void:
	var low := GameSettings.instance().low_effects()
	effects.visible = not low
	set_process(is_visible_in_tree() and not low)
	if low:
		senna.modulate.a = SENNA_ALPHA


func _on_setting_changed(key: StringName) -> void:
	if key == &"quality":
		_sync_motion()


## Thresh shown or hidden: his lantern lights the others or not, and the
## chain lies whole or broken.
func _sync_thresh() -> void:
	lucian.lantern_lit = thresh.visible
	senna.lantern_lit = thresh.visible
	queue_redraw()


## Adds `figure`, bottom-anchored at `place` (see LUCIAN_PLACE) on the left
## or the `right` side, as wide as its art's frame allows.
func _add_figure(figure: TitleFigure, id: StringName, place: Vector3, right: bool) -> void:
	figure.name = id
	var width := figure.width_for(place.y)
	var side := 1.0 if right else 0.0
	figure.anchor_left = side
	figure.anchor_right = side
	figure.anchor_top = 1.0
	figure.anchor_bottom = 1.0
	figure.offset_left = -place.x - width if right else place.x
	figure.offset_right = figure.offset_left + width
	figure.offset_top = -place.z - place.y
	figure.offset_bottom = -place.z
	add_child(figure)


## The point at `t` (0 at Thresh, 1 at Senna) along the chain on the ground.
func _chain_point(t: float) -> Vector2:
	var from := thresh.chain_end()
	var to := senna.hem()
	var sag := (from + to) * 0.5 + Vector2(0, CHAIN_SAG)
	return from.lerp(sag, t).lerp(sag.lerp(to, t), t)


## `at` on the BASE screen, moved with the edge it keeps to: the right one
## for the right half, and the bottom.
func _place(at: Vector2) -> Vector2:
	var x := at.x + (size.x - BASE.x if at.x > BASE.x * 0.5 else 0.0)
	return Vector2(x, at.y + size.y - BASE.y)


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var rect := Rect2(Vector2.ZERO, size)
	MainBackdrop.draw_sky(self, rect)
	MainBackdrop.draw_stars(self, rect, _rng(1), STARS)
	var glow := JourneyMap.glow()
	var moon := _place(MOON_AT)
	for halo in MOON_HALOS:
		draw_texture_rect(glow, Rect2(moon - Vector2.ONE * halo.x * 0.5, Vector2.ONE * halo.x), false, Color(MOONLIGHT, halo.y))
	# The green of the isles on the right, under the moonlit left.
	draw_texture_rect(glow, Rect2(_place(Vector2(1560, 760)) - Vector2(900, 600), Vector2(1800, 1200)), false, Color(SOUL_COLOR, 0.07))
	var paint := TitlePaint.new()
	_paint_sky(paint, moon)
	_paint_far(paint, _rng(2))
	_paint_ruins(paint)
	_paint_middle(paint)
	paint.draw(self)
	draw_texture_rect(glow, Rect2(size * 0.5 - SCRIM_SIZE * 0.5, SCRIM_SIZE), false, Color(0, 0, 0, SCRIM_ALPHA))


## The brightest stars with their glints, the moon and the thin clouds
## across it.
func _paint_sky(paint: TitlePaint, moon: Vector2) -> void:
	for star in BRIGHT_STARS:
		var at := Vector2(star.x * size.x, star.y * BASE.y)
		paint.glow(at, Vector2.ONE * star.z, Color(MOONLIGHT, 0.35))
		paint.line(at - Vector2(star.z, 0), at + Vector2(star.z, 0), 1.0, Color(MOONLIGHT, 0.5))
		paint.line(at - Vector2(0, star.z), at + Vector2(0, star.z), 1.0, Color(MOONLIGHT, 0.5))
		paint.oval(at, Vector2(1.4, 1.4), MOONLIGHT, 0.0, 8)
	var disc := TitlePaint.oval_outline(moon, Vector2.ONE * MOON_RADIUS, 0.0, MOON_SIDES)
	var light := Vector2(-1, -1).normalized()
	paint.shape(disc, TitlePaint.linear(moon + light * MOON_RADIUS, moon - light * MOON_RADIUS, MOON_LIT, MOON_SHADE))
	for sea in MOON_SEAS:
		paint.glow(moon + Vector2(sea.x, sea.y) * MOON_RADIUS, Vector2.ONE * MOON_RADIUS * sea.z * 0.5, Color(MOON_SHADE.darkened(0.15), 0.45))
	for crater in CRATERS:
		var at := moon + Vector2(crater.x, crater.y) * MOON_RADIUS
		var radius := crater.z * MOON_RADIUS
		paint.oval(at, Vector2.ONE * radius, Color(MOON_SHADE.darkened(0.2), 0.5), 0.0, 14)
		paint.rim(TitlePaint.oval_outline(at, Vector2.ONE * radius, 0.0, 14), -light * radius * 0.3, Color(MOON_LIT, 0.6))
	# The far side darkens towards the edge; the lit edge is bright.
	paint.rim(disc, -light * MOON_RADIUS * 0.22, Color(MOON_SHADE.darkened(0.3), 0.45))
	paint.rim(disc, light * 2.5, Color(1, 1, 1, 0.55))
	var rng := _rng(4)
	for k in CLOUDS.size():
		var from := moon + Vector2(CLOUDS[k].x, CLOUDS[k].y)
		var to := moon + Vector2(CLOUDS[k].z, CLOUDS[k].w)
		var thick := CLOUD_THICKNESS[k]
		for i in CLOUD_PUFFS:
			var at := from.lerp(to, (i + rng.randf()) / CLOUD_PUFFS)
			var reach := Vector2(from.distance_to(to) / CLOUD_PUFFS * rng.randf_range(0.9, 1.6), thick * rng.randf_range(0.6, 1.3))
			paint.glow(at + Vector2(0, reach.y * 0.7), reach, CLOUD_DARK)
			paint.glow(at, reach, CLOUD_LIT)


## The far layer: the isles on the horizon with their spires of rock, the
## ruined tower left of the column, the haze over them, and the cliff at
## the right.
func _paint_far(paint: TitlePaint, rng: RandomNumberGenerator) -> void:
	var horizon := _place(Vector2(0, HORIZON)).y
	var isles := _skyline(horizon, Vector2(12, 90), Vector2(30, 90), rng)
	for spire in ROCK_SPIRES:
		var foot := _place(Vector2(spire.x, HORIZON + 10.0))
		paint.shape(PackedVector2Array([foot + Vector2(-spire.z, 0), foot + Vector2(-spire.z * 0.3, -spire.y * 0.7),
			foot + Vector2(-spire.z * 0.05, -spire.y), foot + Vector2(spire.z * 0.25, -spire.y * 0.62), foot + Vector2(spire.z, 0)]), ISLES_COLOR)
	paint.shape(isles, ISLES_COLOR)
	_paint_far_tower(paint)
	_band(paint, horizon - 10.0, 70.0, Color(HAZE_COLOR, 0.14))
	# The cliff: a steep face from its foot, then a broken top to the edge.
	var foot := _place(Vector2(CLIFF_FOOT, HORIZON + 20.0))
	var top := _place(Vector2(CLIFF_FOOT + 80.0, CLIFF_TOP)).y
	var cliff := PackedVector2Array([foot])
	for k in 6:
		var t := (k + 1) / 6.0
		cliff.append(Vector2(foot.x + t * 80.0 + rng.randf_range(-10.0, 10.0), lerpf(foot.y, top, t)))
	var x := foot.x + 90.0
	while x < size.x:
		cliff.append(Vector2(x, top + rng.randf_range(-14.0, 22.0)))
		x += rng.randf_range(26.0, 60.0)
	cliff.append(Vector2(size.x, top))
	cliff.append(Vector2(size.x, horizon + 40.0))
	cliff.append(Vector2(foot.x, horizon + 40.0))
	paint.shape(cliff, TitlePaint.linear(Vector2(0, top), Vector2(0, horizon), CLIFF_COLOR.lightened(0.04), CLIFF_COLOR))
	# Moonlight along its face, and its ledges.
	paint.taper(cliff.slice(0, 7), 2.4, 1.0, Color(MOONLIGHT, 0.2))
	for k in 4:
		var y := lerpf(top, horizon, (k + 1) / 5.0)
		var from := foot.x + 80.0 * (1.0 - (y - top) / (foot.y - top)) + 6.0
		paint.taper(PackedVector2Array([Vector2(from, y), Vector2(from + 60.0 + k * 20.0, y + 8.0)]), 1.6, 0.0, Color(MOONLIGHT, 0.08))


## The ruined tower far off on the isles: a broken top, a ledge, moonlight
## on its left and one window lit faint green.
func _paint_far_tower(paint: TitlePaint) -> void:
	var foot := _place(Vector2(FAR_TOWER.x, FAR_TOWER.y))
	var half := FAR_TOWER.w * 0.5
	var height := FAR_TOWER.z
	var tower := PackedVector2Array([foot + Vector2(-half - 8.0, 0), foot + Vector2(-half, -height * 0.8), foot + Vector2(-half * 0.6, -height * 0.86),
		foot + Vector2(-half * 0.2, -height), foot + Vector2(half * 0.15, -height * 0.9), foot + Vector2(half * 0.5, -height * 0.94),
		foot + Vector2(half, -height * 0.72), foot + Vector2(half + 6.0, 0)])
	paint.shape(tower, TOWER_COLOR)
	paint.rim(tower, Vector2(-2.0, -1.0), Color(MOONLIGHT, 0.18))
	paint.line(foot + Vector2(-half - 3.0, -height * 0.5), foot + Vector2(half + 3.0, -height * 0.5), 4.0, TOWER_COLOR)
	paint.shape(TitlePaint.oval_outline(foot + Vector2(0, -height * 0.62), Vector2(2.6, 6.0), 0.0, 10), Color(SOUL_COLOR, 0.4))


## Helia's ruins on the cliff top: the arcade, then the spires, whole and
## broken.
func _paint_ruins(paint: TitlePaint) -> void:
	var base := _place(Vector2(BASE.x, CLIFF_TOP + 12.0)).y
	var from := _place(Vector2(ARCADE.x, ARCADE.z))
	var top := from.y
	var radius := ARCH_SPAN * 0.5
	var spring := top + 16.0 + radius
	var arches := int((ARCADE.y - ARCADE.x) / ARCH_SPAN)
	var rim := Color(MOONLIGHT, 0.16)
	for i in arches + 1:
		var x := from.x + i * ARCH_SPAN
		paint.shape(PackedVector2Array([Vector2(x - 7.0, spring), Vector2(x + 7.0, spring), Vector2(x + 7.0, base), Vector2(x - 7.0, base)]), RUIN_COLOR)
		paint.line(Vector2(x - 7.0, spring), Vector2(x - 7.0, base), 1.5, rim)
	for i in arches:
		var center := Vector2(from.x + (i + 0.5) * ARCH_SPAN, spring)
		var reach := PI if i != BROKEN_ARCH else PI * 0.45
		paint.taper(_arc(center, radius - 2.0, PI, PI + reach), 10.0, 10.0, RUIN_COLOR)
		paint.taper(_arc(center, radius + 3.0, PI, PI + reach * 0.6), 1.5, 1.5, rim)
		if i != BROKEN_ARCH:
			paint.shape(PackedVector2Array([Vector2(center.x - radius, top), Vector2(center.x + radius, top),
				Vector2(center.x + radius, top + 16.0), Vector2(center.x - radius, top + 16.0)]), RUIN_COLOR)
			paint.line(Vector2(center.x - radius, top), Vector2(center.x + radius, top), 1.5, rim)
	for spire in SPIRES:
		_paint_spire(paint, _place(Vector2(spire.x, spire.y)), spire.z, base, false)
	for spire in BROKEN_SPIRES:
		_paint_spire(paint, _place(Vector2(spire.x, spire.y)), spire.z, base, true)


## A spire from `base` up to `top` (its point), `width` wide: a tower with a
## ledge, a pointed roof (or a broken top), moonlight on its left and two
## windows with a faint green light.
func _paint_spire(paint: TitlePaint, top: Vector2, width: float, base: float, broken: bool) -> void:
	var half := width * 0.5
	var shoulder := top.y + width * 1.8
	var rim := Color(MOONLIGHT, 0.18)
	paint.shape(PackedVector2Array([Vector2(top.x - half, shoulder), Vector2(top.x + half, shoulder), Vector2(top.x + half, base), Vector2(top.x - half, base)]), RUIN_COLOR)
	paint.line(Vector2(top.x - half - 4.0, shoulder + 3.5), Vector2(top.x + half + 4.0, shoulder + 3.5), 7.0, RUIN_COLOR)
	if broken:
		paint.shape(PackedVector2Array([Vector2(top.x - half, shoulder), Vector2(top.x - half, top.y + width * 0.5),
			Vector2(top.x - half * 0.3, top.y + width), Vector2(top.x + half * 0.2, top.y), Vector2(top.x + half * 0.5, top.y + width * 0.9),
			Vector2(top.x + half, top.y + width * 0.6), Vector2(top.x + half, shoulder)]), RUIN_COLOR)
	else:
		paint.shape(PackedVector2Array([Vector2(top.x - half - 5.0, shoulder), top, Vector2(top.x + half + 5.0, shoulder)]), RUIN_COLOR)
		paint.line(Vector2(top.x - half - 5.0, shoulder), top, 1.5, rim)
	paint.line(Vector2(top.x - half, shoulder + 7.0), Vector2(top.x - half, base), 1.5, rim)
	for k in 2:
		var window := shoulder + 34.0 + k * 64.0
		if window + 15.0 < base:
			paint.shape(PackedVector2Array([Vector2(top.x - 2.5, window + 15.0), Vector2(top.x - 2.5, window + 3.0), Vector2(top.x, window),
				Vector2(top.x + 2.5, window + 3.0), Vector2(top.x + 2.5, window + 15.0)]), Color(SOUL_COLOR, 0.4))


## The middle layer: the ridge with its dead trees, the haze over it, the
## ground with its grass, the gravestones and the chain.
func _paint_middle(paint: TitlePaint) -> void:
	var rng := _rng(3)
	paint.shape(_skyline(_place(Vector2(0, RIDGE)).y, Vector2(0, 40), Vector2(120, 260), rng), RIDGE_COLOR)
	for tree in TREES:
		_paint_limb(paint, _place(Vector2(tree.x, RIDGE + 6.0)), -PI * 0.5 + tree.z, tree.y * 0.4, maxf(tree.y * 0.05, 4.0), 0, rng)
	_band(paint, _place(Vector2(0, RIDGE)).y + 10.0, 50.0, Color(HAZE_COLOR, 0.08))
	_paint_ground(paint, rng)
	for grave in GRAVES:
		var at := _place(Vector2(grave.x, grave.y))
		var shrink := lerpf(0.55, 1.0, clampf(inverse_lerp(_place(Vector2(0, HORIZON)).y, size.y, at.y), 0.0, 1.0))
		_paint_grave(paint, at, int(grave.z), grave.w, shrink, GRAVE_COLOR, Color(MOONLIGHT, 0.3))
	_paint_chain(paint)


## A limb of a dead tree from `from`, forking TREE_DEPTH times.
func _paint_limb(paint: TitlePaint, from: Vector2, angle: float, length: float, width: float, depth: int, rng: RandomNumberGenerator) -> void:
	var bend := rng.randf_range(-0.4, 0.4)
	var middle := from + Vector2.from_angle(angle) * length * 0.5
	var to := middle + Vector2.from_angle(angle + bend) * length * 0.5
	paint.taper(PackedVector2Array([from, middle, to]), width, width * 0.62, TREE_COLOR)
	if depth >= TREE_DEPTH:
		return
	var limbs := 2 if depth < 2 else rng.randi_range(1, 3)
	for k in limbs:
		var spread := rng.randf_range(0.3, 0.85) * (1.0 if (k + depth) % 2 == 0 else -1.0)
		_paint_limb(paint, to, angle + bend + spread, length * rng.randf_range(0.55, 0.78), width * 0.62, depth + 1, rng)


## The near ground: a dark band with a soft, uneven top edge and tufts of
## grass along it.
func _paint_ground(paint: TitlePaint, rng: RandomNumberGenerator) -> void:
	var top := _place(Vector2(0, GROUND)).y
	var edge := PackedVector2Array()
	var x := 0.0
	while x < size.x + 40.0:
		edge.append(Vector2(x, _ground_y(x, top)))
		x += 40.0
	var ground := edge.duplicate()
	ground.append(Vector2(size.x, size.y))
	ground.append(Vector2(0, size.y))
	paint.shape(ground, TitlePaint.linear(Vector2(0, top), Vector2(0, size.y), GROUND_TOP, GROUND_BOTTOM))
	x = 0.0
	while x < size.x:
		_tuft(paint, Vector2(x, _ground_y(x, top) + 2.0), rng.randf_range(GRASS_HEIGHT.x, GRASS_HEIGHT.y), GROUND_TOP, rng)
		x += rng.randf_range(GRASS_STEP * 0.5, GRASS_STEP * 1.5)


## The ground's top edge at `x`.
static func _ground_y(x: float, top: float) -> float:
	return top + sin(x * 0.005) * 10.0 + sin(x * 0.013) * 5.0


## A tuft of grass at `root`, `height` tall: a few blades fanning out.
static func _tuft(paint: TitlePaint, root: Vector2, height: float, color: Color, rng: RandomNumberGenerator) -> void:
	for k in 4:
		var lean := rng.randf_range(-0.5, 0.5) + (k - 1.5) * 0.18
		var tip := root + Vector2(sin(lean), -cos(lean)) * height * rng.randf_range(0.6, 1.0)
		var bend := root.lerp(tip, 0.5) + Vector2(lean * height * 0.2, 0)
		paint.taper(PackedVector2Array([root, bend, tip]), height * 0.09, 0.0, color)


## A gravestone of `kind` (see GRAVES) at `at`, tilted by `tilt` and
## scaled by `shrink`, with moonlight on its top and left.
static func _paint_grave(paint: TitlePaint, at: Vector2, kind: int, tilt: float, shrink: float, color: Color, rim: Color) -> void:
	var place := Transform2D(tilt, Vector2.ONE * shrink, 0.0, at)
	var parts: Array[PackedVector2Array] = []
	match kind:
		0:
			var stone := TitlePaint.oval_outline(Vector2(0, -36), Vector2(15, 15), 0.0, 16).slice(8, 16)
			stone.append_array(PackedVector2Array([Vector2(15, -36), Vector2(15, 0), Vector2(-15, 0)]))
			parts.append(stone)
		1:
			parts.append(PackedVector2Array([Vector2(-4, -60), Vector2(4, -60), Vector2(4, 0), Vector2(-4, 0)]))
			parts.append(PackedVector2Array([Vector2(-16, -47), Vector2(16, -47), Vector2(16, -39), Vector2(-16, -39)]))
		_:
			parts.append(PackedVector2Array([Vector2(-22, -16), Vector2(22, -16), Vector2(22, 0), Vector2(-22, 0)]))
	for part in parts:
		var shape := place * part
		paint.shape(shape, color)
		paint.rim(shape, Vector2(-1.4, -1.8) * shrink, rim)


## The chain from Thresh's lantern to Senna, on a faint glow; once Thresh
## is gone, broken in the middle.
func _paint_chain(paint: TitlePaint) -> void:
	var pieces: Array[Vector2] = [Vector2(0.0, 1.0)]
	if not thresh.visible:
		pieces = [Vector2(0.0, CHAIN_BREAK.x), Vector2(CHAIN_BREAK.y, 1.0)]
	for piece in pieces:
		var line := PackedVector2Array()
		for k in CHAIN_PIECES + 1:
			line.append(_chain_point(lerpf(piece.x, piece.y, float(k) / CHAIN_PIECES)))
		if thresh.visible:
			paint.taper(line, 14.0, 14.0, Color(SOUL_COLOR, 0.06))
		paint.chain(line, CHAIN_LINK, CHAIN_WIDTH, CHAIN_COLOR, CHAIN_EDGE)


## A jagged line of land across the screen at `base_y`, its points `rise`
## (min, max) over it and `step` (min, max) apart, down to the bottom.
func _skyline(base_y: float, rise: Vector2, step: Vector2, rng: RandomNumberGenerator) -> PackedVector2Array:
	var points := PackedVector2Array()
	var x := 0.0
	while x < size.x:
		points.append(Vector2(x, base_y - rng.randf_range(rise.x, rise.y)))
		x += rng.randf_range(step.x, step.y)
	points.append(Vector2(size.x, base_y - rng.randf_range(rise.x, rise.y)))
	points.append(Vector2(size.x, size.y))
	points.append(Vector2(0, size.y))
	return points


## A soft band of haze across the screen at `y`, `half` thick each way.
func _band(paint: TitlePaint, y: float, half: float, color: Color) -> void:
	var clear := Color(color, 0.0)
	paint.shape(PackedVector2Array([Vector2(0, y - half), Vector2(size.x, y - half), Vector2(size.x, y), Vector2(0, y)]),
		TitlePaint.linear(Vector2(0, y - half), Vector2(0, y), clear, color))
	paint.shape(PackedVector2Array([Vector2(0, y), Vector2(size.x, y), Vector2(size.x, y + half), Vector2(0, y + half)]),
		TitlePaint.linear(Vector2(0, y), Vector2(0, y + half), color, clear))


## Points along an arc round `center`, from angle `from` to `to`.
static func _arc(center: Vector2, radius: float, from: float, to: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in ARCH_PIECES + 1:
		out.append(center + Vector2.from_angle(lerpf(from, to, float(k) / ARCH_PIECES)) * radius)
	return out


# --- The near layer ------------------------------------------------------------------


## In front of the figures: the dark at the bottom of the screen, tall grass
## along it and a near grave at each corner.
func _draw_foreground() -> void:
	var paint := TitlePaint.new()
	var top := size.y - BOTTOM_SHADE.x
	paint.shape(PackedVector2Array([Vector2(0, top), Vector2(size.x, top), Vector2(size.x, size.y), Vector2(0, size.y)]),
		TitlePaint.linear(Vector2(0, top), Vector2(0, size.y), Color(NEAR_COLOR, 0.0), Color(NEAR_COLOR, BOTTOM_SHADE.y)))
	var rng := _rng(5)
	for grave in NEAR_GRAVES:
		_paint_grave(paint, _place(Vector2(grave.x, BASE.y + 16.0)), int(grave.z), grave.w, grave.y, NEAR_COLOR, Color(MOONLIGHT, 0.12))
	var x := -10.0
	while x < size.x + 10.0:
		_tuft(paint, Vector2(x, size.y + 4.0), rng.randf_range(NEAR_GRASS_HEIGHT.x, NEAR_GRASS_HEIGHT.y), NEAR_COLOR, rng)
		x += rng.randf_range(GRASS_STEP * 0.4, GRASS_STEP * 1.2)
	paint.draw(foreground)


# --- What moves ---------------------------------------------------------------------


func _draw_effects() -> void:
	var glow := JourneyMap.glow()
	var blob := JourneyMap.blob()
	if thresh.visible:
		# Green mist on Thresh's side, slowly turning.
		for i in GREEN_MIST.size():
			var mist := GREEN_MIST[i]
			var at := _place(Vector2(mist.x, mist.y)) + Vector2(sin(_time * 0.13 + i), cos(_time * 0.11 + i * 2.0)) * 30.0
			var alpha := GREEN_MIST_ALPHA * (0.75 + 0.25 * sin(_time * 0.5 + i * 1.3))
			effects.draw_texture_rect(blob, Rect2(at - Vector2(mist.z, mist.z * 0.45) * 0.5, Vector2(mist.z, mist.z * 0.45)), false, Color(SOUL_COLOR, alpha))
	_draw_ground_mist(blob)
	if thresh.visible:
		_draw_lantern(glow)
	# Senna's motes, rising round her.
	var middle := senna.middle()
	for mote in _mote_seeds:
		var span := MOTE_REACH.y * 2.0
		var rise := fposmod(mote.y * span + _time * MOTE_SPEED * (0.6 + mote.z), span)
		var at := middle + Vector2((mote.x * 2.0 - 1.0) * MOTE_REACH.x + sin(_time * 0.6 + mote.z * 9.0) * 12.0, MOTE_REACH.y - rise)
		var alpha := sin(PI * rise / span) * (0.45 + 0.25 * sin(_time * 1.4 + mote.z * 20.0))
		MainBackdrop.draw_mote(effects, at, SENNA_COLOR, alpha)
	# Lucian's relic gun's core, pulsing, and his muzzle glint.
	var core := lucian.relic_core()
	var beat := 0.5 + 0.5 * sin(_time * 2.0 + 1.0)
	effects.draw_texture_rect(glow, Rect2(core - Vector2.ONE * 22.0, Vector2.ONE * 44.0), false, Color(SENNA_COLOR, 0.15 + 0.2 * beat))
	var glint := lucian.muzzle()
	var twinkle := 0.5 + 0.5 * sin(_time * 2.3)
	var shine := 34.0 + 18.0 * twinkle
	effects.draw_texture_rect(glow, Rect2(glint - Vector2.ONE * shine * 0.5, Vector2.ONE * shine), false, Color(GLINT_COLOR, 0.2 + 0.25 * twinkle))
	effects.draw_line(glint - Vector2(shine * 0.4, 0), glint + Vector2(shine * 0.4, 0), Color(1, 0.95, 0.8, 0.3 + 0.3 * twinkle), 1.5)
	effects.draw_line(glint - Vector2(0, shine * 0.25), glint + Vector2(0, shine * 0.25), Color(1, 0.95, 0.8, 0.3 + 0.3 * twinkle), 1.5)


## Thresh's lantern breathing, the souls rising from it, his eyes
## flickering and the lights running along the chain to him.
func _draw_lantern(glow: Texture2D) -> void:
	var lantern := thresh.lantern()
	var pulse := 0.5 + 0.5 * sin(_time * PULSE_RATE)
	var reach := LANTERN_GLOW * (0.9 + 0.1 * pulse)
	effects.draw_texture_rect(glow, Rect2(lantern - Vector2.ONE * reach * 0.5, Vector2.ONE * reach), false, Color(SOUL_COLOR, 0.16 + LANTERN_PULSE * pulse))
	effects.draw_texture_rect(glow, Rect2(lantern - Vector2.ONE * 45.0, Vector2.ONE * 90.0), false, Color(SOUL_CORE, 0.2 + 0.15 * pulse))
	for wisp in _wisp_seeds:
		_draw_wisp(lantern + Vector2(0, -24.0), wisp, glow)
	var eyes := thresh.eyes()
	for k in eyes.size():
		var flicker := 0.5 + 0.5 * sin(_time * EYE_FLICKER + k * 2.1) * sin(_time * 2.3 + k)
		var size_now := EYE_GLOW * (0.85 + 0.3 * flicker)
		effects.draw_texture_rect(glow, Rect2(eyes[k] - Vector2.ONE * size_now * 0.5, Vector2.ONE * size_now), false, Color(SOUL_COLOR, 0.35 + 0.3 * flicker))
	for k in CHAIN_LIGHTS:
		var t := fposmod(float(k) / CHAIN_LIGHTS - _time * CHAIN_LIGHT_SPEED, 1.0)
		var at := _chain_point(t)
		var alpha := sin(PI * t) * 0.5
		effects.draw_texture_rect(glow, Rect2(at - Vector2(30, 12), Vector2(60, 24)), false, Color(SOUL_COLOR, alpha))
		effects.draw_circle(at, 2.0, Color(SOUL_CORE, alpha))


## The ground mist's bands: soft puffs drifting right to left. Each puff's
## height and rise come from its own index, so nothing jumps as they wrap.
func _draw_ground_mist(blob: Texture2D) -> void:
	var step := MIST_PUFF * 0.5
	for b in GROUND_MIST.size():
		var band := GROUND_MIST[b]
		var y := _place(Vector2(0, band.x)).y
		var offset := _time * MIST_SPEED * (1.0 + b * 0.4) + b * 173.0
		var first := floori(offset / step) - 1
		for k in range(first, first + int(size.x / step) + 3):
			var noise := fposmod(sin(k * 12.9898 + b * 78.233) * 43758.5453, 1.0)
			var rise := (noise - 0.5) * band.y * 0.6
			var puff := Vector2(MIST_PUFF * (0.8 + noise * 0.5), band.y * 2.0)
			var at := Vector2(k * step - offset, y - band.y + rise)
			effects.draw_texture_rect(blob, Rect2(at, puff), false, Color(MIST_COLOR, MIST_COLOR.a * band.z))


## A soul rising from `from` towards the sky: it swirls up and drifts left
## on the wind, fading in and out, with a short fading trail.
func _draw_wisp(from: Vector2, wisp: Vector3, glow: Texture2D) -> void:
	var life := fposmod(wisp.z + _time / (WISP_LIFE * (0.8 + wisp.y * 0.4)), 1.0)
	var alpha := sin(PI * life) * 0.75
	var trail := PackedVector2Array()
	var colors := PackedColorArray()
	for k in WISP_TRAIL:
		var t := maxf(life - k * 0.012, 0.0)
		trail.append(from + Vector2(sin(t * 6.0 + wisp.x * TAU) * WISP_SWIRL * t - WISP_DRIFT * t, -WISP_RISE * t))
		colors.append(Color(SOUL_COLOR, alpha * 0.7 * (1.0 - float(k) / WISP_TRAIL)))
	effects.draw_polyline_colors(trail, colors, 3.0, true)
	var reach := 12.0 + 6.0 * wisp.y
	effects.draw_texture_rect(glow, Rect2(trail[0] - Vector2.ONE * reach, Vector2.ONE * reach * 2.0), false, Color(SOUL_COLOR, alpha * 0.7))
	effects.draw_circle(trail[0], 2.6 * (1.0 - life * 0.4), Color(SOUL_CORE, alpha))


static func _rng(salt: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = salt * 7919
	return rng

class_name TitleBackdrop
extends Control
## The title screen's night scene behind its centred column: the story at a
## glance. Under a teal-black sky and a pale moon at the upper left, Lucian
## and Senna's spirit (behind him, ghostly teal) stand at the left and face
## Thresh, who looms at the right with his green lantern held out. Behind
## them are the Shadow Isles: a horizon of jagged isles, a cliff at the right
## with the ruined arches and spires of Helia on it, dead trees and
## gravestones. A faint spectral chain runs along the ground from Thresh to
## Senna, and the middle stays dark so the column reads.
## The figures are backlit SVG silhouettes, bottom-anchored TextureRects:
## Lucian and Senna keep to the left edge and Thresh to the right one, so a
## wider screen only widens the gap between them. The scene behind them is
## drawn once; only `effects`, in front of them, moves: ground mist drifting,
## green mist on Thresh's side, his lantern's glow pulsing and souls rising
## from it, teal motes around Senna, lights running along the chain and
## Lucian's muzzle glinting. It moves only while the title shows.

## The screen the scene is laid out on. On a wider or taller one, whatever
## stands in its right half keeps to the right edge, and all but the sky
## keeps to the bottom.
const BASE := Vector2(1920, 1080)

## The figures' art, and each one's place on the BASE screen: x is its outer
## edge's distance from its side (left for Lucian and Senna, right for
## Thresh), y its height and z how far its feet stand above the bottom.
const LUCIAN_ART := preload("res://assets/art/ui/title_lucian.svg")
const SENNA_ART := preload("res://assets/art/ui/title_senna.svg")
const THRESH_ART := preload("res://assets/art/ui/title_thresh.svg")
const LUCIAN_PLACE := Vector3(190, 870, 14)
const SENNA_PLACE := Vector3(0, 790, 34)
const THRESH_PLACE := Vector3(40, 1010, 8)
## Points in the art, as shares of its size: Thresh's lantern and where his
## chain leaves his art on the ground; the hem of Senna's cloak where the
## chain ends and her middle, for her motes; Lucian's muzzle glint.
const LANTERN_AT := Vector2(0.1875, 0.511)
const CHAIN_FROM := Vector2(0.0, 0.986)
const CHAIN_TO := Vector2(0.45, 0.955)
const SENNA_MIDDLE := Vector2(0.55, 0.45)
const GLINT_AT := Vector2(0.962, 0.252)

## The colours: moonlight, Thresh's green (his lantern, the chain, the
## ruins' windows, the mist on his side), Senna's teal and Lucian's gold.
const MOONLIGHT := Color("cfe0ff")
const SOUL_COLOR := Color("8fe3b0")
const SOUL_CORE := Color("e4fff0")
const SENNA_COLOR := Color("b8fff0")
const GLINT_COLOR := Color("ffcf5a")
## The land, from far to near: the isles on the horizon, the cliff and the
## ruins, the ridge the trees stand on, the ground.
const ISLES_COLOR := Color("11292a")
const CLIFF_COLOR := Color("0c1c1d")
const RUIN_COLOR := Color("0e1f21")
const RIDGE_COLOR := Color("081213")
const GRAVE_COLOR := Color("0f1f21")
const GROUND_TOP := Color("0a1617")
const GROUND_BOTTOM := Color("030607")

## Stars over the sky's top part.
const STARS := 260
## The moon: centre, radius, its lit and shaded sides, its halos (size,
## alpha) and its darker seas (offset and size as shares of the radius).
const MOON_AT := Vector2(330, 170)
const MOON_RADIUS := 88.0
const MOON_LIT := Color("e9f0f5")
const MOON_SHADE := Color("9fb1c2")
const MOON_SIDES := 64
const MOON_HALOS: Array[Vector2] = [Vector2(1100, 0.16), Vector2(460, 0.3), Vector2(250, 0.35)]
const MOON_SEAS: Array[Vector3] = [Vector3(-0.3, -0.25, 0.8), Vector3(0.3, 0.05, 0.7), Vector3(-0.05, 0.4, 0.55)]

## The horizon, where the isles stand, the ridge behind the figures and the
## ground's top edge, on the BASE screen.
const HORIZON := 830.0
const RIDGE := 935.0
const GROUND := 1005.0
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
## Dead trees (x, height, lean) on the ridge, and gravestones (x, y, kind:
## 0 a headstone, 1 a cross, 2 a slab; tilt), smaller the farther they are.
const TREES: Array[Vector3] = [Vector3(14, 500, -0.12), Vector3(700, 250, 0.1), Vector3(1170, 230, -0.08), Vector3(1912, 520, 0.14)]
const TREE_DEPTH := 5
const GRAVES: Array[Vector4] = [Vector4(470, 985, 1, -0.06), Vector4(575, 1012, 0, -0.08), Vector4(650, 990, 1, 0.12),
	Vector4(712, 1022, 2, 0.05), Vector4(850, 945, 1, 0.04), Vector4(1075, 950, 0, -0.05), Vector4(1196, 1000, 0, 0.1),
	Vector4(1248, 1030, 1, -0.14), Vector4(1886, 1002, 0, 0.04)]
## The dark behind the centred column, so it reads: its size and alpha.
const SCRIM_SIZE := Vector2(1150, 1300)
const SCRIM_ALPHA := 0.62

## The chain from Thresh to Senna: its colour, link size, how far its middle
## sags towards the viewer, how many straight pieces draw it, and the lights
## that run along it to Thresh (how many, and the share of it per second).
const CHAIN_COLOR := Color(0.56, 0.89, 0.69, 0.3)
const CHAIN_LINK := 18.0
const CHAIN_SAG := 30.0
const CHAIN_PIECES := 12
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
## The lantern's glow (size), how much it pulses and how fast (rad/s).
const LANTERN_GLOW := 320.0
const LANTERN_PULSE := 0.12
const PULSE_RATE := 1.7
## Souls rising from the lantern: how many, how high and how long each one
## rises (px, s), how wide it swirls, how far it drifts left on the wind
## and how many points its fading trail has.
const WISPS := 9
const WISP_RISE := 300.0
const WISP_LIFE := 6.5
const WISP_SWIRL := 34.0
const WISP_DRIFT := 70.0
const WISP_TRAIL := 8
## Senna's motes: how many, how far round her middle (x, y) and how fast.
const SENNA_MOTES := 22
const MOTE_REACH := Vector2(170, 330)
const MOTE_SPEED := 11.0

var lucian: TextureRect
var senna: TextureRect
var thresh: TextureRect
## The mist, souls, motes and glows, in front of the figures: the only layer
## drawn again every frame.
var effects := Control.new()

## Per wisp and per mote: random shares (0..1) for its place and phase.
var _wisp_seeds: Array[Vector3] = []
var _mote_seeds: Array[Vector3] = []
var _time := 0.0


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	senna = _add_figure(&"Senna", SENNA_ART, SENNA_PLACE, false)
	lucian = _add_figure(&"Lucian", LUCIAN_ART, LUCIAN_PLACE, false)
	thresh = _add_figure(&"Thresh", THRESH_ART, THRESH_PLACE, true)
	effects.name = &"Effects"
	effects.set_anchors_preset(Control.PRESET_FULL_RECT)
	effects.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effects.draw.connect(_draw_effects)
	add_child(effects)
	var rng := _rng(40)
	for i in WISPS:
		_wisp_seeds.append(Vector3(rng.randf(), rng.randf(), (i + rng.randf() * 0.5) / WISPS))
	for i in SENNA_MOTES:
		_mote_seeds.append(Vector3(rng.randf(), rng.randf(), rng.randf()))


func _ready() -> void:
	set_process(is_visible_in_tree())


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_inside_tree():
		set_process(is_visible_in_tree())


func _process(delta: float) -> void:
	_time += delta
	effects.queue_redraw()


## A figure's art, bottom-anchored at `place` (see LUCIAN_PLACE) on the left
## or the `right` side, as wide as its art's shape allows.
func _add_figure(id: StringName, art: Texture2D, place: Vector3, right: bool) -> TextureRect:
	var figure := TextureRect.new()
	figure.name = id
	figure.texture = art
	figure.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	figure.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	figure.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var width := roundf(place.y * art.get_width() / art.get_height())
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
	return figure


## The point at `share` of `figure`'s art, in this control.
static func _point(figure: Control, share: Vector2) -> Vector2:
	return figure.position + figure.size * share


## The point at `t` (0 at Thresh, 1 at Senna) along the chain on the ground.
func _chain_point(t: float) -> Vector2:
	var from := _point(thresh, CHAIN_FROM)
	var to := _point(senna, CHAIN_TO)
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
	# The green of the isles on the right, under the moonlit left.
	draw_texture_rect(glow, Rect2(_place(Vector2(1560, 760)) - Vector2(900, 600), Vector2(1800, 1200)), false, Color(SOUL_COLOR, 0.07))
	_draw_moon()
	_draw_land(_rng(2))
	_draw_ruins()
	var rng := _rng(3)
	for tree in TREES:
		_draw_tree(_place(Vector2(tree.x, RIDGE + 6.0)), tree.y, tree.z, rng)
	_draw_ground()
	for grave in GRAVES:
		_draw_grave(_place(Vector2(grave.x, grave.y)), int(grave.z), grave.w)
	_draw_chain()
	draw_texture_rect(glow, Rect2(size * 0.5 - SCRIM_SIZE * 0.5, SCRIM_SIZE), false, Color(0, 0, 0, SCRIM_ALPHA))


## The moon: its halos, the disc shaded from its lit upper left, its seas
## and a bright rim.
func _draw_moon() -> void:
	var glow := JourneyMap.glow()
	for halo in MOON_HALOS:
		draw_texture_rect(glow, Rect2(MOON_AT - Vector2.ONE * halo.x * 0.5, Vector2.ONE * halo.x), false, Color(MOONLIGHT, halo.y))
	var disc := PackedVector2Array()
	var colors := PackedColorArray()
	var light := Vector2(-1, -1).normalized()
	for i in MOON_SIDES:
		var direction := Vector2.from_angle(TAU * i / MOON_SIDES)
		disc.append(MOON_AT + direction * MOON_RADIUS)
		colors.append(MOON_SHADE.lerp(MOON_LIT, (direction.dot(light) + 1.0) * 0.5))
	draw_polygon(disc, colors)
	var blob := JourneyMap.blob()
	for sea in MOON_SEAS:
		var reach := MOON_RADIUS * sea.z * 0.5
		draw_texture_rect(blob, Rect2(MOON_AT + Vector2(sea.x, sea.y) * MOON_RADIUS - Vector2.ONE * reach, Vector2.ONE * reach * 2.0), false, Color(MOON_SHADE, 0.3))
	draw_arc(MOON_AT, MOON_RADIUS - 1.5, PI * 0.75, PI * 1.75, 32, Color(1, 1, 1, 0.55), 3.0, true)


## The isles on the horizon with the haze over them, the cliff at the right
## and the ridge behind the figures.
func _draw_land(rng: RandomNumberGenerator) -> void:
	var horizon := _place(Vector2(0, HORIZON)).y
	_draw_skyline(horizon, Vector2(12, 90), Vector2(30, 90), ISLES_COLOR, rng)
	draw_texture_rect(JourneyMap.blob(), Rect2(-200, horizon - 60.0, size.x + 400.0, 120.0), false, Color(0.36, 0.62, 0.6, 0.12))
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
	cliff.append(Vector2(size.x, size.y))
	cliff.append(Vector2(foot.x, size.y))
	draw_colored_polygon(cliff, CLIFF_COLOR)
	# Moonlight along its face.
	draw_polyline(cliff.slice(0, 7), Color(MOONLIGHT, 0.14), 2.0, true)
	_draw_skyline(_place(Vector2(0, RIDGE)).y, Vector2(0, 40), Vector2(120, 260), RIDGE_COLOR, rng)


## A jagged line of land across the screen at `base_y`, its points
## `rise` (min, max) over it and `step` (min, max) apart, filled down to the
## bottom in `color`.
func _draw_skyline(base_y: float, rise: Vector2, step: Vector2, color: Color, rng: RandomNumberGenerator) -> void:
	var points := PackedVector2Array([Vector2(0, size.y)])
	var x := 0.0
	while x < size.x:
		points.append(Vector2(x, base_y - rng.randf_range(rise.x, rise.y)))
		x += rng.randf_range(step.x, step.y)
	points.append(Vector2(size.x, base_y - rng.randf_range(rise.x, rise.y)))
	points.append(Vector2(size.x, size.y))
	draw_colored_polygon(points, color)


## Helia's ruins on the cliff top: the arcade, then the spires, whole and broken.
func _draw_ruins() -> void:
	var base := _place(Vector2(BASE.x, CLIFF_TOP + 12.0)).y
	var from := _place(Vector2(ARCADE.x, ARCADE.z))
	var top := from.y
	var radius := ARCH_SPAN * 0.5
	var spring := top + 16.0 + radius
	var arches := int((ARCADE.y - ARCADE.x) / ARCH_SPAN)
	var rim := Color(MOONLIGHT, 0.16)
	for i in arches + 1:
		var x := from.x + i * ARCH_SPAN
		draw_rect(Rect2(x - 7.0, spring, 14.0, base - spring), RUIN_COLOR)
		draw_line(Vector2(x - 7.0, spring), Vector2(x - 7.0, base), rim, 1.5)
	for i in arches:
		var center := Vector2(from.x + (i + 0.5) * ARCH_SPAN, spring)
		var reach := PI if i != BROKEN_ARCH else PI * 0.45
		draw_arc(center, radius - 2.0, PI, PI + reach, 20, RUIN_COLOR, 10.0, true)
		draw_arc(center, radius + 3.0, PI, PI + reach * 0.6, 12, rim, 1.5, true)
		if i != BROKEN_ARCH:
			draw_rect(Rect2(center.x - radius, top, ARCH_SPAN, 16.0), RUIN_COLOR)
			draw_line(Vector2(center.x - radius, top), Vector2(center.x + radius, top), rim, 1.5)
	for spire in SPIRES:
		_draw_spire(_place(Vector2(spire.x, spire.y)), spire.z, base, false)
	for spire in BROKEN_SPIRES:
		_draw_spire(_place(Vector2(spire.x, spire.y)), spire.z, base, true)


## A spire from `base` up to `top` (its point), `width` wide: a tower with a
## ledge, a pointed roof (or a broken top), moonlight on its left and two
## windows with a faint green light.
func _draw_spire(top: Vector2, width: float, base: float, broken: bool) -> void:
	var half := width * 0.5
	var shoulder := top.y + width * 1.8
	var rim := Color(MOONLIGHT, 0.18)
	draw_rect(Rect2(top.x - half, shoulder, width, base - shoulder), RUIN_COLOR)
	draw_rect(Rect2(top.x - half - 4.0, shoulder, width + 8.0, 7.0), RUIN_COLOR)
	if broken:
		draw_colored_polygon(PackedVector2Array([Vector2(top.x - half, shoulder), Vector2(top.x - half, top.y + width * 0.5),
			Vector2(top.x - half * 0.3, top.y + width), Vector2(top.x + half * 0.2, top.y), Vector2(top.x + half * 0.5, top.y + width * 0.9),
			Vector2(top.x + half, top.y + width * 0.6), Vector2(top.x + half, shoulder)]), RUIN_COLOR)
	else:
		draw_colored_polygon(PackedVector2Array([Vector2(top.x - half - 5.0, shoulder), top, Vector2(top.x + half + 5.0, shoulder)]), RUIN_COLOR)
		draw_line(Vector2(top.x - half - 5.0, shoulder), top, rim, 1.5, true)
	draw_line(Vector2(top.x - half, shoulder + 7.0), Vector2(top.x - half, base), rim, 1.5)
	for k in 2:
		var window := Rect2(top.x - 2.5, shoulder + 34.0 + k * 64.0, 5.0, 15.0)
		if window.end.y < base:
			draw_rect(window, Color(SOUL_COLOR, 0.35))


## A dead tree rooted at `root`: a twisted trunk, its limbs forking
## TREE_DEPTH times, `height` tall, leaning by `lean` (radians).
func _draw_tree(root: Vector2, height: float, lean: float, rng: RandomNumberGenerator) -> void:
	_draw_limb(root, -PI * 0.5 + lean, height * 0.4, maxf(height * 0.05, 4.0), 0, rng)


func _draw_limb(from: Vector2, angle: float, length: float, width: float, depth: int, rng: RandomNumberGenerator) -> void:
	var bend := rng.randf_range(-0.4, 0.4)
	var middle := from + Vector2.from_angle(angle) * length * 0.5
	var to := middle + Vector2.from_angle(angle + bend) * length * 0.5
	draw_line(from, middle, RIDGE_COLOR, width, true)
	draw_circle(middle, width * 0.45, RIDGE_COLOR)
	draw_line(middle, to, RIDGE_COLOR, width * 0.8, true)
	if depth >= TREE_DEPTH:
		return
	var limbs := 2 if depth < 2 else rng.randi_range(1, 3)
	for k in limbs:
		var spread := rng.randf_range(0.3, 0.85) * (1.0 if (k + depth) % 2 == 0 else -1.0)
		_draw_limb(to, angle + bend + spread, length * rng.randf_range(0.55, 0.78), width * 0.62, depth + 1, rng)


## The near ground: a dark band with a soft, uneven top edge.
func _draw_ground() -> void:
	var top := _place(Vector2(0, GROUND)).y
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	var x := 0.0
	while x < size.x:
		points.append(Vector2(x, top + sin(x * 0.005) * 10.0 + sin(x * 0.013) * 5.0))
		colors.append(GROUND_TOP)
		x += 40.0
	points.append(Vector2(size.x, top))
	colors.append(GROUND_TOP)
	points.append(Vector2(size.x, size.y))
	colors.append(GROUND_BOTTOM)
	points.append(Vector2(0, size.y))
	colors.append(GROUND_BOTTOM)
	draw_polygon(points, colors)


## A gravestone of `kind` standing at `at`, tilted by `tilt`, smaller the
## nearer it is to the horizon, with moonlight on its top and left.
func _draw_grave(at: Vector2, kind: int, tilt: float) -> void:
	var shrink := lerpf(0.55, 1.0, clampf(inverse_lerp(_place(Vector2(0, HORIZON)).y, size.y, at.y), 0.0, 1.0))
	draw_set_transform(at, tilt, Vector2.ONE * shrink)
	var rim := Color(MOONLIGHT, 0.3)
	match kind:
		0:
			draw_rect(Rect2(-15, -36, 30, 36), GRAVE_COLOR)
			draw_circle(Vector2(0, -36), 15.0, GRAVE_COLOR)
			draw_arc(Vector2(0, -36), 15.0, PI, PI * 1.6, 10, rim, 2.0, true)
			draw_line(Vector2(-15, -36), Vector2(-15, 0), rim, 2.0)
		1:
			draw_rect(Rect2(-4, -60, 8, 60), GRAVE_COLOR)
			draw_rect(Rect2(-16, -47, 32, 8), GRAVE_COLOR)
			draw_line(Vector2(-4, -60), Vector2(4, -60), rim, 2.0)
			draw_line(Vector2(-16, -47), Vector2(-4, -47), rim, 2.0)
		_:
			draw_rect(Rect2(-22, -16, 44, 16), GRAVE_COLOR)
			draw_line(Vector2(-22, -16), Vector2(22, -16), rim, 2.0)
	draw_set_transform(Vector2.ZERO)


## The spectral chain on the ground from Thresh to Senna, on a faint glow.
func _draw_chain() -> void:
	var points := PackedVector2Array()
	for k in CHAIN_PIECES + 1:
		points.append(_chain_point(float(k) / CHAIN_PIECES))
	draw_polyline(points, Color(SOUL_COLOR, 0.07), 14.0, true)
	for k in CHAIN_PIECES:
		JourneyMap.draw_chain(self, points[k], points[k + 1], CHAIN_COLOR, CHAIN_LINK, 2.5)


# --- What moves ---------------------------------------------------------------------


func _draw_effects() -> void:
	var glow := JourneyMap.glow()
	var blob := JourneyMap.blob()
	# Green mist on Thresh's side, slowly turning.
	for i in GREEN_MIST.size():
		var mist := GREEN_MIST[i]
		var at := _place(Vector2(mist.x, mist.y)) + Vector2(sin(_time * 0.13 + i), cos(_time * 0.11 + i * 2.0)) * 30.0
		var alpha := GREEN_MIST_ALPHA * (0.75 + 0.25 * sin(_time * 0.5 + i * 1.3))
		effects.draw_texture_rect(blob, Rect2(at - Vector2(mist.z, mist.z * 0.45) * 0.5, Vector2(mist.z, mist.z * 0.45)), false, Color(SOUL_COLOR, alpha))
	_draw_ground_mist(blob)
	# The lantern: its glow pulsing, and souls rising from it.
	var lantern := _point(thresh, LANTERN_AT)
	var pulse := 0.5 + 0.5 * sin(_time * PULSE_RATE)
	var reach := LANTERN_GLOW * (0.92 + 0.08 * pulse)
	effects.draw_texture_rect(glow, Rect2(lantern - Vector2.ONE * reach * 0.5, Vector2.ONE * reach), false, Color(SOUL_COLOR, 0.2 + LANTERN_PULSE * pulse))
	effects.draw_texture_rect(glow, Rect2(lantern - Vector2.ONE * 45.0, Vector2.ONE * 90.0), false, Color(SOUL_CORE, 0.25 + 0.15 * pulse))
	for wisp in _wisp_seeds:
		_draw_wisp(lantern + Vector2(0, -24.0), wisp, glow)
	# Senna's motes, rising round her.
	var middle := _point(senna, SENNA_MIDDLE)
	for mote in _mote_seeds:
		var span := MOTE_REACH.y * 2.0
		var rise := fposmod(mote.y * span + _time * MOTE_SPEED * (0.6 + mote.z), span)
		var at := middle + Vector2((mote.x * 2.0 - 1.0) * MOTE_REACH.x + sin(_time * 0.6 + mote.z * 9.0) * 12.0, MOTE_REACH.y - rise)
		var alpha := sin(PI * rise / span) * (0.45 + 0.25 * sin(_time * 1.4 + mote.z * 20.0))
		MainBackdrop.draw_mote(effects, at, SENNA_COLOR, alpha)
	# Lights running along the chain, from Senna to Thresh.
	for k in CHAIN_LIGHTS:
		var t := fposmod(float(k) / CHAIN_LIGHTS - _time * CHAIN_LIGHT_SPEED, 1.0)
		var at := _chain_point(t)
		var alpha := sin(PI * t) * 0.5
		effects.draw_texture_rect(glow, Rect2(at - Vector2(30, 12), Vector2(60, 24)), false, Color(SOUL_COLOR, alpha))
		effects.draw_circle(at, 2.0, Color(SOUL_CORE, alpha))
	# Lucian's muzzle glint.
	var glint := _point(lucian, GLINT_AT)
	var twinkle := 0.5 + 0.5 * sin(_time * 2.3)
	var shine := 34.0 + 18.0 * twinkle
	effects.draw_texture_rect(glow, Rect2(glint - Vector2.ONE * shine * 0.5, Vector2.ONE * shine), false, Color(GLINT_COLOR, 0.2 + 0.25 * twinkle))


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


## A soul rising from `from`: it swirls up and drifts left on the wind,
## fading in and out, with a short fading trail.
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

class_name MainBackdrop
extends Control
## The main screen's backdrop, drawn in code behind every section, in the
## scene MainScreen.show_section picks:
## - GROVE, behind the Evolution Tree and the Journey: the night grove's sky
##   around their framed pages, with stars, mist bands, a vignette and light
##   motes rising slowly. The tree's pages draw the same sky inside their
##   frames (draw_sky, draw_stars) with their own moon and hills, so this one
##   has neither.
## - GALLERY, behind the Skin Shop: a hall of relics. A stone wall with one
##   arch per card, lined up with the shop's row; in each, a lamp on a chain
##   lights its card from above in that skin's accent. Piers and banners stand
##   between the arches, the polished floor reflects the light and dust drifts
##   in it. Past the five, the hall goes on into the dark.
## Each scene is drawn once; only the motes move, on a small layer of their
## own, and only while the screen shows.

enum Scene { GROVE, GALLERY }

## The night grove's palette; the tree's pages share it.
const SKY_TOP := Color("08101f")
const SKY_BOTTOM := Color("0d2a2b")
const STAR_COLOR := Color(0.82, 0.88, 1.0)
const MIST_COLOR := Color(0.6, 0.82, 0.86, 0.05)
const GROVE_LIGHT := Color("ffd98a")
## Stars: the share of the sky's height they fill, their alpha and size.
const STAR_REACH := 0.62
const STAR_ALPHA := Vector2(0.05, 0.32)
const STAR_SIZE := Vector2(1.0, 2.2)
## A light mote: its glow's size and its core's radius.
const MOTE_GLOW := 18.0
const MOTE_CORE := 1.6

## The grove around the framed pages: its stars, the few with a glint (in the
## top bar), its mist bands (height share, half thickness, alpha over
## MIST_COLOR's) and its motes rising.
const GROVE_STARS := 220
const GLINTS := 10
const MIST_BANDS: Array[Vector3] = [Vector3(0.12, 60, 1.2), Vector3(0.82, 90, 1.6), Vector3(0.96, 110, 2.6)]
const GROVE_MOTES := 40
const MOTE_SPEED := 8.0
## How dark the corners get.
const VIGNETTE_ALPHA := 0.8

## Each skin's accent: its arch's lamp, light and keystone gem.
const ACCENTS := {
	&"classic": Color("f2c75c"),
	&"high_noon": Color("ff8f3a"),
	&"project": Color("3fe6ff"),
	&"pulsefire": Color("4a8dff"),
	&"vampire": Color("e8283f"),
}
## The light of an arch whose skin has no accent.
const DEFAULT_ACCENT := UiStyle.GOLD_COLOR
## The gallery's stone: the wall's courses (height, block width range and
## shade), its mortar, a niche's dark, the arches' and piers' stone.
const BLOCK_HEIGHT := 40.0
const BLOCK_WIDTH := Vector2(74, 136)
const BLOCK_SHADE := 0.07
const WALL_COLOR := Color("252933")
const MORTAR_COLOR := Color("0b0c10")
## A niche's dark, over the stones at its back (they show through a little).
const NICHE_TOP := Color(0.012, 0.014, 0.022, 0.9)
const NICHE_BOTTOM := Color(0.03, 0.035, 0.045, 0.8)
const RING_COLOR := Color("2c2f39")
const PIER_COLOR := Color("16181f")
const CHAIN_COLOR := Color("6d7480")
## An arch springs SPRING_DROP below its card's top, from piers PIER_WIDTH
## wide (the rest of the pitch is its opening). Its ring of VOUSSOIRS stones
## is RING_WIDTH thick, the keystone KEY_RISE taller; ARC_STEPS per curve.
const SPRING_DROP := 24.0
const PIER_WIDTH := 44.0
const CAPITAL := Vector2(64, 16)
const RING_WIDTH := 24.0
const VOUSSOIRS := 11
const KEY_RISE := 10.0
const ARC_STEPS := 40
## The cornice along the wall CORNICE_GAP over the keystones (its height), the
## banners hanging from it on the piers (size, swallowtail notch) and the
## shadow from the ceiling.
const CORNICE_GAP := 6.0
const CORNICE_HEIGHT := 14.0
const BANNER_SIZE := Vector2(40, 150)
const BANNER_NOTCH := 18.0
const BANNER_COLOR := Color("162440")
const CEILING_SHADOW := 170.0
## Each card's plinth (wider than the card by x, y tall).
const PLINTH := Vector2(16, 14)
const PLINTH_COLOR := Color("23262f")
## The lamps: chain length under the arch's crown, the lantern's size, the
## light cone's width at the lamp and at the floor (over the pitch) and its
## alpha at both ends.
const CHAIN_LENGTH := 44.0
const LAMP_SIZE := Vector2(18, 24)
const CONE_TOP := 34.0
const CONE_SPREAD := 1.2
const CONE_ALPHA := Vector2(0.3, 0.07)
## The floor: its colours far and near (its tiles a shade lighter or darker
## in turn), its joints, its vanishing point's height over the floor line,
## where its rows of tiles end (how far each is, over the floor line's
## distance) and how deep the light and the cards show in it.
const FLOOR_FAR := Color("22252e")
const FLOOR_NEAR := Color("07080b")
const TILE_SHADE := 0.05
const JOINT_COLOR := Color(0, 0, 0, 0.5)
const VANISH_HEIGHT := 520.0
const FLOOR_DEPTHS: Array[float] = [0.9, 0.78, 0.66]
const REFLECTION := 150.0
## Dust in the lamps' light, in the beam over each card and over the pool on
## the floor: how many motes, the share in the beams, how fast it sinks, the
## pool's height and a mote's glow.
const DUST := 60
const DUST_IN_BEAMS := 0.45
const DUST_SPEED := 5.0
const DUST_POOL := 90.0
const DUST_GLOW := 9.0

## Which scene shows; show_section sets it.
var scene := Scene.GROVE:
	set(value):
		if value == scene:
			return
		scene = value
		_seed_motes()
		queue_redraw()
## The drifting motes or dust, the only layer drawn again every frame.
var motes := Control.new()

## Per mote: x and y as shares and a phase, all in 0..1.
var _mote_seeds: Array[Vector3] = []
var _time := 0.0

static var _vignette: GradientTexture2D


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	motes.set_anchors_preset(Control.PRESET_FULL_RECT)
	motes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	motes.draw.connect(_draw_motes)
	add_child(motes)
	_seed_motes()


func _ready() -> void:
	set_process(is_visible_in_tree())


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_inside_tree():
		set_process(is_visible_in_tree())


func _process(delta: float) -> void:
	_time += delta
	motes.queue_redraw()


## The skin `id`'s accent, or DEFAULT_ACCENT.
static func accent(id: StringName) -> Color:
	return ACCENTS.get(id, DEFAULT_ACCENT)


## The night sky's gradient over `rect` on `canvas`: SKY_TOP at its top to
## SKY_BOTTOM at its bottom.
static func draw_sky(canvas: CanvasItem, rect: Rect2) -> void:
	canvas.draw_polygon(_corners(rect), PackedColorArray([SKY_TOP, SKY_TOP, SKY_BOTTOM, SKY_BOTTOM]))


## `count` stars from `rng` over the top STAR_REACH of `rect` on `canvas`,
## fainter the lower they are.
static func draw_stars(canvas: CanvasItem, rect: Rect2, rng: RandomNumberGenerator, count: int) -> void:
	for i in count:
		var at := Vector2(rng.randf_range(0.0, rect.size.x), rng.randf_range(0.0, rect.size.y * STAR_REACH))
		var alpha := rng.randf_range(STAR_ALPHA.x, STAR_ALPHA.y) * (1.0 - at.y / rect.size.y)
		canvas.draw_rect(Rect2(rect.position + at, Vector2.ONE * rng.randf_range(STAR_SIZE.x, STAR_SIZE.y)), Color(STAR_COLOR, alpha))


## A light mote at `at` on `canvas`: a soft glow and a bright core.
static func draw_mote(canvas: CanvasItem, at: Vector2, color: Color, alpha: float) -> void:
	canvas.draw_texture_rect(JourneyMap.glow(), Rect2(at - Vector2.ONE * MOTE_GLOW * 0.5, Vector2.ONE * MOTE_GLOW), false, Color(color, alpha * 0.45))
	canvas.draw_circle(at, MOTE_CORE, Color(color, alpha))


## Where the Skin Shop's card `index` (Skins.ALL order) stands, in this
## control's coordinates: the shop centres its row of SkinCard.SIZE cards,
## SkinShop.GAP apart, between the main screen's bars, rounded down as its
## CenterContainer does. Past the row, the empty arches' places.
func card_rect(index: int) -> Rect2:
	var count := Skins.ALL.size()
	var row := Vector2(count * SkinCard.SIZE.x + (count - 1) * SkinShop.GAP, SkinCard.SIZE.y)
	var area := Rect2(0, MainScreen.TOP_BAR, size.x, size.y - MainScreen.TOP_BAR - MainScreen.BOTTOM_BAR)
	var corner := area.position + ((area.size - row) * 0.5).floor()
	return Rect2(corner + Vector2(index * _pitch(), 0), SkinCard.SIZE)


## Arch `index`'s opening, from the top of its curve down to the floor.
func niche(index: int) -> Rect2:
	var card := card_rect(index)
	var radius := _radius()
	var spring := card.position.y + SPRING_DROP
	return Rect2(card.get_center().x - radius, spring - radius, radius * 2.0, _floor_y() - spring + radius)


## The light of arch `index`: its card's skin's accent.
func arch_accent(index: int) -> Color:
	return accent(Skins.ALL[index].id)


func _seed_motes() -> void:
	var rng := _rng(90 + scene)
	_mote_seeds.clear()
	var count := DUST if scene == Scene.GALLERY else GROVE_MOTES
	for i in count:
		_mote_seeds.append(Vector3(rng.randf(), rng.randf(), rng.randf()))


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	if scene == Scene.GALLERY:
		_draw_gallery()
	else:
		_draw_grove()
	draw_texture_rect(_vignette_texture(), Rect2(Vector2.ZERO, size), false, Color(1, 1, 1, VIGNETTE_ALPHA))


func _draw_motes() -> void:
	if scene == Scene.GALLERY:
		_draw_dust()
		return
	var height := size.y + MOTE_GLOW * 2.0
	for mote in _mote_seeds:
		var speed := MOTE_SPEED * (0.6 + mote.z)
		var at := Vector2(mote.x * size.x + sin(_time * 0.5 + mote.z * 9.0) * 14.0, fposmod(mote.y * height - _time * speed, height) - MOTE_GLOW)
		draw_mote(motes, at, GROVE_LIGHT, 0.35 + 0.3 * sin(_time * 1.3 + mote.z * 20.0))


# --- The grove -------------------------------------------------------------------------


func _draw_grove() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_sky(self, rect)
	draw_stars(self, rect, _rng(1), GROVE_STARS)
	var rng := _rng(2)
	var glow := JourneyMap.glow()
	# A few bright stars with a glint, up in the top bar.
	for i in GLINTS:
		var at := Vector2(rng.randf_range(0.0, size.x), rng.randf_range(10.0, MainScreen.TOP_BAR - 6.0))
		var reach := rng.randf_range(5.0, 9.0)
		var color := Color(STAR_COLOR, rng.randf_range(0.35, 0.7))
		draw_texture_rect(glow, Rect2(at - Vector2.ONE * reach * 2.0, Vector2.ONE * reach * 4.0), false, Color(color, color.a * 0.35))
		for arm: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			draw_polyline_colors(PackedVector2Array([at, at + arm * reach]), PackedColorArray([Color(color, color.a * 0.6), Color(color, 0.0)]), 1.0, true)
		draw_circle(at, 1.4, color)
	var blob := JourneyMap.blob()
	for band in MIST_BANDS:
		var y := size.y * band.x
		var x := -rng.randf_range(0.0, 300.0)
		while x < size.x:
			var width := rng.randf_range(420.0, 760.0)
			var rise := rng.randf_range(-0.3, 0.3) * band.y
			draw_texture_rect(blob, Rect2(Vector2(x, y - band.y + rise), Vector2(width, band.y * 2.0)), false, Color(MIST_COLOR, MIST_COLOR.a * band.z))
			x += width * 0.55


# --- The gallery -----------------------------------------------------------------------


func _draw_gallery() -> void:
	var count := Skins.ALL.size()
	var floor_y := _floor_y()
	# Empty arches past the row, as far as the screen goes.
	var extra := ceili(maxf(card_rect(0).position.x, 0.0) / _pitch()) + 1
	var rng := _rng(12)
	_draw_wall(floor_y)
	var glow := JourneyMap.glow()
	for i in count:
		# The wall around an arch, lit by its lamp.
		var lamp := _lamp_at(i)
		draw_texture_rect(glow, Rect2(lamp - Vector2(_pitch() * 1.2, 260.0), Vector2(_pitch() * 2.4, 900.0)), false, Color(arch_accent(i), 0.1))
	for i in range(-extra, count + extra):
		_draw_niche(i, rng)
	for i in range(-extra, count + extra + 1):
		_draw_pier(i)
	_draw_cornice()
	for i in range(-extra, count + extra + 1):
		_draw_banner(card_rect(i).position.x - SkinShop.GAP * 0.5)
	_draw_floor(floor_y, extra)
	for i in count:
		_draw_light(i, floor_y)
	draw_polygon(_corners(Rect2(0, 0, size.x, CEILING_SHADOW)),
		PackedColorArray([Color(0, 0, 0, 0.7), Color(0, 0, 0, 0.7), Color(0, 0, 0, 0), Color(0, 0, 0, 0)]))


## The back wall: courses of stone blocks over the mortar, from the floor up.
func _draw_wall(floor_y: float) -> void:
	draw_rect(Rect2(0, 0, size.x, floor_y), MORTAR_COLOR)
	var rng := _rng(11)
	var y := floor_y - BLOCK_HEIGHT
	while y > -BLOCK_HEIGHT:
		var x := -rng.randf_range(0.0, BLOCK_WIDTH.y)
		while x < size.x:
			var width := rng.randf_range(BLOCK_WIDTH.x, BLOCK_WIDTH.y)
			var shade := rng.randf_range(-BLOCK_SHADE, BLOCK_SHADE)
			var block := Rect2(x + 1.5, y + 1.5, width - 3.0, BLOCK_HEIGHT - 3.0)
			draw_rect(block, WALL_COLOR.lightened(shade) if shade > 0.0 else WALL_COLOR.darkened(-shade))
			# The top edge catches the light, the bottom one is in shadow.
			draw_line(block.position, Vector2(block.end.x, block.position.y), Color(1, 1, 1, 0.04), 1.0)
			draw_line(Vector2(block.position.x, block.end.y), block.end, Color(0, 0, 0, 0.25), 1.0)
			x += width
		y -= BLOCK_HEIGHT


## Arch `index`'s dark opening, its inner edge and its ring of stones with the
## keystone; a lit arch's keystone carries a gem of its light.
func _draw_niche(index: int, rng: RandomNumberGenerator) -> void:
	var rect := niche(index)
	var radius := _radius()
	var center := Vector2(rect.get_center().x, rect.position.y + radius)
	var outline := _arch_outline(center, radius, rect.end.y)
	var colors := PackedColorArray()
	for point in outline:
		colors.append(NICHE_TOP.lerp(NICHE_BOTTOM, inverse_lerp(rect.position.y, rect.end.y, point.y)))
	draw_polygon(outline, colors)
	var lit := index >= 0 and index < Skins.ALL.size()
	var tint := arch_accent(index) if lit else WALL_COLOR
	# The wall's thickness, seen along the opening's edge.
	var edge := _arch_outline(center, radius - 5.0, rect.end.y)
	draw_polyline(edge, Color(WALL_COLOR.lerp(tint, 0.2 if lit else 0.0).lightened(0.08), 0.8), 10.0, true)
	var outer := radius + RING_WIDTH
	for k in VOUSSOIRS:
		var from := PI + PI * k / VOUSSOIRS
		var to := PI + PI * (k + 1) / VOUSSOIRS
		var key := k * 2 + 1 == VOUSSOIRS
		var reach := outer + (KEY_RISE if key else 0.0)
		var stone := PackedVector2Array()
		for s in 4:
			stone.append(center + Vector2.from_angle(lerpf(from, to, s / 3.0)) * radius)
		for s in 4:
			stone.append(center + Vector2.from_angle(lerpf(to, from, s / 3.0)) * reach)
		var shade := rng.randf_range(-0.05, 0.05) + (0.06 if key else 0.0)
		draw_colored_polygon(stone, RING_COLOR.lightened(shade) if shade > 0.0 else RING_COLOR.darkened(-shade))
		stone.append(stone[0])
		draw_polyline(stone, MORTAR_COLOR, 2.0, true)
	if lit:
		# The lamp's light along the ring's inner edge, and the keystone's gem.
		draw_arc(center, radius + 2.0, PI, TAU, ARC_STEPS, Color(tint, 0.22), 3.0, true)
		var gem := center + Vector2(0, -(outer + KEY_RISE * 0.5 - 2.0))
		draw_texture_rect(JourneyMap.glow(), Rect2(gem - Vector2.ONE * 22.0, Vector2.ONE * 44.0), false, Color(tint, 0.55))
		draw_colored_polygon(_diamond(gem, 6.0), tint.lightened(0.3))
		draw_colored_polygon(_diamond(gem, 2.5), Color(1, 1, 1, 0.85))


## The pier left of arch `index`: its shaft from the springline to the floor,
## shaded round and lit on each side by the arch there, a capital where the
## arches spring and a base.
func _draw_pier(index: int) -> void:
	var x := card_rect(index).position.x - SkinShop.GAP * 0.5
	var spring := niche(index).position.y + _radius()
	var floor_y := _floor_y()
	var half := PIER_WIDTH * 0.5
	for side: float in [-1.0, 1.0]:
		var neighbour := index - 1 if side < 0.0 else index
		var lit := neighbour >= 0 and neighbour < Skins.ALL.size()
		var edge := PIER_COLOR.lerp(arch_accent(neighbour), 0.18).lightened(0.12) if lit else PIER_COLOR.lightened(0.06)
		var outside := x + side * half
		draw_polygon(PackedVector2Array([Vector2(x, spring), Vector2(outside, spring), Vector2(outside, floor_y), Vector2(x, floor_y)]),
			PackedColorArray([PIER_COLOR, edge, edge.darkened(0.3), PIER_COLOR.darkened(0.3)]))
	for flute: float in [-0.4, 0.0, 0.4]:
		draw_line(Vector2(x + flute * half, spring + CAPITAL.y), Vector2(x + flute * half, floor_y - CAPITAL.y), Color(0, 0, 0, 0.3), 2.0)
	for block: Rect2 in [Rect2(x - CAPITAL.x * 0.5, spring - CAPITAL.y * 0.5, CAPITAL.x, CAPITAL.y),
			Rect2(x - CAPITAL.x * 0.5, floor_y - CAPITAL.y, CAPITAL.x, CAPITAL.y)]:
		draw_rect(block, RING_COLOR)
		draw_line(block.position, Vector2(block.end.x, block.position.y), Color(1, 1, 1, 0.08), 2.0)
		draw_rect(block, MORTAR_COLOR, false, 1.5)


## A moulding along the wall, over the arches.
func _draw_cornice() -> void:
	var band := Rect2(0, _cornice_y() - CORNICE_HEIGHT, size.x, CORNICE_HEIGHT)
	draw_rect(band, RING_COLOR.darkened(0.15))
	draw_line(band.position, Vector2(band.end.x, band.position.y), Color(1, 1, 1, 0.07), 2.0)
	draw_polygon(_corners(Rect2(0, band.end.y, size.x, 16.0)),
		PackedColorArray([Color(0, 0, 0, 0.5), Color(0, 0, 0, 0.5), Color(0, 0, 0, 0), Color(0, 0, 0, 0)]))


## A banner at `x` on its rod under the cornice: navy cloth in folds, a gold
## trim and diamond, cut into a swallowtail.
func _draw_banner(x: float) -> void:
	var top := _cornice_y() + CORNICE_GAP
	var half := BANNER_SIZE.x * 0.5
	var bottom := top + BANNER_SIZE.y
	var cloth := PackedVector2Array([Vector2(x - half, top), Vector2(x + half, top), Vector2(x + half, bottom),
		Vector2(x, bottom - BANNER_NOTCH), Vector2(x - half, bottom)])
	var light := BANNER_COLOR.lightened(0.12)
	var dark := BANNER_COLOR.darkened(0.45)
	draw_polygon(cloth, PackedColorArray([light, light, dark, dark.darkened(0.2), dark]))
	for fold: float in [-0.45, 0.2]:
		draw_line(Vector2(x + fold * half, top + 4.0), Vector2(x + fold * half, bottom - 10.0), Color(0, 0, 0, 0.28), 4.0)
	var trim := PackedVector2Array([Vector2(x - half + 4.0, top + 2.0), Vector2(x - half + 4.0, bottom - 6.0),
		Vector2(x, bottom - BANNER_NOTCH - 5.0), Vector2(x + half - 4.0, bottom - 6.0), Vector2(x + half - 4.0, top + 2.0)])
	draw_polyline(trim, Color(UiStyle.BORDER_COLOR, 0.75), 1.5, true)
	var emblem := Vector2(x, top + BANNER_SIZE.y * 0.36)
	draw_colored_polygon(_diamond(emblem, 11.0), Color(UiStyle.BORDER_COLOR, 0.9))
	draw_colored_polygon(_diamond(emblem, 6.0), BANNER_COLOR.darkened(0.2))
	draw_colored_polygon(_diamond(emblem, 2.5), Color(UiStyle.GOLD_COLOR, 0.9))
	draw_line(Vector2(x - half - 8.0, top), Vector2(x + half + 8.0, top), CHAIN_COLOR.darkened(0.3), 4.0)
	for end: float in [-1.0, 1.0]:
		draw_circle(Vector2(x + end * (half + 9.0), top), 3.5, CHAIN_COLOR)


## The polished floor: tiles in perspective, a shade lighter or darker in
## turn and fading towards the viewer, with the piers mirrored in them.
func _draw_floor(floor_y: float, extra: int) -> void:
	var vanish := Vector2(size.x * 0.5, floor_y - VANISH_HEIGHT)
	var rows: Array[float] = [floor_y]
	for depth in FLOOR_DEPTHS:
		rows.append(minf(vanish.y + VANISH_HEIGHT / depth, size.y))
	if rows[-1] < size.y:
		rows.append(size.y)
	var first := card_rect(-extra).position.x - SkinShop.GAP * 0.5
	var columns := (Skins.ALL.size() + extra * 2) * 2
	var step := _pitch() * 0.5
	for row in rows.size() - 1:
		var near := rows[row + 1]
		if near <= rows[row]:
			break
		var far_color := FLOOR_FAR.lerp(FLOOR_NEAR, inverse_lerp(floor_y, size.y, rows[row]))
		var near_color := FLOOR_FAR.lerp(FLOOR_NEAR, inverse_lerp(floor_y, size.y, near))
		for column in columns:
			var left := first + column * step
			var shade := TILE_SHADE if (row + column) % 2 == 0 else -TILE_SHADE
			var top := far_color.lightened(shade) if shade > 0.0 else far_color.darkened(-shade)
			var bottom := near_color.lightened(shade) if shade > 0.0 else near_color.darkened(-shade)
			draw_polygon(PackedVector2Array([_on_floor(vanish, left, rows[row]), _on_floor(vanish, left + step, rows[row]),
				_on_floor(vanish, left + step, near), _on_floor(vanish, left, near)]), PackedColorArray([top, top, bottom, bottom]))
	for column in columns + 1:
		var x := first + column * step
		draw_line(_on_floor(vanish, x, floor_y), _on_floor(vanish, x, size.y), JOINT_COLOR, 1.5, true)
	for y in rows.slice(1):
		draw_line(Vector2(0, y), Vector2(size.x, y), JOINT_COLOR, 1.0)
	# The piers mirrored, dark.
	for i in range(-extra, Skins.ALL.size() + extra + 1):
		var x := card_rect(i).position.x - SkinShop.GAP * 0.5
		_draw_fade(Rect2(x - PIER_WIDTH * 0.5, floor_y, PIER_WIDTH, REFLECTION), Color(0, 0, 0, 0.35))
	draw_line(Vector2(0, floor_y + 1.0), Vector2(size.x, floor_y + 1.0), Color(1, 1, 1, 0.07), 2.0)


## The point of the floor at height `y` on the line from the floor line's `x`
## to the vanishing point.
static func _on_floor(vanish: Vector2, x: float, y: float) -> Vector2:
	return Vector2(vanish.x + (x - vanish.x) * (y - vanish.y) / VANISH_HEIGHT, y)


## Arch `index`'s light: the glow behind its card, its plinth, the cone from
## its lamp to the floor and the pool and reflection there, and the lamp on
## its chain.
func _draw_light(index: int, floor_y: float) -> void:
	var tint := arch_accent(index)
	var card := card_rect(index)
	var glow := JourneyMap.glow()
	draw_texture_rect(glow, card.grow_individual(card.size.x * 0.5, card.size.y * 0.4, card.size.x * 0.5, card.size.y * 0.25), false, Color(tint, 0.3))
	var plinth := Rect2(card.position.x - PLINTH.x * 0.5, card.end.y, card.size.x + PLINTH.x, PLINTH.y)
	# The plinth's face, lit from above in the arch's light.
	var face := PLINTH_COLOR.lerp(tint, 0.3)
	draw_polygon(_corners(plinth), PackedColorArray([face, face, PLINTH_COLOR.darkened(0.45), PLINTH_COLOR.darkened(0.45)]))
	draw_rect(plinth, MORTAR_COLOR, false, 1.0)
	draw_line(plinth.position + Vector2(1, 1.5), Vector2(plinth.end.x - 1.0, plinth.position.y + 1.5), Color(tint.lightened(0.3), 0.7), 2.0)
	var lamp := _lamp_at(index)
	var top := lamp + Vector2(0, LAMP_SIZE.y * 0.5)
	var bottom := Vector2(top.x, floor_y)
	var half_top := CONE_TOP * 0.5
	var half_bottom := _pitch() * CONE_SPREAD * 0.5
	var clear := Color(tint, 0.0)
	for side: float in [-1.0, 1.0]:
		draw_polygon(PackedVector2Array([top, top + Vector2(side * half_top, 0), bottom + Vector2(side * half_bottom, 0), bottom]),
			PackedColorArray([Color(tint, CONE_ALPHA.x), clear, clear, Color(tint, CONE_ALPHA.y)]))
	# In the floor: the card mirrored (dark, its gold edges faint), the cone
	# mirrored, and the pool where the light lands.
	var mirror := Rect2(card.position.x, floor_y + 2.0, card.size.x, REFLECTION * 0.8)
	_draw_fade(mirror, Color(0.02, 0.025, 0.035, 0.6))
	for x: float in [mirror.position.x + 1.0, mirror.end.x - 1.0]:
		draw_polyline_colors(PackedVector2Array([Vector2(x, mirror.position.y), Vector2(x, mirror.end.y)]),
			PackedColorArray([Color(UiStyle.BORDER_COLOR, 0.22), Color(UiStyle.BORDER_COLOR, 0.0)]), 2.0)
	var deep := Vector2(top.x, floor_y + REFLECTION)
	for side: float in [-1.0, 1.0]:
		draw_polygon(PackedVector2Array([bottom, bottom + Vector2(side * half_bottom, 0), deep + Vector2(side * half_bottom * 0.75, 0), deep]),
			PackedColorArray([Color(tint, CONE_ALPHA.x * 0.5), clear, clear, clear]))
	draw_texture_rect(glow, Rect2(card.get_center().x - card.size.x * 0.75, floor_y - 26.0, card.size.x * 1.5, 70.0), false, Color(tint, 0.35))
	_draw_lamp(lamp, tint, niche(index).position.y)


## A lantern centred at `at`, hanging on its chain from `hook_y`: a dark
## iron roof, frame and foot round glass glowing in `tint`, a flame inside.
func _draw_lamp(at: Vector2, tint: Color, hook_y: float) -> void:
	var half := LAMP_SIZE * 0.5
	var iron := CHAIN_COLOR.darkened(0.55)
	var roof := at.y - half.y
	JourneyMap.draw_chain(self, Vector2(at.x, hook_y), Vector2(at.x, roof - 12.0), CHAIN_COLOR, 10.0, 2.0)
	var glow := JourneyMap.glow()
	draw_texture_rect(glow, Rect2(at - Vector2.ONE * 150.0, Vector2.ONE * 300.0), false, Color(tint, 0.3))
	var glass := PackedVector2Array([Vector2(at.x - half.x, roof), Vector2(at.x + half.x, roof),
		Vector2(at.x + half.x * 0.75, at.y + half.y), Vector2(at.x - half.x * 0.75, at.y + half.y)])
	draw_colored_polygon(glass, tint.lightened(0.2))
	draw_texture_rect(glow, Rect2(at - Vector2(half.x, half.y * 0.9), Vector2(LAMP_SIZE.x, LAMP_SIZE.y * 1.4)), false, tint.lightened(0.75))
	draw_circle(at + Vector2(0, 2.0), 2.5, Color(1, 1, 1, 0.95))
	glass.append(glass[0])
	draw_polyline(glass, iron, 2.0, true)
	draw_line(Vector2(at.x, roof), Vector2(at.x, at.y + half.y), Color(iron, 0.8), 1.5)
	draw_colored_polygon(PackedVector2Array([Vector2(at.x, roof - 9.0), Vector2(at.x + half.x + 4.0, roof + 1.0), Vector2(at.x - half.x - 4.0, roof + 1.0)]), iron)
	draw_arc(Vector2(at.x, roof - 12.0), 3.0, 0.0, TAU, 12, iron, 1.5, true)
	draw_rect(Rect2(at.x - half.x * 0.75 - 2.0, at.y + half.y, LAMP_SIZE.x * 0.75 + 4.0, 4.0), iron)
	draw_texture_rect(glow, Rect2(at - Vector2.ONE * 40.0, Vector2.ONE * 80.0), false, Color(tint.lightened(0.4), 0.45))


## Dust sinking slowly through each lamp's beam over its card, and drifting
## over the pool of light on the floor; it fades in and out.
func _draw_dust() -> void:
	var count := Skins.ALL.size()
	var floor_y := _floor_y()
	var glow := JourneyMap.glow()
	for i in _mote_seeds.size():
		var mote := _mote_seeds[i]
		var index := i % count
		var lamp := _lamp_at(index)
		var card := card_rect(index)
		var in_beam := mote.z < DUST_IN_BEAMS
		var top := lamp.y + LAMP_SIZE.y if in_beam else card.end.y
		var span := card.position.y - top if in_beam else floor_y + DUST_POOL - top
		var t := fposmod(mote.y + _time * DUST_SPEED * (0.5 + mote.z) / span, 1.0)
		var y := top + t * span
		# Within the cone's width at that height.
		var half := lerpf(CONE_TOP, _pitch() * CONE_SPREAD, inverse_lerp(lamp.y, floor_y, y)) * 0.5
		var at := Vector2(lamp.x + (mote.x * 2.0 - 1.0) * half + sin(_time * 0.4 + mote.z * 11.0) * 8.0, y)
		var alpha := sin(PI * t) * (0.5 + 0.3 * sin(_time * 1.1 + mote.z * 17.0))
		var color := arch_accent(index).lerp(Color.WHITE, 0.6)
		motes.draw_texture_rect(glow, Rect2(at - Vector2.ONE * DUST_GLOW * 0.5, Vector2.ONE * DUST_GLOW), false, Color(color, alpha * 0.5))
		motes.draw_circle(at, 0.8 + mote.x * 1.0, Color(color, alpha))


## A vertical fade from `color` at the top of `rect` to clear at its bottom.
func _draw_fade(rect: Rect2, color: Color) -> void:
	draw_polygon(_corners(rect), PackedColorArray([color, color, Color(color, 0.0), Color(color, 0.0)]))


## Lamp `index`'s centre: its chain's length under the arch's crown.
func _lamp_at(index: int) -> Vector2:
	var rect := niche(index)
	return Vector2(rect.get_center().x, rect.position.y + CHAIN_LENGTH + LAMP_SIZE.y * 0.5 + 6.0)


## The gap between two cards' centres.
func _pitch() -> float:
	return SkinCard.SIZE.x + SkinShop.GAP


## An arch's inner radius: half its opening.
func _radius() -> float:
	return (_pitch() - PIER_WIDTH) * 0.5


## The cornice's bottom edge: CORNICE_GAP over the keystones' tops.
func _cornice_y() -> float:
	return niche(0).position.y - RING_WIDTH - KEY_RISE - CORNICE_GAP


## The floor line: the cards' foot plus their plinths.
func _floor_y() -> float:
	return card_rect(0).end.y + PLINTH.y


## An arch's opening: up from `bottom` on its left, round its curve about
## `center` and down to `bottom` on its right.
static func _arch_outline(center: Vector2, radius: float, bottom: float) -> PackedVector2Array:
	var points := PackedVector2Array([Vector2(center.x - radius, bottom)])
	for k in ARC_STEPS + 1:
		points.append(center + Vector2.from_angle(PI + PI * k / ARC_STEPS) * radius)
	points.append(Vector2(center.x + radius, bottom))
	return points


## `rect`'s corners, clockwise from its top left.
static func _corners(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])


static func _diamond(at: Vector2, radius: float) -> PackedVector2Array:
	return PackedVector2Array([at + Vector2(0, -radius), at + Vector2(radius, 0), at + Vector2(0, radius), at + Vector2(-radius, 0)])


## Dark corners, clear in the middle.
static func _vignette_texture() -> Texture2D:
	if _vignette == null:
		var gradient := Gradient.new()
		gradient.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
		gradient.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 1)])
		_vignette = GradientTexture2D.new()
		_vignette.gradient = gradient
		_vignette.fill = GradientTexture2D.FILL_RADIAL
		_vignette.fill_from = Vector2(0.5, 0.5)
		_vignette.fill_to = Vector2(1.15, 0.5)
	return _vignette


static func _rng(salt: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = salt * 7919
	return rng

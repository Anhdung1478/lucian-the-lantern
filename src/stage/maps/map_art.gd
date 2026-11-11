class_name MapArt
extends RefCounted
## The battlefields' art kit: small drawing helpers for a StageMap's _draw,
## which passes itself as the `canvas`. One look for every map:
## - The light comes from the top-left. A wall casts a shadow to the
##   bottom-right (SHADOW_DIR) and catches the light on its other side.
## - Everything is seeded: take the dice from rng(), and a map looks the same
##   every time.
## - Wall art stays inside its wall. Only shadows and flat marks lie on the
##   ground a unit walks on, and none is strong enough to hide a unit or a
##   red warning.
## A map is drawn once, but the renderer walks its commands every frame, so
## the kit draws in two cheap ways:
## - Stamps: round and soft shapes are two shared textures (disc, soft),
##   drawn as rects. Thousands batch into a few draw calls, as long as the
##   stamps of one texture come in a run.
## - Facets: thin and flat shapes (blades, cracks, a rock's faces, ripples)
##   are gathered into one mesh: one draw call however many there are.
## A polygon, an arc or an antialiased line is a draw call of its own: the
## helpers that draw them say so. Keep those to a few hundred a map.

## Shadows fall this way: the light comes from the top-left.
const SHADOW_DIR := Vector2(0.6, 0.8)
const SHADOW := Color(0.01, 0.01, 0.04)
## How dark a wall's shadow is at its foot.
const SHADOW_ALPHA := 0.42
## A round wall's shadow is this many discs in a row.
const SHADOW_STEPS := 4

## The stamps: their size in pixels, the clear margin round the shape, and
## the width of the disc's smooth edge.
const STAMP_SIZE := 128
const STAMP_MARGIN := 3.0
const DISC_EDGE := 1.5
## A stamp's rect over its shape's size: the margin is part of the texture.
const STAMP_REACH := STAMP_SIZE / (STAMP_SIZE - 2.0 * STAMP_MARGIN)

## How far past its bounds a map's outside is filled: past what the camera
## shows in play (StageMap.WALL_THICKNESS), enough for a zoomed-out view.
const OUTSIDE_REACH := 1600.0

## A grass tuft's blades, and a blade's width over its height.
const TUFT_BLADES := 3
const BLADE_WIDTH := 0.24
## A crack's pieces, and how far each may turn.
const CRACK_PIECES := 4
const CRACK_TURN := 0.7

## Tree crowns: the bushes along a jungle's edge (radius range), the crowns
## behind them (radius range, and the grid they stand on), how far a crown
## keeps from the edge so the bushes show, and how far into the jungle the
## crowns have darkened to CANOPY_DARK (less light gets in).
const BUSH_RADIUS := Vector2(18, 48)
const BUSH_STEP := 40.0
const BUSH_LOBES := 4
## Whether an edge has open ground along it: probed this far apart, this far
## outside the wall.
const EDGE_PROBE := 110.0
const EDGE_BEYOND := 3.0
const CROWN_RADIUS := Vector2(64, 124)
const CROWN_GRID := 132.0
const CROWN_INSET := 8.0
const CANOPY_DEPTH := 700.0
const CANOPY_DARK := 0.34
## A crown's leaf clumps round its middle, and how far out they sit and how
## big they are (shares of its radius).
const CROWN_LOBES := 6
const LOBE_REACH := 0.48
const LOBE_RADIUS := Vector2(0.4, 0.5)

## A rock: its sides, how far its outline and its flat top are from its
## middle (shares of its radius), and how far the top leans to the light.
const ROCK_SIDES := 9
const ROCK_OUTLINE := Vector2(0.9, 1.0)
const ROCK_TOP := Vector2(0.46, 0.62)
const ROCK_LEAN := 0.14

## A bare tree's limbs: the pieces of each (and how long each is, a share
## of the radius), and how far it may turn.
const LIMB_PIECES := 3
const LIMB_LENGTH := 0.3
const LIMB_TURN := 0.45

## Water: how many bands of depth it has, and its foam line's width.
const WATER_BANDS := 3
const FOAM_WIDTH := 5.0
## A ripple: its arc (radians, from and to), its pieces and its width.
const RIPPLE_ARC := Vector2(PI * 1.12, PI * 1.88)
const RIPPLE_PIECES := 7
const RIPPLE_WIDTH := 2.5

static var _disc: ImageTexture
static var _soft: ImageTexture


## Flat-coloured triangles, gathered and then drawn as one mesh: one draw
## call however many there are. Its edges are not antialiased, so it suits
## small or low-contrast shapes. Keep one under 60,000 points.
class Facets:
	extends RefCounted

	var points := PackedVector2Array()
	var colors := PackedColorArray()


	func triangle(a: Vector2, b: Vector2, c: Vector2, color: Color) -> void:
		points.append(a)
		points.append(b)
		points.append(c)
		colors.append(color)
		colors.append(color)
		colors.append(color)


	func quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, color: Color) -> void:
		triangle(a, b, c, color)
		triangle(a, c, d, color)


	## A straight line `width` wide.
	func line(from: Vector2, to: Vector2, width: float, color: Color) -> void:
		var side := (to - from).normalized().orthogonal() * width * 0.5
		quad(from + side, to + side, to - side, from - side, color)


	## A blade: `width` wide at `from`, a point at `to`.
	func blade(from: Vector2, to: Vector2, width: float, color: Color) -> void:
		var side := (to - from).normalized().orthogonal() * width * 0.5
		triangle(from + side, to, from - side, color)


	## A convex shape, from its outline.
	func fan(outline: PackedVector2Array, color: Color) -> void:
		for i in range(1, outline.size() - 1):
			triangle(outline[0], outline[i], outline[i + 1], color)


	## An arc `width` wide round `center`, in `pieces` straight pieces.
	func arc(center: Vector2, radius: float, from: float, to: float, width: float, color: Color, pieces: int) -> void:
		for i in pieces:
			var a := Vector2.from_angle(lerpf(from, to, float(i) / pieces))
			var b := Vector2.from_angle(lerpf(from, to, float(i + 1) / pieces))
			quad(center + a * (radius + width * 0.5), center + b * (radius + width * 0.5),
				center + b * (radius - width * 0.5), center + a * (radius - width * 0.5), color)


	## How many triangles it holds.
	func count() -> int:
		return floori(points.size() / 3.0)


	## Draws everything gathered so far on `canvas`, inside its _draw.
	func draw(canvas: CanvasItem) -> void:
		if points.is_empty():
			return
		var indices := PackedInt32Array()
		indices.resize(points.size())
		for i in points.size():
			indices[i] = i
		RenderingServer.canvas_item_add_triangle_array(canvas.get_canvas_item(), indices, points, colors)


# --- Dice and places ---------------------------------------------------------------


## The dice for one layer of a map's art: the same `seed_value`, the same art.
static func rng(seed_value: int) -> RandomNumberGenerator:
	var dice := RandomNumberGenerator.new()
	dice.seed = seed_value
	return dice


## `count` points thrown over `area`; with `keep` (point -> bool), only the
## points it says yes to.
static func scatter(dice: RandomNumberGenerator, area: Rect2, count: int, keep := Callable()) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in count:
		var point := area.position + Vector2(dice.randf(), dice.randf()) * area.size
		if not keep.is_valid() or keep.call(point):
			points.append(point)
	return points


## `count` points thrown over the band from `from` to `to`, `half` px to
## each side of that line (a lane, a path, a bank); with `keep`
## (point -> bool), only the points it says yes to.
static func scatter_band(dice: RandomNumberGenerator, from: Vector2, to: Vector2, half: float, count: int, keep := Callable()) -> PackedVector2Array:
	var points := PackedVector2Array()
	var side := (to - from).normalized().orthogonal() * half
	for i in count:
		var point := from.lerp(to, dice.randf()) + side * dice.randf_range(-1.0, 1.0)
		if not keep.is_valid() or keep.call(point):
			points.append(point)
	return points


## One point in every `cell` × `cell` square of `area`, anywhere in its
## square: spread evenly, yet not in rows. With `keep` (point -> bool), only
## the points it says yes to. From the bottom-right square to the top-left
## one, so what is drawn at each point lies over the ones before it, as the
## light has it.
static func grid(dice: RandomNumberGenerator, area: Rect2, cell: float, keep := Callable()) -> PackedVector2Array:
	var points := PackedVector2Array()
	var columns := ceili(area.size.x / cell)
	var rows := ceili(area.size.y / cell)
	for row in range(rows - 1, -1, -1):
		for column in range(columns - 1, -1, -1):
			var point := area.position + Vector2(column + dice.randf(), row + dice.randf()) * cell
			if area.has_point(point) and (not keep.is_valid() or keep.call(point)):
				points.append(point)
	return points


## Points every `step` px along `polygon`'s outline, each moved `inset` px
## into the polygon (out of it, below 0). With `keep` (point -> bool), only
## the points it says yes to.
static func along(polygon: PackedVector2Array, step: float, inset := 0.0, keep := Callable()) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in polygon.size():
		points.append_array(along_edge(polygon, i, step, inset, keep))
	return points


## along(), for the one edge `index` of `polygon` (from that point to the
## next).
static func along_edge(polygon: PackedVector2Array, index: int, step: float, inset := 0.0, keep := Callable()) -> PackedVector2Array:
	var points := PackedVector2Array()
	var from := polygon[index]
	var to := polygon[(index + 1) % polygon.size()]
	var length := from.distance_to(to)
	var shift := inward(polygon, index) * inset
	var at := step * 0.5
	while at < length:
		var point := from.lerp(to, at / length) + shift
		if not keep.is_valid() or keep.call(point):
			points.append(point)
		at += step
	return points


## The unit vector across `polygon`'s edge `index` (from that point to the
## next) that points into the polygon.
static func inward(polygon: PackedVector2Array, index: int) -> Vector2:
	var from := polygon[index]
	var to := polygon[(index + 1) % polygon.size()]
	var normal := (to - from).normalized().orthogonal()
	return normal if Geometry2D.is_point_in_polygon((from + to) * 0.5 + normal, polygon) else -normal


## How far `point` is from `polygon`'s outline.
static func edge_distance(point: Vector2, polygon: PackedVector2Array) -> float:
	var best := INF
	for i in polygon.size():
		var closest := Geometry2D.get_closest_point_to_segment(point, polygon[i], polygon[(i + 1) % polygon.size()])
		best = minf(best, point.distance_squared_to(closest))
	return sqrt(best)


## How far `point` is from the nearest of `polygon`'s edges in `edges` (each
## from that point to the next), or INF with none.
static func _distance_to_edges(point: Vector2, polygon: PackedVector2Array, edges: PackedInt32Array) -> float:
	var best := INF
	for i in edges:
		var closest := Geometry2D.get_closest_point_to_segment(point, polygon[i], polygon[(i + 1) % polygon.size()])
		best = minf(best, point.distance_squared_to(closest))
	return sqrt(best)


## The land round `bounds`, `reach` px out: the strips over it, under it, on
## its left and on its right.
static func border(bounds: Rect2, reach: float) -> Array[Rect2]:
	return [
		Rect2(bounds.position.x - reach, bounds.position.y - reach, bounds.size.x + 2.0 * reach, reach),
		Rect2(bounds.position.x - reach, bounds.end.y, bounds.size.x + 2.0 * reach, reach),
		Rect2(bounds.position.x - reach, bounds.position.y, reach, bounds.size.y),
		Rect2(bounds.end.x, bounds.position.y, reach, bounds.size.y),
	]


static func polygon_of(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])


## The smallest box holding `polygon`.
static func bounds_of(polygon: PackedVector2Array) -> Rect2:
	var box := Rect2(polygon[0], Vector2.ZERO)
	for point in polygon:
		box = box.expand(point)
	return box


# --- Stamps ------------------------------------------------------------------------


## The disc stamp: white, round, with a smooth edge. Its mipmaps keep small
## discs smooth on a canvas that uses them (StageMap does).
static func disc_texture() -> Texture2D:
	if _disc == null:
		_disc = _stamp(false)
	return _disc


## The soft stamp: white in the middle, fading to nothing at its edge.
static func soft_texture() -> Texture2D:
	if _soft == null:
		_soft = _stamp(true)
	return _soft


## A filled circle. A stamp.
static func disc(canvas: CanvasItem, at: Vector2, radius: float, color: Color) -> void:
	canvas.draw_texture_rect(disc_texture(), _stamp_rect(at, radius), false, color)


## A filled oval, `radii.x` wide and `radii.y` tall each way. A stamp.
static func oval(canvas: CanvasItem, at: Vector2, radii: Vector2, color: Color) -> void:
	var half := radii * STAMP_REACH
	canvas.draw_texture_rect(disc_texture(), Rect2(at - half, half * 2.0), false, color)


## A soft round patch: `color` in the middle, nothing at `radius`. A stamp.
static func glow(canvas: CanvasItem, at: Vector2, radius: float, color: Color) -> void:
	canvas.draw_texture_rect(soft_texture(), _stamp_rect(at, radius), false, color)


## A soft oval patch. A stamp.
static func soft_oval(canvas: CanvasItem, at: Vector2, radii: Vector2, color: Color) -> void:
	var half := radii * STAMP_REACH
	canvas.draw_texture_rect(soft_texture(), Rect2(at - half, half * 2.0), false, color)


## The rect a round stamp of `radius` at `at` is drawn in.
static func _stamp_rect(at: Vector2, radius: float) -> Rect2:
	var half := radius * STAMP_REACH
	return Rect2(at.x - half, at.y - half, half * 2.0, half * 2.0)


static func _stamp(soft: bool) -> ImageTexture:
	var data := PackedByteArray()
	data.resize(STAMP_SIZE * STAMP_SIZE * 4)
	data.fill(255)
	var middle := (STAMP_SIZE - 1) * 0.5
	var radius := STAMP_SIZE * 0.5 - STAMP_MARGIN
	for y in STAMP_SIZE:
		for x in STAMP_SIZE:
			var distance := Vector2(x - middle, y - middle).length()
			var alpha := clampf((radius - distance) / DISC_EDGE + 0.5, 0.0, 1.0)
			if soft:
				var share := minf(distance / radius, 1.0)
				alpha = (1.0 - share * share) * (1.0 - share * share)
			data[(y * STAMP_SIZE + x) * 4 + 3] = roundi(alpha * 255.0)
	var image := Image.create_from_data(STAMP_SIZE, STAMP_SIZE, false, Image.FORMAT_RGBA8, data)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


# --- The ground --------------------------------------------------------------------


## The land outside `bounds`, filled with `color` as far as OUTSIDE_REACH, so
## no flat band or void shows past the border. Draw the map's own outside
## (trees, a wall's top) over it.
static func outside(canvas: CanvasItem, bounds: Rect2, color: Color) -> void:
	for rect in border(bounds, OUTSIDE_REACH):
		canvas.draw_rect(rect, color)


## `count` large soft patches over `area`, `light` and `dark` in turn, each
## `radii.x` to `radii.y` px: the ground's flat tint, broken up. Stamps.
static func patches(canvas: CanvasItem, dice: RandomNumberGenerator, area: Rect2, count: int, radii: Vector2, light: Color, dark: Color) -> void:
	for i in count:
		var at := area.position + Vector2(dice.randf(), dice.randf()) * area.size
		var radius := dice.randf_range(radii.x, radii.y)
		soft_oval(canvas, at, Vector2(radius * dice.randf_range(1.0, 1.5), radius), light if i % 2 == 0 else dark)


## A soft band from `from` to `to`: `color` along its middle, nothing `half`
## px to each side (a worn path, a wet bank). Two polygons.
static func band(canvas: CanvasItem, from: Vector2, to: Vector2, half: float, color: Color) -> void:
	var side := (to - from).normalized().orthogonal() * half
	var clear := Color(color, 0.0)
	canvas.draw_polygon(PackedVector2Array([from + side, to + side, to, from]), PackedColorArray([clear, clear, color, color]))
	canvas.draw_polygon(PackedVector2Array([from, to, to - side, from - side]), PackedColorArray([color, color, clear, clear]))


## A grass tuft at `at`: a few blades `height` px tall, fanning up. Facets.
static func tuft(into: Facets, dice: RandomNumberGenerator, at: Vector2, height: float, color: Color) -> void:
	for i in TUFT_BLADES:
		var lean := (i - (TUFT_BLADES - 1) * 0.5) * 0.5 + dice.randf_range(-0.2, 0.2)
		var root := at + Vector2((i - (TUFT_BLADES - 1) * 0.5) * height * 0.16, 0.0)
		into.blade(root, root + Vector2(sin(lean), -cos(lean)) * height * dice.randf_range(0.65, 1.0), height * BLADE_WIDTH, color)


## A pebble at `at`: its shadow, its body and a lighter top. Stamps.
static func pebble(canvas: CanvasItem, dice: RandomNumberGenerator, at: Vector2, radius: float, color: Color) -> void:
	var radii := Vector2(radius, radius * dice.randf_range(0.7, 0.95))
	oval(canvas, at + SHADOW_DIR * radius * 0.4, radii, Color(SHADOW, 0.3))
	oval(canvas, at, radii, color)
	oval(canvas, at - SHADOW_DIR * radius * 0.25, radii * 0.55, color.lightened(0.16))


## A crack from `at`, about `length` px long: a few straight pieces that
## turn a little, and a short branch. Facets.
static func crack(into: Facets, dice: RandomNumberGenerator, at: Vector2, length: float, width: float, color: Color) -> void:
	var heading := dice.randf() * TAU
	var from := at
	for i in CRACK_PIECES:
		heading += dice.randf_range(-CRACK_TURN, CRACK_TURN)
		var to := from + Vector2.from_angle(heading) * length / CRACK_PIECES
		into.line(from, to, width, color)
		if i == 1:
			into.blade(to, to + Vector2.from_angle(heading + dice.randf_range(0.7, 1.2)) * length * 0.3, width, color)
		from = to


## Stone slabs over `area`: rows of `tile`-sized slabs, every other row
## moved `stagger` of a slab along (0: a straight grid). Each slab is
## `color`, lighter or darker by up to `spread`, with `joint_color` showing
## `joint` px wide between slabs, a lit line along its top and left and a
## dark one along its bottom and right. Rects: they batch.
static func tiles(canvas: CanvasItem, dice: RandomNumberGenerator, area: Rect2, tile: Vector2, color: Color, joint_color: Color,
		spread := 0.04, joint := 4.0, stagger := 0.5) -> void:
	canvas.draw_rect(area, joint_color)
	var lit := Color(1, 1, 1, 0.05)
	var shaded := Color(SHADOW, 0.16)
	var row := 0
	var y := area.position.y
	while y < area.end.y:
		var x := area.position.x - (tile.x * stagger if row % 2 == 1 else 0.0)
		while x < area.end.x:
			var slab := Rect2(x, y, tile.x, tile.y).grow(-joint * 0.5).intersection(area)
			x += tile.x
			if slab.size.x <= joint or slab.size.y <= joint:
				continue
			var shade := dice.randf_range(-spread, spread)
			canvas.draw_rect(slab, color.lightened(shade) if shade > 0.0 else color.darkened(-shade))
			canvas.draw_rect(Rect2(slab.position, Vector2(slab.size.x, 2.0)), lit)
			canvas.draw_rect(Rect2(slab.position, Vector2(2.0, slab.size.y)), lit)
			canvas.draw_rect(Rect2(slab.position.x, slab.end.y - 2.0, slab.size.x, 2.0), shaded)
			canvas.draw_rect(Rect2(slab.end.x - 2.0, slab.position.y, 2.0, slab.size.y), shaded)
		y += tile.y
		row += 1


## Darkens the map toward its far edges: nothing `depth` px inside `bounds`,
## `darkness` at the border and over the land outside. Draw it last: the map
## is under every unit, so it dims the ground only. Four polygons.
static func vignette(canvas: CanvasItem, bounds: Rect2, depth: float, darkness: float) -> void:
	var dark := Color(SHADOW, darkness)
	var clear := Color(SHADOW, 0.0)
	var outer := polygon_of(bounds)
	var inner := polygon_of(bounds.grow(-depth))
	for i in 4:
		var next := (i + 1) % 4
		canvas.draw_polygon(PackedVector2Array([outer[i], outer[next], inner[next], inner[i]]), PackedColorArray([dark, dark, clear, clear]))
	outside(canvas, bounds, dark)


# --- Walls -------------------------------------------------------------------------


## The shadow a wall `polygon` of `height` casts on the ground: `darkness`
## at the wall's foot, fading to nothing at its far edge. Draw it before the
## wall. A polygon per edge that faces away from the light.
static func cast_shadow(canvas: CanvasItem, polygon: PackedVector2Array, height: float, darkness := SHADOW_ALPHA) -> void:
	var shift := SHADOW_DIR * height
	var dark := Color(SHADOW, darkness)
	var clear := Color(SHADOW, 0.0)
	for i in polygon.size():
		if inward(polygon, i).dot(SHADOW_DIR) >= 0.0:
			continue
		var from := polygon[i]
		var to := polygon[(i + 1) % polygon.size()]
		canvas.draw_polygon(PackedVector2Array([from, to, to + shift, from + shift]), PackedColorArray([dark, dark, clear, clear]))


## The shadow of a round wall (a rock, a pillar, a trunk) of `radius` and
## `height`. Draw it before the wall. Stamps.
static func round_shadow(canvas: CanvasItem, at: Vector2, radius: float, height: float, darkness := SHADOW_ALPHA) -> void:
	var layer := Color(SHADOW, 1.0 - pow(1.0 - darkness, 1.0 / SHADOW_STEPS))
	for step in range(1, SHADOW_STEPS + 1):
		disc(canvas, at + SHADOW_DIR * height * step / SHADOW_STEPS, radius, layer)
	glow(canvas, at + SHADOW_DIR * height, radius * 1.5, Color(SHADOW, darkness * 0.6))


## A line along a wall `polygon`'s outline: `lit` on the edges that face the
## light, `shaded` on the others. An antialiased line per edge.
static func rim(canvas: CanvasItem, polygon: PackedVector2Array, lit: Color, shaded: Color, width: float) -> void:
	for i in polygon.size():
		var facing := inward(polygon, i).dot(SHADOW_DIR)
		canvas.draw_line(polygon[i], polygon[(i + 1) % polygon.size()], shaded.lerp(lit, smoothstep(-0.25, 0.25, facing)), width, true)


## A stone wall round `bounds`, `thickness` px thick (a map's border rects),
## `height` tall: its shadow on the floor, `block`-sized blocks of `color`
## along it (turned on its sides), and a line along its inner edge, lit
## where the wall faces the light. Draw it after the floor. Rects, then a
## few polygons and lines.
static func wall_ring(canvas: CanvasItem, dice: RandomNumberGenerator, bounds: Rect2, thickness: float, block: Vector2, color: Color, height: float) -> void:
	for rect in border(bounds, thickness):
		cast_shadow(canvas, polygon_of(rect), height)
	for rect in border(bounds, thickness):
		var turned := block if rect.size.x > rect.size.y else Vector2(block.y, block.x)
		tiles(canvas, dice, rect, turned, color, color.darkened(0.45), 0.07, 3.0)
	# The floor is a hole in the wall: where the floor's edge faces the light,
	# the wall's faces away from it.
	rim(canvas, polygon_of(bounds), Color(SHADOW, 0.5), color.lightened(0.3), 4.0)


## Tree crowns over a jungle wall `polygon`. `under` fills it: the dark
## under the trees. Bushes line its edge and crowns in `tints` fill the
## rest. The trees at the edge are the brightest, and catch `light` where
## the edge faces it; deep in the jungle they darken.
## `open` (point -> bool) says whether the ground at a point is open: a map
## can pass is_walkable.bind(0.0). An edge with open ground along it is an
## edge of the jungle: bushes line it and no crown reaches over it, so the
## wall stays where it is. An edge with none (the map's border, another
## wall) is not: the jungle goes on there, and crowns may reach over it.
## Without `open`, every edge is an edge of the jungle. One polygon, then
## stamps.
static func canopy(canvas: CanvasItem, dice: RandomNumberGenerator, polygon: PackedVector2Array, tints: PackedColorArray, light: Color, under: Color, open := Callable()) -> void:
	canvas.draw_colored_polygon(polygon, under)
	var edges := PackedInt32Array()
	for i in polygon.size():
		if not open.is_valid() or not along_edge(polygon, i, EDGE_PROBE, -EDGE_BEYOND, open).is_empty():
			edges.append(i)
	for i in edges:
		var into := inward(polygon, i)
		var lit := 1.0 if into.dot(SHADOW_DIR) > 0.1 else 0.3
		for spot in along_edge(polygon, i, BUSH_STEP, 0.0):
			var radius := dice.randf_range(BUSH_RADIUS.x, BUSH_RADIUS.y)
			var center := spot + into * (radius + dice.randf_range(1.0, 6.0)) + into.orthogonal() * dice.randf_range(-0.3, 0.3) * BUSH_STEP
			if open.is_valid() and not open.call(spot - into * EDGE_BEYOND):
				continue
			if Geometry2D.is_point_in_polygon(center, polygon) and edge_distance(center, polygon) >= radius:
				crown(canvas, dice, center, radius, tints[dice.randi() % tints.size()], light, lit, BUSH_LOBES)
	var keep := func(point: Vector2) -> bool: return Geometry2D.is_point_in_polygon(point, polygon)
	for center in grid(dice, bounds_of(polygon), CROWN_GRID, keep):
		var depth := _distance_to_edges(center, polygon, edges)
		if depth - CROWN_INSET < BUSH_RADIUS.x:
			continue
		var radius := minf(dice.randf_range(CROWN_RADIUS.x, CROWN_RADIUS.y), depth - CROWN_INSET)
		var deep := clampf(depth / CANOPY_DEPTH, 0.0, 1.0)
		var lit := lerpf(0.8, 0.25, deep) * dice.randf_range(0.6, 1.0)
		var tint := tints[dice.randi() % tints.size()].darkened(CANOPY_DARK * deep)
		crown(canvas, dice, center, radius, tint, light, lit, CROWN_LOBES if deep < 0.5 else BUSH_LOBES)


## One tree crown seen from above, `radius` wide: its shadow on what lies
## under it, then `lobes` leaf clumps round a dark middle, the ones away
## from the light first and darker, the ones toward it last and lighter, and
## a few leaves that catch `light`. `lit` (0 to 1) is how much light it
## catches. Stamps.
static func crown(canvas: CanvasItem, dice: RandomNumberGenerator, at: Vector2, radius: float, tint: Color, light: Color, lit: float, lobes := CROWN_LOBES) -> void:
	# Thousands of these are drawn: the stamps straight on the canvas.
	var stamp := disc_texture()
	canvas.draw_texture_rect(stamp, _stamp_rect(at + SHADOW_DIR * radius * 0.32, radius), false, Color(SHADOW, 0.36))
	canvas.draw_texture_rect(stamp, _stamp_rect(at, radius * 0.9), false, tint.darkened(0.3))
	var away := SHADOW_DIR.angle()
	for i in lobes:
		# In pairs, from the side away from the light round both ways to the lit side.
		var turn := PI * (floorf(i / 2.0) + dice.randf_range(0.2, 0.8)) / (lobes / 2.0) * (1.0 if i % 2 == 0 else -1.0)
		var facing := -cos(turn)
		var shade := tint.lightened(0.1 * facing * (0.4 + lit)) if facing > 0.0 else tint.darkened(-0.22 * facing)
		canvas.draw_texture_rect(stamp, _stamp_rect(at + Vector2.from_angle(away + turn) * radius * LOBE_REACH,
			radius * dice.randf_range(LOBE_RADIUS.x, LOBE_RADIUS.y)), false, shade)
	canvas.draw_texture_rect(stamp, _stamp_rect(at - SHADOW_DIR * radius * 0.14, radius * 0.5), false, tint.lightened(0.05 + 0.09 * lit))
	for i in floori(lobes / 3.0):
		var leaf := at - SHADOW_DIR.rotated(dice.randf_range(-0.9, 0.9)) * radius * dice.randf_range(0.3, 0.6)
		canvas.draw_texture_rect(stamp, _stamp_rect(leaf, radius * dice.randf_range(0.14, 0.24)), false, Color(light, 0.1 + 0.3 * lit))


## A rock filling the round wall at `at`: a ragged outline just inside
## `radius`, sloping faces (light toward the light, dark away from it) and a
## flat top that leans to the light, with a crack. Facets; draw its
## round_shadow first.
static func rock(into: Facets, dice: RandomNumberGenerator, at: Vector2, radius: float, color: Color) -> void:
	var outline := PackedVector2Array()
	var top := PackedVector2Array()
	var middle := at - SHADOW_DIR * radius * ROCK_LEAN
	var turn := dice.randf() * TAU
	for i in ROCK_SIDES:
		var direction := Vector2.from_angle(turn + TAU * (i + dice.randf_range(-0.22, 0.22)) / ROCK_SIDES)
		outline.append(at + direction * radius * dice.randf_range(ROCK_OUTLINE.x, ROCK_OUTLINE.y))
		top.append(middle + direction * radius * dice.randf_range(ROCK_TOP.x, ROCK_TOP.y))
	for i in ROCK_SIDES:
		var next := (i + 1) % ROCK_SIDES
		var facing := ((outline[i] + outline[next]) * 0.5 - at).normalized().dot(-SHADOW_DIR)
		var face := color.lightened(0.16 * facing) if facing > 0.0 else color.darkened(-0.5 * facing)
		into.quad(outline[i], outline[next], top[next], top[i], face.darkened(dice.randf_range(0.0, 0.08)))
	for i in ROCK_SIDES:
		into.triangle(middle, top[i], top[(i + 1) % ROCK_SIDES], color.lightened(0.2 + 0.05 * (i % 2)))
	for i in ROCK_SIDES:
		var next := (i + 1) % ROCK_SIDES
		if ((top[i] + top[next]) * 0.5 - middle).dot(-SHADOW_DIR) > 0.0:
			into.line(top[i], top[next], 2.5, color.lightened(0.42))
	crack(into, dice, middle + Vector2(dice.randf_range(-0.2, 0.2), dice.randf_range(-0.2, 0.2)) * radius, radius * 0.5, 2.0, color.darkened(0.45))


## A round stone pillar filling the round wall at `at`, seen from above: a
## plinth, the shaft's top a step in from it with a lit edge toward the
## light, and a ring of `trim` inlaid in the top. Stamps; draw its
## round_shadow first.
static func pillar(canvas: CanvasItem, at: Vector2, radius: float, color: Color, trim: Color) -> void:
	disc(canvas, at, radius, color.lightened(0.3))
	disc(canvas, at + SHADOW_DIR * 3.0, radius - 2.0, color.darkened(0.42))
	disc(canvas, at + SHADOW_DIR * radius * 0.1, radius * 0.82, Color(SHADOW, 0.5))
	disc(canvas, at, radius * 0.8, color.lightened(0.34))
	disc(canvas, at + SHADOW_DIR * 2.5, radius * 0.8 - 2.0, color)
	disc(canvas, at - SHADOW_DIR * radius * 0.1, radius * 0.6, color.lightened(0.1))
	disc(canvas, at, radius * 0.4, trim)
	disc(canvas, at, radius * 0.4 - 4.0, color.lightened(0.06))
	disc(canvas, at - SHADOW_DIR * radius * 0.36, radius * 0.16, Color(1, 1, 1, 0.16))


## The bare limbs of a dead tree seen from above, filling the round wall at
## `at`: `count` forking limbs of `color`, thick at the trunk and thin at
## the tips, from its middle to its edge, a thin line of `light` along the
## ones that face the light. All of it stays inside `radius`. Facets.
static func limbs(into: Facets, dice: RandomNumberGenerator, at: Vector2, radius: float, count: int, color: Color, light: Color) -> void:
	var reach := radius * 0.96
	for i in count:
		var heading := TAU * (i + dice.randf_range(-0.3, 0.3)) / count
		var from := at + Vector2.from_angle(heading) * radius * 0.1
		var width := radius * 0.11
		for piece in LIMB_PIECES:
			heading += dice.randf_range(-LIMB_TURN, LIMB_TURN)
			var to := at + (from + Vector2.from_angle(heading) * radius * LIMB_LENGTH - at).limit_length(reach)
			into.line(from, to, width, color)
			if Vector2.from_angle(heading).dot(-SHADOW_DIR) > 0.2:
				into.line(from - SHADOW_DIR * width * 0.3, to - SHADOW_DIR * width * 0.3, maxf(width * 0.3, 1.0), Color(light, 0.45))
			if piece == 1:
				var branch := heading + (0.8 if dice.randf() < 0.5 else -0.8)
				into.blade(to, at + (to + Vector2.from_angle(branch) * radius * LIMB_LENGTH - at).limit_length(reach), width * 0.8, color)
			from = to
			width *= 0.7


# --- Water -------------------------------------------------------------------------


## Water over `polygon`: `bank` at its edge, `deep` from `depth` px in, in
## WATER_BANDS steps, and a line of `foam` along the edge. A few polygons
## and one antialiased line.
static func water(canvas: CanvasItem, polygon: PackedVector2Array, deep: Color, bank: Color, foam: Color, depth: float) -> void:
	canvas.draw_colored_polygon(polygon, bank)
	for band_number in range(1, WATER_BANDS + 1):
		var share := float(band_number) / WATER_BANDS
		for inner in Geometry2D.offset_polygon(polygon, -depth * share, Geometry2D.JOIN_ROUND):
			canvas.draw_colored_polygon(inner, bank.lerp(deep, share))
	var edge := polygon.duplicate()
	edge.append(polygon[0])
	canvas.draw_polyline(edge, foam, FOAM_WIDTH, true)


## A ripple at `at`: a thin arc, open at the bottom. Facets.
static func ripple(into: Facets, at: Vector2, radius: float, color: Color) -> void:
	into.arc(at, radius, RIPPLE_ARC.x, RIPPLE_ARC.y, RIPPLE_WIDTH, color, RIPPLE_PIECES)

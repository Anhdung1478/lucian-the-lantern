class_name TitleFigure
extends Control
## One of the title's three figures, painted once in code (TitlePaint) in
## its own units: `box`, the art's frame, is scaled to the node's height.
## The backdrop gives the node its size and keeps it to the bottom and to
## one side. Every part is lit the same way: shaded across from the moon's
## side, with the lantern's soft green on the side facing it. Then the
## figure's outline, all its parts as one, gets a cool rim of moonlight on
## the moon's side and, while the lantern lights it, a green rim on the
## side facing that; the edges inside the outline are lit only faintly.

## The moonlight's rim, at the top of the figure and at its feet.
const MOON_RIM_TOP := Color(0.86, 0.92, 1.0, 0.95)
const MOON_RIM_FEET := Color(0.55, 0.66, 0.82, 0.3)
## The lantern's green.
const LANTERN_GREEN := Color("8fe3b0")
## A rim's soft outer band: how much wider than the rim, and how faint.
const SOFT_REACH := 2.6
const SOFT_ALPHA := 0.14
## A part's base, shaded across it: tinted towards MOON_TINT on the moon's
## side and darkened on the far one; and the lantern's soft fill on the
## side facing it (a share of its green's alpha there).
const MOON_TINT := Color("9fb6d8")
const LIT_SIDE := 0.07
const DARK_SIDE := 0.6
const FILL_ALPHA := 0.5
## How strong the lantern's crisp rim is, over its soft fill.
const LANTERN_RIM := 0.6
## How strongly the edges inside the outline are lit, over the outline's.
const INNER_RIM := 0.22
## How far a fold's light lies from its shadow (a share of its width), and
## how wide it is.
const FOLD_LIGHT_OFFSET := 0.55
const FOLD_LIGHT_WIDTH := 0.35

## The art's frame, in its own units.
var box: Rect2
## What a part's base is tinted towards on the moon's side.
var lit_tint := MOON_TINT
## The rim's colour at the top of the figure and at its feet.
var rim_top := MOON_RIM_TOP
var rim_feet := MOON_RIM_FEET
## How solid the figure's parts are at its feet, from fully solid at
## `fade_from` (a height in units): a spirit fades into the mist.
var feet_alpha := 1.0
var fade_from := 0.0
## A fold in the cloth: its shadow, and the light along its ridge.
var fold_dark := Color(0.0, 0.0, 0.02, 0.42)
var fold_light := Color(0.78, 0.86, 1.0, 0.13)
## Towards the moon, and the moonlit rim's width, in units.
var moon_way := Vector2(-0.45, -1.0).normalized()
var rim_width := 0.9
## The lantern, in units, and how far its light reaches; its rim's width.
var lantern_at := Vector2.ZERO
var lantern_reach := 1.0
var lantern_width := 1.1
## The parts painted so far, for the outline's rims.
var _parts: Array[PackedVector2Array] = []
## False once the lantern is gone (Thresh is hidden): no green on this
## figure. Setting it paints the figure again.
var lantern_lit := true:
	set(value):
		lantern_lit = value
		queue_redraw()


func _init(frame: Rect2) -> void:
	box = frame
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## The node's width at `height` px tall: the frame's shape.
func width_for(height: float) -> float:
	return roundf(height * box.size.x / box.size.y)


## `units` in the art, in the parent's coordinates.
func at(units: Vector2) -> Vector2:
	return position + (units - box.position) * size.y / box.size.y


func _draw() -> void:
	if size.y <= 0.0:
		return
	var scale_by := size.y / box.size.y
	draw_set_transform(-box.position * scale_by, 0.0, Vector2.ONE * scale_by)
	var paint := TitlePaint.new()
	_parts.clear()
	_paint(paint)
	_paint_outline(paint)
	paint.draw(self)


## Paints the figure, in units. Each figure paints its own.
func _paint(_paint_with: TitlePaint) -> void:
	pass


## Paints `outline` as one part: `base` shaded across it, lighter on the
## moon's side, the lantern's soft green on the side facing it, and its
## edges lit faintly. It counts towards the figure's outline.
func _part(paint: TitlePaint, outline: PackedVector2Array, base: Color) -> void:
	var middle := _middle(outline)
	var across := Vector2(signf(moon_way.x), 0.0)
	var reach := _reach(outline, middle, across)
	paint.shape(outline, _solid(TitlePaint.linear(middle + across * reach, middle - across * reach,
		base.lerp(lit_tint, LIT_SIDE), base.darkened(DARK_SIDE))))
	if lantern_lit:
		var way := (lantern_at - middle).normalized()
		var green: Color = _lantern_tint().call(middle)
		paint.shape(outline, TitlePaint.linear(middle, middle + way * _reach(outline, middle, way),
			Color(green, 0.0), Color(green, green.a * FILL_ALPHA)))
	paint.rim(outline, moon_way * rim_width, _moon_tint(INNER_RIM))
	if lantern_lit:
		paint.rim(outline, _lantern_way(outline) * lantern_width, _lantern_tint(LANTERN_RIM * INNER_RIM))
	_parts.append(outline)


## The rims of light along the figure's outline, over everything painted:
## moonlight, then the lantern's green. A part's rim is what is left of its
## lit band once every part moved back from the light is taken away, so
## only the edges with nothing beyond them shine.
func _paint_outline(paint: TitlePaint) -> void:
	var moon := _moon_tint()
	var green := _lantern_tint(LANTERN_RIM)
	for outline in _parts:
		for band in [moon_way * rim_width * SOFT_REACH, moon_way * rim_width]:
			paint.shapes(_outline_band(outline, band), _faded(moon, SOFT_ALPHA) if band.length() > rim_width else moon)
		if lantern_lit:
			var way := _lantern_way(outline)
			paint.shapes(_outline_band(outline, way * lantern_width * SOFT_REACH), _faded(green, SOFT_ALPHA))
			paint.shapes(_outline_band(outline, way * lantern_width), green)


## The band of `outline` facing `toward` (as TitlePaint.rim) with nothing
## beyond it: every part, moved back by `toward`, taken away.
func _outline_band(outline: PackedVector2Array, toward: Vector2) -> Array[PackedVector2Array]:
	var bands := TitlePaint.cut(outline, [TitlePaint.moved(outline, -toward)])
	var cutters: Array[PackedVector2Array] = []
	for band in bands:
		var reach := TitlePaint.bounds(band)
		for part in _parts:
			if part != outline and TitlePaint.bounds(part).grow(toward.length()).intersects(reach):
				cutters.append(TitlePaint.moved(part, -toward))
	var out: Array[PackedVector2Array] = []
	for band in bands:
		out.append_array(TitlePaint.cut(band, cutters))
	return out


## Towards the lantern from `outline`'s middle.
func _lantern_way(outline: PackedVector2Array) -> Vector2:
	return (lantern_at - _middle(outline)).normalized()


## A fold along `path`: a shadow that swells to `width` in its middle, and
## a thin light along its ridge on the moon's side.
func _fold(paint: TitlePaint, path: String, width: float) -> void:
	var line := TitlePaint.outline(path)
	paint.taper(line, 0.0, 0.0, _solid(fold_dark), width)
	paint.taper(TitlePaint.moved(line, moon_way * width * FOLD_LIGHT_OFFSET), 0.0, 0.0, _solid(fold_light), width * FOLD_LIGHT_WIDTH)


## The moon's rim colour by height: bright at the top, faint at the feet.
func _moon_tint(strength := 1.0) -> Callable:
	var top := Color(rim_top, rim_top.a * strength)
	var feet := Color(rim_feet, rim_feet.a * strength)
	return TitlePaint.linear(Vector2(0, box.position.y), Vector2(0, box.end.y), top, feet)


## `tint` (a colour, or a Callable as TitlePaint takes), fading out
## towards the feet as `feet_alpha` says.
func _solid(tint: Variant) -> Variant:
	if feet_alpha >= 1.0:
		return tint
	var fade := TitlePaint.linear(Vector2(0, fade_from), Vector2(0, box.end.y), Color.WHITE, Color(1, 1, 1, feet_alpha))
	return func(point: Vector2) -> Color:
		var color: Color = tint if tint is Color else (tint as Callable).call(point)
		return Color(color, color.a * (fade.call(point) as Color).a)


## The lantern's green, fading with the distance from it.
func _lantern_tint(strength := 1.0) -> Callable:
	return TitlePaint.radial(lantern_at, lantern_reach, Color(LANTERN_GREEN, strength))


## `tint` with its alpha scaled by `share`.
static func _faded(tint: Callable, share: float) -> Callable:
	return func(point: Vector2) -> Color:
		var color: Color = tint.call(point)
		return Color(color, color.a * share)


## The middle of `outline`'s corners.
static func _middle(outline: PackedVector2Array) -> Vector2:
	var sum := Vector2.ZERO
	for point in outline:
		sum += point
	return sum / outline.size()


## How far `outline` reaches from `middle` along `way`, at most.
static func _reach(outline: PackedVector2Array, middle: Vector2, way: Vector2) -> float:
	var most := 0.0
	for point in outline:
		most = maxf(most, absf((point - middle).dot(way)))
	return maxf(most, 0.001)

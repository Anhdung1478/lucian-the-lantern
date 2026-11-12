class_name TitleFigure
extends Control
## One of the title's three figures, painted once in code (TitlePaint) in
## its own units: `box`, the art's frame, is scaled to the node's height.
## The backdrop gives the node its size and keeps it to the bottom and to
## one side. Every part is lit the same way: shaded across from the moon's
## side, with a cool rim of moonlight on that side and, while the lantern
## lights the figure, a green rim on the side facing it.

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
	_paint(paint)
	paint.draw(self)


## Paints the figure, in units. Each figure paints its own.
func _paint(_paint_with: TitlePaint) -> void:
	pass


## Paints `outline` as one part: `base` shaded across it, lighter on the
## moon's side, the lantern's soft green on the side facing it, then its
## rims of light.
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
	_rims(paint, outline)


## The rims of light on `outline`: moonlight, then the lantern's green.
func _rims(paint: TitlePaint, outline: PackedVector2Array, strength := 1.0) -> void:
	var moon := _moon_tint(strength)
	paint.rim(outline, moon_way * rim_width * SOFT_REACH, _faded(moon, SOFT_ALPHA))
	paint.rim(outline, moon_way * rim_width, moon)
	if not lantern_lit:
		return
	var way := (lantern_at - _middle(outline)).normalized()
	var green := _lantern_tint(strength * LANTERN_RIM)
	paint.rim(outline, way * lantern_width * SOFT_REACH, _faded(green, SOFT_ALPHA))
	paint.rim(outline, way * lantern_width, green)


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

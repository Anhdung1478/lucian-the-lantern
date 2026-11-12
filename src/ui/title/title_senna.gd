class_name TitleSenna
extends TitleFigure
## Senna's spirit on the title, behind Lucian, facing right: a hooded robe
## with a mantle over her shoulders, her relic cannon over her shoulder,
## its barrel up and back, her near hand on its grip. Her face is calm under
## the hood, eyes closed, locks falling from it. She is teal and ghostly:
## lit from within, rimmed in teal, fading into the mist below her waist,
## with an aura round her.

## The art's frame, in units.
const BOX := Rect2(0, -14, 132, 262)
## Towards the moon (behind her, up and to her right), the lantern far to
## the right in her units and how far its light reaches.
const MOON_WAY := Vector2(0.3, -1.0)
const LANTERN_AT := Vector2(420, 90)
const LANTERN_REACH := 820.0
## Her rim, and how solid she is at her feet, from her waist down.
const RIM_TOP := Color(0.85, 1.0, 0.96, 1.0)
const RIM_FEET := Color(0.37, 0.85, 0.75, 0.0)
## What her parts are tinted towards on the moon's side.
const LIT_TINT := Color("7fe6d4")
const FEET_ALPHA := 0.05
const FADE_FROM := 96.0

## Her colours: the robe, the mantle, her face and hair, the cannon and
## its light, the dark inside her hood.
const ROBE := Color("0f3534")
const MANTLE := Color("134241")
const SKIN := Color("2a5f5a")
const HAIR := Color("0e2b2a")
const CANNON := Color("235a55")
const TEAL := Color("b8fff0")
const HOOD_DARK := Color(0.0, 0.03, 0.04, 0.85)
## Her aura: soft glows (middle, size) behind her, and their alpha.
const AURA: Array[Rect2] = [Rect2(74, 24, 34, 36), Rect2(70, 110, 52, 130), Rect2(30, 30, 30, 30)]
const AURA_ALPHA := 0.07
## A fold in her robe: its shadow, the light on its ridge and its width.
const FOLD_DARK := Color(0.0, 0.05, 0.06, 0.5)
const FOLD_LIGHT := Color(0.72, 1.0, 0.94, 0.16)
const FOLD_WIDTH := 3.0

## Her parts, back to front.
const ROBE_SHAPE := "M 62 36 C 56 42 52 48 50 56 C 46 80 44 110 40 140 C 36 170 28 200 14 226 L 27 222 L 28 237 L 41 228 L 50 241 L 60 234 L 72 243 L 84 236 L 97 241 C 98 214 96 180 94 150 C 92 120 92 90 92 66 C 91 54 87 46 80 40 Z"
const BOOT := "M 86 233 L 96 233 L 98 239.6 L 106 242.6 L 106.4 246 L 85 246 Z"
const SASH := "M 51.4 88 C 64 91 80 91 92.4 87.6 L 92.4 94.6 C 80 98 64 98 50.8 95 Z"
const MANTLE_SHAPE := "M 59.6 37 C 54 43 49.6 52 47.6 63 C 53 69 63 71.6 74 70.6 C 84 69.6 91 66 95 61 C 93 51 88 43 81 39 Z"
const HOOD := "M 58 46 C 53 38 51 28 52.6 18 C 53.4 12 50.6 7 46.6 2.6 C 56 1 63 -0.6 72 -0.2 C 83 0.4 89.4 6.6 90.2 13.4 C 87.4 13.4 84.6 14.4 82.6 16.6 C 80.4 19.6 79.6 24 79.8 28.4 C 80 33 81.4 37.6 84 41.6 L 70 47 Z"
## The hood's folds, wrapping round it from its opening to its back.
const HOOD_FOLDS: Array[String] = ["M 86 7 C 76 4.4 64 6 56 11", "M 82 19 C 72 17 62 20.6 55.6 28", "M 80.6 32 C 72 31.6 64 35 58.6 42"]
## The trim along the hood's opening: its colour and width.
const TRIM := Color("2f7a72")
const TRIM_WIDTH := 1.6
const FACE := "M 80.6 13.6 C 82.6 14.4 83.6 15.8 83.8 17.6 L 84.4 19.4 L 84.2 21 L 86.4 24.6 L 84.6 25.6 L 85 26.8 L 84.4 27.6 L 84.8 28.6 L 84.2 31.4 C 83.6 33 82.4 33.8 81 34 L 80.6 40.6 L 76 41.6 L 76 15 Z"
const EYE := "M 81.6 20.6 Q 82.7 21.5 84 20.9"
const ARM := "M 52 50 C 56 46 62 47 64 52 C 66 60 67 68 70 74 L 82 79 L 84 86 L 70 86 C 63 84 59 78 57 70 C 55 62 53 56 52 50 Z"
const HAND := "M 80 77.4 L 86.6 78.4 L 87.6 85 L 81 86.6 Z"
## Locks of her hair, falling from her hood: each a curve, its width at
## the hood and at its end.
const LOCKS: Array[String] = ["M 80.6 33.4 C 81.4 42 80.8 52 82.4 62", "M 78.6 36 C 78.8 46 77.6 56 78.6 66", "M 82 34.2 C 83.6 42 84 50 85.6 57"]
const LOCK_WIDTH := Vector2(2.2, 0.7)
const ROBE_FOLDS: Array[String] = [
	"M 60 72 C 58 120 50 170 34 220",
	"M 72 98 C 72 140 70 190 64 234",
	"M 82 96 C 84 140 84 190 86 234",
	"M 54 100 C 50 140 44 180 30 214",
]
## The relic cannon, drawn along +x from its breech and laid at CANNON_AT,
## turned by CANNON_ANGLE: the stock, the grip, the barrel with its rail,
## the flared muzzle; the rings round the barrel (x), the relic core in its
## stock and the muzzle's light.
const CANNON_AT := Vector2(90, 106)
const CANNON_ANGLE := -2.18
const STOCK := "M -2 -9.4 C -8 -9.4 -10.6 -5 -10.6 0 C -10.6 5.4 -8 10.6 -1.6 10.6 L 26 9.6 L 28 4 L 28 -5 L 26 -9 Z"
const GRIP := "M 25 5 L 29.4 5 L 33 13.8 L 27.6 14.4 Z"
const BARREL := "M 26 -5.8 L 108 -4.8 L 108 4.6 L 26 5.8 Z"
const RAIL := "M 32 -5.6 C 54 -11 82 -10.4 104 -4.8 Z"
const FIN := "M 40 5.4 C 60 9.4 80 9.4 98 4.8 Z"
const MUZZLE := "M 106 -6.4 L 114 -7 L 122 -11.6 L 129 -10.6 L 129 10.4 L 122 11.4 L 114 6.8 L 106 6.2 Z"
const RINGS: Array[float] = [46.0, 68.0, 90.0]
const CORE := Vector2(9, 0.4)
const MUZZLE_LIGHT := Vector2(131, 0)


func _init() -> void:
	super(BOX)
	fold_dark = FOLD_DARK
	fold_light = FOLD_LIGHT
	moon_way = MOON_WAY.normalized()
	lantern_at = LANTERN_AT
	lantern_reach = LANTERN_REACH
	lantern_width = 0.7
	lit_tint = LIT_TINT
	rim_top = RIM_TOP
	rim_feet = RIM_FEET
	feet_alpha = FEET_ALPHA
	fade_from = FADE_FROM


## Her middle, in the parent's coordinates: where her motes drift.
func middle() -> Vector2:
	return at(Vector2(72, 104))


## Where the robe's hem meets the ground in front of her, in the parent's
## coordinates: where the chain from the lantern ends.
func hem() -> Vector2:
	return at(Vector2(60, 236))


func _paint(paint: TitlePaint) -> void:
	for aura in AURA:
		paint.glow(aura.position, aura.size, Color(TEAL, AURA_ALPHA))
	_part(paint, TitlePaint.outline(BOOT), ROBE)
	var robe := TitlePaint.outline(ROBE_SHAPE)
	_part(paint, robe, ROBE)
	for fold in ROBE_FOLDS:
		_fold(paint, fold, FOLD_WIDTH)
	paint.glow_in(robe, Vector2(78, 70), 46.0, Color(TEAL, 0.22))
	_part(paint, TitlePaint.outline(SASH), MANTLE)
	_paint_cannon(paint)
	var mantle := TitlePaint.outline(MANTLE_SHAPE)
	_part(paint, mantle, MANTLE)
	_fold(paint, "M 62 44 Q 60 56 61 68", FOLD_WIDTH * 0.7)
	_fold(paint, "M 76 44 Q 80 56 79 69", FOLD_WIDTH * 0.6)
	_paint_head(paint)
	_part(paint, TitlePaint.outline(ARM), MANTLE)
	_fold(paint, "M 57 58 Q 60 68 66 76", FOLD_WIDTH * 0.6)
	_part(paint, TitlePaint.outline(HAND), SKIN)


## The relic cannon over her shoulder: its parts, its teal rings, its core
## and the light at its muzzle.
func _paint_cannon(paint: TitlePaint) -> void:
	for part in [GRIP, STOCK, FIN, BARREL, RAIL, MUZZLE]:
		_part(paint, _cannon(TitlePaint.outline(part)), CANNON)
	for x in RINGS:
		paint.shape(_cannon(PackedVector2Array([Vector2(x - 1.8, -6.4), Vector2(x + 1.8, -6.3), Vector2(x + 1.8, 6.1), Vector2(x - 1.8, 6.2)])), TEAL)
		paint.glow(_cannon(PackedVector2Array([Vector2(x, 0)]))[0], Vector2(9, 9), Color(TEAL, 0.25))
	var core := _cannon(PackedVector2Array([CORE]))[0]
	paint.oval(core, Vector2(4.4, 4.4), Color(0.02, 0.08, 0.09))
	paint.oval(core, Vector2(3, 3), TEAL)
	paint.glow(core, Vector2(11, 11), Color(TEAL, 0.45))
	paint.glow(_cannon(PackedVector2Array([MUZZLE_LIGHT]))[0], Vector2(12, 12), Color(TEAL, 0.8))


## Her head: the face, lit from within, the shadow of the hood's brim on
## it, her closed eye and lips; then the hood over it and her locks.
func _paint_head(paint: TitlePaint) -> void:
	var face := TitlePaint.outline(FACE)
	_part(paint, face, SKIN)
	paint.glow_in(face, Vector2(84, 28), 12.0, Color(TEAL, 0.4))
	paint.shape(face, TitlePaint.linear(Vector2(0, 14), Vector2(0, 22), HOOD_DARK, Color(HOOD_DARK, 0.0)))
	paint.stroke(EYE, 0.55, Color(0.02, 0.1, 0.1, 0.9))
	paint.stroke("M 84.4 27.2 L 83.2 27.2", 0.45, Color(0.02, 0.1, 0.1, 0.8))
	paint.oval(Vector2(85.2, 24.6), Vector2(0.4, 0.28), Color(0.02, 0.1, 0.1, 0.8))
	var hood := TitlePaint.outline(HOOD)
	_part(paint, hood, MANTLE)
	for fold in HOOD_FOLDS:
		_fold(paint, fold, FOLD_WIDTH * 0.6)
	paint.rim_inside(hood, Vector2(TRIM_WIDTH, 0.0), TitlePaint.outline("M 78 10 L 92 10 L 92 46 L 78 46 Z"), TRIM)
	for lock in LOCKS:
		var line := TitlePaint.outline(lock)
		paint.taper(line, LOCK_WIDTH.x, LOCK_WIDTH.y, HAIR)
		paint.taper(TitlePaint.moved(line, Vector2(0.5, -0.2)), LOCK_WIDTH.x * 0.3, 0.0, Color(TEAL, 0.35))



## `outline`, drawn in the cannon's own frame, where it lies on her shoulder.
func _cannon(outline: PackedVector2Array) -> PackedVector2Array:
	return TitlePaint.turned(outline, Vector2.ZERO, CANNON_ANGLE, CANNON_AT)

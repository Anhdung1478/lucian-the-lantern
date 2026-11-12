class_name TitleLucian
extends TitleFigure
## Lucian on the title: in profile, facing right towards Thresh, in his long
## coat, its tails swept back by the wind. His far arm aims his own slim
## pistol, its muzzle hot; his near hand holds Senna's relic gun low at his
## side, its rings lit teal. The moon is behind him at the upper left, the
## lantern far to the right.

## The art's frame, in units.
const BOX := Rect2(0, -12, 146, 260)
## Towards the moon, and where the lantern is in his units, how far its
## light reaches and how wide its rim on him is.
const MOON_WAY := Vector2(-0.55, -0.83)
const LANTERN_AT := Vector2(330, 100)
const LANTERN_REACH := 760.0
const LANTERN_WIDTH := 0.7

## His colours: the coat, the trousers and boots, the vest and shirt, the
## belt and its gold, his skin and his hair.
const COAT := Color("141b24")
const TROUSERS := Color("0f1319")
const BOOTS := Color("0a0c0f")
const VEST := Color("181e27")
const SHIRT := Color("7d8894")
const BELT := Color("1b2028")
const GOLD := Color("d9b263")
const SKIN := Color("3d2418")
const HAIR := Color("0c0a0a")
const STEEL := Color("2c3540")
const RELIC := Color("3a4e51")
const TEAL := Color("b8fff0")
const MUZZLE := Color("fff1c4")
## The small lights and darks: the moon along the pistol's barrel, on his
## knuckles and on the soles; the creases; his eye, its pupil, his nostril;
## and the dark the coat takes on towards its hem.
const STEEL_LIGHT := Color(0.85, 0.9, 1.0, 0.55)
const KNUCKLE_LIGHT := Color(1.0, 0.86, 0.7, 0.3)
const SOLE_LIGHT := Color(0.55, 0.66, 0.82, 0.3)
const CREASE := Color(0.0, 0.0, 0.0, 0.5)
const EYE_WHITE := Color(0.85, 0.9, 0.86, 0.55)
const PUPIL := Color(0.05, 0.04, 0.04)
const NOSTRIL := Color(0.12, 0.06, 0.04)
const HEM_SHADE := Color(0.0, 0.0, 0.02, 0.45)

## His parts, back to front.
const BACK_LEG := "M 52 124 L 67 127 C 64.6 146 61 162 59.4 178 C 58 194 55.6 212 53.4 229 L 43.6 229 C 44 220 43 210 43.4 200 C 43.8 190 45.4 182 46 174 C 47 158 48.6 142 52 124 Z"
const BACK_BOOT := "M 43.2 227 L 52.6 227 L 53.2 237 L 60.4 241.4 L 60.6 246 L 38.8 246 L 39 238 Z"
const FRONT_LEG := "M 67 125 L 83 123 C 89.6 142 95 158 97.4 176 C 99.6 194 101.4 212 102.2 226 L 90.2 227.4 C 89.2 216 88 206 86.4 196 C 85 188 84.6 182 83.6 178 C 78.6 160 72 146 67 125 Z"
const FRONT_BOOT := "M 90 225.6 L 102.4 224.6 L 103.4 236.6 L 114.2 241.6 L 114.4 246 L 88 246 L 88.2 237.4 Z"
const FAR_ARM := "M 72 41 C 85 42.6 100 46 114 50.4 L 116.6 51 L 116.6 61 L 113 61.2 C 100 59.6 87 58.4 75 58 Z"
const PISTOL := "M 117 51 L 137.6 51 L 139.6 52.2 L 139.6 55.4 L 126.4 55.8 L 125.4 58.2 L 122 58.2 L 121.2 66 L 116.6 65.4 L 117.6 57.2 L 116.4 55.4 Z"
const FAR_FIST := "M 113.8 50.4 C 117.4 49.2 121.2 49.4 122.8 52.4 L 122.8 58.6 C 120.4 61 117.2 61.6 114.2 61.2 Z"
const COAT_SHAPE := "M 63 35.6 L 48 42 C 46 52 47.8 64 49.6 76 C 51.4 88 52.6 96 51 106 C 47 132 38 160 26 184 C 19 197 11 207 3 213 L 15 210 L 12 223 L 25 212 L 29 226 L 37 211 L 44 222 L 50 210 L 56.6 214 C 58 196 60.4 172 62 156 L 66 131 L 73 140 C 80 160 87 184 92 204 L 103 207 C 99 186 94 160 89 138 C 85 122 80 110 78 98 C 77 84 79.6 64 81 48 L 77.6 40 L 76.8 36.4 L 71 38.6 Z"
const VEST_SHAPE := "M 69.6 37.6 L 77.2 37.8 L 80.6 47.6 C 79.6 64 77.8 82 78.2 97 L 72 97.6 C 71 80 70.4 58 69.6 37.6 Z"
const SHIRT_SHAPE := "M 70.6 37.4 L 77 37.4 L 74 47 Z"
const BELT_SHAPE := "M 50.8 96.6 L 78.6 95 L 78.8 100.4 L 51.2 102 Z"
## The collar standing up behind his neck, and its front.
const COLLAR := "M 58.4 29.4 C 58.8 27.2 60.4 26.8 61.6 28.6 L 66.4 37.8 L 66 41.4 L 56.8 42.6 Z"
const COLLAR_FRONT := "M 73.6 39 L 77.4 34.6 L 79.8 41.6 L 76.6 45.4 Z"
const HEAD := "M 65.6 39 L 64.2 31 C 61.6 27 60.8 20.5 61.6 15.5 C 62.6 9.6 66.6 5.8 71.8 5.8 C 76.8 6 79.6 9.2 79.8 13.2 L 80.4 16 L 79.9 17.6 L 80.6 19.4 L 82.9 23.3 L 80.8 24.5 L 80.6 25.4 L 81.2 26.6 L 80.6 27.5 L 81 28.4 L 80 29.8 C 80.6 30.8 80.8 32 80.2 33.2 C 79 34.6 76.6 35.4 74 35.2 L 74.8 39 Z"
const HAIR_SHAPE := "M 79.7 12.6 C 79.4 8.8 76.6 5.6 71.8 5.6 C 66.6 5.6 62.4 9.4 61.4 15.4 C 60.7 20 61.4 25 63.4 28.8 L 66.4 28.6 C 67.4 25.6 68.6 22.4 69.6 20.4 C 70.8 18 72.2 15.8 74 14.2 C 75.6 13 77.4 12.6 79.7 12.6 Z"
const BEARD := "M 72.4 20.2 L 73.8 20.6 C 74.4 24.4 75.4 27.4 77.4 28.8 C 78.4 29.4 79.4 29.4 80 29.8 C 80.6 30.8 80.8 32 80.2 33.2 C 79 34.6 76.6 35.4 74 35.2 C 71.2 34.6 69.6 32.2 68.8 29.2 L 69.6 26 C 70.8 24.6 71.6 22.6 72.4 20.2 Z"
const MUSTACHE := "M 79.2 25 L 80.8 25.2 L 81.3 26.4 L 79.8 26.7 C 78.9 26.5 78.2 26.1 77.7 25.6 Z"
const EYE := "M 77.1 18.5 L 79.3 18.1 L 78.8 19.3 Z"
const BROW := "M 75.8 16.8 L 78 16.1 L 80.2 16.3"
const NEAR_ARM := "M 52.4 44 C 57 40.4 63 41.6 64.4 46 C 64.2 56 62.6 66 61.6 74 C 64.6 81 67.4 88 70.4 94.6 L 64.6 99.6 C 60 92.6 56 85 53.6 78 C 51.4 67 51 55 52.4 44 Z"
const NEAR_HAND := "M 64 96.4 C 65.2 94.4 68 93.8 70 94.4 C 71.8 95.2 72.4 97.6 71.6 99.8 C 70.6 101.8 67.6 102.6 65.4 102 C 63.8 101.2 63.4 98.4 64 96.4 Z"
## Senna's relic gun in his near hand, drawn pointing right from where he
## holds it and turned down by RELIC_ANGLE at RELIC_AT: the receiver, the
## barrel, the muzzle cap and the curved guard over them; the rings on the
## barrel (x, half width, top and bottom) and its core.
const RELIC_AT := Vector2(67.6, 98.2)
const RELIC_ANGLE := 0.38
const RELIC_GUARD := "M -6 -6.2 C 2 -9.6 14 -9.6 25 -5 L 25 -3.6 C 14 -7 2 -7 -5 -4.6 Z"
const RELIC_BODY := "M -7 -4.6 C -7 -6.6 -5 -7 -3 -7 L 10 -6.6 L 13 -4 L 13 4 L 10 5.6 L -3.6 5.6 C -6 5.6 -7.4 4 -7 2 Z"
const RELIC_BARREL := "M 12 -3.6 L 30 -3.2 L 30 2.8 L 12 3.4 Z"
const RELIC_CAP := "M 29 -4.8 L 34.6 -4.4 L 35.6 0 L 34.6 4 L 29 4.4 Z"
const RELIC_RINGS: Array[float] = [17.0, 23.5]
const RELIC_RING := Vector3(1.1, -3.5, 3.1)
const RELIC_CORE := Vector2(3, -0.6)
## The pistol's muzzle, where it glints.
const MUZZLE_AT := Vector2(140.4, 53.6)

## The folds of the coat: the back tail's, the front panel's and the
## sleeve's, each a curve; and how wide a fold's shadow swells.
const COAT_FOLDS: Array[String] = [
	"M 50.4 108 C 46 134 36 162 18 198",
	"M 53.6 114 C 50.6 142 44 170 31 204",
	"M 58.4 132 C 56.6 156 53 182 46 210",
	"M 48.6 96 C 50.4 74 48.6 58 50.6 46",
	"M 82.6 118 C 85.6 146 89.6 174 96 203",
	"M 76.4 128 C 80.2 156 85 182 89.6 203",
]
const SLEEVE_FOLDS: Array[String] = [
	"M 93.4 47.8 Q 95.6 52.6 94.2 58.4",
	"M 100 49 Q 101.6 53 100.2 59",
	"M 86 46.6 Q 87.6 51 86.8 57.6",
]
const FOLD_WIDTH := 2.6


func _init() -> void:
	super(BOX)
	moon_way = MOON_WAY.normalized()
	lantern_at = LANTERN_AT
	lantern_reach = LANTERN_REACH
	lantern_width = LANTERN_WIDTH


## Where his pistol's muzzle is, in the parent's coordinates.
func muzzle() -> Vector2:
	return at(MUZZLE_AT)


## Where the relic gun's core is, in the parent's coordinates.
func relic_core() -> Vector2:
	return at(_relic(PackedVector2Array([RELIC_CORE]))[0])


func _paint(paint: TitlePaint) -> void:
	_part(paint, TitlePaint.outline(BACK_LEG), TROUSERS)
	_fold(paint, "M 46.6 170 Q 52 175.6 59 173", FOLD_WIDTH * 0.8)
	_part(paint, TitlePaint.outline(BACK_BOOT), BOOTS)
	_part(paint, TitlePaint.outline(FRONT_LEG), TROUSERS)
	_fold(paint, "M 84.4 172 Q 90 177 97 172.6", FOLD_WIDTH * 0.8)
	_part(paint, TitlePaint.outline(FRONT_BOOT), BOOTS)
	for sole in ["M 39 244.6 L 60.4 244.6", "M 88.2 244.6 L 114.2 244.6"]:
		paint.stroke(sole, 0.8, SOLE_LIGHT)
	_paint_far_arm(paint)
	_paint_head(paint)
	_paint_coat(paint)
	_paint_near_arm(paint)


## The far arm aiming the pistol, behind his body: the sleeve and its
## folds, the pistol with its gold and its hot muzzle, and the fist.
func _paint_far_arm(paint: TitlePaint) -> void:
	_part(paint, TitlePaint.outline(FAR_ARM), COAT)
	for fold in SLEEVE_FOLDS:
		_fold(paint, fold, FOLD_WIDTH * 0.7)
	_part(paint, TitlePaint.outline(PISTOL), STEEL)
	paint.line(Vector2(119, 51.6), Vector2(137.4, 51.6), 0.6, STEEL_LIGHT)
	paint.line(Vector2(131, 51.2), Vector2(131, 55.6), 1.2, GOLD)
	paint.line(Vector2(122.6, 58.2), Vector2(121.8, 64), 0.8, Color(GOLD, 0.6))
	paint.glow(MUZZLE_AT, Vector2(6, 6), Color(MUZZLE, 0.5))
	paint.oval(MUZZLE_AT, Vector2(1.1, 1.1), MUZZLE)
	_part(paint, TitlePaint.outline(FAR_FIST), SKIN)
	paint.stroke("M 116.6 52.2 Q 119.4 51.2 121.6 52.8", 0.5, KNUCKLE_LIGHT)


## The long coat: shaded, darker towards its hem, its folds,
## the vest, the shirt's collar and the belt with its gold buckle.
func _paint_coat(paint: TitlePaint) -> void:
	var coat := TitlePaint.outline(COAT_SHAPE)
	_part(paint, coat, COAT)
	paint.shape(coat, TitlePaint.linear(Vector2(0, 120), Vector2(0, 226), Color(HEM_SHADE, 0.0), HEM_SHADE))
	for fold in COAT_FOLDS:
		_fold(paint, fold, FOLD_WIDTH)
	_part(paint, TitlePaint.outline(VEST_SHAPE), VEST)
	paint.fill(SHIRT_SHAPE, SHIRT)
	paint.stroke("M 70.2 40 C 71 60 71.6 80 72.2 96", 0.7, CREASE)
	_part(paint, TitlePaint.outline(BELT_SHAPE), BELT)
	paint.fill("M 64 95.6 L 68.4 95.4 L 68.6 100.4 L 64.2 100.6 Z", GOLD)
	paint.fill("M 65.2 96.8 L 67.4 96.7 L 67.5 99.2 L 65.3 99.3 Z", BELT)
	_part(paint, TitlePaint.outline(COLLAR), COAT)
	_part(paint, TitlePaint.outline(COLLAR_FRONT), COAT)


## His head in profile, under the coat's collar: skin shaded, short hair,
## a short beard and moustache, the ear, the eye and the brow.
func _paint_head(paint: TitlePaint) -> void:
	_part(paint, TitlePaint.outline(HEAD), SKIN)
	paint.shape(TitlePaint.outline(HAIR_SHAPE), HAIR)
	paint.shape(TitlePaint.outline(BEARD), Color(HAIR, 0.92))
	paint.fill(MUSTACHE, HAIR)
	paint.oval(Vector2(69.6, 21.6), Vector2(1.5, 2.3), SKIN.darkened(0.25), 0.2)
	paint.oval(Vector2(69.8, 21.8), Vector2(0.7, 1.3), SKIN.darkened(0.6), 0.2)
	paint.fill(EYE, EYE_WHITE)
	paint.oval(Vector2(78.6, 18.7), Vector2(0.45, 0.45), PUPIL)
	paint.stroke(BROW, 0.8, HAIR)
	paint.oval(Vector2(81.3, 23.9), Vector2(0.45, 0.3), NOSTRIL)


## The near arm, low at his side, with Senna's relic gun: its light on the
## coat round it, the sleeve, the gun with its rings and core, the hand.
func _paint_near_arm(paint: TitlePaint) -> void:
	var core := _relic(PackedVector2Array([RELIC_CORE]))[0]
	paint.glow_in(TitlePaint.outline(COAT_SHAPE), core, 26.0, Color(TEAL, 0.16))
	_part(paint, TitlePaint.outline(NEAR_ARM), COAT)
	_fold(paint, "M 53.8 60 Q 57.6 66 61.6 74", FOLD_WIDTH * 0.8)
	_fold(paint, "M 57.4 82 Q 61.6 86 63.6 93", FOLD_WIDTH * 0.6)
	for part in [RELIC_BODY, RELIC_BARREL, RELIC_CAP, RELIC_GUARD]:
		_part(paint, _relic(TitlePaint.outline(part)), RELIC)
	for x in RELIC_RINGS:
		var ring := Rect2(x - RELIC_RING.x, RELIC_RING.y, RELIC_RING.x * 2.0, RELIC_RING.z - RELIC_RING.y)
		paint.shape(_relic(PackedVector2Array([ring.position, Vector2(ring.end.x, ring.position.y), ring.end, Vector2(ring.position.x, ring.end.y)])), TEAL)
	paint.glow(_relic(PackedVector2Array([Vector2(18.5, 0)]))[0], Vector2(14, 9), Color(TEAL, 0.28))
	paint.oval(core, Vector2(2.4, 2.4), TEAL)
	paint.glow(core, Vector2(8, 8), Color(TEAL, 0.55))
	var hand := TitlePaint.outline(NEAR_HAND)
	_part(paint, hand, SKIN)
	paint.rim(hand, Vector2(0.7, 0.4), Color(TEAL, 0.55))
	paint.stroke("M 67.4 94.6 Q 68.6 97.6 68 101.8", 0.4, CREASE)
	paint.stroke("M 69.8 95 Q 70.6 97.6 70.2 101", 0.4, CREASE)


## `outline`, drawn in the relic gun's own frame, where it lies in his hand.
func _relic(outline: PackedVector2Array) -> PackedVector2Array:
	return TitlePaint.turned(outline, Vector2.ZERO, RELIC_ANGLE, RELIC_AT)

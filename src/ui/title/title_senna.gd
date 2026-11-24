class_name TitleSenna
extends TitleFigure
## Senna on the title and ending screens, standing behind Lucian and facing
## right. On the title she is a translucent teal spirit bound to the mist;
## when `freed` is true (TheEndScreen) she stands solid and living in warm
## Sentinel colours with dawn rim light, her ornate Relic Cannon resting
## proudly across her shoulder.

## The art's frame, in units.
const BOX := Rect2(0, -14, 132, 262)
## Towards the moon, and where the lantern is in her units, how far its
## light reaches and how wide its rim on her is.
const MOON_WAY := Vector2(0.3, -1.0)
const LANTERN_AT := Vector2(420, 90)
const LANTERN_REACH := 820.0
const LANTERN_WIDTH := 0.7

## Spirit lighting (title) vs freed living lighting (ending).
const SPIRIT_RIM_TOP := Color(0.85, 1.0, 0.96, 1.0)
const SPIRIT_RIM_FEET := Color(0.37, 0.85, 0.75, 0.0)
const SPIRIT_LIT_TINT := Color("7fe6d4")
const SPIRIT_FEET_ALPHA := 0.0
const SPIRIT_FADE_FROM := 96.0
const SPIRIT_FOLD_DARK := Color(0.0, 0.05, 0.06, 0.58)
const SPIRIT_FOLD_LIGHT := Color(0.72, 1.0, 0.94, 0.24)

const FREED_RIM_TOP := Color(1.0, 0.89, 0.64, 0.96)
const FREED_RIM_FEET := Color(0.82, 0.62, 0.38, 0.38)
const FREED_LIT_TINT := Color("f0d4a8")
const FREED_FOLD_DARK := Color(0.02, 0.02, 0.04, 0.46)
const FREED_FOLD_LIGHT := Color(1.0, 0.9, 0.7, 0.18)

## Her middle (where motes drift) and the hem where the chain meets her.
const MIDDLE := Vector2(72, 104)
const HEM := Vector2(60, 236)

## Spirit palette (Title Screen).
const SPIRIT_ROBE := Color("113b3a")
const SPIRIT_CLOAK := Color("0d2d2d")
const SPIRIT_MANTLE := Color("164947")
const SPIRIT_SCARF := Color("1a5552")
const SPIRIT_SKIN := Color("316b64")
const SPIRIT_HAIR := Color("0d2928")
const SPIRIT_CANNON := Color("123231")
const SPIRIT_TRIM := Color("5cd4c4")
const SPIRIT_GOLD := Color("7fe0cf")

## Living Sentinel palette (Freed End Screen).
const FREED_ROBE := Color("1b242c")
const FREED_CLOAK := Color("141d24")
const FREED_MANTLE := Color("25333c")
const FREED_SCARF := Color("cfc8b9")
const FREED_SKIN := Color("563423")
const FREED_HAIR := Color("120e0d")
const FREED_CANNON := Color("243034")
const FREED_TRIM := Color("d9ceb8")
const FREED_GOLD := Color("dfb664")

const CANNON_EDGE := Color(0.86, 1.0, 0.96, 0.56)
const TEAL := Color("b8fff0")
const TEAL_CORE := Color("ecfffb")
const HOOD_DARK := Color(0.0, 0.03, 0.04, 0.8)
const FEATURE_SPIRIT := Color(0.02, 0.1, 0.1, 0.88)
const FEATURE_FREED := Color(0.08, 0.04, 0.03, 0.92)
const CORE_RIM := Color(0.03, 0.09, 0.1)
const SOUL_AT := Vector2(73, 66)

const AURA: Array[Rect2] = [Rect2(74, 24, 34, 36), Rect2(68, 114, 52, 126), Rect2(26, 20, 32, 32)]
const AURA_ALPHA := 0.075
const FOLD_WIDTH := 3.6

## Graceful layered silhouette: sculpted boots, flowing multi-layered cloak
## and scarf drapery sweeping softly into the mist, cinched Sentinel tunic.
const BACK_BOOT := "M 53 214 L 64.5 215 L 65 233 C 67.5 237.5 71 240.5 74 242.5 C 74.8 244.2 74.2 245.5 72.5 246 L 51.5 246 L 51.5 236 Z"
const FRONT_BOOT := "M 78 214 L 90 214 L 91 231 C 95.5 236 101 239.5 105 242 C 106 244 105.5 245.5 103.5 246 L 77 246 L 77 235 Z"

## Soft cascading Sentinel back-cloak & draped scarf flowing gently down-back.
const BACK_CLOAK := "M 54 44 C 46 68 38 100 30 136 C 23 170 15 202 6 228 C 17 236 33 236 48 232 C 54 206 59 172 63 136 L 63 46 Z"
const SCARF_DRAPE := "M 54 47 C 46 62 39 82 34 106 C 30 128 27 152 20 176 C 29 172 37 158 43 136 C 48 114 52 88 56 64 Z"

## Flowing asymmetrical Sentinel coat-robe (organic diagonal front drape).
const ROBE_SHAPE := "M 58 40 C 54 50 53 68 55 92 C 49 114 44 144 37 178 C 32 202 25 222 17 238 C 31 243 49 242 64 234 C 71 218 76 202 80 188 C 83 204 86 220 91 236 C 96 237 100 234 102 228 C 98 200 95 168 92 136 C 89 112 86 99 84 92 C 86 74 87 58 84 44 Z"
const SASH := "M 53.5 89 C 64 93 77 93 85.5 88.5 L 86 96 C 77 100 64 100 53 96.5 Z"
const SASH_DROP := "M 64 96 L 73 96.5 C 71 124 66 154 60 184 L 53 178 C 58 152 62 124 64 96 Z"
const MANTLE_SHAPE := "M 54 38 C 47 45 43 55 42.5 66 C 50 73 61 75.5 74 74 C 84 72.5 91.5 68.5 95 62 C 92.5 51 87.5 43 80 39 Z"
const SCARF_COLLAR := "M 55 39 C 63 46 76 47 85 43 L 86 50 C 76 55 62 54 52 47 Z"

## Sleeker organic draped hood framing her graceful 3/4 face & braided locks.
const HOOD := "M 55 46 C 51 38 50 28 52 19 C 53.5 12 58 6.8 65 5.0 C 73 3.2 82 5.0 87.5 10.2 C 89 12.0 89.6 13.8 89.6 15.2 C 86.4 14.4 83 15.2 80.6 17.4 C 78 20.2 77 24.8 77.4 29.8 C 77.8 34.8 79.6 39 82.8 42.6 L 68 48 Z"
const HOOD_FOLDS: Array[String] = [
	"M 84 9.5 C 74 7.8 62.5 9.8 55.5 15",
	"M 79.5 21 C 70 19.8 61 23.2 55.5 30.5",
	"M 78.5 33 C 70.5 33.2 62.5 36.5 57.5 43",
]
const TRIM_BOX := "M 76 11 L 92 11 L 92 46 L 76 46 Z"
const FACE := "M 78.8 14.2 C 82.2 14.8 84.0 16.4 84.5 18.6 L 85.1 20.4 L 84.7 22.0 L 87.1 25.0 L 85.1 26.2 L 85.5 27.4 L 84.8 28.4 L 85.2 29.5 L 84.0 32.4 C 83.0 34.2 81.2 35.0 79.2 35.2 L 78.8 42.0 L 72.0 43.0 L 72.5 16.0 Z"
const EYE_CLOSED := "M 81.6 21.4 Q 83.0 22.4 84.4 21.6"
const EYE_OPEN := "M 81.2 21.2 Q 82.8 20.3 84.4 21.2 Q 82.8 22.1 81.2 21.2 Z"
const BROW := "M 80.8 19.6 Q 82.8 18.8 84.8 19.5"

## Fuller braided hair locks cascading naturally over her cheek & collarbone.
const LOCKS: Array[String] = [
	"M 79.6 32.5 C 81.0 43 80.6 56 83.0 70",
	"M 77.2 34.8 C 77.4 47 76.0 61 77.6 75",
	"M 81.8 33.8 C 84.0 43 84.8 54 86.8 64",
	"M 74.6 35.8 C 73.2 47 71.2 59 70.0 71",
	"M 72.4 37.0 C 70.0 46 67.5 56 66.0 66",
]
const LOCK_WIDTH := Vector2(2.4, 0.8)

## Well-proportioned near arm & hand wrapping cleanly around the cannon's grip.
const ARM := "M 51 50 C 55.5 46 61.5 47.5 63.2 53 C 64.5 62 65.2 71 67.8 77.5 L 80 80 L 80.5 87 L 66.5 87.8 C 58.8 86 54.5 79.5 53 71 C 51.5 62.5 50.5 56 51 50 Z"
const BRACER := "M 69.5 78 L 80 80 L 80.5 87 L 68.5 87.2 Z"
const HAND := "M 78.8 78.6 C 81.8 77.0 85.8 77.8 87.4 80.2 C 88.6 82.2 87.8 85.6 85.8 87.2 C 83.6 88.6 80.2 88.4 78.6 86.6 Z"

## Organic drapery folds down her cloak & skirt.
const ROBE_FOLDS: Array[String] = [
	"M 56 76 C 53 122 44 172 28 228",
	"M 68 98 C 66 138 61 178 52 226",
	"M 80 96 C 83 136 86 176 90 224",
	"M 46 112 C 40 150 31 188 17 224",
]

## Iconic Relic Cannon: sculpted stone-and-brass receiver, twin segmented
## barrel rails, glowing central teal channel, 3 crisp relic rings, faceted
## core crystal & flared twin-prong ancient stone muzzle.
const CANNON_AT := Vector2(88.0, 105.0)
const CANNON_ANGLE := -2.14
const STOCK := "M -6 -9.6 C -11.5 -9.0 -13.5 -4.6 -13.5 0.0 C -13.5 5.2 -11.0 10.0 -5.0 10.6 L 26 9.8 L 31 5.6 L 31 -5.8 L 26 -9.4 Z"
const STOCK_PLATE := "M -4 -6.6 L 22 -6.4 L 25 -3.6 L 25 3.6 L 22 6.8 L -4 6.6 Z"
const GRIP := "M 18.5 4.8 L 25.2 4.8 L 28.8 14.2 L 22.0 14.8 Z"
const BARREL_UPPER := "M 28 -7.2 L 106 -5.8 L 106 -1.8 L 28 -2.2 Z"
const BARREL_LOWER := "M 28 2.2 L 106 1.8 L 106 5.8 L 28 7.2 Z"
const BARREL_CHANNEL := "M 26 -2.2 L 108 -1.8 L 108 1.8 L 26 2.2 Z"
const RAIL_TOP := "M 34 -7.0 C 56 -12.2 82 -11.4 102 -5.8 L 96 -5.6 C 78 -9.2 56 -9.6 38 -6.8 Z"
const FIN_BOTTOM := "M 40 6.8 C 60 11.2 82 10.6 98 5.8 L 92 5.6 C 78 8.6 60 8.8 44 6.6 Z"
const MUZZLE_COLLAR := "M 103 -7.2 L 111 -8.0 L 111 8.0 L 103 7.2 Z"
const MUZZLE_TOP := "M 109 -7.8 L 122 -12.6 L 127.5 -10.8 L 124 -4.2 L 110 -2.6 Z"
const MUZZLE_BOT := "M 109 7.8 L 122 12.6 L 127.5 10.8 L 124 4.2 L 110 2.6 Z"
const RINGS: Array[float] = [46.0, 68.0, 90.0]
const RING := Vector3(1.9, -7.2, 7.2)
const CORE := Vector2(9.0, 0.0)
const MUZZLE_LIGHT := Vector2(124.0, 0.0)

## When true (TheEndScreen), Senna is solid, living, and lit by warm golden dawn.
var freed := false:
	set(value):
		freed = value
		_sync_state()
		queue_redraw()


func _init() -> void:
	super(BOX)
	moon_way = MOON_WAY.normalized()
	lantern_at = LANTERN_AT
	lantern_reach = LANTERN_REACH
	lantern_width = LANTERN_WIDTH
	_sync_state()


func _sync_state() -> void:
	if freed:
		feet_alpha = 1.0
		fade_from = 0.0
		lit_tint = FREED_LIT_TINT
		rim_top = FREED_RIM_TOP
		rim_feet = FREED_RIM_FEET
		fold_dark = FREED_FOLD_DARK
		fold_light = FREED_FOLD_LIGHT
	else:
		feet_alpha = SPIRIT_FEET_ALPHA
		fade_from = SPIRIT_FADE_FROM
		lit_tint = SPIRIT_LIT_TINT
		rim_top = SPIRIT_RIM_TOP
		rim_feet = SPIRIT_RIM_FEET
		fold_dark = SPIRIT_FOLD_DARK
		fold_light = SPIRIT_FOLD_LIGHT


## Her middle, in the parent's coordinates: where her motes drift.
func middle() -> Vector2:
	return at(MIDDLE)


## Where the robe's hem meets the ground in front of her, in the parent's
## coordinates: where the chain from the lantern ends.
func hem() -> Vector2:
	return at(HEM)


func _paint(paint: TitlePaint) -> void:
	var robe_col := FREED_ROBE if freed else SPIRIT_ROBE
	var cloak_col := FREED_CLOAK if freed else SPIRIT_CLOAK
	var mantle_col := FREED_MANTLE if freed else SPIRIT_MANTLE
	var scarf_col := FREED_SCARF if freed else SPIRIT_SCARF
	var trim_col := FREED_TRIM if freed else SPIRIT_TRIM
	var gold_col := FREED_GOLD if freed else SPIRIT_GOLD

	if freed:
		paint.glow(Vector2(70, 96), Vector2(56, 128), Color(FREED_RIM_TOP, 0.08))
	else:
		for aura in AURA:
			paint.glow(aura.position, aura.size, Color(TEAL, AURA_ALPHA))

	_part(paint, TitlePaint.outline(BACK_CLOAK), cloak_col)
	_fold(paint, "M 48 68 C 38 110 28 162 16 218", FOLD_WIDTH * 0.75)
	_part(paint, TitlePaint.outline(SCARF_DRAPE), scarf_col.darkened(0.24))
	_fold(paint, "M 47 72 C 41 104 34 136 26 166", FOLD_WIDTH * 0.55)
	_part(paint, TitlePaint.outline(BACK_BOOT), cloak_col.darkened(0.2))
	_part(paint, TitlePaint.outline(FRONT_BOOT), cloak_col.darkened(0.12))
	if freed:
		paint.line(Vector2(78, 215), Vector2(90, 215), 1.3, gold_col)
		paint.line(Vector2(53, 215.5), Vector2(64.5, 216), 1.1, gold_col)

	var robe := TitlePaint.outline(ROBE_SHAPE)
	_part(paint, robe, robe_col)
	for fold in ROBE_FOLDS:
		_fold(paint, fold, FOLD_WIDTH)
	paint.stroke("M 79 186 C 74 204 68 220 62 234", 1.1, Color(trim_col, 0.65))
	paint.stroke("M 80 186 C 83 204 86 220 90 235", 1.0, Color(trim_col, 0.55))
	if not freed:
		paint.glow_in(robe, SOUL_AT, 48.0, Color(TEAL, 0.34))

	_part(paint, TitlePaint.outline(SASH_DROP), mantle_col)
	paint.stroke("M 68 99 C 65 126 61 154 57 180", 0.95, Color(gold_col, 0.72))
	_part(paint, TitlePaint.outline(SASH), mantle_col.lightened(0.06))
	paint.line(Vector2(54, 92.5), Vector2(85, 92.0), 1.2, Color(gold_col, 0.75))
	paint.oval(Vector2(72, 92.4), Vector2(2.4, 2.0), gold_col)

	var mantle := TitlePaint.outline(MANTLE_SHAPE)
	_part(paint, mantle, mantle_col)
	_fold(paint, "M 60 44 Q 58 56 59 69", FOLD_WIDTH * 0.65)
	_fold(paint, "M 75 44 Q 79 56 78 70", FOLD_WIDTH * 0.6)
	paint.stroke("M 43 65 C 51 72 62 74.5 74 73 C 83.5 71.5 90.5 67.5 94.5 61.5", 1.1, Color(gold_col, 0.7))
	if not freed:
		paint.glow_in(mantle, SOUL_AT, 30.0, Color(TEAL, 0.3))

	_part(paint, TitlePaint.outline(SCARF_COLLAR), scarf_col)
	paint.oval(Vector2(78.5, 48.5), Vector2(2.2, 2.2), gold_col)

	_paint_head(paint)
	_paint_cannon(paint)
	_paint_arm(paint)


func _paint_cannon(paint: TitlePaint) -> void:
	var cannon_col := FREED_CANNON if freed else SPIRIT_CANNON
	var gold_col := FREED_GOLD if freed else SPIRIT_GOLD

	for part in [GRIP, STOCK, FIN_BOTTOM, RAIL_TOP, BARREL_LOWER, BARREL_UPPER, MUZZLE_COLLAR, MUZZLE_BOT, MUZZLE_TOP]:
		var outline := _cannon(TitlePaint.outline(part))
		_part(paint, outline, cannon_col)
		paint.rim(outline, moon_way * rim_width, CANNON_EDGE)

	paint.shape(_cannon(TitlePaint.outline(STOCK_PLATE)), cannon_col.lightened(0.14))
	paint.line(_cannon_pt(Vector2(-3.5, -6.5)), _cannon_pt(Vector2(22.0, -6.3)), 1.0, Color(gold_col, 0.85))
	paint.line(_cannon_pt(Vector2(-3.5, 6.5)), _cannon_pt(Vector2(22.0, 6.7)), 1.0, Color(gold_col, 0.85))
	paint.line(_cannon_pt(Vector2(107.0, -7.4)), _cannon_pt(Vector2(107.0, 7.4)), 1.4, gold_col)

	paint.shape(_cannon(TitlePaint.outline(BARREL_CHANNEL)), Color(TEAL, 0.82))
	paint.line(_cannon_pt(Vector2(28.0, 0.0)), _cannon_pt(Vector2(109.0, 0.0)), 1.4, TEAL_CORE)

	for x in RINGS:
		var band := Rect2(x - RING.x, RING.y, RING.x * 2.0, RING.z - RING.y)
		var ring_poly := _cannon(PackedVector2Array([band.position, Vector2(band.end.x, band.position.y), band.end, Vector2(band.position.x, band.end.y)]))
		paint.shape(ring_poly, TEAL)
		paint.line(_cannon_pt(Vector2(x - RING.x, RING.y)), _cannon_pt(Vector2(x - RING.x, RING.z)), 0.85, gold_col)
		paint.line(_cannon_pt(Vector2(x + RING.x, RING.y)), _cannon_pt(Vector2(x + RING.x, RING.z)), 0.85, gold_col)
		paint.glow(_cannon_pt(Vector2(x, 0.0)), Vector2(10.0, 10.0), Color(TEAL, 0.28))

	var core := _cannon_pt(CORE)
	paint.oval(core, Vector2(5.2, 5.2), gold_col)
	paint.oval(core, Vector2(4.2, 4.2), CORE_RIM)
	paint.oval(core, Vector2(3.1, 3.1), TEAL)
	paint.oval(core, Vector2(1.5, 1.5), TEAL_CORE)
	paint.glow(core, Vector2(12.5, 12.5), Color(TEAL, 0.5))

	var m_at := _cannon_pt(MUZZLE_LIGHT)
	paint.glow(m_at, Vector2(14.0, 14.0), Color(TEAL, 0.72))
	paint.oval(m_at, Vector2(2.6, 2.6), TEAL_CORE)


func _paint_arm(paint: TitlePaint) -> void:
	var mantle_col := FREED_MANTLE if freed else SPIRIT_MANTLE
	var skin_col := FREED_SKIN if freed else SPIRIT_SKIN
	var gold_col := FREED_GOLD if freed else SPIRIT_GOLD

	_part(paint, TitlePaint.outline(ARM), mantle_col)
	_fold(paint, "M 56 58 Q 59 68 64 77", FOLD_WIDTH * 0.6)
	_part(paint, TitlePaint.outline(BRACER), mantle_col.darkened(0.15))
	paint.line(Vector2(69.5, 78.2), Vector2(68.5, 87.2), 1.3, gold_col)
	var hand := TitlePaint.outline(HAND)
	_part(paint, hand, skin_col)
	paint.rim(hand, Vector2(0.7, -0.4), Color(TEAL, 0.42))
	paint.stroke("M 81.8 79.8 Q 83.0 82.8 82.2 86.8", 0.42, FEATURE_FREED if freed else FEATURE_SPIRIT)
	paint.stroke("M 84.6 80.2 Q 85.6 83.0 85.0 86.4", 0.42, FEATURE_FREED if freed else FEATURE_SPIRIT)


func _paint_head(paint: TitlePaint) -> void:
	var skin_col := FREED_SKIN if freed else SPIRIT_SKIN
	var hair_col := FREED_HAIR if freed else SPIRIT_HAIR
	var mantle_col := FREED_MANTLE if freed else SPIRIT_MANTLE
	var trim_col := FREED_TRIM if freed else SPIRIT_TRIM
	var gold_col := FREED_GOLD if freed else SPIRIT_GOLD
	var feat_col := FEATURE_FREED if freed else FEATURE_SPIRIT

	var face := TitlePaint.outline(FACE)
	_part(paint, face, skin_col)
	if freed:
		paint.taper(TitlePaint.outline("M 84.4 20.6 L 86.7 24.8"), 0.55, 0.3, Color(FREED_RIM_TOP, 0.35))
	else:
		paint.glow_in(face, Vector2(84, 28), 13.0, Color(TEAL, 0.42))
	paint.shape(face, TitlePaint.linear(Vector2(0, 14), Vector2(0, 21.5), HOOD_DARK, Color(HOOD_DARK, 0.0)))

	paint.stroke(BROW, 0.55, hair_col)
	if freed:
		paint.fill(EYE_OPEN, Color(0.92, 0.91, 0.89, 0.85))
		paint.oval(Vector2(83.2, 21.2), Vector2(0.58, 0.58), Color(0.08, 0.05, 0.04))
		paint.oval(Vector2(83.35, 21.0), Vector2(0.18, 0.18), Color.WHITE)
		paint.stroke("M 81.2 21.0 Q 82.8 20.1 84.5 21.1", 0.45, feat_col)
	else:
		paint.stroke(EYE_CLOSED, 0.6, feat_col)
	paint.stroke("M 84.8 28.0 L 83.2 27.9", 0.48, feat_col)
	paint.oval(Vector2(85.7, 25.2), Vector2(0.4, 0.26), feat_col)

	var hood := TitlePaint.outline(HOOD)
	_part(paint, hood, mantle_col)
	for fold in HOOD_FOLDS:
		_fold(paint, fold, FOLD_WIDTH * 0.58)
	paint.rim_inside(hood, Vector2(1.7, 0.0), TitlePaint.outline(TRIM_BOX), trim_col)

	for i in LOCKS.size():
		var line := TitlePaint.outline(LOCKS[i])
		paint.taper(line, LOCK_WIDTH.x, LOCK_WIDTH.y, hair_col)
		var sheen := Color(FREED_RIM_TOP, 0.3) if freed else Color(TEAL, 0.38)
		paint.taper(TitlePaint.moved(line, Vector2(0.5, -0.2)), LOCK_WIDTH.x * 0.3, 0.0, sheen)
		if i < 2:
			var cuff := line[line.size() / 2]
			paint.oval(cuff, Vector2(1.25, 0.65), gold_col, 0.15)


func _cannon(outline: PackedVector2Array) -> PackedVector2Array:
	return TitlePaint.turned(outline, Vector2.ZERO, CANNON_ANGLE, CANNON_AT)


func _cannon_pt(point: Vector2) -> Vector2:
	return _cannon(PackedVector2Array([point]))[0]

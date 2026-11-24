class_name TitleLucian
extends TitleFigure
## Lucian on the title and ending screens: commanding 3/4 heroic stance facing
## right. On the title screen his far arm aims his sleek Sentinel relic pistol
## towards Thresh while his near hand grips Senna's heavier relic pistol low
## at his side. When `peaceful` is true (TheEndScreen), he lowers his weapon
## into a calm, victorious stance bathed in warm golden dawn rim light.

## The art's frame, in units.
const BOX := Rect2(0, -12, 146, 260)
## Towards the moon, and where the lantern is in his units, how far its
## light reaches and how wide its rim on him is.
const MOON_WAY := Vector2(-0.55, -0.83)
const LANTERN_AT := Vector2(330, 100)
const LANTERN_REACH := 760.0
const LANTERN_WIDTH := 0.7

## Warm dawn lighting used in the peaceful ending state.
const DAWN_LIT_TINT := Color("f0cca0")
const DAWN_RIM_TOP := Color(1.0, 0.87, 0.6, 0.94)
const DAWN_RIM_FEET := Color(0.84, 0.6, 0.36, 0.34)

## His colours: Sentinel dark coat, slate vest, ivory under-tunic & trim,
## trousers, leather boots, belt, gold clasps, skin, locked hair, pistol
## silver-steel, Senna's relic stone-metal and its luminous teal core.
const COAT := Color("151d28")
const COAT_INNER := Color("212c3b")
const COAT_TRIM := Color("cbc4b2")
const TROUSERS := Color("10151c")
const BOOTS := Color("0b0e13")
const BOOT_PLATE := Color("202835")
const VEST := Color("1c2532")
const SHIRT := Color("bebaa9")
const BELT := Color("241c17")
const GOLD := Color("deb562")
const GOLD_BRIGHT := Color("ffe5a0")
const SKIN := Color("4b2d1e")
const SKIN_SHADE := Color("24130b")
const HAIR := Color("0d0b0c")
const STEEL := Color("34404e")
const PISTOL_IVORY := Color("d2d5da")
const RELIC := Color("374c52")
const RELIC_DARK := Color("1e2b30")
const TEAL := Color("b8fff0")
const MUZZLE := Color("fff1c4")
const LIGHT_CHANNEL := Color("ffe9aa")

## Subtle lighting accents and facial details.
const STEEL_LIGHT := Color(0.88, 0.93, 1.0, 0.64)
const KNUCKLE_LIGHT := Color(1.0, 0.86, 0.7, 0.34)
const SOLE_LIGHT := Color(0.58, 0.7, 0.86, 0.34)
const CREASE := Color(0.0, 0.0, 0.02, 0.56)
const EYE_WHITE := Color(0.88, 0.91, 0.9, 0.8)
const PUPIL := Color(0.05, 0.04, 0.04)
const NOSTRIL := Color(0.14, 0.07, 0.05)
const HEM_SHADE := Color(0.0, 0.0, 0.02, 0.48)

## Grounded athletic stance: braced rear leg, forward leg bent at knee with
## nearly vertical shin and sculpted leather Sentinel boots.
const BACK_LEG := "M 50 122 L 68 124 C 65 144 62 160 59 174 C 58 190 55 208 52 224 L 40 224 C 39 210 39 194 42 178 C 44 162 46 142 50 122 Z"
const BACK_KNEEPAD := "M 42.5 166 C 48 164 55 165 59.5 169 L 58.5 178 C 53 176 47 176 42 178 Z"
const BACK_BOOT := "M 38.5 212 L 53.5 213 L 53 230 C 56 235 60 238.5 64 241 C 65 243 64.5 245 62.5 246 L 44.5 246 L 42.5 244.5 L 36 246 L 35.5 238 C 37 231 38.5 222 38.5 212 Z"

const FRONT_LEG := "M 67 120 L 87 120 C 94 139 98 156 97.5 171 C 97 188 96 206 95 222 L 82 222 C 80 206 79 190 80 175 C 76 158 70 140 67 120 Z"
const FRONT_KNEEPAD := "M 82 165 C 88 163 95 164 98 168 L 97.5 177 C 92.5 175.5 87 175.5 81.5 177 Z"
const FRONT_BOOT := "M 80.5 210 L 96.5 211 L 97 227 C 102 233 109 237.5 114.5 240.5 C 115.8 242.5 115.2 245 113 246 L 91 246 L 88.5 244.5 L 80 246 L 79.5 236 C 80.5 229 80.5 220 80.5 210 Z"

## Layered far coat-tail sweeping behind his legs for wind-blown volume.
const FAR_COAT_TAIL := "M 49 114 L 65 117 C 57 152 42 188 20 220 C 13 224 7 220 4 215 C 19 190 35 154 49 114 Z"

## Broad heroic V-taper Sentinel coat with sweeping S-curve billowing back
## tail and organic curved front flap.
const COAT_SHAPE := "M 42 47 C 44 39 53 35 64 34.5 L 81 36.5 L 88 46 C 86.5 65 83.5 84 82 101 C 88 125 97 154 106 190 C 102 200 94 205 86 202 C 80 174 75 148 70 127 L 61 127 C 57 155 52 184 44 214 C 31 225 14 224 2 214 C 14 196 27 172 36 144 C 42 124 47 108 46.5 92 C 43 76 41 60 42 47 Z"
const COAT_BACK_HEM_TRIM := "M 4.5 212 C 16 220 31 221 43.2 211.5 L 44.2 207.5 C 32 217 17.5 216 7.0 208.5 Z"
const COAT_FRONT_HEM_TRIM := "M 86.5 199 C 93 201.5 100 198 104.5 189 L 103.5 185 C 99 194 92.5 197.5 85.8 195.2 Z"

## Structured chest vest, ivory shirt V-neck, diagonal strap & utility belt.
const VEST_SHAPE := "M 55 37.5 L 80 37.5 L 87 47.5 C 85.5 66 83 84 81.5 99 L 56 100 C 55 82 54.5 60 55 37.5 Z"
const SHIRT_SHAPE := "M 64 37 L 77.5 37.5 L 73 51.5 Z"
const CHEST_STRAP := "M 52 43 L 58.5 40.5 L 82 95.5 L 76 97.5 Z"
const BELT_SHAPE := "M 46.5 96.5 L 82.5 95 L 82.8 102.5 L 47 104 Z"

## High layered Sentinel collar framing his neck & jawline.
const COLLAR_BACK := "M 49 45 L 52 24.5 C 55 21.5 60.5 22 65 27.5 L 70 38.5 L 62.5 45 Z"
const COLLAR_LINING := "M 53.5 26.5 C 56.5 24.5 60 25 63.2 29 L 67.5 38 L 63.5 40 L 55 34 Z"
const COLLAR_FRONT := "M 75.5 39 L 82 28.5 C 84.5 29.5 86.8 34.5 87.2 41.5 L 80.5 47 Z"

## Sculpted 3/4 heroic profile head, noble jaw, trimmed beard & flowing locks.
const HEAD_PIVOT := Vector2(69.5, 36.0)
const NECK := "M 62 31 L 74.5 33 L 75.5 44 L 61.5 43 Z"
const HEAD := "M 64 38 L 62.5 29 C 60 24.5 59.5 18.5 61 13.5 C 62.8 8 67.5 4.8 73 5.2 C 78.2 5.6 81.2 9 81.6 13.4 L 82.2 16.4 L 81.2 18.2 L 82.0 20.2 L 84.4 23.4 L 82.2 24.8 L 81.8 25.9 L 82.4 27.1 L 81.7 28.1 L 82.0 29.3 L 80.8 31.2 C 81.0 32.5 80.4 33.8 79.0 34.6 C 77.2 35.6 74.4 36.0 71.5 35.4 L 72.5 39 Z"
const HAIR_CROWN := "M 81.4 12.6 C 80.6 8.2 77.2 4.8 72.2 4.6 C 66.2 4.4 61.4 8.2 59.8 14.2 C 58.6 19 59.6 24.6 62 29 L 66 28.6 C 67.4 25.2 68.4 22.4 69.8 20 C 71.4 17.2 73.2 15.2 75.6 13.8 C 77.6 12.8 79.4 12.4 81.4 12.6 Z"
const HAIR_LOCKS: Array[String] = [
	"M 66.5 8.5 C 60 9.5 54 13 50 18.5",
	"M 63 12 C 56.5 14 51.5 18.5 48.5 24.5",
	"M 61.5 17 C 55.5 20 51.5 25 49.5 31.5",
	"M 62 22.5 C 57.5 26 54.5 31 53.5 37",
	"M 64.5 26 C 61 30 59 34 58.5 39",
]
const BEARD := "M 71.6 21.0 L 73.4 21.4 C 74.2 25.2 75.8 28.2 78.0 29.5 C 79.2 30.0 80.4 30.0 81.0 30.5 C 81.1 32.0 80.5 33.6 79.0 34.6 C 77.2 35.6 74.4 35.9 71.6 35.3 C 68.8 34.4 67.4 31.8 66.8 28.6 L 68.0 25.6 C 69.4 24.2 70.6 22.6 71.6 21.0 Z"
const MUSTACHE := "M 79.4 25.3 L 82.0 25.6 L 82.5 27.0 L 80.5 27.3 C 79.3 27.0 78.3 26.5 77.7 25.9 Z"
const EYE := "M 78.2 18.8 L 80.7 18.5 L 80.3 19.6 L 78.4 19.5 Z"
const BROW_COMBAT := "M 76.4 16.6 L 79.2 17.5 L 81.7 17.0"
const BROW_PEACEFUL := "M 76.6 17.0 Q 79.2 16.2 81.6 16.8"

## Far arm (combat: athletic shoulder, slight elbow bend, armored bracer & fist
## cleanly gripping the Sentinel pistol handle).
const FAR_ARM_COMBAT := "M 80 41 C 90 42 98 46.5 103 49.5 L 116 46.5 L 116.5 55.5 C 109 58 101 59.5 95.5 58 C 88 56 82 54.5 78 53.5 Z"
const FAR_BRACER_COMBAT := "M 105.5 48.2 L 116 46.2 L 116.5 55.6 L 106 57.6 Z"
const FAR_FIST_COMBAT := "M 114.2 46.6 C 118.2 45.8 122.2 46.6 123.4 49.8 L 122.8 55.8 C 120.4 57.6 117.2 57.8 114.4 56.8 Z"

## Far arm (peaceful: lowered naturally at his side, pistol hanging relaxed).
const FAR_ARM_PEACEFUL := "M 80 42 C 87 45 92 56 95 72 C 98 84 100.5 94 103 102 L 94.5 104.5 C 91 94 87.5 83 85 72 C 82 60 80 52 78.5 46 Z"
const FAR_BRACER_PEACEFUL := "M 91 90 L 99.5 88 L 103 102 L 94.5 104.5 Z"
const FAR_FIST_PEACEFUL := "M 95.0 101.2 C 97.8 100.0 101.5 100.4 103.2 103.0 C 104.2 105.8 102.6 109.0 99.8 109.8 C 97.0 110.2 94.6 108.4 94.2 105.6 Z"

## Lucian's sleek Sentinel Relic Pistol: grip centered at (0, 0) so the fist
## wraps cleanly around the handle in BOTH combat and peaceful poses!
const PISTOL_AT_COMBAT := Vector2(118.5, 53.0)
const PISTOL_ANGLE_COMBAT := -0.02
const PISTOL_AT_PEACEFUL := Vector2(99.2, 105.6)
const PISTOL_ANGLE_PEACEFUL := 1.24
const PISTOL_GRIP := "M -3.4 -3.2 L 3.4 -3.2 L 1.6 7.8 L -4.2 7.2 Z"
const PISTOL_FRAME := "M -4.8 -9.6 L 20.6 -9.6 L 25.4 -8.0 L 25.4 -4.0 L 19.6 -2.2 L 6.8 -1.8 L 5.0 0.8 L -3.6 0.8 Z"
const PISTOL_SLIDE := "M -4.2 -10.2 L 23.6 -10.2 L 25.4 -8.4 L 25.4 -6.8 L -4.2 -6.8 Z"
const PISTOL_GUARD := "M 4.6 -2.0 L 10.2 -2.0 L 8.4 3.2 L 2.2 3.2 L 2.6 1.6 L 6.8 1.6 L 7.6 -0.8 L 4.6 -0.8 Z"
const PISTOL_MUZZLE_LOCAL := Vector2(26.2, -6.6)

## Near arm: broad Sentinel shoulder pad, elbow bent back slightly so his
## forearm brings Senna's Relic Pistol cleanly forward-down at his side.
const NEAR_PAULDRON := "M 38 48 C 40 39.5 49 36.5 59 38.5 L 63.5 45 C 57 49.5 47.5 52 38 52 Z"
const NEAR_ARM := "M 42 47 C 48.5 43 57 45 59 51 C 57.5 61 55 70 53.5 78 C 57.5 85.5 62.5 92.5 67 99 L 59.5 104 C 53 96.5 46.5 88.5 43 79.5 C 40 68.5 40 57.5 42 47 Z"
const NEAR_BRACER := "M 51.5 86 L 59 83 L 67 99 L 59.5 104 Z"
const NEAR_HAND := "M 59.5 100.2 C 61.5 97.6 65.4 97.2 67.8 98.8 C 69.8 100.4 70.0 103.8 68.4 106.4 C 66.6 108.6 62.8 108.8 60.6 107.2 C 58.8 105.6 58.6 102.4 59.5 100.2 Z"

## Senna's heavier gunmetal-and-teal Relic Pistol: grip centered at (0, 0) so
## his near fist wraps firmly around the handle beneath the receiver!
const RELIC_AT_COMBAT := Vector2(64.8, 103.8)
const RELIC_ANGLE_COMBAT := 0.54
const RELIC_AT_PEACEFUL := Vector2(65.0, 104.5)
const RELIC_ANGLE_PEACEFUL := 0.80
const RELIC_GRIP := "M -3.4 -2.8 L 3.0 -2.8 L 0.8 6.8 L -4.8 6.2 Z"
const RELIC_GUARD := "M -7.0 -11.4 C 2.0 -15.8 15.0 -15.6 27.0 -10.8 L 26.5 -9.0 C 15.0 -12.8 2.5 -12.8 -5.5 -9.8 Z"
const RELIC_BODY := "M -7.6 -10.2 C -7.6 -12.4 -5.4 -13.0 -2.8 -13.0 L 11.6 -12.4 L 15.0 -9.8 L 15.0 -1.8 L 11.4 -0.2 L -3.8 -0.2 C -6.4 -0.2 -8.0 -2.0 -7.6 -4.0 Z"
const RELIC_BARREL := "M 14.0 -9.4 L 32.4 -8.8 L 32.4 -2.8 L 14.0 -2.2 Z"
const RELIC_CAP := "M 31.2 -10.6 L 36.8 -10.0 L 37.8 -5.6 L 36.8 -1.4 L 31.2 -1.0 Z"
const RELIC_RINGS: Array[float] = [18.8, 25.4]
const RELIC_RING := Vector3(1.15, -9.3, -2.3)
const RELIC_CORE := Vector2(3.6, -6.2)

## Coat and sleeve cloth folds.
const COAT_FOLDS: Array[String] = [
	"M 46.5 108 C 41 136 30 166 11 204",
	"M 51 114 C 47 144 39 174 24 210",
	"M 56.5 130 C 53.5 156 49 184 40 212",
	"M 46 92 C 47.5 72 46 56 48 46",
	"M 84.5 118 C 89 146 94 170 100 192",
	"M 76.5 126 C 81.5 154 86.5 176 91.5 196",
]
const SLEEVE_FOLDS_COMBAT: Array[String] = [
	"M 92 47.5 Q 94.5 52 93 57.5",
	"M 99.5 49 Q 101.5 53 100 58",
	"M 85 45.5 Q 87 50 86 55.5",
]
const FOLD_WIDTH := 2.6

## Peaceful ending stance: lowers Lucian's weapon and shifts to warm dawn rim light.
var peaceful := false:
	set(value):
		peaceful = value
		_sync_lighting()
		queue_redraw()


func _init() -> void:
	super(BOX)
	moon_way = MOON_WAY.normalized()
	lantern_at = LANTERN_AT
	lantern_reach = LANTERN_REACH
	lantern_width = LANTERN_WIDTH
	_sync_lighting()


func _sync_lighting() -> void:
	if peaceful:
		lit_tint = DAWN_LIT_TINT
		rim_top = DAWN_RIM_TOP
		rim_feet = DAWN_RIM_FEET
	else:
		lit_tint = MOON_TINT
		rim_top = MOON_RIM_TOP
		rim_feet = MOON_RIM_FEET


## Where his pistol's muzzle is, in the parent's coordinates.
func muzzle() -> Vector2:
	return at(_pistol(PackedVector2Array([PISTOL_MUZZLE_LOCAL]))[0])


## Where the relic gun's core is, in the parent's coordinates.
func relic_core() -> Vector2:
	return at(_relic(PackedVector2Array([RELIC_CORE]))[0])


func _paint(paint: TitlePaint) -> void:
	_part(paint, TitlePaint.outline(FAR_COAT_TAIL), COAT.darkened(0.3))
	_paint_legs(paint)
	_paint_far_arm(paint)
	_paint_coat(paint)
	_paint_head(paint)
	_paint_near_arm(paint)


func _paint_legs(paint: TitlePaint) -> void:
	_part(paint, TitlePaint.outline(BACK_LEG), TROUSERS)
	_fold(paint, "M 44 166 Q 50 172 58 170", FOLD_WIDTH * 0.8)
	_part(paint, TitlePaint.outline(BACK_KNEEPAD), BOOT_PLATE)
	_part(paint, TitlePaint.outline(BACK_BOOT), BOOTS)
	paint.line(Vector2(38.5, 214), Vector2(53.5, 215), 1.4, GOLD)
	paint.line(Vector2(38.5, 224), Vector2(53.0, 225), 0.9, BOOT_PLATE.lightened(0.15))

	_part(paint, TitlePaint.outline(FRONT_LEG), TROUSERS)
	_fold(paint, "M 82 168 Q 89 173 96.5 169", FOLD_WIDTH * 0.8)
	_fold(paint, "M 72 136 Q 82 146 92 162", FOLD_WIDTH * 0.65)
	_part(paint, TitlePaint.outline(FRONT_KNEEPAD), BOOT_PLATE)
	_part(paint, TitlePaint.outline(FRONT_BOOT), BOOTS)
	paint.line(Vector2(80.5, 212), Vector2(96.5, 213), 1.6, GOLD)
	paint.line(Vector2(81, 223), Vector2(96.8, 224), 1.0, BOOT_PLATE.lightened(0.15))
	paint.line(Vector2(81, 232), Vector2(98, 233), 0.9, GOLD.darkened(0.15))
	for sole in ["M 36.2 244.6 L 63.0 244.6", "M 80.2 244.6 L 113.5 244.6"]:
		paint.stroke(sole, 0.9, SOLE_LIGHT)


## The far arm: aiming his sleek Sentinel pistol in combat, or relaxed low in peace.
func _paint_far_arm(paint: TitlePaint) -> void:
	if peaceful:
		_part(paint, TitlePaint.outline(FAR_ARM_PEACEFUL), COAT)
		_fold(paint, "M 84 62 Q 88 70 93 78", FOLD_WIDTH * 0.65)
		_part(paint, TitlePaint.outline(FAR_BRACER_PEACEFUL), BOOT_PLATE)
		paint.line(Vector2(91, 90.5), Vector2(99.5, 88.5), 1.2, GOLD)
		_paint_sentinel_pistol(paint)
		var fist := TitlePaint.outline(FAR_FIST_PEACEFUL)
		_part(paint, fist, SKIN)
		paint.rim(fist, Vector2(0.6, -0.4), KNUCKLE_LIGHT)
	else:
		_part(paint, TitlePaint.outline(FAR_ARM_COMBAT), COAT)
		for fold in SLEEVE_FOLDS_COMBAT:
			_fold(paint, fold, FOLD_WIDTH * 0.65)
		_part(paint, TitlePaint.outline(FAR_BRACER_COMBAT), BOOT_PLATE)
		paint.line(Vector2(106, 48.2), Vector2(106.5, 57.6), 1.3, GOLD)
		_paint_sentinel_pistol(paint)
		var fist := TitlePaint.outline(FAR_FIST_COMBAT)
		_part(paint, fist, SKIN)
		paint.stroke("M 116.2 48.2 Q 119.2 47.4 121.6 49.0", 0.55, KNUCKLE_LIGHT)
		paint.stroke("M 117.2 51.4 L 122.0 51.8", 0.45, CREASE)
		paint.stroke("M 116.8 54.0 L 121.4 54.4", 0.45, CREASE)


func _paint_sentinel_pistol(paint: TitlePaint) -> void:
	_part(paint, _pistol(TitlePaint.outline(PISTOL_GRIP)), STEEL.darkened(0.25))
	_part(paint, _pistol(TitlePaint.outline(PISTOL_GUARD)), GOLD.darkened(0.1))
	_part(paint, _pistol(TitlePaint.outline(PISTOL_FRAME)), STEEL)
	_part(paint, _pistol(TitlePaint.outline(PISTOL_SLIDE)), PISTOL_IVORY)
	var top_a := _pistol(PackedVector2Array([Vector2(-2.5, -9.6)]))[0]
	var top_b := _pistol(PackedVector2Array([Vector2(23.0, -9.6)]))[0]
	paint.line(top_a, top_b, 0.7, STEEL_LIGHT)
	var band_a := _pistol(PackedVector2Array([Vector2(13.2, -10.2)]))[0]
	var band_b := _pistol(PackedVector2Array([Vector2(13.2, -2.2)]))[0]
	paint.line(band_a, band_b, 1.5, GOLD)
	var chan_a := _pistol(PackedVector2Array([Vector2(2.0, -6.2)]))[0]
	var chan_b := _pistol(PackedVector2Array([Vector2(22.4, -6.2)]))[0]
	paint.line(chan_a, chan_b, 1.25, Color(LIGHT_CHANNEL, 0.45 if peaceful else 0.94))
	if not peaceful:
		var tip := _pistol(PackedVector2Array([PISTOL_MUZZLE_LOCAL]))[0]
		paint.glow(tip, Vector2(7.0, 7.0), Color(MUZZLE, 0.55))
		paint.oval(tip, Vector2(1.3, 1.3), MUZZLE)


## The long Sentinel coat, vest with gold clasps, utility belt & high collar.
func _paint_coat(paint: TitlePaint) -> void:
	var coat := TitlePaint.outline(COAT_SHAPE)
	_part(paint, coat, COAT)
	paint.shape(coat, TitlePaint.linear(Vector2(0, 126), Vector2(0, 224), Color(HEM_SHADE, 0.0), HEM_SHADE))
	paint.fill(COAT_BACK_HEM_TRIM, Color(COAT_TRIM, 0.75))
	paint.fill(COAT_FRONT_HEM_TRIM, Color(COAT_TRIM, 0.75))
	for fold in COAT_FOLDS:
		_fold(paint, fold, FOLD_WIDTH)
	_part(paint, TitlePaint.outline(VEST_SHAPE), VEST)
	paint.fill(SHIRT_SHAPE, SHIRT)
	paint.stroke("M 71 42 C 72 60 72.5 80 72.5 97", 0.8, CREASE)
	for y_clasp in [53.0, 64.0, 75.0, 86.0]:
		paint.line(Vector2(67.2, y_clasp), Vector2(76.2, y_clasp - 0.4), 1.5, GOLD)
		paint.oval(Vector2(71.8, y_clasp - 0.2), Vector2(1.3, 0.9), GOLD_BRIGHT)
	_part(paint, TitlePaint.outline(CHEST_STRAP), BELT)
	paint.line(Vector2(55.5, 42.0), Vector2(79.0, 96), 0.7, Color(GOLD, 0.45))
	_part(paint, TitlePaint.outline(BELT_SHAPE), BELT)
	paint.fill("M 64.5 95.6 L 71.2 95.3 L 71.5 102.6 L 64.8 102.9 Z", GOLD)
	paint.fill("M 66.0 97.1 L 69.8 96.9 L 70.0 101.1 L 66.2 101.3 Z", BELT)
	paint.oval(Vector2(68.0, 99.1), Vector2(0.9, 0.9), GOLD_BRIGHT)
	_part(paint, TitlePaint.outline(COLLAR_BACK), COAT)
	paint.fill(COLLAR_LINING, Color(COAT_TRIM, 0.7))
	paint.stroke("M 52 24.5 C 55 21.5 60.5 22 65 27.5 L 70 38.5", 0.9, GOLD)
	_part(paint, TitlePaint.outline(COLLAR_FRONT), COAT_INNER)
	paint.stroke("M 75.5 39 L 82 28.5 C 84.5 29.5 86.4 34 86.8 40.5", 0.85, GOLD)


## Sculpted 3/4 profile head with subtle facial planes, trimmed beard & locks.
func _paint_head(paint: TitlePaint) -> void:
	_part(paint, _head(TitlePaint.outline(NECK)), SKIN.darkened(0.2))
	var head_shape := _head(TitlePaint.outline(HEAD))
	_part(paint, head_shape, SKIN)
	# Subtle brow-socket recess and warm nose-bridge rim (no oval cheek spot).
	paint.shape(_head(TitlePaint.outline("M 76.5 17.6 L 81.2 17.7 L 80.6 20.3 L 76.8 20.0 Z")), Color(SKIN_SHADE, 0.36))
	paint.taper(_head(TitlePaint.outline("M 81.6 18.8 L 83.9 23.0")), 0.65, 0.35, Color(lit_tint, 0.25))
	paint.shape(_head(TitlePaint.outline(HAIR_CROWN)), HAIR)
	for i in HAIR_LOCKS.size():
		var track := _head(TitlePaint.outline(HAIR_LOCKS[i]))
		paint.taper(track, 2.7 - i * 0.12, 1.0, HAIR)
		paint.taper(TitlePaint.moved(track, Vector2(0.0, -0.6)), 0.6, 0.0, Color(lit_tint, 0.24))
	paint.shape(_head(TitlePaint.outline(BEARD)), Color(HAIR, 0.95))
	paint.shape(_head(TitlePaint.outline(MUSTACHE)), HAIR)
	paint.oval(_head_pt(Vector2(69.2, 22.2)), Vector2(1.5, 2.4), SKIN.darkened(0.24), 0.18)
	paint.oval(_head_pt(Vector2(69.4, 22.4)), Vector2(0.7, 1.25), SKIN_SHADE, 0.18)
	paint.shape(_head(TitlePaint.outline(EYE)), EYE_WHITE)
	paint.oval(_head_pt(Vector2(79.6, 19.0)), Vector2(0.48, 0.48), PUPIL)
	paint.oval(_head_pt(Vector2(79.75, 18.85)), Vector2(0.16, 0.16), Color.WHITE)
	paint.taper(_head(TitlePaint.outline(BROW_PEACEFUL if peaceful else BROW_COMBAT)), 0.9, 0.8, HAIR)
	paint.oval(_head_pt(Vector2(82.4, 24.0)), Vector2(0.42, 0.28), NOSTRIL)
	paint.line(_head_pt(Vector2(80.2, 27.6)), _head_pt(Vector2(81.9, 27.6)), 0.45, SKIN_SHADE)


## Near arm, Sentinel shoulder pad, bracer & fist firmly gripping Senna's Relic Pistol.
func _paint_near_arm(paint: TitlePaint) -> void:
	var core := _relic(PackedVector2Array([RELIC_CORE]))[0]
	paint.glow_in(TitlePaint.outline(COAT_SHAPE), core, 28.0, Color(TEAL, 0.16))
	_part(paint, TitlePaint.outline(NEAR_ARM), COAT)
	_fold(paint, "M 45 62 Q 49.5 69 53 77", FOLD_WIDTH * 0.8)
	_fold(paint, "M 48.5 82 Q 53.5 87 57.5 94", FOLD_WIDTH * 0.65)
	_part(paint, TitlePaint.outline(NEAR_PAULDRON), BOOT_PLATE)
	paint.stroke("M 38.5 48 C 41 41 49 38 58.5 40", 1.2, GOLD)
	_part(paint, TitlePaint.outline(NEAR_BRACER), BOOT_PLATE)
	paint.line(Vector2(51.5, 86.2), Vector2(59.0, 83.2), 1.4, GOLD)
	# Senna's Relic Pistol: grip sits right inside his closed fist below the receiver.
	_part(paint, _relic(TitlePaint.outline(RELIC_GRIP)), RELIC_DARK)
	for part in [RELIC_BODY, RELIC_BARREL, RELIC_CAP, RELIC_GUARD]:
		_part(paint, _relic(TitlePaint.outline(part)), RELIC)
	paint.line(_relic(PackedVector2Array([Vector2(-3.5, -11.4)]))[0], _relic(PackedVector2Array([Vector2(11.4, -11.0)]))[0], 0.85, GOLD)
	for x in RELIC_RINGS:
		var band := Rect2(x - RELIC_RING.x, RELIC_RING.y, RELIC_RING.x * 2.0, RELIC_RING.z - RELIC_RING.y)
		paint.shape(_relic(PackedVector2Array([band.position, Vector2(band.end.x, band.position.y), band.end, Vector2(band.position.x, band.end.y)])), TEAL)
	paint.glow(_relic(PackedVector2Array([Vector2(21.5, -5.8)]))[0], Vector2(14.0, 9.0), Color(TEAL, 0.28))
	paint.oval(core, Vector2(3.1, 3.1), GOLD)
	paint.oval(core, Vector2(2.3, 2.3), TEAL)
	paint.glow(core, Vector2(8.5, 8.5), Color(TEAL, 0.55))
	var hand := TitlePaint.outline(NEAR_HAND)
	_part(paint, hand, SKIN)
	paint.rim(hand, Vector2(0.8, 0.4), Color(TEAL, 0.55))
	paint.stroke("M 62.5 98.8 Q 64.2 102.0 63.4 106.8", 0.45, CREASE)
	paint.stroke("M 65.4 99.4 Q 66.8 102.4 66.0 106.4", 0.45, CREASE)


func _head(outline: PackedVector2Array) -> PackedVector2Array:
	if not peaceful:
		return outline
	return TitlePaint.turned(outline, HEAD_PIVOT, -0.065, Vector2(0.0, -0.8))


func _head_pt(point: Vector2) -> Vector2:
	return _head(PackedVector2Array([point]))[0]


func _pistol(outline: PackedVector2Array) -> PackedVector2Array:
	var at_pos := PISTOL_AT_PEACEFUL if peaceful else PISTOL_AT_COMBAT
	var angle := PISTOL_ANGLE_PEACEFUL if peaceful else PISTOL_ANGLE_COMBAT
	return TitlePaint.turned(outline, Vector2.ZERO, angle, at_pos)


func _relic(outline: PackedVector2Array) -> PackedVector2Array:
	var at_pos := RELIC_AT_PEACEFUL if peaceful else RELIC_AT_COMBAT
	var angle := RELIC_ANGLE_PEACEFUL if peaceful else RELIC_ANGLE_COMBAT
	return TitlePaint.turned(outline, Vector2.ZERO, angle, at_pos)

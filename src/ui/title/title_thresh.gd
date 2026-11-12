class_name TitleThresh
extends TitleFigure
## Thresh on the title, looming at the right and facing left, towards
## Lucian and Senna. A tall hood over a dark face with burning green eyes,
## spiked pauldrons, a ribbed chest with the green of the souls showing
## between the ribs, a long tattered robe and chains across him and down to
## the ground. His near hand holds the lantern out on a short chain, small
## souls caged in its light, which lights him green from below; his far hand
## lets the sickle hang on its chain. The moon is far to his upper left.

## The art's frame, in units.
const BOX := Rect2(-12, -8, 176, 286)
## Towards the moon, and his lantern (its middle) and how far its light
## reaches.
const MOON_WAY := Vector2(-0.85, -0.53)
const LANTERN_MIDDLE := Vector2(21, 139)
const LANTERN_REACH := 115.0

## His colours: the robe, the iron of his armour, the dark of his face, his
## bone-pale claws, the chains, his eyes and the souls' green.
const ROBE := Color("0b1411")
const IRON := Color("1a2521")
const FACE_DARK := Color("010403")
const CLAW := Color("3a4a42")
const CHAIN := Color("466454")
const CHAIN_EDGE := Color(0.01, 0.02, 0.015, 0.95)
const EYE := Color("eafff2")
const SOUL := Color("8fe3b0")
## A fold in his robe: its shadow, the light on its ridge and its width.
const FOLD_DARK := Color(0.0, 0.0, 0.0, 0.5)
const FOLD_LIGHT := Color(0.7, 0.85, 0.95, 0.12)
const FOLD_WIDTH := 3.4

## His parts, back to front.
const FAR_ARM := "M 123 71 L 137 70 C 141 96 145 120 148.4 146 L 139 148 C 135 124 130 98 123 71 Z"
const FAR_HAND := "M 138 144 L 148.6 142.6 L 150.6 150 L 148 156 L 144.6 152 L 142.6 157 L 140 152 Z"
const SICKLE := "M 140 186 C 162 181 178 198 173 232 C 167 213 157 202 138.6 198 Z"
const SICKLE_HAFT := "M 141.6 177 L 146.4 177 L 145.6 196 L 140.6 196 Z"
const SICKLE_RING := Vector2(144, 174)
const ROBE_SHAPE := "M 82 118 L 120 116 C 127 150 137 190 146 228 C 150 244 154 260 157 276 L 149 266 L 146 277 L 137 263 L 131 276 L 122 262 L 113 277 L 106 265 L 99 276 L 92 260 L 85 275 L 77 262 L 67 273 L 61 256 L 50 268 L 47 254 L 34 262 L 38 250 L 24 254 C 40 236 54 212 62 190 C 70 166 77 144 82 118 Z"
const TORSO := "M 63 70 C 90 65 112 61 135 63 C 133 88 125 108 117 128 L 83 131 C 77 110 69 90 63 70 Z"
const FAR_PAULDRON := "M 108 62 C 116 54 130 55 137 62 C 141 69 139 77 134 81 L 110 77 Z"
const FAR_SPIKES: Array[String] = ["M 121 58 L 131 33 L 131.4 60 Z", "M 130 61 L 152 46 L 137 68 Z"]
const HOOD := "M 69 61 C 63 52 61 40 64 30 C 67 20 75 13 85 10.6 C 92 5.6 99 -1 109 -6 C 103 3 100.6 10 101.4 16 C 106.4 24 107.4 36 104.4 46 C 102.4 54 98 60.4 92 64.6 Z"
const FACE := "M 66.6 31.6 C 69.6 24.6 76.6 20.6 83.6 22.6 C 87.6 29.6 87.6 41.6 83.6 51.6 C 79.6 57.6 73.6 59.6 69.6 55.6 C 65.6 49.6 64.6 39.6 66.6 31.6 Z"
const SLEEVE := "M 66 73 C 60 86 52 95 44 99 L 45 114 L 49.6 104 L 53 120 L 57 104.6 L 62.4 114 L 63 98 C 66 92 68 86 70.6 79 Z"
const ARM := "M 61 70 C 57 80 51 89 45 95 C 40 98.6 34 99.6 28 100 L 28 106 C 35 106.6 42 106 49 103 C 56 98 62 90 68 82 Z"
const PAULDRON := "M 50 75 C 52 63 62 55 74 55 L 85 59 L 83 76 C 72 80.6 60 80.6 50 75 Z"
const SPIKES: Array[String] = ["M 54 68 L 36 47 L 61 61 Z", "M 61 60.6 L 51 36 L 69 56.6 Z", "M 70 57 L 70 34 L 78 56.6 Z"]
## The lines between the near pauldron's plates.
const PAULDRON_LAMES: Array[String] = ["M 52 70 C 61 73.4 72 73.6 83.4 69.6", "M 56 63.6 C 64 66 73 66.4 84 63"]
const HAND := "M 29.4 99.4 L 22.4 99.2 L 17.4 102.6 L 21.4 103.4 L 17.6 107 L 22.6 106.2 L 21.4 110.6 L 25.8 107.2 L 30.4 106.6 Z"
## The ribs across his chest: where each starts at his breastbone, where it
## curves round, and where it ends.
const RIBS: Array[String] = [
	"M 110 74 Q 88 72 69 83",
	"M 109 84 Q 88 82 71.6 93.4",
	"M 107 94 Q 88 92.6 74.4 104",
	"M 104 104 Q 89 103.4 77.4 114",
]
const RIB_WIDTH := Vector2(2.2, 5.0)
## The robe's folds, and the hood's.
const ROBE_FOLDS: Array[String] = [
	"M 92 132 C 90 172 84 212 76 256",
	"M 106 130 C 110 172 116 214 121 258",
	"M 84 140 C 78 180 66 220 52 258",
	"M 116 132 C 124 170 134 214 142 262",
]
const HOOD_FOLDS: Array[String] = ["M 98 16 C 102 30 101 44 96 56", "M 88 14 C 94 26 95 42 92 58"]
## The chains: across his chest, round his waist, from his lantern arm
## and down his robe to the ground, where the backdrop takes it on to
## Senna; how long a link is.
const CHAINS: Array[String] = [
	"M 70 77 C 88 91 104 103 122 115",
	"M 81 125 C 95 131 109 129 120 123",
	"M 47 101 C 51 122 65 132 81 125",
	"M 81 126 C 69 160 57 214 43 262 C 39 270 29 273 -12 274",
	"M 145 152 C 146 160 145.6 166 144.4 172",
]
const LINK := 5.4
const CHAIN_FROM := Vector2(-12, 274)
## His eyes in the dark of his face, and the glow round them.
const EYES: Array[Vector2] = [Vector2(73.4, 38), Vector2(80.6, 37.4)]
const EYE_TILT: Array[float] = [0.22, -0.14]
## The lantern on its short chain, drawn round LANTERN_MIDDLE: the ring and
## the cap, the cage's frame, its bars (x), the bottom; the souls caged in
## its light (offset, size).
const LANTERN_TOP := Vector2(21, 109)
const CAP := "M 11.6 121.4 L 21 113.4 L 30.4 121.4 Z"
const CAP_BAND := "M 10.6 120.8 L 31.4 120.8 L 31.4 124.8 L 10.6 124.8 Z"
const CAGE := "M 13.4 124.8 L 28.6 124.8 L 32.4 138 L 28.6 151.4 L 13.4 151.4 L 9.6 138 Z"
const BARS: Array[float] = [15.4, 21.0, 26.6]
const BASE_BAND := "M 11.6 151 L 30.4 151 L 30.4 155 L 11.6 155 Z"
const BASE := "M 14 155 L 28 155 L 25 159.6 L 21 165 L 17 159.6 Z"
const SOULS: Array[Vector3] = [Vector3(-4.4, -6, 2.1), Vector3(3.6, 1.4, 1.8), Vector3(-1.6, 7.2, 1.6), Vector3(4.4, -7.4, 1.3)]


func _init() -> void:
	super(BOX)
	fold_dark = FOLD_DARK
	fold_light = FOLD_LIGHT
	moon_way = MOON_WAY.normalized()
	rim_width = 0.8
	lantern_at = LANTERN_MIDDLE
	lantern_reach = LANTERN_REACH
	lantern_width = 1.0


## Where his lantern's light is, in the parent's coordinates.
func lantern() -> Vector2:
	return at(LANTERN_MIDDLE)


## Where his chain leaves him on the ground, in the parent's coordinates.
func chain_end() -> Vector2:
	return at(CHAIN_FROM)


## Where his eyes are, in the parent's coordinates.
func eyes() -> PackedVector2Array:
	return PackedVector2Array([at(EYES[0]), at(EYES[1])])


func _paint(paint: TitlePaint) -> void:
	paint.glow(LANTERN_MIDDLE, Vector2(46, 46), Color(SOUL, 0.18))
	_part(paint, TitlePaint.outline(FAR_ARM), ROBE)
	paint.chain(TitlePaint.outline(CHAINS[4]), LINK, 1.2, CHAIN, CHAIN_EDGE)
	paint.ring(SICKLE_RING, Vector2(2.6, 2.6), 1.4, IRON.lightened(0.15))
	_part(paint, TitlePaint.outline(SICKLE_HAFT), IRON)
	var sickle := TitlePaint.outline(SICKLE)
	_part(paint, sickle, IRON.lightened(0.08))
	paint.rim(sickle, Vector2(0.0, -1.2), Color(MOON_RIM_TOP, 0.7))
	paint.rim(sickle, Vector2(-1.0, 0.8), Color(SOUL, 0.5))
	_part(paint, TitlePaint.outline(FAR_HAND), CLAW)
	_paint_robe(paint)
	_paint_chest(paint)
	for spike in FAR_SPIKES:
		_spike(paint, TitlePaint.outline(spike))
	_part(paint, TitlePaint.outline(FAR_PAULDRON), IRON)
	for k in 4:
		paint.chain(TitlePaint.outline(CHAINS[k]), LINK, 1.2, CHAIN, CHAIN_EDGE)
	_paint_hood(paint)
	_part(paint, TitlePaint.outline(SLEEVE), ROBE)
	_part(paint, TitlePaint.outline(ARM), ROBE)
	_fold(paint, "M 60 80 Q 54 90 46 96", FOLD_WIDTH * 0.6)
	_paint_pauldron(paint)
	_part(paint, TitlePaint.outline(HAND), CLAW)
	_paint_lantern(paint)


## The long robe: shaded and rimmed, its folds, the lantern's green on its
## lower front, and dark towards its tattered hem.
func _paint_robe(paint: TitlePaint) -> void:
	var robe := TitlePaint.outline(ROBE_SHAPE)
	_part(paint, robe, ROBE)
	for fold in ROBE_FOLDS:
		_fold(paint, fold, FOLD_WIDTH)
	paint.glow_in(robe, LANTERN_MIDDLE, 95.0, Color(SOUL, 0.26))
	paint.shape(robe, TitlePaint.linear(Vector2(0, 200), Vector2(0, 278), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.5)))


## The chest: dark, the souls' green glowing inside it, the ribs over it
## with the moon along their tops.
func _paint_chest(paint: TitlePaint) -> void:
	var torso := TitlePaint.outline(TORSO)
	_part(paint, torso, ROBE)
	paint.glow_in(torso, Vector2(86, 96), 34.0, Color(SOUL, 0.85))
	for rib in RIBS:
		var line := TitlePaint.outline(rib)
		paint.taper(line, RIB_WIDTH.x + 1.4, RIB_WIDTH.y + 1.4, Color(0.0, 0.01, 0.0, 0.85))
		paint.taper(line, RIB_WIDTH.x, RIB_WIDTH.y, TitlePaint.linear(line[0], line[-1], IRON.darkened(0.4), IRON.lerp(lit_tint, 0.12)))
		paint.taper(TitlePaint.moved(line, Vector2(0.0, -RIB_WIDTH.y * 0.4)), 0.0, RIB_WIDTH.y * 0.3, Color(MOON_RIM_TOP, 0.4))
	paint.taper(TitlePaint.outline("M 68.6 76 C 72 92 76 108 80 124"), 3.4, 2.0, IRON)


## The hood: shaded and rimmed with its folds, the dark of his face, the
## green glow in it and his burning eyes.
func _paint_hood(paint: TitlePaint) -> void:
	var hood := TitlePaint.outline(HOOD)
	_part(paint, hood, ROBE)
	for fold in HOOD_FOLDS:
		_fold(paint, fold, FOLD_WIDTH * 0.7)
	var face := TitlePaint.outline(FACE)
	paint.shape(face, FACE_DARK)
	paint.glow_in(face, Vector2(76, 44), 16.0, Color(SOUL, 0.3))
	paint.rim(face, Vector2(1.4, 0.0), Color(0, 0, 0, 0.6))
	for k in EYES.size():
		paint.glow(EYES[k], Vector2(6.4, 5), Color(SOUL, 0.7))
		paint.oval(EYES[k], Vector2(2.4, 1.1), EYE, EYE_TILT[k])
	# A faint grin of teeth under them.
	for k in 6:
		var x := 71.6 + k * 1.6
		paint.line(Vector2(x, 48.6 + absf(k - 2.5) * 0.3), Vector2(x, 50.6 + absf(k - 2.5) * 0.3), 0.7, Color(SOUL, 0.35))


## The near pauldron and its spikes.
func _paint_pauldron(paint: TitlePaint) -> void:
	for spike in SPIKES:
		_spike(paint, TitlePaint.outline(spike))
	var pauldron := TitlePaint.outline(PAULDRON)
	_part(paint, pauldron, IRON)
	for lame in PAULDRON_LAMES:
		var line := TitlePaint.outline(lame)
		paint.taper(line, 1.2, 1.2, Color(0, 0, 0, 0.65))
		paint.taper(TitlePaint.moved(line, Vector2(0, -1.0)), 0.6, 0.6, Color(MOON_RIM_TOP, 0.25))


## The lantern on its short chain: its light round it, the iron cap and
## cage, the green inside with the souls caged in it, the bars over them.
func _paint_lantern(paint: TitlePaint) -> void:
	paint.chain(PackedVector2Array([Vector2(24, 104), LANTERN_TOP]), 4.0, 1.0, CHAIN, CHAIN_EDGE)
	paint.ring(LANTERN_TOP + Vector2(0, 2), Vector2(2.4, 2.4), 1.2, IRON.lightened(0.2))
	paint.glow(LANTERN_MIDDLE, Vector2(30, 30), Color(SOUL, 0.35))
	_part(paint, TitlePaint.outline(CAP), IRON)
	_part(paint, TitlePaint.outline(CAP_BAND), IRON.lightened(0.1))
	var cage := TitlePaint.outline(CAGE)
	paint.shape(cage, Color("1b4a33"))
	paint.glow_in(cage, LANTERN_MIDDLE, 16.0, Color("c9ffe0"))
	paint.fill("M 21 129 Q 25.4 137 21 146.6 Q 16.6 137 21 129 Z", Color(EYE, 0.85))
	for soul in SOULS:
		var spot := LANTERN_MIDDLE + Vector2(soul.x, soul.y)
		paint.glow(spot, Vector2.ONE * soul.z * 2.6, Color(EYE, 0.6))
		paint.oval(spot, Vector2.ONE * soul.z * 0.6, EYE)
	for x in BARS:
		paint.line(Vector2(x, 124.8), Vector2(x + (x - 21.0) * 0.1, 151.4), 1.3, IRON.darkened(0.3))
	paint.line(Vector2(9.8, 138), Vector2(32.2, 138), 1.0, IRON.darkened(0.3))
	paint.rim(cage, Vector2(-0.8, -0.4), Color(MOON_RIM_TOP, 0.4))
	_part(paint, TitlePaint.outline(BASE_BAND), IRON.lightened(0.1))
	_part(paint, TitlePaint.outline(BASE), IRON)


## A spike of his armour, from its outline (two corners at its root, then
## its tip): a cone, lit along its moon side and dark on the other, rimmed.
func _spike(paint: TitlePaint, outline: PackedVector2Array) -> void:
	var root := (outline[0] + outline[2]) * 0.5
	var tip := outline[1]
	var lit := outline[0] if (outline[0] - root).dot(moon_way) > 0.0 else outline[2]
	var dark := outline[2] if lit == outline[0] else outline[0]
	paint.shape(PackedVector2Array([lit, tip, root]), IRON.lerp(lit_tint, 0.18))
	paint.shape(PackedVector2Array([root, tip, dark]), IRON.darkened(0.6))
	_rims(paint, outline)

class_name TitleThresh
extends TitleFigure
## Thresh, the Chain Warden, looming at the right and facing left towards
## Lucian and Senna. Sinuous burning emerald soul-flame dreadlocks drift back
## from a gaunt shadowed skull framed inside a towering torn dark-iron cowl;
## broad hunched iron pauldrons with integrated curved bone-iron hooks flank
## a hollowed ribcage blazing with trapped soulfire. His armored near gauntlet
## suspends an ornate octagonal lantern while his far hand drags a wickedly
## curved Death Sentence scythe on heavy linked chains.

## The art's frame, in units.
const BOX := Rect2(-12, -8, 176, 286)
## Towards the moon and the moonlit rim's width; his lantern (its middle),
## how far its light reaches and how wide its rim on him is.
const MOON_WAY := Vector2(-0.85, -0.53)
const RIM_WIDTH := 0.85
const LANTERN_MIDDLE := Vector2(21, 141)
const LANTERN_REACH := 125.0
const LANTERN_WIDTH := 1.05

## His colours: shadow-cloth robe, forged dark-iron armour, abyssal skull
## shadow, gaunt spectral bone, heavy chains, blazing eyes & emerald soulfire.
const ROBE := Color("0a1310")
const IRON := Color("1a2622")
const IRON_BRIGHT := Color("2a3c35")
const SKULL_DARK := Color("020504")
const SKULL_BONE := Color("192d25")
const CLAW := Color("3b4f46")
const CHAIN := Color("4b6b59")
const CHAIN_EDGE := Color(0.01, 0.02, 0.015, 0.95)
const EYE := Color("ecfff4")
const SOUL := Color("8fe3b0")
const SOUL_DEEP := Color("196846")
const SOUL_BRIGHT := Color("caffdf")

const RIB_EDGE := Color(0.0, 0.01, 0.0, 0.9)
const SEAM := Color(0.0, 0.0, 0.0, 0.74)
const HEM_SHADE := Color(0.0, 0.0, 0.0, 0.58)
const FOLD_DARK := Color(0.0, 0.0, 0.0, 0.64)
const FOLD_LIGHT := Color(0.7, 0.88, 0.95, 0.2)
const FOLD_WIDTH := 4.0

## Towering tattered cape, shadow-cloth coat & organic billowing hem tendrils.
const CAPE := "M 106 56 C 127 52 142 61 149 76 C 156 104 161 146 162 188 C 163 218 160 246 157 272 C 152 260 148 252 144 268 C 139 252 135 244 130 264 C 127 232 124 188 120 146 C 116 112 111 84 106 56 Z"
const ROBE_SHAPE := "M 79 118 L 121 116 C 128 150 137 190 145 228 C 149 246 153 262 155 276 C 148 265 143 255 138 273 C 132 258 127 250 120 275 C 113 260 107 248 100 274 C 93 258 87 250 79 273 C 72 256 65 248 55 268 C 49 252 44 246 34 261 C 30 248 26 244 16 254 C 35 234 51 210 61 186 C 69 164 75 142 79 118 Z"
const TABARD := "M 85 126 L 113 124 C 114 158 113 196 110 228 C 106 240 102 232 98 246 C 94 232 90 228 87 239 C 85.5 204 85 162 85 126 Z"
const TABARD_COLOR := Color("101c17")
const TASSET_LEFT := "M 73 122 L 89 124 L 85 154 L 67 146 Z"
const TASSET_RIGHT := "M 109 123 L 125 119 L 129 148 L 111 153 Z"

## Far arm & massive wickedly curved Death Sentence Scythe kept cleanly in-frame.
const FAR_ARM := "M 114 66 L 137 64 C 141 92 144 118 145 144 L 133 146 C 128 120 121 92 114 66 Z"
const FAR_VAMBRACE := "M 129 122 L 144 120 L 146 147 L 131 149 Z"
const FAR_HAND := "M 131 144 L 144 143 L 146 153 L 142 160 L 138 154 L 135 161 L 131 154 Z"
const SICKLE_CHAIN := "M 138 155 C 138.5 163 137.5 169 136 175"
const SICKLE_RING := Vector2(135.5, 177.5)
const SICKLE_HAFT := "M 132.5 180 L 138.5 180 L 137.5 206 L 130.5 204 Z"
const SICKLE_COUNTER := "M 125 184 L 137 181 L 137 190 L 127 191 Z"
const SICKLE_BLADE := "M 134 183 C 151 179 160 195 158 219 C 156 236 147 248 135 256 C 143 243 147 230 146 218 L 139 213 L 145 205 C 144 198 140 194 132 194 Z"
const SICKLE_EDGE := "M 136 185 C 150 182 158 196 156 218 C 154 234 146 245 137 253"

## Broad hollowed spectral ribcage blazing fiercely from within.
const TORSO := "M 61 68 C 88 62 114 59 137 62 C 134 89 126 110 117 130 L 81 133 C 74 111 67 90 61 68 Z"
const RIBS: Array[String] = [
	"M 115 69 C 101 68 85 72 70 83",
	"M 114 78 C 100 77.5 85 82 72 93",
	"M 112 87.5 C 99 88 86 92.5 75 103",
	"M 109 97 C 97 98 87 102 78 112",
	"M 105 106.5 C 95 108 88 111 81 119.5",
	"M 100 115.5 C 93 117 88 119.5 83.5 126",
]
const RIB_WIDTH := Vector2(1.6, 3.8)

## Towering torn high-collared dark-iron cowl (NOT a pointy witch hat!)
## sweeping up behind his hunched neck and framing his burning skull.
const COWL_BACK := "M 60 66 C 58 50 61 32 70 20 C 79 12 95 10 109 18 C 117 28 118 45 113 62 L 94 70 Z"
const COWL_COLLAR_LEFT := "M 53 66 C 54 50 56 38 61 30 L 67 39 L 66 64 Z"
const COWL_COLLAR_RIGHT := "M 92 66 L 103 28 C 110 34 115 46 111 66 Z"

## Flowing, sinuous emerald soul-flame dreadlocks drifting UP & BACK in the wind
## (organic ghostly underwater fire — NOT stiff radial pineapple spikes!).
const FLAME_TENDRILS: Array[String] = [
	"M 69 24 C 66 13 71 4 82 -3 C 89 -6 96 -5 102 -2",
	"M 76 23 C 78 12 86 4 98 0 C 107 -2 115 0 122 4",
	"M 82 26 C 88 17 98 11 112 10 C 121 10 128 13 134 18",
	"M 84 32 C 94 25 106 22 119 24 C 127 25 133 29 138 34",
	"M 65 27 C 60 18 62 9 69 3 C 75 -1 81 -2 88 -1",
	"M 85 38 C 96 34 107 34 118 38 C 125 41 130 45 134 50",
]
const FLAME_TENDRIL_WIDTHS: Array[Vector2] = [
	Vector2(6.5, 0.8),
	Vector2(7.0, 0.8),
	Vector2(6.2, 0.7),
	Vector2(5.4, 0.6),
	Vector2(4.8, 0.6),
	Vector2(4.5, 0.5),
]

## Gaunt 3/4-profile shadowed spectral skull emerging from abyssal cowl dark:
## deep overhanging brow, hollow sunken sockets, gaunt cheekbones & fierce jaw.
const FACE_VOID := "M 61 33 C 62 22 70 17 81 18 C 90 21 94 31 92 44 C 89 54 82 61 73 61 C 65 60 60 51 61 33 Z"
const SKULL_CRANIUM := "M 62 32 C 63 23 69 19 77 20 C 83 21 87 27 86.5 34 L 74 35.5 L 62.5 33.5 Z"
const SKULL_BROW := "M 61.5 32.5 L 72.5 35.2 L 85.5 31.8 L 84.5 28.6 L 72.5 31.4 L 62.8 29.0 Z"
const SKULL_CHEEK_L := "M 62 38.5 L 67.5 41.2 L 66 47.5 L 61.5 44 Z"
const SKULL_CHEEK_R := "M 85.5 37.5 L 78.5 41.0 L 80.5 47.5 L 86 43.0 Z"
const SKULL_NOSE := "M 70.5 39.5 L 72.5 44.5 L 69.2 44.8 Z"
const SKULL_JAW := "M 64.5 48.5 L 68.5 52.0 L 73.5 52.8 L 78.5 51.5 L 81.5 47.8 L 80 56.8 L 73.5 59.0 L 66.8 56.5 Z"
const EYES: Array[Vector2] = [Vector2(67.8, 36.6), Vector2(76.6, 35.8)]
const EYE_TILT: Array[float] = [0.30, -0.24]

## Heavy hunched dark-iron pauldrons with compact curved bone-iron hooks
## integrated seamlessly along the upper armor silhouette.
const FAR_PAULDRON := "M 104 58 C 115 48 132 50 142 60 C 146 69 143 80 135 85 L 106 80 Z"
const FAR_HOOKS: Array[String] = [
	"M 116 55 C 122 45 128 39 135 37 C 131 44 129 50 128 57 Z",
	"M 129 58 C 138 52 146 49 153 50 C 145 56 141 61 137 67 Z",
]
const FAR_LAMES: Array[String] = ["M 107 69 C 118 62 131 62 142 69", "M 111 60 C 120 55 131 55 140 60"]

const PAULDRON := "M 44 78 C 47 61 60 50 76 50 L 92 56 L 88 79 C 74 85 57 85 44 78 Z"
const NEAR_HOOKS: Array[String] = [
	"M 50 67 C 41 61 35 55 32 49 C 41 52 48 56 56 61 Z",
	"M 58 58 C 53 49 51 42 52 36 C 58 43 63 49 68 55 Z",
	"M 69 54 C 69 46 71 41 75 37 C 76 43 77 49 79 54 Z",
]
const PAULDRON_LAMES: Array[String] = ["M 46 72 C 56 62 71 60 90 66", "M 53 62 C 62 56 74 55 91 60"]

## Powerful draped near arm, smoothly curved forged-iron forearm armor & claws.
const NEAR_SLEEVE_DRAPE := "M 64 74 C 55 88 46 98 37 104 L 39 124 L 46 112 L 51 130 L 57 114 L 64 123 L 66 104 C 69 96 71 88 73 79 Z"
const NEAR_UPPER_ARM := "M 58 69 C 52 80 45 90 39 95 L 51 104 C 59 96 66 86 71 77 Z"
const NEAR_VAMBRACE := "M 49 91 C 42 93 34 95 26 96 L 26 107 C 34 107.5 43 106.5 51 103 C 54 100 54 95 49 91 Z"
const NEAR_ELBOW_HOOK := "M 46 97 C 52 103 55 109 53 114 C 48 109 44 105 41 102 Z"
const NEAR_HAND := "M 28.5 96 L 19.5 96.5 L 13.0 101.2 L 19.0 102.2 L 13.8 107.4 L 20.5 106.4 L 18.6 112.8 L 24.5 108.0 L 29.8 107.5 Z"

## Ornate octagonal iron Lantern cage & swirling soulfire core.
const LANTERN_HOOK := Vector2(21.5, 106.5)
const LANTERN_TOP := Vector2(21.0, 114.0)
const LANTERN_CROWN := "M 18 118 L 21 109 L 24 118 Z"
const CAP := "M 8.5 124.5 L 14 120 L 21 115 L 28 120 L 33.5 124.5 Z"
const CAP_BAND := "M 7.0 123.5 L 35.0 123.5 L 34.0 127.8 L 8.0 127.8 Z"
const CAGE := "M 11.5 127.8 L 30.5 127.8 L 35.2 141.0 L 30.5 154.5 L 11.5 154.5 L 6.8 141.0 Z"
const GLASS := Color("164830")
const GLASS_LIGHT := Color("caffdf")
const FLAME_OUTER := "M 21 130 C 26.5 135 28 144 21 151 C 14 144 15.5 135 21 130 Z"
const FLAME_INNER := "M 21 133.5 C 24 138 24.5 144 21 148.5 C 17.5 144 18 138 21 133.5 Z"
const BARS: Array[float] = [14.6, 21.0, 27.4]
const BASE_BAND := "M 9.0 154.0 L 33.0 154.0 L 31.8 158.2 L 10.2 158.2 Z"
const BASE := "M 12.5 158.2 L 29.5 158.2 L 25.5 164.0 L 21.0 171.0 L 16.5 164.0 Z"
const SOULS: Array[Vector3] = [
	Vector3(-5.5, -5.5, 2.2),
	Vector3(4.8, 1.8, 1.9),
	Vector3(-2.4, 7.6, 1.7),
	Vector3(5.2, -7.2, 1.4),
	Vector3(-6.2, 3.2, 1.3),
]

## Heavy forged chains wrapped tightly across ribcage, waist & trailing to ground.
const CHAINS: Array[String] = [
	"M 66 76 C 86 92 104 104 123 116",
	"M 74 106 C 92 98 110 88 127 76",
	"M 79 124 C 95 131 110 129 121 122",
	"M 43 105 C 48 124 64 134 80 125",
	"M 80 126 C 68 162 56 214 42 262 C 38 270 28 273 -12 274",
]
const LINK := 5.6
const CHAIN_FROM := Vector2(-12, 274)

## Robe and cape folds.
const ROBE_FOLDS: Array[String] = [
	"M 92 132 C 89 172 83 212 75 256",
	"M 106 130 C 111 172 117 214 121 258",
	"M 83 140 C 76 180 64 220 50 256",
	"M 118 132 C 125 170 135 214 142 262",
]
const CAPE_FOLDS: Array[String] = [
	"M 139 76 C 149 120 154 180 154 252",
	"M 127 92 C 135 140 140 200 142 256",
]


func _init() -> void:
	super(BOX)
	fold_dark = FOLD_DARK
	fold_light = FOLD_LIGHT
	moon_way = MOON_WAY.normalized()
	rim_width = RIM_WIDTH
	lantern_at = LANTERN_MIDDLE
	lantern_reach = LANTERN_REACH
	lantern_width = LANTERN_WIDTH


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
	paint.glow(LANTERN_MIDDLE, Vector2(54, 54), Color(SOUL, 0.2))
	_part(paint, TitlePaint.outline(CAPE), ROBE.darkened(0.25))
	for fold in CAPE_FOLDS:
		_fold(paint, fold, FOLD_WIDTH)
	_paint_far_arm_and_scythe(paint)
	_paint_robe(paint)
	_paint_chest(paint)
	for hook in FAR_HOOKS:
		_curved_hook(paint, TitlePaint.outline(hook))
	_part(paint, TitlePaint.outline(FAR_PAULDRON), IRON)
	_lames(paint, FAR_LAMES)
	for chain in CHAINS:
		paint.chain(TitlePaint.outline(chain), LINK, 1.3, CHAIN, CHAIN_EDGE)
	_paint_head(paint)
	_paint_near_arm(paint)
	_paint_pauldron(paint)
	_paint_lantern(paint)


func _paint_far_arm_and_scythe(paint: TitlePaint) -> void:
	_part(paint, TitlePaint.outline(FAR_ARM), ROBE)
	_fold(paint, "M 124 80 Q 133 104 138 128", FOLD_WIDTH * 0.7)
	_part(paint, TitlePaint.outline(FAR_VAMBRACE), IRON)
	paint.chain(TitlePaint.outline(SICKLE_CHAIN), LINK, 1.3, CHAIN, CHAIN_EDGE)
	paint.ring(SICKLE_RING, Vector2(3.0, 3.0), 1.5, IRON_BRIGHT)
	_part(paint, TitlePaint.outline(SICKLE_COUNTER), IRON)
	_part(paint, TitlePaint.outline(SICKLE_HAFT), IRON)
	var blade := TitlePaint.outline(SICKLE_BLADE)
	_part(paint, blade, IRON_BRIGHT)
	paint.rim(blade, Vector2(0.0, -1.4), Color(MOON_RIM_TOP, 0.75))
	paint.rim(blade, Vector2(-1.4, 0.8), Color(SOUL, 0.55))
	paint.taper(TitlePaint.outline(SICKLE_EDGE), 1.6, 0.4, Color(SOUL_BRIGHT, 0.55))
	_part(paint, TitlePaint.outline(FAR_HAND), CLAW)


func _paint_robe(paint: TitlePaint) -> void:
	var robe := TitlePaint.outline(ROBE_SHAPE)
	_part(paint, robe, ROBE)
	for fold in ROBE_FOLDS:
		_fold(paint, fold, FOLD_WIDTH)
	paint.glow_in(robe, LANTERN_MIDDLE, 105.0, Color(SOUL, 0.28))
	var tabard := TitlePaint.outline(TABARD)
	_part(paint, tabard, TABARD_COLOR)
	_fold(paint, "M 99 132 C 99.5 170 98.5 200 97.5 234", FOLD_WIDTH * 0.6)
	paint.stroke("M 88 130 L 89 232", 0.9, Color(IRON_BRIGHT, 0.55))
	paint.stroke("M 110 128 L 109 226", 0.9, Color(IRON_BRIGHT, 0.55))
	_part(paint, TitlePaint.outline(TASSET_LEFT), IRON)
	_part(paint, TitlePaint.outline(TASSET_RIGHT), IRON)
	paint.shape(robe, TitlePaint.linear(Vector2(0, 200), Vector2(0, 278), Color(HEM_SHADE, 0.0), HEM_SHADE))


func _paint_chest(paint: TitlePaint) -> void:
	var torso := TitlePaint.outline(TORSO)
	_part(paint, torso, ROBE.darkened(0.35))
	paint.glow_in(torso, Vector2(91, 96), 42.0, Color(SOUL_DEEP, 0.95))
	paint.glow_in(torso, Vector2(89, 95), 28.0, Color(SOUL, 0.92))
	paint.glow_in(torso, Vector2(88, 94), 14.0, Color(SOUL_BRIGHT, 0.72))
	paint.taper(TitlePaint.outline("M 82 112 C 88 100 96 90 92 78"), 2.4, 0.6, Color(SOUL_BRIGHT, 0.45))
	paint.taper(TitlePaint.outline("M 98 114 C 94 102 86 92 84 78"), 2.0, 0.5, Color(SOUL, 0.45))
	for rib in RIBS:
		var line := TitlePaint.outline(rib)
		paint.taper(line, RIB_WIDTH.x + 1.6, RIB_WIDTH.x + 1.6, RIB_EDGE, RIB_WIDTH.y)
		paint.taper(line, RIB_WIDTH.x, RIB_WIDTH.x, TitlePaint.linear(line[0], line[-1], IRON.darkened(0.45), IRON.lerp(lit_tint, 0.2)), RIB_WIDTH.y)
		paint.taper(TitlePaint.moved(line, Vector2(0.0, -RIB_WIDTH.y * 0.36)), 0.0, 0.0, Color(MOON_RIM_TOP, 0.45), RIB_WIDTH.y * 0.28)
		paint.taper(TitlePaint.moved(line, Vector2(0.0, RIB_WIDTH.y * 0.34)), 0.0, 0.0, Color(SOUL, 0.38), RIB_WIDTH.y * 0.25)
	paint.taper(TitlePaint.outline("M 68 74 C 72 91 77 108 82 126"), 4.2, 2.2, IRON_BRIGHT)


## Towering torn dark-iron cowl, flowing spectral emerald flame-dreadlocks
## sweeping back in the wind, abyssal face shadow, gaunt skull & burning eyes.
func _paint_head(paint: TitlePaint) -> void:
	# Soft drifting soulfire aura behind his skull crown.
	paint.glow(Vector2(92, 16), Vector2(44, 28), Color(SOUL_DEEP, 0.4))
	paint.glow(Vector2(82, 22), Vector2(26, 20), Color(SOUL, 0.48))

	# Torn high-collared dark-iron cowl rising behind his hunched shoulders.
	_part(paint, TitlePaint.outline(COWL_BACK), ROBE)

	# Sinuous flowing emerald flame-dreadlocks sweeping back like spectral fire.
	for i in FLAME_TENDRILS.size():
		var track := TitlePaint.outline(FLAME_TENDRILS[i])
		var w := FLAME_TENDRIL_WIDTHS[i]
		paint.taper(track, w.x * 1.45, w.y, TitlePaint.linear(track[0], track[-1], Color(SOUL_DEEP, 0.85), Color(SOUL_DEEP, 0.0)))
		paint.taper(track, w.x, w.y * 0.6, TitlePaint.linear(track[0], track[-1], Color(SOUL, 0.9), Color(SOUL, 0.08)))
		paint.taper(TitlePaint.moved(track, Vector2(-0.6, -0.8)), w.x * 0.36, 0.0, TitlePaint.linear(track[0], track[-1], Color(SOUL_BRIGHT, 0.85), Color(SOUL_BRIGHT, 0.0)))

	_part(paint, TitlePaint.outline(COWL_COLLAR_LEFT), IRON)
	_part(paint, TitlePaint.outline(COWL_COLLAR_RIGHT), IRON)

	# Deep abyssal void inside the cowl so his gaunt skull emerges from darkness.
	var void_poly := TitlePaint.outline(FACE_VOID)
	paint.shape(void_poly, SKULL_DARK)
	paint.glow_in(void_poly, Vector2(73, 46), 16.0, Color(SOUL_DEEP, 0.72))
	paint.glow_in(void_poly, Vector2(73, 48), 9.0, Color(SOUL, 0.42))

	# Gaunt sculpted dark spectral skull planes (no round mask, no smiley teeth).
	var cranium := TitlePaint.outline(SKULL_CRANIUM)
	paint.shape(cranium, TitlePaint.linear(Vector2(62, 22), Vector2(86, 34), SKULL_BONE.lightened(0.18), SKULL_DARK))
	paint.rim(cranium, Vector2(-0.9, -1.0), Color(SOUL, 0.55))

	var brow := TitlePaint.outline(SKULL_BROW)
	paint.shape(brow, IRON.darkened(0.2))
	paint.rim(brow, Vector2(-0.7, -0.9), Color(SOUL_BRIGHT, 0.52))

	paint.shape(TitlePaint.outline(SKULL_CHEEK_L), SKULL_BONE.lightened(0.16))
	paint.rim(TitlePaint.outline(SKULL_CHEEK_L), Vector2(-0.7, 0.3), Color(SOUL, 0.45))
	paint.shape(TitlePaint.outline(SKULL_CHEEK_R), SKULL_BONE.darkened(0.25))
	paint.shape(TitlePaint.outline(SKULL_NOSE), SKULL_DARK)

	var jaw := TitlePaint.outline(SKULL_JAW)
	paint.shape(jaw, TitlePaint.linear(Vector2(65, 50), Vector2(82, 56), SKULL_BONE.lightened(0.1), SKULL_DARK))
	paint.rim(jaw, Vector2(-0.8, 0.7), Color(SOUL, 0.48))

	# Fierce sunken glowing emerald eye slits.
	for k in EYES.size():
		paint.glow(EYES[k], Vector2(7.8, 5.2), Color(SOUL, 0.8))
		paint.oval(EYES[k], Vector2(2.8, 1.05), EYE, EYE_TILT[k])


func _paint_near_arm(paint: TitlePaint) -> void:
	_part(paint, TitlePaint.outline(NEAR_SLEEVE_DRAPE), ROBE)
	_part(paint, TitlePaint.outline(NEAR_UPPER_ARM), ROBE.lightened(0.05))
	_fold(paint, "M 57 78 Q 51 89 44 96", FOLD_WIDTH * 0.6)
	_part(paint, TitlePaint.outline(NEAR_ELBOW_HOOK), IRON)
	var vambrace := TitlePaint.outline(NEAR_VAMBRACE)
	_part(paint, vambrace, IRON)
	paint.stroke("M 35 95 C 36 99 36 103 35 107", 1.1, SEAM)
	paint.stroke("M 43 93 C 44 98 44 102 43 105.5", 1.1, SEAM)
	paint.line(Vector2(27.5, 96.2), Vector2(27.5, 107.0), 1.3, IRON_BRIGHT)
	_part(paint, TitlePaint.outline(NEAR_HAND), CLAW)


func _paint_pauldron(paint: TitlePaint) -> void:
	for hook in NEAR_HOOKS:
		_curved_hook(paint, TitlePaint.outline(hook))
	var pauldron := TitlePaint.outline(PAULDRON)
	_part(paint, pauldron, IRON)
	_lames(paint, PAULDRON_LAMES)


func _lames(paint: TitlePaint, lames: Array[String]) -> void:
	for lame in lames:
		var line := TitlePaint.outline(lame)
		paint.taper(line, 1.3, 1.3, SEAM)
		paint.taper(TitlePaint.moved(line, Vector2(0, -1.0)), 0.7, 0.7, Color(MOON_RIM_TOP, 0.28))


func _curved_hook(paint: TitlePaint, outline: PackedVector2Array) -> void:
	_part(paint, outline, IRON_BRIGHT)
	paint.rim(outline, moon_way * 1.1, Color(MOON_RIM_TOP, 0.55))


func _paint_lantern(paint: TitlePaint) -> void:
	paint.chain(PackedVector2Array([LANTERN_HOOK, LANTERN_TOP]), 4.2, 1.1, CHAIN, CHAIN_EDGE)
	paint.ring(LANTERN_TOP + Vector2(0, 1.8), Vector2(2.8, 2.8), 1.3, IRON_BRIGHT)
	paint.glow(LANTERN_MIDDLE, Vector2(38, 38), Color(SOUL, 0.42))
	_part(paint, TitlePaint.outline(LANTERN_CROWN), IRON)
	_part(paint, TitlePaint.outline(CAP), IRON)
	_part(paint, TitlePaint.outline(CAP_BAND), IRON_BRIGHT)
	paint.taper(TitlePaint.outline("M 8 125 Q 4 123 3.5 119"), 1.6, 0.4, IRON_BRIGHT)
	paint.taper(TitlePaint.outline("M 34 125 Q 38 123 38.5 119"), 1.6, 0.4, IRON_BRIGHT)

	var cage := TitlePaint.outline(CAGE)
	paint.shape(cage, GLASS)
	paint.glow_in(cage, LANTERN_MIDDLE, 19.0, GLASS_LIGHT)
	paint.fill(FLAME_OUTER, Color(SOUL, 0.78))
	paint.fill(FLAME_INNER, Color(EYE, 0.92))
	paint.taper(TitlePaint.outline("M 13 148 C 16 141 25 138 28 132"), 1.6, 0.4, Color(EYE, 0.65))
	paint.taper(TitlePaint.outline("M 29 149 C 24 143 17 139 14 132"), 1.4, 0.4, Color(SOUL_BRIGHT, 0.55))
	for soul in SOULS:
		var spot := LANTERN_MIDDLE + Vector2(soul.x, soul.y)
		paint.glow(spot, Vector2.ONE * soul.z * 2.8, Color(EYE, 0.62))
		paint.oval(spot, Vector2.ONE * soul.z * 0.6, EYE)

	for x in BARS:
		paint.line(Vector2(x, 127.8), Vector2(x + (x - 21.0) * 0.12, 154.5), 1.5, IRON.darkened(0.32))
		paint.line(Vector2(x - 0.5, 127.8), Vector2(x - 0.5 + (x - 21.0) * 0.12, 154.5), 0.45, Color(SOUL_BRIGHT, 0.35))
	paint.line(Vector2(7.0, 141.0), Vector2(35.0, 141.0), 1.2, IRON.darkened(0.3))
	paint.rim(cage, Vector2(-1.0, -0.5), Color(MOON_RIM_TOP, 0.45))

	_part(paint, TitlePaint.outline(BASE_BAND), IRON_BRIGHT)
	_part(paint, TitlePaint.outline(BASE), IRON)

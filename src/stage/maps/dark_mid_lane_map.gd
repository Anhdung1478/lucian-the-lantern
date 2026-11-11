class_name DarkMidLaneMap
extends MidLaneMap
## Act 4: Act 1's lane in the dark. The same layout and points, a black and
## violet palette. Dark Lucian rises from the river at `boss_point`.
## The lane is a cool grey, a few steps lighter than the shadow minions and
## Dark Lucian, so they stand out on it; the violet is kept for the jungle's
## edge, the river's depths and a few wisps of light over the trees, whose
## glow spills a little onto the lane's edge.

## The wisps: this far apart along each edge of the lane (a step each way),
## this far back over the trees; their glow on the ground and the trees,
## their halo and their pale heart; the motes that dance in each, this far
## round it.
const WISP_STEP := Vector2(620, 940)
const WISP_BACK := Vector2(30, 90)
const WISP_POOL := 330.0
const WISP_HALO := 70.0
const WISP_HEART := 16.0
const WISP_MOTES := 4
const WISP_SPREAD := 40.0
const WISP_COLOR := Color("b48cff")
## A violet haze over the lane in large soft patches (how many, their
## radius range, how strong).
const HAZE_PATCHES := 16
const HAZE_RADIUS := Vector2(380, 760)
const HAZE_ALPHA := 0.09


func _init() -> void:
	super()
	lane_color = Color("434051")
	jungle_color = Color("130f1a")
	jungle_edge = Color("4a3670")
	tree_color = Color("0a0810")
	leaf_light = Color("54447f")
	river_color = Color("2a2748")
	river_edge = Color("6c62a8")
	rock_color = Color("524e64")
	firefly_color = Color("c9a8ff")
	flower_color = Color("a993d6")
	depths_color = Color("8f5cff")
	vignette_alpha = 0.62


## Act 1's fireflies in violet, and a few motes dancing in each wisp.
func build_ambience() -> MapAmbience:
	var ambience := super()
	var dice := MapArt.rng(37)
	for at in _wisps():
		var round_it := MapArt.scatter(dice, Rect2(at - Vector2.ONE * WISP_SPREAD, Vector2.ONE * WISP_SPREAD * 2.0), WISP_MOTES)
		ambience.add(MapAmbience.Kind.FIREFLY, round_it, Color(WISP_COLOR.lightened(0.4), 0.9), dice)
	return ambience


## Over the finished map: the haze, then the wisps, each a soft pool of
## violet on the lane's edge and the trees round it, a halo and a pale heart.
func _draw_lights() -> void:
	var dice := MapArt.rng(41)
	for at in MapArt.scatter_band(dice, _lane_from(), _lane_to(), LANE_HALF, HAZE_PATCHES):
		MapArt.glow(self, at, dice.randf_range(HAZE_RADIUS.x, HAZE_RADIUS.y), Color(WISP_COLOR, HAZE_ALPHA))
	var wisps := _wisps()
	for at in wisps:
		MapArt.glow(self, at, WISP_POOL, Color(WISP_COLOR, 0.16))
	for at in wisps:
		MapArt.glow(self, at, WISP_HALO, Color(WISP_COLOR, 0.35))
		MapArt.glow(self, at, WISP_HEART, Color(WISP_COLOR.lightened(0.6), 0.6))


## Where the wisps hang: over the trees along both edges of the lane, apart,
## none over the river.
func _wisps() -> PackedVector2Array:
	var dice := MapArt.rng(43)
	var spots := PackedVector2Array()
	var length := _lane_from().distance_to(_lane_to())
	for side: float in [1.0, -1.0]:
		var run := dice.randf_range(300.0, 700.0)
		while run < length:
			var spot := _lane_from() + _along * run + _across * side * (LANE_HALF + dice.randf_range(WISP_BACK.x, WISP_BACK.y))
			if get_bounds().grow(-60.0).has_point(spot) and not _in_river(spot, -80.0):
				spots.append(spot)
			run += dice.randf_range(WISP_STEP.x, WISP_STEP.y)
	return spots

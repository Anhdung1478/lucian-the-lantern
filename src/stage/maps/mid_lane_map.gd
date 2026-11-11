class_name MidLaneMap
extends StageMap
## Act 1: a long diagonal lane from the bottom-left to the top-right, jungle
## walls on both sides, and the river crossing its middle as walkable
## shallow water. Three rocks give cover. Lucian and Senna start at the
## bottom-left end; minions come from the top-right end; Thresh rises from
## the river.
## Drawn with MapArt: a worn lane with an old road's stones down its middle
## and grass creeping in from the jungle, tree crowns over the walls and
## past the border, a winding river with sand banks and a glow in its depths
## where the boss rises, faceted rocks, and fireflies and a shimmer on the
## water (build_ambience).

const LANE_START := Vector2(500, 2700)
const LANE_END := Vector2(4700, 500)
const LANE_HALF := 450.0
## Half the river's width, and how far it runs each way from the lane's center.
const RIVER_HALF := 260.0
const RIVER_REACH := 1100.0
const ROCK_RADIUS := 70.0

## The lane as it is drawn runs this far past its two ends, to the map's
## corners.
const LANE_RUN := 700.0
## The ground: its soft patches (how many, their radius range) and the path
## worn along the lane's middle (half its width).
const PATCHES := 40
const PATCH_RADIUS := Vector2(240, 520)
const PATH_HALF := 330.0
## Grass creeps in from the jungle: soft stamps this far apart along its
## edge, this wide. Tufts and flowers grow in that strip along each edge,
## and a few tufts in the open (tries: only those that land on the lane's
## dry ground are kept).
const GRASS_STEP := 150.0
const GRASS_REACH := 210.0
const TUFT_TRIES := 520
const OPEN_TUFT_TRIES := 240
const TUFT_HEIGHT := Vector2(11, 19)
const FLOWER_TRIES := 110
const PEBBLE_TRIES := 230
const PEBBLE_RADIUS := Vector2(4, 9)
const CRACK_TRIES := 40
## The old road down the lane's middle: flat stones (tries), thick along the
## middle line and gone COBBLE_REACH from it, each this wide.
const COBBLE_TRIES := 1500
const COBBLE_REACH := 280.0
const COBBLE_RADIUS := Vector2(10, 23)
## The river as it is drawn: its banks wind this far in and out (BANK_POINTS
## points a side) and run on this far under the trees at each end; sand lies
## this far round it; it is deep this far in; and it has ripples, stones in
## its shallows and lily pads in its arms (tries).
const BANK_POINTS := 34
const BANK_WIND := 16.0
const RIVER_RUN := 170.0
const SAND_REACH := 44.0
const WET_REACH := 14.0
const RIVER_DEPTH := 150.0
const RIPPLE_TRIES := 90
## The current: faint streaks along the river's flow (tries), this long.
const STREAK_TRIES := 70
const STREAK_LENGTH := Vector2(70, 190)
## The water darkens as it runs on under the trees: this dark at each end.
const SHADE_ALPHA := 0.5
const STONE_TRIES := 60
const STONE_RADIUS := Vector2(7, 16)
const PAD_TRIES := 150
const PAD_RADIUS := Vector2(10, 19)
## How tall the trees and the rocks are, for their shadows; how far past the
## border the trees are drawn.
const TREE_HEIGHT := 64.0
const ROCK_HEIGHT := 40.0
const TREES_OUTSIDE := 150.0
## The far edges darken over this depth.
const VIGNETTE_DEPTH := 560.0
## Fireflies in the grass along each edge, and glints on the river (tries).
const FIREFLY_TRIES := 60
const GLINT_TRIES := 110

## The palette; a subclass sets its own in _init.
var lane_color := Color("5b5244")
var jungle_color := Color("1d3a24")
var jungle_edge := Color("2f5a35")
var tree_color := Color("16301d")
## The light the leaves catch.
var leaf_light := Color("8da490")
var river_color := Color("2e5f86")
var river_edge := Color("6fb4d8")
var rock_color := Color("6b6660")
## The mood: the fireflies, the flowers at the jungle's foot, and the glow
## in the river's depths where the boss rises.
var firefly_color := Color("e6f28a")
var flower_color := Color("efe6b4")
var depths_color := Color("5fd6b4")
## How dark the far edges are.
var vignette_alpha := 0.42
var _river: PackedVector2Array
var _along := (LANE_END - LANE_START).normalized()
var _across := _along.orthogonal()
var _center := (LANE_START + LANE_END) * 0.5


func _init() -> void:
	size = Vector2(5200, 3200)
	var area := PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)])
	var lane := _band(LANE_START - along() * 2000.0, LANE_END + along() * 2000.0, LANE_HALF)
	var river := _band(center() - across() * RIVER_REACH, center() + across() * RIVER_REACH, RIVER_HALF)
	_river = Geometry2D.intersect_polygons(area, river)[0]
	var open: PackedVector2Array = Geometry2D.merge_polygons(lane, river)[0]
	# The open lane and river cross the whole area, so every piece is jungle (no holes).
	for piece in Geometry2D.clip_polygons(area, open):
		wall_polygons.append(piece)
	lucian_start = LANE_START + along() * 300.0
	ally_start = LANE_START + along() * 120.0 + across() * 160.0
	merchant_point = center() - along() * 700.0 - across() * 160.0
	boss_point = center() + across() * 300.0
	spawn_points = [LANE_END - along() * 200.0 + across() * 160.0, LANE_END - along() * 200.0 - across() * 160.0]
	for rock: Vector2 in [center() - along() * 480.0 + across() * 230.0, center() + along() * 480.0 - across() * 230.0, center() - across() * 720.0]:
		wall_circles.append(Vector3(rock.x, rock.y, ROCK_RADIUS))


## Down the lane, toward the minions' end.
func along() -> Vector2:
	return _along


## Across the lane, toward the top-left jungle.
func across() -> Vector2:
	return _across


func center() -> Vector2:
	return _center


func build_ambience() -> MapAmbience:
	var ambience := MapAmbience.new()
	var dice := MapArt.rng(31)
	for side: float in [1.0, -1.0]:
		ambience.add(MapAmbience.Kind.FIREFLY, _scatter_in_grass(dice, side, FIREFLY_TRIES, _on_lane.bind(30.0)), firefly_color, dice)
	ambience.add(MapAmbience.Kind.GLINT, MapArt.scatter(dice, MapArt.bounds_of(_river), GLINT_TRIES, _in_river.bind(40.0)),
		Color(river_edge.lightened(0.5), 0.75), dice)
	return ambience


func _band(from: Vector2, to: Vector2, half: float) -> PackedVector2Array:
	var side := (to - from).normalized().orthogonal() * half
	return PackedVector2Array([from + side, to + side, to - side, from - side])


func _draw() -> void:
	MapArt.outside(self, get_bounds(), _under_color())
	_draw_ground()
	_draw_river()
	_draw_marks()
	_draw_shadows()
	_draw_jungle()
	_draw_rocks()
	_draw_lights()
	MapArt.vignette(self, get_bounds(), VIGNETTE_DEPTH, vignette_alpha)


## The lane: its tint broken up by soft patches, a lighter path worn along
## its middle, and grass creeping in from the jungle's edge.
func _draw_ground() -> void:
	draw_rect(get_bounds(), lane_color)
	MapArt.patches(self, MapArt.rng(21), get_bounds(), PATCHES, PATCH_RADIUS,
		Color(lane_color.lightened(0.14), 0.5), Color(lane_color.darkened(0.32), 0.45))
	MapArt.band(self, _lane_from(), _lane_to(), PATH_HALF, Color(lane_color.lightened(0.13), 0.6))
	for polygon in wall_polygons:
		for at in MapArt.along(polygon, GRASS_STEP, -MapArt.EDGE_BEYOND, _is_ground):
			MapArt.glow(self, at, GRASS_REACH, Color(_grass_color(), 0.34))


## The river: sand round it, the water in bands of depth with a foam line,
## a glow in its depths round the boss's point, a shade at each end where it
## runs on under the trees, the current's streaks and ripples, stones with
## foam round them in its shallows and lily pads in its arms.
func _draw_river() -> void:
	var banks := _banks()
	for sand in Geometry2D.offset_polygon(banks, SAND_REACH, Geometry2D.JOIN_ROUND):
		draw_colored_polygon(sand, lane_color.lightened(0.2))
	for wet in Geometry2D.offset_polygon(banks, WET_REACH, Geometry2D.JOIN_ROUND):
		draw_colored_polygon(wet, lane_color.darkened(0.22))
	var foam := Color(river_edge.lightened(0.45), 0.8)
	MapArt.water(self, banks, river_color.darkened(0.16), river_color.lerp(river_edge, 0.45), foam, RIVER_DEPTH)
	for reach: float in [-190.0, 0.0, 190.0]:
		MapArt.glow(self, boss_point + across() * reach, RIVER_HALF - 20.0, Color(depths_color, 0.24))
	for side: float in [1.0, -1.0]:
		MapArt.glow(self, center() + across() * side * (RIVER_REACH + RIVER_RUN), RIVER_HALF + RIVER_RUN, Color(_under_color(), SHADE_ALPHA))
	var dice := MapArt.rng(3)
	var box := MapArt.bounds_of(_river)
	var ripples := MapArt.Facets.new()
	var current := Color(river_edge.lightened(0.3), 0.12)
	for at in MapArt.scatter(dice, box, STREAK_TRIES, _in_river.bind(40.0)):
		var half := across() * dice.randf_range(STREAK_LENGTH.x, STREAK_LENGTH.y) * 0.5
		ripples.blade(at - half, at + half, 3.0, current)
	for at in MapArt.scatter(dice, box, RIPPLE_TRIES, _in_river.bind(46.0)):
		MapArt.ripple(ripples, at, dice.randf_range(14.0, 34.0), Color(river_edge.lightened(0.3), 0.45))
	ripples.draw(self)
	var stones := MapArt.scatter(dice, box, STONE_TRIES, _near_bank)
	for at in stones:
		MapArt.disc(self, at, STONE_RADIUS.y * 1.1, Color(foam, 0.28))
	for at in stones:
		MapArt.pebble(self, dice, at, dice.randf_range(STONE_RADIUS.x, STONE_RADIUS.y), rock_color.darkened(0.12))
	var pad_color := _grass_color().lightened(0.08)
	for at in MapArt.scatter(dice, box, PAD_TRIES, _in_arm):
		var radius := dice.randf_range(PAD_RADIUS.x, PAD_RADIUS.y)
		MapArt.disc(self, at + MapArt.SHADOW_DIR * 4.0, radius, Color(MapArt.SHADOW, 0.3))
		MapArt.disc(self, at, radius, pad_color)
		MapArt.disc(self, at - MapArt.SHADOW_DIR * radius * 0.22, radius * 0.62, pad_color.lightened(0.14))


## Small things on the lane: the old road's stones down its middle; tufts
## and flowers, thick at the jungle's foot and thin in the open; pebbles;
## cracks.
func _draw_marks() -> void:
	var dice := MapArt.rng(5)
	var cobble := lane_color.lightened(0.1)
	for at in MapArt.scatter_band(dice, _lane_from(), _lane_to(), COBBLE_REACH, COBBLE_TRIES, _is_paved.bind(dice)):
		var radii := Vector2(1.0, dice.randf_range(0.62, 0.8)) * dice.randf_range(COBBLE_RADIUS.x, COBBLE_RADIUS.y)
		MapArt.oval(self, at + MapArt.SHADOW_DIR * 3.0, radii, Color(MapArt.SHADOW, 0.2))
		MapArt.oval(self, at, radii, Color(cobble.lightened(dice.randf_range(0.0, 0.07)), 0.7))
	var marks := MapArt.Facets.new()
	var crack_color := Color(lane_color.darkened(0.45), 0.32)
	for at in MapArt.scatter_band(dice, _lane_from(), _lane_to(), LANE_HALF, CRACK_TRIES, _on_lane.bind(60.0)):
		MapArt.crack(marks, dice, at, dice.randf_range(40.0, 90.0), 2.0, crack_color)
	var blades: Array[Color] = [_grass_color(), _grass_color().lightened(0.18), lane_color.lightened(0.22)]
	var tufts := MapArt.scatter_band(dice, _lane_from(), _lane_to(), LANE_HALF - GRASS_REACH, OPEN_TUFT_TRIES, _on_lane.bind(6.0))
	for side: float in [1.0, -1.0]:
		tufts.append_array(_scatter_in_grass(dice, side, TUFT_TRIES, _grows_grass.bind(dice)))
	for at in tufts:
		MapArt.tuft(marks, dice, at, dice.randf_range(TUFT_HEIGHT.x, TUFT_HEIGHT.y), Color(blades[dice.randi() % blades.size()], 0.85))
	marks.draw(self)
	var pebble_color := rock_color.lerp(lane_color, 0.45)
	for at in MapArt.scatter_band(dice, _lane_from(), _lane_to(), LANE_HALF, PEBBLE_TRIES, _on_lane.bind(20.0)):
		MapArt.pebble(self, dice, at, dice.randf_range(PEBBLE_RADIUS.x, PEBBLE_RADIUS.y), pebble_color)
	for side: float in [1.0, -1.0]:
		for at in _scatter_in_grass(dice, side, FLOWER_TRIES, _grows_grass.bind(dice)):
			MapArt.disc(self, at, dice.randf_range(2.5, 4.0), Color(flower_color, 0.8))


## The trees' shadows on the lane and the river (the trees past the top and
## left borders cast theirs too), and the rocks'.
func _draw_shadows() -> void:
	for polygon in wall_polygons:
		MapArt.cast_shadow(self, polygon, TREE_HEIGHT)
	for rect in border_rects():
		MapArt.cast_shadow(self, MapArt.polygon_of(rect), TREE_HEIGHT)
	for rock in wall_circles:
		MapArt.round_shadow(self, Vector2(rock.x, rock.y), rock.z, ROCK_HEIGHT)


## Tree crowns over the jungle, and on past the border where the camera
## still sees.
func _draw_jungle() -> void:
	var tints := PackedColorArray([tree_color.lerp(jungle_color, 0.5), jungle_color, jungle_color.lerp(jungle_edge, 0.3), jungle_color.lerp(jungle_edge, 0.55)])
	var dice := MapArt.rng(7)
	for rect in MapArt.border(get_bounds(), TREES_OUTSIDE):
		MapArt.canopy(self, dice, MapArt.polygon_of(rect), tints, leaf_light, _under_color(), _is_ground)
	for polygon in wall_polygons:
		MapArt.canopy(self, dice, polygon, tints, leaf_light, _under_color(), _is_ground)


func _draw_rocks() -> void:
	var dice := MapArt.rng(9)
	var stone := MapArt.Facets.new()
	for rock in wall_circles:
		MapArt.rock(stone, dice, Vector2(rock.x, rock.y), rock.z, rock_color)
	stone.draw(self)


## Lights over the finished map: none in Act 1 (Act 4's twin has its own).
func _draw_lights() -> void:
	pass


## The river's outline as it is drawn: the band's long sides wind in and out
## a little, so the banks are not ruled lines, and it runs on under the
## trees at both ends. In the jungle the trees cover the difference.
func _banks() -> PackedVector2Array:
	var points := PackedVector2Array()
	for side: float in [1.0, -1.0]:
		for i in BANK_POINTS + 1:
			var share := float(i) / BANK_POINTS
			var reach := lerpf(-RIVER_REACH - RIVER_RUN, RIVER_REACH + RIVER_RUN, share) * side
			var wind := sin(share * TAU * 2.4 + side) * BANK_WIND + sin(share * TAU * 7.0) * BANK_WIND * 0.3
			points.append(_center + _across * reach + _along * side * (RIVER_HALF + wind))
	return points


## The two ends of the lane as it is drawn, on its middle line.
func _lane_from() -> Vector2:
	return LANE_START - _along * LANE_RUN


func _lane_to() -> Vector2:
	return LANE_END + _along * LANE_RUN


## `tries` points thrown over the strip of grass along one edge of the lane
## (`side` 1: the top-left edge; -1: the bottom-right one), those `keep`
## says yes to.
func _scatter_in_grass(dice: RandomNumberGenerator, side: float, tries: int, keep: Callable) -> PackedVector2Array:
	var shift := _across * side * (LANE_HALF - GRASS_REACH * 0.5)
	return MapArt.scatter_band(dice, _lane_from() + shift, _lane_to() + shift, GRASS_REACH * 0.5, tries, keep)


## The dark under the trees.
func _under_color() -> Color:
	return tree_color.darkened(0.35)


func _grass_color() -> Color:
	return jungle_color.lerp(jungle_edge, 0.75)


## How far `point` is from the lane's middle line.
func _off_lane(point: Vector2) -> float:
	return absf((point - _center).dot(_across))


## How far `point` is from the river's middle line.
func _off_river(point: Vector2) -> float:
	return absf((point - _center).dot(_along))


## On the lane or in the river, inside the map: not jungle.
func _is_ground(point: Vector2) -> bool:
	return get_bounds().has_point(point) and (_off_lane(point) < LANE_HALF or _in_river(point, 0.0))


## In the river, at least `margin` from its banks and its ends.
func _in_river(point: Vector2, margin: float) -> bool:
	return _off_river(point) < RIVER_HALF - margin and _off_lane(point) < RIVER_REACH - margin


## In the river's shallows: near a bank, where it crosses the lane.
func _near_bank(point: Vector2) -> bool:
	return _in_river(point, 24.0) and _off_river(point) > RIVER_HALF - 90.0 and _off_lane(point) < LANE_HALF


## In one of the river's arms, between the jungle's walls: off the lane and
## clear of the banks.
func _in_arm(point: Vector2) -> bool:
	return _in_river(point, 30.0) and _off_lane(point) > LANE_HALF + 60.0


## On the lane's dry ground, at least `margin` from the jungle, the river's
## sand and the map's border.
func _on_lane(point: Vector2, margin: float) -> bool:
	return (_off_lane(point) < LANE_HALF - margin and _off_river(point) > RIVER_HALF + SAND_REACH + margin
		and get_bounds().grow(-margin).has_point(point))


## Where a stone of the old road lies: on the lane's dry ground, mostly
## along its middle line (`dice` decides).
func _is_paved(point: Vector2, dice: RandomNumberGenerator) -> bool:
	var off := _off_lane(point) / COBBLE_REACH
	return _on_lane(point, 30.0) and dice.randf() < 1.0 - off * off


## Where a tuft or a flower grows in the grass along the lane's edge: on dry
## ground, nearly always at the jungle's foot, less often away from it
## (`dice` decides).
func _grows_grass(point: Vector2, dice: RandomNumberGenerator) -> bool:
	var open := clampf((LANE_HALF - _off_lane(point)) / GRASS_REACH, 0.0, 1.0)
	return _on_lane(point, 6.0) and dice.randf() < lerpf(1.0, 0.2, open)

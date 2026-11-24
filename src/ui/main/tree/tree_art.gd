class_name TreeArt
extends RefCounted
## The Evolution Tree page's scenery (V2.2): a Sentinel of Light Astrolabe &
## Starlight Constellation altar. Replaces the literal oak tree with deep
## midnight-obsidian sky, subtle teal-and-indigo nebula washes, a grand
## engraved brass astrolabe centered behind the branch, delicate starlight
## constellation filaments joining each branch's groups, and quiet obsidian
## pools behind every lantern node. Laid out once from deterministic RNG;
## nothing on it moves at rest.

const STARS := 95
## Subtle celestial glow off the top right (echoing the night sky).
const MOON_GLOW_AT := Vector2(1260, -60)
const MOON_LIGHT := Color(0.56, 0.78, 0.92)
const NEBULA_TEAL := Color(0.14, 0.42, 0.44)
const NEBULA_GOLD := Color(0.86, 0.68, 0.34)
const NEBULA_INDIGO := Color(0.14, 0.22, 0.44)
## Engraved brass astrolabe geometry.
const BRASS := Color("c9a45c")
const BRASS_BRIGHT := Color("ffe39a")
const FILAMENT := Color(0.79, 0.64, 0.36, 0.24)
const FILAMENT_CORE := Color(0.68, 0.9, 0.86, 0.16)
## Subtle dark mist hugging the bottom of the frame.
const FLOOR_MIST := Color(0.03, 0.08, 0.09, 0.72)
## Quiet obsidian pool behind each node so its lantern tile and name pop.
const NODE_SHADE := Color(0.015, 0.025, 0.038, 0.78)
const SHADE_SIZE := Vector2(236, 256)
const SHADE_DROP := 24.0
## Kept for layout margin clarity: nothing of the astrolabe enters KEEP_CLEAR.
const ASTROLABE_CENTER_Y := 525.0
const ASTROLABE_RADIUS := 360.0

var page: TreePage
var middle: float
## Center of the engraved Sentinel astrolabe.
var astrolabe_center: Vector2
## Outer radius of the engraved astrolabe (fits cleanly below CLEAR_TOP).
var astrolabe_radius: float
## Constellation filament curves joining each group/node to the altar axis.
var filaments: Array[PackedVector2Array] = []
## Small star-junction diamonds along the constellation web: (x, y, radius).
var junctions: Array[Vector3] = []
## Soft nebula clouds placed deterministically behind the constellation: (x, y, rx, ry).
var nebulae: Array[Vector4] = []
## Bright 4-point starlight glints in the sky: (x, y, size, alpha).
var glints: Array[Vector4] = []


func _init(tree_page: TreePage) -> void:
	page = tree_page
	middle = TreePage.SIZE.x * 0.5
	astrolabe_center = Vector2(middle, ASTROLABE_CENTER_Y)
	astrolabe_radius = minf(ASTROLABE_RADIUS, ASTROLABE_CENTER_Y - TreePage.CLEAR_TOP - 20.0)
	_lay_nebulae(page.rng(40))
	_lay_constellation(page.rng(41))
	_lay_glints(page.rng(42))


# --- Drawing --------------------------------------------------------------------------


## Night sky, soft cosmic nebula clouds, distant stars, and subtle floor mist.
func draw_back(canvas: Control) -> void:
	_draw_sky(canvas)
	_draw_nebulae(canvas)
	_draw_glints(canvas)
	_draw_floor_mist(canvas)


## The engraved Sentinel astrolabe, corner filigree, constellation filaments,
## junction diamonds, and quiet obsidian pools under every node.
func draw_tree(canvas: Control) -> void:
	_draw_astrolabe(canvas)
	_draw_corner_filigree(canvas)
	_draw_constellation(canvas)
	var glow := JourneyMap.glow()
	for center: Vector2 in page.centers.values():
		var at := center + Vector2(0, SHADE_DROP)
		canvas.draw_texture_rect(glow, Rect2(at - SHADE_SIZE * 0.5, SHADE_SIZE), false, NODE_SHADE)


# --- Layout ---------------------------------------------------------------------------


func _lay_nebulae(rng: RandomNumberGenerator) -> void:
	# Soft luminous clouds behind each group & around the astrolabe heart.
	nebulae.append(Vector4(astrolabe_center.x, astrolabe_center.y, 440.0, 290.0))
	for group in page.groups:
		var anchor: Vector2 = group["anchor"]
		nebulae.append(Vector4(anchor.x + rng.randf_range(-24.0, 24.0), anchor.y - 30.0, rng.randf_range(220.0, 320.0), rng.randf_range(160.0, 230.0)))
	for k in 3:
		var x := rng.randf_range(180.0, TreePage.SIZE.x - 180.0)
		var y := rng.randf_range(TreePage.CLEAR_TOP + 120.0, TreePage.SIZE.y - 120.0)
		nebulae.append(Vector4(x, y, rng.randf_range(240.0, 380.0), rng.randf_range(130.0, 200.0)))


func _lay_constellation(rng: RandomNumberGenerator) -> void:
	# Central vertical Sentinel meridian spine if any nodes sit on the middle axis.
	var axis_ys: Array[float] = []
	for id: StringName in page.centers:
		if page.on_trunk[id]:
			axis_ys.append(page.centers[id].y)
	axis_ys.sort()
	if axis_ys.size() >= 2:
		filaments.append(PackedVector2Array([Vector2(middle, axis_ys[0]), Vector2(middle, axis_ys[-1])]))
	# Graceful curved starlight filaments connecting each group to the astrolabe
	# hub and linking sibling nodes within multi-node clusters.
	for group in page.groups:
		var ids: Array = group["ids"]
		var anchor: Vector2 = group["anchor"]
		var side := signf(anchor.x - middle)
		var hub := Vector2(middle + side * 44.0, clampf(anchor.y + 40.0, astrolabe_center.y - 120.0, astrolabe_center.y + 150.0))
		var ctrl1 := hub.lerp(anchor, 0.35) + Vector2(side * 24.0, -18.0)
		var ctrl2 := hub.lerp(anchor, 0.72) + Vector2(-side * 12.0, 14.0)
		filaments.append(TreePage.bezier(hub, ctrl1, ctrl2, anchor))
		junctions.append(Vector3(hub.x, hub.y, 4.0))
		if ids.size() >= 2:
			# Connect each member of the cluster to its group anchor.
			for id: StringName in ids:
				var c: Vector2 = page.centers[id]
				if c.distance_to(anchor) > 36.0:
					filaments.append(PackedVector2Array([anchor, c]))
			junctions.append(Vector3(anchor.x, anchor.y, 3.5))
		else:
			var lone: Vector2 = page.centers[ids[0]]
			if lone.distance_to(anchor) > 12.0:
				filaments.append(PackedVector2Array([anchor, lone]))
	# Subtle decorative star-points along the astrolabe's cardinal intersections.
	for k in 4:
		var ang := k * PI * 0.5 + PI * 0.25
		var pt := astrolabe_center + Vector2.from_angle(ang) * (astrolabe_radius * 0.72)
		junctions.append(Vector3(pt.x, pt.y, rng.randf_range(2.6, 3.8)))


func _lay_glints(rng: RandomNumberGenerator) -> void:
	for k in 14:
		var x := rng.randf_range(64.0, TreePage.SIZE.x - 64.0)
		var y := rng.randf_range(TreePage.CLEAR_TOP + 24.0, TreePage.SIZE.y - 64.0)
		glints.append(Vector4(x, y, rng.randf_range(4.0, 8.5), rng.randf_range(0.18, 0.45)))


# --- Drawing parts --------------------------------------------------------------------


func _draw_sky(canvas: Control) -> void:
	var rect := Rect2(Vector2.ZERO, TreePage.SIZE)
	MainBackdrop.draw_sky(canvas, rect)
	var glow := JourneyMap.glow()
	canvas.draw_texture_rect(glow, Rect2(MOON_GLOW_AT - Vector2(920, 640), Vector2(1840, 1280)), false, Color(MOON_LIGHT, 0.14))
	canvas.draw_texture_rect(glow, Rect2(astrolabe_center - Vector2(680, 440), Vector2(1360, 880)), false, Color(NEBULA_TEAL, 0.16))
	MainBackdrop.draw_stars(canvas, rect, page.rng(1), STARS)


func _draw_nebulae(canvas: Control) -> void:
	var glow := JourneyMap.glow()
	for i in nebulae.size():
		var n := nebulae[i]
		var col := NEBULA_GOLD if i == 0 else (NEBULA_TEAL if i % 2 == 1 else NEBULA_INDIGO)
		var alpha := 0.085 if i == 0 else 0.095
		canvas.draw_texture_rect(glow, Rect2(Vector2(n.x - n.z, n.y - n.w), Vector2(n.z * 2.0, n.w * 2.0)), false, Color(col, alpha))


func _draw_glints(canvas: Control) -> void:
	var glow := JourneyMap.glow()
	for g in glints:
		var at := Vector2(g.x, g.y)
		var s := g.z
		var a := g.w
		canvas.draw_texture_rect(glow, Rect2(at - Vector2.ONE * s * 2.4, Vector2.ONE * s * 4.8), false, Color(BRASS_BRIGHT, a * 0.45))
		var star := PackedVector2Array([
			at + Vector2(0, -s), at + Vector2(s * 0.22, -s * 0.22),
			at + Vector2(s, 0), at + Vector2(s * 0.22, s * 0.22),
			at + Vector2(0, s), at + Vector2(-s * 0.22, s * 0.22),
			at + Vector2(-s, 0), at + Vector2(-s * 0.22, -s * 0.22),
		])
		canvas.draw_colored_polygon(star, Color(1.0, 0.96, 0.84, a))


func _draw_floor_mist(canvas: Control) -> void:
	var size := TreePage.SIZE
	var glow := JourneyMap.glow()
	canvas.draw_texture_rect(glow, Rect2(Vector2(-120.0, size.y - 210.0), Vector2(size.x + 240.0, 320.0)), false, FLOOR_MIST)
	canvas.draw_texture_rect(glow, Rect2(Vector2(middle - 520.0, size.y - 140.0), Vector2(1040.0, 220.0)), false, Color(NEBULA_TEAL, 0.12))


## Grand engraved brass Sentinel astrolabe behind the branch.
func _draw_astrolabe(canvas: Control) -> void:
	var c := astrolabe_center
	var r := astrolabe_radius
	# Outer double celestial ring.
	canvas.draw_arc(c, r, 0.0, TAU, 96, Color(BRASS, 0.2), 1.6, true)
	canvas.draw_arc(c, r - 12.0, 0.0, TAU, 96, Color(BRASS, 0.11), 1.0, true)
	# Fine degree ticks around the outer dial (72 ticks, 12 major compass notches).
	for i in 72:
		var ang := TAU * float(i) / 72.0
		var dir := Vector2.from_angle(ang)
		var major := i % 6 == 0
		var inner_r := r - (12.0 if major else 5.5)
		canvas.draw_line(c + dir * inner_r, c + dir * r, Color(BRASS, 0.26 if major else 0.11), 1.4 if major else 1.0, true)
	# Middle ecliptic ring & subtle diagonal orbital arc.
	var r_mid := r * 0.72
	canvas.draw_arc(c, r_mid, 0.0, TAU, 80, Color(BRASS, 0.15), 1.2, true)
	var orbit := PackedVector2Array()
	for i in 73:
		var ang := TAU * float(i) / 72.0
		var p := Vector2(cos(ang) * r * 1.18, sin(ang) * r * 0.44).rotated(-0.22)
		var world := c + p
		if world.y > TreePage.CLEAR_TOP + 10.0:
			orbit.append(world)
	if orbit.size() >= 2:
		canvas.draw_polyline(orbit, Color(BRASS, 0.09), 1.1, true)
	# Inner sacred-geometry Sentinel ring & 8-point compass diamond.
	var r_in := r * 0.4
	canvas.draw_arc(c, r_in, 0.0, TAU, 64, Color(BRASS, 0.14), 1.2, true)
	for rot: float in [0.0, PI * 0.25]:
		var poly := PackedVector2Array()
		for k in 5:
			var ang := rot + k * PI * 0.5
			poly.append(c + Vector2.from_angle(ang) * r_in)
		canvas.draw_polyline(poly, Color(BRASS, 0.11), 1.0, true)
	# Subtle cardinal axes & outer compass diamonds.
	for k in 4:
		var ang := k * PI * 0.5
		var dir := Vector2.from_angle(ang)
		canvas.draw_line(c + dir * (r_in * 0.45), c + dir * (r + 14.0), Color(BRASS, 0.12), 1.0, true)
		_draw_diamond(canvas, c + dir * r, 5.5, Color(BRASS, 0.36))
	# Delicate horizontal horizon rule through the astrolabe.
	canvas.draw_line(Vector2(64.0, c.y), Vector2(c.x - r - 24.0, c.y), Color(BRASS, 0.09), 1.0, true)
	canvas.draw_line(Vector2(c.x + r + 24.0, c.y), Vector2(TreePage.SIZE.x - 64.0, c.y), Color(BRASS, 0.09), 1.0, true)


## Subtle engraved brass corner brackets in the lower corners of the page.
func _draw_corner_filigree(canvas: Control) -> void:
	var size := TreePage.SIZE
	for side: float in [-1.0, 1.0]:
		var x := 30.0 if side < 0.0 else size.x - 30.0
		var y := size.y - 30.0
		var dx := -side * 42.0
		canvas.draw_polyline(PackedVector2Array([Vector2(x, y - 42.0), Vector2(x, y), Vector2(x + dx, y)]), Color(BRASS, 0.22), 1.4, true)
		_draw_diamond(canvas, Vector2(x, y), 4.0, Color(BRASS, 0.32))


## Delicate starlight constellation filaments & junction diamonds.
func _draw_constellation(canvas: Control) -> void:
	var glow := JourneyMap.glow()
	for curve in filaments:
		if curve.size() < 2:
			continue
		canvas.draw_polyline(curve, Color(BRASS, 0.08), 5.0, true)
		canvas.draw_polyline(curve, FILAMENT, 1.8, true)
		canvas.draw_polyline(curve, FILAMENT_CORE, 1.0, true)
	for j in junctions:
		var at := Vector2(j.x, j.y)
		var r := j.z
		canvas.draw_texture_rect(glow, Rect2(at - Vector2.ONE * r * 3.5, Vector2.ONE * r * 7.0), false, Color(BRASS_BRIGHT, 0.22))
		_draw_diamond(canvas, at, r, Color(BRASS_BRIGHT, 0.65))


static func _draw_diamond(canvas: CanvasItem, at: Vector2, r: float, color: Color) -> void:
	canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(0, -r), at + Vector2(r, 0), at + Vector2(0, r), at + Vector2(-r, 0)]), color)


## Whether a circle at `center` with `radius` overlaps `rect`.
static func circle_hits_rect(center: Vector2, radius: float, rect: Rect2) -> bool:
	var nearest := Vector2(clampf(center.x, rect.position.x, rect.end.x), clampf(center.y, rect.position.y, rect.end.y))
	return nearest.distance_to(center) < radius

class_name TreePage
extends Control
## One branch of the Evolution Tree on a page of its own, drawn as a tree in a
## night grove: a glowing trunk rises from roots at the bottom centre, curved
## limbs reach every node, requirement links wind along the limbs as vines
## (dim, then gold once the node that needs them is bought), faint leaves and
## light motes drift around, and the branch's name and blurb sit top left.
## A node's `grid` is its (column, row up from the ground) on this page: the
## page centres the branch's columns, and its rows from the ground (row 0) to
## the top one. A node on the centre column sits on the trunk.
## A node with a level sum (R) wears a segmented ring, one segment per rank of
## the sum, marked where each of its levels opens. The Backpack page hangs a
## preview under each node: the equip slots with their acts, and the 9x6
## backpack with its open cells lit. It redraws on refresh() only; the motes
## drift on a small layer of their own.

const SIZE := Vector2(1416, 840)
## One grid cell, in pixels.
const CELL := Vector2(180, 150)
## The branch's rows (0 to the top one) are centred on this line.
const MIDDLE_Y := 420.0
## Where the trunk meets the ground.
const GROUND_Y := 772.0
## The trunk: its width at the roots and at its top.
const TRUNK_ROOT := 70.0
const TRUNK_TIP := 26.0
## A limb leaves the trunk this far below its node, and never closer to the
## ground than LIMB_GROUND; where a node on the trunk is, it leaves from
## behind that node instead. Its width from the trunk to the node.
const LIMB_DROP := 96.0
const LIMB_GROUND := 52.0
const LIMB_ROOT := 24.0
const LIMB_TIP := 11.0
const CURVE_STEPS := 28
## Vines: one wave's length, its height, the line's width, the gap between
## leaves.
const VINE_WAVE := 34.0
const VINE_AMP := 4.0
const VINE_WIDTH := 2.5
const VINE_LEAF_STEP := 36.0
## The ring of a node with a level sum: radius, thickness, the open gap at the
## bottom (radians) and the font of its marks.
const RING_RADIUS := 80.0
const RING_WIDTH := 8.0
const RING_GAP := PI * 0.8
const RING_FONT := 15
## The header, top left: its box and fonts.
const HEADER_RECT := Rect2(24, 18, 480, 112)
const HEADER_AT := Vector2(40, 46)
const CAPTION_FONT := 15
const TITLE_FONT := 32
const BLURB_FONT := 18
## A limb's caption (OFFENSE, REWARDS...) over its top node.
const GROUP_FONT := 17
const GROUP_LIFT := 26.0
## The Backpack page's previews: the plaque under each node and its cells.
const PLAQUE_TOP := 104.0
const PLAQUE_SIZE := Vector2(340, 214)
const SLOT_SIZE := 42.0
const SLOT_GAP := 8.0
const MINI_CELL := 22.0
const MINI_GAP := 4.0
const MINI_COLUMNS := 9
const EQUIP_ID := &"equip_slots"
const BACKPACK_ID := &"backpack_slots"
## Light motes drifting up: how many, how fast.
const MOTES := 28
const MOTE_SPEED := 9.0
const FRAME_INSET := 7.0

## The night grove (the main screen's backdrop matches these).
const SKY_TOP := Color("08101f")
const SKY_BOTTOM := Color("0d2a2b")
const STAR_COLOR := Color(0.82, 0.88, 1.0)
const MOON_COLOR := Color("f3ead2")
const MOON_AT := Vector2(1010, 132)
const MOON_RADIUS := 26.0
const HILL_FAR := Color("0f252c")
const HILL_NEAR := Color("0a191c")
const SILHOUETTE := Color("081316")
const MIST_COLOR := Color(0.6, 0.82, 0.86, 0.05)
const GROUND_COLOR := Color("0a1411")
const GRASS_COLOR := Color("1d3a2a")
const CANOPY_COLOR := Color(0.1, 0.24, 0.18, 0.55)
const LEAF_COLOR := Color("447556")
const LEAF_DARK := Color("2a4c3c")
const BARK_COLOR := Color("54443a")
const BARK_EDGE := Color("140f0c")
const LIGHT := Color("ffd98a")
const VINE_DIM := Color("4d6458")
const VINE_LIT := UiStyle.GOLD_COLOR
const RING_DIM := Color(0.22, 0.27, 0.3)
const PLAQUE_COLOR := Color(0.035, 0.05, 0.06, 0.94)
const FRAME_COLOR := Color(0.79, 0.64, 0.36, 0.85)
const FRAME_INNER := Color(0.79, 0.64, 0.36, 0.28)
const TEXT_OUTLINE := Color(0.01, 0.02, 0.03, 0.9)

## The branches' names, blurbs and tab icons.
const NAMES := {
	&"skills": "Skills", &"stats": "Stats", &"backpack": "Backpack",
	&"economy": "Economy", &"summoners": "Summoners",
}
const BLURBS := {
	&"skills": "Q, W and E open the passive; their ranks open R.",
	&"stats": "Offense, defense and sustain for Lucian himself.",
	&"backpack": "Equip slots for gear, and cells to carry more.",
	&"economy": "More gold, XP and essence, and a better merchant.",
	&"summoners": "Summoner spells, their upgrades, a second slot.",
}
const ICONS := {
	&"skills": preload("res://assets/art/ui/icon_r.svg"),
	&"stats": preload("res://assets/art/tree/stat_ad.svg"),
	&"backpack": preload("res://assets/art/tree/backpack_slots.svg"),
	&"economy": preload("res://assets/art/tree/stage_gold.svg"),
	&"summoners": preload("res://assets/art/summoners/flash.svg"),
}
## Per branch, its limbs: each a chain of node ids from the trunk outward,
## with an optional caption. A node in no chain grows from the trunk alone.
const LIMBS := {
	&"skills": [
		{"ids": [&"skill_w", &"passive", &"skill_r"]},
	],
	&"stats": [
		{"label": "OFFENSE", "ids": [&"stat_ad", &"stat_ap", &"stat_attack_speed"]},
		{"label": "DEFENSE", "ids": [&"stat_hp", &"stat_armor", &"stat_mr"]},
		{"label": "SUSTAIN", "ids": [&"stat_mana", &"stat_hp_regen", &"stat_mana_regen"]},
	],
	&"economy": [
		{"label": "REWARDS", "ids": [&"stage_gold", &"bonus_xp", &"essence_drop"]},
		{"label": "MERCHANT", "ids": [&"merchant_stock", &"refresh_cost"]},
	],
	&"summoners": [
		{"ids": [&"flash", &"flash_upgrade"]},
		{"ids": [&"ghost", &"ghost_upgrade"]},
		{"ids": [&"barrier", &"barrier_upgrade"]},
		{"ids": [&"heal", &"heal_upgrade"]},
		{"ids": [&"clarity", &"clarity_upgrade"]},
		{"ids": [&"smite", &"smite_upgrade"]},
	],
}
const LOCK := preload("res://assets/art/ui/lock.svg")

var branch: StringName
var tree: EvolutionTree
## Node id -> its TreeNodeView on this page.
var views := {}
## Node id -> the node's centre on the page.
var centers := {}

## Node id -> the node it grows from (&"" for the trunk), parents first.
var _parent := {}
## Node id -> true when it sits on the trunk.
var _on_trunk := {}
## Node id -> its limb's points, from where it leaves the trunk or its parent
## to the node (none for a node on the trunk).
var _limbs := {}
var _trunk_top := 0.0
var _motes := Control.new()
## Per mote: its x, y and a phase in 0..1.
var _mote_seeds: Array[Vector3] = []
var _time := 0.0
var _spaced_font: FontVariation


func _init(branch_id: StringName, evolution_tree: EvolutionTree, essences: Essences) -> void:
	branch = branch_id
	tree = evolution_tree
	size = SIZE
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layout()
	_motes.size = SIZE
	_motes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_motes.draw.connect(_draw_motes)
	add_child(_motes)
	var rng := _rng(90)
	for i in MOTES:
		_mote_seeds.append(Vector3(rng.randf_range(20.0, SIZE.x - 20.0), rng.randf_range(0.0, SIZE.y), rng.randf()))
	for data in tree.branch_nodes(branch):
		var view := TreeNodeView.new(data, tree, essences)
		view.position = centers[data.id] - Vector2.ONE * TreeNodeView.SIZE * 0.5
		add_child(view)
		views[data.id] = view


func _ready() -> void:
	set_process(is_visible_in_tree())


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_inside_tree():
		set_process(is_visible_in_tree())


func _process(delta: float) -> void:
	_time += delta
	_motes.queue_redraw()


## Levels bought in `branch` and its levels in all, as (bought, all).
static func levels(evolution_tree: EvolutionTree, branch_id: StringName) -> Vector2i:
	var count := Vector2i.ZERO
	for data in evolution_tree.branch_nodes(branch_id):
		count += Vector2i(evolution_tree.level(data.id), data.max_level)
	return count


## Redraws the views, limbs, vines and previews from the tree.
func refresh() -> void:
	for view: TreeNodeView in views.values():
		view.refresh()
	queue_redraw()


# --- Layout ---------------------------------------------------------------------------


func _layout() -> void:
	var nodes := tree.branch_nodes(branch)
	var columns := Vector2(INF, -INF)
	var top_row := 0.0
	for data in nodes:
		columns = Vector2(minf(columns.x, data.grid.x), maxf(columns.y, data.grid.x))
		top_row = maxf(top_row, data.grid.y)
	var middle := Vector2((columns.x + columns.y) * 0.5, top_row * 0.5)
	for data in nodes:
		centers[data.id] = Vector2(SIZE.x * 0.5 + (data.grid.x - middle.x) * CELL.x, MIDDLE_Y - (data.grid.y - middle.y) * CELL.y)
	for limb: Dictionary in LIMBS.get(branch, []):
		var ids: Array = limb["ids"]
		for i in ids.size():
			_parent[ids[i]] = ids[i - 1] if i > 0 else &""
	for data in nodes:
		if not _parent.has(data.id):
			_parent[data.id] = &""
	_trunk_top = GROUND_Y - LIMB_GROUND
	for id: StringName in _parent:
		var parent: StringName = _parent[id]
		_on_trunk[id] = absf(centers[id].x - SIZE.x * 0.5) < 1.0 and (parent == &"" or _on_trunk[parent])
		if _on_trunk[id]:
			_trunk_top = minf(_trunk_top, centers[id].y)
	for id: StringName in _parent:
		if not _on_trunk[id] and _parent[id] == &"":
			_trunk_top = minf(_trunk_top, _attach_y(id))
	for id: StringName in _parent:
		if _on_trunk[id]:
			continue
		var parent: StringName = _parent[id]
		var from: Vector2
		if parent != &"":
			from = centers[parent]
		else:
			# From the trunk's own side, so boughs going left and right never cross.
			var y := _attach_y(id)
			from = Vector2(SIZE.x * 0.5 + signf(centers[id].x - SIZE.x * 0.5) * _trunk_width(y) * 0.3, y)
		_limbs[id] = _limb_curve(from, centers[id])


## Where node `id`'s limb leaves the trunk: LIMB_DROP under the node, or
## from behind a node on the trunk that would sit there (its name included).
func _attach_y(id: StringName) -> float:
	var y := minf(centers[id].y + LIMB_DROP, GROUND_Y - LIMB_GROUND)
	for other: StringName in _on_trunk:
		var center: Vector2 = centers[other]
		if _on_trunk[other] and y > center.y - TreeNodeView.SIZE * 0.5 and y < center.y + TreeNodeView.SIZE:
			return center.y + TreeNodeView.SIZE * 0.2
	return y


## The trunk's width at height `y`.
func _trunk_width(y: float) -> float:
	return lerpf(TRUNK_ROOT, TRUNK_TIP, inverse_lerp(GROUND_Y, _trunk_top, y))


## A limb from `from` out to `to`, arching like a bough: it rises from the
## trunk, bends outward and comes into the node from the inner side; a node
## straight above gets a straight limb.
func _limb_curve(from: Vector2, to: Vector2) -> PackedVector2Array:
	var d := to - from
	var c1 := from + Vector2(d.x * 0.2, d.y * 0.6 - absf(d.x) * 0.22)
	var c2 := to - Vector2(d.x * 0.45, absf(d.x) * 0.12)
	return _bezier(from, c1, c2, to)


static func _bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in CURVE_STEPS + 1:
		var t := float(i) / CURVE_STEPS
		var u := 1.0 - t
		points.append(p0 * u * u * u + p1 * 3.0 * u * u * t + p2 * 3.0 * u * t * t + p3 * t * t * t)
	return points


## Points from node `id` down its limbs to the trunk (the last point is on the
## trunk), or only down to `stop` when that is on the way.
func _stem(id: StringName, stop := &"") -> PackedVector2Array:
	var points := PackedVector2Array([centers[id]])
	var at := id
	while at != stop and not _on_trunk[at]:
		var limb: PackedVector2Array = _limbs[at]
		for i in range(limb.size() - 2, -1, -1):
			points.append(limb[i])
		at = _parent[at]
		if at == &"":
			return points
	if at != stop and stop != &"":
		# Both on the trunk.
		points.append(centers[stop])
	return points


func _grows_from(id: StringName, ancestor: StringName) -> bool:
	var at: StringName = _parent[id]
	while at != &"":
		if at == ancestor:
			return true
		at = _parent[at]
	return false


## The vine from node `id` to `required`, along the limbs and the trunk.
func _vine_path(id: StringName, required: StringName) -> PackedVector2Array:
	if _grows_from(id, required) or (_on_trunk[id] and _on_trunk[required]):
		return _stem(id, required)
	var path := _stem(id)
	var back := _stem(required)
	back.reverse()
	path.append_array(back)
	return path


# --- Drawing -----------------------------------------------------------------------


func _draw() -> void:
	_draw_sky()
	_draw_hills()
	_draw_canopy()
	_draw_ground()
	_draw_trunk()
	for id: StringName in _limbs:
		var lit := tree.level(id) > 0
		var from_trunk: bool = _parent[id] == &""
		_draw_strip(_limbs[id], LIMB_ROOT if from_trunk else LIMB_TIP + 2.0, LIMB_TIP, BARK_COLOR)
		if lit:
			draw_polyline(_limbs[id], Color(LIGHT, 0.55), 2.0, true)
	_draw_vines()
	_draw_leaves()
	for id: StringName in centers:
		if not tree.node(id).level_sum_ids.is_empty():
			_draw_ring(id)
	if views.has(EQUIP_ID):
		_draw_equip_preview(centers[EQUIP_ID])
	if views.has(BACKPACK_ID):
		_draw_backpack_preview(centers[BACKPACK_ID])
	_draw_group_captions()
	_draw_header()
	_draw_frame()


func _draw_sky() -> void:
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(SIZE.x, 0), SIZE, Vector2(0, SIZE.y)]),
		PackedColorArray([SKY_TOP, SKY_TOP, SKY_BOTTOM, SKY_BOTTOM]))
	var rng := _rng(1)
	for i in 120:
		var at := Vector2(rng.randf_range(0.0, SIZE.x), rng.randf_range(0.0, SIZE.y * 0.62))
		var alpha := rng.randf_range(0.05, 0.32) * (1.0 - at.y / SIZE.y)
		draw_rect(Rect2(at, Vector2.ONE * rng.randf_range(1.0, 2.2)), Color(STAR_COLOR, alpha))
	var glow := JourneyMap.glow()
	# The moon and its halo, and the tree's own light around its crown.
	draw_texture_rect(glow, Rect2(MOON_AT - Vector2(330, 260), Vector2(660, 520)), false, Color(0.55, 0.7, 0.85, 0.08))
	draw_texture_rect(glow, Rect2(MOON_AT - Vector2.ONE * MOON_RADIUS * 3.0, Vector2.ONE * MOON_RADIUS * 6.0), false, Color(MOON_COLOR, 0.22))
	draw_circle(MOON_AT, MOON_RADIUS, MOON_COLOR)
	for spot: Vector3 in [Vector3(-8, -6, 7), Vector3(9, 6, 5), Vector3(-2, 12, 4), Vector3(10, -10, 3)]:
		draw_circle(MOON_AT + Vector2(spot.x, spot.y), spot.z, Color(0.75, 0.72, 0.62, 0.45))
	draw_circle(MOON_AT + Vector2(9, -5), MOON_RADIUS * 0.92, Color(SKY_TOP, 0.12))
	var crown := Vector2(SIZE.x * 0.5, (_trunk_top + MIDDLE_Y) * 0.5)
	draw_texture_rect(glow, Rect2(crown - Vector2(640, 420), Vector2(1280, 840)), false, Color(LIGHT, 0.09))
	draw_texture_rect(glow, Rect2(crown - Vector2(300, 240), Vector2(600, 480)), false, Color(LIGHT, 0.06))


## Two rows of far hills with mist between them, and dark trees standing at
## both sides of the grove.
func _draw_hills() -> void:
	for layer in 2:
		if layer == 1:
			_draw_side_trees()
		var base := 600.0 + layer * 80.0
		var points := PackedVector2Array([Vector2(0, SIZE.y)])
		var x := 0.0
		while x <= SIZE.x:
			var rise := sin(x * 0.0042 + layer * 2.1) * 34.0 + sin(x * 0.011 + layer) * 14.0
			points.append(Vector2(x, base - rise))
			x += 24.0
		points.append(Vector2(SIZE.x, SIZE.y))
		draw_colored_polygon(points, HILL_FAR if layer == 0 else HILL_NEAR)
		var rng := _rng(20 + layer)
		for i in 5:
			var at := Vector2(rng.randf_range(0.0, SIZE.x), base - 10.0 + rng.randf_range(-20.0, 30.0))
			draw_texture_rect(JourneyMap.glow(), Rect2(at - Vector2(340, 50), Vector2(680, 100)), false, MIST_COLOR)


## Tall dark trees in the grove's corners, framing the page.
func _draw_side_trees() -> void:
	var rng := _rng(7)
	var blob := JourneyMap.blob()
	for side: float in [-1.0, 1.0]:
		for k in 3:
			var x := SIZE.x * 0.5 + side * (SIZE.x * 0.5 - 70.0 - k * 120.0 - rng.randf_range(-20.0, 20.0))
			var top := rng.randf_range(250.0, 380.0) + k * 70.0
			var foot := Vector2(x, 760.0)
			var height := foot.y - top
			draw_line(foot, Vector2(x + side * rng.randf_range(-12.0, 12.0), top), SILHOUETTE, 14.0 - k * 3.0, true)
			for leaf in 6:
				var at := Vector2(x + rng.randf_range(-70.0, 70.0), top + rng.randf_range(-20.0, height * 0.45))
				var radius := rng.randf_range(50.0, 90.0) * (1.0 - k * 0.15)
				draw_texture_rect(blob, Rect2(at - Vector2(radius, radius * 0.8), Vector2(radius * 2.0, radius * 1.6)), false, Color(SILHOUETTE, 0.9))


## Dark foliage behind the nodes, so the branch reads as one crown.
func _draw_canopy() -> void:
	var rng := _rng(3)
	var blob := JourneyMap.blob()
	for id: StringName in centers:
		var center: Vector2 = centers[id]
		for k in 3:
			var radius := rng.randf_range(100.0, 150.0)
			var at := center + Vector2(rng.randf_range(-60.0, 60.0), rng.randf_range(-60.0, 30.0))
			draw_texture_rect(blob, Rect2(at - Vector2(radius, radius * 0.85), Vector2(radius * 2.0, radius * 1.7)), false, CANOPY_COLOR)


## The grove's ground: a low mound under the trunk, with grass on its rim.
func _draw_ground() -> void:
	var rim := PackedVector2Array()
	var x := 0.0
	while x <= SIZE.x:
		var spread := (x - SIZE.x * 0.5) / 420.0
		rim.append(Vector2(x, GROUND_Y + 34.0 - 40.0 * exp(-spread * spread)))
		x += 12.0
	var fill := rim.duplicate()
	fill.append(SIZE)
	fill.append(Vector2(0, SIZE.y))
	draw_colored_polygon(fill, GROUND_COLOR)
	draw_polyline(rim, Color(0.45, 0.62, 0.55, 0.22), 2.0, true)
	var rng := _rng(4)
	for point in rim:
		for k in 2:
			var foot := point + Vector2(rng.randf_range(-6.0, 6.0), 2.0)
			var tip := foot + Vector2(rng.randf_range(-5.0, 5.0), -rng.randf_range(4.0, 12.0))
			draw_line(foot, tip, GRASS_COLOR, 2.0, true)


func _draw_trunk() -> void:
	var middle := SIZE.x * 0.5
	var base := Vector2(middle, GROUND_Y)
	var glow := JourneyMap.glow()
	var y := GROUND_Y
	while y > _trunk_top:
		draw_texture_rect(glow, Rect2(Vector2(middle, y) - Vector2(80, 90), Vector2(160, 180)), false, Color(LIGHT, 0.07))
		y -= 70.0
	# Roots, spreading over the mound.
	for side: float in [-1.0, -0.5, 0.15, 0.6, 1.0]:
		var reach := 150.0 * absf(side) + 30.0
		var end := base + Vector2(signf(side) * reach, 30.0 + absf(side) * 12.0)
		var bend := base + Vector2(signf(side) * reach * 0.35, 22.0)
		_draw_strip(_bezier(base + Vector2(side * 14.0, -20.0), bend, bend, end), 14.0, 3.0, BARK_COLOR)
	_draw_strip(PackedVector2Array([Vector2(middle, GROUND_Y + 12.0), Vector2(middle, _trunk_top)]), TRUNK_ROOT, TRUNK_TIP, BARK_COLOR, 12)
	# The light up its core.
	var core := PackedVector2Array([Vector2(middle, GROUND_Y), Vector2(middle, lerpf(GROUND_Y, _trunk_top, 0.5)), Vector2(middle, _trunk_top)])
	draw_polyline_colors(core, PackedColorArray([Color(LIGHT, 0.0), Color(LIGHT, 0.7), Color(LIGHT, 0.3)]), 3.0, true)
	draw_polyline_colors(core, PackedColorArray([Color(LIGHT, 0.0), Color(LIGHT, 0.16), Color(LIGHT, 0.06)]), 12.0, true)


## A tapered strip along `points`, `from_width` wide at its start and
## `to_width` at its end, lit on its left; `steps` splits a two-point line.
func _draw_strip(points: PackedVector2Array, from_width: float, to_width: float, color: Color, steps := 0) -> void:
	if steps > 0 and points.size() == 2:
		var split := PackedVector2Array()
		for i in steps + 1:
			split.append(points[0].lerp(points[1], float(i) / steps))
		points = split
	var count := points.size()
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var vertices := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for i in count:
		var along := (points[mini(i + 1, count - 1)] - points[maxi(i - 1, 0)]).normalized()
		var across := along.orthogonal() * lerpf(from_width, to_width, float(i) / (count - 1)) * 0.5
		left.append(points[i] + across)
		right.append(points[i] - across)
		vertices.append_array([points[i] + across, points[i] - across])
		colors.append_array([color.lightened(0.12), color.darkened(0.35)])
		if i > 0:
			var a := i * 2 - 2
			indices.append_array([a, a + 1, a + 2, a + 1, a + 3, a + 2])
	RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), indices, vertices, colors)
	draw_polyline(left, BARK_EDGE, 1.5, true)
	draw_polyline(right, BARK_EDGE, 1.5, true)


func _draw_vines() -> void:
	var phase := 0.0
	for id: StringName in centers:
		var data := tree.node(id)
		for required in data.requires:
			if centers.has(required):
				_draw_vine(_vine_path(id, required), tree.level(id) > 0, phase)
				phase += 1.3


## A vine winding along `path`, with small leaves; gold when `lit`.
func _draw_vine(path: PackedVector2Array, lit: bool, phase: float) -> void:
	var points := _resample(path, 5.0)
	var count := points.size()
	if count < 2:
		return
	var wavy := PackedVector2Array()
	var normals := PackedVector2Array()
	for i in count:
		var along := (points[mini(i + 1, count - 1)] - points[maxi(i - 1, 0)]).normalized()
		normals.append(along.orthogonal())
		wavy.append(points[i] + normals[i] * sin(i * 5.0 / VINE_WAVE * TAU + phase) * VINE_AMP)
	var color := VINE_LIT if lit else VINE_DIM
	if lit:
		draw_polyline(wavy, Color(LIGHT, 0.16), VINE_WIDTH + 7.0, true)
	draw_polyline(wavy, color, VINE_WIDTH, true)
	var every := int(VINE_LEAF_STEP / 5.0)
	for i in range(every, count - every, every):
		var side := 1.0 if (i / every) % 2 == 0 else -1.0
		var along := normals[i].orthogonal() * -1.0
		_draw_leaf(wavy[i], (along + normals[i] * side * 1.2).angle(), 10.0, color.darkened(0.1))


## `points` resampled every `step` px along the line.
static func _resample(points: PackedVector2Array, step: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	if points.is_empty():
		return out
	out.append(points[0])
	var carry := 0.0
	for i in range(1, points.size()):
		var from := points[i - 1]
		var length := from.distance_to(points[i])
		var at := step - carry
		while at <= length:
			out.append(from.lerp(points[i], at / length))
			at += step
		carry = length - (at - step)
	if out[-1] != points[-1]:
		out.append(points[-1])
	return out


## Faint leaves along the limbs and the top of the trunk, clear of the nodes.
func _draw_leaves() -> void:
	var rng := _rng(5)
	var sprays: Array[PackedVector2Array] = []
	for id: StringName in _limbs:
		sprays.append(_limbs[id])
	sprays.append(PackedVector2Array([Vector2(SIZE.x * 0.5, lerpf(GROUND_Y, _trunk_top, 0.55)), Vector2(SIZE.x * 0.5, _trunk_top)]))
	for spray in sprays:
		for at in _resample(spray, 22.0):
			if rng.randf() < 0.45:
				continue
			var offset := Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(12.0, 30.0)
			var leaf := at + offset
			if _near_node(leaf):
				continue
			var color := LEAF_COLOR if rng.randf() < 0.5 else LEAF_DARK
			_draw_leaf(leaf, offset.angle() + rng.randf_range(-0.5, 0.5), rng.randf_range(9.0, 15.0), Color(color, rng.randf_range(0.45, 0.8)))


## A leaf from `at`, pointing at `angle`.
func _draw_leaf(at: Vector2, angle: float, length: float, color: Color) -> void:
	var along := Vector2.from_angle(angle)
	var across := along.orthogonal()
	var points := PackedVector2Array()
	for k in 5:
		var t := k / 4.0
		points.append(at + along * length * t + across * sin(PI * t) * length * 0.32)
	for k in range(3, 0, -1):
		var t := k / 4.0
		points.append(at + along * length * t - across * sin(PI * t) * length * 0.32)
	draw_colored_polygon(points, color)


## Inside a node's frame, badge or name.
func _near_node(at: Vector2) -> bool:
	for id: StringName in centers:
		var center: Vector2 = centers[id]
		if Rect2(center - Vector2(CELL.x * 0.5 - 4.0, 60.0), Vector2(CELL.x - 8.0, 156.0)).has_point(at):
			return true
	return false


## The segmented ring of node `id`'s level sum: one segment per rank,
## lit up to the current total, with a mark where each level opens.
func _draw_ring(id: StringName) -> void:
	var data := tree.node(id)
	var center: Vector2 = centers[id]
	var marks := data.level_sums
	var ticks: int = marks[-1]
	var total := tree.level_sum(id)
	var start := PI * 0.5 + RING_GAP * 0.5
	var step := (TAU - RING_GAP) / ticks
	var lit := minf(float(total) / ticks, 1.0)
	draw_texture_rect(JourneyMap.glow(), Rect2(center - Vector2.ONE * RING_RADIUS * 1.6, Vector2.ONE * RING_RADIUS * 3.2), false, Color(LIGHT, 0.06 + 0.16 * lit))
	draw_arc(center, RING_RADIUS, start, start + TAU - RING_GAP, 64, Color(0, 0, 0, 0.55), RING_WIDTH + 5.0, true)
	for k in ticks:
		var from := start + k * step + 0.035
		var color := UiStyle.GOLD_COLOR if k < total else RING_DIM
		draw_arc(center, RING_RADIUS, from, start + (k + 1) * step - 0.035, 8, color, RING_WIDTH, true)
	var font := get_theme_default_font()
	for mark: int in marks:
		var direction := Vector2.from_angle(start + mark * step)
		var reached := total >= mark
		var color := UiStyle.TITLE_COLOR if reached else UiStyle.DIM_COLOR
		var tip := center + direction * (RING_RADIUS + RING_WIDTH * 0.5 + 2.0)
		var across := direction.orthogonal() * 5.0
		draw_colored_polygon(PackedVector2Array([tip, tip + direction * 7.0 + across, tip + direction * 14.0, tip + direction * 7.0 - across]),
			UiStyle.GOLD_COLOR if reached else RING_DIM.lightened(0.3))
		var text := str(mark)
		var label_at := center + direction * (RING_RADIUS + 30.0)
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, RING_FONT).x
		_draw_text(text, label_at + Vector2(-width * 0.5, font.get_ascent(RING_FONT) * 0.4), RING_FONT, color)


## Under Equip Slots: the six equip slots, open ones lit, the next level's
## slot outlined when it is open to buy, the others locked, and the act each
## one needs.
func _draw_equip_preview(center: Vector2) -> void:
	var data := tree.node(EQUIP_ID)
	var level := tree.level(EQUIP_ID)
	var open := roundi(data.value(level))
	var next := roundi(data.value(level + 1)) if tree.next_level_open(data.id) else open
	var all := roundi(data.value(data.max_level))
	var plaque := _draw_plaque(center, "EQUIP SLOTS", "%d / %d" % [open, all])
	var width := all * SLOT_SIZE + (all - 1) * SLOT_GAP
	var left := Vector2(center.x - width * 0.5, plaque.position.y + 66.0)
	for i in all:
		var rect := Rect2(left + Vector2(i * (SLOT_SIZE + SLOT_GAP), 0), Vector2.ONE * SLOT_SIZE)
		_draw_slot(rect, i < open, i >= open and i < next)
		if i >= next:
			draw_texture_rect(LOCK, Rect2(rect.get_center() - Vector2.ONE * 10.0, Vector2.ONE * 20.0), false, Color(1, 1, 1, 0.75))
	# The act each slot's level needs, under a bracket per act.
	var font := get_theme_default_font()
	var i := 1
	while i < all:
		var act := data.act_needed(i - 1)
		var last := i
		while last + 1 < all and data.act_needed(last) == act:
			last += 1
		if act > 0:
			var from_x := left.x + i * (SLOT_SIZE + SLOT_GAP)
			var to_x := left.x + last * (SLOT_SIZE + SLOT_GAP) + SLOT_SIZE
			var y := left.y + SLOT_SIZE + 10.0
			var cleared := tree.is_level_open(EQUIP_ID, i - 1)
			var color := TreeNodeView.MAXED_COLOR if cleared else JourneyPanel.CAPTION_COLOR
			draw_polyline(PackedVector2Array([Vector2(from_x + 2, y - 4), Vector2(from_x + 2, y), Vector2(to_x - 2, y), Vector2(to_x - 2, y - 4)]), Color(color, 0.7), 1.5, true)
			var text := "Act %d" % act
			var text_width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
			_draw_text(text, Vector2((from_x + to_x - text_width) * 0.5, y + 22.0), 16, color)
		i = last + 1
	_draw_text("Only equipped items give stats.", Vector2(plaque.position.x + 22.0, plaque.end.y - 20.0), 15, UiStyle.DIM_COLOR)


## Under Backpack Slots: the 9x6 backpack, its open cells lit and the next
## level's cells outlined when it is open to buy.
func _draw_backpack_preview(center: Vector2) -> void:
	var data := tree.node(BACKPACK_ID)
	var level := tree.level(BACKPACK_ID)
	var open := roundi(data.value(level))
	var next := roundi(data.value(level + 1)) if tree.next_level_open(data.id) else open
	var plaque := _draw_plaque(center, "BACKPACK", "%d / %d" % [open, Inventory.BACKPACK_SIZE])
	var width := MINI_COLUMNS * MINI_CELL + (MINI_COLUMNS - 1) * MINI_GAP
	var left := Vector2(center.x - width * 0.5, plaque.position.y + 46.0)
	for i in Inventory.BACKPACK_SIZE:
		var at := left + Vector2(i % MINI_COLUMNS, i / MINI_COLUMNS) * (MINI_CELL + MINI_GAP)
		_draw_slot(Rect2(at, Vector2.ONE * MINI_CELL), i < open, i >= open and i < next, 4)


## A plaque under a node, with a caption and a count; returns its rect.
func _draw_plaque(center: Vector2, caption: String, count: String) -> Rect2:
	var rect := Rect2(Vector2(center.x - PLAQUE_SIZE.x * 0.5, center.y + PLAQUE_TOP), PLAQUE_SIZE)
	var style := UiStyle.panel(PLAQUE_COLOR, Color(UiStyle.BORDER_COLOR, 0.55), 2, 0.0, 10)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 10
	draw_style_box(style, rect)
	_draw_text(caption, rect.position + Vector2(20.0, 30.0), 15, JourneyPanel.CAPTION_COLOR, 3)
	var font := get_theme_default_font()
	var width := font.get_string_size(count, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	_draw_text(count, rect.position + Vector2(PLAQUE_SIZE.x - 20.0 - width, 31.0), 18, UiStyle.TITLE_COLOR)
	return rect


## One slot of a preview: lit when open, outlined when the next level opens it.
func _draw_slot(rect: Rect2, open: bool, next: bool, radius := 6) -> void:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(radius)
	style.set_border_width_all(2)
	if open:
		style.bg_color = Color(UiStyle.GOLD_COLOR, 0.32)
		style.border_color = UiStyle.GOLD_COLOR
	elif next:
		style.bg_color = Color(UiStyle.GOLD_COLOR, 0.07)
		style.border_color = Color(UiStyle.GOLD_COLOR, 0.45)
	else:
		style.bg_color = Color(1, 1, 1, 0.03)
		style.border_color = Color(1, 1, 1, 0.1)
	draw_style_box(style, rect)


## Each captioned limb's name over its top node, between two small diamonds.
func _draw_group_captions() -> void:
	var font := _font(3)
	for limb: Dictionary in LIMBS.get(branch, []):
		if not limb.has("label"):
			continue
		var top := Vector2(0, INF)
		for id: StringName in limb["ids"]:
			if centers[id].y < top.y:
				top = centers[id]
		var text: String = limb["label"]
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, GROUP_FONT).x
		var baseline := Vector2(top.x - width * 0.5, top.y - TreeNodeView.SIZE * 0.5 - GROUP_LIFT)
		_draw_text(text, baseline, GROUP_FONT, JourneyPanel.CAPTION_COLOR, 3)
		for side: float in [-1.0, 1.0]:
			var at := Vector2(top.x + side * (width * 0.5 + 16.0), baseline.y - GROUP_FONT * 0.35)
			draw_colored_polygon(PackedVector2Array([at + Vector2(0, -4), at + Vector2(4, 0), at + Vector2(0, 4), at + Vector2(-4, 0)]), JourneyPanel.CAPTION_COLOR)


func _draw_header() -> void:
	_draw_text("EVOLUTION TREE", HEADER_AT, CAPTION_FONT, JourneyPanel.CAPTION_COLOR, 3)
	_draw_text(String(NAMES[branch]).to_upper(), HEADER_AT + Vector2(0, 40), TITLE_FONT, UiStyle.TITLE_COLOR, 4)
	_draw_text(BLURBS[branch], HEADER_AT + Vector2(0, 70), BLURB_FONT, UiStyle.DIM_COLOR)


## The gold frame, open on the right where the info column stands.
func _draw_frame() -> void:
	var outer := StyleBoxFlat.new()
	outer.draw_center = false
	outer.border_color = FRAME_COLOR
	outer.set_border_width_all(2)
	outer.border_width_right = 0
	outer.corner_radius_top_left = 10
	outer.corner_radius_bottom_left = 10
	draw_style_box(outer, Rect2(Vector2.ZERO, SIZE))
	draw_rect(Rect2(Vector2.ONE * FRAME_INSET, SIZE - Vector2(FRAME_INSET, FRAME_INSET * 2.0)), FRAME_INNER, false, 1.0)
	for corner: Vector2 in [Vector2(FRAME_INSET, FRAME_INSET), Vector2(FRAME_INSET, SIZE.y - FRAME_INSET)]:
		draw_colored_polygon(PackedVector2Array([corner + Vector2(0, -6), corner + Vector2(6, 0), corner + Vector2(0, 6), corner + Vector2(-6, 0)]), FRAME_COLOR)


func _draw_motes() -> void:
	var glow := JourneyMap.glow()
	var height := GROUND_Y + 20.0
	for mote in _mote_seeds:
		var speed := MOTE_SPEED * (0.6 + mote.z)
		var at := Vector2(mote.x + sin(_time * 0.5 + mote.z * 9.0) * 14.0, fposmod(mote.y - _time * speed, height))
		var alpha := 0.35 + 0.3 * sin(_time * 1.3 + mote.z * 20.0)
		_motes.draw_texture_rect(glow, Rect2(at - Vector2.ONE * 9.0, Vector2.ONE * 18.0), false, Color(LIGHT, alpha * 0.45))
		_motes.draw_circle(at, 1.6, Color(LIGHT, alpha))


## `text` with its baseline at `at`, outlined; `spacing` spreads capitals.
func _draw_text(text: String, at: Vector2, font_size: int, color: Color, spacing := 0) -> void:
	var font := _font(spacing)
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 5, TEXT_OUTLINE)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


## The default font, its capitals spread by `spacing` px.
func _font(spacing := 0) -> Font:
	if spacing == 0:
		return get_theme_default_font()
	if _spaced_font == null:
		_spaced_font = FontVariation.new()
		_spaced_font.base_font = get_theme_default_font()
	_spaced_font.spacing_glyph = spacing
	return _spaced_font


func _rng(salt: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = salt * 31 + EvolutionTree.BRANCHES.find(branch)
	return rng

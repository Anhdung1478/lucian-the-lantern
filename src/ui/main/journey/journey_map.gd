class_name JourneyMap
extends Control
## The Journey's world map, drawn in code on dark parchment: the six act
## regions along one winding stone road (a Curve2D through every stage in
## play order), Training beside 1-1 and the Endless portal in the
## bottom-right corner, off the road. The road glows gold up to the latest
## cleared stage and is dim beyond; a locked act lies under fog with a chain;
## Lucian's token (the equipped skin's portrait) floats over the next stage.
## A click on an open place emits `node_chosen`. Nothing here saves.

## An open place was clicked.
signal node_chosen(node: JourneyNode)

const SIZE := Vector2(1416, 904)
## Stage id -> its medallion's center. Rows: Acts 1–3 left to right, Act 4
## right to left, Acts 5–6 left to right.
const NODES := {
	"1-1": Vector2(234, 200),
	"2-1": Vector2(398, 254), "2-2": Vector2(502, 172), "2-3": Vector2(620, 258),
	"3-1": Vector2(772, 172), "3-2": Vector2(880, 258), "3-3": Vector2(988, 172), "3-4": Vector2(1096, 258), "3-5": Vector2(1258, 200),
	"4-1": Vector2(1218, 470), "4-2": Vector2(862, 492), "4-3": Vector2(500, 466),
	"5-1": Vector2(110, 716), "5-2": Vector2(222, 812), "5-3": Vector2(336, 716), "5-4": Vector2(450, 812), "5-5": Vector2(574, 734),
	"6-1": Vector2(698, 816), "6-2": Vector2(802, 724), "6-3": Vector2(906, 816), "6-4": Vector2(1010, 724), "6-5": Vector2(1136, 800),
}
const TRAINING_AT := Vector2(88, 262)
const ENDLESS_AT := Vector2(1314, 736)
## The road in play order: stage ids, and the bends where it changes rows.
const ROAD := [
	"1-1", "2-1", "2-2", "2-3", "3-1", "3-2", "3-3", "3-4", "3-5", Vector2(1352, 340),
	"4-1", "4-2", "4-3", Vector2(150, 548),
	"5-1", "5-2", "5-3", "5-4", "5-5", "6-1", "6-2", "6-3", "6-4", "6-5",
]
## How round the road bends: a handle's share of the shorter side's length.
const ROAD_CURVE := 0.42
## Per act: `area` (its hover area and the fog's reach), `blobs` (the soft
## ellipses of its ground), its ground `color`, the panel's `accent`, where
## its name goes and where the fog's lock hangs.
const REGIONS := [
	{"area": Rect2(16, 16, 320, 324), "blobs": [Rect2(-30, -20, 400, 390), Rect2(40, 120, 300, 250)],
		"color": Color("26361f"), "accent": Color("6fae5a"), "name_at": Vector2(40, 30), "lock_at": Vector2(232, 290)},
	{"area": Rect2(336, 16, 352, 324), "blobs": [Rect2(316, -20, 400, 380)],
		"color": Color("2a3039"), "accent": Color("8aa4c8"), "name_at": Vector2(372, 30), "lock_at": Vector2(452, 212)},
	{"area": Rect2(688, 16, 712, 324), "blobs": [Rect2(664, -20, 430, 380), Rect2(950, -20, 490, 390)],
		"color": Color("15301f"), "accent": Color("4fbf6a"), "name_at": Vector2(740, 30), "lock_at": Vector2(1042, 214)},
	{"area": Rect2(300, 340, 1100, 220), "blobs": [Rect2(270, 318, 560, 270), Rect2(690, 306, 740, 290)],
		"color": Color("271b3d"), "accent": Color("9467d0"), "name_at": Vector2(930, 366), "lock_at": Vector2(680, 480)},
	{"area": Rect2(16, 560, 624, 328), "blobs": [Rect2(-30, 540, 400, 390), Rect2(270, 546, 400, 380)],
		"color": Color("15302d"), "accent": Color("4fb8a4"), "name_at": Vector2(190, 570), "lock_at": Vector2(280, 764)},
	{"area": Rect2(640, 560, 580, 328), "blobs": [Rect2(618, 546, 380, 380), Rect2(890, 540, 360, 390)],
		"color": Color("070c0a"), "accent": Color("62e0a0"), "name_at": Vector2(680, 570), "lock_at": Vector2(958, 770)},
]
## The parchment and its frame.
const PARCHMENT := Color("15130f")
const STAIN_LIGHT := Color(0.32, 0.27, 0.18, 0.09)
const STAIN_DARK := Color(0.0, 0.0, 0.0, 0.16)
const FRAME_COLOR := Color(0.79, 0.64, 0.36, 0.85)
const FRAME_INNER := Color(0.79, 0.64, 0.36, 0.28)
const FRAME_INSET := 7.0
## The road: its dark edge, stone and cobbles, dim and lit.
const ROAD_EDGE := Color(0.03, 0.025, 0.02, 0.9)
const ROAD_DIM := Color("332f29")
const ROAD_LIT := Color("b8913f")
const ROAD_LIT_CORE := Color(1.0, 0.91, 0.66, 0.85)
const ROAD_WIDTH := 16.0
const ROAD_EDGE_WIDTH := 24.0
const COBBLE_STEP := 13.0
## The region names: the act line and the name, in spaced capitals.
const ACT_FONT := 15
const NAME_FONT := 25
const NAME_COLOR := UiStyle.TITLE_COLOR
const ACT_COLOR := Color("c9a45c")
const FOGGED_NAME := Color(0.56, 0.57, 0.62)
const NAME_OUTLINE := Color(0.02, 0.02, 0.02, 0.9)
## The fog over a locked act, and its chain and lock.
const FOG_COLOR := Color(0.025, 0.025, 0.035, 0.84)
const FOG_WISP := Color(0.62, 0.64, 0.72, 0.05)
const FOG_GROWTH := 24.0
const CHAIN_COLOR := Color("7d848e")
const CHAIN_REACH := Vector2(92, 34)
const FOG_LOCK_RADIUS := 26.0
const LOCK := preload("res://assets/art/ui/lock.svg")
const LANTERN := preload("res://assets/art/ui/title_lantern.svg")
## Lucian's token: its size, how far over the medallion it floats, its bob.
const TOKEN_SIZE := 48.0
const TOKEN_LIFT := 38.0
const TOKEN_BOB := 4.0
const TOKEN_BOB_SPEED := 2.4
const TOKEN_RING := UiStyle.GOLD_COLOR
## The compass rose, where the road turns from Act 4 down to Act 5.
const COMPASS_AT := Vector2(100, 428)
## Act 1's river, from the top edge past 1-1 (Thresh rises from it): a
## curve's ends and its pull.
const RIVER := [Vector2(268, 14), Vector2(186, 200), Vector2(322, 342)]
## Act 6: chains hanging into the abyss (top, length), and the lantern
## hanging from its own.
const HANGING_CHAINS := [Vector3(1068, 590, 84), Vector3(1192, 600, 60)]
const LANTERN_AT := Vector2(950, 650)
const LANTERN_SIZE := 56.0
## The soft glows and blobs, and round art's sides.
const GLOW_SIZE := 128
const ROUND_SIDES := 40

static var _glow: GradientTexture2D
static var _blob: GradientTexture2D

## The 22 stages, in play order.
var nodes: Array[JourneyNode] = []
var training := JourneyNode.landmark(JourneyNode.TRAINING)
var endless := JourneyNode.landmark(JourneyNode.ENDLESS)
## Per act: the region's hover area; a fogged one says what to clear.
var regions: Array[Control] = []
var road := Curve2D.new()
## The latest cleared stage, which the road glows up to ("" for none), and
## that glow's length along the road.
var lit_stage := ""
var lit_offset := 0.0
## The stage Lucian's token floats over: the first open one not yet cleared
## (null once every stage is).
var token_node: JourneyNode
var token := Control.new()
## The equipped skin's portrait, on the token.
var token_texture: Texture2D

var _by_id := {}
var _fogged: Array[bool] = [false, false, false, false, false, false]
## Drawn over the places: the fog, the region names and the frame.
var _overlay := Control.new()
var _token_base := Vector2.ZERO
var _time := 0.0
## The default font with its capitals spread, for the region names.
var _spaced_font: FontVariation


func _init() -> void:
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_road()
	for act in Journey.ACTS.size():
		var area := Control.new()
		var rect: Rect2 = REGIONS[act]["area"]
		area.position = rect.position
		area.size = rect.size
		area.mouse_filter = Control.MOUSE_FILTER_PASS
		add_child(area)
		regions.append(area)
	training.place(TRAINING_AT)
	_add_place(training)
	for act in range(1, Journey.ACTS.size() + 1):
		for stage in range(1, Journey.stage_count(act) + 1):
			var node := JourneyNode.for_stage(act, stage)
			node.place(NODES[node.stage_id])
			_add_place(node)
			nodes.append(node)
			_by_id[node.stage_id] = node
	endless.place(ENDLESS_AT)
	_add_place(endless)
	_overlay.size = SIZE
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)
	token.size = Vector2(TOKEN_SIZE + 16.0, TOKEN_SIZE + 28.0)
	token.mouse_filter = Control.MOUSE_FILTER_IGNORE
	token.draw.connect(_draw_token)
	add_child(token)


func _process(delta: float) -> void:
	_time += delta
	token.position = _token_base + Vector2(0, sin(_time * TOKEN_BOB_SPEED) * TOKEN_BOB)


## The stage with this id, or null.
func node_for(stage_id: String) -> JourneyNode:
	return _by_id.get(stage_id)


## True while `act` is locked: its region lies under the fog.
func is_fogged(act: int) -> bool:
	return _fogged[act - 1]


## Locks, opens and marks every place from these cleared stages; Endless
## shows `best`; the token wears `portrait`.
func refresh(cleared: Array[String], best: int, portrait: Texture2D) -> void:
	for act in range(1, Journey.ACTS.size() + 1):
		_fogged[act - 1] = not Journey.is_act_open(act, cleared)
		if _fogged[act - 1]:
			regions[act - 1].set_meta(&"hover_text", "Clear Act %d first" % (act - 1))
		elif regions[act - 1].has_meta(&"hover_text"):
			regions[act - 1].remove_meta(&"hover_text")
	lit_stage = ""
	token_node = null
	for node in nodes:
		var open := Journey.is_stage_open(node.act, node.stage, cleared)
		node.set_state(not open, is_fogged(node.act), node.stage_id in cleared)
		if node.cleared:
			lit_stage = node.stage_id
		if token_node == null and open and not node.cleared:
			token_node = node
	training.set_state(false, false, false)
	endless.set_state(not Journey.is_endless_open(cleared), false, false)
	endless.set_best(best)
	lit_offset = road.get_closest_offset(node_for(lit_stage).center) if lit_stage != "" else 0.0
	token_texture = portrait
	token.visible = token_node != null
	set_process(token.visible)
	if token_node:
		_token_base = token_node.center - Vector2(token.size.x * 0.5, TOKEN_SIZE * 0.5 + 8.0 + token_node.radius() + TOKEN_LIFT)
		token.position = _token_base
	queue_redraw()
	_overlay.queue_redraw()
	token.queue_redraw()


## Lights `node` (white outline) and no other place.
func select(node: JourneyNode) -> void:
	for place in places():
		place.set_selected(place == node)


## Every place: the stages, Training and Endless.
func places() -> Array[JourneyNode]:
	var found: Array[JourneyNode] = []
	found.assign(nodes)
	found.append(training)
	found.append(endless)
	return found


## A white radial glow that fades from its middle to its edge; a draw call's
## modulate tints it.
static func glow() -> Texture2D:
	if _glow == null:
		_glow = _radial(PackedFloat32Array([0.0, 1.0]), PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)]))
	return _glow


## A soft blob: solid in its middle, fading out over its outer half.
static func blob() -> Texture2D:
	if _blob == null:
		_blob = _radial(PackedFloat32Array([0.0, 0.5, 1.0]), PackedColorArray([Color.WHITE, Color(1, 1, 1, 0.92), Color(1, 1, 1, 0)]))
	return _blob


## Draws `texture` cropped to a circle of `radius` at `center` on `canvas`;
## `zoom` above 1 crops closer to the art's middle.
static func draw_round_art(canvas: CanvasItem, texture: Texture2D, center: Vector2, radius: float, zoom := 1.0, tint := Color.WHITE) -> void:
	var points := PackedVector2Array()
	var uvs := PackedVector2Array()
	for i in ROUND_SIDES:
		var direction := Vector2.from_angle(TAU * i / ROUND_SIDES)
		points.append(center + direction * radius)
		uvs.append(Vector2(0.5, 0.5) + direction * (0.5 / zoom))
	canvas.draw_polygon(points, PackedColorArray([tint]), uvs, texture)


## A chain from `from` to `to`: flat links (ovals) and edge-on links (bars)
## in turn, each with a dark outline.
static func draw_chain(canvas: CanvasItem, from: Vector2, to: Vector2, color: Color, link := 22.0, width := 4.0) -> void:
	var length := from.distance_to(to)
	if length < link:
		return
	var along := (to - from) / length
	var across := along.orthogonal()
	var step := link * 0.74
	var dark := Color(0.02, 0.02, 0.025, color.a)
	var count := int((length - link) / step) + 1
	for i in count:
		var middle := from + along * (link * 0.5 + i * step)
		if i % 2 == 0:
			var oval := PackedVector2Array()
			for k in 17:
				var angle := TAU * k / 16.0
				oval.append(middle + along * cos(angle) * link * 0.5 + across * sin(angle) * link * 0.27)
			canvas.draw_polyline(oval, dark, width + 3.0, true)
			canvas.draw_polyline(oval, color, width, true)
		else:
			var half := along * link * 0.46
			canvas.draw_line(middle - half, middle + half, dark, width + 4.0, true)
			canvas.draw_line(middle - half, middle + half, color.lightened(0.15), width + 1.0, true)


static func _radial(offsets: PackedFloat32Array, colors: PackedColorArray) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = offsets
	gradient.colors = colors
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = GLOW_SIZE
	texture.height = GLOW_SIZE
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture


func _add_place(place: JourneyNode) -> void:
	place.chosen.connect(func() -> void: node_chosen.emit(place))
	add_child(place)


## The road through every ROAD point, its bends rounded: each point's handles
## run along the line from the point before to the point after.
func _build_road() -> void:
	var points: Array[Vector2] = []
	for entry: Variant in ROAD:
		points.append(NODES[entry] if entry is String else entry)
	for i in points.size():
		var before := points[maxi(i - 1, 0)]
		var after := points[mini(i + 1, points.size() - 1)]
		var reach := minf(points[i].distance_to(before), points[i].distance_to(after))
		if i == 0 or i == points.size() - 1:
			reach = maxf(points[i].distance_to(before), points[i].distance_to(after))
		var handle := (after - before).normalized() * reach * ROAD_CURVE
		road.add_point(points[i], -handle, handle)


## The road's points from `from` to `to` along it.
func _road_points(from: float, to: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var at := from
	while at < to:
		points.append(road.sample_baked(at))
		at += 6.0
	points.append(road.sample_baked(to))
	return points


# --- Drawing -----------------------------------------------------------------------


func _draw() -> void:
	_draw_parchment()
	for act in REGIONS.size():
		for rect: Rect2 in REGIONS[act]["blobs"]:
			draw_texture_rect(blob(), rect, false, REGIONS[act]["color"])
	_draw_endless_corner()
	_draw_compass(COMPASS_AT)
	_draw_loss()
	_draw_sentinels()
	_draw_jungle()
	_draw_darkness()
	_draw_shadow_isles()
	_draw_lantern()
	_draw_training_path()
	_draw_road()


func _draw_parchment() -> void:
	draw_rect(Rect2(Vector2.ZERO, SIZE), PARCHMENT)
	var rng := _rng(11)
	for i in 18:
		var radius := rng.randf_range(120.0, 320.0)
		var at := Vector2(rng.randf_range(0.0, SIZE.x), rng.randf_range(0.0, SIZE.y))
		draw_texture_rect(glow(), Rect2(at - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), false, STAIN_LIGHT if i % 2 == 0 else STAIN_DARK)
	for i in 700:
		var at := Vector2(rng.randf_range(0.0, SIZE.x), rng.randf_range(0.0, SIZE.y))
		draw_rect(Rect2(at, Vector2.ONE * rng.randf_range(1.0, 2.0)), Color(0.9, 0.8, 0.6, rng.randf_range(0.02, 0.06)))


## The green-purple haze around the Endless portal's corner.
func _draw_endless_corner() -> void:
	draw_texture_rect(blob(), Rect2(1190, 560, 260, 360), false, Color("1d1430"))
	draw_texture_rect(glow(), Rect2(ENDLESS_AT - Vector2(150, 150), Vector2(300, 300)), false, Color(0.45, 0.3, 0.8, 0.18))
	draw_texture_rect(glow(), Rect2(ENDLESS_AT - Vector2(100, 120), Vector2(200, 240)), false, Color(0.3, 0.85, 0.6, 0.08))


## A compass rose where the road turns from Act 4 down to Act 5.
func _draw_compass(at: Vector2) -> void:
	var line := Color(0.79, 0.64, 0.36, 0.45)
	draw_arc(at, 46.0, 0.0, TAU, 64, line, 1.5, true)
	draw_arc(at, 40.0, 0.0, TAU, 64, Color(line, 0.25), 1.0, true)
	for i in 8:
		var direction := Vector2.from_angle(TAU * i / 8.0 - PI * 0.5)
		var length := 52.0 if i % 2 == 0 else 30.0
		var side := direction.orthogonal() * (9.0 if i % 2 == 0 else 6.0)
		var tip := at + direction * length
		draw_colored_polygon(PackedVector2Array([at, at + side, tip]), Color(0.79, 0.64, 0.36, 0.55))
		draw_colored_polygon(PackedVector2Array([at, tip, at - side]), Color(0.25, 0.2, 0.12, 0.7))
	draw_circle(at, 4.0, Color(0.79, 0.64, 0.36, 0.8))
	_draw_text("N", at + Vector2(0, -58), 15, Color(0.79, 0.64, 0.36, 0.75), true)


## Act 1: the lane from bottom-left to top-right, the river across it.
func _draw_loss() -> void:
	var rng := _rng(1)
	_soft_band(Vector2(0, 336), Vector2(352, 40), 52.0, Color(0.36, 0.32, 0.26, 0.5))
	_soft_band(Vector2(0, 336), Vector2(352, 40), 30.0, Color(0.42, 0.37, 0.3, 0.35))
	var river := PackedVector2Array()
	var colors := PackedColorArray()
	for i in 41:
		var t := i / 40.0
		var at: Vector2 = RIVER[0].lerp(RIVER[1], t).lerp(RIVER[1].lerp(RIVER[2], t), t)
		river.append(at + Vector2(1, 0) * sin(t * TAU * 1.6) * 9.0)
		colors.append(Color(0.18, 0.37, 0.53, sin(PI * t) * 0.95))
	draw_polyline_colors(river, colors, 16.0, true)
	for i in colors.size():
		colors[i] = Color(0.44, 0.7, 0.85, colors[i].a * 0.6)
	draw_polyline_colors(river, colors, 3.0, true)
	for i in 14:
		var at := Vector2(rng.randf_range(30.0, 320.0), rng.randf_range(40.0, 330.0))
		if _near_road(at, 44.0) or at.distance_to(TRAINING_AT) < 70.0 or _near_lane(at):
			continue
		_draw_tree_clump(at, rng, 0.8)


## Act 2: a tiled training ground and its pillars.
func _draw_sentinels() -> void:
	var middle := Vector2(512, 196)
	var radii := Vector2(168, 132)
	var tile := 22.0
	var y := middle.y - radii.y
	while y < middle.y + radii.y:
		var x := middle.x - radii.x
		while x < middle.x + radii.x:
			var d := ((Vector2(x, y) - middle) / radii).length()
			if d < 1.0:
				var shade := Color("3c424c") if (int(x / tile) + int(y / tile)) % 2 == 0 else Color("343a43")
				draw_rect(Rect2(x + 1.5, y + 1.5, tile - 3.0, tile - 3.0), Color(shade, 0.7 * (1.0 - d * d)))
			x += tile
		y += tile
	for at: Vector2 in [Vector2(372, 108), Vector2(608, 108), Vector2(452, 304), Vector2(560, 318), Vector2(668, 168), Vector2(350, 186)]:
		draw_circle(at + Vector2(3, 5), 11.0, Color(0, 0, 0, 0.5))
		draw_circle(at, 11.0, Color("8a8478"))
		draw_circle(at + Vector2(-3, -3), 6.0, Color("a29c8f"))
		draw_arc(at, 11.0, 0.0, TAU, 24, Color("4f4b44"), 2.0, true)


## Act 3: dark jungle tree clumps, and the Elder Dragon's pit as its last stage.
func _draw_jungle() -> void:
	var rng := _rng(3)
	var pit: Vector2 = NODES["3-5"]
	for i in 70:
		var at := Vector2(rng.randf_range(700.0, 1390.0), rng.randf_range(80.0, 330.0))
		if _near_road(at, 40.0) or _near_node(at, 34.0) or at.distance_to(pit) < 104.0:
			continue
		_draw_tree_clump(at, rng, 1.0)
	draw_circle(pit + Vector2(0, 6), 88.0, Color(0, 0, 0, 0.45))
	draw_circle(pit, 86.0, Color("24221f"))
	draw_circle(pit, 76.0, Color("4a4540"))
	for ring: float in [64.0, 70.0]:
		draw_arc(pit, ring, 0.0, TAU, 64, Color(0.85, 0.8, 0.7, 0.12), 2.0, true)
	draw_texture_rect(glow(), Rect2(pit - Vector2(70, 70), Vector2(140, 140)), false, Color(0.55, 0.45, 0.95, 0.35))
	for i in 12:
		var at := pit + Vector2.from_angle(TAU * i / 12.0 + 0.2) * 84.0
		draw_circle(at, rng.randf_range(6.0, 10.0), Color("1a1917"))
		draw_circle(at + Vector2(-2, -2), 3.0, Color("3a3732"))


## Act 4: purple haze, dark shards and motes.
func _draw_darkness() -> void:
	var rng := _rng(4)
	for i in 14:
		var at := Vector2(rng.randf_range(330.0, 1380.0), rng.randf_range(350.0, 560.0))
		var radius := rng.randf_range(70.0, 150.0)
		var tint := Color(0.37, 0.26, 0.52, 0.22) if i % 3 != 0 else Color(0.03, 0.02, 0.06, 0.4)
		draw_texture_rect(glow(), Rect2(at - Vector2(radius * 1.4, radius), Vector2(radius * 2.8, radius * 2.0)), false, tint)
	for i in 16:
		var at := Vector2(rng.randf_range(330.0, 1380.0), rng.randf_range(360.0, 550.0))
		if _near_road(at, 34.0) or _near_node(at, 30.0):
			continue
		var tall := rng.randf_range(16.0, 30.0)
		var lean := rng.randf_range(-6.0, 6.0)
		draw_colored_polygon(PackedVector2Array([at + Vector2(-5, 0), at + Vector2(lean, -tall), at + Vector2(5, 0)]), Color("120d1c"))
		draw_line(at + Vector2(lean * 0.5, -tall * 0.5), at + Vector2(lean, -tall), Color(0.58, 0.4, 0.82, 0.5), 1.5, true)
	for i in 60:
		var at := Vector2(rng.randf_range(320.0, 1390.0), rng.randf_range(350.0, 556.0))
		draw_circle(at, rng.randf_range(1.0, 2.6), Color(0.62, 0.45, 0.9, rng.randf_range(0.25, 0.7)))


## Act 5: teal mist, dead trees and Karthus's graves.
func _draw_shadow_isles() -> void:
	var rng := _rng(5)
	for i in 12:
		var at := Vector2(rng.randf_range(20.0, 640.0), rng.randf_range(580.0, 880.0))
		var radius := rng.randf_range(60.0, 130.0)
		draw_texture_rect(glow(), Rect2(at - Vector2(radius * 1.5, radius), Vector2(radius * 3.0, radius * 2.0)), false, Color(0.3, 0.62, 0.56, 0.12))
	for i in 40:
		var at := Vector2(rng.randf_range(30.0, 630.0), rng.randf_range(640.0, 884.0))
		if _near_road(at, 40.0) or _near_node(at, 40.0) or at.y - 70.0 < 620.0:
			continue
		_draw_dead_tree(at, rng)
	var karthus: Vector2 = NODES["5-5"]
	for offset: Vector2 in [Vector2(-62, 64), Vector2(70, 58), Vector2(-24, 92), Vector2(30, 96)]:
		var at := karthus + offset
		draw_rect(Rect2(at - Vector2(6, 9), Vector2(12, 18)), Color("5d6560"))
		draw_circle(at - Vector2(0, 9), 6.0, Color("5d6560"))
		draw_line(at + Vector2(-2, -6), at + Vector2(-2, 4), Color("3b413e"), 1.5)


## Act 6: the abyss with green mist, chains hanging into it, the lantern's
## glow, rock islands under its stages and the round platform under 6-5.
func _draw_lantern() -> void:
	var rng := _rng(6)
	for i in 8:
		var at := Vector2(rng.randf_range(660.0, 1200.0), rng.randf_range(620.0, 870.0))
		draw_texture_rect(glow(), Rect2(at - Vector2(120, 80), Vector2(240, 160)), false, Color(0, 0, 0, 0.45))
	for i in 12:
		var at := Vector2(rng.randf_range(650.0, 1210.0), rng.randf_range(590.0, 880.0))
		draw_texture_rect(glow(), Rect2(at - Vector2(110, 60), Vector2(220, 120)), false, Color(0.3, 0.85, 0.55, 0.07))
	for chain: Vector3 in HANGING_CHAINS:
		draw_chain(self, Vector2(chain.x, chain.y), Vector2(chain.x, chain.y + chain.z), Color(0.28, 0.3, 0.32), 16.0, 3.0)
	for stage in range(1, Journey.stage_count(6)):
		var node := node_for(Journey.stage_id(6, stage))
		_draw_island(node.center, node.radius() + 14.0, rng)
	var platform: Vector2 = NODES["6-5"]
	draw_circle(platform + Vector2(0, 8), 82.0, Color(0, 0, 0, 0.6))
	draw_circle(platform, 80.0, Color("3a3f43"))
	draw_arc(platform, 80.0, 0.0, TAU, 72, Color("5d6560"), 3.0, true)
	draw_arc(platform, 70.0, 0.0, TAU, 72, Color("23282b"), 2.0, true)
	for i in 24:
		var from := TAU * i / 24.0
		draw_arc(platform, 64.0, from, from + TAU / 48.0, 4, Color(0.45, 1.0, 0.7, 0.55), 2.0, true)
	draw_chain(self, Vector2(LANTERN_AT.x, 566), LANTERN_AT - Vector2(0, LANTERN_SIZE * 0.42), Color(0.28, 0.3, 0.32), 14.0, 2.5)
	draw_texture_rect(glow(), Rect2(LANTERN_AT - Vector2(80, 80), Vector2(160, 160)), false, Color(0.4, 1.0, 0.7, 0.26))
	draw_texture_rect(LANTERN, Rect2(LANTERN_AT - Vector2.ONE * LANTERN_SIZE * 0.5, Vector2.ONE * LANTERN_SIZE), false)


## A ragged rock island in the abyss, under a stage.
func _draw_island(at: Vector2, radius: float, rng: RandomNumberGenerator) -> void:
	var outline := PackedVector2Array()
	for i in 14:
		outline.append(at + Vector2.from_angle(TAU * i / 14.0) * radius * rng.randf_range(0.88, 1.08))
	var shadow := PackedVector2Array()
	for point in outline:
		shadow.append(point + Vector2(0, 9))
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.6))
	draw_colored_polygon(outline, Color("2b3134"))
	outline.append(outline[0])
	draw_polyline(outline, Color("4f5a60"), 2.0, true)


## The dotted footpath from Training to 1-1.
func _draw_training_path() -> void:
	var from := TRAINING_AT + (NODES["1-1"] - TRAINING_AT).normalized() * (training.radius() + 6.0)
	var to: Vector2 = NODES["1-1"] - (NODES["1-1"] - TRAINING_AT).normalized() * 56.0
	var length := from.distance_to(to)
	var along := (to - from) / length
	var at := 0.0
	while at < length:
		draw_line(from + along * at, from + along * minf(at + 6.0, length), Color(0.79, 0.64, 0.36, 0.5), 3.0, true)
		at += 13.0


func _draw_road() -> void:
	var whole := road.get_baked_length()
	var all := _road_points(0.0, whole)
	draw_polyline(all, ROAD_EDGE, ROAD_EDGE_WIDTH, true)
	if lit_offset > 0.0:
		var lit := _road_points(0.0, lit_offset)
		draw_polyline(lit, Color(UiStyle.GOLD_COLOR, 0.12), ROAD_EDGE_WIDTH + 18.0, true)
		draw_polyline(lit, Color(UiStyle.GOLD_COLOR, 0.22), ROAD_EDGE_WIDTH + 6.0, true)
		draw_polyline(lit, ROAD_LIT, ROAD_WIDTH, true)
	if lit_offset < whole:
		draw_polyline(_road_points(lit_offset, whole), ROAD_DIM, ROAD_WIDTH, true)
	# Cobbles: small stones in two staggered rows.
	var at := COBBLE_STEP * 0.5
	var row := 0
	while at < whole:
		var here := road.sample_baked(at)
		var ahead := road.sample_baked(minf(at + 1.0, whole))
		var across := (ahead - here).normalized().orthogonal()
		var lit_here := at <= lit_offset
		var stone := Color(1.0, 0.86, 0.5, 0.55) if lit_here else Color(0.48, 0.44, 0.38, 0.55)
		draw_circle(here + across * (3.6 if row % 2 == 0 else -3.6), 2.6, stone)
		at += COBBLE_STEP * 0.5
		row += 1
	if lit_offset > 0.0:
		draw_polyline(_road_points(0.0, lit_offset), ROAD_LIT_CORE, 2.0, true)


## The fog over locked acts with their chains and locks, the region names
## and the frame: over the places.
func _draw_overlay() -> void:
	for act in REGIONS.size():
		if not _fogged[act]:
			continue
		var region: Dictionary = REGIONS[act]
		for rect: Rect2 in region["blobs"]:
			_overlay.draw_texture_rect(blob(), rect.grow(FOG_GROWTH), false, FOG_COLOR)
		var rng := _rng(40 + act)
		var area: Rect2 = region["area"]
		for i in 9:
			var at := area.position + Vector2(rng.randf(), rng.randf()) * area.size
			var radius := rng.randf_range(50.0, 110.0)
			_overlay.draw_texture_rect(glow(), Rect2(at - Vector2(radius * 1.6, radius), Vector2(radius * 3.2, radius * 2.0)), false, FOG_WISP)
		var lock_at: Vector2 = region["lock_at"]
		draw_chain(_overlay, lock_at - CHAIN_REACH, lock_at + CHAIN_REACH, CHAIN_COLOR)
		draw_chain(_overlay, lock_at + Vector2(-CHAIN_REACH.x, CHAIN_REACH.y), lock_at + Vector2(CHAIN_REACH.x, -CHAIN_REACH.y), CHAIN_COLOR)
		_overlay.draw_circle(lock_at + Vector2(0, 3), FOG_LOCK_RADIUS, Color(0, 0, 0, 0.6))
		_overlay.draw_circle(lock_at, FOG_LOCK_RADIUS, Color("15161a"))
		_overlay.draw_arc(lock_at, FOG_LOCK_RADIUS, 0.0, TAU, 40, CHAIN_COLOR, 2.5, true)
		_overlay.draw_texture_rect(LOCK, Rect2(lock_at - Vector2(17, 17), Vector2(34, 34)), false)
	for act in REGIONS.size():
		var at: Vector2 = REGIONS[act]["name_at"]
		var fogged := _fogged[act]
		_draw_text("ACT %d" % (act + 1), at + Vector2(0, ACT_FONT), ACT_FONT, FOGGED_NAME if fogged else ACT_COLOR, false, _overlay, 3)
		_draw_text(String(Journey.ACTS[act]["name"]).to_upper(), at + Vector2(0, ACT_FONT + 6.0 + NAME_FONT), NAME_FONT,
			FOGGED_NAME if fogged else NAME_COLOR, false, _overlay, 3)
	_draw_frame()


func _draw_frame() -> void:
	var outer := StyleBoxFlat.new()
	outer.draw_center = false
	outer.border_color = FRAME_COLOR
	outer.set_border_width_all(2)
	outer.border_width_right = 0
	outer.corner_radius_top_left = 10
	outer.corner_radius_bottom_left = 10
	_overlay.draw_style_box(outer, Rect2(Vector2.ZERO, SIZE))
	_overlay.draw_rect(Rect2(Vector2.ONE * FRAME_INSET, SIZE - Vector2(FRAME_INSET, FRAME_INSET * 2.0)), FRAME_INNER, false, 1.0)
	for corner: Vector2 in [Vector2(FRAME_INSET, FRAME_INSET), Vector2(FRAME_INSET, SIZE.y - FRAME_INSET)]:
		_overlay.draw_colored_polygon(PackedVector2Array([corner + Vector2(0, -6), corner + Vector2(6, 0), corner + Vector2(0, 6), corner + Vector2(-6, 0)]), FRAME_COLOR)


func _draw_token() -> void:
	if token_node == null:
		return
	var middle := Vector2(token.size.x * 0.5, TOKEN_SIZE * 0.5 + 8.0)
	var radius := TOKEN_SIZE * 0.5
	var tip := middle + Vector2(0, radius + 16.0)
	token.draw_colored_polygon(PackedVector2Array([middle + Vector2(-10, radius - 4), tip, middle + Vector2(10, radius - 4)]), TOKEN_RING.darkened(0.2))
	token.draw_texture_rect(glow(), Rect2(middle - Vector2.ONE * radius * 1.7, Vector2.ONE * radius * 3.4), false, Color(UiStyle.GOLD_COLOR, 0.35))
	token.draw_circle(middle + Vector2(0, 3), radius + 3.0, Color(0, 0, 0, 0.5))
	token.draw_circle(middle, radius + 3.0, TOKEN_RING)
	token.draw_circle(middle, radius, Color("1a1712"))
	if token_texture:
		draw_round_art(token, token_texture, middle, radius - 1.0, 1.0)
	token.draw_arc(middle, radius + 3.0, PI * 1.1, PI * 1.9, 24, Color(1, 0.95, 0.75, 0.9), 1.5, true)


## Draws `text` with its baseline at `at` (centered on it when `centered`),
## outlined, on `canvas` (the map by default); `spacing` spreads capitals.
func _draw_text(text: String, at: Vector2, font_size: int, color: Color, centered := false, canvas: CanvasItem = null, spacing := 0) -> void:
	var target := canvas if canvas else self
	var font: Font = get_theme_default_font()
	if spacing > 0:
		if _spaced_font == null or _spaced_font.spacing_glyph != spacing:
			_spaced_font = FontVariation.new()
			_spaced_font.base_font = font
			_spaced_font.spacing_glyph = spacing
		font = _spaced_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var start := at - Vector2(width * 0.5, 0) if centered else at
	target.draw_string_outline(font, start, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 5, NAME_OUTLINE)
	target.draw_string(font, start, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


## A wide soft band from `from` to `to`, fading in and out at its ends.
func _soft_band(from: Vector2, to: Vector2, half: float, color: Color) -> void:
	var across := (to - from).normalized().orthogonal() * half
	var stops: Array[float] = [0.0, 0.25, 0.75, 1.0]
	var alphas: Array[float] = [0.0, 1.0, 1.0, 0.0]
	for i in 3:
		var a := from.lerp(to, stops[i])
		var b := from.lerp(to, stops[i + 1])
		var ca := Color(color, color.a * alphas[i])
		var cb := Color(color, color.a * alphas[i + 1])
		draw_polygon(PackedVector2Array([a + across, b + across, b - across, a - across]), PackedColorArray([ca, cb, cb, ca]))


func _draw_tree_clump(at: Vector2, rng: RandomNumberGenerator, scale_by: float) -> void:
	var parts := rng.randi_range(2, 4)
	draw_circle(at + Vector2(4, 7) * scale_by, 20.0 * scale_by, Color(0, 0, 0, 0.35))
	for k in parts:
		var offset := Vector2(rng.randf_range(-12.0, 12.0), rng.randf_range(-8.0, 8.0)) * scale_by
		var radius := rng.randf_range(11.0, 18.0) * scale_by
		draw_circle(at + offset, radius, Color("16301d"))
		draw_circle(at + offset + Vector2(-3, -3) * scale_by, radius * 0.7, Color("1d3a24"))
		draw_arc(at + offset, radius, PI * 1.05, PI * 1.6, 10, Color("2f5a35"), 2.0, true)


func _draw_dead_tree(at: Vector2, rng: RandomNumberGenerator) -> void:
	var height := rng.randf_range(34.0, 58.0)
	var top := at + Vector2(rng.randf_range(-6.0, 6.0), -height)
	draw_line(at + Vector2(4, 2), top + Vector2(4, 2), Color(0, 0, 0, 0.4), 5.0, true)
	draw_line(at, top, Color("0f1312"), 4.0, true)
	for k in 3:
		var from := at.lerp(top, rng.randf_range(0.45, 0.9))
		var side := -1.0 if k % 2 == 0 else 1.0
		var tip := from + Vector2(side * rng.randf_range(10.0, 20.0), -rng.randf_range(8.0, 16.0))
		draw_line(from, tip, Color("141a18"), 2.0, true)
		draw_line(tip, tip + Vector2(side * 5.0, -6.0), Color("141a18"), 1.5, true)
	draw_line(at.lerp(top, 0.3), top, Color(0.3, 0.45, 0.42, 0.35), 1.0, true)


func _near_road(at: Vector2, margin: float) -> bool:
	return road.get_closest_point(at).distance_to(at) < margin


func _near_node(at: Vector2, margin: float) -> bool:
	for place in places():
		if place.center.distance_to(at) < place.radius() + margin:
			return true
	return false


## Inside Act 1's lane band.
func _near_lane(at: Vector2) -> bool:
	return Geometry2D.get_closest_point_to_segment(at, Vector2(0, 336), Vector2(352, 40)).distance_to(at) < 46.0


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng

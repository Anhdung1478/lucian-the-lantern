class_name TreeMap
extends Control
## The Evolution Tree as one forest: every grove grows from the same ground,
## with roots and a name under it, and lines from each node to the nodes it
## needs (gold once the node is bought). Left-drag pans, the wheel zooms
## around the cursor; a press that moves no more than DRAG_START is a click
## on the node under it. The map can never leave the screen.

const CELL := 150.0
const MARGIN := 160.0
const GROUND_Y := 620.0
const COLUMNS := 27
const MAP_SIZE := Vector2(MARGIN * 2.0 + COLUMNS * CELL, 760.0)
const DRAG_START := 6.0
const MIN_ZOOM := 0.6
const MAX_ZOOM := 1.4
const ZOOM_STEP := 0.1
## Where the soil starts, under the row 0 badges.
const GROUND_TOP := 688.0
const GROUND_COLOR := Color("2a1d14")
const GROUND_EDGE := Color("4a3423")
const ROOT_COLOR := Color("5a3e29")
const LINE_WIDTH := 4.0
const LINE_LIT := Color("ffcf5a")
const LINE_DIM := Color("3a4150")
const GROVE_FONT_SIZE := 22

## Node id -> TreeNodeView.
var views := {}
## The scale of the map, MIN_ZOOM to MAX_ZOOM.
var zoom := 1.0
## The Map control: it holds the views and the drawing, moved to pan and
## scaled to zoom.
var layer := Control.new()
var tree: EvolutionTree
## How far the map's right end may come in from the right edge, so the last
## grove can be dragged out from under the info panel.
var right_room := 0.0

var _pressed := false
var _dragging := false
var _press_at := Vector2.ZERO
var _last_at := Vector2.ZERO


func _init(evolution_tree: EvolutionTree, essences: Essences) -> void:
	tree = evolution_tree
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	layer.name = &"Map"
	layer.size = MAP_SIZE
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.draw.connect(_draw_map)
	add_child(layer)
	for data in tree.nodes():
		var view := TreeNodeView.new(data, tree, essences)
		view.position = node_center(data.grid) - Vector2.ONE * TreeNodeView.SIZE * 0.5
		layer.add_child(view)
		views[data.id] = view


func _ready() -> void:
	resized.connect(_clamp)
	# The Skills grove at the left edge, the ground at the bottom.
	layer.position = Vector2(0.0, size.y - MAP_SIZE.y)
	_clamp()


## A node's center on the map for its (column, row up from the ground).
static func node_center(grid: Vector2) -> Vector2:
	return Vector2(MARGIN + grid.x * CELL, GROUND_Y - grid.y * CELL)


## Redraws the views and the requirement lines from the tree.
func refresh() -> void:
	for view: TreeNodeView in views.values():
		view.refresh()
	layer.queue_redraw()


## Moves the map by `offset`, as far as the clamp allows.
func pan_by(offset: Vector2) -> void:
	layer.position += offset
	_clamp()


## Sets the zoom to `factor` (clamped to MIN_ZOOM..MAX_ZOOM), keeping the map
## point under `point` (in this control's coordinates) where it is.
func zoom_at(point: Vector2, factor: float) -> void:
	var under := (point - layer.position) / zoom
	zoom = clampf(factor, MIN_ZOOM, MAX_ZOOM)
	layer.scale = Vector2.ONE * zoom
	layer.position = point - under * zoom
	_clamp()


## The view under `point` (in this control's coordinates), or null.
func view_at(point: Vector2) -> TreeNodeView:
	var on_map := (point - layer.position) / zoom
	for view: TreeNodeView in views.values():
		if Rect2(view.position, view.size).has_point(on_map):
			return view
	return null


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button:
		if button.pressed and button.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			var step := ZOOM_STEP if button.button_index == MOUSE_BUTTON_WHEEL_UP else -ZOOM_STEP
			zoom_at(button.position, snappedf(zoom + step, ZOOM_STEP))
			accept_event()
		elif button.button_index == MOUSE_BUTTON_LEFT:
			_on_left(button.pressed, button.position)
			accept_event()
		return
	var motion := event as InputEventMouseMotion
	if motion and _pressed:
		if not _dragging and motion.position.distance_to(_press_at) > DRAG_START:
			_dragging = true
		if _dragging:
			pan_by(motion.position - _last_at)
			_last_at = motion.position
		accept_event()


func _on_left(pressed: bool, at: Vector2) -> void:
	if pressed:
		_pressed = true
		_dragging = false
		_press_at = at
		_last_at = at
		return
	if _pressed and not _dragging:
		var view := view_at(_press_at)
		if view:
			view.click()
	_pressed = false
	_dragging = false


## Keeps the map on screen: it covers the width (but `right_room`), and its
## ground stays at the bottom while it is shorter than the screen.
func _clamp() -> void:
	var shown := MAP_SIZE * zoom
	layer.position.x = clampf(layer.position.x, minf(size.x - right_room - shown.x, 0.0), 0.0)
	layer.position.y = clampf(layer.position.y, size.y - shown.y, maxf(size.y - shown.y, 0.0))


func _draw_map() -> void:
	# The ground runs on under `right_room`, so the forest never ends in mid-air.
	var ground_width := MAP_SIZE.x + right_room / MIN_ZOOM
	layer.draw_rect(Rect2(0.0, GROUND_TOP, ground_width, MAP_SIZE.y - GROUND_TOP), GROUND_COLOR)
	layer.draw_line(Vector2(0.0, GROUND_TOP), Vector2(ground_width, GROUND_TOP), GROUND_EDGE, 3.0)
	var groves := _groves()
	for grove: Vector2 in groves.values():
		_draw_roots((grove.x + grove.y) * 0.5, (grove.y - grove.x) * 0.5)
	for branch: StringName in groves:
		var grove: Vector2 = groves[branch]
		var left := node_center(Vector2(grove.x, 0)).x - CELL
		var width := (grove.y - grove.x + 2.0) * CELL
		layer.draw_string(ThemeDB.fallback_font, Vector2(left, MAP_SIZE.y - 18.0), String(branch).to_upper(),
			HORIZONTAL_ALIGNMENT_CENTER, width, GROVE_FONT_SIZE, UiStyle.DIM_COLOR)
	# Dim lines first, so a lit line is never drawn over.
	for lit: bool in [false, true]:
		for data in tree.nodes():
			if (tree.level(data.id) > 0) != lit:
				continue
			for required in data.requires:
				layer.draw_line(node_center(data.grid), node_center(tree.node(required).grid),
					LINE_LIT if lit else LINE_DIM, LINE_WIDTH, true)


## Three curved roots spreading from the middle of a grove (columns, as a
## center and a half width) down into the soil.
func _draw_roots(center_column: float, half_columns: float) -> void:
	var top := Vector2(node_center(Vector2(center_column, 0)).x, GROUND_TOP)
	var reach := (half_columns + 0.8) * CELL
	for side: float in [-1.0, -0.25, 1.0]:
		var end := top + Vector2(side * reach, 44.0 if absf(side) == 1.0 else 30.0)
		var bend := top + Vector2(side * reach * 0.3, 34.0)
		var points := PackedVector2Array()
		for i in 13:
			var t := i / 12.0
			points.append(top.lerp(bend, t).lerp(bend.lerp(end, t), t))
		layer.draw_polyline(points, ROOT_COLOR, 5.0 if absf(side) == 1.0 else 4.0, true)


## Branch -> (first column, last column), in catalog order.
func _groves() -> Dictionary:
	var groves := {}
	for data in tree.nodes():
		var span: Vector2 = groves.get(data.branch, Vector2(data.grid.x, data.grid.x))
		groves[data.branch] = Vector2(minf(span.x, data.grid.x), maxf(span.y, data.grid.x))
	return groves

class_name MapThumbnail
extends Control
## Endless's map preview: a 400×180 card drawn from the chosen map's lists.
## StageMaps.create builds the map, which fills its lists in _init; they are
## read at once and the instance is freed. It never enters the tree, so
## nothing bakes (StageMap makes its walls and navigation in _ready). Random
## shows a "?" card.

const SIZE := Vector2(400, 180)
## The map's margin inside the card.
const PAD := 10.0
## Per act the choice plays on: floor, walls and their edge, round walls.
const THEMES := {
	1: [Color("5b5244"), Color("1d3a24"), Color("2f5a35"), Color("6b6660")],
	2: [Color("3a3f47"), Color("4a4f57"), Color("6b717b"), Color("8a8478")],
	3: [Color("4d4b37"), Color("1d3a24"), Color("2f5a35"), Color("16301d")],
	4: [Color("37313f"), Color("120f1a"), Color("5e4285"), Color("4a4554")],
	5: [Color("2a3330"), Color("0b0e0d"), Color("3a4a3c"), Color("1c1f1e")],
	6: [Color("2b3134"), Color("040706"), Color("4f5a60"), Color("343b3f")],
}
const CARD_COLOR := Color(0.03, 0.035, 0.045)
const CARD_BORDER := Color(0.79, 0.64, 0.36, 0.6)
const ABYSS_EDGE := Color(0.3, 0.85, 0.55, 0.45)
const MIST_COLOR := Color(0.78, 0.9, 0.85, 0.14)
const START_COLOR := UiStyle.GOLD_COLOR
const SPAWN_COLOR := Color("e0475a")
const RANDOM_FONT := 84
const CAPTION_FONT := 16

## The Journey.ENDLESS_MAPS index shown (0 is Random).
var choice := 0
## The map's area on the card, and its shapes there.
var ground := Rect2()
var walls: Array[PackedVector2Array] = []
var chasms: Array[PackedVector2Array] = []
## Round walls and mist banks: (x, y, radius) on the card.
var circles: Array[Vector3] = []
var mist: Array[Vector3] = []
var start := Vector2.ZERO
var spawns: Array[Vector2] = []

var _theme: Array = THEMES[1]


func _init() -> void:
	size = SIZE
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Shows map `index` (a Journey.ENDLESS_MAPS index; Random shows "?").
func show_choice(index: int) -> void:
	choice = index
	walls.clear()
	chasms.clear()
	circles.clear()
	mist.clear()
	spawns.clear()
	ground = Rect2()
	var place := EndlessPlan.map_for(index)
	if place != Vector2i.ZERO:
		var map := StageMaps.create(place.x, place.y)
		_read(map)
		map.free()
		_theme = THEMES[place.x]
	queue_redraw()


func is_random() -> bool:
	return EndlessPlan.map_for(choice) == Vector2i.ZERO


## Copies `map`'s shapes onto the card, fitted inside PAD.
func _read(map: StageMap) -> void:
	var fit := minf((SIZE.x - PAD * 2.0) / map.size.x, (SIZE.y - PAD * 2.0) / map.size.y)
	ground = Rect2((SIZE - map.size * fit) * 0.5, map.size * fit)
	var bounds := PackedVector2Array([Vector2.ZERO, Vector2(map.size.x, 0), map.size, Vector2(0, map.size.y)])
	for polygon in map.wall_polygons:
		for piece in Geometry2D.intersect_polygons(polygon, bounds):
			walls.append(_fit(piece, fit))
	for polygon in map.chasm_polygons:
		for piece in Geometry2D.intersect_polygons(polygon, bounds):
			chasms.append(_fit(piece, fit))
	for circle in map.wall_circles:
		circles.append(Vector3(ground.position.x + circle.x * fit, ground.position.y + circle.y * fit, circle.z * fit))
	for bank in map.mist:
		mist.append(Vector3(ground.position.x + bank.x * fit, ground.position.y + bank.y * fit, bank.z * fit))
	start = ground.position + map.lucian_start * fit
	for point in map.spawn_points:
		spawns.append(ground.position + point * fit)


func _fit(polygon: PackedVector2Array, fit: float) -> PackedVector2Array:
	var fitted := PackedVector2Array()
	for point in polygon:
		fitted.append(ground.position + point * fit)
	return fitted


func _draw() -> void:
	draw_style_box(UiStyle.panel(CARD_COLOR, CARD_BORDER, 2, 0.0, 8), Rect2(Vector2.ZERO, SIZE))
	if is_random():
		_draw_random()
		return
	var floor_color: Color = _theme[0]
	var wall_color: Color = _theme[1]
	var edge_color: Color = _theme[2]
	var round_color: Color = _theme[3]
	draw_rect(ground, floor_color)
	for polygon in chasms:
		draw_colored_polygon(polygon, Color("040706"))
		draw_polyline(_closed(polygon), ABYSS_EDGE, 1.5, true)
	for polygon in walls:
		draw_colored_polygon(polygon, wall_color)
		draw_polyline(_closed(polygon), edge_color, 1.5, true)
	for circle in circles:
		var at := Vector2(circle.x, circle.y)
		var radius := maxf(circle.z, 1.5)
		draw_circle(at, radius, round_color)
		draw_arc(at, radius, 0.0, TAU, 16, round_color.darkened(0.4), 1.0, true)
	for bank in mist:
		draw_texture_rect(JourneyMap.glow(), Rect2(Vector2(bank.x - bank.z, bank.y - bank.z), Vector2.ONE * bank.z * 2.0), false, MIST_COLOR)
	for point in spawns:
		draw_circle(point, 3.5, SPAWN_COLOR)
	draw_circle(start, 6.0, Color(0, 0, 0, 0.6))
	draw_circle(start, 4.5, START_COLOR)
	draw_rect(ground, Color(0, 0, 0, 0.6), false, 2.0)


func _draw_random() -> void:
	var font := get_theme_default_font()
	var middle := SIZE * 0.5
	for i in 3:
		var radius := 46.0 + i * 18.0
		draw_arc(middle, radius, 0.0, TAU, 64, Color(0.79, 0.64, 0.36, 0.18 - i * 0.05), 2.0, true)
	var mark_width := font.get_string_size("?", HORIZONTAL_ALIGNMENT_LEFT, -1, RANDOM_FONT).x
	var baseline := middle + Vector2(-mark_width * 0.5, (font.get_ascent(RANDOM_FONT) - font.get_descent(RANDOM_FONT)) * 0.5 - 10.0)
	draw_string(font, baseline, "?", HORIZONTAL_ALIGNMENT_LEFT, -1, RANDOM_FONT, UiStyle.GOLD_COLOR)
	var caption := "A map is rolled each run"
	var caption_width := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, CAPTION_FONT).x
	draw_string(font, Vector2(middle.x - caption_width * 0.5, SIZE.y - 18.0), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, CAPTION_FONT, UiStyle.DIM_COLOR)


func _closed(polygon: PackedVector2Array) -> PackedVector2Array:
	var closed := polygon.duplicate()
	closed.append(polygon[0])
	return closed

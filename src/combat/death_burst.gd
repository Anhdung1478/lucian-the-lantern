class_name DeathBurst
extends Node2D
## An enemy's end: a thin ring that opens and a few motes that fly out from
## where it stood, in its own color, gone within LIFETIME. Only a look, and
## only made while Juice is on.

const LIFETIME := 0.35
const MOTES := 9
## A mote starts this far from the middle and flies this much further (shares
## of the unit's radius; each flies a little less or more).
const MOTE_START := 0.45
const MOTE_FLIGHT := 1.15
const MOTE_SIZE := 5.5
## The ring opens from RING_START to RING_END of the radius.
const RING_START := 0.7
const RING_END := 1.45
const RING_WIDTH := 2.5
## A unit's color when its art can't be read (headless), and how much paler
## than the art the burst is.
const FALLBACK := Color(0.85, 0.35, 0.3)
const PALER := 0.25
## The art is read at most SAMPLES times across and down.
const SAMPLES := 24

## Art path -> its color, so each kind of enemy is read once.
static var _colors := {}

var radius := 30.0
var color := FALLBACK

var _age := 0.0
## Each mote: its direction, scaled by how far it flies (shares of radius).
var _motes := PackedVector2Array()


## The color an enemy's `art` reads as: the average of its opaque pixels,
## the vivid ones counting most (so outlines and shading count little),
## made a little paler.
static func color_of(art: Texture2D) -> Color:
	if art == null:
		return FALLBACK
	var key := art.resource_path
	if _colors.has(key):
		return _colors[key]
	var found := _read_color(art.get_image())
	if key != "":
		_colors[key] = found
	return found


static func _read_color(image: Image) -> Color:
	if image == null or image.is_empty():
		return FALLBACK
	if image.is_compressed() and image.decompress() != OK:
		return FALLBACK
	var step := maxi(1, maxi(image.get_width(), image.get_height()) / SAMPLES)
	var sum := Vector3.ZERO
	var weight := 0.0
	for y in range(0, image.get_height(), step):
		for x in range(0, image.get_width(), step):
			var pixel := image.get_pixel(x, y)
			if pixel.a < 0.5:
				continue
			var share := 0.02 + pixel.s * pixel.v
			sum += Vector3(pixel.r, pixel.g, pixel.b) * share
			weight += share
	if weight <= 0.0:
		return FALLBACK
	return Color(sum.x / weight, sum.y / weight, sum.z / weight).lightened(PALER)


## A burst at `at` for a unit of `unit_radius`, in `unit_color`.
func setup(at: Vector2, unit_radius: float, unit_color: Color) -> void:
	position = at
	radius = unit_radius
	color = unit_color
	var turn := randf() * TAU
	for i in MOTES:
		_motes.append(Vector2.from_angle(turn + TAU * i / MOTES + randf_range(-0.25, 0.25)) * randf_range(0.7, 1.2))


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := _age / LIFETIME
	# Quick at first, slowing as it spreads.
	var out := 1.0 - (1.0 - t) * (1.0 - t)
	var fade := 1.0 - t
	draw_arc(Vector2.ZERO, radius * lerpf(RING_START, RING_END, out), 0.0, TAU, 40, Color(color, 0.7 * fade), RING_WIDTH, true)
	for mote in _motes:
		var at := mote.normalized() * radius * (MOTE_START + MOTE_FLIGHT * mote.length() * out)
		draw_circle(at, MOTE_SIZE * (0.4 + 0.6 * fade), Color(color, fade))

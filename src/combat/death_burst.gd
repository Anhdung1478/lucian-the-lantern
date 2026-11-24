class_name DeathBurst
extends Node2D
## An enemy's end: an incandescent flash core, double expanding shock-rings,
## angular shattering shards, and soft dissipating mist puffs in its own color,
## gone within LIFETIME. Only a look, and only made while Juice is on.

const LIFETIME := 0.35
const SHARDS := 11
const PUFFS := 6
## A shard starts this far from the middle and flies this much further (shares
## of the unit's radius; each flies a little less or more).
const SHARD_START := 0.25
const SHARD_FLIGHT := 1.45
## The outer ring opens from RING_START to RING_END of the radius.
const RING_START := 0.55
const RING_END := 1.65
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
## Each shard: [angle, reach_mult, len, width, spin_rate].
var _shards: Array[Array] = []
## Each mist puff: [angle, reach_mult, start_r, end_r].
var _puffs: Array[Array] = []


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
	_shards.clear()
	_puffs.clear()
	var turn := randf() * TAU
	for i in SHARDS:
		var ang := turn + TAU * i / SHARDS + randf_range(-0.24, 0.24)
		_shards.append([ang, randf_range(0.75, 1.35), randf_range(8.0, 16.0), randf_range(2.6, 5.2), randf_range(-5.0, 5.0)])
	for i in PUFFS:
		var ang := turn + 0.35 + TAU * i / PUFFS + randf_range(-0.3, 0.3)
		_puffs.append([ang, randf_range(0.55, 1.05), randf_range(6.0, 10.0), randf_range(16.0, 24.0)])


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := clampf(_age / LIFETIME, 0.0, 1.0)
	var out := 1.0 - pow(1.0 - t, 2.4)
	var fade := 1.0 - t
	var hot := color.lerp(Color.WHITE, 0.7)
	# Soft dissipating mist puffs behind shards.
	for puff in _puffs:
		var ang: float = puff[0]
		var dist := radius * (0.2 + 0.95 * (puff[1] as float) * out)
		var r := lerpf(puff[2], puff[3], out)
		SoftShape.ellipse(self, Vector2.from_angle(ang) * dist, Vector2.ONE * r, Color(color.darkened(0.12), 0.32 * fade * fade), 0.2)
	# Initial incandescent flash core (quick punch over first 42% of life).
	if t < 0.42:
		var ft := 1.0 - t / 0.42
		SoftShape.ellipse(self, Vector2.ZERO, Vector2.ONE * (radius * (0.65 + 0.55 * (1.0 - ft))), Color(color, 0.55 * ft), 0.25)
		SoftShape.ellipse(self, Vector2.ZERO, Vector2.ONE * (radius * 0.52 * ft), Color(hot, 0.95 * ft), 0.45)
	# Double expanding tapered shock-rings.
	var outer_r := radius * lerpf(RING_START, RING_END, out)
	var inner_r := radius * lerpf(RING_START * 0.7, RING_END * 0.78, sqrt(t))
	draw_arc(Vector2.ZERO, outer_r, 0.0, TAU, 48, Color(hot, 0.78 * fade * fade), lerpf(4.0, 0.9, t), true)
	draw_arc(Vector2.ZERO, inner_r, 0.0, TAU, 40, Color(color, 0.48 * fade), lerpf(7.5, 1.5, t), true)
	# Varied tapered angular shards flying outward.
	for shard in _shards:
		var ang: float = shard[0]
		var dist := radius * (SHARD_START + SHARD_FLIGHT * (shard[1] as float) * out)
		var center := Vector2.from_angle(ang) * dist
		var dir := Vector2.from_angle(ang + (shard[4] as float) * t * 0.28)
		var side := dir.orthogonal()
		var half_l: float = (shard[2] as float) * (0.35 + 0.65 * fade)
		var half_w: float = (shard[3] as float) * (0.3 + 0.7 * fade)
		var poly := PackedVector2Array([
			center + dir * half_l,
			center + side * half_w - dir * (half_l * 0.15),
			center - dir * (half_l * 0.85),
			center - side * half_w - dir * (half_l * 0.15),
		])
		draw_colored_polygon(poly, Color(color, 0.92 * fade))
		var core_poly := PackedVector2Array([
			center + dir * (half_l * 0.65),
			center + side * (half_w * 0.42),
			center - dir * (half_l * 0.45),
			center - side * (half_w * 0.42),
		])
		draw_colored_polygon(core_poly, Color(hot, 0.85 * fade))

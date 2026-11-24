class_name HatefogZone
extends Node2D
## Malignance's Hatefog: scorched arcane ground under an enemy hit by R. For
## DURATION seconds it deals magic damage every second to enemies inside and
## lowers their magic resist while they stand in it.

const DURATION := 3.0
const RADIUS := 150.0
const TICK := 1.0
const BASE_DAMAGE := 60.0
const AP_RATIO := 0.05
const FILL := Color(0.26, 0.05, 0.28, 0.42)
const MIST_DARK := Color(0.18, 0.02, 0.22, 0.36)
const MIST_GLOW := Color(0.68, 0.14, 0.58, 0.28)
const EDGE := Color(0.92, 0.34, 0.86, 0.82)
const FISSURE := Color(1.0, 0.42, 0.72, 0.75)
const EMBER_COLOR := Color(1.0, 0.62, 0.94, 0.85)
const FISSURE_COUNT := 6
const EMBER_COUNT := 14

var lucian: Lucian
var icon: Texture2D

var _left := DURATION
var _age := 0.0
var _next_tick := 0.0
var _ticks_left := roundi(DURATION / TICK)
## Pre-rolled branching scorch fissures: Array[PackedVector2Array].
var _fissures: Array[PackedVector2Array] = []
## Pre-rolled rising hatefog embers: [angle, radial_share, speed, phase, size].
var _embers: Array[Array] = []


func setup(owner_lucian: Lucian, at: Vector2, status_icon: Texture2D) -> void:
	lucian = owner_lucian
	position = at
	icon = status_icon
	z_index = -1


func _ready() -> void:
	var base_turn := randf() * TAU
	for i in FISSURE_COUNT:
		var ang := base_turn + TAU * i / FISSURE_COUNT + randf_range(-0.22, 0.22)
		var crack := PackedVector2Array([Vector2.from_angle(ang) * randf_range(12.0, 24.0)])
		var cur_ang := ang
		for step in range(1, 5):
			cur_ang += randf_range(-0.24, 0.24)
			var r := RADIUS * (0.22 * step + randf_range(-0.04, 0.05))
			crack.append(Vector2.from_angle(cur_ang) * minf(r, RADIUS * 0.9))
		_fissures.append(crack)
	for i in EMBER_COUNT:
		_embers.append([randf() * TAU, randf_range(0.18, 0.88), randf_range(0.55, 1.15), randf(), randf_range(2.2, 4.2)])


func _physics_process(delta: float) -> void:
	_age += delta
	_left -= delta
	_next_tick -= delta
	if _next_tick <= 0.0 and _ticks_left > 0 and is_instance_valid(lucian):
		_next_tick += TICK
		_ticks_left -= 1
		for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
			if enemy.global_position.distance_to(global_position) <= RADIUS + enemy.radius:
				enemy.add_status(Enemy.HATEFOG, TICK + 0.1, 1, icon)
				enemy.take_damage(lucian.make_damage(BASE_DAMAGE + AP_RATIO * lucian.stats.ap, DamageInfo.Type.MAGIC, &"malignance"))
	if _left <= 0.0:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var fade := clampf(_left / 0.45, 0.0, 1.0) * clampf(_age / 0.12, 0.0, 1.0)
	if fade <= 0.001:
		return
	var pulse := 0.5 + 0.5 * sin(_age * 7.5)
	# Layered dark-violet scorched arcane fog base.
	SoftShape.ellipse(self, Vector2.ZERO, Vector2.ONE * (RADIUS * 1.04), Color(FILL, FILL.a * fade), 0.58)
	# Counter-rotating swirling hatefog lobes.
	for i in 4:
		var a1 := _age * 0.75 + i * TAU * 0.25
		var p1 := Vector2.from_angle(a1) * (RADIUS * 0.34)
		SoftShape.ellipse(self, p1, Vector2(RADIUS * 0.62, RADIUS * 0.44), Color(MIST_DARK, MIST_DARK.a * fade), 0.22)
		var a2 := -_age * 1.1 + i * TAU * 0.25 + 0.4
		var p2 := Vector2.from_angle(a2) * (RADIUS * 0.48)
		SoftShape.ellipse(self, p2, Vector2(RADIUS * 0.44, RADIUS * 0.32), Color(MIST_GLOW, (0.2 + 0.12 * pulse) * fade), 0.2)
	# Glowing violet-crimson scorch fissures.
	for crack in _fissures:
		draw_polyline(crack, Color(EDGE, 0.32 * fade), 5.5, true)
		draw_polyline(crack, Color(FISSURE, (0.55 + 0.25 * pulse) * fade), 2.0, true)
	# Central scorched core glow.
	SoftShape.ellipse(self, Vector2.ZERO, Vector2.ONE * (RADIUS * (0.26 + 0.05 * pulse)), Color(FISSURE, 0.35 * fade), 0.25)
	# Pulsing runic outer boundary ring + rotating arcane ticks.
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 64, Color(EDGE, 0.35 * fade), 7.0, true)
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 64, Color(EDGE, (0.72 + 0.2 * pulse) * fade), 2.5, true)
	draw_arc(Vector2.ZERO, RADIUS * 0.88, 0.0, TAU, 56, Color(FISSURE, (0.28 + 0.18 * pulse) * fade), 1.5, true)
	for i in 12:
		var ang := _age * 0.45 + TAU * i / 12.0
		var dir := Vector2.from_angle(ang)
		var tick_len := 11.0 if i % 3 == 0 else 6.0
		draw_line(dir * (RADIUS - tick_len), dir * RADIUS, Color(EMBER_COLOR, (0.55 + 0.25 * pulse) * fade), 2.0, true)
	for i in 4:
		var seg := -_age * 0.7 + i * TAU * 0.25
		draw_arc(Vector2.ZERO, RADIUS * (0.56 + 0.05 * pulse), seg, seg + 0.75, 16, Color(EDGE, 0.45 * fade), 2.0, true)
	# Rising hatefog embers drifting upward and swirling.
	for ember in _embers:
		var cycle := fmod(_age * (ember[2] as float) + (ember[3] as float), 1.0)
		var ea := sin(cycle * PI) * fade
		var ang: float = (ember[0] as float) + _age * 0.65
		var base := Vector2.from_angle(ang) * (RADIUS * (ember[1] as float))
		var pt := base + Vector2(sin(_age * 5.0 + (ember[3] as float) * TAU) * 6.0, -cycle * 28.0)
		var sz: float = (ember[4] as float) * (0.5 + 0.5 * (1.0 - cycle))
		draw_circle(pt, sz * 2.0, Color(EDGE, 0.28 * ea))
		draw_circle(pt, sz, Color(EMBER_COLOR, 0.9 * ea))

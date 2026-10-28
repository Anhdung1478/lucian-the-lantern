class_name TrainingGroundMap
extends StageMap
## Act 2: the Sentinels' training ground. An open stone arena with round
## pillars to hide behind (Akshan's Comeuppance) and training dummies along
## the walls. Gates on the left, top and right let the waves in. Each stage
## moves the pillars a little and opens more gates.

const PILLAR_RADIUS := 70.0
const DUMMY_RADIUS := 34.0
const DUMMY_ART := preload("res://assets/art/enemies/training_dummy.svg")
const GATES := {&"left": Vector2(150, 1400), &"top": Vector2(2300, 150), &"right": Vector2(4450, 1400)}
const DUMMIES: Array[Vector2] = [Vector2(700, 110), Vector2(1500, 110), Vector2(3100, 110), Vector2(3900, 110), Vector2(700, 2690), Vector2(3900, 2690)]
const TILE := 200.0
const FLOOR := Color("3a3f47")
const FLOOR_ALT := Color("343941")
const PILLAR := Color("8a8478")
const GATE := Color("c9a45c")
const WALL := Color("4a4f57")

var stage := 1


func _init(stage_number := 1) -> void:
	stage = stage_number
	size = Vector2(4600, 2800)
	lucian_start = Vector2(2300, 2550)
	merchant_point = Vector2(1700, 2350)
	boss_point = GATES[&"top"] + Vector2(0, 150)
	for gate: StringName in ([&"top", &"right"] if stage == 1 else [&"left", &"top", &"right"]):
		spawn_points.append(GATES[gate])
	for pillar in pillars(stage):
		wall_circles.append(Vector3(pillar.x, pillar.y, PILLAR_RADIUS))
	for dummy in DUMMIES:
		wall_circles.append(Vector3(dummy.x, dummy.y, DUMMY_RADIUS))


## Stage 1: 6 pillars; stage 2: 8; stage 3: a ring of 10 around the center.
static func pillars(stage_number: int) -> Array[Vector2]:
	var found: Array[Vector2] = []
	if stage_number >= 3:
		for i in 10:
			found.append(Vector2(2300, 1400) + Vector2.from_angle(deg_to_rad(18.0 + 36.0 * i)) * 650.0)
		return found
	found.assign([Vector2(1300, 900), Vector2(3300, 900), Vector2(1300, 1900), Vector2(3300, 1900), Vector2(2300, 950), Vector2(2300, 1850)])
	if stage_number == 2:
		found.append_array([Vector2(800, 1400), Vector2(3800, 1400)])
	return found


func _draw() -> void:
	# The outer wall, where the camera still sees past the floor.
	for rect in border_rects():
		draw_rect(rect, WALL)
	var x := 0.0
	while x < size.x:
		var y := 0.0
		while y < size.y:
			var odd := (roundi(x / TILE) + roundi(y / TILE)) % 2 == 1
			draw_rect(Rect2(x, y, TILE, TILE), FLOOR_ALT if odd else FLOOR)
			y += TILE
		x += TILE
	for gate: Vector2 in GATES.values():
		var along_wall := Vector2(0, 1) if gate.x < 300.0 or gate.x > size.x - 300.0 else Vector2(1, 0)
		draw_line(gate - along_wall * 160.0, gate + along_wall * 160.0, GATE, 10.0)
	for circle in wall_circles:
		var at := Vector2(circle.x, circle.y)
		if circle.z == PILLAR_RADIUS:
			draw_circle(at, circle.z, PILLAR)
			draw_circle(at + Vector2(-14, -14), circle.z * 0.55, PILLAR.lightened(0.15))
			draw_arc(at, circle.z, 0.0, TAU, 40, PILLAR.darkened(0.4), 5.0, true)
		else:
			draw_texture(DUMMY_ART, at - DUMMY_ART.get_size() * 0.5, Color(1, 1, 1, 0.75))
	draw_rect(get_bounds(), Color("6b717b"), false, 4.0)

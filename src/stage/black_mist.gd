class_name BlackMist
extends Node2D
## Act 5's Black Mist: pale green-grey banks lying on the ground, under the
## units, breathing slowly. A normal or elite enemy inside a bank is veiled
## (a dark silhouette, no health bar, no radar dot) while Lucian is more than
## REVEAL_RANGE away; a veiled enemy can still be targeted and hit. While
## veiled and hurt, it also regenerates REGEN of its max HP a second
## (Grievous Wounds cuts it); one Lucian is close enough to see doesn't.
## Bosses and mini bosses are never veiled and never regenerate.
## The stage adds it to its world, so it freezes with it; give it the map's
## `banks` and `lucian`.

## Lucian this close to an enemy in the mist sees it.
const REVEAL_RANGE := 350.0
## A veiled normal or elite enemy heals this share of its max HP a second.
const REGEN := 0.01
## Under the units (0) and the ground zones (HazardZone.Z), over the floor.
const Z := HazardZone.Z - 1
## The bank's body, its darker heart and its wisps.
const MIST_COLOR := Color("7d968a")
const HEART_COLOR := Color("2a3a34")
const WISP_COLOR := Color("a9c0b2")
## The alpha of the body's disc, the layers over it, the heart, a wisp and the edge line.
const BODY_ALPHA := 0.2
const LAYER_ALPHA := 0.22
const HEART_ALPHA := 0.6
const WISP_ALPHA := 0.2
const EDGE_ALPHA := 0.22
const EDGE_WIDTH := 3.0
## The body's disc and the heart, as shares of a bank's radius.
const BODY_SHARE := 0.97
const HEART_SHARE := 0.62
## How far each layer breathes (share of its size), and the seconds one breath takes.
const BREATH := 0.25
const BREATH_TIME := 7.0
## Each soft layer: radius share, how far from the bank's middle it drifts
## (share) and its starting angle.
const LAYERS := [Vector3(0.95, 0.0, 0.0), Vector3(0.8, 0.18, 1.7), Vector3(0.65, 0.22, 3.4)]
## Wisps round the rim: how many, how far they sit from the middle, and their
## size (shares of the radius), spread by the golden angle so no two bunch up.
const WISPS := 9
const WISP_REACH := Vector2(0.52, 0.28)
const WISP_SIZE := Vector2(0.22, 0.08)
## Outer billowing fog lobes softening the mist bank's perimeter.
const RIM_LOBES := 12
const TENDRILS := 7
const RIM_DASHES := 14
const GOLDEN_ANGLE := 2.399963
## Radians a second the layers and wisps turn round their bank.
const DRIFT_SPEED := 0.05
## A bank redraws this often (seconds), only while Juice is on.
const REDRAW_EVERY := 0.1
const EDGE_SIDES := 48

## Banks: (x, y, radius), in the world's space.
var banks: Array[Vector3] = []
var lucian: Lucian

var _age := 0.0
var _redraw_in := 0.0


func _init() -> void:
	z_index = Z


## `point` lies inside a bank.
func in_mist(point: Vector2) -> bool:
	for bank in banks:
		if point.distance_to(Vector2(bank.x, bank.y)) <= bank.z:
			return true
	return false


func _physics_process(delta: float) -> void:
	var watching := is_instance_valid(lucian)
	for enemy in get_tree().get_nodes_in_group(&"enemies"):
		if enemy is EnemyUnit:
			var unit: EnemyUnit = enemy
			var misted := not unit.data.is_boss_kind() and in_mist(unit.global_position)
			var reach := unit.global_position.distance_to(lucian.global_position) if watching else INF
			unit.veiled = misted and reach > REVEAL_RANGE
			if unit.veiled and unit.hp < unit.max_hp:
				unit.heal(unit.max_hp * REGEN * delta)


## The drift and breathing run only with Juice on; off, the banks stand still.
func _process(delta: float) -> void:
	if not Juice.on():
		return
	_age += delta
	_redraw_in -= delta
	if _redraw_in <= 0.0:
		_redraw_in = REDRAW_EVERY
		queue_redraw()


## Seconds the banks have drifted (0 while Juice is off).
func drift_time() -> float:
	return _age


func _draw() -> void:
	for bank in banks:
		var middle := Vector2(bank.x, bank.y)
		var radius := bank.z
		var seed_phase := bank.x * 0.001 + bank.y * 0.0007
		# Soft layered gradient body instead of a hard disc edge.
		MapArt.glow(self, middle, radius * 1.12, Color(MIST_COLOR, BODY_ALPHA * 1.15))
		MapArt.glow(self, middle, radius * BODY_SHARE, Color(MIST_COLOR, BODY_ALPHA * 0.9))
		# Soft billowing outer fog lobes around the perimeter.
		for i in RIM_LOBES:
			var base_angle := TAU * i / RIM_LOBES + seed_phase * 0.5
			var drift := _age * DRIFT_SPEED * (0.65 if i % 2 == 0 else -0.5)
			var lobe_angle := base_angle + drift
			var swell := 0.86 + 0.16 * sin(_age * TAU / BREATH_TIME + seed_phase + i * 1.3)
			var reach := radius * (0.76 + 0.1 * sin(i * 2.3 + seed_phase))
			var lobe_r := radius * (0.28 + 0.07 * cos(i * 1.9)) * swell
			var lobe_at := middle + Vector2.from_angle(lobe_angle) * reach
			MapArt.glow(self, lobe_at, lobe_r, Color(MIST_COLOR, LAYER_ALPHA * 0.85))
		for layer: Vector3 in LAYERS:
			var phase := layer.z + seed_phase
			var breath := 1.0 - BREATH * 0.5 + BREATH * 0.5 * sin(_age * TAU / BREATH_TIME + phase)
			var at := middle + Vector2.from_angle(phase + _age * DRIFT_SPEED) * radius * layer.y
			MapArt.glow(self, at, radius * layer.x * breath, Color(MIST_COLOR, LAYER_ALPHA))
		var heart_at := middle + Vector2.from_angle(seed_phase + _age * DRIFT_SPEED * 2.0) * radius * 0.06
		MapArt.glow(self, heart_at, radius * HEART_SHARE, Color(HEART_COLOR, HEART_ALPHA))
		for i in WISPS:
			var angle := i * GOLDEN_ANGLE + seed_phase + _age * DRIFT_SPEED * (1.0 if i % 2 == 0 else -0.7)
			var reach := WISP_REACH.x + WISP_REACH.y * fposmod(i * 0.618, 1.0)
			var size := WISP_SIZE.x + WISP_SIZE.y * sin(i * 1.7)
			MapArt.soft_oval(self, middle + Vector2.from_angle(angle) * radius * reach, Vector2(size, size * 0.62) * radius, Color(WISP_COLOR, WISP_ALPHA))
		# Drifting wispy tendrils curling near the outer edge.
		for i in TENDRILS:
			var start_ang := TAU * i / TENDRILS + seed_phase + _age * DRIFT_SPEED * (1.1 if i % 2 == 0 else -0.85)
			var pts := PackedVector2Array()
			for step_i in 6:
				var share := float(step_i) / 5.0
				var ang := start_ang + share * 0.42
				var radial := radius * (0.86 + 0.14 * share + 0.04 * sin(share * PI * 2.0 + _age * 0.9 + i))
				pts.append(middle + Vector2.from_angle(ang) * radial)
			draw_polyline(pts, Color(WISP_COLOR, WISP_ALPHA * 0.6), 7.5, true)
			draw_polyline(pts, Color(WISP_COLOR, WISP_ALPHA * 0.9), 2.4, true)
		# Very subtle translucent broken undulating perimeter hint so reveal boundaries stay readable.
		for i in RIM_DASHES:
			var base := TAU * i / RIM_DASHES + seed_phase * 0.3 + _age * DRIFT_SPEED * 0.25
			var span := (TAU / RIM_DASHES) * (0.42 + 0.14 * sin(i * 2.1 + seed_phase))
			var pts := PackedVector2Array()
			for step_i in 5:
				var share := float(step_i) / 4.0
				var ang := base + share * span
				var wave := sin(ang * 5.0 + seed_phase + _age * 0.7) * 4.5
				pts.append(middle + Vector2.from_angle(ang) * (radius + wave))
			var hint_alpha := EDGE_ALPHA * (0.48 + 0.28 * sin(i * 1.7 + _age * 0.6))
			draw_polyline(pts, Color(MIST_COLOR, hint_alpha * 0.45), EDGE_WIDTH * 2.2, true)
			draw_polyline(pts, Color(WISP_COLOR, hint_alpha * 0.75), EDGE_WIDTH * 0.7, true)

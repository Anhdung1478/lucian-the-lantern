class_name BlackMist
extends Node2D
## Act 5's Black Mist: pale green-grey banks lying on the ground, under the
## units, breathing slowly. A normal or elite enemy inside a bank is veiled
## (a dark silhouette, no health bar, no radar dot) while Lucian is more than
## REVEAL_RANGE away; a veiled enemy can still be targeted and hit. Bosses and
## mini bosses are never veiled. The stage adds it to its world, so it
## freezes with it; give it the map's `banks` and `lucian`.

## Lucian this close to an enemy in the mist sees it.
const REVEAL_RANGE := 350.0
## Under the units (0) and the ground zones (HazardZone.Z), over the floor.
const Z := HazardZone.Z - 1
const MIST_COLOR := Color("9fb8a8")
## The alpha of a bank's layers, and how far each breathes.
const ALPHA := 0.35
const BREATH := 0.25
## Seconds one breath takes.
const BREATH_TIME := 7.0
## Each layer: radius share, and how far from the bank's middle it drifts (share).
const LAYERS := [Vector3(1.0, 0.0, 0.0), Vector3(0.8, 0.18, 1.7), Vector3(0.6, 0.22, 3.4)]
const BANK_SIDES := 40

## Banks: (x, y, radius), in the world's space.
var banks: Array[Vector3] = []
var lucian: Lucian

var _age := 0.0


func _init() -> void:
	z_index = Z


## `point` lies inside a bank.
func in_mist(point: Vector2) -> bool:
	for bank in banks:
		if point.distance_to(Vector2(bank.x, bank.y)) <= bank.z:
			return true
	return false


func _physics_process(_delta: float) -> void:
	var watching := is_instance_valid(lucian)
	for enemy in get_tree().get_nodes_in_group(&"enemies"):
		if enemy is EnemyUnit:
			var unit: EnemyUnit = enemy
			var reach := unit.global_position.distance_to(lucian.global_position) if watching else INF
			unit.veiled = not unit.data.is_boss_kind() and in_mist(unit.global_position) and reach > REVEAL_RANGE


func _process(delta: float) -> void:
	_age += delta
	queue_redraw()


func _draw() -> void:
	for bank in banks:
		var middle := Vector2(bank.x, bank.y)
		for layer: Vector3 in LAYERS:
			var phase := layer.z + bank.x * 0.001
			var breath := 1.0 - BREATH * 0.5 + BREATH * 0.5 * sin(_age * TAU / BREATH_TIME + phase)
			var at := middle + Vector2.from_angle(phase + _age * 0.05) * bank.z * layer.y
			draw_colored_polygon(_blob(at, bank.z * layer.x), Color(MIST_COLOR, ALPHA * 0.5 * breath))


static func _blob(middle: Vector2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in BANK_SIDES:
		points.append(middle + Vector2.from_angle(TAU * i / BANK_SIDES) * radius)
	return points

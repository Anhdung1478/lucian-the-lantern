class_name MapAmbience
extends Node2D
## A map's ambient life: a few slow, quiet lights on a node of their own, so
## they move without the map's art being drawn again. Fireflies wander round
## their spots, glowing and fading; glints come and go on water; dust drifts
## with the wind and fades at both ends of its way. A map makes one in its
## build_ambience and StageMap adds it, just over the floor: under ground
## zones, warnings and units. It is off while the Quality setting is low.
## Only the motes in view are drawn, as soft stamps: one batch.

enum Kind { FIREFLY, GLINT, DUST }

## Over the map's floor (StageMap.FLOOR_Z), under everything else.
const Z := 1
## Motes this far outside the view are still drawn, so none pops in.
const VIEW_MARGIN := 80.0
## A firefly: how far it wanders from its spot, how fast (radians a second,
## each way), how fast it glows and fades, and its halo and core.
const FIREFLY_ROAM := Vector2(34, 24)
const FIREFLY_SPEED := Vector2(0.37, 0.29)
const FIREFLY_PULSE := 0.8
const FIREFLY_HALO := 15.0
const FIREFLY_CORE := 3.5
## A glint: how fast it comes and goes, and its size at its brightest.
const GLINT_PULSE := 0.6
const GLINT_SIZE := Vector2(26, 3.5)
## Dust: how far it drifts before it starts again, its speed in px a second,
## its way, and its size.
const DUST_REACH := 420.0
const DUST_SPEED := 14.0
const DUST_WAY := Vector2(0.94, -0.34)
const DUST_SIZE := 5.0

var _spots := PackedVector2Array()
var _kinds := PackedByteArray()
var _colors := PackedColorArray()
## Per mote, 0 to 1: where in its cycle it starts.
var _phases := PackedFloat32Array()
var _time := 0.0


func _ready() -> void:
	z_index = Z
	GameSettings.instance().changed.connect(_on_setting_changed)
	_sync()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


## Adds a mote of `kind` in `color` at each of `spots`; `dice` gives each
## its place in the cycle, so they never move together.
func add(kind: Kind, spots: PackedVector2Array, color: Color, dice: RandomNumberGenerator) -> void:
	for spot in spots:
		_spots.append(spot)
		_kinds.append(kind)
		_colors.append(color)
		_phases.append(dice.randf())


## How many motes it has.
func count() -> int:
	return _spots.size()


## Where mote `index` is at `time`.
func place_of(index: int, time: float) -> Vector2:
	var turn := _phases[index] * TAU
	match _kinds[index]:
		Kind.FIREFLY:
			return _spots[index] + Vector2(sin(time * FIREFLY_SPEED.x + turn * 3.0), cos(time * FIREFLY_SPEED.y + turn * 5.0)) * FIREFLY_ROAM
		Kind.DUST:
			return _spots[index] + DUST_WAY * (_drift(index, time) - 0.5) * DUST_REACH
	return _spots[index]


## How bright mote `index` is at `time`, 0 to 1.
func glow_of(index: int, time: float) -> float:
	var turn := _phases[index] * TAU
	match _kinds[index]:
		Kind.FIREFLY:
			return 0.5 + 0.5 * sin(time * FIREFLY_PULSE + turn * 7.0)
		Kind.GLINT:
			return pow(maxf(sin(time * GLINT_PULSE + turn), 0.0), 3.0)
	return sin(PI * _drift(index, time))


func _draw() -> void:
	var view := (get_global_transform_with_canvas().affine_inverse() * get_viewport_rect()).grow(VIEW_MARGIN)
	var stamp := MapArt.soft_texture()
	for i in _spots.size():
		if not view.has_point(_spots[i]):
			continue
		var at := place_of(i, _time)
		var color := _colors[i]
		color.a *= glow_of(i, _time)
		match _kinds[i]:
			Kind.FIREFLY:
				draw_texture_rect(stamp, Rect2(at.x - FIREFLY_HALO, at.y - FIREFLY_HALO, FIREFLY_HALO * 2.0, FIREFLY_HALO * 2.0), false, Color(color, color.a * 0.4))
				draw_texture_rect(stamp, Rect2(at.x - FIREFLY_CORE, at.y - FIREFLY_CORE, FIREFLY_CORE * 2.0, FIREFLY_CORE * 2.0), false, color)
			Kind.GLINT:
				draw_texture_rect(stamp, Rect2(at - GLINT_SIZE, GLINT_SIZE * 2.0), false, color)
			Kind.DUST:
				draw_texture_rect(stamp, Rect2(at.x - DUST_SIZE, at.y - DUST_SIZE, DUST_SIZE * 2.0, DUST_SIZE * 2.0), false, color)


## How far along its way dust mote `index` is at `time`, 0 to 1.
func _drift(index: int, time: float) -> float:
	return fposmod(time * DUST_SPEED / DUST_REACH + _phases[index], 1.0)


func _on_setting_changed(key: StringName) -> void:
	if key == &"quality":
		_sync()


## Shown and moving unless the Quality setting is low or nothing is drawn
## (the tests, the bots).
func _sync() -> void:
	visible = Juice.on()
	set_process(visible)

class_name CastRange
extends RefCounted
## The shape a range indicator draws for a cast: a line toward the aim (Q, W,
## a dash), two dashed lines (R) or a circle around Lucian (Gunblade, Smite,
## Flash). Distances are from Lucian's center.

enum Kind { LINE, TWIN_LINES, CIRCLE }

## Lucian's width: how wide a dash's path is.
const BODY_WIDTH := 60.0

var kind := Kind.LINE
## How far the line reaches, or the circle's radius.
var reach := 0.0
var width := 0.0
## TWIN_LINES: how far each line runs from the aim line.
var spread := 0.0
## W: the cross its missile bursts into at the end (arm length x width).
var cross := Vector2.ZERO
## Dashes and Flash: a ring where Lucian lands, at the aimed distance kept
## between min_reach and reach. These casts move him, so a root refuses them.
var landing := false
var min_reach := 0.0
## Gunblade and Smite hit an enemy: aimed at one out of reach, Lucian walks
## over first.
var targets_enemy := false


static func line(length: float, line_width: float) -> CastRange:
	var shape := CastRange.new()
	shape.reach = length
	shape.width = line_width
	return shape


## A dash: Lucian's path, up to `length` long, as far as the cursor (but at
## least `shortest`).
static func dash(length: float, shortest := 0.0) -> CastRange:
	var shape := line(length, BODY_WIDTH)
	shape.landing = true
	shape.min_reach = shortest
	return shape


## A blink (Flash): how far it reaches all around, and where Lucian lands.
static func blink(radius: float) -> CastRange:
	var shape := circle(radius)
	shape.landing = true
	return shape


## A cast on the enemy nearest the cursor within `radius`.
static func target(radius: float) -> CastRange:
	var shape := circle(radius)
	shape.targets_enemy = true
	return shape


static func twin(length: float, gap: float) -> CastRange:
	var shape := line(length, 0.0)
	shape.kind = Kind.TWIN_LINES
	shape.spread = gap
	return shape


static func circle(radius: float) -> CastRange:
	var shape := CastRange.new()
	shape.kind = Kind.CIRCLE
	shape.reach = radius
	return shape


## How far from Lucian the landing ring goes for an aim `distance` away.
func landing_distance(distance: float) -> float:
	return clampf(distance, min_reach, reach)

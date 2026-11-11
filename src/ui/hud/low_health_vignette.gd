class_name LowHealthVignette
extends Control
## A soft red vignette at the screen's edges that pulses slowly while Lucian
## is below LOW of his health. It sits under the rest of the HUD, never takes
## the mouse, and is gone at LOW or more, when he is dead and on low effects.

## The vignette starts below this share of health.
const LOW := 0.3
## Its alpha at the threshold and at no health left (it grows between), and
## how far the pulse dims it (a share of the alpha).
const ALPHA_AT_LOW := 0.25
const ALPHA_AT_ZERO := 0.6
const PULSE_DIP := 0.4
## Seconds a pulse takes.
const PULSE_TIME := 2.4
const EDGE_COLOR := Color("b81d1d")
## Where the gradient turns from clear to red, across the distance from the
## centre to the nearest edge.
const CLEAR_UNTIL := 0.55
const TEXTURE_SIZE := 128

static var _texture: GradientTexture2D

## How strong the vignette is, 0 to 1: 0 gone, 1 at no health left.
var strength := 0.0
var _time := 0.0


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)


## The vignette's strength for Lucian at `hp` of `max_hp`: 0 when he is dead,
## at LOW of his health or more, or on low effects; else growing from 0 at LOW
## to 1 at no health.
static func strength_for(hp: float, max_hp: float, is_dead: bool, low_effects: bool) -> float:
	if is_dead or low_effects or max_hp <= 0.0 or hp / max_hp >= LOW:
		return 0.0
	return clampf(1.0 - hp / max_hp / LOW, 0.0, 1.0)


## The vignette's alpha at `strength` and pulse `phase` (0 to 1 over a pulse).
static func alpha_for(power: float, phase: float) -> float:
	if power <= 0.0:
		return 0.0
	var base := lerpf(ALPHA_AT_LOW, ALPHA_AT_ZERO, power)
	return base * (1.0 - PULSE_DIP * (0.5 - 0.5 * cos(phase * TAU)))


## Follows Lucian.
func show_health(lucian: Lucian) -> void:
	strength = strength_for(lucian.hp, lucian.stats.max_hp, lucian.dead, not Juice.on())
	visible = strength > 0.0


func _process(delta: float) -> void:
	if visible:
		_time += delta
		queue_redraw()


func _draw() -> void:
	draw_texture_rect(_edges(), Rect2(Vector2.ZERO, size), false, Color(1, 1, 1, alpha_for(strength, fposmod(_time / PULSE_TIME, 1.0))))


## Clear in the middle, red at the edges, stretched over the screen.
static func _edges() -> GradientTexture2D:
	if _texture == null:
		var gradient := Gradient.new()
		gradient.offsets = PackedFloat32Array([0.0, CLEAR_UNTIL, 1.0])
		gradient.colors = PackedColorArray([Color(EDGE_COLOR, 0.0), Color(EDGE_COLOR, 0.0), EDGE_COLOR])
		_texture = GradientTexture2D.new()
		_texture.gradient = gradient
		_texture.fill = GradientTexture2D.FILL_RADIAL
		_texture.fill_from = Vector2(0.5, 0.5)
		_texture.fill_to = Vector2(1.0, 0.5)
		_texture.width = TEXTURE_SIZE
		_texture.height = TEXTURE_SIZE
	return _texture

class_name FxSparks
extends RefCounted
## Small particles for skin effects (embers, drops, pixels, sparks), in the
## frame of the node that draws them. Each lives at most MAX_LIFE seconds,
## so no effect outlasts 0.6 s.

enum Shape { DOT, SQUARE, HEX, STREAK }

const MAX_LIFE := 0.6

## Added to every velocity each second (falling drops).
var gravity := Vector2.ZERO
## Share of the velocity lost each second (embers slowing down).
var drag := 0.0

## Each: {at, velocity, life, left, size, color}.
var _items: Array[Dictionary] = []


func emit(at: Vector2, velocity: Vector2, life: float, size: float, color: Color) -> void:
	var capped := minf(life, MAX_LIFE)
	_items.append({"at": at, "velocity": velocity, "life": capped, "left": capped, "size": size, "color": color})


func step(delta: float) -> void:
	for item in _items:
		item.left -= delta
		item.velocity += gravity * delta
		item.velocity *= maxf(1.0 - drag * delta, 0.0)
		item.at += item.velocity * delta
	_items.assign(_items.filter(func(item: Dictionary) -> bool: return item.left > 0.0))


func size() -> int:
	return _items.size()


func is_empty() -> bool:
	return _items.is_empty()


## Draws them on `canvas`, from inside its _draw, each fading as it ages.
func draw_on(canvas: CanvasItem, shape := Shape.DOT) -> void:
	for item in _items:
		var color: Color = item.color
		color.a *= item.left / item.life
		var at: Vector2 = item.at
		var side: float = item.size
		match shape:
			Shape.SQUARE:
				canvas.draw_rect(Rect2(at - Vector2.ONE * side * 0.5, Vector2.ONE * side), color)
			Shape.HEX:
				var points := PackedVector2Array()
				for i in 6:
					points.append(at + Vector2.RIGHT.rotated(i * PI / 3.0) * side)
				canvas.draw_colored_polygon(points, color)
			Shape.STREAK:
				var velocity: Vector2 = item.velocity
				canvas.draw_line(at, at - velocity * 0.03, color, side)
			_:
				canvas.draw_circle(at, side, color)

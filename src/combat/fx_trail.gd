class_name FxTrail
extends DashTrail
## A skin's E trail. It grows behind Lucian and fades once the dash is over,
## like DashTrail, but draws its own look and animates: sparks, and copies of
## Lucian's `body`. Never made on Low effects (see Lucian.start_dash).

## Lucian's body art, for trails that draw copies of him.
var body: Texture2D
var age := 0.0
var sparks := FxSparks.new()


func _process(delta: float) -> void:
	age += delta
	sparks.step(delta)
	queue_redraw()


func reach(to: Vector2) -> void:
	var before := length
	super(to)
	if length > before:
		_grown(before, length)


## The trail grew from `from_x` to `to_x` along its length.
func _grown(_from_x: float, _to_x: float) -> void:
	pass

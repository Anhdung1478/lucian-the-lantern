class_name GhostImage
extends Sprite2D
## Ghost's afterimage: Lucian's outline in a pale ghostly color, left behind
## as he runs, fading out.

const LIFETIME := 0.35
const SHADER := preload("res://src/combat/ghost_image.gdshader")
const START_ALPHA := 0.55


func setup(body: Texture2D, from: Vector2, facing: float) -> void:
	texture = body
	position = from
	rotation = facing


func _ready() -> void:
	material = ShaderMaterial.new()
	(material as ShaderMaterial).shader = SHADER
	modulate.a = START_ALPHA
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, LIFETIME)
	tween.tween_callback(queue_free)

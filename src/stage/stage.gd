extends Node2D
## The on-stage screen. Only wires its children together.

@onready var arena: TestArena = $Arena
@onready var lucian: Lucian = $World/Lucian
@onready var camera: StageCamera = $StageCamera


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	camera.setup(lucian, arena.get_bounds().grow(TestArena.WALL_THICKNESS))

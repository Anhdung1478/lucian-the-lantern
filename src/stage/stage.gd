class_name Stage
extends Node2D
## The on-stage screen. Owns the stage gold and wires its children together.

var wallet := Wallet.new()

@onready var arena: TestArena = $Arena
@onready var lucian: Lucian = $World/Lucian
@onready var dummy: TrainingDummy = $World/TrainingDummy
@onready var damage_numbers: DamageNumberSpawner = $DamageNumbers
@onready var camera: StageCamera = $StageCamera
@onready var hud: Hud = $Hud
@onready var debug_table: DebugTable = $DebugTable
@onready var screens: ScreenSwitcher = $Screens


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	camera.setup(lucian, arena.get_bounds().grow(TestArena.WALL_THICKNESS))
	lucian.projectile_parent = $Projectiles
	dummy.damage_taken.connect(damage_numbers.spawn.bind(dummy))
	hud.setup(lucian, wallet)
	debug_table.setup(self)
	screens.backpack.setup(lucian.inventory)
	screens.backpack_toggled.connect(debug_table.set_docked_right)

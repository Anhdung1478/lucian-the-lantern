class_name Stage
extends Node2D
## The on-stage screen. Owns the stage gold and the merchant, and wires its
## children together.

const DUMMY_SCENE := preload("res://src/enemies/training_dummy.tscn")
const EXTRA_DUMMY_RING := 300.0
## Up, right, left and up-right of the first dummy: never toward the merchant.
const EXTRA_DUMMY_ANGLES := [-PI / 2.0, 0.0, PI, -PI / 4.0]

var wallet := Wallet.new()
## The merchant on the map, or null.
var merchant: Merchant
## Items tab slots the merchant can sell from (2, up to 4 later from the
## Evolution Tree).
var shop_slots := 2
## Debug: more dummies around the first one, for Runaan's and Statikk Shiv.
var extra_dummies: Array[TrainingDummy] = []

@onready var arena: TestArena = $Arena
@onready var lucian: Lucian = $World/Lucian
@onready var dummy: TrainingDummy = $World/TrainingDummy
@onready var damage_numbers: DamageNumberSpawner = $DamageNumbers
@onready var camera: StageCamera = $StageCamera
@onready var hud: Hud = $Hud
@onready var debug_table: DebugTable = $DebugTable
@onready var screens: ScreenSwitcher = $Screens


func _ready() -> void:
	var settings := GameSettings.instance()
	settings.apply()
	settings.changed.connect(_on_setting_changed)
	lucian.queue_casts = settings.get_value(&"queue_casts")
	screens.settings.setup(settings)
	add_child(Sfx.new())
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	camera.setup(lucian, arena.get_bounds().grow(TestArena.WALL_THICKNESS))
	lucian.projectile_parent = $Projectiles
	dummy.damage_taken.connect(damage_numbers.spawn.bind(dummy))
	hud.setup(lucian, wallet)
	debug_table.setup(self)
	screens.backpack.setup(lucian.inventory)
	screens.backpack.potion_used.connect(lucian.use_item)
	screens.backpack_toggled.connect(debug_table.set_docked_right)
	lucian.merchant_reached.connect(_open_shop)
	screens.backpack.traded.connect(func(ok: bool) -> void: Sfx.play(&"coin" if ok else &"error"))
	add_merchant()


## Puts a new merchant at the map center, replacing any old one. A new
## merchant is a new visit, with new stock.
func add_merchant() -> void:
	remove_merchant()
	merchant = Merchant.new()
	merchant.setup(lucian.item_catalog)
	merchant.stock.unlocked = shop_slots
	merchant.position = arena.get_bounds().get_center()
	$World.add_child(merchant)


## Takes the merchant off the map, closing his shop if it is open.
func remove_merchant() -> void:
	if screens.is_shopping():
		screens.set_backpack_open(false)
	if is_instance_valid(merchant):
		merchant.remove_from_group(&"merchants")
		merchant.queue_free()
	merchant = null


## Debug: `count` dummies in all, the extras in a ring around the first.
func set_dummy_count(count: int) -> void:
	for extra in extra_dummies:
		extra.queue_free()
	extra_dummies.clear()
	for i in maxi(count - 1, 0):
		var extra: TrainingDummy = DUMMY_SCENE.instantiate()
		extra.position = dummy.position + Vector2.from_angle(EXTRA_DUMMY_ANGLES[i]) * EXTRA_DUMMY_RING
		$World.add_child(extra)
		extra.damage_taken.connect(damage_numbers.spawn.bind(extra))
		debug_table.watch(extra)
		extra_dummies.append(extra)


func set_shop_slots(count: int) -> void:
	shop_slots = clampi(count, 1, MerchantStock.SLOTS)
	if merchant:
		merchant.stock.unlocked = shop_slots


func _on_setting_changed(key: StringName) -> void:
	if key == &"queue_casts":
		lucian.queue_casts = GameSettings.instance().get_value(&"queue_casts")


func _open_shop(visited: Merchant) -> void:
	screens.open_shop(Shop.new(visited.stock, lucian.inventory, wallet))

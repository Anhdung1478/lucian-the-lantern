class_name Merchant
extends StaticBody2D
## The merchant on the map. Right-clicking him sends Lucian over; once Lucian
## is within INTERACT_RANGE the shop opens. Owns this visit's stock, so a new
## merchant always brings new items. Blocks movement like a wall.

const ART := preload("res://assets/art/npc/merchant.svg")
const INTERACT_RANGE := 250.0
## Clicks this close to his center count as clicking him.
const CLICK_RADIUS := 70.0
const BODY_RADIUS := 44.0
const HOVER_COLOR := Color(1.0, 0.81, 0.35, 0.85)
const NAME_COLOR := Color("ffe9a8")

var stock: MerchantStock

var _hovered := false


func setup(catalog: ItemCatalog) -> void:
	stock = MerchantStock.new(catalog)


func _ready() -> void:
	add_to_group(&"merchants")
	collision_layer = Layers.WORLD
	collision_mask = 0
	var circle := CircleShape2D.new()
	circle.radius = BODY_RADIUS
	var shape := CollisionShape2D.new()
	shape.shape = circle
	add_child(shape)
	var sprite := Sprite2D.new()
	sprite.texture = ART
	# The hover ring and name are drawn by this node, over the art.
	sprite.show_behind_parent = true
	add_child(sprite)


func is_under(point: Vector2) -> bool:
	return global_position.distance_to(point) <= CLICK_RADIUS


func _process(_delta: float) -> void:
	var hovered := is_under(get_global_mouse_position())
	if hovered != _hovered:
		_hovered = hovered
		queue_redraw()


func _draw() -> void:
	if _hovered:
		draw_arc(Vector2.ZERO, CLICK_RADIUS + 10.0, 0.0, TAU, 64, HOVER_COLOR, 4.0, true)
	var font := ThemeDB.fallback_font
	var at := Vector2(-100.0, -96.0)
	draw_string_outline(font, at, "Merchant", HORIZONTAL_ALIGNMENT_CENTER, 200.0, 20, 6, Color.BLACK)
	draw_string(font, at, "Merchant", HORIZONTAL_ALIGNMENT_CENTER, 200.0, 20, NAME_COLOR)

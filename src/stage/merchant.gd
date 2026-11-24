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
## Camp lantern center relative to merchant.svg center (30 - 88, 68 - 88).
const LANTERN_OFFSET := Vector2(-58.0, -20.0)
const BREATH_SCALE := 0.015
const BREATH_SPEED := 2.2

var stock: MerchantStock

var _hovered := false
var _sprite: Sprite2D
var _idle_time := 0.0


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
	var shadow := UnitShadow.new()
	shadow.radius = BODY_RADIUS
	add_child(shadow)
	_sprite = Sprite2D.new()
	_sprite.texture = ART
	# The hover ring and name are drawn by this node, over the art.
	_sprite.show_behind_parent = true
	add_child(_sprite)


func is_under(point: Vector2) -> bool:
	return global_position.distance_to(point) <= CLICK_RADIUS


func _process(delta: float) -> void:
	var hovered := is_under(Pointer.in_world(self))
	var needs_redraw := hovered != _hovered
	_hovered = hovered
	if Juice.on():
		_idle_time += delta
		var breath := 1.0 + BREATH_SCALE * sin(_idle_time * BREATH_SPEED)
		if _sprite:
			_sprite.scale = Vector2(1.0 / sqrt(breath), breath)
		needs_redraw = true
	elif _sprite and _sprite.scale != Vector2.ONE:
		_sprite.scale = Vector2.ONE
		needs_redraw = true
	if needs_redraw:
		queue_redraw()


func _draw() -> void:
	if Juice.on():
		var flicker := 0.86 + 0.14 * sin(_idle_time * 5.3) * cos(_idle_time * 2.9)
		var pulse := 1.0 + 0.08 * sin(_idle_time * 3.7)
		draw_circle(LANTERN_OFFSET, 36.0 * pulse, Color(1.0, 0.7, 0.22, 0.13 * flicker))
		draw_circle(LANTERN_OFFSET, 21.0 * pulse, Color(1.0, 0.84, 0.42, 0.2 * flicker))
		draw_circle(LANTERN_OFFSET, 9.0, Color(1.0, 0.96, 0.78, 0.28 * flicker))
	if _hovered:
		draw_arc(Vector2.ZERO, CLICK_RADIUS + 10.0, 0.0, TAU, 64, HOVER_COLOR, 4.0, true)
	var font := ThemeDB.fallback_font
	var at := Vector2(-100.0, -96.0)
	var title := Lang.t("Merchant")
	draw_string_outline(font, at, title, HORIZONTAL_ALIGNMENT_CENTER, 200.0, 20, 6, Color.BLACK)
	draw_string(font, at, title, HORIZONTAL_ALIGNMENT_CENTER, 200.0, 20, NAME_COLOR)

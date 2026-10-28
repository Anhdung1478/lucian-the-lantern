class_name LootDrop
extends Node2D
## An item on the ground where an enemy died. Lucian picks it up by walking
## within PICKUP_RANGE, into the backpack. With no room it stays and says
## so, at most every FULL_NOTE_GAP seconds. It stays until the stage ends.

const PICKUP_RANGE := 60.0
const FULL_NOTE_GAP := 3.0
const ICON_SIZE := 44.0
const GLOW := Color(0.6, 0.85, 1.0, 0.35)
const LEGENDARY_GLOW := Color(1.0, 0.8, 0.3, 0.5)

var item: ItemData
var lucian: Lucian

var _note_left := 0.0
var _time := 0.0


func _physics_process(delta: float) -> void:
	_time += delta
	_note_left -= delta
	queue_redraw()
	if not is_instance_valid(lucian) or not lucian.can_act():
		return
	if global_position.distance_to(lucian.global_position) > PICKUP_RANGE:
		return
	if lucian.inventory.add(item):
		Sfx.play(&"coin")
		queue_free()
	elif _note_left <= 0.0:
		_note_left = FULL_NOTE_GAP
		var note := FloatingText.new("Backpack full", UiStyle.ERROR_COLOR)
		note.position = global_position + Vector2(0, -50)
		get_parent().add_child(note)


func _draw() -> void:
	var bob := sin(_time * 3.0) * 5.0
	var glow := LEGENDARY_GLOW if item.kind == ItemData.Kind.LEGENDARY else GLOW
	draw_circle(Vector2(0, 8), 30.0, Color(glow, glow.a * (0.7 + 0.3 * sin(_time * 4.0))))
	draw_texture_rect(item.icon, Rect2(-ICON_SIZE * 0.5, -ICON_SIZE * 0.5 + bob - 6.0, ICON_SIZE, ICON_SIZE), false)

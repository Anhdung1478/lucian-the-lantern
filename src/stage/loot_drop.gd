class_name LootDrop
extends Node2D
## An item on the ground where an enemy died. Lucian picks it up by walking
## within PICKUP_RANGE, into the backpack. With no room it stays and says
## so, at most every FULL_NOTE_GAP seconds. It stays until the stage ends.
## One that would land off the ground (a ledge over the abyss, a wall) lands
## on the first ground toward the merchant instead (Stage.drop_loot).

const PICKUP_RANGE := 60.0
## A drop lands at least this far inside walkable ground.
const GROUND_MARGIN := 20.0
const FULL_NOTE_GAP := 3.0
const ICON_SIZE := 44.0
const GLOW := Color(0.6, 0.85, 1.0, 0.35)
const LEGENDARY_GLOW := Color(1.0, 0.8, 0.3, 0.5)
## The soft shadow on the ground under the bobbing icon.
const SHADOW_RADIUS := 20.0

var item: ItemData
var lucian: Lucian

var _note_left := 0.0
var _time := 0.0


func _ready() -> void:
	var shadow := UnitShadow.new()
	shadow.radius = SHADOW_RADIUS
	add_child(shadow)


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
		var note := FloatingText.new(Lang.t("Backpack full"), UiStyle.ERROR_COLOR)
		note.position = global_position + Vector2(0, -50)
		get_parent().add_child(note)


func _draw() -> void:
	if item == null:
		return
	var alive := Juice.on()
	var legendary := item.kind == ItemData.Kind.LEGENDARY
	var bob := sin(_time * 3.0) * 5.0 if alive else 0.0
	var pulse := (0.78 + 0.22 * sin(_time * 4.0)) if alive else 0.9
	var glow := LEGENDARY_GLOW if legendary else GLOW
	var core_tint := Color(1.0, 0.96, 0.78) if legendary else Color(0.84, 0.95, 1.0)
	var base_y := 10.0
	var beam_height := 168.0 if legendary else 108.0
	var outer_half := 26.0 if legendary else 18.0
	var inner_half := 10.0 if legendary else 6.5
	# Radiant ground base pool & crisp base ring.
	MapArt.soft_oval(self, Vector2(0, base_y), Vector2(outer_half * 1.45, outer_half * 0.65), Color(glow, glow.a * 0.85 * pulse))
	draw_arc(Vector2(0, base_y), outer_half * 0.78, 0.0, TAU, 32, Color(core_tint, 0.35 * pulse), 1.6, true)
	# Sleek vertical radiant loot-beam pillar tapering softly upward.
	var outer_top := Color(glow, 0.0)
	var outer_bot := Color(glow, glow.a * (0.82 if legendary else 0.65) * pulse)
	draw_polygon(
		PackedVector2Array([
			Vector2(-outer_half, base_y),
			Vector2(outer_half, base_y),
			Vector2(outer_half * 0.45, base_y - beam_height),
			Vector2(-outer_half * 0.45, base_y - beam_height),
		]),
		PackedColorArray([outer_bot, outer_bot, outer_top, outer_top]),
	)
	var inner_top := Color(core_tint, 0.0)
	var inner_bot := Color(core_tint, (0.68 if legendary else 0.42) * pulse)
	draw_polygon(
		PackedVector2Array([
			Vector2(-inner_half, base_y),
			Vector2(inner_half, base_y),
			Vector2(inner_half * 0.3, base_y - beam_height * 0.88),
			Vector2(-inner_half * 0.3, base_y - beam_height * 0.88),
		]),
		PackedColorArray([inner_bot, inner_bot, inner_top, inner_top]),
	)
	# Soft halo behind the bobbing icon.
	var icon_center := Vector2(0, bob - 6.0)
	MapArt.glow(self, icon_center, 34.0 if legendary else 26.0, Color(glow, (0.48 if legendary else 0.3) * pulse))
	# Orbiting & gently rising sparkle motes along the pillar (when Juice is on).
	if alive:
		var mote_count := 6 if legendary else 3
		for i in mote_count:
			var life := fposmod(_time * (0.65 if legendary else 0.5) + float(i) / mote_count, 1.0)
			var ang := _time * (2.6 if legendary else 1.7) + TAU * i / mote_count
			var spread := (20.0 if legendary else 13.0) * (1.0 - 0.35 * life)
			var pos := Vector2(cos(ang) * spread, base_y - 8.0 - life * (beam_height * 0.78))
			var alpha := sin(life * PI) * (0.95 if legendary else 0.65)
			var sz := (4.8 if legendary else 2.8) * (0.7 + 0.3 * sin(_time * 7.0 + i * 1.9))
			if legendary:
				var narrow := sz * 0.28
				draw_colored_polygon(PackedVector2Array([
					pos + Vector2(0, -sz), pos + Vector2(narrow, -narrow),
					pos + Vector2(sz, 0), pos + Vector2(narrow, narrow),
					pos + Vector2(0, sz), pos + Vector2(-narrow, narrow),
					pos + Vector2(-sz, 0), pos + Vector2(-narrow, -narrow),
				]), Color(core_tint, alpha))
			else:
				draw_circle(pos, sz * 0.75, Color(core_tint, alpha))
	draw_texture_rect(item.icon, Rect2(-ICON_SIZE * 0.5, -ICON_SIZE * 0.5 + bob - 6.0, ICON_SIZE, ICON_SIZE), false)

class_name SummonerSlot
extends Control
## One summoner spell on the HUD, right of the skills: its icon, cooldown sweep
## and seconds, and its key. Hover the icon for the spell's card.

const SIZE := 48.0
const FILL := Color(0.09, 0.105, 0.14)
const FRAME_COLOR := Color(0.36, 0.4, 0.48)
const CHAIN := preload("res://assets/art/ui/chain.svg")
const SWEEP_COLOR := Color(0, 0, 0, 0.65)

var lucian: Lucian
## 0 = D, 1 = F.
var slot := 0


func _init(target: Lucian, summoner_slot: int) -> void:
	lucian = target
	slot = summoner_slot
	custom_minimum_size = Vector2(SIZE, SkillSlot.PLUS_HEIGHT + SkillSlot.ICON_SIZE + SkillSlot.DOTS_HEIGHT)
	mouse_filter = MOUSE_FILTER_PASS


## Flash's and Smite's range, shown around Lucian while hovered.
func hover_range() -> CastRange:
	return lucian.summoner_range(slot)


func tooltip_content() -> Control:
	if slot >= lucian.summoners.open_slots:
		return TooltipCard.note("Locked: buy the 2nd summoner slot in the Evolution Tree.")
	var spell := lucian.summoners.spell_in(slot)
	if spell == null:
		return TooltipCard.note("No spell: pick one in Journey before starting.")
	return TooltipCard.summoner(spell, _key(), lucian.summoners.upgrade_text(spell.id))


func tooltip_place() -> HoverTip.Place:
	return HoverTip.Place.ABOVE


func _process(_delta: float) -> void:
	queue_redraw()


## Only the icon counts for hovering, not the space above and below it.
func _has_point(point: Vector2) -> bool:
	return _icon_rect().has_point(point)


func _draw() -> void:
	var rect := _icon_rect()
	var spell := lucian.summoners.spell_in(slot)
	draw_rect(rect, FILL)
	if spell == null:
		draw_rect(rect, FRAME_COLOR, false, 2.0)
		if slot >= lucian.summoners.open_slots:
			draw_texture_rect(CHAIN, rect.grow(-8.0), false, Color(1, 1, 1, 0.85))
		return
	draw_texture_rect(spell.icon, rect, false)
	var cooldown := lucian.summoners.cooldown(spell.id)
	if not cooldown.is_ready():
		draw_set_transform(rect.position)
		draw_colored_polygon(SkillSlot.sweep_polygon(cooldown.fraction_remaining(), SIZE), SWEEP_COLOR)
		draw_set_transform(Vector2.ZERO)
		var text := "%.1f" % cooldown.remaining if cooldown.remaining < 1.0 else str(ceili(cooldown.remaining))
		var at := Vector2(rect.position.x, rect.get_center().y + 7.0)
		_text(at, text, HORIZONTAL_ALIGNMENT_CENTER, SIZE, 20)
	draw_rect(rect, FRAME_COLOR, false, 2.0)
	_text(Vector2(rect.position.x, rect.end.y - 3.0), _key(), HORIZONTAL_ALIGNMENT_RIGHT, SIZE - 3.0, 12)


func _icon_rect() -> Rect2:
	return Rect2(0, SkillSlot.PLUS_HEIGHT + (SkillSlot.ICON_SIZE - SIZE) * 0.5, SIZE, SIZE)


func _key() -> String:
	return GameSettings.instance().key_label(LucianController.SUMMONER_ACTIONS[slot])


func _text(at: Vector2, text: String, align: HorizontalAlignment, width: float, font_size: int) -> void:
	var font := ThemeDB.fallback_font
	draw_string_outline(font, at, text, align, width, font_size, 4, Color.BLACK)
	draw_string(font, at, text, align, width, font_size, Color.WHITE)

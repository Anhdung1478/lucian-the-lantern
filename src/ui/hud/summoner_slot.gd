class_name SummonerSlot
extends Control
## One summoner spell on the HUD, right of the skills, in a dark cell: its
## icon, cooldown sweep and seconds, and its key in the corner tab. The rim
## turns gold while the mouse is on the icon; hover it for the spell's card.

const SIZE := 48.0
const CHAIN := preload("res://assets/art/ui/chain.svg")
const SWEEP_COLOR := Color(0, 0, 0, 0.65)

var lucian: Lucian
## 0 = D, 1 = F.
var slot := 0

## The mouse is on the icon: its rim is gold.
var _hovered := false


func _init(target: Lucian, summoner_slot: int) -> void:
	lucian = target
	slot = summoner_slot
	custom_minimum_size = Vector2(SIZE, SkillSlot.PLUS_HEIGHT + SkillSlot.ICON_SIZE + SkillSlot.DOTS_HEIGHT)
	mouse_filter = MOUSE_FILTER_PASS
	mouse_entered.connect(func() -> void: _hovered = true)
	mouse_exited.connect(func() -> void: _hovered = false)


## Flash's and Smite's range, shown around Lucian while hovered.
func hover_range() -> CastRange:
	return lucian.summoner_range(slot)


func tooltip_content() -> Control:
	if slot >= lucian.summoners.open_slots:
		return TooltipCard.note("Locked: buy the 2nd summoner slot in the Evolution Tree.")
	var spell := lucian.summoners.spell_in(slot)
	if spell == null:
		return TooltipCard.note("No spell: pick one in Journey before starting.")
	var summoners := lucian.summoners
	return TooltipCard.summoner(spell, _key(), summoners.cooldown_of(spell), summoners.upgrade_text(spell.id))


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
	HudCell.draw_box(self, rect, UiStyle.CELL_BORDER, _hovered)
	if spell == null:
		if slot >= lucian.summoners.open_slots:
			draw_texture_rect(CHAIN, rect.grow(-8.0), false, Color(1, 1, 1, 0.85))
		return
	var inner := rect.grow(-HudCell.INSET)
	draw_texture_rect(spell.icon, inner, false)
	var cooldown := lucian.summoners.cooldown(spell.id)
	if not cooldown.is_ready():
		draw_set_transform(inner.position)
		draw_colored_polygon(SkillSlot.sweep_polygon(cooldown.fraction_remaining(), inner.size.x), SWEEP_COLOR)
		draw_set_transform(Vector2.ZERO)
		var at := Vector2(rect.position.x, rect.get_center().y + 7.0)
		HudCell.draw_text(self, at, HudCell.seconds_text(cooldown.remaining), HORIZONTAL_ALIGNMENT_CENTER, SIZE, 20)
	HudCell.draw_key(self, rect, _key())


func _icon_rect() -> Rect2:
	return Rect2(0, SkillSlot.PLUS_HEIGHT + (SkillSlot.ICON_SIZE - SIZE) * 0.5, SIZE, SIZE)


func _key() -> String:
	return GameSettings.instance().short_key_label(LucianController.SUMMONER_ACTIONS[slot])

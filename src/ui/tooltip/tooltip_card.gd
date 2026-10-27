class_name TooltipCard
extends RefCounted
## Builds LoL-style tooltip cards: a dark panel with a gold border, a header
## (icon, name, a line under it, something on the right) and a rich text body.

const WIDTH := 400.0
const ICON_SIZE := 48.0
const BODY_FONT_SIZE := 16
const BG_COLOR := Color(0.04, 0.05, 0.07, 0.97)
const BORDER_COLOR := Color(0.79, 0.64, 0.36)
const NAME_COLOR := Color("ffe9a8")
const SUB_COLOR := Color("9aa3b2")
const KIND_NAMES := {ItemData.Kind.FRAGMENT: "Fragment", ItemData.Kind.LEGENDARY: "Legendary", ItemData.Kind.POTION: "Potion"}


static func item(shown: ItemData, catalog: ItemCatalog) -> Control:
	var icon := ItemIcon.new(shown)
	icon.tooltips = false
	var cost := TooltipText.color("%d gold" % shown.cost, TooltipText.GOLD)
	var card := _card(icon, shown.display_name, KIND_NAMES[shown.kind], cost)
	var stats: PackedStringArray = []
	for key: StringName in shown.stats:
		stats.append(ItemStats.line(key, shown.stats[key]))
	_body(card, "\n".join(stats))
	if shown.is_potion():
		_body(card, potion_text(shown))
	var effects: PackedStringArray = []
	for effect in shown.effects:
		var label := "Active — %s (%s s)" % [effect.effect_name, TooltipText.number(effect.cooldown)] \
			if effect.active else "Passive — %s" % effect.effect_name
		effects.append("%s: %s" % [TooltipText.color(label, TooltipText.GOLD), TooltipText.colorize(effect.description)])
	if not effects.is_empty():
		_separator(card)
		_body(card, "\n\n".join(effects))
	var footer := ""
	if shown.is_fragment():
		footer = "Drag onto another fragment to craft a legendary."
	elif shown.is_potion():
		footer = "Right-click it in the backpack to drink, or put it in slot 1-6 and press its key. Stacks up to %d." % shown.max_stack
	elif catalog and shown.components.size() == 2:
		footer = "Recipe: %s + %s" % [
			catalog.find(shown.components[0]).display_name, catalog.find(shown.components[1]).display_name]
	if footer != "":
		_separator(card)
		_body(card, TooltipText.color(footer, TooltipText.DIM))
	return card


## "Restores 200 HP over 5 s." with the HP / mana colored.
static func potion_text(shown: ItemData) -> String:
	var parts: PackedStringArray = []
	if shown.restore_hp > 0.0:
		parts.append("[hp]%s HP[/hp]" % TooltipText.number(shown.restore_hp))
	if shown.restore_mana > 0.0:
		parts.append("[mana]%s mana[/mana]" % TooltipText.number(shown.restore_mana))
	return TooltipText.colorize("Restores %s over [kw]%s s[/kw]." % [" and ".join(parts), TooltipText.number(shown.restore_time)])


## A skill's card. `skill` is null for the passive.
static func skill(lucian: Lucian, shown: LucianSkill, icon_texture: Texture2D, key: String) -> Control:
	var icon := TextureRect.new()
	icon.texture = icon_texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	if shown == null:
		var card := _card(icon, "Lightslinger", "Passive", "")
		_body(card, lucian.passive.describe())
		return card
	var data := shown.data
	var rank := shown.rank()
	var rank_text := TooltipText.color("Rank %d/%d" % [rank, data.max_rank], TooltipText.TEXT if rank > 0 else TooltipText.DIM)
	var card := _card(icon, data.display_name, "[%s]" % key, rank_text)
	var costs: PackedStringArray = []
	if data.mana_cost.any(func(value: float) -> bool: return value > 0.0):
		costs.append(TooltipText.color("Cost: ", TooltipText.DIM) + TooltipText.ranked(data.mana_cost, rank) + TooltipText.colorize(" [mana]Mana[/mana]"))
	costs.append(TooltipText.color("Cooldown: ", TooltipText.DIM) + TooltipText.ranked(data.cooldown, rank) + " s")
	_body(card, "
".join(costs))
	_separator(card)
	_body(card, shown.describe())
	var bonus := shown.max_rank_bonus()
	if bonus != "":
		var reached := shown.is_max_rank()
		_body(card, TooltipText.color("Rank %d: " % data.max_rank, TooltipText.GOLD if reached else TooltipText.DIM)
			+ TooltipText.color(bonus, TooltipText.TEXT if reached else TooltipText.DIM))
	return card


## A HUD buff's card: icon, name, time left and what it does.
static func buff(shown: Dictionary) -> Control:
	var icon := TextureRect.new()
	icon.texture = shown.icon
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var subtitle := "Buff"
	if shown.duration > 0.0:
		subtitle = "%s s left" % TooltipText.number(snappedf(shown.left, 0.1))
	var card := _card(icon, shown.name, subtitle, "")
	_body(card, TooltipText.colorize(shown.text))
	return card


## A small card with one line of text.
static func note(text: String) -> Control:
	var card := _panel()
	var label := Label.new()
	label.text = text
	label.add_theme_color_override(&"font_color", Color(TooltipText.TEXT))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.get_child(0).add_child(label)
	return card


static func _panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = BG_COLOR
	style.border_color = BORDER_COLOR
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override(&"panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 8)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(box)
	return panel


static func _card(icon: Control, title: String, subtitle: String, right_bbcode: String) -> PanelContainer:
	var card := _panel()
	card.custom_minimum_size.x = WIDTH
	var header := HBoxContainer.new()
	header.add_theme_constant_override(&"separation", 12)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.get_child(0).add_child(header)
	icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(icon)
	var names := VBoxContainer.new()
	names.add_theme_constant_override(&"separation", 0)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(names)
	names.add_child(_label(title, 20, NAME_COLOR))
	names.add_child(_label(subtitle, 14, SUB_COLOR))
	if right_bbcode != "":
		var right := _rich(right_bbcode)
		right.custom_minimum_size.x = 0.0
		right.fit_content = true
		right.autowrap_mode = TextServer.AUTOWRAP_OFF
		right.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		header.add_child(right)
	_separator(card)
	return card


static func _body(card: PanelContainer, bbcode: String) -> void:
	if bbcode == "":
		return
	var body := _rich(bbcode)
	body.custom_minimum_size.x = WIDTH - 24.0
	card.get_child(0).add_child(body)


static func _rich(bbcode: String) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override(&"normal_font_size", BODY_FONT_SIZE)
	label.add_theme_color_override(&"default_color", Color(TooltipText.TEXT))
	label.text = bbcode
	return label


static func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


static func _separator(card: PanelContainer) -> void:
	var line := ColorRect.new()
	line.color = Color(BORDER_COLOR, 0.35)
	line.custom_minimum_size.y = 1.0
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.get_child(0).add_child(line)

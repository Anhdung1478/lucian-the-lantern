class_name RecipeTable
extends PanelContainer
## The crafting recipes shown beside the backpack: one scrollable line per
## legendary, "[fragment] + [fragment] = [legendary]". Every icon has its card.

const ICON_SIZE := 40.0
const WIDTH := 300.0
const MAX_HEIGHT := 860.0


func setup(catalog: ItemCatalog) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = TooltipCard.BG_COLOR
	style.border_color = TooltipCard.BORDER_COLOR
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	add_theme_stylebox_override(&"panel", style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 8)
	add_child(box)
	var title := Label.new()
	title.text = "RECIPES"
	title.add_theme_color_override(&"font_color", TooltipCard.NAME_COLOR)
	title.add_theme_font_size_override(&"font_size", 20)
	box.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(WIDTH, MAX_HEIGHT)
	box.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override(&"separation", 6)
	scroll.add_child(rows)
	for legendary in catalog.legendaries():
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 10)
		rows.add_child(row)
		_icon(row, catalog.find(legendary.components[0]), catalog)
		_sign(row, "+")
		_icon(row, catalog.find(legendary.components[1]), catalog)
		_sign(row, "=")
		_icon(row, legendary, catalog)


func _icon(row: HBoxContainer, item: ItemData, catalog: ItemCatalog) -> void:
	var icon := ItemIcon.new(item, catalog)
	icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	row.add_child(icon)


func _sign(row: HBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override(&"font_size", 20)
	label.add_theme_color_override(&"font_color", TooltipCard.SUB_COLOR)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)

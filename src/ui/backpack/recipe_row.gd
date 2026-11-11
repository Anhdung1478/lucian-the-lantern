class_name RecipeRow
extends PanelContainer
## One line of the recipe table: [fragment] + [fragment] = [legendary], then
## the legendary's name. A fragment Lucian holds has a gold rim. With both
## held the whole line is lit gold: the merchant's Craft tab would make it
## (RecipeTable.can_craft). Every icon has its card.

const ICON_SIZE := 42.0
const GAP := 6
const PAD := 4.0
const SIGN_FONT := 18
const NAME_FONT := 13
## Room for a long name on two lines ("Lord Dominik's / Regards").
const NAME_WIDTH := 112.0
## A lit line: a gold wash and a thin gold frame.
const LIT_FILL := Color(1.0, 0.81, 0.35, 0.1)
const LIT_FRAME := Color(1.0, 0.81, 0.35, 0.6)
const RADIUS := 6

var legendary: ItemData
## Lucian holds both fragments.
var lit := false

var _parts: Array[ItemIcon] = []
var _made: ItemIcon
var _signs: Array[Label] = []
var _name: Label


func _init(made: ItemData, catalog: ItemCatalog) -> void:
	legendary = made
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", GAP)
	add_child(row)
	for part in 2:
		_parts.append(_icon(row, catalog.find(made.components[part]), catalog))
		_signs.append(_sign(row, "+" if part == 0 else "="))
	_made = _icon(row, made, catalog)
	_name = UiStyle.label(made.display_name, NAME_FONT)
	_name.custom_minimum_size.x = NAME_WIDTH
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name.max_lines_visible = 2
	_name.add_theme_constant_override(&"line_spacing", -2)
	row.add_child(_name)
	refresh(null)


## Lights the fragments `inventory` holds, and the line when it holds both.
func refresh(inventory: Inventory) -> void:
	lit = RecipeTable.can_craft(legendary, inventory)
	for part in 2:
		_parts[part].lit = inventory != null and RecipeTable.holds_part(legendary, part, inventory)
		_signs[part].add_theme_color_override(&"font_color", UiStyle.GOLD_COLOR if lit else UiStyle.DIM_COLOR)
	_made.lit = lit
	_name.add_theme_color_override(&"font_color", UiStyle.GOLD_COLOR if lit else UiStyle.TEXT_COLOR)
	var style := StyleBoxFlat.new()
	style.bg_color = LIT_FILL if lit else Color.TRANSPARENT
	style.border_color = LIT_FRAME if lit else Color.TRANSPARENT
	style.set_border_width_all(1)
	style.set_corner_radius_all(RADIUS)
	style.set_content_margin_all(PAD)
	add_theme_stylebox_override(&"panel", style)


func _icon(row: HBoxContainer, item: ItemData, catalog: ItemCatalog) -> ItemIcon:
	var icon := ItemIcon.new(item, catalog)
	icon.framed = true
	icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	row.add_child(icon)
	return icon


func _sign(row: HBoxContainer, text: String) -> Label:
	var label := UiStyle.label(text, SIGN_FONT, UiStyle.DIM_COLOR)
	row.add_child(label)
	return label

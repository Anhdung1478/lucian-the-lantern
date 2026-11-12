class_name RecipeRow
extends PanelContainer
## One line of the recipe table: [part] + [part] = [what it makes], then its
## name. A legendary's parts are its two fragments. Upgraded boots' are the
## boots they come from and their fragment; the starting boots share the
## first cell of a second-tier line (RecipeChoice), since either pair makes
## the same boots. A part Lucian holds, or wears, has a gold rim. With both
## the whole line is lit gold: the merchant's Craft tab would make it
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

## The legendary or the boots the line makes.
var made: ItemData
## Lucian has both parts.
var lit := false

## An ItemIcon each, or a RecipeChoice for a part that can be either of
## several items.
var _parts: Array[Control] = []
var _result: ItemIcon
var _signs: Array[Label] = []
var _name: Label


func _init(item: ItemData, catalog: ItemCatalog) -> void:
	made = item
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", GAP)
	add_child(row)
	var parts := RecipeTable.parts(made, catalog)
	for part in 2:
		_parts.append(_part(row, parts[part], catalog))
		_signs.append(_sign(row, "+" if part == 0 else "="))
	_result = _icon(row, made, catalog)
	_name = UiStyle.label(made.display_name, NAME_FONT)
	_name.custom_minimum_size.x = NAME_WIDTH
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name.max_lines_visible = 2
	_name.add_theme_constant_override(&"line_spacing", -2)
	row.add_child(_name)
	refresh(null)


## Lights the parts `inventory` has, and the line when it has both.
func refresh(inventory: Inventory) -> void:
	lit = RecipeTable.can_craft(made, inventory)
	for part in 2:
		_parts[part].set(&"lit", inventory != null and RecipeTable.holds_part(made, part, inventory))
		_signs[part].add_theme_color_override(&"font_color", UiStyle.GOLD_COLOR if lit else UiStyle.DIM_COLOR)
	_result.lit = lit
	_name.add_theme_color_override(&"font_color", UiStyle.GOLD_COLOR if lit else UiStyle.TEXT_COLOR)
	var style := StyleBoxFlat.new()
	style.bg_color = LIT_FILL if lit else Color.TRANSPARENT
	style.border_color = LIT_FRAME if lit else Color.TRANSPARENT
	style.set_border_width_all(1)
	style.set_corner_radius_all(RADIUS)
	style.set_content_margin_all(PAD)
	add_theme_stylebox_override(&"panel", style)


## A part's cell: its one item, or the items it can be sharing the cell.
func _part(row: HBoxContainer, options: Array[ItemData], catalog: ItemCatalog) -> Control:
	if options.size() == 1:
		return _icon(row, options[0], catalog)
	var choice := RecipeChoice.new(options, catalog)
	choice.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	row.add_child(choice)
	return choice


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

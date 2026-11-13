class_name RecipeRow
extends PanelContainer
## One line of the recipe table: [part] + [part] = [what it makes], then its
## name. A legendary's parts are its two fragments. Upgraded boots' are the
## boots they come from and their fragment; the starting boots share the
## first cell of a second-tier line (RecipeChoice), since either pair makes
## the same boots. With both parts held (or worn) the line is lit: a raised
## fill and a gold name, eased in and out; the merchant's Craft tab would make
## it (RecipeTable.can_craft). The cells keep their kind's rim. Every icon has
## its card.

const ICON_SIZE := 40.0
## Between the cells; the name keeps twice that from the result. The signs
## sit closer to their cells (SIGN_GAP, less than none: a sign has room of
## its own): the room goes to the names.
const GAP := 5
const SIGN_GAP := -1
## Around the line (its right side keeps UiStyle.INSET from the name).
const PAD := 4.0
const PAD_Y := 6.0
const SIGN_FONT := 16
const NAME_FONT := UiStyle.FONT_NOTE
## Room for a long name on two lines ("Lord Dominik's / Regards").
const NAME_WIDTH := 112.0
## A lit line: a raised fill, no frame.
const LIT_FILL := UiStyle.SURFACE_RAISED
const RADIUS := 6

## The legendary or the boots the line makes.
var made: ItemData
## Lucian has both parts.
var lit := false
## The lit look, 0 to 1 (UiMotion.lit).
var lit_t := 0.0

## An ItemIcon each, or a RecipeChoice for a part that can be either of
## several items.
var _parts: Array[Control] = []
var _result: ItemIcon
var _signs: Array[Label] = []
var _name: Label


func _init(item: ItemData, catalog: ItemCatalog) -> void:
	made = item
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", SIGN_GAP)
	add_child(row)
	var parts := RecipeTable.parts(made, catalog)
	for part in 2:
		_parts.append(_part(row, parts[part], catalog))
		_signs.append(_sign(row, "+" if part == 0 else "="))
	_result = _icon(row, made, catalog)
	# Blanks between the result and its name make the gap there twice GAP.
	_blank(row, GAP * 2 - 2 * SIGN_GAP)
	_name = UiStyle.label(Lang.t(made.display_name), NAME_FONT)
	_name.custom_minimum_size.x = NAME_WIDTH
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name.max_lines_visible = 2
	# Two lines fit the icons' height, so every line is as tall.
	_name.add_theme_constant_override(&"line_spacing", -4)
	row.add_child(_name)
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(RADIUS)
	style.set_content_margin_all(PAD)
	style.content_margin_top = PAD_Y
	style.content_margin_bottom = PAD_Y
	# The name keeps INSET from the row's right edge, lit or not.
	style.content_margin_right = UiStyle.INSET
	add_theme_stylebox_override(&"panel", style)
	refresh(null)


## Lights the parts `inventory` has, and the line when it has both.
func refresh(inventory: Inventory) -> void:
	lit = RecipeTable.can_craft(made, inventory)
	for part in 2:
		_parts[part].set(&"lit", inventory != null and RecipeTable.holds_part(made, part, inventory))
	_result.lit = lit
	UiMotion.lit(self, lit, _show_lit)


## The lit look part way (`t`, 0 to 1): the fill, the name and the signs.
func _show_lit(t: float) -> void:
	(get_theme_stylebox(&"panel") as StyleBoxFlat).bg_color = Color(LIT_FILL, t)
	# Exactly gold once lit (a lerp to 1 is not quite).
	var gold := t >= 1.0
	_name.add_theme_color_override(&"font_color", UiStyle.GOLD_COLOR if gold else UiStyle.TEXT_COLOR.lerp(UiStyle.GOLD_COLOR, t))
	for sign in _signs:
		sign.add_theme_color_override(&"font_color", UiStyle.GOLD_COLOR if gold else UiStyle.DIM_COLOR.lerp(UiStyle.GOLD_COLOR, t))


## A part's cell: its one item, or the items it can be sharing the cell.
func _part(row: HBoxContainer, options: Array[ItemData], catalog: ItemCatalog) -> Control:
	if options.size() == 1:
		return _icon(row, options[0], catalog)
	var choice := RecipeChoice.new(options, catalog)
	choice.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	choice.show_lit = false
	row.add_child(choice)
	return choice


func _icon(row: HBoxContainer, item: ItemData, catalog: ItemCatalog) -> ItemIcon:
	var icon := ItemIcon.new(item, catalog)
	icon.framed = true
	icon.show_lit = false
	icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	row.add_child(icon)
	return icon


func _sign(row: HBoxContainer, text: String) -> Label:
	var label := UiStyle.label(text, SIGN_FONT, UiStyle.DIM_COLOR)
	row.add_child(label)
	return label


## A plain space `width` wide.
func _blank(row: HBoxContainer, width: float) -> void:
	var blank := Control.new()
	blank.custom_minimum_size.x = width
	blank.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(blank)

class_name BackpackScreen
extends CanvasLayer
## The backpack (P): 7x7 tan cells, and below them, outside the backpack, the
## dark equip row (slots 1-6 and the sell slot, which only matters once the
## merchant exists). The recipe table sits top-left while it is open.

const COLUMNS := 7
const CELL_GAP := 6
## The backpack is centered in the screen area above the HUD panel.
const AREA_BOTTOM := 880.0
const ROW_GAP := 18.0
const PANEL_COLOR := Color("4a3524")
const PANEL_BORDER := Color("2b1f15")
const STRIP_COLOR := Color("1f1812")
const STRIP_BORDER := Color("8c6e45")
const TITLE_COLOR := Color("f3e2b8")
const MARGIN := 16.0

var inventory: Inventory

var _cells: Array[ItemCell] = []
var _column: VBoxContainer


func _ready() -> void:
	layer = 30
	visible = false


func setup(target_inventory: Inventory) -> void:
	inventory = target_inventory
	inventory.changed.connect(_redraw_cells)
	_build()


func open() -> void:
	visible = true
	_redraw_cells()


func close() -> void:
	visible = false


## Index of the item being dragged, or -1.
func dragged_index() -> int:
	return -1


## Index of the cell the dragged item is over, or -1.
func target_index() -> int:
	return -1


func is_dragging() -> bool:
	return dragged_index() >= 0


func on_cell_input(_cell: ItemCell, _event: InputEvent) -> void:
	pass


func _redraw_cells() -> void:
	for cell in _cells:
		cell.queue_redraw()


func _build() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.45)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var recipes := RecipeTable.new()
	recipes.setup(inventory.catalog)
	recipes.position = Vector2(MARGIN, MARGIN)
	backdrop.add_child(recipes)

	_column = VBoxContainer.new()
	_column.add_theme_constant_override(&"separation", int(ROW_GAP))
	backdrop.add_child(_column)

	var pack := _panel(PANEL_COLOR, PANEL_BORDER, 3, 20)
	_column.add_child(pack)
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 12)
	pack.add_child(box)
	var title := Label.new()
	title.text = "BACKPACK"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 26)
	title.add_theme_color_override(&"font_color", TITLE_COLOR)
	box.add_child(title)
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override(&"h_separation", CELL_GAP)
	grid.add_theme_constant_override(&"v_separation", CELL_GAP)
	box.add_child(grid)
	for i in Inventory.BACKPACK_SIZE:
		_add_cell(grid, i, ItemCell.Style.BACKPACK)

	var strip := _panel(STRIP_COLOR, STRIP_BORDER, 2, 14)
	strip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_column.add_child(strip)
	var equip_row := HBoxContainer.new()
	equip_row.add_theme_constant_override(&"separation", CELL_GAP)
	strip.add_child(equip_row)
	for i in Inventory.EQUIP_SIZE:
		_add_cell(equip_row, Inventory.EQUIP_START + i, ItemCell.Style.EQUIP)
	_add_cell(equip_row, -1, ItemCell.Style.SELL)

	_column.resized.connect(_place_column)
	_place_column.call_deferred()


func _place_column() -> void:
	var width := get_viewport().get_visible_rect().size.x
	var size := _column.get_combined_minimum_size()
	_column.position = Vector2((width - size.x) * 0.5, maxf((AREA_BOTTOM - size.y) * 0.5, MARGIN))


func _add_cell(parent: Control, index: int, style: ItemCell.Style) -> void:
	var cell := ItemCell.new(index, style, self)
	parent.add_child(cell)
	_cells.append(cell)


func _panel(color: Color, border: Color, border_width: int, margin: float) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(margin)
	panel.add_theme_stylebox_override(&"panel", style)
	return panel

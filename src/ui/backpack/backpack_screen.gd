class_name BackpackScreen
extends CanvasLayer
## The backpack (P): 7x7 tan cells, and below them, outside the backpack, the
## dark equip row (slots 1-6 and the sell slot, which only matters once the
## merchant exists). The recipe table sits top-left while it is open.
##
## Dragging: holding the left button on an item (or moving while holding)
## picks it up; releasing drops it, decided by Inventory.drop_outcome. Held
## over its recipe partner, the craft pop-up's line runs around in CRAFT_HOLD
## seconds; releasing after that crafts, before that swaps.

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
const HOLD_TO_PICK := 0.2
const MOVE_TO_PICK := 6.0
const CRAFT_HOLD := 1.0
const GHOST_SIZE := 56.0

var inventory: Inventory

## Added in inventory order, so _cells[i] is cell i; the sell slot comes last.
var _cells: Array[ItemCell] = []
var _column: VBoxContainer
## Cell index under the pressed button, the picked-up one, and the one the
## picked-up item is over (-1 for none).
var _press_index := -1
var _drag_index := -1
var _target := -1
var _press_position := Vector2.ZERO
var _press_time := 0.0
var _craft_time := 0.0
## Last mouse position seen by the pressed cell, which gets every mouse event
## until the button is released.
var _mouse := Vector2.ZERO
## The dragged icon and the craft pop-up sit above the debug table.
var _top := CanvasLayer.new()
var _ghost := ItemIcon.new()
var _craft_popup := CraftPopup.new()


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


## Closing mid-drag puts the item back.
func close() -> void:
	_end_drag()
	visible = false


## Index of the item being dragged, or -1.
func dragged_index() -> int:
	return _drag_index


## Index of the cell the dragged item is over, or -1.
func target_index() -> int:
	return _target if _drag_index >= 0 else -1


func is_dragging() -> bool:
	return _drag_index >= 0


func on_cell_input(cell: ItemCell, event: InputEvent) -> void:
	var mouse_event := event as InputEventMouse
	if mouse_event == null:
		return
	_mouse = mouse_event.global_position
	var button := event as InputEventMouseButton
	if button and button.button_index == MOUSE_BUTTON_LEFT:
		if button.pressed and cell.item() and not cell.is_locked():
			_press_index = cell.index
			_press_position = _mouse
			_press_time = 0.0
		elif not button.pressed:
			_release()
	elif event is InputEventMouseMotion and _press_index >= 0 and _drag_index < 0 			and _mouse.distance_to(_press_position) > MOVE_TO_PICK:
		_pick_up()


func _process(delta: float) -> void:
	if _press_index < 0:
		return
	if _drag_index < 0:
		_press_time += delta
		if _press_time >= HOLD_TO_PICK:
			_pick_up()
		return
	_ghost.position = _mouse - _ghost.size * 0.5
	var target := _cell_index_at(_mouse)
	if target != _target:
		_target = target
		_craft_time = 0.0
		_update_craft_popup()
		_redraw_cells()
	elif _craft_popup.visible:
		_craft_time += delta
		_craft_popup.progress = _craft_time / CRAFT_HOLD


## Alt-tabbing away mid-drag puts the item back.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_end_drag()


func _pick_up() -> void:
	_drag_index = _press_index
	_target = _press_index
	_ghost.item = inventory.item_at(_drag_index)
	_ghost.position = _mouse - _ghost.size * 0.5
	_ghost.visible = true
	_redraw_cells()


func _release() -> void:
	if _drag_index >= 0:
		var craft_ready := _craft_popup.visible and _craft_time >= CRAFT_HOLD
		inventory.apply_drop(_drag_index, _target, craft_ready)
	_end_drag()


func _end_drag() -> void:
	_press_index = -1
	_drag_index = -1
	_target = -1
	_craft_time = 0.0
	_ghost.visible = false
	_craft_popup.visible = false
	_redraw_cells()


func _update_craft_popup() -> void:
	var result: ItemData = null
	if _target >= 0 and not inventory.is_locked(_target):
		result = inventory.craft_result(_drag_index, _target)
	if result == null:
		_craft_popup.visible = false
		return
	_craft_popup.show_result(result, inventory.catalog, _cells[_target].get_global_rect())


## Inventory index of the cell at `point`; -1 outside any cell and for the
## sell slot.
func _cell_index_at(point: Vector2) -> int:
	for cell in _cells:
		if cell.get_global_rect().has_point(point):
			return cell.index
	return -1


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

	_top.layer = 100
	add_child(_top)
	_ghost.tooltips = false
	_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ghost.size = Vector2(GHOST_SIZE, GHOST_SIZE)
	_ghost.visible = false
	_top.add_child(_ghost)
	_top.add_child(_craft_popup)


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

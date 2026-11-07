class_name BackpackScreen
extends CanvasLayer
## The backpack (P): 9x6 tan cells, and below them, outside the backpack, the
## dark equip row (slots 1-6 and the sell slot) and the gear row (the boots
## cell, then the Health and Mana potion cells on keys 7 and 8). The recipe
## table sits top-left while it is open, shop or not.
##
## Dragging: holding the left button on an item (or moving while holding)
## picks it up; releasing drops it, decided by Inventory.drop_outcome.
## Nothing is crafted in the backpack: that is the merchant's Craft tab.
##
## Potions are drunk only with keys 7 and 8, from their potion cells (which
## check that Lucian can act); the backpack has no Use button.
##
## Shop mode (open_shop): the merchant's shop sits right of the backpack.
## Shop items are bought by dragging them onto a cell or by right-clicking
## them, and items dropped on the red sell slot are sold (boots never are).
## On the Craft tab, two fragments (or the boots and a fragment) are dragged
## onto its two inputs. An item in an input leaves the backpack view (in_craft)
## until it is dragged back out, the tab changes or the shop closes; Craft
## asks first.

## A purchase, sale or refresh went through (true) or was refused (false).
signal traded(ok: bool)

const COLUMNS := 9
const CELL_GAP := 6
## The backpack is centered in the screen area above the HUD panel.
const AREA_BOTTOM := 880.0
const ROW_GAP := 18.0
const SHOP_GAP := 36.0
const PANEL_COLOR := Color("4a3524")
const PANEL_BORDER := Color("2b1f15")
const STRIP_COLOR := Color("1f1812")
const STRIP_BORDER := Color("8c6e45")
const TITLE_COLOR := Color("f3e2b8")
const MARGIN := 16.0
## Between the equip strip and the gear strip under it.
const GEAR_GAP := 10
const HOLD_TO_PICK := 0.2
const MOVE_TO_PICK := 6.0
const GHOST_SIZE := 56.0
## Drop target of the sell slot while the shop is open.
const SELL := -2
## Drop targets of the Craft tab's two inputs.
const CRAFT_FIRST := -3
const CRAFT_SECOND := -4

var inventory: Inventory
## The open shop, or null outside shop mode.
var shop: Shop

## Added in inventory order, so _cells[i] is cell i (the potion and boots
## cells included); the sell slot comes last.
var _cells: Array[ItemCell] = []
var _column: VBoxContainer
var _recipes: RecipeTable
var _shop_panel := ShopPanel.new()
## Cell index under the pressed button, the picked-up one, and the one the
## picked-up item is over (-1 for none, SELL for the sell slot).
var _press_index := -1
var _drag_index := -1
var _target := -1
## The same for a shop slot being pressed or dragged.
var _press_slot: ShopSlot
var _drag_slot: ShopSlot
## The same for a Craft tab input being pressed or dragged.
var _press_input: CraftSlot
var _drag_input: CraftSlot
var _press_position := Vector2.ZERO
var _press_time := 0.0
## Last mouse position seen by the pressed cell, which gets every mouse event
## until the button is released.
var _mouse := Vector2.ZERO
## The dragged icon sits above the debug table.
var _top := CanvasLayer.new()
var _ghost := ItemIcon.new()
## The Craft button's question.
var _confirm := ConfirmPopup.new()
## The viewport whose size_changed places the column, while in the tree.
var _viewport: Viewport


func _ready() -> void:
	layer = 30
	visible = false


## The window can change shape mid-stage (fullscreen from the pause menu's
## Settings), so the column is placed again whenever the viewport resizes,
## shown or not.
func _enter_tree() -> void:
	_viewport = get_viewport()
	if not _viewport.size_changed.is_connected(_place_column):
		_viewport.size_changed.connect(_place_column)


func _exit_tree() -> void:
	if _viewport and _viewport.size_changed.is_connected(_place_column):
		_viewport.size_changed.disconnect(_place_column)
	_viewport = null


func setup(target_inventory: Inventory) -> void:
	inventory = target_inventory
	inventory.changed.connect(redraw_cells)
	_build()


func open() -> void:
	visible = true
	redraw_cells()


## Opens the backpack beside the merchant's shop.
func open_shop(new_shop: Shop) -> void:
	shop = new_shop
	_shop_panel.visible = true
	_shop_panel.show_tab(0)
	_shop_panel.show_refresh_cost(shop.refresh_cost)
	open()
	_place_column()


## Closing mid-drag puts the item back. Also ends shop mode: the Craft tab's
## inputs give their items back and an open Craft question is dropped.
func close() -> void:
	_end_drag()
	if _confirm.is_open():
		_confirm.answer(false)
	visible = false
	shop = null
	_shop_panel.clear_craft()
	_shop_panel.visible = false
	_place_column()


func is_shopping() -> bool:
	return shop != null


func shop_panel() -> ShopPanel:
	return _shop_panel


## Index of the item being dragged, or -1 (also while dragging from the shop
## or a Craft input).
func dragged_index() -> int:
	return _drag_index


## The Craft input being dragged from, or null.
func dragged_input() -> CraftSlot:
	return _drag_input


## Whether the item in cell `index` sits in a Craft input: the cell draws
## empty and takes no drag, drop or purchase until the item comes back. The
## item stays in the cell in the Inventory.
func in_craft(index: int) -> bool:
	return shop != null and _shop_panel.holds(index)


## The Craft button's Yes / No question.
func craft_confirm() -> ConfirmPopup:
	return _confirm


## The shop slot being dragged, or null.
func dragged_shop_slot() -> ShopSlot:
	return _drag_slot


## Index of the cell the dragged item is over, -1 for none, SELL for the
## sell slot, CRAFT_FIRST / CRAFT_SECOND for the Craft tab's inputs.
func target_index() -> int:
	return _target if is_dragging() else -1


func is_dragging() -> bool:
	return _drag_index >= 0 or _drag_slot != null or _drag_input != null


## Gold the dragged item would sell for when dropped now; 0 when it is not
## over the sell slot.
func sell_preview() -> int:
	if shop == null or _drag_index < 0 or _target != SELL:
		return 0
	return shop.sell_value(_drag_index)


## The dragged item is over the sell slot but can't be sold (boots).
func sell_refused() -> bool:
	return shop != null and _drag_index >= 0 and _target == SELL and not shop.can_sell(_drag_index)


func refresh_shop() -> void:
	if shop:
		_report(shop.refresh())


## The shop's Undo sale button: buys back the last sale.
func undo_sale() -> void:
	if shop:
		_report(shop.undo_sale())


## The Craft tab's Craft button: asks "Craft Muramana from ... for 2100
## gold?" and Yes crafts what is in its two inputs; No changes nothing. Inputs
## that make nothing, or a fee the wallet can't pay, are refused at once.
## A craft uses up both inputs' items, so both inputs empty and what it made
## shows in its cell (upgraded boots in the boots cell).
func craft() -> void:
	if shop == null:
		return
	var first := _shop_panel.first_input().index
	var second := _shop_panel.second_input().index
	if shop.craft_result(first, second) == null:
		_report(Shop.Result.NO_RECIPE)
	elif not shop.wallet.can_afford(shop.craft_fee(first, second)):
		_report(Shop.Result.NO_GOLD)
	else:
		_confirm.ask(_shop_panel.craft_question(), _craft_now)


## Yes to the Craft question.
func _craft_now() -> void:
	if shop:
		var result := shop.craft(_shop_panel.first_input().index, _shop_panel.second_input().index)
		if result == Shop.Result.OK:
			_shop_panel.clear_craft()
			Sfx.play(&"craft")
		_report(result)


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
	elif event is InputEventMouseMotion and _press_index >= 0 and _drag_index < 0 \
			and _mouse.distance_to(_press_position) > MOVE_TO_PICK:
		_pick_up()


## A Craft tab input: a right-click empties it (its item comes back to the
## backpack) and its item is dragged out like a cell's (_drop_from_input).
func on_craft_input(input: CraftSlot, event: InputEvent) -> void:
	var mouse_event := event as InputEventMouse
	if mouse_event == null or shop == null:
		return
	_mouse = mouse_event.global_position
	var button := event as InputEventMouseButton
	if button and button.pressed and button.button_index == MOUSE_BUTTON_RIGHT:
		if not is_dragging():
			input.clear()
	elif button and button.button_index == MOUSE_BUTTON_LEFT:
		if button.pressed and input.index >= 0:
			_press_input = input
			_press_position = _mouse
			_press_time = 0.0
		elif not button.pressed:
			_release()
	elif event is InputEventMouseMotion and _press_input and _drag_input == null \
			and _mouse.distance_to(_press_position) > MOVE_TO_PICK:
		_pick_up()


func on_shop_slot_input(slot: ShopSlot, event: InputEvent) -> void:
	var mouse_event := event as InputEventMouse
	if mouse_event == null or shop == null:
		return
	_mouse = mouse_event.global_position
	var button := event as InputEventMouseButton
	if button and button.pressed and button.button_index == MOUSE_BUTTON_RIGHT:
		if not is_dragging():
			_buy(slot, -1)
	elif button and button.button_index == MOUSE_BUTTON_LEFT:
		if button.pressed and slot.item():
			_press_slot = slot
			_press_position = _mouse
			_press_time = 0.0
		elif not button.pressed:
			_release()
	elif event is InputEventMouseMotion and _press_slot and _drag_slot == null \
			and _mouse.distance_to(_press_position) > MOVE_TO_PICK:
		_pick_up()


func _process(delta: float) -> void:
	if _press_index < 0 and _press_slot == null and _press_input == null:
		return
	if not is_dragging():
		_press_time += delta
		if _press_time >= HOLD_TO_PICK:
			_pick_up()
		return
	_ghost.position = _mouse - _ghost.size * 0.5
	var target := _cell_index_at(_mouse)
	if target != _target:
		_target = target
		redraw_cells()


## Alt-tabbing away mid-drag puts the item back.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_end_drag()


func _pick_up() -> void:
	if _press_slot:
		_drag_slot = _press_slot
		_target = -1
		_ghost.item = _drag_slot.item()
	elif _press_input:
		_drag_input = _press_input
		_target = _drag_input.target()
		_ghost.item = _drag_input.item()
	else:
		_drag_index = _press_index
		_target = _press_index
		_ghost.item = inventory.item_at(_drag_index)
	_ghost.position = _mouse - _ghost.size * 0.5
	_ghost.visible = true
	redraw_cells()


func _release() -> void:
	if _drag_slot:
		if _target >= 0:
			_buy(_drag_slot, _target)
	elif _drag_input:
		_drop_from_input(_drag_input, _target)
	elif _drag_index >= 0:
		if _target == SELL:
			if shop.can_sell(_drag_index):
				shop.sell(_drag_index)
				traded.emit(true)
			else:
				_shop_panel.show_message("Boots can't be sold")
				traded.emit(false)
		elif _target == CRAFT_FIRST or _target == CRAFT_SECOND:
			if not _shop_panel.load_input(_target, _drag_index):
				traded.emit(false)
		elif not in_craft(_target):
			inventory.apply_drop(_drag_index, _target)
	_end_drag()


## An item dragged out of a Craft input: dropped on the other input it moves
## there (trading places with what that held), on its own input it stays, on
## a free cell that takes it it moves into that cell, and anywhere else it
## comes back to its own cell.
func _drop_from_input(input: CraftSlot, target: int) -> void:
	if input.index < 0 or target == input.target():
		return
	if target == CRAFT_FIRST or target == CRAFT_SECOND:
		_shop_panel.move_input(input, target)
		return
	var cell := input.index
	input.clear()
	if target >= 0 and inventory.drop_outcome(cell, target) == Inventory.Drop.MOVE:
		inventory.apply_drop(cell, target)


func _end_drag() -> void:
	_press_index = -1
	_drag_index = -1
	_press_slot = null
	_drag_slot = null
	_press_input = null
	_drag_input = null
	_target = -1
	_ghost.visible = false
	redraw_cells()


func _buy(slot: ShopSlot, cell: int) -> void:
	var result: Shop.Result
	if slot.potion:
		result = shop.buy_potion(slot.potion, cell)
	else:
		result = shop.buy_slot(slot.stock_slot, cell)
	_report(result, slot)


func _report(result: Shop.Result, slot: ShopSlot = null) -> void:
	if result != Shop.Result.OK:
		_shop_panel.refuse(result, slot)
	traded.emit(result == Shop.Result.OK)


## Inventory index of the cell at `point`; -1 outside any cell. The sell slot
## is SELL while the shop is open and -1 otherwise; the Craft tab's inputs
## are CRAFT_FIRST and CRAFT_SECOND for an item dragged from a cell or an
## input.
func _cell_index_at(point: Vector2) -> int:
	for cell in _cells:
		if cell.get_global_rect().has_point(point):
			if cell.index >= 0:
				return cell.index
			return SELL if shop and _drag_index >= 0 else -1
	if shop and (_drag_index >= 0 or _drag_input):
		var input := _shop_panel.craft_input_at(point)
		if input:
			return input.target()
	return -1


## Every cell draws again (an item moved, or left or came back from a Craft
## input).
func redraw_cells() -> void:
	for cell in _cells:
		cell.queue_redraw()


func _build() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.45)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	_recipes = RecipeTable.new()
	_recipes.setup(inventory.catalog)
	_recipes.position = Vector2(MARGIN, MARGIN)
	backdrop.add_child(_recipes)

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

	# The equip strip and, under it as wide, the gear strip.
	var strips := VBoxContainer.new()
	strips.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	strips.add_theme_constant_override(&"separation", GEAR_GAP)
	_column.add_child(strips)
	var strip := _panel(STRIP_COLOR, STRIP_BORDER, 2, 14)
	strips.add_child(strip)
	var equip_row := HBoxContainer.new()
	equip_row.add_theme_constant_override(&"separation", CELL_GAP)
	strip.add_child(equip_row)
	for i in Inventory.EQUIP_SIZE:
		_add_cell(equip_row, Inventory.EQUIP_START + i, ItemCell.Style.EQUIP)
	# [Boots] ... [HP 7][MP 8], added in index order (60, 61, 62) so _cells
	# stays in inventory order; the boots cell is then moved to the front.
	var gear := _panel(STRIP_COLOR, STRIP_BORDER, 2, 14)
	strips.add_child(gear)
	var gear_row := HBoxContainer.new()
	gear_row.add_theme_constant_override(&"separation", CELL_GAP)
	gear.add_child(gear_row)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gear_row.add_child(spacer)
	_add_cell(gear_row, Inventory.HP_POTION_CELL, ItemCell.Style.POTION)
	_add_cell(gear_row, Inventory.MP_POTION_CELL, ItemCell.Style.POTION)
	_add_cell(gear_row, Inventory.BOOTS_CELL, ItemCell.Style.BOOTS)
	gear_row.move_child(_cells.back(), 0)
	_add_cell(equip_row, -1, ItemCell.Style.SELL)

	var potions: Array[ItemData] = []
	if inventory.catalog:
		potions = inventory.catalog.potions()
	_shop_panel.setup(self, potions)
	_shop_panel.visible = false
	backdrop.add_child(_shop_panel)

	_column.resized.connect(_place_column)
	_shop_panel.resized.connect(_place_column)
	_place_column.call_deferred()

	_top.layer = 100
	add_child(_top)
	_ghost.tooltips = false
	_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ghost.size = Vector2(GHOST_SIZE, GHOST_SIZE)
	_ghost.visible = false
	_top.add_child(_ghost)
	add_child(_confirm)


## Centered above the HUD panel; with the shop open, the backpack and the
## shop are centered side by side. Runs again when the column or the shop
## resizes and when the viewport does.
func _place_column() -> void:
	if _column == null:
		return
	var width := get_viewport().get_visible_rect().size.x
	var size := _column.get_combined_minimum_size()
	var shop_size := _shop_panel.get_combined_minimum_size() if _shop_panel.visible else Vector2.ZERO
	var total := size.x + (SHOP_GAP + shop_size.x if _shop_panel.visible else 0.0)
	var top := maxf((AREA_BOTTOM - size.y) * 0.5, MARGIN)
	_column.position = Vector2((width - total) * 0.5, top)
	_shop_panel.position = Vector2(_column.position.x + size.x + SHOP_GAP, top)
	_shop_panel.size = shop_size


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

class_name BackpackScreen
extends CanvasLayer
## The backpack (P), in the Lantern look: an ornate plate headed BACKPACK
## with 9x6 dark cells (a line under them says how many are open while some
## are locked), and below it one plain strip as wide, its cells on the
## backpack's nine columns: the equip slots 1-6, then the
## boots cell and the Health and Mana potion cells on keys 7 and 8. The
## recipe table sits top-left while it is open, shop or not.
##
## Dragging: holding the left button on an item (or moving while holding)
## picks it up; releasing drops it, decided by Inventory.drop_outcome.
## Nothing is crafted in the backpack: that is the merchant's Craft tab.
## A drop, purchase or craft that would equip a second penetration item is
## refused with a pop-up naming the equipped one (pen_limit_text).
##
## Potions are drunk only with keys 7 and 8, from their potion cells (which
## check that Lucian can act); the backpack has no Use button.
##
## Shop mode (open_shop): the merchant's shop sits right of the backpack, as
## tall as its column. Shop items are bought by dragging them onto a cell or
## by right-clicking them, and items dropped on the sell slot, in the
## merchant's foot, are sold (boots never are). A purchase goes into the
## backpack; with every open cell full it is refused with a pop-up
## (BACKPACK_FULL), unless the item is dragged onto a free equip slot.
## On the Craft tab, two fragments (or the boots and a fragment) are dragged
## onto its two inputs. An item in an input leaves the backpack view (in_craft)
## until it is dragged back out, the tab changes or the shop closes; Craft
## asks first.
##
## Motion (none while UiMotion.off()): the screen fades in and out; the
## merchant's panel enters from the right while the backpack eases aside to
## make room. The screen's `visible` is whether it is open and flips at once;
## what is drawn lives on an inner layer (_view) that stays up until the fade
## out ends, and ignores the mouse meanwhile. A picked-up item's icon grows a
## little; one dropped where it can't go flies back before it hides. A cell
## that receives a bought or crafted item lands it (ItemCell.land).

## A purchase, sale or refresh went through (true) or was refused (false).
signal traded(ok: bool)

const LAYER := 30
const COLUMNS := 9
const CELL_GAP := 6
## The backpack is centered in the screen area above the HUD panel.
const AREA_BOTTOM := 880.0
const ROW_GAP := 18.0
## The screen fades in over this long, and out over UiMotion.EXIT.
const FADE_TIME := UiMotion.BASE
const SHOP_GAP := 24.0
## The least room between the recipe table and the backpack.
const TABLE_GAP := 20.0
## Between the backpack's frame and its cells, and under its heading; the
## strip under it uses the same, so its cells sit on the backpack's columns.
const PACK_PAD := 22.0
const HEADING_GAP := 14
const MARGIN := 16.0
const HOLD_TO_PICK := 0.2
const MOVE_TO_PICK := 6.0
const GHOST_SIZE := 56.0
## A picked-up icon grows to GHOST_LIFT over GHOST_LIFT_TIME; one refused
## flies back to where it came from over GHOST_BACK_TIME.
const GHOST_LIFT := 1.08
const GHOST_LIFT_TIME := 0.08
const GHOST_BACK_TIME := 0.15
## Drop target of the sell slot while the shop is open.
const SELL := -2
## Drop targets of the Craft tab's two inputs.
const CRAFT_FIRST := -3
const CRAFT_SECOND := -4
## The pop-up for a purchase (or an undone sale) with no room in the backpack.
const BACKPACK_FULL := "Your backpack is full."
## The line under the grid while some cells are locked.
const OPEN_NOTE := "%d of %d cells open. Buy Backpack Slots in the Evolution Tree."

var inventory: Inventory
## The open shop, or null outside shop mode.
var shop: Shop

## Added in inventory order, so _cells[i] is cell i (the potion and boots
## cells included); the sell slot comes last.
var _cells: Array[ItemCell] = []
var _column: VBoxContainer
## What is drawn: the dim backdrop and everything on it, on an inner layer
## that outlives `visible` by the fade out.
var _view := CanvasLayer.new()
var _backdrop: ColorRect
var _fade: Tween
var _recipes: RecipeTable
var _shop_panel := ShopPanel.new()
## The line under the grid: how many cells are open.
var _open_note: Label
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
var _ghost_motion: Tween
## Where the picked-up item came from, in screen coordinates.
var _ghost_home := Rect2()
## The Craft button's question, and the full-backpack and one-penetration
## notices.
var _confirm := ConfirmPopup.new()
## The viewport whose size_changed places the column, while in the tree.
var _viewport: Viewport


func _ready() -> void:
	layer = LAYER
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


## Opens the backpack (in shop mode when `shop` is set): visible at once,
## then the backdrop fades in.
func open() -> void:
	var was_open := visible
	visible = true
	_shop_panel.visible = shop != null
	redraw_cells()
	if not was_open:
		_fade_in()
	_place_column(true)


## Opens the backpack beside the merchant's shop.
func open_shop(new_shop: Shop) -> void:
	var entering := not (visible and _shop_panel.visible)
	shop = new_shop
	_shop_panel.show_tab(0)
	_shop_panel.show_refresh_cost(shop.refresh_cost)
	open()
	if entering:
		_enter_shop_panel()


## Closing mid-drag puts the item back. Also ends shop mode: the Craft tab's
## inputs give their items back and an open Craft question or notice is
## dropped. No cell stays lit by a mouse that was over it. `visible` turns
## false at once; the drawing fades out after.
func close() -> void:
	_end_drag()
	if _confirm.is_open():
		_confirm.dismiss()
	visible = false
	for cell in _cells:
		cell.hovered = false
	shop = null
	_shop_panel.clear_craft()
	_fade_out()


func is_shopping() -> bool:
	return shop != null


## Whether the screen is open (it may still be fading out once closed).
func is_open() -> bool:
	return visible


func shop_panel() -> ShopPanel:
	return _shop_panel


## Index of the item being dragged, or -1 (also while dragging from the shop
## or a Craft input).
func dragged_index() -> int:
	return _drag_index


## The Craft input being dragged from, or null.
func dragged_input() -> CraftSlot:
	return _drag_input


## The item being dragged (from a cell, a Craft input or the shop), or null.
func dragged_item() -> ItemData:
	return _ghost.item if is_dragging() else null


## Whether the item in cell `index` sits in a Craft input: the cell draws
## empty and takes no drag, drop or purchase until the item comes back. The
## item stays in the cell in the Inventory.
func in_craft(index: int) -> bool:
	return shop != null and _shop_panel.holds(index)


## The pop-up: the Craft button's Yes / No question, and the notices for a
## full backpack and the one-penetration rule.
func craft_confirm() -> ConfirmPopup:
	return _confirm


## The one-penetration rule's notice, naming the penetration item equipped.
static func pen_limit_text(equipped: ItemData) -> String:
	return Lang.t("Only one penetration item can be equipped,\nand %s already is.") % Lang.t(equipped.display_name)


## The line under the grid for `open` cells of `total` ("" with none locked).
static func open_note(open_cells: int, total := Inventory.BACKPACK_SIZE) -> String:
	if open_cells >= total:
		return ""
	return Lang.t(OPEN_NOTE) % [open_cells, total]


## The shop slot being dragged, or null.
func dragged_shop_slot() -> ShopSlot:
	return _drag_slot


## Whether what is being dragged would land in cell `index` if dropped there:
## an item from another cell moves, swaps or stacks, one from a Craft input
## moves in, and a shop item is bought into the cell. The cell lights up gold
## (ItemCell.is_lit). False for a locked cell, one that can't hold the item,
## the cell it came from and one whose item sits in a Craft input.
func takes_drop(index: int) -> bool:
	if index < 0 or index >= Inventory.SIZE or in_craft(index):
		return false
	if _drag_index >= 0:
		return inventory.drop_outcome(_drag_index, index) != Inventory.Drop.RETURN
	if _drag_input:
		return inventory.drop_outcome(_drag_input.index, index) == Inventory.Drop.MOVE
	if _drag_slot:
		return _drag_slot.item() != null and inventory.can_put(index, _drag_slot.item())
	return false


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
		var before := _contents()
		var result := shop.undo_sale()
		if result == Shop.Result.OK:
			_land_changed(before)
		_report(result)


## The Craft tab's Craft button: asks "Craft Muramana from ... for 1600
## gold?" and Yes crafts what is in its two inputs; No changes nothing. Inputs
## that make nothing, a legendary the one-penetration rule keeps out of both
## inputs' cells, or a fee the wallet can't pay, are refused at once.
## A craft uses up both inputs' items, so both inputs empty and what it made
## shows in its cell (Shop.craft_cell; upgraded boots in the boots cell).
func craft() -> void:
	if shop == null:
		return
	var first := _shop_panel.first_input().index
	var second := _shop_panel.second_input().index
	var made := shop.craft_result(first, second)
	if made == null:
		_report(Shop.Result.NO_RECIPE)
	elif shop.craft_cell(first, second) < 0:
		_report(Shop.Result.PEN_LIMIT, null, inventory.pen_blocker(first, made))
	elif not shop.wallet.can_afford(shop.craft_fee(first, second)):
		_report(Shop.Result.NO_GOLD)
	else:
		_confirm.ask(_shop_panel.craft_question(), _craft_now)


## Yes to the Craft question.
func _craft_now() -> void:
	if shop:
		var before := _contents()
		var result := shop.craft(_shop_panel.first_input().index, _shop_panel.second_input().index)
		if result == Shop.Result.OK:
			_shop_panel.clear_craft()
			Sfx.play(&"craft")
			_land_changed(before)
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
		_ghost_home = _drag_slot.get_global_rect()
		_ghost_home = Rect2(_ghost_home.position + Vector2(ShopSlot.PAD, (_ghost_home.size.y - ShopSlot.WELL) * 0.5),
			Vector2(ShopSlot.WELL, ShopSlot.WELL))
	elif _press_input:
		_drag_input = _press_input
		_target = _drag_input.target()
		_ghost.item = _drag_input.item()
		_ghost_home = _drag_input.get_global_rect()
	else:
		_drag_index = _press_index
		_target = _press_index
		_ghost.item = inventory.item_at(_drag_index)
		_ghost_home = _cells[_drag_index].get_global_rect()
	_ghost.position = _mouse - _ghost.size * 0.5
	_ghost.visible = true
	_lift_ghost()
	redraw_cells()


## Drops what is held. A drop that goes nowhere (or is refused) sends the
## icon back to where it came from before it hides.
func _release() -> void:
	var landed := true
	if _drag_slot:
		landed = _target >= 0 and _buy(_drag_slot, _target)
	elif _drag_input:
		landed = _drop_from_input(_drag_input, _target)
	elif _drag_index >= 0:
		if _target == SELL:
			if shop.can_sell(_drag_index):
				shop.sell(_drag_index)
				traded.emit(true)
			else:
				_shop_panel.show_message(Lang.t("Boots can't be sold"))
				traded.emit(false)
				landed = false
		elif _target == CRAFT_FIRST or _target == CRAFT_SECOND:
			if not _shop_panel.load_input(_target, _drag_index):
				traded.emit(false)
				landed = false
		elif not in_craft(_target):
			landed = _drop(_drag_index, _target)
		else:
			landed = false
	else:
		landed = false
	_end_drag(not landed)


## Drops the item in cell `from` on cell `to` (Inventory.apply_drop). One the
## one-penetration rule sends back says why in the pop-up. False when the
## item stays where it was.
func _drop(from: int, to: int) -> bool:
	var blocker := inventory.drop_pen_blocker(from, to)
	if blocker:
		_confirm.tell(pen_limit_text(blocker))
		Sfx.play(&"error")
		return false
	if to == from or to < 0 or inventory.drop_outcome(from, to) == Inventory.Drop.RETURN:
		return false
	inventory.apply_drop(from, to)
	return true


## An item dragged out of a Craft input: dropped on the other input it moves
## there (trading places with what that held), on its own input it stays, on
## a free cell that takes it it moves into that cell, and anywhere else it
## comes back to its own cell. False when it stays in its input or goes back
## to its own cell (its icon flies there).
func _drop_from_input(input: CraftSlot, target: int) -> bool:
	if input.index < 0 or target == input.target():
		return false
	if target == CRAFT_FIRST or target == CRAFT_SECOND:
		_shop_panel.move_input(input, target)
		return true
	var cell := input.index
	input.clear()
	if target >= 0 and inventory.drop_outcome(cell, target) == Inventory.Drop.MOVE:
		inventory.apply_drop(cell, target)
		return true
	_ghost_home = _cells[cell].get_global_rect()
	return false


## Ends a drag. `fly_back`: the icon goes back to where it came from before
## it hides (at once while UiMotion.off()).
func _end_drag(fly_back := false) -> void:
	var was_dragging := is_dragging()
	_press_index = -1
	_drag_index = -1
	_press_slot = null
	_drag_slot = null
	_press_input = null
	_drag_input = null
	_target = -1
	if was_dragging and fly_back and _ghost.visible:
		_send_ghost_home()
	else:
		_hide_ghost()
	redraw_cells()


## Buys what `slot` sells into `cell` (-1: wherever it goes). True when it
## went through; the cell that got it lands it.
func _buy(slot: ShopSlot, cell: int) -> bool:
	var item := slot.item()
	var before := _contents()
	var result: Shop.Result
	if slot.potion:
		result = shop.buy_potion(slot.potion, cell)
	else:
		result = shop.buy_slot(slot.stock_slot, cell)
	if result == Shop.Result.OK:
		_land_changed(before)
	_report(result, slot, inventory.pen_blocker(cell, item) if cell >= 0 else null)
	return result == Shop.Result.OK


## A refused trade flashes the slot's price and says why: no room in the
## backpack and the one-penetration rule (naming `blocker`, the equipped
## penetration item) in the pop-up, the rest in the shop's red message.
func _report(result: Shop.Result, slot: ShopSlot = null, blocker: ItemData = null) -> void:
	if result == Shop.Result.NO_ROOM:
		_confirm.tell(Lang.t(BACKPACK_FULL))
	elif result == Shop.Result.PEN_LIMIT and blocker:
		_confirm.tell(pen_limit_text(blocker))
	if result != Shop.Result.OK:
		_shop_panel.refuse(result, slot)
	traded.emit(result == Shop.Result.OK)


## Every cell's item and count, to see which cells a trade filled.
func _contents() -> Array:
	var all := []
	for i in Inventory.SIZE:
		all.append([inventory.item_at(i), inventory.count_at(i)])
	return all


## The cells that got an item (a new one, or more of it) since `before` land it.
func _land_changed(before: Array) -> void:
	for i in Inventory.SIZE:
		var now := inventory.item_at(i)
		if now != null and (now != before[i][0] or inventory.count_at(i) > before[i][1]):
			_cells[i].land()


## Inventory index of the cell at `point`; -1 outside any cell. The sell slot
## is SELL while the shop is open and -1 otherwise; the Craft tab's inputs
## are CRAFT_FIRST and CRAFT_SECOND for an item dragged from a cell or an
## input.
func _cell_index_at(point: Vector2) -> int:
	for cell in _cells:
		if cell.index < 0 and not cell.is_visible_in_tree():
			continue
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
## input) and eases its gold look to match; the line under the grid follows
## the open cells.
func redraw_cells() -> void:
	for cell in _cells:
		cell.refresh_lit()
	if _open_note:
		_open_note.text = open_note(inventory.unlocked_backpack)
		_open_note.visible = _open_note.text != ""


## Shows the drawing and fades the backdrop in from where it is. Skipped
## while UiMotion.off(), and by a tree-less screen.
func _fade_in() -> void:
	if _fade and _fade.is_valid():
		_fade.kill()
	_fade = null
	_view.visible = true
	_backdrop.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_INHERITED
	if UiMotion.off() or not is_inside_tree():
		_backdrop.modulate.a = 1.0
		return
	if _backdrop.modulate.a >= 1.0:
		_backdrop.modulate.a = 0.0
	_fade = UiMotion.tween(_backdrop)
	_fade.tween_property(_backdrop, ^"modulate:a", 1.0, FADE_TIME)


## Fades the drawing out (it ignores the mouse at once), then hides it, the
## shop panel with it, and puts the column back in the middle.
func _fade_out() -> void:
	if _fade and _fade.is_valid():
		_fade.kill()
	_fade = null
	_backdrop.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	if UiMotion.off() or not is_inside_tree() or not _view.visible:
		_after_fade_out()
		return
	_fade = UiMotion.tween(_backdrop)
	_fade.tween_property(_backdrop, ^"modulate:a", 0.0, UiMotion.EXIT)
	_fade.tween_callback(_after_fade_out)


func _after_fade_out() -> void:
	_fade = null
	_view.visible = false
	_backdrop.modulate.a = 1.0
	_backdrop.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_INHERITED
	_shop_panel.visible = false
	_place_column()


## The merchant's panel enters from the right while the column makes room.
func _enter_shop_panel() -> void:
	if UiMotion.off() or not is_inside_tree():
		return
	var home: Vector2 = _shop_panel.get_meta(&"glide_to", _shop_panel.position)
	_kill_glide(_shop_panel)
	_shop_panel.position.x = home.x + UiMotion.RISE
	_shop_panel.modulate.a = 0.0
	_glide(_shop_panel, home, true)
	UiMotion.tween(_shop_panel).tween_property(_shop_panel, ^"modulate:a", 1.0, UiMotion.BASE)


func _lift_ghost() -> void:
	_stop_ghost()
	_ghost.pivot_offset = _ghost.size * 0.5
	_ghost.scale = Vector2.ONE
	if UiMotion.off():
		_ghost.scale = Vector2.ONE * GHOST_LIFT
		return
	_ghost_motion = UiMotion.tween(_ghost)
	_ghost_motion.tween_property(_ghost, ^"scale", Vector2.ONE * GHOST_LIFT, GHOST_LIFT_TIME)


## A refused drop: the icon flies back to where it came from, then hides.
func _send_ghost_home() -> void:
	_stop_ghost()
	if UiMotion.off() or not is_inside_tree() or _ghost_home.size == Vector2.ZERO:
		_hide_ghost()
		return
	var to := _ghost_home.get_center() - _ghost.size * 0.5
	_ghost_motion = UiMotion.tween(_ghost).set_parallel(true)
	_ghost_motion.tween_property(_ghost, ^"position", to, GHOST_BACK_TIME)
	_ghost_motion.tween_property(_ghost, ^"scale", Vector2.ONE, GHOST_BACK_TIME)
	_ghost_motion.chain().tween_callback(_hide_ghost)


func _hide_ghost() -> void:
	_stop_ghost()
	_ghost.visible = false
	_ghost.scale = Vector2.ONE


func _stop_ghost() -> void:
	if _ghost_motion and _ghost_motion.is_valid():
		_ghost_motion.kill()
	_ghost_motion = null


func _build() -> void:
	_view.layer = LAYER
	_view.visible = false
	add_child(_view)
	var backdrop := ColorRect.new()
	_backdrop = backdrop
	backdrop.color = Color(0, 0, 0, 0.45)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_view.add_child(backdrop)

	_recipes = RecipeTable.new()
	_recipes.setup(inventory.catalog, inventory)
	_recipes.position = Vector2(MARGIN, MARGIN)
	backdrop.add_child(_recipes)

	_column = VBoxContainer.new()
	_column.add_theme_constant_override(&"separation", int(ROW_GAP))
	backdrop.add_child(_column)

	var pack := Plate.new(PACK_PAD)
	_column.add_child(pack)
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", HEADING_GAP)
	pack.add_child(box)
	box.add_child(BagHeading.new(Lang.t("BACKPACK")))
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override(&"h_separation", CELL_GAP)
	grid.add_theme_constant_override(&"v_separation", CELL_GAP)
	box.add_child(grid)
	for i in Inventory.BACKPACK_SIZE:
		_add_cell(grid, i, ItemCell.Style.BACKPACK)
	_open_note = UiStyle.note("")
	box.add_child(_open_note)

	# One strip as wide as the backpack, its cells on the backpack's columns:
	# the equip slots, then [Boots][HP 7][MP 8]. Added in index
	# order (60, 61, 62) so _cells stays in inventory order; the boots cell is
	# then moved in front of the potions.
	var strip := Plate.new(PACK_PAD, false)
	_column.add_child(strip)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", CELL_GAP)
	strip.add_child(row)
	for i in Inventory.EQUIP_SIZE:
		_add_cell(row, Inventory.EQUIP_START + i, ItemCell.Style.EQUIP)
	_add_cell(row, Inventory.HP_POTION_CELL, ItemCell.Style.POTION)
	_add_cell(row, Inventory.MP_POTION_CELL, ItemCell.Style.POTION)
	_add_cell(row, Inventory.BOOTS_CELL, ItemCell.Style.BOOTS)
	row.move_child(_cells.back(), Inventory.EQUIP_SIZE)

	# The sell slot lives in the merchant's foot, so it only shows in the shop.
	var sell := ItemCell.new(-1, ItemCell.Style.SELL, self)
	_cells.append(sell)
	var potions: Array[ItemData] = []
	if inventory.catalog:
		potions = inventory.catalog.potions()
	_shop_panel.setup(self, potions, sell)
	_shop_panel.visible = false
	backdrop.add_child(_shop_panel)

	_column.resized.connect(_place_column)
	_column.minimum_size_changed.connect(_place_column)
	_shop_panel.resized.connect(_place_column)
	# The shop is no taller than it needs once its wrapped note is laid out.
	_shop_panel.minimum_size_changed.connect(_place_column)
	_place_column.call_deferred()

	_top.layer = 100
	add_child(_top)
	_ghost.tooltips = false
	_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ghost.size = Vector2(GHOST_SIZE, GHOST_SIZE)
	_ghost.visible = false
	_top.add_child(_ghost)
	add_child(_confirm)
	redraw_cells()


## Centered above the HUD panel; with the shop open, the backpack and the
## shop are centered side by side, tops and bottoms on the same lines (the
## shop is as tall as the column). On a narrower screen they move right,
## clear of the recipe table, as far as the screen's edge lets them. Runs
## again when the column or the shop resizes and when the viewport does.
## `animate`: the column eases to its place (opening beside the shop).
func _place_column(animate := false) -> void:
	if _column == null or not is_inside_tree():
		return
	var width := get_viewport().get_visible_rect().size.x
	var size := _column.get_combined_minimum_size()
	_shop_panel.custom_minimum_size.y = size.y
	var shop_size := _shop_panel.get_combined_minimum_size() if _shop_panel.visible else Vector2.ZERO
	var total := size.x + (SHOP_GAP + shop_size.x if _shop_panel.visible else 0.0)
	var top := maxf((AREA_BOTTOM - size.y) * 0.5, MARGIN)
	var clear := _recipes.position.x + _recipes.get_combined_minimum_size().x + TABLE_GAP
	var left := minf(maxf((width - total) * 0.5, clear), width - MARGIN - total)
	var column_at := Vector2(maxf(left, MARGIN), top)
	_glide(_column, column_at, animate)
	_glide(_shop_panel, Vector2(column_at.x + size.x + SHOP_GAP, top), animate)
	_shop_panel.size = shop_size


## Moves `node` to `to`: eases there over UiMotion.BASE when `animate` (and
## motion is on and it shows), carries on toward a moved target if it is
## already easing, else jumps.
func _glide(node: Control, to: Vector2, animate: bool) -> void:
	var running: Tween = node.get_meta(&"glide") if node.has_meta(&"glide") else null
	var moving := running != null and running.is_valid() and running.is_running()
	if moving and node.get_meta(&"glide_to") == to:
		return
	_kill_glide(node)
	if not (moving or animate) or UiMotion.off() or not node.is_visible_in_tree() or node.position == to:
		node.position = to
		return
	var glide := UiMotion.tween(node)
	glide.tween_property(node, ^"position", to, UiMotion.BASE)
	node.set_meta(&"glide", glide)
	node.set_meta(&"glide_to", to)


func _kill_glide(node: Control) -> void:
	var running: Tween = node.get_meta(&"glide") if node.has_meta(&"glide") else null
	if running and running.is_valid():
		running.kill()
	node.remove_meta(&"glide")
	node.remove_meta(&"glide_to")


func _add_cell(parent: Control, index: int, style: ItemCell.Style) -> void:
	var cell := ItemCell.new(index, style, self)
	parent.add_child(cell)
	_cells.append(cell)

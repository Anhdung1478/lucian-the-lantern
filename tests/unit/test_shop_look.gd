extends GutTest
## The merchant's panel in the Lantern look: rows that name what is for
## sale, the Craft tab's states, and a panel that never changes size.

const Fixtures := preload("res://tests/unit/item_fixtures.gd")

var inventory: Inventory
var wallet: Wallet
var stock: MerchantStock
var screen: BackpackScreen
var panel: ShopPanel


func before_each() -> void:
	var catalog := Fixtures.catalog()
	for item in catalog.items:
		item.cost = 1000 if not item.is_potion() else 50
	catalog.find(&"gunblade").cost = 2600
	inventory = Inventory.new(catalog)
	inventory.add(catalog.find(&"sword"))
	inventory.add(catalog.find(&"rod"))
	inventory.add(catalog.find(&"belt"))
	inventory.add(catalog.find(&"edge"))
	wallet = Wallet.new()
	wallet.add(5000)
	stock = MerchantStock.new(catalog, 3)
	screen = BackpackScreen.new()
	add_child_autofree(screen)
	screen.setup(inventory)
	screen.open_shop(Shop.new(stock, inventory, wallet))
	panel = screen.shop_panel()
	await wait_physics_frames(3)


func slot(tab: int, index: int) -> ShopSlot:
	return panel.slots(tab)[index]


func cell(index: int) -> ItemCell:
	return screen._cells[index]


func center(control: Control) -> Vector2:
	return control.get_global_rect().get_center()


func mouse(target: Control, event: InputEventMouse, at: Vector2) -> void:
	event.global_position = at
	if target is ShopSlot:
		screen.on_shop_slot_input(target, event)
	elif target is CraftSlot:
		target._gui_input(event)
	else:
		screen.on_cell_input(target, event)


func button(target: Control, pressed: bool, at: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	mouse(target, event, at)


## Picks `from` up and holds it over `to`.
func hold(from: Control, to: Control) -> void:
	button(from, true, center(from))
	mouse(from, InputEventMouseMotion.new(), center(to))
	screen._process(0.0)


func drag(from: Control, to: Control) -> void:
	hold(from, to)
	button(from, false, center(to))


func craft_tab() -> void:
	panel.show_tab(ShopPanel.CRAFT_TAB)
	await wait_physics_frames(3)


func test_the_merchant_sits_on_an_ornate_plate_headed_merchant() -> void:
	assert_is(panel, Plate)
	assert_true(panel.ornate)
	var headings := panel.find_children("*", "HBoxContainer", true, false).filter(
		func(node: Node) -> bool: return node is BagHeading)
	assert_eq(headings.size(), 1)
	assert_eq(headings[0].label.text, "MERCHANT")


func test_a_row_names_its_item_and_its_stats() -> void:
	var catalog := inventory.catalog
	assert_eq(ShopSlot.line_text(catalog.find(&"sword")), "+35 Attack Damage", "a lone stat is named")
	assert_eq(ShopSlot.line_text(catalog.find(&"gunblade")), "+40 +80", "several: their amounts, each with its icon")
	assert_eq(ShopSlot.line_text(catalog.find(&"red")), "Restores 200 HP over 5 s")
	assert_eq(ShopSlot.line_text(catalog.find(&"blue")), "Restores 150 mana over 5 s")
	assert_eq(ShopSlot.line_text(Fixtures.fragment(&"plain", {})), "Fragment", "no stats: its kind")
	var parts := ShopSlot.line_parts(catalog.find(&"gunblade"))
	assert_eq(parts[0].icon, StatStyle.icon(&"ad"))
	assert_eq(parts[0].color, StatStyle.color(&"ad"))
	assert_eq(parts[1].icon, StatStyle.icon(&"ap"))
	assert_eq(slot(0, 0).title(), stock.item_at(0).display_name)


func test_sold_and_locked_rows_say_so() -> void:
	assert_eq(slot(0, 3).title(), "Locked", "two slots open, the last two chained")
	assert_eq(screen.shop.buy_slot(0), Shop.Result.OK)
	assert_eq(slot(0, 0).title(), "SOLD")
	assert_null(slot(0, 0).item())


func test_a_potion_row_carries_the_key_that_drinks_it() -> void:
	assert_eq(slot(ShopPanel.POTIONS_TAB, 0).key_text(), "7")
	assert_eq(slot(ShopPanel.POTIONS_TAB, 1).key_text(), "8")
	assert_eq(slot(ShopPanel.ITEMS_TAB, 0).key_text(), "", "an item has no key")


func test_the_panel_keeps_its_size_on_every_tab_and_with_any_message() -> void:
	var size := panel.get_combined_minimum_size()
	for tab: int in [ShopPanel.POTIONS_TAB, ShopPanel.CRAFT_TAB, ShopPanel.ITEMS_TAB]:
		panel.show_tab(tab)
		await wait_physics_frames(3)
		assert_eq(panel.get_combined_minimum_size(), size, "tab %d" % tab)
		assert_eq(panel.size, size, "no taller or wider than it needs")
	panel.show_message("Only fragments and boots are crafted, and this message is far too long for one line")
	await wait_physics_frames(3)
	assert_eq(panel.get_combined_minimum_size(), size, "a long message is cut off")


## The old panel grew wider for "Sells for N gold", which moved the backpack
## and took the sell slot from under the mouse.
func test_an_item_held_over_the_sell_slot_moves_nothing() -> void:
	var sell: ItemCell = screen._cells.back()
	var at := screen._column.position
	hold(cell(0), sell)
	assert_eq(screen.sell_preview(), 700)
	panel._process(0.0)
	assert_eq(panel._message.text, "Sells for 700 gold")
	await wait_physics_frames(3)
	screen._process(0.0)
	assert_eq(screen._column.position, at, "the backpack stays put")
	assert_eq(screen.sell_preview(), 700, "the sell slot is still under the mouse")
	button(cell(0), false, Vector2(5, 5))


func test_the_backpack_and_the_shop_stay_clear_of_the_recipes_on_a_narrower_screen() -> void:
	# Its own viewport, so the test window keeps its size.
	var view := SubViewport.new()
	view.size = Vector2i(1728, 1080)
	add_child_autofree(view)
	var own := BackpackScreen.new()
	view.add_child(own)
	own.setup(inventory)
	own.open_shop(Shop.new(stock, inventory, wallet))
	await wait_process_frames(3)
	var table := own._recipes.get_global_rect()
	var right := own.shop_panel().get_global_rect().end.x
	assert_gte(own._column.position.x, table.end.x, "16:10: right of the recipe table")
	assert_lte(right, 1728.0, "and on the screen")
	view.size = Vector2i(1440, 1080)
	right = own._column.position.x + own._column.get_combined_minimum_size().x + BackpackScreen.SHOP_GAP + own.shop_panel().get_combined_minimum_size().x
	assert_lte(right, 1440.0, "4:3, too narrow for all three: the shop stays on the screen, over the table")
	assert_gte(own._column.position.x, BackpackScreen.MARGIN)


func test_the_craft_tab_goes_from_empty_to_ready() -> void:
	await craft_tab()
	panel._process(0.0)
	assert_eq(panel.craft_state(), ShopPanel.CraftState.EMPTY)
	assert_true(panel.craft_button().disabled)
	assert_eq(panel.craft_button().text, "Craft")
	drag(cell(0), panel.first_input())
	panel._process(0.0)
	assert_eq(panel.craft_state(), ShopPanel.CraftState.ONE)
	assert_true(panel.craft_button().disabled)
	assert_eq(panel.second_input().rim(), UiStyle.BORDER_COLOR, "the input still to fill stands out")
	assert_eq(panel.first_input().rim(), UiStyle.RIM_FRAGMENT)
	assert_false(panel.result_slot().is_lit())
	drag(cell(1), panel.second_input())
	panel._process(0.0)
	assert_eq(panel.craft_state(), ShopPanel.CraftState.READY)
	assert_false(panel.craft_button().disabled)
	assert_eq(panel.craft_button().text, "Craft")
	assert_true(panel.result_slot().is_lit(), "the result lights up")
	assert_eq(panel.result_slot().rim(), UiStyle.RIM_LEGENDARY)
	assert_eq(panel._arrow.get_theme_color(&"font_color"), UiStyle.GOLD_COLOR)
	assert_eq(panel._fee_label.get_theme_color(&"font_color"), UiStyle.GOLD_COLOR)


func test_a_craft_the_wallet_cannot_pay_for_says_so_on_the_button() -> void:
	await craft_tab()
	drag(cell(0), panel.first_input())
	drag(cell(1), panel.second_input())
	wallet.spend(wallet.gold - 100)
	panel._process(0.0)
	assert_eq(panel.craft_state(), ShopPanel.CraftState.NO_GOLD)
	assert_eq(panel.craft_button().text, "Not enough gold")
	assert_false(panel.craft_button().disabled, "it still answers a press, with the red message")
	assert_eq(panel._fee_label.get_theme_color(&"font_color"), UiStyle.ERROR_COLOR)
	assert_false(panel.result_slot().is_lit())
	wallet.add(5000)
	panel._process(0.0)
	assert_eq(panel.craft_state(), ShopPanel.CraftState.READY)
	assert_eq(panel.craft_button().text, "Craft")


func test_two_inputs_that_make_nothing_say_no_recipe() -> void:
	await craft_tab()
	drag(cell(0), panel.first_input())
	drag(cell(2), panel.second_input())
	panel._process(0.0)
	assert_eq(panel.craft_state(), ShopPanel.CraftState.NO_RECIPE, "a sword and a belt")
	assert_eq(panel.craft_button().text, "No recipe")
	assert_true(panel.craft_button().disabled)
	assert_eq(panel.result_slot().rim(), UiStyle.BAD_COLOR)
	assert_eq(panel._craft_note.get_theme_color(&"font_color"), UiStyle.ERROR_COLOR)


func test_fully_upgraded_boots_alone_make_nothing() -> void:
	inventory.set_boots(Fixtures.boots(&"swift", 3))
	await craft_tab()
	drag(cell(Inventory.BOOTS_CELL), panel.first_input())
	assert_eq(panel.craft_state(), ShopPanel.CraftState.NO_RECIPE)
	assert_eq(panel.craft_note(), "swift are fully upgraded.")


func test_a_craft_input_lights_only_under_an_item_it_takes() -> void:
	await craft_tab()
	hold(cell(0), panel.first_input())
	assert_eq(screen.dragged_item().id, &"sword")
	assert_true(panel.first_input().is_lit(), "a fragment")
	assert_false(panel.second_input().is_lit(), "only the input under it")
	button(cell(0), false, Vector2(5, 5))
	assert_null(screen.dragged_item())
	hold(cell(3), panel.first_input())
	assert_false(panel.first_input().is_lit(), "a legendary is never crafted")
	button(cell(3), false, Vector2(5, 5))


func test_a_dragged_shop_item_lights_a_cell_it_can_be_bought_into() -> void:
	inventory.unlocked_backpack = 30
	hold(slot(0, 0), cell(20))
	assert_true(screen.takes_drop(20), "a free cell")
	assert_true(cell(20).is_lit())
	assert_true(screen.takes_drop(Inventory.EQUIP_START), "a free equip slot")
	assert_false(screen.takes_drop(0), "a taken cell: the item would go elsewhere")
	assert_false(screen.takes_drop(40), "a locked cell")
	assert_false(screen.takes_drop(Inventory.HP_POTION_CELL))
	button(slot(0, 0), false, Vector2(5, 5))


func test_the_merchant_is_as_tall_as_the_backpack_column_and_lines_up_with_it() -> void:
	var column := screen._column.get_global_rect()
	var plate := panel.get_global_rect()
	assert_eq(plate.position.y, column.position.y, "tops on one line")
	assert_eq(plate.end.y, column.end.y, "bottoms on one line")
	assert_eq(plate.position.x, column.end.x + BackpackScreen.SHOP_GAP)


func test_the_sell_slot_sits_in_the_foot_left_with_the_message_beside_it() -> void:
	var sell: ItemCell = screen._cells.back()
	var foot := sell.get_parent()
	assert_eq(foot.get_child(0), sell, "first in the foot")
	assert_true(foot.is_ancestor_of(panel._message), "the message shares its line")
	assert_true(foot.is_ancestor_of(panel.undo_button()))
	assert_gt(panel.undo_button().global_position.x, panel._message.global_position.x, "the buttons on the right")


func test_undo_sale_never_moves_between_tabs() -> void:
	var at := panel.undo_button().global_position
	for tab: int in [ShopPanel.POTIONS_TAB, ShopPanel.CRAFT_TAB, ShopPanel.ITEMS_TAB]:
		panel.show_tab(tab)
		await wait_physics_frames(2)
		assert_eq(panel.undo_button().global_position, at, "tab %d" % tab)
	assert_eq(panel.refresh_text(), "Refresh 100")


func test_the_open_tab_page_is_the_only_one_shown() -> void:
	for tab: int in [ShopPanel.CRAFT_TAB, ShopPanel.POTIONS_TAB]:
		panel.show_tab(tab)
		for other in 3:
			assert_eq(panel.page(other).visible, other == tab)
	assert_eq(panel._tab_highlight.target, panel._tab_buttons[ShopPanel.POTIONS_TAB], "the fill follows the tab")


func test_the_gold_counts_to_the_wallet() -> void:
	panel._process(0.0)
	assert_eq(panel._gold_label.final_text(), "5000")
	wallet.spend(1200)
	panel._process(0.0)
	assert_eq(panel._gold_label.final_text(), "3800")


func test_a_potion_row_says_what_lucian_carries() -> void:
	var potion := slot(ShopPanel.POTIONS_TAB, 0)
	var cell_index := Inventory.potion_cell(potion.potion)
	assert_eq(potion.carrying_text(), Lang.t("Carrying %d / %d") % [inventory.count_at(cell_index), potion.potion.max_stack])
	assert_eq(slot(ShopPanel.ITEMS_TAB, 0).carrying_text(), "", "only potions")


func test_no_tab_leaves_an_empty_band_over_80_px() -> void:
	# 80 px on screen is 96 units; a short page's block is centred above its hint.
	for tab in 3:
		panel.show_tab(tab)
		await wait_physics_frames(2)
		var block: Control = panel._rows[tab]
		var hint: Control = panel._hints[tab]
		var page: Control = panel.page(tab)
		var above := block.get_global_rect().position.y - page.get_global_rect().position.y
		var between := hint.get_global_rect().position.y - block.get_global_rect().end.y
		assert_lt(above, 96.0, "tab %d: the room over its content" % tab)
		assert_lt(between, 96.0, "tab %d: the room between content and hint" % tab)


func test_the_tabs_share_one_track() -> void:
	assert_eq(panel._tab_highlight.track_tabs.size(), 3)
	assert_gt(panel._tab_highlight.track_rect().size.x, 0.0)

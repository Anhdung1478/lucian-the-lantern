extends GutTest

const Fixtures := preload("res://tests/unit/item_fixtures.gd")

var inventory: Inventory
var wallet: Wallet
var stock: MerchantStock
var screen: BackpackScreen


func before_each() -> void:
	var catalog := Fixtures.catalog()
	for item in catalog.items:
		item.cost = 1000 if not item.is_potion() else 50
	inventory = Inventory.new(catalog)
	inventory.add(catalog.find(&"sword"))
	wallet = Wallet.new()
	wallet.add(5000)
	stock = MerchantStock.new(catalog, 3)
	screen = BackpackScreen.new()
	add_child_autofree(screen)
	screen.setup(inventory)
	screen.open_shop(Shop.new(stock, inventory, wallet))
	await wait_physics_frames(3)


func slot(tab: int, index: int) -> ShopSlot:
	return screen.shop_panel().slots(tab)[index]


func center(control: Control) -> Vector2:
	return control.get_global_rect().get_center()


func cell(index: int) -> ItemCell:
	return screen._cells[index]


func sell_cell() -> ItemCell:
	return screen._cells[screen._cells.size() - 1]


func mouse(target: Control, event: InputEventMouse, at: Vector2) -> void:
	event.global_position = at
	if target is ShopSlot:
		screen.on_shop_slot_input(target, event)
	elif target is CraftSlot:
		target._gui_input(event)
	else:
		screen.on_cell_input(target, event)


func button(target: Control, index: MouseButton, pressed: bool, at: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = index
	event.pressed = pressed
	mouse(target, event, at)


## Press on `from`, move over `to`, release there. Every event goes to the
## pressed control, as in Godot.
func drag(from: Control, to: Control) -> void:
	button(from, MOUSE_BUTTON_LEFT, true, center(from))
	mouse(from, InputEventMouseMotion.new(), center(to))
	screen._process(0.0)
	button(from, MOUSE_BUTTON_LEFT, false, center(to))


func test_shop_mode_keeps_the_recipe_table() -> void:
	assert_true(screen.is_shopping())
	assert_true(screen._recipes.visible, "crafting is at the merchant, so the recipes show there")
	var table := screen._recipes.get_global_rect()
	var pack := screen._column.get_global_rect()
	assert_true(table.end.x <= pack.position.x, "the table sits clear of the backpack: %s / %s" % [table, pack])


func test_right_click_buys_into_the_first_empty_cell() -> void:
	var item := stock.item_at(0)
	button(slot(0, 0), MOUSE_BUTTON_RIGHT, true, center(slot(0, 0)))
	assert_eq(inventory.item_at(1), item)
	assert_eq(wallet.gold, 4000)


func test_right_clicking_a_locked_slot_says_it_is_locked() -> void:
	assert_true(slot(0, 3).is_locked(), "two slots open, the last two chained")
	watch_signals(screen)
	button(slot(0, 3), MOUSE_BUTTON_RIGHT, true, center(slot(0, 3)))
	assert_eq(screen.shop_panel()._message.text, "That slot is locked", "not \"Already sold\"")
	assert_signal_emitted_with_parameters(screen, "traded", [false])
	assert_eq(wallet.gold, 5000)


func test_a_locked_slot_names_the_tree_node_that_opens_it() -> void:
	var node: TreeNodeData = load("res://data/tree/merchant_stock.tres")
	var card := slot(0, 3).tooltip_content()
	assert_not_null(card, "a chained slot explains itself")
	var text := (card.find_children("*", "Label", true, false)[0] as Label).text
	assert_string_contains(text, node.display_name)
	assert_string_contains(text, "Evolution Tree")
	card.free()
	card = slot(0, 0).tooltip_content()
	for label: Label in card.find_children("*", "Label", true, false):
		assert_ne(label.text, text, "an open slot shows its item")
	card.free()


func test_dragging_a_shop_item_onto_a_cell_buys_it_there() -> void:
	var item := stock.item_at(1)
	drag(slot(0, 1), cell(20))
	assert_eq(inventory.item_at(20), item)
	assert_true(stock.is_sold(1))


func test_dragging_onto_an_occupied_cell_buys_into_a_free_cell() -> void:
	var item := stock.item_at(1)
	drag(slot(0, 1), cell(0))
	assert_eq(inventory.item_at(0).id, &"sword", "the taken cell is untouched")
	assert_eq(inventory.item_at(1), item)
	assert_eq(wallet.gold, 4000)
	assert_true(stock.is_sold(1))


func test_dragging_onto_an_occupied_cell_with_no_free_cell_buys_nothing() -> void:
	inventory.unlocked_backpack = 1
	drag(slot(0, 1), cell(0))
	assert_eq(wallet.gold, 5000)
	assert_false(stock.is_sold(1))
	assert_true(screen.craft_confirm().is_open())
	assert_eq(screen.craft_confirm()._message.text, "Your backpack is full.")
	assert_null(inventory.item_at(Inventory.EQUIP_START), "never spilled into an empty equip slot")


func test_a_right_click_with_the_backpack_full_says_so_in_a_pop_up() -> void:
	inventory.unlocked_backpack = 1
	watch_signals(screen)
	button(slot(0, 0), MOUSE_BUTTON_RIGHT, true, center(slot(0, 0)))
	var popup := screen.craft_confirm()
	assert_true(popup.is_open())
	assert_eq(popup._message.text, BackpackScreen.BACKPACK_FULL)
	assert_eq(_choices(popup), "OK", "a notice: OK alone")
	assert_eq(screen.shop_panel()._message.text, "", "the pop-up says it, not the red line")
	assert_signal_emitted_with_parameters(screen, "traded", [false])
	assert_eq(wallet.gold, 5000)
	assert_false(stock.is_sold(0))
	popup.answer(true)
	assert_false(popup.is_open())


func test_a_shop_item_dragged_onto_a_free_equip_slot_is_bought_with_the_backpack_full() -> void:
	inventory.unlocked_backpack = 1
	var item := stock.item_at(1)
	drag(slot(0, 1), cell(Inventory.EQUIP_START + 2))
	assert_eq(inventory.item_at(Inventory.EQUIP_START + 2), item)
	assert_eq(wallet.gold, 4000)
	assert_false(screen.craft_confirm().is_open())


## A penetration legendary for 1000 gold.
func _pen(id: StringName, key := &"armor_pen") -> ItemData:
	var made := Fixtures.legendary(id, &"sword", &"belt", {key: 0.3})
	made.display_name = {&"ldr": "Lord Dominik's Regards", &"void": "Void Staff"}.get(id, String(id))
	made.cost = 1000
	return made


func test_a_second_penetration_item_dragged_onto_an_equip_slot_is_refused_with_a_pop_up() -> void:
	inventory.put(Inventory.EQUIP_START, _pen(&"void", &"magic_pen"))
	stock.items[1] = _pen(&"ldr")
	drag(slot(0, 1), cell(Inventory.EQUIP_START + 1))
	var popup := screen.craft_confirm()
	assert_true(popup.is_open())
	assert_eq(popup._message.text, "Only one penetration item can be equipped,\nand Void Staff already is.")
	assert_eq(wallet.gold, 5000)
	assert_false(stock.is_sold(1))
	assert_null(inventory.item_at(Inventory.EQUIP_START + 1))


## The pop-up's buttons on screen, in order: "Yes / No".
func _choices(popup: ConfirmPopup) -> String:
	var labels := PackedStringArray()
	for each: Button in popup.find_children("*", "Button", true, false):
		if each.visible:
			labels.append(each.text)
	return " / ".join(labels)


func _key(code: Key) -> InputEventKey:
	var key := InputEventKey.new()
	key.keycode = code
	key.physical_keycode = code
	key.pressed = true
	return key


func test_a_notice_closes_on_ok_enter_or_esc() -> void:
	var popup := screen.craft_confirm()
	var calls: Array[String] = []
	popup.tell("Your backpack is full.", func() -> void: calls.append("ok"))
	assert_eq(_choices(popup), "OK")
	popup.answer(false)
	popup.cancel()
	assert_true(popup.is_open(), "no No or Cancel to answer")
	popup._input(_key(KEY_ENTER))
	assert_false(popup.is_open())
	popup.tell("Your backpack is full.")
	popup._input(_key(KEY_ESCAPE))
	assert_false(popup.is_open(), "ESC is OK")
	assert_eq(calls, ["ok"] as Array[String])


func test_closing_the_shop_drops_an_open_notice() -> void:
	inventory.unlocked_backpack = 1
	button(slot(0, 0), MOUSE_BUTTON_RIGHT, true, center(slot(0, 0)))
	assert_true(screen.craft_confirm().is_open())
	screen.close()
	assert_false(screen.craft_confirm().is_open())


func test_dropping_a_shop_item_outside_buys_nothing() -> void:
	button(slot(0, 0), MOUSE_BUTTON_LEFT, true, center(slot(0, 0)))
	mouse(slot(0, 0), InputEventMouseMotion.new(), Vector2(5, 5))
	screen._process(0.0)
	button(slot(0, 0), MOUSE_BUTTON_LEFT, false, Vector2(5, 5))
	assert_eq(wallet.gold, 5000)


func test_potions_tab_buys_potions() -> void:
	screen.shop_panel().show_tab(1)
	await wait_physics_frames(2)
	button(slot(1, 0), MOUSE_BUTTON_RIGHT, true, center(slot(1, 0)))
	button(slot(1, 0), MOUSE_BUTTON_RIGHT, true, center(slot(1, 0)))
	assert_eq(inventory.item_at(Inventory.HP_POTION_CELL).id, &"red", "into its potion cell first")
	assert_eq(inventory.count_at(Inventory.HP_POTION_CELL), 2)
	assert_null(inventory.item_at(1))


## The Potions tab's hint names the potion keys as bound, in full, and follows
## a rebind made while the shop is open.
func test_the_potions_hint_names_the_potion_keys_as_bound() -> void:
	var shared := GameSettings._instance
	GameSettings._instance = GameSettings.new("user://test_shop_drag_settings.json")
	var own := BackpackScreen.new()
	add_child_autofree(own)
	own.setup(inventory)
	own.open_shop(Shop.new(stock, inventory, wallet))
	var panel := own.shop_panel()
	panel.show_tab(ShopPanel.POTIONS_TAB)
	var first := panel._hint.text
	var mouse_four := InputEventMouseButton.new()
	mouse_four.button_index = MOUSE_BUTTON_XBUTTON1
	GameSettings._instance.rebind(&"potion_mp", mouse_four)
	var rebound := panel._hint.text
	panel.show_tab(ShopPanel.ITEMS_TAB)
	var items_hint := panel._hint.text
	panel.show_tab(ShopPanel.POTIONS_TAB)
	var shown_again := panel._hint.text
	GameSettings._instance = shared
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_shop_drag_settings.json"))
	assert_string_contains(first, "the 7 and 8 cells first")
	assert_string_contains(rebound, "the 7 and Mouse 4 cells first", "a rebind shows at once")
	assert_eq(items_hint, ShopPanel.HINTS[ShopPanel.ITEMS_TAB])
	assert_eq(shown_again, rebound)


func test_a_potion_dragged_onto_an_equip_slot_buys_nothing() -> void:
	screen.shop_panel().show_tab(1)
	await wait_physics_frames(2)
	drag(slot(1, 0), cell(Inventory.EQUIP_START))
	assert_null(inventory.item_at(Inventory.EQUIP_START))
	assert_eq(wallet.gold, 5000)
	assert_eq(screen.shop_panel()._message.text, "That item can't go there")


func test_cells_stay_in_inventory_order_with_the_sell_slot_last() -> void:
	assert_eq(screen._cells.size(), Inventory.SIZE + 1)
	for i in Inventory.SIZE:
		assert_eq(cell(i).index, i)
	assert_eq(sell_cell().index, -1)
	assert_eq(sell_cell().style, ItemCell.Style.SELL)
	assert_eq(cell(Inventory.BOOTS_CELL).style, ItemCell.Style.BOOTS)
	assert_eq(cell(Inventory.HP_POTION_CELL).style, ItemCell.Style.POTION)
	var row := cell(Inventory.BOOTS_CELL).get_parent()
	assert_eq(row.get_child(0), cell(Inventory.BOOTS_CELL), "the boots come first in their row")


func _wear(id: StringName, tier: int) -> ItemData:
	var worn := Fixtures.boots(id, tier)
	inventory.set_boots(worn)
	return worn


func test_boots_on_the_sell_slot_are_refused() -> void:
	var worn := _wear(&"speed", 1)
	button(cell(Inventory.BOOTS_CELL), MOUSE_BUTTON_LEFT, true, center(cell(Inventory.BOOTS_CELL)))
	mouse(cell(Inventory.BOOTS_CELL), InputEventMouseMotion.new(), center(sell_cell()))
	screen._process(0.0)
	assert_true(screen.sell_refused())
	assert_eq(screen.sell_preview(), 0)
	button(cell(Inventory.BOOTS_CELL), MOUSE_BUTTON_LEFT, false, center(sell_cell()))
	assert_eq(inventory.boots(), worn)
	assert_eq(wallet.gold, 5000)
	assert_eq(screen.shop_panel()._message.text, "Boots can't be sold")


func test_boots_dragged_onto_a_cell_go_back() -> void:
	var worn := _wear(&"speed", 1)
	drag(cell(Inventory.BOOTS_CELL), cell(5))
	assert_eq(inventory.boots(), worn)
	assert_null(inventory.item_at(5))


func test_the_craft_tab_upgrades_the_boots_dragged_in() -> void:
	var catalog := inventory.catalog
	catalog.items.append(Fixtures.boots(&"speed", 1))
	var greaves := Fixtures.boots(&"sword_greaves", 2, &"sword", &"", 300)
	catalog.items.append(greaves)
	inventory.set_boots(catalog.find(&"speed"))
	var panel := screen.shop_panel()
	panel.show_tab(ShopPanel.CRAFT_TAB)
	await wait_physics_frames(3)
	assert_eq(panel.slots(ShopPanel.CRAFT_TAB).size(), 0, "no shop slots on the Craft tab")
	assert_false(panel._refresh.visible)
	drag(cell(Inventory.BOOTS_CELL), panel.first_input())
	panel._process(0.0)
	assert_eq(panel._craft_note.text, "Now drag in a fragment.")
	drag(cell(0), panel.second_input())
	assert_eq([panel.first_input().index, panel.second_input().index], [Inventory.BOOTS_CELL, 0])
	assert_eq(panel.craft_preview(), greaves)
	assert_eq(panel.result_slot().item(), greaves)
	panel._process(0.0)
	assert_eq(panel._fee_label.text, "300")
	assert_eq(panel._craft_note.text, "speed + sword → sword_greaves")
	assert_false(panel.craft_button().disabled)
	panel.craft_button().pressed.emit()
	assert_true(screen.craft_confirm().is_open(), "Craft asks first")
	screen.craft_confirm().answer(true)
	assert_eq(inventory.boots(), greaves)
	assert_null(inventory.item_at(0), "the fragment is used up")
	assert_eq(wallet.gold, 4700)
	assert_eq([panel.first_input().index, panel.second_input().index], [-1, -1], "a craft empties both inputs")
	assert_false(screen.in_craft(Inventory.BOOTS_CELL))
	assert_eq(cell(Inventory.BOOTS_CELL).item(), greaves, "the upgraded boots show in their cell at once")
	drag(cell(Inventory.BOOTS_CELL), panel.first_input())
	screen.close()
	assert_eq(panel.first_input().index, -1, "closing empties the inputs")
	assert_eq(cell(Inventory.BOOTS_CELL).item(), greaves, "the boots are back in their cell")


func test_the_craft_tab_makes_a_legendary_for_its_fee() -> void:
	var catalog := inventory.catalog
	var gunblade := catalog.find(&"gunblade")
	gunblade.cost = 2600
	inventory.add(catalog.find(&"rod"))
	var panel := screen.shop_panel()
	panel.show_tab(ShopPanel.CRAFT_TAB)
	await wait_physics_frames(3)
	drag(cell(0), panel.first_input())
	drag(cell(1), panel.second_input())
	panel._process(0.0)
	assert_eq(panel.craft_preview(), gunblade)
	assert_eq(panel._fee_label.text, "600", "2600 minus two 1000-gold fragments")
	panel.craft_button().pressed.emit()
	assert_eq(screen.craft_confirm()._message.text, "Craft gunblade from sword and rod for 600 gold?")
	screen.craft_confirm().answer(true)
	assert_eq(inventory.item_at(0), gunblade, "the legendary goes where the first input was")
	assert_eq(cell(0).item(), gunblade, "and shows there")
	assert_null(inventory.item_at(1))
	assert_eq(wallet.gold, 4400)
	assert_eq([panel.first_input().index, panel.second_input().index], [-1, -1])


func test_the_craft_tab_refuses_a_legendary_and_says_when_nothing_is_made() -> void:
	var catalog := inventory.catalog
	inventory.add(catalog.find(&"belt"))
	inventory.add(catalog.find(&"edge"))
	var panel := screen.shop_panel()
	panel.show_tab(ShopPanel.CRAFT_TAB)
	await wait_physics_frames(3)
	panel._process(0.0)
	assert_eq(panel._craft_note.text, "Drag in two fragments, or your boots and a fragment.")
	assert_true(panel.craft_button().disabled)
	drag(cell(2), panel.first_input())
	assert_eq(panel.first_input().index, -1, "a legendary is never crafted")
	assert_eq(panel._message.text, "Only fragments and boots are crafted")
	drag(cell(0), panel.first_input())
	drag(cell(1), panel.second_input())
	panel._process(0.0)
	assert_null(panel.craft_preview())
	assert_eq(panel._craft_note.text, "No legendary is made from sword and belt.")
	assert_true(panel.craft_button().disabled)
	assert_eq(panel._fee_label.text, "–")


## The Craft tab, laid out.
func craft_tab() -> ShopPanel:
	var panel := screen.shop_panel()
	panel.show_tab(ShopPanel.CRAFT_TAB)
	await wait_physics_frames(3)
	return panel


func id_at(index: int) -> StringName:
	var item := inventory.item_at(index)
	return item.id if item else &""


## The text of the first Label under `node`.
func _label_text(node: Node) -> String:
	if node is Label:
		return node.text
	for child in node.get_children():
		var text := _label_text(child)
		if text != "":
			return text
	return ""


func test_an_item_in_a_craft_input_leaves_the_backpack_view() -> void:
	var panel: ShopPanel = await craft_tab()
	drag(cell(0), panel.first_input())
	assert_eq(panel.first_input().index, 0)
	assert_true(screen.in_craft(0))
	assert_null(cell(0).item(), "the cell draws empty")
	assert_eq(id_at(0), &"sword", "the inventory keeps it in its cell, so a save loses nothing")
	assert_eq(panel.first_input().item().id, &"sword")
	var card: Control = cell(0).tooltip_content()
	assert_eq(_label_text(card), "In the Craft tab: drag it back here, or right-click its input")
	card.free()
	button(cell(0), MOUSE_BUTTON_LEFT, true, center(cell(0)))
	screen._process(0.3)
	assert_false(screen.is_dragging(), "a held cell can't be picked up, so it can't be sold either")
	button(cell(0), MOUSE_BUTTON_LEFT, false, center(sell_cell()))
	assert_eq(id_at(0), &"sword")
	assert_eq(wallet.gold, 5000)


func test_one_cell_cannot_fill_both_inputs() -> void:
	var panel: ShopPanel = await craft_tab()
	drag(cell(0), panel.first_input())
	drag(cell(0), panel.second_input())
	assert_eq([panel.first_input().index, panel.second_input().index], [0, -1], "the held cell isn't dragged again")
	panel._process(0.0)
	assert_eq(panel._craft_note.text, "Now drag in a fragment.")
	assert_true(panel.craft_button().disabled)
	assert_true(panel.load_input(BackpackScreen.CRAFT_SECOND, 0))
	assert_eq([panel.first_input().index, panel.second_input().index], [-1, 0], "loading it again moves it")
	inventory.add(inventory.catalog.find(&"sword"))
	drag(cell(1), panel.first_input())
	panel._process(0.0)
	assert_eq(panel.craft_preview().id, &"edge", "two swords from two cells make their legendary")


func test_a_held_cell_refuses_drops_and_purchases() -> void:
	inventory.add(inventory.catalog.find(&"rod"))
	var panel: ShopPanel = await craft_tab()
	drag(cell(0), panel.first_input())
	drag(cell(1), cell(0))
	assert_eq([id_at(0), id_at(1)], [&"sword", &"rod"], "nothing is dropped on the held cell")
	assert_eq(panel.first_input().index, 0)
	var bought := stock.item_at(1)
	assert_eq(screen.shop.buy_slot(1, 0), Shop.Result.OK)
	assert_eq(id_at(0), &"sword", "the held cell counts as taken")
	assert_eq(inventory.item_at(2), bought, "the purchase goes to the first free cell")


func test_changing_tab_gives_the_items_back() -> void:
	var panel: ShopPanel = await craft_tab()
	drag(cell(0), panel.first_input())
	panel._tab_buttons[ShopPanel.CRAFT_TAB].pressed.emit()
	assert_eq(panel.first_input().index, 0, "the tab already showing changes nothing")
	panel._tab_buttons[ShopPanel.ITEMS_TAB].pressed.emit()
	assert_eq(panel.first_input().index, -1)
	assert_false(screen.in_craft(0))
	assert_eq(cell(0).item().id, &"sword")


func test_closing_gives_the_items_back() -> void:
	var panel: ShopPanel = await craft_tab()
	drag(cell(0), panel.first_input())
	screen.close()
	screen.open_shop(Shop.new(stock, inventory, wallet))
	assert_eq(panel.first_input().index, -1)
	assert_eq(cell(0).item().id, &"sword")


func test_dragging_an_input_back_onto_its_cell_gives_it_back() -> void:
	var panel: ShopPanel = await craft_tab()
	drag(cell(0), panel.first_input())
	drag(panel.first_input(), cell(0))
	assert_eq(panel.first_input().index, -1)
	assert_eq(cell(0).item().id, &"sword")


func test_dragging_an_input_onto_a_free_cell_moves_it_there() -> void:
	var panel: ShopPanel = await craft_tab()
	drag(cell(0), panel.first_input())
	drag(panel.first_input(), cell(7))
	assert_eq(panel.first_input().index, -1)
	assert_eq([id_at(0), id_at(7)], [&"", &"sword"])
	assert_eq(cell(7).item().id, &"sword")


func test_dragging_an_input_anywhere_else_gives_it_back() -> void:
	inventory.add(inventory.catalog.find(&"rod"))
	var panel: ShopPanel = await craft_tab()
	drag(cell(0), panel.first_input())
	drag(panel.first_input(), cell(1))
	assert_eq(panel.first_input().index, -1, "a taken cell: it comes back")
	assert_eq([id_at(0), id_at(1)], [&"sword", &"rod"])
	drag(cell(0), panel.first_input())
	drag(panel.first_input(), sell_cell())
	assert_eq(panel.first_input().index, -1)
	assert_eq(id_at(0), &"sword", "never sold from an input")
	assert_eq(wallet.gold, 5000)
	drag(cell(0), panel.first_input())
	var input := panel.first_input()
	button(input, MOUSE_BUTTON_LEFT, true, center(input))
	mouse(input, InputEventMouseMotion.new(), Vector2(5, 5))
	screen._process(0.0)
	button(input, MOUSE_BUTTON_LEFT, false, Vector2(5, 5))
	assert_eq(input.index, -1, "dropped outside: it comes back")
	assert_eq(cell(0).item().id, &"sword")


func test_dragging_from_one_input_to_the_other_moves_it() -> void:
	inventory.add(inventory.catalog.find(&"rod"))
	var panel: ShopPanel = await craft_tab()
	drag(cell(0), panel.first_input())
	drag(panel.first_input(), panel.second_input())
	assert_eq([panel.first_input().index, panel.second_input().index], [-1, 0])
	assert_true(screen.in_craft(0), "still held")
	drag(cell(1), panel.first_input())
	drag(panel.second_input(), panel.first_input())
	assert_eq([panel.first_input().index, panel.second_input().index], [0, 1], "onto a full input they trade places")
	var input := panel.first_input()
	button(input, MOUSE_BUTTON_LEFT, true, center(input))
	screen._process(0.3)
	assert_eq(screen.dragged_input(), input, "held still, it is picked up")
	screen._process(0.0)
	button(input, MOUSE_BUTTON_LEFT, false, center(input))
	assert_eq(input.index, 0, "dropped on its own input it stays")


func test_a_right_click_on_an_input_gives_its_item_back() -> void:
	var panel: ShopPanel = await craft_tab()
	drag(cell(0), panel.first_input())
	button(panel.first_input(), MOUSE_BUTTON_RIGHT, true, center(panel.first_input()))
	assert_eq(panel.first_input().index, -1)
	assert_eq(cell(0).item().id, &"sword")


func test_craft_asks_first_and_no_changes_nothing() -> void:
	inventory.catalog.find(&"gunblade").cost = 2600
	inventory.add(inventory.catalog.find(&"rod"))
	var panel: ShopPanel = await craft_tab()
	drag(cell(0), panel.first_input())
	drag(cell(1), panel.second_input())
	panel.craft_button().pressed.emit()
	var confirm := screen.craft_confirm()
	assert_true(confirm.is_open())
	assert_eq(id_at(0), &"sword", "nothing is crafted before Yes")
	confirm.answer(false)
	assert_false(confirm.is_open())
	assert_eq([id_at(0), id_at(1)], [&"sword", &"rod"])
	assert_eq(wallet.gold, 5000)
	assert_eq([panel.first_input().index, panel.second_input().index], [0, 1], "No keeps the inputs")
	panel.craft_button().pressed.emit()
	confirm.answer(true)
	assert_eq(id_at(0), &"gunblade")
	assert_eq(wallet.gold, 4400)


func test_a_crafted_penetration_item_goes_to_the_second_cell_when_the_first_is_closed_to_it() -> void:
	var gunblade := inventory.catalog.find(&"gunblade")
	gunblade.stats[&"armor_pen"] = 0.3
	gunblade.cost = 2600
	inventory.put(Inventory.EQUIP_START, _pen(&"void", &"magic_pen"))
	inventory.put(Inventory.EQUIP_START + 1, inventory.catalog.find(&"rod"))
	var panel: ShopPanel = await craft_tab()
	assert_true(panel.load_input(BackpackScreen.CRAFT_FIRST, Inventory.EQUIP_START + 1))
	assert_true(panel.load_input(BackpackScreen.CRAFT_SECOND, 0))
	panel.craft_button().pressed.emit()
	assert_string_starts_with(screen.craft_confirm()._message.text, "Craft gunblade", "it asks as usual")
	screen.craft_confirm().answer(true)
	assert_eq(id_at(0), &"gunblade", "the backpack cell, not the equip slot")
	assert_eq(id_at(Inventory.EQUIP_START + 1), &"")
	assert_eq(wallet.gold, 4400)


func test_a_craft_with_both_cells_closed_to_its_penetration_item_is_refused_with_a_pop_up() -> void:
	inventory.catalog.find(&"gunblade").stats[&"armor_pen"] = 0.3
	inventory.put(Inventory.EQUIP_START, _pen(&"void", &"magic_pen"))
	inventory.put(Inventory.EQUIP_START + 1, inventory.catalog.find(&"rod"))
	inventory.apply_drop(0, Inventory.EQUIP_START + 2)
	var panel: ShopPanel = await craft_tab()
	assert_true(panel.load_input(BackpackScreen.CRAFT_FIRST, Inventory.EQUIP_START + 1))
	assert_true(panel.load_input(BackpackScreen.CRAFT_SECOND, Inventory.EQUIP_START + 2))
	watch_signals(screen)
	panel.craft_button().pressed.emit()
	var popup := screen.craft_confirm()
	assert_eq(popup._message.text, "Only one penetration item can be equipped,\nand Void Staff already is.")
	assert_eq(_choices(popup), "OK", "refused at once, not asked")
	assert_signal_emitted_with_parameters(screen, "traded", [false])
	assert_eq([id_at(Inventory.EQUIP_START + 1), id_at(Inventory.EQUIP_START + 2)], [&"rod", &"sword"])
	assert_eq(wallet.gold, 5000)


func test_craft_without_the_gold_is_refused_without_asking() -> void:
	inventory.catalog.find(&"gunblade").cost = 2600
	inventory.add(inventory.catalog.find(&"rod"))
	wallet.reset()
	wallet.add(100)
	var panel: ShopPanel = await craft_tab()
	drag(cell(0), panel.first_input())
	drag(cell(1), panel.second_input())
	panel.craft_button().pressed.emit()
	assert_false(screen.craft_confirm().is_open())
	assert_eq(panel._message.text, "Not enough gold")
	assert_eq(id_at(0), &"sword")


func test_closing_drops_an_open_craft_question() -> void:
	inventory.add(inventory.catalog.find(&"rod"))
	var panel: ShopPanel = await craft_tab()
	drag(cell(0), panel.first_input())
	drag(cell(1), panel.second_input())
	panel.craft_button().pressed.emit()
	screen.close()
	assert_false(screen.craft_confirm().is_open())
	assert_eq([id_at(0), id_at(1)], [&"sword", &"rod"])
	assert_eq(wallet.gold, 5000)


func test_dropping_on_the_sell_slot_sells() -> void:
	drag(cell(0), sell_cell())
	assert_null(inventory.item_at(0))
	assert_eq(wallet.gold, 5700)


func test_undo_button_follows_the_sales() -> void:
	var panel := screen.shop_panel()
	panel._process(0.0)
	assert_true(panel.undo_button().disabled, "nothing sold yet")
	drag(cell(0), sell_cell())
	panel._process(0.0)
	assert_false(panel.undo_button().disabled)
	assert_eq(panel.undo_button().get_meta(&"hover_text"), "Buy back sword for 700 gold")
	panel.undo_button().pressed.emit()
	panel._process(0.0)
	assert_eq(inventory.item_at(0).id, &"sword")
	assert_eq(wallet.gold, 5000)
	assert_true(panel.undo_button().disabled)
	assert_false(panel.undo_button().has_meta(&"hover_text"))


func test_sell_preview_while_over_the_sell_slot() -> void:
	button(cell(0), MOUSE_BUTTON_LEFT, true, center(cell(0)))
	mouse(cell(0), InputEventMouseMotion.new(), center(sell_cell()))
	screen._process(0.0)
	assert_eq(screen.sell_preview(), 700)
	button(cell(0), MOUSE_BUTTON_LEFT, false, Vector2(5, 5))


func test_refused_purchase_shows_a_message() -> void:
	wallet.reset()
	button(slot(0, 0), MOUSE_BUTTON_RIGHT, true, center(slot(0, 0)))
	assert_eq(screen.shop_panel()._message.text, "Not enough gold")


func test_refresh_greys_out_once_every_open_slot_is_sold() -> void:
	var panel := screen.shop_panel()
	panel._process(0.0)
	assert_false(panel._refresh.disabled)
	for i in stock.unlocked:
		assert_eq(screen.shop.buy_slot(i), Shop.Result.OK)
	panel._process(0.0)
	assert_true(panel._refresh.disabled, "nothing left to re-roll")
	var gold := wallet.gold
	screen.refresh_shop()
	assert_eq(wallet.gold, gold, "a refused refresh costs nothing")
	assert_eq(panel._message.text, "Nothing left to refresh")


func test_closing_ends_shop_mode() -> void:
	screen.close()
	assert_false(screen.is_shopping())
	assert_true(screen._recipes.visible)

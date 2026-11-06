extends GutTest

const Fixtures := preload("res://tests/unit/item_fixtures.gd")
const Result := Shop.Result
const EQUIP := Inventory.EQUIP_START

var catalog: ItemCatalog
var inventory: Inventory
var wallet: Wallet
var stock: MerchantStock
var shop: Shop


func before_each() -> void:
	catalog = Fixtures.catalog()
	for item in catalog.items:
		item.cost = 1000 if not item.is_potion() else 50
	inventory = Inventory.new(catalog)
	wallet = Wallet.new()
	stock = MerchantStock.new(catalog, 7)
	shop = Shop.new(stock, inventory, wallet)


func test_buying_a_slot_pays_and_fills_the_first_empty_cell() -> void:
	wallet.add(1500)
	var item := stock.item_at(0)
	assert_eq(shop.buy_slot(0), Result.OK)
	assert_eq(wallet.gold, 500)
	assert_eq(inventory.item_at(0), item)
	assert_true(stock.is_sold(0))


func test_not_enough_gold_is_refused() -> void:
	wallet.add(999)
	assert_eq(shop.buy_slot(0), Result.NO_GOLD)
	assert_eq(wallet.gold, 999)
	assert_null(inventory.item_at(0))
	assert_false(stock.is_sold(0))


func test_a_sold_or_locked_slot_cannot_be_bought() -> void:
	wallet.add(5000)
	shop.buy_slot(0)
	assert_eq(shop.buy_slot(0), Result.SOLD_OUT)
	assert_eq(shop.buy_slot(3), Result.SOLD_OUT, "locked")
	assert_eq(wallet.gold, 4000)


func test_full_backpack_is_refused_without_paying() -> void:
	wallet.add(5000)
	for i in Inventory.BACKPACK_SIZE:
		inventory.add(catalog.find(&"sword"))
	assert_eq(shop.buy_slot(0), Result.NO_ROOM)
	assert_eq(wallet.gold, 5000)


func test_buying_into_a_chosen_cell() -> void:
	wallet.add(5000)
	inventory.add(catalog.find(&"belt"))
	assert_eq(shop.buy_slot(0, 0), Result.OK, "occupied: bought into a free cell instead")
	assert_eq(inventory.item_at(1), stock.items[0])
	assert_eq(shop.buy_slot(1, EQUIP), Result.OK)
	assert_eq(inventory.item_at(EQUIP), stock.items[1])


func test_potions_stack_and_never_sell_out() -> void:
	wallet.add(1000)
	var red := catalog.find(&"red")
	for i in 10:
		assert_eq(shop.buy_potion(red), Result.OK)
	assert_eq(inventory.count_at(Inventory.HP_POTION_CELL), 9, "its potion cell first")
	assert_eq(inventory.count_at(0), 1, "then the backpack")
	assert_eq(wallet.gold, 500)


func test_potion_dragged_onto_its_stack() -> void:
	wallet.add(1000)
	var red := catalog.find(&"red")
	shop.buy_potion(red, 5)
	assert_eq(shop.buy_potion(red, 5), Result.OK)
	assert_eq(inventory.count_at(5), 2)


func test_selling_pays_the_sell_price() -> void:
	inventory.add(catalog.find(&"sword"))
	assert_eq(shop.sell_value(0), 700)
	assert_eq(shop.sell(0), 700)
	assert_eq(wallet.gold, 700)
	assert_null(inventory.item_at(0))


func test_selling_a_stack_pays_for_each() -> void:
	inventory.add(catalog.find(&"red"), 4)
	assert_eq(shop.sell(Inventory.HP_POTION_CELL), 4 * 35, "from a potion cell too")


func test_selling_an_empty_cell_does_nothing() -> void:
	assert_eq(shop.sell(3), 0)
	assert_eq(wallet.gold, 0)


func test_refresh_costs_gold() -> void:
	assert_eq(shop.refresh(), Result.NO_GOLD)
	wallet.add(MerchantStock.REFRESH_COST)
	assert_eq(shop.refresh(), Result.OK)
	assert_eq(wallet.gold, 0)


func test_a_refresh_with_every_open_slot_sold_is_refused_for_free() -> void:
	wallet.add(MerchantStock.REFRESH_COST)
	assert_true(shop.can_refresh())
	for i in stock.unlocked:
		stock.mark_sold(i)
	var before := stock.items.duplicate()
	assert_false(shop.can_refresh())
	assert_eq(shop.refresh(), Result.NOTHING_TO_REFRESH)
	assert_eq(wallet.gold, MerchantStock.REFRESH_COST, "no gold taken")
	assert_eq(stock.items, before, "nothing re-rolled")


func test_a_refresh_costs_what_the_shop_says() -> void:
	shop.refresh_cost = 50
	wallet.add(120)
	assert_eq(shop.refresh(), Result.OK)
	assert_eq(wallet.gold, 70)


func test_a_locked_cell_is_refused_without_paying() -> void:
	wallet.add(5000)
	inventory.unlocked_backpack = 5
	assert_eq(shop.buy_slot(0, 5), Result.CELL_LOCKED)
	assert_eq(wallet.gold, 5000)
	assert_null(inventory.item_at(5))


func test_no_room_counts_only_the_open_cells() -> void:
	wallet.add(5000)
	inventory.unlocked_backpack = 2
	inventory.add(catalog.find(&"sword"), 1)
	inventory.add(catalog.find(&"belt"), 1)
	assert_eq(shop.buy_slot(0), Result.NO_ROOM)
	assert_eq(wallet.gold, 5000)


# --- The Craft tab ---------------------------------------------------------------


func _real_shop() -> Shop:
	var real := load("res://data/items/catalog.tres") as ItemCatalog
	return Shop.new(MerchantStock.new(real, 1), Inventory.new(real), Wallet.new())


func test_crafting_two_fragments_pays_the_fee_and_puts_the_legendary_in_the_first_cell() -> void:
	var real_shop := _real_shop()
	var bag := real_shop.inventory
	var tear := bag.catalog.find(&"tear_of_the_goddess")
	bag.add(tear)
	bag.put(EQUIP, tear)
	real_shop.wallet.add(2500)
	assert_eq(real_shop.craft_result(EQUIP, 0), bag.catalog.find(&"muramana"))
	assert_eq(real_shop.craft_fee(EQUIP, 0), 2100)
	assert_eq(real_shop.craft(EQUIP, 0), Result.OK)
	assert_eq(real_shop.wallet.gold, 400)
	assert_eq(bag.item_at(EQUIP), bag.catalog.find(&"muramana"), "it stays equipped where the first input was")
	assert_null(bag.item_at(0), "the second fragment is used up")


func test_a_craft_without_the_fee_changes_nothing() -> void:
	var real_shop := _real_shop()
	var bag := real_shop.inventory
	bag.add(bag.catalog.find(&"bf_sword"))
	bag.add(bag.catalog.find(&"cloak_of_agility"))
	var fee := real_shop.craft_fee(0, 1)
	assert_gt(fee, 0)
	real_shop.wallet.add(fee - 1)
	assert_eq(real_shop.craft(0, 1), Result.NO_GOLD)
	assert_eq(real_shop.wallet.gold, fee - 1)
	assert_eq(bag.item_at(0), bag.catalog.find(&"bf_sword"))
	assert_eq(bag.item_at(1), bag.catalog.find(&"cloak_of_agility"))


func test_a_craft_needs_two_different_open_cells_that_make_something() -> void:
	var real_shop := _real_shop()
	var bag := real_shop.inventory
	var tear := bag.catalog.find(&"tear_of_the_goddess")
	bag.add(tear)
	bag.add(tear)
	bag.add(bag.catalog.find(&"giants_belt"))
	bag.add(bag.catalog.find(&"giants_belt"))
	real_shop.wallet.add(9999)
	assert_eq(real_shop.craft(0, 0), Result.NO_RECIPE, "one tear is not two")
	assert_eq(real_shop.craft(0, 5), Result.NO_RECIPE, "an empty cell")
	assert_eq(real_shop.craft(0, -1), Result.NO_RECIPE)
	assert_eq(real_shop.craft(2, 3), Result.NO_RECIPE, "two Giant's Belts make nothing")
	bag.unlocked_backpack = 1
	assert_eq(real_shop.craft(0, 1), Result.NO_RECIPE, "a locked cell")
	assert_eq(real_shop.wallet.gold, 9999)

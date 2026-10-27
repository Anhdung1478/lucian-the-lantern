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
	assert_eq(shop.buy_slot(0, 0), Result.NO_ROOM, "occupied")
	assert_eq(shop.buy_slot(0, EQUIP), Result.OK)
	assert_eq(inventory.item_at(EQUIP), stock.items[0])


func test_potions_stack_and_never_sell_out() -> void:
	wallet.add(1000)
	var red := catalog.find(&"red")
	for i in 10:
		assert_eq(shop.buy_potion(red), Result.OK)
	assert_eq(inventory.count_at(0), 9)
	assert_eq(inventory.count_at(1), 1)
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
	assert_eq(shop.sell(0), 4 * 35)


func test_selling_an_empty_cell_does_nothing() -> void:
	assert_eq(shop.sell(3), 0)
	assert_eq(wallet.gold, 0)


func test_refresh_costs_gold() -> void:
	assert_eq(shop.refresh(), Result.NO_GOLD)
	wallet.add(MerchantStock.REFRESH_COST)
	assert_eq(shop.refresh(), Result.OK)
	assert_eq(wallet.gold, 0)

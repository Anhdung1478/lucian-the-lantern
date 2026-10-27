extends GutTest

const Fixtures := preload("res://tests/unit/item_fixtures.gd")

var catalog: ItemCatalog
var stock: MerchantStock


func before_each() -> void:
	catalog = Fixtures.catalog()
	stock = MerchantStock.new(catalog, 1234)


func test_four_slots_two_unlocked_all_filled() -> void:
	assert_eq(stock.items.size(), MerchantStock.SLOTS)
	assert_eq(stock.unlocked, 2)
	for i in MerchantStock.SLOTS:
		assert_not_null(stock.items[i])
	assert_false(stock.is_locked(1))
	assert_true(stock.is_locked(2))


func test_sells_only_fragments_and_legendaries() -> void:
	for attempt in 200:
		stock.refresh()
		for item in stock.items:
			assert_false(item.is_potion())


func test_legendaries_show_up_about_one_time_in_ten() -> void:
	var legendaries := 0
	for attempt in 500:
		stock.refresh()
		for item in stock.items:
			if item.kind == ItemData.Kind.LEGENDARY:
				legendaries += 1
	assert_between(legendaries, 120, 290, "2000 rolls at 10%")


func test_sold_slots_stay_empty_through_refresh() -> void:
	stock.mark_sold(0)
	assert_null(stock.item_at(0))
	var kept := stock.items[1]
	for attempt in 30:
		stock.refresh()
		assert_null(stock.item_at(0))
	assert_not_null(stock.item_at(1))
	assert_true(stock.is_sold(0))
	assert_false(kept == null)


func test_refresh_rerolls_unsold_slots() -> void:
	var changed := false
	var first := stock.items.duplicate()
	for attempt in 20:
		stock.refresh()
		if stock.items != first:
			changed = true
	assert_true(changed)


func test_locked_slots_sell_nothing() -> void:
	assert_null(stock.item_at(3))
	stock.unlocked = 4
	assert_not_null(stock.item_at(3))


func test_unlocked_stays_between_1_and_4() -> void:
	stock.unlocked = 0
	assert_eq(stock.unlocked, 1)
	stock.unlocked = 9
	assert_eq(stock.unlocked, 4)


func test_changes_emit_changed() -> void:
	watch_signals(stock)
	stock.refresh()
	stock.mark_sold(1)
	stock.unlocked = 3
	assert_signal_emit_count(stock, "changed", 3)

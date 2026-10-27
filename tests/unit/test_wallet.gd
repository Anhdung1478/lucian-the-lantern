extends GutTest

var wallet: Wallet


func before_each() -> void:
	wallet = Wallet.new()


func test_starts_empty() -> void:
	assert_eq(wallet.gold, 0)


func test_add_and_spend() -> void:
	wallet.add(500)
	assert_true(wallet.spend(200))
	assert_eq(wallet.gold, 300)


func test_spending_more_than_owned_is_refused() -> void:
	wallet.add(100)
	assert_false(wallet.spend(101))
	assert_eq(wallet.gold, 100)


func test_can_afford() -> void:
	wallet.add(50)
	assert_true(wallet.can_afford(50))
	assert_false(wallet.can_afford(51))


func test_changed_signal_on_add_spend_and_reset() -> void:
	watch_signals(wallet)
	wallet.add(10)
	wallet.spend(5)
	wallet.spend(500)
	wallet.reset()
	assert_signal_emit_count(wallet, "changed", 3)
	assert_eq(wallet.gold, 0)


func test_negative_add_is_ignored() -> void:
	wallet.add(-20)
	assert_eq(wallet.gold, 0)

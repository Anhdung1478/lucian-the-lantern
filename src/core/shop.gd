class_name Shop
extends RefCounted
## The merchant's rules for one open shop: buying from the Items tab (a
## MerchantStock slot) or the Potions tab, crafting on the Craft tab (two
## fragments into a legendary, or boots and a fragment into better boots, for
## a fee), selling, and refreshing, all for stage gold. Nothing is paid when a
## purchase does not fit. Boots are never sold.

enum Result {
	OK, NO_GOLD, NO_ROOM, CELL_LOCKED, CELL_TAKEN, SOLD_OUT, NOTHING_TO_REFRESH,
	NO_RECIPE, WRONG_CELL,
}

var stock: MerchantStock
var inventory: Inventory
var wallet: Wallet
## What a refresh costs (the Evolution Tree can lower it).
var refresh_cost := MerchantStock.REFRESH_COST


func _init(merchant_stock: MerchantStock, target_inventory: Inventory, stage_wallet: Wallet) -> void:
	stock = merchant_stock
	inventory = target_inventory
	wallet = stage_wallet


## Buys what stock slot `slot` sells, into `cell` or (-1) the first cell
## it fits.
func buy_slot(slot: int, cell := -1) -> Result:
	var item := stock.item_at(slot)
	if item == null:
		return Result.SOLD_OUT
	var result := _buy(item, cell)
	if result == Result.OK:
		stock.mark_sold(slot)
	return result


func buy_potion(potion: ItemData, cell := -1) -> Result:
	return _buy(potion, cell)


## There is an item in `index` and it isn't boots, which can't be sold.
func can_sell(index: int) -> bool:
	var item := inventory.item_at(index)
	return item != null and not item.is_boots()


## Gold the merchant pays for everything in `index` (0 for boots).
func sell_value(index: int) -> int:
	return inventory.item_at(index).sell_price() * inventory.count_at(index) if can_sell(index) else 0


## Sells everything in `index`. Returns the gold gained; boots are refused.
func sell(index: int) -> int:
	if not can_sell(index):
		return 0
	var value := sell_value(index)
	inventory.remove(index)
	wallet.add(value)
	return value


## What the Craft tab makes from the items in cells `first` and `second`
## (see ItemCatalog.craft), or null: both cells must be different, unlocked
## and hold something.
func craft_result(first: int, second: int) -> ItemData:
	if not _craftable(first, second):
		return null
	return inventory.catalog.craft(inventory.item_at(first), inventory.item_at(second))


## The gold crafting cells `first` and `second` costs (0 when they make
## nothing): see ItemCatalog.craft_fee.
func craft_fee(first: int, second: int) -> int:
	if not _craftable(first, second):
		return 0
	return inventory.catalog.craft_fee(inventory.item_at(first), inventory.item_at(second))


## The Craft tab's button: pays the fee, then uses up both items. Upgraded
## boots go in the boots cell; a legendary goes in `first`'s cell and
## `second`'s is emptied. NO_GOLD changes nothing.
func craft(first: int, second: int) -> Result:
	var made := craft_result(first, second)
	if made == null:
		return Result.NO_RECIPE
	if not wallet.spend(craft_fee(first, second)):
		return Result.NO_GOLD
	if made.is_boots():
		var fragment := second if inventory.item_at(first).is_boots() else first
		inventory.craft_into(Inventory.BOOTS_CELL, fragment, made)
	else:
		inventory.craft_into(first, second, made)
	return Result.OK


## A refresh would change something: an open slot is still unsold.
func can_refresh() -> bool:
	return stock.has_unsold()


## Re-rolls the unsold slots for refresh_cost. Refused for free when every
## open slot is sold, since nothing would change.
func refresh() -> Result:
	if not can_refresh():
		return Result.NOTHING_TO_REFRESH
	if not wallet.spend(refresh_cost):
		return Result.NO_GOLD
	stock.refresh()
	return Result.OK


func _buy(item: ItemData, cell: int) -> Result:
	if not wallet.can_afford(item.cost):
		return Result.NO_GOLD
	if cell < 0 and inventory.space_for(item) <= 0:
		return Result.NO_ROOM
	if cell >= 0 and inventory.is_locked(cell):
		return Result.CELL_LOCKED
	if cell >= 0 and not Inventory.accepts(cell, item):
		return Result.WRONG_CELL
	if cell >= 0 and not inventory.can_put(cell, item):
		return Result.CELL_TAKEN
	wallet.spend(item.cost)
	if cell < 0:
		inventory.add(item)
	else:
		inventory.put(cell, item)
	return Result.OK


func _craftable(first: int, second: int) -> bool:
	if inventory.catalog == null or first == second:
		return false
	for index in [first, second]:
		if index < 0 or index >= Inventory.SIZE or inventory.is_locked(index) or inventory.item_at(index) == null:
			return false
	return true

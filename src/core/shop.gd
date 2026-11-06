class_name Shop
extends RefCounted
## The merchant's rules for one open shop: buying from the Items tab (a
## MerchantStock slot) or the Potions tab, upgrading boots on the Boots tab,
## selling, and refreshing, all for stage gold. Nothing is paid when a
## purchase does not fit. Boots are never sold.

enum Result {
	OK, NO_GOLD, NO_ROOM, CELL_LOCKED, CELL_TAKEN, SOLD_OUT, NOTHING_TO_REFRESH,
	NOT_UPGRADABLE, NO_BOOTS, WRONG_CELL,
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


## The boots the Boots tab makes from the boots in `boots_index` and the
## fragment in `fragment_index`, or null when they don't upgrade (see
## ItemCatalog.boots_upgrade).
func upgrade_result(boots_index: int, fragment_index: int) -> ItemData:
	if inventory.catalog == null or boots_index < 0 or fragment_index < 0 or boots_index == fragment_index:
		return null
	if inventory.is_locked(fragment_index):
		return null
	return inventory.catalog.boots_upgrade(inventory.item_at(boots_index), inventory.item_at(fragment_index))


## The Boots tab's Upgrade: pays the new boots' fee, uses up the fragment and
## puts the new boots in the boots cell.
func upgrade_boots(boots_index: int, fragment_index: int) -> Result:
	var boots := inventory.item_at(boots_index) if boots_index >= 0 else null
	if boots == null or not boots.is_boots():
		return Result.NO_BOOTS
	var result := upgrade_result(boots_index, fragment_index)
	if result == null:
		return Result.NOT_UPGRADABLE
	if not wallet.spend(result.upgrade_cost):
		return Result.NO_GOLD
	inventory.remove(fragment_index)
	inventory.set_boots(result)
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

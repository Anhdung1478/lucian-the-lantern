class_name Shop
extends RefCounted
## The merchant's rules for one open shop: buying from the Items tab (a
## MerchantStock slot) or the Potions tab, selling, and refreshing, all for
## stage gold. Nothing is paid when a purchase does not fit.

enum Result { OK, NO_GOLD, NO_ROOM, SOLD_OUT }

var stock: MerchantStock
var inventory: Inventory
var wallet: Wallet


func _init(merchant_stock: MerchantStock, target_inventory: Inventory, stage_wallet: Wallet) -> void:
	stock = merchant_stock
	inventory = target_inventory
	wallet = stage_wallet


## The potions tab: every potion in the catalog, never sold out.
func potions() -> Array[ItemData]:
	return inventory.catalog.potions()


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


## Gold the merchant pays for everything in `index`.
func sell_value(index: int) -> int:
	var item := inventory.item_at(index)
	return item.sell_price() * inventory.count_at(index) if item else 0


## Sells everything in `index`. Returns the gold gained.
func sell(index: int) -> int:
	var value := sell_value(index)
	if inventory.item_at(index) == null:
		return 0
	inventory.remove(index)
	wallet.add(value)
	return value


func refresh() -> Result:
	if not wallet.spend(MerchantStock.REFRESH_COST):
		return Result.NO_GOLD
	stock.refresh()
	return Result.OK


func _buy(item: ItemData, cell: int) -> Result:
	if not wallet.can_afford(item.cost):
		return Result.NO_GOLD
	var fits := inventory.space_for(item) > 0 if cell < 0 else inventory.can_put(cell, item)
	if not fits:
		return Result.NO_ROOM
	wallet.spend(item.cost)
	if cell < 0:
		inventory.add(item)
	else:
		inventory.put(cell, item)
	return Result.OK

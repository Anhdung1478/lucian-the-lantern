class_name MerchantStock
extends RefCounted
## What one merchant visit sells on the Items tab: 4 slots, of which the
## first `unlocked` can be bought from (2, up to 4 from the Evolution Tree).
## Each slot holds a random fragment, or at LEGENDARY_CHANCE a random
## legendary. A slot bought from stays empty for the rest of the visit, even
## after a refresh; a refresh re-rolls the others.

signal changed

const SLOTS := 4
const LEGENDARY_CHANCE := 0.1
const REFRESH_COST := 100

var catalog: ItemCatalog
## What each slot holds, sold or not.
var items: Array[ItemData] = []
var unlocked := 2:
	set(value):
		unlocked = clampi(value, 1, SLOTS)
		changed.emit()

var _sold: Array[bool] = []
var _rng := RandomNumberGenerator.new()


## A negative seed picks a random one.
func _init(item_catalog: ItemCatalog, rng_seed := -1) -> void:
	catalog = item_catalog
	if rng_seed >= 0:
		_rng.seed = rng_seed
	else:
		_rng.randomize()
	items.resize(SLOTS)
	_sold.resize(SLOTS)
	for i in SLOTS:
		items[i] = _roll()


func is_locked(slot: int) -> bool:
	return slot >= unlocked


func is_sold(slot: int) -> bool:
	return _sold[slot]


## The item slot `slot` sells now; null when locked or already bought.
func item_at(slot: int) -> ItemData:
	if is_locked(slot) or _sold[slot]:
		return null
	return items[slot]


func mark_sold(slot: int) -> void:
	_sold[slot] = true
	changed.emit()


func refresh() -> void:
	for i in SLOTS:
		if not _sold[i]:
			items[i] = _roll()
	changed.emit()


func _roll() -> ItemData:
	var pool := catalog.legendaries() if _rng.randf() < LEGENDARY_CHANCE else catalog.fragments()
	return pool[_rng.randi_range(0, pool.size() - 1)]

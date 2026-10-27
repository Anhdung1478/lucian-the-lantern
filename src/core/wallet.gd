class_name Wallet
extends RefCounted
## Stage gold. Every stage starts with 0; the merchant takes it.

signal changed(gold: int)

var gold := 0


func add(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	changed.emit(gold)


func can_afford(amount: int) -> bool:
	return gold >= amount


## Pays `amount` if there is enough gold. False (and nothing paid) otherwise.
func spend(amount: int) -> bool:
	if not can_afford(amount):
		return false
	gold -= amount
	changed.emit(gold)
	return true


func reset() -> void:
	gold = 0
	changed.emit(gold)

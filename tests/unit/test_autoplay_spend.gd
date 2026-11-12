extends GutTest
## The balance bot's tree shopping (tests/tools/autoplay.gd, _spend): short of
## orange, it forges just what is missing, and only when the blue still pays.

const PREFIX := "user://test_autoplay_spend_slot_"
const PLENTY := 1000000

var bot: SceneTree


func before_each() -> void:
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new(PREFIX)
	bot = load("res://tests/tools/autoplay.gd").new()


func after_each() -> void:
	bot.free()


func _save() -> SaveGame:
	return SaveGame.instance()


## A fresh save, Act 1 cleared, holding `blue` and no orange; one _spend.
func _spend_with(blue: int) -> String:
	_save().reset()
	_save().set_cleared(Journey.all_stage_ids(1))
	_save().essences.set_amount(Essences.BLUE, blue)
	return bot._spend(_save())


func _forged(text: String) -> int:
	var total := 0
	for part in text.split(", "):
		if part.begins_with("forged "):
			total += int(part.split(" ")[1])
	return total


func test_it_forges_exactly_the_orange_it_spends() -> void:
	var text := _spend_with(PLENTY)
	assert_gt(_forged(text), 0, text)
	assert_eq(_save().essences.amount(Essences.ORANGE), 0, "nothing forged is left over")
	assert_eq(_forged(text), _save().tree.spent().y, "every forged orange paid for a level")
	assert_eq(PLENTY - _save().essences.amount(Essences.BLUE), _save().tree.spent().x + _forged(text) * Essences.FORGE_BLUE)


func test_it_does_not_forge_until_the_blue_pays_the_level_and_the_forge() -> void:
	# The least blue at which the bot forges anything at all.
	var low := 0
	var high := PLENTY
	while low < high:
		var middle := (low + high) / 2
		if _forged(_spend_with(middle)) > 0:
			high = middle
		else:
			low = middle + 1
	assert_gt(_forged(_spend_with(low)), 0)
	var text := _spend_with(low - 1)
	assert_eq(_forged(text), 0, "one blue short of level and forge: no forge")
	assert_eq(_save().essences.amount(Essences.ORANGE), 0)
	assert_eq(_save().essences.amount(Essences.BLUE) + _save().tree.spent().x, low - 1, "no blue went anywhere else")


func test_it_does_not_forge_when_orange_is_in_hand() -> void:
	_save().reset()
	_save().set_cleared(Journey.all_stage_ids(1))
	_save().essences.set_amount(Essences.BLUE, PLENTY)
	_save().essences.set_amount(Essences.ORANGE, PLENTY)
	assert_eq(_forged(bot._spend(_save())), 0)

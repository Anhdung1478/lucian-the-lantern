extends GutTest

const PREFIX := "user://test_skin_shop_save_slot_"

var shop: SkinShop


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real save.
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new(PREFIX)
	SaveGame.instance().reset()
	SaveGame.instance().slot = 1
	_remove_files()
	shop = SkinShop.new()
	add_child_autofree(shop)


func after_each() -> void:
	_remove_files()


func _remove_files() -> void:
	for n in range(1, SaveGame.SLOTS + 1):
		for file in [SaveGame.instance().path(n), SaveGame.instance().backup_path(n)]:
			if FileAccess.file_exists(file):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(file))


func _card(id: StringName) -> SkinCard:
	for card in shop.cards:
		if card.skin.id == id:
			return card
	return null


func test_new_save_shows_classic_equipped_and_others_to_buy() -> void:
	assert_eq(shop.cards.size(), 5)
	var classic := _card(SaveGame.CLASSIC)
	assert_eq(classic.button.text, "Equipped")
	assert_true(classic.button.disabled)
	for card in shop.cards:
		if card.skin.id == SaveGame.CLASSIC:
			continue
		assert_true(card.button.text.begins_with("Purchase"), card.skin.id)
		assert_true(card.button.disabled, card.skin.id)


func test_purchase_button_follows_essences_alone() -> void:
	var noon := _card(&"high_noon")
	assert_true(noon.button.disabled)
	SaveGame.instance().essences.add(Essences.PURPLE, 25)
	assert_false(noon.button.disabled)
	SaveGame.instance().essences.set_amount(Essences.PURPLE, 0)
	assert_true(noon.button.disabled)
	SaveGame.instance().essences.add(Essences.PURPLE, 25)
	assert_false(noon.button.disabled)
	SaveGame.instance().essences.spend(0, 0, 25)
	assert_true(noon.button.disabled)


func test_purchase_then_equip() -> void:
	SaveGame.instance().essences.add(Essences.PURPLE, 25)
	var noon := _card(&"high_noon")
	assert_false(noon.button.disabled)
	noon.button.pressed.emit()
	assert_eq(SaveGame.instance().essences.amount(Essences.PURPLE), 0)
	assert_eq(noon.button.text, "Equip")
	assert_eq(SaveGame.instance().skin, SaveGame.CLASSIC)
	noon.button.pressed.emit()
	assert_eq(noon.button.text, "Equipped")
	assert_true(noon.button.disabled)
	assert_eq(_card(SaveGame.CLASSIC).button.text, "Equip")
	assert_eq(StageSetup.from_save(SaveGame.instance()).skin.id, &"high_noon")
	assert_false(SaveGame.instance().slot_exists(1), "no file written")


func test_close_popup_has_nothing_to_close() -> void:
	assert_false(shop.close_popup())

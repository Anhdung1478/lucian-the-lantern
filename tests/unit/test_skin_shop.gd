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


func test_the_equipped_button_keeps_the_disabled_text_color() -> void:
	var classic := _card(SaveGame.CLASSIC)
	assert_eq(classic.button.get_theme_color(&"font_disabled_color"), UiStyle.DISABLED_FONT)
	var unaffordable: SkinCard = shop.cards.filter(func(card: SkinCard) -> bool: return card.skin.id != SaveGame.CLASSIC)[0]
	assert_eq(unaffordable.button.get_theme_color(&"font_disabled_color"), UiStyle.ERROR_COLOR, "a price you can't pay stays red")


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


func _purple() -> int:
	return SaveGame.instance().essences.amount(Essences.PURPLE)


func test_purchase_then_equip() -> void:
	SaveGame.instance().essences.add(Essences.PURPLE, 25)
	var noon := _card(&"high_noon")
	assert_false(noon.button.disabled)
	noon.button.pressed.emit()
	assert_not_null(shop.purchase, "Purchase asks first")
	assert_eq(_purple(), 25, "nothing spent yet")
	shop.purchase.purchase_button.pressed.emit()
	assert_null(shop.purchase, "the question closes")
	assert_eq(_purple(), 0)
	assert_eq(noon.button.text, "Equip")
	assert_eq(SaveGame.instance().skin, SaveGame.CLASSIC)
	noon.button.pressed.emit()
	assert_null(shop.purchase, "Equip asks nothing")
	assert_eq(noon.button.text, "Equipped")
	assert_true(noon.button.disabled)
	assert_eq(_card(SaveGame.CLASSIC).button.text, "Equip")
	assert_eq(StageSetup.from_save(SaveGame.instance()).skin.id, &"high_noon")
	assert_false(SaveGame.instance().slot_exists(1), "no file written")


func test_cancel_and_esc_spend_nothing() -> void:
	SaveGame.instance().essences.add(Essences.PURPLE, 25)
	var noon := _card(&"high_noon")
	noon.button.pressed.emit()
	shop.purchase.cancel_button.pressed.emit()
	assert_null(shop.purchase)
	noon.button.pressed.emit()
	assert_true(shop.close_popup(), "ESC closes it")
	assert_null(shop.purchase)
	assert_eq(_purple(), 25)
	assert_false(&"high_noon" in SaveGame.instance().owned_skins)
	assert_eq(noon.button.text, "Purchase  25")


func test_the_table_shows_the_price_what_you_have_and_what_is_left() -> void:
	SaveGame.instance().essences.add(Essences.PURPLE, 75)
	_card(&"project").button.pressed.emit()
	var popup := shop.purchase
	assert_eq(popup.card.title_label.text, "PURCHASE SKIN")
	assert_eq(popup.card.subtitle_label.text, "PROJECT")
	assert_eq(popup.price_label.text, "30")
	assert_eq(popup.owned_label.text, "75")
	assert_eq(popup.after_label.text, "45")
	assert_eq(popup.purchase_button.text, "Purchase  30")


func test_purchase_is_off_while_the_price_cant_be_paid() -> void:
	SaveGame.instance().essences.add(Essences.PURPLE, 25)
	_card(&"high_noon").button.pressed.emit()
	var popup := shop.purchase
	assert_false(popup.purchase_button.disabled)
	SaveGame.instance().essences.set_amount(Essences.PURPLE, 10)
	assert_true(popup.purchase_button.disabled)
	assert_eq(popup.owned_label.text, "10")
	assert_eq(popup.after_label.text, "-15")
	popup.purchase_button.pressed.emit()
	assert_false(&"high_noon" in SaveGame.instance().owned_skins, "a disabled Purchase buys nothing")
	assert_eq(_purple(), 10)


func test_a_hidden_shop_closes_the_question() -> void:
	SaveGame.instance().essences.add(Essences.PURPLE, 25)
	_card(&"high_noon").button.pressed.emit()
	shop.visible = false
	assert_null(shop.purchase)


func test_the_preview_and_the_question_replace_each_other() -> void:
	SaveGame.instance().essences.add(Essences.PURPLE, 25)
	var noon := _card(&"high_noon")
	noon.button.pressed.emit()
	noon.preview_button.pressed.emit()
	assert_null(shop.purchase)
	assert_not_null(shop.preview)
	noon.button.pressed.emit()
	assert_null(shop.preview)
	assert_not_null(shop.purchase)


func test_close_popup_has_nothing_to_close_without_a_preview() -> void:
	assert_false(shop.close_popup())

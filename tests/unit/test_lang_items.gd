extends GutTest
## The items part in Vietnamese: every text of the item scripts and data has
## its translation, and the item cards, the backpack and the merchant show no
## text that skipped Lang.t.

const CATALOG := "res://data/items/catalog.tres"
const SCRIPT_DIRS: Array[String] = [
	"res://src/lucian/items", "res://src/ui/tooltip", "res://src/ui/items", "res://src/ui/backpack", "res://src/ui/shop",
]
const SCRIPTS: Array[String] = [
	"res://src/ui/stat_style.gd", "res://src/stage/merchant.gd", "res://src/stage/loot_drop.gd",
	"res://src/core/item_stats.gd", "res://src/core/item_data.gd", "res://src/core/item_effect.gd",
	"res://src/core/item_catalog.gd", "res://src/core/inventory.gd", "res://src/core/shop.gd",
	"res://src/core/merchant_stock.gd", "res://src/core/loot_table.gd", "res://src/core/stat_block.gd",
	"res://src/core/unit_stats.gd", "res://src/core/energize_charge.gd", "res://src/core/shields.gd",
]
## Pieces other parts' functions hand to these screens: the pop-up's buttons.
const FROM_OTHER_PARTS: Array[String] = ["Yes", "No", "Cancel"]

var catalog: ItemCatalog


func before_each() -> void:
	catalog = load(CATALOG) as ItemCatalog


func after_each() -> void:
	Lang.probe = false
	Lang.use(Lang.ENGLISH)


func _scripts() -> Array:
	var paths: Array = SCRIPTS.duplicate()
	for dir in SCRIPT_DIRS:
		paths.append_array(LangProbe.scripts_in(dir))
	return paths


func test_every_text_in_the_item_scripts_has_a_vietnamese() -> void:
	assert_eq(LangProbe.missing_in(_scripts()), [] as Array[String])


func test_every_text_in_the_item_data_has_a_vietnamese() -> void:
	assert_eq(LangProbe.missing_data("res://data/items"), [] as Array[String])
	var missing: Array[String] = []
	for item in catalog.items:
		for effect in item.effects:
			for text: String in [effect.effect_name, effect.description]:
				if not LangProbe.known().has(text):
					missing.append("%s: %s" % [item.id, text])
	assert_eq(missing, [] as Array[String], "every passive and active, name and text")


## The stat lines carry their icon's path inside an [img] tag, which the probe
## reads as text.
func _icon_paths() -> Array:
	var paths: Array = []
	for icon: Texture2D in StatStyle.ICONS.values():
		paths.append(icon.resource_path)
	return paths


func _plain_in_cards(items: Array, inventory: Inventory = null) -> Array[String]:
	var plain: Array[String] = []
	for item: ItemData in items:
		var card := TooltipCard.item(item, catalog, inventory)
		add_child_autofree(card)
		for text in LangProbe.plain_texts(card, _icon_paths()):
			plain.append("%s: %s" % [item.id, text])
	return plain


func test_the_item_cards_of_every_item_show_no_plain_text() -> void:
	Lang.probe = true
	var inventory := Inventory.new(catalog)
	for id in [&"bf_sword", &"tear_of_the_goddess", &"boots_of_speed"]:
		inventory.add(catalog.find(id))
	assert_eq(_plain_in_cards(catalog.items, inventory), [] as Array[String])


func test_the_stat_cards_show_no_plain_text() -> void:
	Lang.probe = true
	var plain: Array[String] = []
	for key in StatStyle.KEYS:
		var card := TooltipCard.stat(key, "12", "")
		add_child_autofree(card)
		plain.append_array(LangProbe.plain_texts(card, _icon_paths()))
	assert_eq(plain, [] as Array[String])


func test_the_summoner_card_and_a_buff_card_show_no_plain_text() -> void:
	Lang.probe = true
	var spell: SummonerData = load("res://data/summoners/heal.tres")
	var card := TooltipCard.summoner(spell, "D", 240.0)
	add_child_autofree(card)
	assert_eq(LangProbe.plain_texts(card, ["D"]), [] as Array[String], "the summoner card")
	var buff := {"icon": null, "duration": 3.0, "left": 1.5, "name": Lang.t("Annul"), "text": Lang.t("A shield absorbs damage.")}
	var buff_card := TooltipCard.buff(buff)
	add_child_autofree(buff_card)
	assert_eq(LangProbe.plain_texts(buff_card), [] as Array[String], "the buff card")


func test_the_item_buffs_show_no_plain_text() -> void:
	Lang.probe = true
	var groups: Array = [
		[&"kraken_slayer", &"banshees_veil", &"kaenic_rookern", &"spear_of_shojin", &"archangels_staff", &"deaths_dance"],
		[&"gluttonous_greaves", &"armored_advance", &"jaksho_the_protean", &"statikk_shiv", &"immortal_shieldbow", &"chainlaced_crushers"],
	]
	var plain: Array[String] = []
	var seen := 0
	for ids: Array in groups:
		var lucian: Lucian = load("res://src/lucian/lucian.tscn").instantiate()
		add_child_autofree(lucian)
		for i in ids.size():
			lucian.inventory.put(Inventory.EQUIP_START + i, lucian.item_catalog.find(ids[i]))
		lucian.passives.shojin_stacks = 2
		lucian.passives.jaksho_stacks = 2
		lucian.passives.mana_charge = 30.0
		lucian.passives.slay_stacks = 3
		for shown in lucian.passives.buffs():
			seen += 1
			var card := TooltipCard.buff(shown)
			add_child_autofree(card)
			for text in LangProbe.plain_texts(card):
				plain.append("%s: %s" % [shown.id, text])
	assert_gt(seen, 6, "the buffs were built")
	assert_eq(plain, [] as Array[String])


func _backpack(with_shop: bool) -> BackpackScreen:
	var inventory := Inventory.new(catalog)
	for id in [&"bf_sword", &"bf_sword", &"needlessly_large_rod", &"infinity_edge"]:
		inventory.add(catalog.find(id))
	inventory.add(catalog.find(&"hp_potion"), 3)
	var screen := BackpackScreen.new()
	add_child_autofree(screen)
	screen.setup(inventory)
	if with_shop:
		var wallet := Wallet.new()
		wallet.add(5000)
		screen.open_shop(Shop.new(MerchantStock.new(catalog, 3), inventory, wallet))
	else:
		screen.open()
	return screen


func test_the_backpack_with_its_recipes_shows_no_plain_text() -> void:
	Lang.probe = true
	var screen := _backpack(false)
	await wait_physics_frames(3)
	assert_eq(LangProbe.plain_texts(screen, FROM_OTHER_PARTS), [] as Array[String])


func test_the_merchant_shows_no_plain_text_on_each_tab() -> void:
	Lang.probe = true
	var screen := _backpack(true)
	var panel := screen.shop_panel()
	await wait_physics_frames(3)
	for tab in [ShopPanel.ITEMS_TAB, ShopPanel.POTIONS_TAB, ShopPanel.CRAFT_TAB]:
		panel.show_tab(tab)
		await wait_physics_frames(2)
		assert_eq(LangProbe.plain_texts(panel, FROM_OTHER_PARTS), [] as Array[String], "tab %d" % tab)
	panel.show_message(Lang.t("Boots can't be sold"))
	assert_eq(LangProbe.plain_texts(panel, FROM_OTHER_PARTS), [] as Array[String], "a message")


func test_the_crafts_notes_and_question_show_no_plain_text() -> void:
	Lang.probe = true
	var screen := _backpack(true)
	var panel := screen.shop_panel()
	panel.show_tab(ShopPanel.CRAFT_TAB)
	await wait_physics_frames(2)
	panel.first_input().load_cell(0)
	await wait_physics_frames(1)
	panel.second_input().load_cell(1)
	await wait_physics_frames(2)
	assert_eq(panel.craft_state(), ShopPanel.CraftState.READY)
	assert_eq(LangProbe.plain_texts(panel), [] as Array[String], "ready to craft")
	var question := panel.craft_question()
	assert_eq(LangProbe.plain_texts(_label(question)), [] as Array[String], "the question")


func _label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	add_child_autofree(label)
	return label


func test_the_vietnamese_item_card_names_the_stats_and_the_passive() -> void:
	Lang.use(Lang.VIETNAMESE)
	var edge := catalog.find(&"infinity_edge")
	var card := TooltipCard.item(edge, catalog)
	add_child_autofree(card)
	var text := ""
	for body in card.find_children("*", "RichTextLabel", true, false):
		text += TooltipText.plain((body as RichTextLabel).text) + "\n"
	assert_string_contains(text, "+65 Sức Mạnh Công Kích")
	assert_string_contains(text, "+20% Tỉ Lệ Chí Mạng")
	assert_string_contains(text, "Nội Tại — Hoàn Hảo")
	assert_string_contains(text, "Đòn chí mạng gây thêm 40% sát thương.")
	assert_string_contains(text, "Công thức: Kiếm B.F. + Kiếm B.F. + ")
	assert_string_contains(text, " vàng tại thương nhân.")


func test_the_vietnamese_texts_with_values_keep_their_values() -> void:
	Lang.use(Lang.VIETNAMESE)
	assert_eq(Lang.t("%d gold") % 1100, "1100 vàng")
	assert_eq(Lang.t("Sells for %d gold") % 770, "Bán được 770 vàng")
	assert_eq(ItemStats.line(&"attack_speed", 0.25), "+25% Tốc Độ Đánh")
	assert_eq(StatStyle.stat_name(&"armor"), "Giáp")
	assert_eq(TooltipText.plain(TooltipCard.potion_text(catalog.find(&"hp_potion"))), "Hồi 200 Máu trong 5 s.")
	assert_eq(TooltipText.plain(TooltipText.ratio([0.6], 1, "AD")), "(+60% SMCK)")
	assert_eq(ShopPanel.hint(ShopPanel.ITEMS_TAB), "Nhấp chuột phải hoặc kéo để mua.\nKéo món đồ vào ô đỏ để bán.")


func test_english_is_unchanged() -> void:
	assert_eq(Lang.t("Sells for %d gold") % 770, "Sells for 770 gold")
	assert_eq(ItemStats.line(&"ad", 65.0), "+65 Attack Damage")
	assert_eq(TooltipText.plain(TooltipCard.potion_text(catalog.find(&"hp_potion"))), "Restores 200 HP over 5 s.")

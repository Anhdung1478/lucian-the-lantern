extends GutTest

const Slot := ChampionProgress.Slot

var lucian: Lucian


func before_each() -> void:
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	add_child_autofree(lucian)


func plain_description(slot: Slot) -> String:
	return TooltipText.plain(lucian.skills[slot].describe())


func test_q_lists_damage_and_scaling_per_rank() -> void:
	var text := plain_description(Slot.Q)
	assert_string_contains(text, "80/110/140/170/200 (+60/70/80/90/100% AD) physical damage")


func test_w_lists_magic_damage_and_move_speed() -> void:
	var text := plain_description(Slot.W)
	assert_string_contains(text, "75/110/145/180/215 (+90% AP) magic damage")
	assert_string_contains(text, "60/65/70/75/80 move speed")


func test_e_gives_dash_range() -> void:
	assert_string_contains(plain_description(Slot.E), "280")


func test_r_lists_shots_and_per_shot_damage() -> void:
	var text := plain_description(Slot.R)
	assert_string_contains(text, "22 shots")
	assert_string_contains(text, "15/30/45 (+25% AD) (+15% AP) physical damage")


func test_passive_gives_second_shot_ratio() -> void:
	assert_string_contains(TooltipText.plain(lucian.passive.describe()), "60% AD")


func test_every_skill_has_a_max_rank_bonus() -> void:
	for skill in lucian.skills:
		assert_ne(skill.max_rank_bonus(), "", skill.data.display_name)


func test_current_rank_is_highlighted() -> void:
	lucian.try_rank_up(Slot.Q)
	assert_string_contains(lucian.skills[Slot.Q].describe(), "[color=#%s]80[/color]" % TooltipText.BRIGHT)


func test_skill_cards_build() -> void:
	var cards: Array[Control] = [TooltipCard.skill(lucian, null, null, "")]
	for skill in lucian.skills:
		cards.append(TooltipCard.skill(lucian, skill, null, "Q"))
	for card in cards:
		assert_not_null(card)
		card.free()


func test_item_cards_build_for_every_item() -> void:
	for item in lucian.item_catalog.items:
		var card := TooltipCard.item(item, lucian.item_catalog)
		assert_not_null(card, str(item.id))
		card.free()


func test_buff_cards_build_for_every_buff() -> void:
	for id in [&"kraken_slayer", &"statikk_shiv", &"spear_of_shojin", &"archangels_staff", &"black_cleaver"]:
		lucian.inventory.add(lucian.item_catalog.find(id))
	for i in 5:
		lucian.inventory.apply_drop(i, Inventory.EQUIP_START + i)
	lucian.passives.shojin_stacks = 2
	lucian.passives.mana_charge = 30.0
	lucian.add_speed_buff(&"fervor", 20.0, 0.0, 2.0)
	lucian.shield = 120.0
	lucian.restores.start(lucian.item_catalog.find(&"hp_potion"))
	var buffs := lucian.buffs()
	assert_eq(buffs.size(), 7)
	for buff in buffs:
		var card := TooltipCard.buff(buff)
		assert_not_null(card, str(buff.id))
		card.free()


func test_summoner_cards_build() -> void:
	for spell in SummonerSpells.SPELLS:
		var card := TooltipCard.summoner(spell, "D", spell.cooldown)
		assert_not_null(card, str(spell.id))
		card.free()


## Every line of text on a card, tags removed.
func card_text(card: Control) -> String:
	var parts: PackedStringArray = []
	for label: Label in card.find_children("*", "Label", true, false):
		parts.append(label.text)
	for rich: RichTextLabel in card.find_children("*", "RichTextLabel", true, false):
		parts.append(rich.get_parsed_text())
	return "\n".join(parts)


func test_boots_cards_say_they_cant_be_sold_and_how_they_upgrade() -> void:
	var catalog := lucian.item_catalog
	var card := TooltipCard.item(catalog.find(&"boots_of_speed"), catalog)
	var text := card_text(card)
	assert_string_contains(text, "Boots")
	assert_string_contains(text, "Can't be sold")
	assert_false(text.contains("gold\n"), "no price")
	assert_string_contains(text, "all but Giant's Belt")
	card.free()
	card = TooltipCard.item(catalog.find(&"berserkers_greaves"), catalog)
	assert_string_contains(card_text(card), "Upgrade at the merchant's Craft tab with a Recurve Bow (500 gold) into Gunmetal Greaves.")
	card.free()
	card = TooltipCard.item(catalog.find(&"immortal_path"), catalog)
	text = card_text(card)
	assert_string_contains(text, "Fully upgraded.")
	assert_string_contains(text, "Now and Forever")
	card.free()


func test_potion_cards_point_to_their_key() -> void:
	var card := TooltipCard.item(lucian.item_catalog.find(&"mp_potion"), lucian.item_catalog)
	assert_string_contains(card_text(card), "Put it in its potion cell and press 8 to drink.")
	assert_false(card_text(card).contains("Right-click"), "no Use button any more")
	card.free()


func test_crafting_cards_send_the_player_to_the_merchant() -> void:
	var catalog := lucian.item_catalog
	var card := TooltipCard.item(catalog.find(&"tear_of_the_goddess"), catalog)
	assert_string_contains(card_text(card), "Craft it with another fragment at the merchant's Craft tab.")
	card.free()
	card = TooltipCard.item(catalog.find(&"muramana"), catalog)
	assert_string_contains(card_text(card), "Recipe: Tear of the Goddess + Tear of the Goddess + 2100 gold at the merchant.")
	card.free()

extends GutTest


func test_known_keys() -> void:
	for key in [&"ad", &"ap", &"attack_speed", &"crit_chance", &"armor", &"mr", &"max_hp", &"max_mana",
			&"ability_haste", &"move_speed", &"move_speed_pct", &"lifesteal", &"omnivamp",
			&"armor_pen", &"magic_pen", &"heal_shield_power", &"tenacity"]:
		assert_true(ItemStats.is_known(key), str(key))
	assert_false(ItemStats.is_known(&"lethality"))


func test_flat_line() -> void:
	assert_eq(ItemStats.line(&"ad", 65.0), "+65 Attack Damage")
	assert_eq(ItemStats.line(&"max_hp", 350.0), "+350 Health")


func test_percent_line() -> void:
	assert_eq(ItemStats.line(&"attack_speed", 0.25), "+25% Attack Speed")
	assert_eq(ItemStats.line(&"crit_chance", 0.15), "+15% Critical Strike Chance")
	assert_eq(ItemStats.line(&"armor_pen", 0.3), "+30% Armor Penetration")


func test_amount_is_the_signed_number_or_percent() -> void:
	assert_eq(ItemStats.amount(&"ad", 65.0), "+65")
	assert_eq(ItemStats.amount(&"attack_speed", 0.25), "+25%")

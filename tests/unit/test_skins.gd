extends GutTest
## Skins: the data matches the doc table, and each one changes Lucian's stats,
## body and HUD portrait.

## Id -> [cost, bonus lines, weakness lines], from docs/main_screen.md.
const DOC := {
	&"classic": [0, [], []],
	&"high_noon": [25, ["+15% AD"], ["−15% Attack Speed"]],
	&"project": [30, ["+20% Attack Speed", "+15% Move Speed"], ["−10% AD"]],
	&"pulsefire": [20, ["+15% AP", "+15 Ability Haste"], ["−10% Attack Speed"]],
	&"vampire": [25, ["+15% Lifesteal", "Kills heal 2% max HP"], ["−20% max HP"]],
}

var lucian: Lucian


func before_each() -> void:
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	add_child_autofree(lucian)


func give_equipped(id: StringName) -> void:
	var inventory := lucian.inventory
	inventory.add(lucian.item_catalog.find(id))
	var from := -1
	for i in Inventory.BACKPACK_SIZE:
		if inventory.item_at(i) and inventory.item_at(i).id == id:
			from = i
	inventory.apply_drop(from, Inventory.EQUIP_START, false)


func test_five_skins_in_doc_order() -> void:
	var ids: Array[StringName] = []
	for skin in Skins.ALL:
		ids.append(skin.id)
	assert_eq(ids, [&"classic", &"high_noon", &"project", &"pulsefire", &"vampire"] as Array[StringName])
	assert_eq(Skins.CLASSIC, &"classic")


func test_costs_and_card_lines_match_the_doc() -> void:
	for skin in Skins.ALL:
		var row: Array = DOC[skin.id]
		assert_eq(skin.cost, row[0], str(skin.id))
		assert_eq(Array(skin.bonuses), row[1], str(skin.id))
		assert_eq(Array(skin.weaknesses), row[2], str(skin.id))
		assert_ne(skin.display_name, "", str(skin.id))
		assert_ne(skin.playstyle, "", str(skin.id))


func test_every_skin_has_art_the_same_size_as_classic() -> void:
	var classic := Skins.find(&"classic")
	assert_eq(classic.portrait.get_size(), Vector2(384, 384))
	assert_eq(classic.body.get_size(), Vector2(128, 128))
	for skin in Skins.ALL:
		assert_eq(skin.portrait.get_size(), classic.portrait.get_size(), str(skin.id))
		assert_eq(skin.body.get_size(), classic.body.get_size(), str(skin.id))


## Every body SVG draws Lucian's own gun's muzzle at (46, -15) and Senna's at
## (46, 15); shots and muzzle flashes leave from these markers.
func test_muzzle_markers_sit_at_the_gun_tips() -> void:
	assert_eq((lucian.get_node("Visuals/MuzzleLeft") as Marker2D).position, Vector2(46, -15))
	assert_eq((lucian.get_node("Visuals/MuzzleRight") as Marker2D).position, Vector2(46, 15))


func test_find_unknown_is_classic() -> void:
	assert_eq(Skins.find(&"vampire").id, &"vampire")
	assert_eq(Skins.find(&"nope"), Skins.find(&"classic"))


func test_classic_changes_nothing() -> void:
	assert_eq(lucian.skin, Skins.find(&"classic"))
	var base := lucian.base_stats.at_level(1)
	assert_almost_eq(lucian.stats.ad, base.ad, 0.001)
	assert_almost_eq(lucian.stats.attack_speed, base.attack_speed, 0.0001)
	assert_almost_eq(lucian.stats.max_hp, base.max_hp, 0.001)


func test_high_noon_hits_harder_and_slower() -> void:
	var classic_attack_speed := lucian.stats.attack_speed
	lucian.apply_skin(Skins.find(&"high_noon"))
	assert_almost_eq(lucian.stats.ad, lucian.base_stats.at_level(1).ad * 1.15, 0.001)
	assert_lt(lucian.stats.attack_speed, classic_attack_speed)


func test_skin_scales_after_items_and_level_ups() -> void:
	lucian.apply_skin(Skins.find(&"high_noon"))
	give_equipped(&"bf_sword")
	lucian.progress.set_level(5)
	assert_almost_eq(lucian.stats.ad, (lucian.base_stats.at_level(5).ad + 35.0) * 1.15, 0.001)


func test_tree_bonus_adds_before_the_skin_scales() -> void:
	lucian.tree_bonus = {&"ad": 10.0}
	lucian.apply_skin(Skins.find(&"high_noon"))
	assert_almost_eq(lucian.stats.ad, (lucian.base_stats.at_level(1).ad + 10.0) * 1.15, 0.001)


func test_project_moves_and_attacks_faster_for_less_ad() -> void:
	var classic := lucian.stats
	lucian.apply_skin(Skins.find(&"project"))
	assert_almost_eq(lucian.stats.move_speed, classic.move_speed * 1.15, 0.001)
	assert_almost_eq(lucian.stats.ad, classic.ad * 0.9, 0.001)
	assert_gt(lucian.stats.attack_speed, classic.attack_speed)


func test_pulsefire_gives_haste_and_ap() -> void:
	var classic_attack_speed := lucian.stats.attack_speed
	lucian.apply_skin(Skins.find(&"pulsefire"))
	assert_almost_eq(lucian.stats.ability_haste, 15.0, 0.001)
	assert_lt(lucian.stats.attack_speed, classic_attack_speed)
	give_equipped(&"needlessly_large_rod")
	var rod_ap: float = lucian.item_catalog.find(&"needlessly_large_rod").stats[&"ap"]
	assert_almost_eq(lucian.stats.ap, rod_ap * 1.15, 0.001)


func test_vampire_trades_max_hp_for_lifesteal() -> void:
	var classic_max_hp := lucian.stats.max_hp
	var vampire := Skins.find(&"vampire")
	lucian.apply_skin(vampire)
	assert_almost_eq(lucian.stats.max_hp, classic_max_hp * 0.8, 0.001)
	assert_almost_eq(lucian.stats.lifesteal, 0.15, 0.0001)
	assert_almost_eq(lucian.hp, lucian.stats.max_hp, 0.001)
	assert_eq((lucian.get_node("Visuals/Body") as Sprite2D).texture, vampire.body)
	assert_eq(lucian.visuals.body_texture(), vampire.body)


func _hit(enemy_hp: float) -> float:
	var enemy := Enemy.new()
	enemy.max_hp = 1000.0
	add_child_autofree(enemy)
	enemy.hp = maxf(enemy_hp, 1.0)
	lucian.hp = lucian.stats.max_hp * 0.5
	var before := lucian.hp
	# A Q (no life steal) that kills an enemy at 1 HP, or scratches one at 50.
	enemy.take_damage(lucian.make_damage(1.0 if enemy_hp > 1.0 else 5.0, DamageInfo.Type.TRUE, &"q"))
	return lucian.hp - before


func test_vampire_kill_heals_two_percent_max_hp() -> void:
	lucian.apply_skin(Skins.find(&"vampire"))
	assert_almost_eq(_hit(0.0), lucian.stats.max_hp * 0.02, 0.0001)


func test_vampire_hit_that_does_not_kill_does_not_heal() -> void:
	lucian.apply_skin(Skins.find(&"vampire"))
	assert_almost_eq(_hit(50.0), 0.0, 0.0001)


func test_classic_kill_does_not_heal() -> void:
	assert_almost_eq(_hit(0.0), 0.0, 0.0001)


func test_hud_shows_the_skin_portrait() -> void:
	var vampire := Skins.find(&"vampire")
	lucian.apply_skin(vampire)
	var hud: Hud = load("res://src/ui/hud/hud.tscn").instantiate()
	add_child_autofree(hud)
	hud.setup(lucian, Wallet.new())
	assert_eq(hud.portrait.texture, vampire.portrait)

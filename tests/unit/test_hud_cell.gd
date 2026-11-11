extends GutTest
## HudCell and the HUD cells built on it: skills, summoner spells and items.

var lucian: Lucian


func before_each() -> void:
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	add_child_autofree(lucian)


func _skill_slot(slot: int, key: String) -> SkillSlot:
	var ui := SkillSlot.new()
	ui.setup(lucian, lucian.skills[slot], null, key)
	add_child_autofree(ui)
	return ui


func test_a_cooldown_reads_tenths_under_a_second_and_whole_seconds_above() -> void:
	assert_eq(HudCell.seconds_text(0.44), "0.4")
	assert_eq(HudCell.seconds_text(1.0), "1")
	assert_eq(HudCell.seconds_text(2.3), "3")
	assert_eq(HudCell.seconds_text(59.01), "60")


func test_a_cell_lights_up_while_the_mouse_is_on_it() -> void:
	var summoner := SummonerSlot.new(lucian, 0)
	add_child_autofree(summoner)
	var item := HudItemSlot.new(lucian.inventory, Inventory.EQUIP_START)
	add_child_autofree(item)
	for cell: Control in [_skill_slot(ChampionProgress.Slot.Q, "Q"), summoner, item]:
		assert_false(cell._hovered)
		cell.mouse_entered.emit()
		assert_true(cell._hovered, "lit")
		cell.mouse_exited.emit()
		assert_false(cell._hovered, "and dark again")


func test_a_skills_icon_sits_inside_its_cells_rim() -> void:
	var ui := _skill_slot(ChampionProgress.Slot.Q, "Q")
	var cell := ui._cell_rect()
	assert_eq(cell.size, Vector2.ONE * SkillSlot.ICON_SIZE)
	assert_eq(ui._icon.position, cell.position + Vector2.ONE * HudCell.INSET)
	assert_eq(ui._icon.size, cell.size - Vector2.ONE * HudCell.INSET * 2.0)


func test_the_passive_cell_is_centered_in_the_skills_band() -> void:
	var ui := SkillSlot.new()
	ui.setup(lucian, null, null, "", SkillSlot.PASSIVE_SIZE)
	add_child_autofree(ui)
	var cell := ui._cell_rect()
	assert_eq(cell.size, Vector2.ONE * SkillSlot.PASSIVE_SIZE)
	assert_eq(cell.get_center().y, SkillSlot.PLUS_HEIGHT + SkillSlot.ICON_SIZE * 0.5)


func test_a_rebound_key_shows_in_the_tab() -> void:
	var ui := _skill_slot(ChampionProgress.Slot.Q, "Q")
	ui.set_key("M4")
	assert_eq(ui._key, "M4")

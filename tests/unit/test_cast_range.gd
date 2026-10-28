extends GutTest
## Range indicators: the shape of each skill, item active and summoner spell,
## the HUD slots that show one while hovered, and what the indicator shows.

const Slot := ChampionProgress.Slot
const EQUIP := Inventory.EQUIP_START

var lucian: Lucian


func before_each() -> void:
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	add_child_autofree(lucian)


func equip(id: StringName, slot := 0) -> void:
	lucian.inventory.put(EQUIP + slot, lucian.item_catalog.find(id))


func learn_all() -> void:
	lucian.progress.set_level(6)
	for slot in [Slot.Q, Slot.W, Slot.E, Slot.R]:
		assert_true(lucian.try_rank_up(slot))


func test_skills_show_nothing_until_learned() -> void:
	for slot in [Slot.Q, Slot.W, Slot.E, Slot.R]:
		assert_null(lucian.skill_range(slot), str(slot))


func test_skill_shapes() -> void:
	learn_all()
	var q := lucian.skill_range(Slot.Q)
	assert_eq(q.kind, CastRange.Kind.LINE)
	assert_eq(q.reach, 800.0)
	assert_eq(q.width, 60.0)
	var w := lucian.skill_range(Slot.W)
	assert_eq(w.kind, CastRange.Kind.LINE)
	assert_eq(w.reach, Lucian.GUN_REACH + 900.0, "the missile flies 900 from the gun")
	assert_eq(w.cross, Vector2(400, 60), "the cross it bursts into")
	var e := lucian.skill_range(Slot.E)
	assert_eq(e.reach, 280.0)
	assert_eq(e.min_reach, 0.0, "as short as the cursor is close")
	assert_true(e.landing)
	var r := lucian.skill_range(Slot.R)
	assert_eq(r.kind, CastRange.Kind.TWIN_LINES)
	assert_eq(r.reach, Lucian.GUN_REACH + 1200.0)
	assert_gt(r.spread, 0.0)


func test_q_range_grows_at_max_rank() -> void:
	lucian.progress.set_level(9)
	for i in 5:
		lucian.try_rank_up(Slot.Q)
	assert_eq(lucian.skill_range(Slot.Q).reach, 900.0)
	assert_eq(lucian.skill_range(Slot.Q).width, 90.0)


func test_item_shapes() -> void:
	equip(&"hextech_gunblade", 0)
	equip(&"galeforce", 1)
	equip(&"hextech_rocketbelt", 2)
	equip(&"infinity_edge", 3)
	assert_eq(lucian.equip_range(0).kind, CastRange.Kind.CIRCLE)
	assert_eq(lucian.equip_range(0).reach, ItemActives.GUNBLADE_RANGE)
	assert_true(lucian.equip_range(0).targets_enemy)
	assert_eq(lucian.equip_range(1).reach, ItemActives.GALEFORCE_DASH)
	assert_true(lucian.equip_range(1).landing)
	assert_eq(lucian.equip_range(1).min_reach, 0.0)
	assert_eq(lucian.equip_range(2).reach, ItemActives.ROCKETBELT_DASH)
	assert_eq(lucian.equip_range(2).min_reach, 0.0)
	assert_null(lucian.equip_range(3), "no active")
	assert_null(lucian.equip_range(4), "empty")


func test_summoner_shapes() -> void:
	lucian.summoners.slots = [&"flash", &"smite"]
	var flash := lucian.summoner_range(0)
	assert_eq(flash.kind, CastRange.Kind.CIRCLE, "a blink: a circle, not a path")
	assert_eq(flash.reach, SummonerSpells.FLASH_RANGE)
	assert_true(flash.landing, "where he lands, while aiming")
	assert_false(flash.targets_enemy)
	assert_eq(lucian.summoner_range(1).kind, CastRange.Kind.CIRCLE)
	assert_eq(lucian.summoner_range(1).reach, SummonerSpells.SMITE_RANGE)
	assert_true(lucian.summoner_range(1).targets_enemy)
	for id in [&"ghost", &"barrier", &"heal", &"clarity"]:
		lucian.summoners.slots = [id, &"smite"]
		assert_null(lucian.summoner_range(0), str(id))


func test_landing_is_kept_between_min_and_max() -> void:
	var e := CastRange.dash(280.0, 160.0)
	assert_eq(e.landing_distance(50.0), 160.0)
	assert_eq(e.landing_distance(200.0), 200.0)
	assert_eq(e.landing_distance(900.0), 280.0)


func test_hud_slots_give_their_range() -> void:
	learn_all()
	equip(&"hextech_gunblade", 0)
	var hud: Hud = load("res://src/ui/hud/hud.tscn").instantiate()
	add_child_autofree(hud)
	hud.setup(lucian, Wallet.new())
	assert_null(Hud.hover_range_of(hud.skill_row.get_child(0)), "the passive")
	assert_eq(Hud.hover_range_of(hud.skill_row.get_child(1)).reach, 800.0, "Q")
	var summoner: Control = hud.skill_row.get_child(hud.skill_row.get_child_count() - 2)
	assert_eq(Hud.hover_range_of(summoner).reach, SummonerSpells.FLASH_RANGE)
	assert_eq(Hud.hover_range_of(hud.item_grid.get_child(0)).reach, ItemActives.GUNBLADE_RANGE)
	assert_null(Hud.hover_range_of(hud.item_grid.get_child(1)), "empty slot")
	assert_null(Hud.hover_range_of(null))


func test_the_aimed_cast_wins_over_the_hovered_one() -> void:
	var indicator := lucian.indicator
	assert_null(indicator.shown())
	indicator.hovered = CastRange.circle(500.0)
	assert_eq(indicator.shown(), indicator.hovered)
	indicator.aimed = CastRange.line(800.0, 60.0)
	assert_eq(indicator.shown(), indicator.aimed)
	await wait_process_frames(1)
	assert_true(indicator.visible)
	indicator.aimed = null
	indicator.hovered = null
	await wait_process_frames(1)
	assert_false(indicator.visible)

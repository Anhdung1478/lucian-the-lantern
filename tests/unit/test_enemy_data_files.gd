extends GutTest

const IDS := [
	"melee_minion", "ranged_minion", "siege_minion", "super_minion", "thresh_1", "akshan",
	"raptor", "raptor_big", "murkwolf", "murkwolf_big", "krug", "krug_big", "gromp",
	"blue_sentinel", "red_brambleback", "rift_scuttler",
]
## Act 3's monsters (docs/implementation/phase7.md): id -> [kind, behavior,
## camp, HP, armor, MR, damage, attack range, attack interval, speed, radius,
## gold, XP].
const ACT_3 := {
	"raptor": [&"normal", &"swarm", &"raptors", 110.0, 10.0, 0.0, 8.0, 90.0, 0.9, 330.0, 22.0, 20, 10],
	"raptor_big": [&"normal", &"swarm", &"raptors", 360.0, 20.0, 10.0, 18.0, 100.0, 1.0, 320.0, 32.0, 55, 28],
	"murkwolf": [&"normal", &"flank", &"wolves", 190.0, 10.0, 10.0, 12.0, 100.0, 1.1, 340.0, 26.0, 30, 16],
	"murkwolf_big": [&"normal", &"flank", &"wolves", 480.0, 20.0, 15.0, 24.0, 110.0, 1.2, 320.0, 36.0, 70, 36],
	"krug": [&"normal", &"brute", &"krugs", 200.0, 30.0, 10.0, 16.0, 100.0, 1.5, 200.0, 28.0, 30, 16],
	"krug_big": [&"normal", &"brute", &"krugs", 720.0, 40.0, 15.0, 34.0, 120.0, 1.8, 170.0, 46.0, 80, 42],
	"gromp": [&"normal", &"spit", &"gromp", 650.0, 15.0, 25.0, 22.0, 500.0, 1.7, 160.0, 44.0, 80, 40],
	"blue_sentinel": [&"elite", &"brute", &"blue", 1700.0, 35.0, 35.0, 42.0, 150.0, 1.6, 240.0, 50.0, 160, 90],
	"red_brambleback": [&"elite", &"brute", &"red", 1700.0, 35.0, 35.0, 40.0, 150.0, 1.5, 240.0, 50.0, 160, 90],
	"rift_scuttler": [&"elite", &"flee", &"scuttle", 600.0, 20.0, 20.0, 0.0, 0.0, 1.25, 250.0, 34.0, 120, 60],
}


func _data(id: String) -> EnemyData:
	return load("res://data/enemies/%s.tres" % id) as EnemyData


func test_every_enemy_file_is_complete() -> void:
	for id in IDS:
		var data := _data(id)
		assert_not_null(data, id)
		assert_eq(data.id, StringName(id))
		assert_not_null(data.art, "%s art" % id)
		assert_true(data.kind in [&"normal", &"elite", &"mini_boss", &"boss"], "%s kind" % id)


func test_melee_and_ranged_minions_walk_at_240() -> void:
	assert_eq(_data("melee_minion").move_speed, 240.0)
	assert_eq(_data("ranged_minion").move_speed, 240.0)


func test_the_ranged_minion_is_a_magic_kiter() -> void:
	var data := _data("ranged_minion")
	assert_eq(data.damage_type, DamageInfo.Type.MAGIC)
	assert_lt(data.keep_min, data.keep_max)
	assert_lte(data.keep_max, data.attack_range)


func test_the_siege_minion_marks_a_circle_for_a_second() -> void:
	var data := _data("siege_minion")
	assert_eq(data.area_radius, 110.0)
	assert_eq(data.warn_time, 1.0)


func test_the_super_minion_empowers_500_around_it() -> void:
	assert_eq(_data("super_minion").empower_radius, 500.0)


func _every_file() -> Array[EnemyData]:
	var found: Array[EnemyData] = []
	for file in DirAccess.get_files_at("res://data/enemies/"):
		if file.ends_with(".tres"):
			found.append(load("res://data/enemies/" + file) as EnemyData)
	return found


## A boss missing from SaveGame.BOSS_IDS is dropped from "bosses" on load,
## so it would pay its first-time purple again after every reload. (The ids
## of bosses still to come are listed before their files exist.)
func test_every_boss_and_mini_boss_is_in_boss_ids() -> void:
	var bosses := 0
	for data in _every_file():
		if data.kind in [&"boss", &"mini_boss"]:
			bosses += 1
			assert_has(SaveGame.BOSS_IDS, String(data.id), String(data.id))
	assert_gt(bosses, 0)


func test_the_act_3_and_4_bosses_are_in_boss_ids() -> void:
	for id in ["infernal_drake", "ocean_drake", "elder_dragon", "dark_lucian"]:
		assert_has(SaveGame.BOSS_IDS, id)


func test_the_new_fields_are_off_by_default() -> void:
	var data := EnemyData.new()
	assert_eq(data.camp, &"")
	assert_eq(data.split_into, &"")
	assert_eq(data.split_count, 0)
	assert_eq(data.escape_after, 0.0)
	assert_eq(data.extra_blue, 0)
	assert_eq(data.extra_orange, 0)
	assert_eq(data.buff_on_kill, &"")


func test_the_act_3_monsters_match_the_table() -> void:
	var fields := ["kind", "behavior", "camp", "max_hp", "armor", "mr", "damage", "attack_range", "attack_interval", "move_speed", "radius", "gold", "xp"]
	for id: String in ACT_3:
		var data := _data(id)
		for i in fields.size():
			assert_eq(data.get(fields[i]), ACT_3[id][i], "%s %s" % [id, fields[i]])


func test_the_act_3_on_hits_and_specials() -> void:
	for id in ["raptor", "raptor_big", "murkwolf", "murkwolf_big", "krug", "krug_big", "blue_sentinel", "red_brambleback"]:
		assert_eq(_data(id).damage_type, DamageInfo.Type.PHYSICAL, id)
	var gromp := _data("gromp")
	assert_eq(gromp.damage_type, DamageInfo.Type.MAGIC)
	assert_eq(gromp.projectile_speed, 500.0)
	assert_eq([gromp.keep_min, gromp.keep_max], [380.0, 480.0])
	assert_eq([gromp.hit_burn, gromp.hit_burn_time, gromp.burn_type()], [6.0, 3.0, DamageInfo.Type.MAGIC])
	var blue := _data("blue_sentinel")
	assert_eq([blue.hit_slow, blue.hit_slow_time, blue.buff_on_kill], [0.3, 1.5, JungleBuffs.BLUE])
	var red := _data("red_brambleback")
	assert_eq([red.hit_burn, red.hit_burn_time, red.burn_type(), red.buff_on_kill], [8.0, 3.0, DamageInfo.Type.MAGIC, JungleBuffs.RED])
	var krug_big := _data("krug_big")
	assert_eq([krug_big.split_into, krug_big.split_count], [&"krug", 2])
	var scuttler := _data("rift_scuttler")
	assert_eq([scuttler.escape_after, scuttler.extra_blue, scuttler.extra_orange], [15.0, 45, 4])


## A split names an enemy file the stage can load, and a buff on kill is a
## jungle buff Lucian knows.
func test_every_split_and_buff_on_kill_names_something_real() -> void:
	var splits := 0
	var buffs := 0
	for data in _every_file():
		if data.split_into != &"":
			splits += 1
			assert_true(ResourceLoader.exists(Stage.ENEMY_PATH % data.split_into), "%s splits into %s" % [data.id, data.split_into])
			assert_gt(data.split_count, 0, String(data.id))
		if data.buff_on_kill != &"":
			buffs += 1
			assert_true(JungleBuffs.is_jungle_buff(data.buff_on_kill), "%s gives %s" % [data.id, data.buff_on_kill])
	assert_gt(splits, 0)
	assert_gt(buffs, 0)

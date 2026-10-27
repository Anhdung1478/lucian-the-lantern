extends GutTest

const SKILL_FILES := [
	"res://data/skills/q_piercing_light.tres",
	"res://data/skills/w_ardent_blaze.tres",
	"res://data/skills/e_relentless_pursuit.tres",
	"res://data/skills/r_the_culling.tres",
]


func test_lucian_stats_load_with_sane_values() -> void:
	var stats := load("res://data/lucian_stats.tres") as UnitStats
	assert_not_null(stats)
	var level_1 := stats.at_level(1)
	assert_gt(level_1.max_hp, 0.0)
	assert_gt(level_1.attack_speed, 0.0)
	assert_gt(level_1.move_speed, 0.0)
	assert_gt(level_1.attack_range, 0.0)


func test_skill_files_have_one_value_or_one_per_rank() -> void:
	for path in SKILL_FILES:
		var data := load(path) as SkillData
		assert_not_null(data, path)
		for field in ["mana_cost", "cooldown", "base_damage", "ad_ratio", "ap_ratio"]:
			var size: int = data.get(field).size()
			assert_true(
				size == 0 or size == 1 or size == data.max_rank,
				"%s %s has %d values for %d ranks" % [path, field, size, data.max_rank]
			)
		assert_gt(data.cooldown.size(), 0, "%s needs a cooldown" % path)


func test_skill_max_ranks_match_progress_rules() -> void:
	var expected := ChampionProgress.MAX_RANKS
	for i in SKILL_FILES.size():
		var data := load(SKILL_FILES[i]) as SkillData
		assert_eq(data.max_rank, expected[i], SKILL_FILES[i])

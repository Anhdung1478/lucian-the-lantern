extends GutTest
## The stage part in Vietnamese: every text of its scripts and data has a
## translation, the screens built with Lang.probe on show no plain text, and
## the most visible texts read right.

## Mouse buttons and keys, as the bindings name them.
const KEY_NAMES: Array[String] = ["RMB", "LMB"]

const SCRIPT_DIRS: Array[String] = [
	"res://src/stage", "res://src/ui/hud", "res://src/ui/stage", "res://src/enemies", "res://src/combat",
	"res://src/allies", "res://src/lucian",
]
## Scripts of those folders that belong to the items part.
const OTHER_PARTS: Array[String] = ["merchant.gd", "loot_drop.gd"]
const CORE_SCRIPTS: Array[String] = [
	"death_recap", "elite_trait", "endless_modifiers", "endless_plan", "endless_runner", "enemy_data", "lantern_gifts",
	"resolve", "stage_setup", "stage_stats", "wave_plan", "wave_runner", "kill_rewards", "crowd_control", "skill_data",
	"summoner_data", "champion_progress", "damage_info", "damage_over_time", "dps_meter",
]
const DATA_DIRS: Array[String] = ["res://data/skills", "res://data/summoners", "res://data/enemies"]


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real save or settings.
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new("user://test_lang_stage_save_slot_")
	if GameSettings._instance == null or GameSettings._instance.path == GameSettings.DEFAULT_PATH:
		GameSettings._instance = GameSettings.new("user://test_lang_stage_settings.json")


func after_each() -> void:
	Lang.probe = false
	Lang.use(Lang.ENGLISH)
	get_tree().paused = false


func _scripts() -> Array[String]:
	var paths: Array[String] = []
	for dir in SCRIPT_DIRS:
		for path in LangProbe.scripts_in(dir):
			if path.contains("/lucian/items/") or path.get_file() in OTHER_PARTS:
				continue
			paths.append(path)
	for name in CORE_SCRIPTS:
		paths.append("res://src/core/%s.gd" % name)
	return paths


func _essences(blue := 0, orange := 0, purple := 0) -> Dictionary:
	return {Essences.BLUE: blue, Essences.ORANGE: orange, Essences.PURPLE: purple}


func test_every_text_in_the_scripts_has_a_vietnamese() -> void:
	assert_eq(LangProbe.missing_in(_scripts()), [] as Array[String])


func test_every_text_in_the_data_has_a_vietnamese() -> void:
	var missing: Array[String] = []
	for dir in DATA_DIRS:
		missing.append_array(LangProbe.missing_data(dir))
	assert_eq(missing, [] as Array[String])


func test_the_result_card_after_a_clear_has_no_plain_text() -> void:
	Lang.probe = true
	var result := StageResult.new()
	add_child_autofree(result)
	var rows := [["Time", "1:05"], ["Waves", "5 / 5"], ["Kills", "40"], ["Damage dealt", "900"], ["Damage taken", "20"],
		["Gold earned", "300"], ["Level reached", "6"], ["Gift", LanternGifts.display_name(1)]]
	var lines: Array[String] = [Lang.t("Stage %s is open") % "1-2", Lang.t("+%d purple essence (first clear)") % 2]
	result.show_result(true, "2-1", rows, _essences(5, 3, 2), lines, false, true)
	assert_eq(LangProbe.plain_texts(result), [] as Array[String])


func test_the_result_card_after_a_defeat_with_a_recap_has_no_plain_text() -> void:
	Lang.probe = true
	var stats := StageStats.new()
	stats.damage_taken = 100.0
	stats.damage_by_source = {&"melee_minion": 60.0, &"burn": 40.0}
	stats.last_hit_by = &"burn"
	stats.last_hit_with = DamageOverTime.SOURCE
	var recap := DeathRecap.build(stats, SaveGame.instance().tree, SaveGame.instance().essences)
	var result := StageResult.new()
	add_child_autofree(result)
	result.show_result(false, "2-1", [["Time", "1:05"]], _essences(), [] as Array[String], false, false, EndlessDirector.RUN_OVER, recap)
	assert_eq(LangProbe.plain_texts(result), [] as Array[String])
	assert_eq(result.title.text, Lang.mark("RUN OVER"))


func test_the_stage_info_and_the_wave_preview_have_no_plain_text() -> void:
	Lang.probe = true
	var runner := WaveRunner.new(WavePlan.waves("2-2"), &"test_boss")
	var info := StageInfo.new()
	add_child_autofree(info)
	info.setup("2-2", runner)
	info.refresh()
	var preview := WavePreview.new()
	add_child_autofree(preview)
	preview.setup(runner)
	assert_eq(LangProbe.plain_texts(info), [] as Array[String], "waiting")
	assert_eq(LangProbe.plain_texts(preview), [] as Array[String], "the next wave")
	runner.skip()
	for i in 10:
		runner.tick(WaveRunner.GROUP_GAP)
	info.refresh()
	assert_eq(LangProbe.plain_texts(info), [] as Array[String], "fighting")


func test_the_wave_banner_and_the_modifier_picks_have_no_plain_text() -> void:
	Lang.probe = true
	for line in WaveBanner.lines(3) + WaveBanner.lines(5, &"boss", Lang.t("Thresh")) + WaveBanner.lines(4, &"mini_boss", Lang.t("Karthus")):
		assert_eq(LangProbe.plain_texts(_label(line)), [] as Array[String], line)
	var modifiers := ModifierPick.new([1, 2, EndlessModifiers.NOTHING] as Array[int])
	add_child_autofree(modifiers)
	assert_eq(LangProbe.plain_texts(modifiers), [] as Array[String], "modifiers")
	var gifts := ModifierPick.new([1, 6, 7] as Array[int], true)
	add_child_autofree(gifts)
	assert_eq(LangProbe.plain_texts(gifts), [] as Array[String], "gifts")


func _label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	add_child_autofree(label)
	return label


func test_the_hud_of_a_stage_has_no_plain_text() -> void:
	Lang.probe = true
	SaveGame.instance().reset()
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_stage(SaveGame.instance(), 1, 1))
	add_child_autofree(stage)
	await wait_process_frames(3)
	stage.lucian.invulnerable = true
	stage._tip(&"move")
	stage._tip(&"attack_move")
	stage._tip(&"hook")
	stage.hud.tips.show_tip(&"trait", EliteTrait.tip(EliteTrait.SWIFT))
	await wait_process_frames(2)
	assert_eq(LangProbe.plain_texts(stage.hud, KEY_NAMES), [] as Array[String])
	stage.show_result(false)
	assert_eq(LangProbe.plain_texts(stage.result), [] as Array[String], "the result")


func test_lucians_buffs_and_skill_texts_go_through_lang() -> void:
	Lang.probe = true
	var lucian: Lucian = load("res://src/lucian/lucian.tscn").instantiate()
	add_child_autofree(lucian)
	lucian.barrier = 50.0
	lucian.shield = 20.0
	lucian.add_slow(&"test", 0.2, 3.0)
	lucian.add_speed_buff(&"ardent_blaze", 0.0, 0.2, 2.0, true)
	lucian.add_speed_buff(&"fervor", 30.0, 0.0, 2.0)
	lucian.add_burn(&"test", 5.0, 3.0, DamageInfo.Type.TRUE)
	lucian.add_cc(CrowdControl.Kind.STUN, 1.0)
	lucian.add_cc(CrowdControl.Kind.FEAR, 1.0)
	lucian.add_cc(CrowdControl.Kind.ROOT, 1.0)
	lucian.add_jungle_buff(JungleBuffs.BLUE)
	lucian.add_jungle_buff(JungleBuffs.RED)
	lucian.gift = 2
	lucian.set_resolve(2, 3)
	for row in lucian.buffs():
		assert_eq(LangProbe.plain_texts(_label(row.name), []), [] as Array[String], row.name)
		assert_eq(LangProbe.plain_texts(_label(TooltipText.plain(row.text)), []), [] as Array[String], row.id)
	var texts: Array[String] = [lucian.passive.describe()]
	for skill in lucian.skills:
		texts.append(skill.describe() + skill.max_rank_bonus())
		texts.append(lucian.skill_lock_note(skill.slot))
	for text in texts:
		assert_eq(LangProbe.plain_texts(_label(TooltipText.plain(text))), [] as Array[String], text)


func test_the_most_visible_texts_in_vietnamese() -> void:
	Lang.use(Lang.VIETNAMESE)
	assert_eq(Lang.t("Wave %d/%d") % [2, 5], "Đợt 2/5")
	assert_eq(Lang.t("STAGE CLEARED"), "HOÀN THÀNH MÀN")
	assert_eq(Lang.t("Enemies: %d") % 7, "Kẻ địch: 7")
	assert_eq(WaveBanner.lines(3)[0], "ĐỢT 3")
	assert_eq(LanternGifts.display_name(1), "Lưỡi Sắc")
	assert_eq(LanternGifts.text(6), "Hút Máu Toàn Phần +6%", "the percent sign is not doubled")
	assert_eq(Resolve.describe(1).begins_with("Quyết Tâm: mỗi lần thất bại"), true)
	assert_eq(Resolve.journey_line(0, 1), "")
	assert_eq(DeathRecap.TIP_BURN.length() > 0, true)
	assert_eq(Lang.t(DeathRecap.TIP_BURN), "Mặt đất cháy gây sát thương liên tục khi bạn đứng trên đó. Hãy bước ra ngay.")


func test_a_text_with_values_keeps_them_in_vietnamese() -> void:
	Lang.use(Lang.VIETNAMESE)
	assert_eq(Lang.t("%s %d / %d: +%d%% damage, -%d%% taken") % ["Quyết Tâm", 3, 5, 30, 30], "Quyết Tâm 3 / 5: +30% sát thương, -30% sát thương nhận")
	assert_eq(Lang.t("Killed by %s") % "Lính Cận Chiến", "Bị Lính Cận Chiến hạ gục")
	assert_eq(Lang.t("+%d purple essence (%s, first kill)") % [3, "Thresh"], "+3 tinh chất tím (Thresh, lần đầu hạ gục)")


func test_the_english_is_unchanged() -> void:
	assert_eq(LanternGifts.text(6), "+6% omnivamp")
	assert_eq(WaveBanner.lines(3)[0], "WAVE 3")
	assert_eq(Resolve.journey_note(1), "Lucian fell here once.\nEach defeat makes this stage a little easier, up to %d times, until it is cleared." % Resolve.MAX_STACKS)

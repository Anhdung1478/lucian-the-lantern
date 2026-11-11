extends SceneTree
## Prints, for every story stage: the HP its waves hold (after act, wave and
## stage scaling), the XP, gold (after the stage's gold share) and blue they
## pay (an Ancient Krug's splits included, summons not), the level Lucian reaches by the end (from the
## act's start level), and the strongest wave's raw damage per second. Then
## each boss's and mini boss's wall: its HP ÷ the gold earned in its stage
## before its wave, and each act's average gold per stage (the boss's own
## gold included).
## Usage: godot --headless --path . -s res://tests/tools/stage_budget.gd


func _initialize() -> void:
	print("stage  waves  enemies  waveHP(sum)  maxWaveHP  bossHP  XP    level  gold   blue  maxWaveDPS  HP per wave  |  gold at each break")
	var walls: PackedStringArray = []
	var act_golds: PackedStringArray = []
	for act in range(1, Journey.ACTS.size() + 1):
		var act_gold := 0.0
		for number in range(1, Journey.stage_count(act) + 1):
			var id := Journey.stage_id(act, number)
			var waves := WavePlan.waves(id)
			var hp := 0.0
			var max_wave_hp := 0.0
			var max_dps := 0.0
			var xp := 0.0
			var gold := 0.0
			var blue := 0
			var count := 0
			var wave_hps: PackedStringArray = []
			## The gold earned by each break (every kill, no tree bonus).
			var break_golds: PackedStringArray = []
			## The gold earned before the last wave began.
			var gold_before_last := 0.0
			for w in waves.size():
				var wave_hp := 0.0
				var dps := 0.0
				if w == waves.size() - 1:
					gold_before_last = gold
				for enemy_id: StringName in waves[w]:
					var data: EnemyData = load("res://data/enemies/%s.tres" % enemy_id)
					var unit_hp := data.max_hp * data.hp_scale(act, w + 1) * WavePlan.hp_share(id, enemy_id)
					wave_hp += unit_hp
					# Its splits (an Ancient Krug's two Krugs) count too.
					if data.split_into != &"":
						var split: EnemyData = load("res://data/enemies/%s.tres" % data.split_into)
						wave_hp += data.split_count * split.max_hp * split.hp_scale(act, w + 1) * WavePlan.hp_share(id, data.split_into)
						xp += data.split_count * split.xp * split.reward_scale(act)
						gold += data.split_count * split.gold * split.reward_scale(act) * WavePlan.gold_share(id, data.split_into)
						blue += data.split_count * act
					if data.attack_interval > 0.0:
						dps += data.damage * data.damage_scale(act, w + 1) / data.attack_interval
					xp += data.xp * data.reward_scale(act)
					gold += data.gold * data.reward_scale(act) * WavePlan.gold_share(id, enemy_id)
					blue += act * (5 if data.kind == &"elite" else 1) if not data.is_boss_kind() else (50 if data.kind == &"mini_boss" else 100)
					count += 1
				hp += wave_hp
				if w < waves.size() - 1:
					break_golds.append("%d" % gold)
				max_wave_hp = maxf(max_wave_hp, wave_hp)
				wave_hps.append("%.1fk" % (wave_hp / 1000.0))
				max_dps = maxf(max_dps, dps)
			var boss := WavePlan.boss(id)
			var boss_hp := 0.0
			act_gold += gold
			if boss != &"":
				var boss_data: EnemyData = load("res://data/enemies/%s.tres" % boss)
				boss_hp = boss_data.max_hp
				blue += 100
				act_gold += boss_data.gold
				walls.append(_wall(id, boss_data, gold))
			var mini_boss := WavePlan.mini_boss(id)
			if mini_boss != &"":
				walls.append(_wall(id, load("res://data/enemies/%s.tres" % mini_boss), gold_before_last))
			var progress := ChampionProgress.new()
			# Where the act starts him (V1.3), else level 1.
			var start: Variant = StageSetup.for_stage(SaveGame.new("user://budget_"), act, number).get("start_level")
			if start is int:
				progress.set_level(start)
			progress.add_xp(int(xp))
			print("%-5s  %5d  %7d  %11d  %9d  %6d  %5d  %5d  %5d  %4d  %9d  %s  |  %s" % [id, waves.size(), count, hp, max_wave_hp, boss_hp, xp,
				progress.level, gold, blue, max_dps, " · ".join(wave_hps), " · ".join(break_golds)])
		act_golds.append("Act %d %d" % [act, act_gold / Journey.stage_count(act)])
	print("\nwalls: HP ÷ the gold earned before its wave")
	for line in walls:
		print(line)
	print("\ngold per stage, by act (the boss's included): %s" % " · ".join(act_golds))
	quit()


## "3-2  infernal_drake   9000 / 2490 = 3.61".
static func _wall(id: String, data: EnemyData, gold_before: float) -> String:
	return "%-5s  %-16s  %6d / %5d = %.2f" % [id, data.id, data.max_hp, gold_before, data.max_hp / maxf(gold_before, 1.0)]

extends SceneTree
## Prints, for every story stage: the HP its waves hold (after act, wave and
## stage scaling), the XP, gold and blue they pay, the level Lucian reaches
## by the end (from the act's start level), and the strongest wave's raw
## damage per second.
## Usage: godot --headless --path . -s res://tests/tools/stage_budget.gd


func _initialize() -> void:
	print("stage  waves  enemies  waveHP(sum)  maxWaveHP  bossHP  XP    level  gold   blue  maxWaveDPS  HP per wave  |  gold at each break")
	for act in range(1, Journey.ACTS.size() + 1):
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
			for w in waves.size():
				var wave_hp := 0.0
				var dps := 0.0
				for enemy_id: StringName in waves[w]:
					var data: EnemyData = load("res://data/enemies/%s.tres" % enemy_id)
					var unit_hp := data.max_hp * data.hp_scale(act, w + 1) * WavePlan.hp_share(id, enemy_id)
					wave_hp += unit_hp
					# Its splits (an Ancient Krug's two Krugs) count too.
					if data.split_into != &"":
						var split: EnemyData = load("res://data/enemies/%s.tres" % data.split_into)
						wave_hp += data.split_count * split.max_hp * split.hp_scale(act, w + 1) * WavePlan.hp_share(id, data.split_into)
					if data.attack_interval > 0.0:
						dps += data.damage * data.damage_scale(act, w + 1) / data.attack_interval
					xp += data.xp * data.reward_scale(act)
					gold += data.gold * data.reward_scale(act)
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
			if boss != &"":
				boss_hp = (load("res://data/enemies/%s.tres" % boss) as EnemyData).max_hp
				blue += 100
			var progress := ChampionProgress.new()
			# Where the act starts him (V1.3), else level 1.
			var start: Variant = StageSetup.for_stage(SaveGame.new("user://budget_"), act, number).get("start_level")
			if start is int:
				progress.set_level(start)
			progress.add_xp(int(xp))
			print("%-5s  %5d  %7d  %11d  %9d  %6d  %5d  %5d  %5d  %4d  %9d  %s  |  %s" % [id, waves.size(), count, hp, max_wave_hp, boss_hp, xp,
				progress.level, gold, blue, max_dps, " · ".join(wave_hps), " · ".join(break_golds)])
	quit()

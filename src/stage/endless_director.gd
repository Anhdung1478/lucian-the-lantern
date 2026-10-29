class_name EndlessDirector
extends Node
## Endless mode inside a stage (design: Endless mode). The Stage adds one only
## when run.endless and calls its hooks: start (the runner), scale (each
## spawn's strength) and skip_to_boss (debug). It records the best as each
## wave is won, and lets the break after a boss wave go (the modifier pick
## comes there later). The rest of the run is the story's stage: the merchant
## in breaks, rewards, loot.

var stage: Stage
var runner: EndlessRunner


## The run's waves, made up as they come; the Stage wires the rest of the
## runner as for the story.
func start(owner_stage: Stage) -> EndlessRunner:
	stage = owner_stage
	runner = EndlessRunner.new()
	runner.break_started.connect(_on_wave_won)
	runner.boss_cleared.connect(_on_boss_cleared)
	return runner


## A spawn's strength in place of the act and wave scaling (call before it
## joins the tree): a normal or elite enemy's HP and damage grow with its
## wave; a boss's or mini boss's HP is fixed by its wave, and its basic damage
## and skill hits grow by tier.
func scale(unit: EnemyUnit) -> void:
	var data := unit.data
	match data.kind:
		&"boss":
			unit.max_hp = EndlessPlan.boss_hp(unit.wave)
			_power(unit, EndlessPlan.boss_power(unit.wave))
		&"mini_boss":
			unit.max_hp = EndlessPlan.mini_boss_hp(unit.wave)
			_power(unit, EndlessPlan.mini_boss_power(unit.wave))
		_:
			unit.max_hp = data.max_hp * EndlessPlan.hp_scale(unit.wave)
			unit.damage = data.damage * EndlessPlan.damage_scale(unit.wave)


## Debug: the next boss wave comes next. A held break is let go first, so the
## jump never leaves the runner waiting.
func skip_to_boss() -> void:
	runner.release()
	runner.skip_to_boss()


func _power(unit: EnemyUnit, power: float) -> void:
	unit.damage = unit.data.damage * power
	unit.skill_scale = power


## A wave was won (its break starts): the best, in memory only. The stage's
## end saves it.
func _on_wave_won(_seconds: float) -> void:
	SaveGame.instance().record_endless(runner.waves_cleared)


## For now the break after a boss wave counts down at once.
func _on_boss_cleared(_wave: int) -> void:
	runner.release()

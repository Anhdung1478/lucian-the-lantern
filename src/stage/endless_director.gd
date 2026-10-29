class_name EndlessDirector
extends Node
## Endless mode inside a stage (design: Endless mode). The Stage adds one only
## when run.endless and calls its hooks: start (the runner), scale (each
## spawn's strength) and skip_to_boss (debug). It records the best as each
## wave is won. After a boss wave it holds the break for the ModifierPick over
## a paused game, applies the pick and lets the break go. At the end it adds
## the run's rows and "New best" to the result (add_result). The rest of the
## run is the story's stage: the merchant in breaks, rewards, loot.

## The result's title: a run only ends when Lucian falls.
const RUN_OVER := "RUN OVER"
## The result's green line, when the run beat the best it started with.
const NEW_BEST := "New best: %d %s!"
## The Modifier row with none in effect (none picked yet, or Nothing).
const NO_MODIFIER := "None"

var stage: Stage
var runner: EndlessRunner
## The run's modifier (an EndlessModifiers id): NONE before the first pick
## and after Nothing.
var modifier := EndlessModifiers.NONE
## The pick on screen after a boss wave, or null.
var pick: ModifierPick
## The save's best when the run started; "New best" beats this one, as the
## save's own rises with each wave won.
var start_best := 0


## The run's waves, made up as they come; the Stage wires the rest of the
## runner as for the story.
func start(owner_stage: Stage) -> EndlessRunner:
	stage = owner_stage
	start_best = SaveGame.instance().endless_best
	runner = EndlessRunner.new()
	runner.break_started.connect(_on_wave_won)
	runner.boss_cleared.connect(_on_boss_cleared)
	return runner


## A spawn's strength in place of the act and wave scaling (call before it
## joins the tree): a normal or elite enemy's HP and damage grow with its
## wave; a boss's or mini boss's HP is fixed by its wave, and its basic damage
## and skill hits grow by tier. Then the modifier's: every enemy's speed, and
## bosses' and mini bosses' HP.
func scale(unit: EnemyUnit) -> void:
	var data := unit.data
	match data.kind:
		&"boss":
			unit.max_hp = EndlessPlan.boss_hp(unit.wave) * EndlessModifiers.boss_hp(modifier)
			_power(unit, EndlessPlan.boss_power(unit.wave))
		&"mini_boss":
			unit.max_hp = EndlessPlan.mini_boss_hp(unit.wave) * EndlessModifiers.boss_hp(modifier)
			_power(unit, EndlessPlan.mini_boss_power(unit.wave))
		_:
			unit.max_hp = data.max_hp * EndlessPlan.hp_scale(unit.wave)
			unit.damage = data.damage * EndlessPlan.damage_scale(unit.wave)
	unit.move_speed *= EndlessModifiers.enemy_speed(modifier)


## Modifier `id` replaces the run's (Nothing clears it): the elite count,
## the rewards and Lucian's stats at once; enemy speed and boss HP from the
## next spawn.
func choose(id: int) -> void:
	modifier = EndlessModifiers.NONE if id == EndlessModifiers.NOTHING else id
	runner.elite_mult = EndlessModifiers.elite_mult(modifier)
	EndlessModifiers.apply_rewards(stage.run, modifier)
	stage.lucian.set_run_scale(EndlessModifiers.run_scale(modifier))


## The run's parts of the result: Waves cleared on top of `rows` and the
## modifier's downside at the bottom ([label, value] pairs), and "New best"
## in `lines` when the run beat the best it started with.
func add_result(rows: Array, lines: Array[String]) -> void:
	var waves := runner.waves_cleared
	rows.push_front(["Waves cleared", str(waves)])
	rows.append(["Modifier", NO_MODIFIER if modifier == EndlessModifiers.NONE else EndlessModifiers.downside(modifier)])
	if waves > start_best:
		lines.append(NEW_BEST % [waves, "wave" if waves == 1 else "waves"])


## Debug: the next boss wave comes next. An open pick closes and a held break
## is let go first, so the jump never leaves the runner waiting.
func skip_to_boss() -> void:
	_close_pick()
	runner.release()
	runner.skip_to_boss()


func _power(unit: EnemyUnit, power: float) -> void:
	unit.damage = unit.data.damage * power
	unit.skill_scale = power


## A wave was won (its break starts): the best, in memory only. The stage's
## end saves it.
func _on_wave_won(_seconds: float) -> void:
	SaveGame.instance().record_endless(runner.waves_cleared)


## Deferred: the boss's death can come in a shot's physics callback.
func _on_boss_cleared(_wave: int) -> void:
	_open_pick.call_deferred()


## The pick over a paused game, the backpack and menu closed and the screens
## locked (no ESC, no P). None once the run is over or a debug jump let the
## break go.
func _open_pick() -> void:
	if pick or not runner.held or stage.lucian.dead or stage.result.visible:
		return
	var screens := stage.screens
	if screens.backpack.visible:
		screens.set_backpack_open(false)
	screens.set_menu_open(false)
	screens.locked = true
	pick = ModifierPick.new(EndlessModifiers.offer(stage.rng, modifier))
	pick.picked.connect(_on_picked)
	add_child(pick)
	get_tree().paused = true


## A card: it becomes the run's modifier, and the break counts down. Only the
## first click counts (the pick is freed at the frame's end).
func _on_picked(id: int) -> void:
	if pick == null:
		return
	choose(id)
	Sfx.play(&"buff")
	_close_pick()
	runner.release()


func _close_pick() -> void:
	if pick == null:
		return
	pick.queue_free()
	pick = null
	stage.screens.locked = false
	get_tree().paused = false

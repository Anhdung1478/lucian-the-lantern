class_name Resolve
extends RefCounted
## Resolve: a story stage that beats Lucian gets a little easier each time,
## so every player gets through in the end. Each defeat on a stage not yet
## cleared gives one stack there, up to MAX_STACKS. A stack raises the damage
## Lucian deals and lowers the damage he takes by the difficulty's step
## (Difficulty.resolve_step: none on Extreme). Clearing the stage ends it;
## replays of a cleared stage, Training and Endless never have it. With the
## Gameplay setting off the defeats are still counted, but nothing applies.

const MAX_STACKS := 5
## The Gameplay setting's key (GameSettings), on by default.
const SETTING := &"resolve"
## The buff row's id, name and icon (a fist under a rising chevron).
const BUFF := &"resolve"
const NAME := "Resolve"
const ICON := preload("res://assets/art/ui/status_empower.svg")


## The setting is on in the game's shared settings.
static func enabled() -> bool:
	return GameSettings.instance().get_value(SETTING)


## The stacks `defeats` defeats give on `difficulty`: one each, up to
## MAX_STACKS; none where a stack is worth nothing (Extreme).
static func stacks(defeats: int, difficulty: int) -> int:
	return clampi(defeats, 0, MAX_STACKS) if Difficulty.resolve_step(difficulty) > 0.0 else 0


## The stacks the next try on `stage_id` gets from `save`: none with the
## setting off, on a cleared stage or outside the story.
static func stacks_on(save: SaveGame, stage_id: String) -> int:
	return stacks(save.defeats_on(stage_id), save.difficulty) if enabled() else 0


## Every hit Lucian deals with `count` stacks is multiplied by this.
static func damage_dealt_scale(count: int, difficulty: int) -> float:
	return 1.0 + Difficulty.resolve_step(difficulty) * count


## Every hit Lucian takes with `count` stacks is multiplied by this, on top
## of the difficulty's own scale: 5 stacks halve it on Normal.
static func damage_taken_scale(count: int, difficulty: int) -> float:
	return 1.0 - Difficulty.resolve_step(difficulty) * count


## What `count` stacks are worth, in percent: 30 for 3 stacks on Normal.
static func percent(count: int, difficulty: int) -> int:
	return roundi(Difficulty.resolve_step(difficulty) * count * 100.0)


## What `difficulty` does to Resolve, for the difficulty page's hover text.
static func describe(difficulty: int) -> String:
	var share := percent(1, difficulty)
	if share <= 0:
		return "No %s: a defeat makes no stage easier." % NAME
	return "%s: each defeat on a stage gives +%d%% damage dealt and -%d%% damage taken there, up to %d times." % [
		NAME, share, share, MAX_STACKS]


## The buff row's entry for `count` stacks after `defeats` defeats on the
## stage (see Lucian.buffs): the stack count on the icon, no timer, and a
## card that reads "+30% damage dealt, -30% damage taken. You fell here 3
## times."
static func buff(count: int, defeats: int, difficulty: int) -> Dictionary:
	var share := percent(count, difficulty)
	var text := "[kw]+%d%% damage dealt[/kw], [kw]-%d%% damage taken[/kw]. You fell here %s." % [share, share, _times(defeats)]
	return {"id": BUFF, "name": NAME, "icon": ICON, "text": TooltipText.colorize(text), "count": str(count),
		"left": 0.0, "duration": 0.0, "ready": false}


## The DEFEATED screen's line for a next try with `count` stacks: "Resolve
## 3 / 5: +30% damage, -30% damage taken on your next try"; "" with none.
static func defeat_line(count: int, difficulty: int) -> String:
	if count <= 0:
		return ""
	var share := percent(count, difficulty)
	return "%s %d / %d: +%d%% damage, -%d%% damage taken on your next try" % [NAME, count, MAX_STACKS, share, share]


## The Journey's line for a stage with `count` stacks: "Resolve 3 / 5: +30%
## damage, -30% taken"; "" with none.
static func journey_line(count: int, difficulty: int) -> String:
	if count <= 0:
		return ""
	var share := percent(count, difficulty)
	return "%s %d / %d: +%d%% damage, -%d%% taken" % [NAME, count, MAX_STACKS, share, share]


## The Journey line's hover text, after `defeats` defeats on the stage, on
## two lines.
static func journey_note(defeats: int) -> String:
	return "Lucian fell here %s.\nEach defeat makes this stage a little easier, up to %d times, until it is cleared." % [
		_times(defeats), MAX_STACKS]


## "once", "3 times".
static func _times(count: int) -> String:
	return "once" if count == 1 else "%d times" % count

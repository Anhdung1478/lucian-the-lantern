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


## The DEFEATED screen's line for a next try with `count` stacks: "Resolve
## 3 / 5: +30% damage, -30% damage taken on your next try"; "" with none.
static func defeat_line(count: int, difficulty: int) -> String:
	if count <= 0:
		return ""
	var share := percent(count, difficulty)
	return "Resolve %d / %d: +%d%% damage, -%d%% damage taken on your next try" % [count, MAX_STACKS, share, share]

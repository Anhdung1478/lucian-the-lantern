class_name Journey
extends RefCounted
## The story map: 6 acts of stages ("act-stage" ids like "2-3"), which of them
## are open, and what each stage card shows. Static data and rules only.

## Per act: name, story line, waves of each stage, and which stages have a
## mini boss. The last stage of every act is its boss.
const ACTS := [
	{"name": "The Loss", "story": "Lucian and Senna fight together, until Thresh takes her soul.", "waves": [2], "mini_bosses": []},
	{"name": "The Sentinels", "story": "Lucian trains with Akshan to prove he's ready to hunt Thresh.", "waves": [2, 3, 3], "mini_bosses": []},
	{"name": "The Jungle", "story": "Lucian crosses the jungle, facing the drakes and the Elder Dragon.", "waves": [3, 4, 4, 5, 5], "mini_bosses": [2, 4]},
	{"name": "The Darkness", "story": "Lucian faces his own fear and grief as Dark Lucian.", "waves": [4, 5, 5], "mini_bosses": []},
	{"name": "Shadow Isles", "story": "Lucian fights through Maokai, Elise and Karthus.", "waves": [5, 5, 6, 6, 6], "mini_bosses": [2, 4]},
	{"name": "The Lantern", "story": "Lucian defeats Thresh and frees Senna.", "waves": [6, 6, 7, 7, 7], "mini_bosses": [2, 4]},
]
## Endless Mode opens once this many acts are cleared.
const ENDLESS_ACT := 3
const ENDLESS_MAPS := ["Random", "Mid lane", "Training ground", "Jungle", "Dark mid lane", "Dead forest", "Thresh's domain"]


static func stage_id(act: int, stage: int) -> String:
	return "%d-%d" % [act, stage]


static func stage_count(act: int) -> int:
	return ACTS[act - 1]["waves"].size()


static func is_stage_id(id: String) -> bool:
	var parts := id.split("-")
	if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
		return false
	var act := parts[0].to_int()
	var stage := parts[1].to_int()
	return act >= 1 and act <= ACTS.size() and stage >= 1 and stage <= stage_count(act) and id == stage_id(act, stage)


## Every stage id of acts 1..through_act, in play order.
static func all_stage_ids(through_act: int) -> Array[String]:
	var ids: Array[String] = []
	for act in mini(through_act, ACTS.size()):
		for stage in stage_count(act + 1):
			ids.append(stage_id(act + 1, stage + 1))
	return ids


## An act is cleared when its last stage is.
static func act_cleared(act: int, cleared: Array[String]) -> bool:
	return stage_id(act, stage_count(act)) in cleared


## Acts cleared in a row from Act 1.
static func acts_cleared(cleared: Array[String]) -> int:
	var count := 0
	while count < ACTS.size() and act_cleared(count + 1, cleared):
		count += 1
	return count


static func is_act_open(act: int, cleared: Array[String]) -> bool:
	return act <= acts_cleared(cleared) + 1


## A stage opens once the one before it in its act is cleared; the first
## stage opens with its act.
static func is_stage_open(act: int, stage: int, cleared: Array[String]) -> bool:
	if not is_act_open(act, cleared):
		return false
	return stage <= 1 or stage_id(act, stage - 1) in cleared


## The stage after `stage` of `act`: the next in the act, else the first of
## the next act, as Vector2i(act, stage). Vector2i.ZERO when it is the last
## stage of the last act.
static func next_stage(act: int, stage: int) -> Vector2i:
	if stage < stage_count(act):
		return Vector2i(act, stage + 1)
	if act < ACTS.size():
		return Vector2i(act + 1, 1)
	return Vector2i.ZERO


static func is_endless_open(cleared: Array[String]) -> bool:
	return acts_cleared(cleared) >= ENDLESS_ACT


## &"boss" for the last stage of an act, &"mini_boss" for the listed ones,
## else &"".
static func boss_kind(act: int, stage: int) -> StringName:
	if stage == stage_count(act):
		return &"boss"
	if stage in ACTS[act - 1]["mini_bosses"]:
		return &"mini_boss"
	return &""


static func waves(act: int, stage: int) -> int:
	return ACTS[act - 1]["waves"][stage - 1]

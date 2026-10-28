class_name ChampionProgress
extends RefCounted
## In-stage level, XP and skill ranks. Skill points are derived (level minus
## spent ranks), so they can never drift out of sync.

signal level_changed(level: int)
signal xp_changed(xp_into_level: int, xp_for_next: int)
signal skill_points_changed(points: int)
signal rank_changed(slot: Slot, rank: int)

enum Slot { Q, W, E, R }

const MAX_LEVEL := 18
const MAX_RANKS := [5, 5, 5, 3]
const R_LEVELS := [6, 11, 16]

var level := 1
## XP gained inside the current level.
var xp := 0
var ranks: Array[int] = [0, 0, 0, 0]
## Highest rank bought in the Evolution Tree. Phase 1: everything is bought.
var bought: Array[int] = [5, 5, 5, 3]


static func xp_to_next(from_level: int) -> int:
	return 180 + 100 * from_level


static func required_level(slot: Slot, rank: int) -> int:
	if slot == Slot.R:
		return R_LEVELS[rank - 1]
	return 2 * rank - 1


func skill_points() -> int:
	var spent := 0
	for rank in ranks:
		spent += rank
	return level - spent


func xp_for_next() -> int:
	return 0 if level >= MAX_LEVEL else xp_to_next(level)


func can_rank_up(slot: Slot) -> bool:
	var next := ranks[slot] + 1
	return (
		skill_points() > 0
		and next <= mini(MAX_RANKS[slot], bought[slot])
		and level >= required_level(slot, next)
	)


## The next rank of `slot` is bought in the Evolution Tree.
func next_rank_bought(slot: Slot) -> bool:
	return ranks[slot] < mini(MAX_RANKS[slot], bought[slot])


func is_maxed(slot: Slot) -> bool:
	return ranks[slot] >= MAX_RANKS[slot]


func rank_up(slot: Slot) -> bool:
	if not can_rank_up(slot):
		return false
	ranks[slot] += 1
	rank_changed.emit(slot, ranks[slot])
	skill_points_changed.emit(skill_points())
	return true


func add_xp(amount: int) -> void:
	if level >= MAX_LEVEL:
		return
	xp += amount
	var start_level := level
	while level < MAX_LEVEL and xp >= xp_to_next(level):
		xp -= xp_to_next(level)
		level += 1
	if level >= MAX_LEVEL:
		xp = 0
	if level != start_level:
		level_changed.emit(level)
		skill_points_changed.emit(skill_points())
	xp_changed.emit(xp, xp_for_next())


## Debug only. Keeps the current ranks if they are still legal at the new
## level, otherwise refunds all of them.
func set_level(new_level: int) -> void:
	level = clampi(new_level, 1, MAX_LEVEL)
	xp = 0
	if not _ranks_legal():
		_clear_ranks()
	level_changed.emit(level)
	skill_points_changed.emit(skill_points())
	xp_changed.emit(xp, xp_for_next())


func reset_ranks() -> void:
	_clear_ranks()
	skill_points_changed.emit(skill_points())


func _ranks_legal() -> bool:
	if skill_points() < 0:
		return false
	for slot in ranks.size():
		if ranks[slot] > 0 and level < required_level(slot, ranks[slot]):
			return false
	return true


func _clear_ranks() -> void:
	for slot in ranks.size():
		if ranks[slot] != 0:
			ranks[slot] = 0
			rank_changed.emit(slot, 0)

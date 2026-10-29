class_name Enemy
extends CharacterBody2D
## Anything Lucian can attack: resists, damage intake, skill marks, statuses
## from items (armor shred, Grievous Wounds, MR shred), slows and burns. An
## untargetable enemy (Sky Dive) is out of every hitbox and takes no damage.

signal damage_taken(info: DamageInfo, final_amount: float)
## The enemy died (once). Lucian's kill hooks run from it too.
signal died(enemy: Enemy)

const MARK_RING_COLOR := Color(1.0, 0.55, 0.15, 0.85)
## Statuses with a combat effect. SLOW and BURN are kept by add_slow and
## add_burn, for the health bar.
const CARVE := &"carve"
const GRIEVOUS_WOUNDS := &"grievous_wounds"
const SLOW := &"slow"
const BURN := &"burn"
const HATEFOG := &"hatefog"
const SLOW_ICON := preload("res://assets/art/ui/debuff_slow.svg")
const BURN_ICON := preload("res://assets/art/ui/status_burn.svg")
## Armor lost per Carve stack, and magic resist lost in Hatefog.
const CARVE_ARMOR_SHRED := 0.05
const HATEFOG_MR_SHRED := 10.0
## Healing taken under Grievous Wounds.
const GRIEVOUS_HEALING := 0.6
## Seconds a dead enemy fades before it is freed.
const DEATH_FADE := 0.4

@export var max_hp := 100.0
@export var armor := 0.0
@export var mr := 0.0
## Used for clicking on the enemy and for attack range.
@export var radius := 40.0

var hp := 0.0
## The HP the last hit really took: its final amount, capped at the HP left
## (set before damage_taken is emitted).
var hp_lost := 0.0
var dead := false
## Out of the enemies group and every hitbox, and takes no damage (see
## set_untargetable). Still alive.
var untargetable := false
## Whoever hit this enemy last: the kill is theirs.
var last_attacker: Node
## Mark id -> seconds left.
var _marks := {}
## Status id -> {stacks, left, duration, icon}.
var _statuses := {}
## Slow id -> {pct, left}. The strongest one counts.
var _slows := {}
var _burns := DamageOverTime.new()
## The body's and each hurtbox's layer from before going untargetable.
var _layers := {}


func _ready() -> void:
	hp = max_hp
	add_to_group(&"enemies")


func is_alive() -> bool:
	return not dead


## The attacker may scale the hit first (before_damage), then armor or magic
## resist, after any shred, lowers it. A dead or untargetable enemy takes
## nothing. A burn tick (`over_time`) makes no sound and no flash. It dies
## after the attacker's on-hit effects, so they still see the target.
func take_damage(info: DamageInfo) -> float:
	if dead or untargetable:
		return 0.0
	var attacker: Node = info.attacker if is_instance_valid(info.attacker) else null
	if attacker and attacker.has_method(&"before_damage"):
		attacker.before_damage(self, info)
	var final_amount := DamageCalc.mitigate(info.amount, info.type, effective_armor(), effective_mr(), info.armor_pen, info.magic_pen)
	if attacker:
		last_attacker = attacker
	var hp_before := hp
	_lose_hp(final_amount)
	hp_lost = hp_before - hp
	if not info.over_time:
		Sfx.play(&"hit", -12.0)
		_show_hit()
	damage_taken.emit(info, final_amount)
	if attacker and attacker.has_method(&"on_damage_dealt"):
		attacker.on_damage_dealt(self, info, final_amount)
	if hp <= 0.0:
		_die()
	return final_amount


## Sky Dive and the like: the enemy leaves the enemies group, its body's
## layer and every hurtbox's, so attacks, homing shots, clicks, Senna and
## the radar drop it, and it takes no damage. Turning it off puts the old
## layers back. Does nothing on a dead or escaped enemy: it never comes back.
func set_untargetable(on: bool) -> void:
	if not is_alive() or on == untargetable:
		return
	untargetable = on
	if on:
		remove_from_group(&"enemies")
		_layers = {self: collision_layer}
		collision_layer = 0
		for child in get_children():
			if child is Hurtbox:
				_layers[child] = (child as Hurtbox).collision_layer
				(child as Hurtbox).collision_layer = 0
	else:
		add_to_group(&"enemies")
		for node: Variant in _layers:
			if is_instance_valid(node):
				(node as CollisionObject2D).collision_layer = _layers[node]
		_layers.clear()


## A slow of `pct` (0.3 = 30%) for `seconds`. The same id replaces the old
## one; the strongest slow counts. Shown over the health bar as SLOW.
func add_slow(id: StringName, pct: float, seconds: float, icon: Texture2D = SLOW_ICON) -> void:
	if dead:
		return
	_slows[id] = {"pct": pct, "left": seconds}
	var longest := 0.0
	for slow: Dictionary in _slows.values():
		longest = maxf(longest, slow.left)
	_set_status(SLOW, longest, icon)


## The strongest slow on this enemy, 0 when none.
func slow_amount() -> float:
	var strongest := 0.0
	for slow: Dictionary in _slows.values():
		strongest = maxf(strongest, slow.pct)
	return strongest


## A burn of `dps` damage of `type` per second for `seconds`, ticking every
## 0.5 s through take_damage and credited to `attacker`. The same id
## refreshes. Shown over the health bar as BURN.
func add_burn(id: StringName, dps: float, seconds: float, type: DamageInfo.Type, attacker: Node = null, icon: Texture2D = BURN_ICON) -> void:
	if dead:
		return
	_burns.add(id, dps, seconds, type, attacker)
	_set_status(BURN, _burns.time_left(_burns.longest()), icon)


## Once: out of the enemies group and every hitbox, the kill credit, then a
## short fade before the node goes. Its slows and burns end.
func _die() -> void:
	if dead:
		return
	dead = true
	_leave_fight()
	died.emit(self)
	if is_instance_valid(last_attacker) and last_attacker.has_method(&"on_kill"):
		last_attacker.on_kill(self)
	_fade_out()


## For good: out of the enemies group and every hitbox; its slows and burns end.
func _leave_fight() -> void:
	remove_from_group(&"enemies")
	collision_layer = 0
	for child in get_children():
		if child is Hurtbox:
			(child as Hurtbox).collision_layer = 0
	_slows.clear()
	_burns.clear()
	_statuses.erase(SLOW)
	_statuses.erase(BURN)


## A short fade, then the node goes.
func _fade_out() -> void:
	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, DEATH_FADE)
	fade.tween_callback(queue_free)


## Armor after Carve: each stack removes 5% of it (only positive armor).
func effective_armor() -> float:
	if armor <= 0.0:
		return armor
	return armor * (1.0 - CARVE_ARMOR_SHRED * status_stacks(CARVE))


func effective_mr() -> float:
	return mr - (HATEFOG_MR_SHRED if has_status(HATEFOG) else 0.0)


## Healing this enemy receives, after Grievous Wounds.
func heal(amount: float) -> void:
	hp = minf(hp + amount * (GRIEVOUS_HEALING if has_status(GRIEVOUS_WOUNDS) else 1.0), max_hp)


func add_mark(id: StringName, duration: float) -> void:
	_marks[id] = duration
	queue_redraw()


func has_mark(id: StringName) -> bool:
	return _marks.has(id)


## Adds a stack (up to `max_stacks`) and refreshes the duration. `icon` is
## shown over the health bar.
func add_status(id: StringName, duration: float, max_stacks := 1, icon: Texture2D = null) -> void:
	var status: Dictionary = _statuses.get(id, {"stacks": 0})
	status.stacks = mini(status.stacks + 1, max_stacks)
	status.left = duration
	status.duration = duration
	status.icon = icon
	_statuses[id] = status


func has_status(id: StringName) -> bool:
	return _statuses.has(id)


func status_stacks(id: StringName) -> int:
	return _statuses[id].stacks if _statuses.has(id) else 0


## Every status as {id, stacks, left, duration, icon}, for the health bar.
func statuses() -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for id: StringName in _statuses:
		var status: Dictionary = _statuses[id].duplicate()
		status.id = id
		found.append(status)
	return found


func _lose_hp(amount: float) -> void:
	hp = maxf(hp - amount, 0.0)


## A hit landed (not a burn tick): subclasses flash.
func _show_hit() -> void:
	pass


## Shows status `id` (one stack) for `seconds`, the longest slow or burn.
func _set_status(id: StringName, seconds: float, icon: Texture2D) -> void:
	_statuses[id] = {"stacks": 1, "left": seconds, "duration": seconds, "icon": icon}


func _physics_process(delta: float) -> void:
	for id in _marks.keys():
		_marks[id] -= delta
		if _marks[id] <= 0.0:
			_marks.erase(id)
			queue_redraw()
	for id in _statuses.keys():
		_statuses[id].left -= delta
		if _statuses[id].left <= 0.0:
			_statuses.erase(id)
	for id in _slows.keys():
		_slows[id].left -= delta
		if _slows[id].left <= 0.0:
			_slows.erase(id)
	if not _burns.is_empty():
		for hit in _burns.tick(delta):
			if dead:
				break
			take_damage(hit)


func _draw() -> void:
	if not _marks.is_empty():
		draw_arc(Vector2.ZERO, radius + 14.0, 0.0, TAU, 48, MARK_RING_COLOR, 4.0, true)

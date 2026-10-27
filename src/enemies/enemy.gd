class_name Enemy
extends CharacterBody2D
## Anything Lucian can attack: resists, damage intake, skill marks and
## statuses from items (armor shred, Grievous Wounds, slow, MR shred).

signal damage_taken(info: DamageInfo, final_amount: float)

const MARK_RING_COLOR := Color(1.0, 0.55, 0.15, 0.85)
## Statuses with a combat effect.
const CARVE := &"carve"
const GRIEVOUS_WOUNDS := &"grievous_wounds"
const SLOW := &"slow"
const HATEFOG := &"hatefog"
## Armor lost per Carve stack, and magic resist lost in Hatefog.
const CARVE_ARMOR_SHRED := 0.05
const HATEFOG_MR_SHRED := 10.0
## Healing taken under Grievous Wounds.
const GRIEVOUS_HEALING := 0.6

@export var max_hp := 100.0
@export var armor := 0.0
@export var mr := 0.0
## Used for clicking on the enemy and for attack range.
@export var radius := 40.0

var hp := 0.0
## Mark id -> seconds left.
var _marks := {}
## Status id -> {stacks, left, duration, icon}.
var _statuses := {}


func _ready() -> void:
	hp = max_hp
	add_to_group(&"enemies")


## The attacker may scale the hit first (before_damage), then armor or magic
## resist, after any shred, lowers it.
func take_damage(info: DamageInfo) -> float:
	var attacker: Node = info.attacker if is_instance_valid(info.attacker) else null
	if attacker and attacker.has_method(&"before_damage"):
		attacker.before_damage(self, info)
	var final_amount := DamageCalc.mitigate(info.amount, info.type, effective_armor(), effective_mr(), info.armor_pen, info.magic_pen)
	_lose_hp(final_amount)
	Sfx.play(&"hit", -12.0)
	damage_taken.emit(info, final_amount)
	if attacker and attacker.has_method(&"on_damage_dealt"):
		attacker.on_damage_dealt(self, info, final_amount)
	return final_amount


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


func _draw() -> void:
	if not _marks.is_empty():
		draw_arc(Vector2.ZERO, radius + 14.0, 0.0, TAU, 48, MARK_RING_COLOR, 4.0, true)

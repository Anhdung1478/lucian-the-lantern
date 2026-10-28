class_name LucianController
extends Node
## Turns player input into Lucian commands. Uses _unhandled_input so clicks
## that land on the HUD or the debug table never reach the world.

## Holding move re-issues the order once the cursor has moved this far.
const REISSUE_DISTANCE := 8.0
## Extra slack around an enemy's radius when clicking on it.
const CLICK_SLACK := 10.0
const ITEM_ACTIONS: Array[StringName] = [&"item_1", &"item_2", &"item_3", &"item_4", &"item_5", &"item_6"]
const SUMMONER_ACTIONS: Array[StringName] = [&"summoner_d", &"summoner_f"]
const SKILL_ACTIONS := {
	&"skill_q": ChampionProgress.Slot.Q,
	&"skill_w": ChampionProgress.Slot.W,
	&"skill_e": ChampionProgress.Slot.E,
	&"skill_r": ChampionProgress.Slot.R,
}

var _move_held := false
var _last_move_point := Vector2.ZERO
var _attack_move_armed := false

@onready var lucian: Lucian = get_parent()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		# A focused debug SpinBox would otherwise keep eating Q/W/E/R.
		get_viewport().gui_release_focus()
	for action: StringName in SKILL_ACTIONS:
		if event.is_action_pressed(action):
			# Ctrl+Q also matches skill_q, so the rank-up check comes first.
			if (event as InputEventWithModifiers).ctrl_pressed:
				lucian.try_rank_up(SKILL_ACTIONS[action])
			else:
				lucian.try_cast(SKILL_ACTIONS[action], _cursor())
			get_viewport().set_input_as_handled()
			return
	for slot in ITEM_ACTIONS.size():
		if event.is_action_pressed(ITEM_ACTIONS[slot]):
			lucian.use_equip_slot(slot, _cursor())
			get_viewport().set_input_as_handled()
			return
	for slot in SUMMONER_ACTIONS.size():
		if event.is_action_pressed(SUMMONER_ACTIONS[slot]):
			lucian.use_summoner(slot, _cursor())
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed(&"move"):
		_set_attack_move_armed(false)
		var merchant := _merchant_under_cursor()
		if merchant:
			lucian.command_visit(merchant)
		else:
			_move_held = true
			_issue_move()
	elif event.is_action_pressed(&"attack_move"):
		_set_attack_move_armed(true)
	elif event.is_action_pressed(&"attack"):
		if _attack_move_armed:
			lucian.command_attack_move(_cursor())
			_set_attack_move_armed(false)
		else:
			var enemy := _enemy_under_cursor()
			if enemy:
				lucian.command_attack(enemy)
	else:
		return
	get_viewport().set_input_as_handled()


## A pause screen opening drops the held move and the armed attack-move.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
		_move_held = false
		_set_attack_move_armed(false)


func _physics_process(_delta: float) -> void:
	if not _move_held:
		return
	# Polled so a release eaten by the GUI still ends the hold.
	if not Input.is_action_pressed(&"move"):
		_move_held = false
	elif _cursor().distance_to(_last_move_point) > REISSUE_DISTANCE:
		_issue_move()


func _issue_move() -> void:
	_last_move_point = _cursor()
	lucian.command_move(_last_move_point)


func _set_attack_move_armed(armed: bool) -> void:
	_attack_move_armed = armed
	lucian.set_range_ring_visible(armed)
	Input.set_default_cursor_shape(Input.CURSOR_CROSS if armed else Input.CURSOR_ARROW)


func _enemy_under_cursor() -> Enemy:
	var cursor := _cursor()
	var best: Enemy = null
	var best_distance := INF
	for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
		var distance := cursor.distance_to(enemy.global_position)
		if distance <= enemy.radius + CLICK_SLACK and distance < best_distance:
			best = enemy
			best_distance = distance
	return best


func _merchant_under_cursor() -> Merchant:
	for merchant: Merchant in get_tree().get_nodes_in_group(&"merchants"):
		if merchant.is_under(_cursor()):
			return merchant
	return null


func _cursor() -> Vector2:
	return lucian.get_global_mouse_position()

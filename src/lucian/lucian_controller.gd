class_name LucianController
extends Node
## Turns player input into Lucian commands. Uses _unhandled_input so clicks
## that land on the HUD or the debug table never reach the world.
##
## Skill, item and summoner keys cast by their cast mode (a setting per key):
## quick cast fires on press; quick cast with indicator shows the range while
## the key is held and fires on release; normal cast shows it on press and
## fires on left-click. Right-click or ESC cancels an aim. Casts with no aim,
## or not ready, always fire on press.

## Holding move re-issues the order once the cursor has moved this far.
const REISSUE_DISTANCE := 8.0
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
## The key whose cast is being aimed (&"" when none), and its cast mode.
var _aiming: StringName = &""
var _aim_mode := ""

@onready var lucian: Lucian = get_parent()


func _ready() -> void:
	# A right-click held from before a dash or Flash stops steering Lucian; a
	# new click (during the dash or after it) walks on.
	lucian.move_dropped.connect(func() -> void: _move_held = false)


func _unhandled_input(event: InputEvent) -> void:
	if not lucian.can_act():
		return
	if event is InputEventMouseButton and event.pressed:
		# A focused debug SpinBox would otherwise keep eating Q/W/E/R.
		get_viewport().gui_release_focus()
	if _aiming != &"" and _aim_input(event):
		get_viewport().set_input_as_handled()
		return
	for action in GameSettings.CASTABLE:
		if event.is_action_pressed(action):
			# Ctrl+Q also matches skill_q, so the rank-up check comes first.
			var with_ctrl := event is InputEventWithModifiers and (event as InputEventWithModifiers).ctrl_pressed
			if SKILL_ACTIONS.has(action) and with_ctrl:
				lucian.try_rank_up(SKILL_ACTIONS[action])
			else:
				_press_cast(action)
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
		cancel_aim()
		_set_attack_move_armed(true)
	elif event.is_action_pressed(&"attack"):
		if _attack_move_armed:
			lucian.command_attack_move(_cursor())
			_set_attack_move_armed(false)
		else:
			var enemy := lucian.enemy_at(_cursor())
			if enemy:
				lucian.command_attack(enemy)
	else:
		return
	get_viewport().set_input_as_handled()


## A pause screen opening drops the held move, the armed attack-move and the
## cast being aimed.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
		_move_held = false
		_set_attack_move_armed(false)
		cancel_aim()


## The key whose cast is being aimed, or &"".
func aiming() -> StringName:
	return _aiming


## Drops the cast being aimed. False when there was none (ESC then opens the
## menu instead).
func cancel_aim() -> bool:
	if _aiming == &"":
		return false
	_aiming = &""
	lucian.indicator.aimed = null
	return true


func _process(_delta: float) -> void:
	if _aiming == &"":
		return
	# Quick cast with indicator fires once the key is let go.
	if _aim_mode == "indicator" and not Input.is_action_pressed(_aiming):
		_fire_aim()
		return
	lucian.indicator.aim_point = _cursor()


## A cast key pressed: fired now, or aimed first by its cast mode.
func _press_cast(action: StringName) -> void:
	cancel_aim()
	var mode := GameSettings.instance().cast_mode(action)
	var shape := _range_of(action)
	if mode == "quick" or shape == null or not _ready_to_cast(action):
		_cast(action, _cursor())
		return
	_set_attack_move_armed(false)
	_aiming = action
	_aim_mode = mode
	lucian.indicator.aimed = shape
	lucian.indicator.aim_point = _cursor()


## While aiming: right-click cancels (without moving). Left-click fires in
## normal cast and does nothing while a quick cast with indicator is held.
## Another cast key takes over the aim (the caller handles it). True when the
## event was used.
func _aim_input(event: InputEvent) -> bool:
	if event.is_action_pressed(&"move"):
		cancel_aim()
		return true
	if event.is_action_pressed(&"attack"):
		if _aim_mode == "normal":
			_fire_aim()
		return true
	return false


func _fire_aim() -> void:
	var action := _aiming
	cancel_aim()
	_cast(action, _cursor())


func _cast(action: StringName, aim: Vector2) -> void:
	if SKILL_ACTIONS.has(action):
		lucian.try_cast(SKILL_ACTIONS[action], aim)
	elif ITEM_ACTIONS.has(action):
		lucian.use_equip_slot(ITEM_ACTIONS.find(action), aim)
	else:
		lucian.use_summoner(SUMMONER_ACTIONS.find(action), aim)


## The range indicator's shape for the cast on `action`, or null without aim.
func _range_of(action: StringName) -> CastRange:
	if SKILL_ACTIONS.has(action):
		return lucian.skill_range(SKILL_ACTIONS[action])
	if ITEM_ACTIONS.has(action):
		return lucian.equip_range(ITEM_ACTIONS.find(action))
	return lucian.summoner_range(SUMMONER_ACTIONS.find(action))


## Off cooldown (and with the mana, for skills), so aiming it can end in a cast.
func _ready_to_cast(action: StringName) -> bool:
	if SKILL_ACTIONS.has(action):
		return lucian.can_cast(SKILL_ACTIONS[action])
	if ITEM_ACTIONS.has(action):
		var item := lucian.inventory.item_at(Inventory.EQUIP_START + ITEM_ACTIONS.find(action))
		return lucian.item_cooldown(item.id).is_ready()
	return lucian.summoners.cooldown(lucian.summoners.spell_in(SUMMONER_ACTIONS.find(action)).id).is_ready()


func _physics_process(_delta: float) -> void:
	if not lucian.can_act():
		_move_held = false
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


func _merchant_under_cursor() -> Merchant:
	for merchant: Merchant in get_tree().get_nodes_in_group(&"merchants"):
		if merchant.is_under(_cursor()):
			return merchant
	return null


func _cursor() -> Vector2:
	return lucian.get_global_mouse_position()

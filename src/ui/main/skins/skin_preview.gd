class_name SkinPreview
extends Control
## The Skin Shop's preview of one skin's effects: Lucian in that skin and a
## training dummy on a stage floor. Q, W, E, R and basic attacks play with
## the skin's SkinFx at game size and with its sounds. ▶ All loops them and
## starts on opening; a skill's button plays only that one. It deals no
## damage and saves nothing. It stands still while covered (set_covered). ✕ or ESC (SkinShop.close_popup) closes it and
## frees everything it spawned. It is the shop's other pop-up, so it looks
## like one: the menus' blurred, dimmed MenuBackdrop and an ornate Plate,
## opening and closing with UiMotion's overlay motion (`closed` at once).

signal closed

const PANEL_SIZE := Vector2(1200, 680)
## The plate's padding, as the old panel's.
const PANEL_PAD := 24.0
const STAGE_SIZE := Vector2(1140, 500)
const LUCIAN_AT := Vector2(220, 250)
const DUMMY_AT := Vector2(920, 250)
## The gun muzzles of lucian.tscn, facing right: his own gun, then Senna's.
const MUZZLES: Array[Vector2] = [Vector2(46, -15), Vector2(46, 15)]
## Rank 1 numbers, as in the skills (a test keeps them equal).
const Q_CAST := 0.3
const Q_WIDTH := 60.0
const W_CAST := 0.2
const W_SPEED := 1600.0
const W_BAR := Vector2(400, 60)
const E_DISTANCE := 280.0
const E_SPEED := 1350.0
const R_SHOTS := 22
const R_DURATION := 3.0
const R_SPEED := 2800.0
const ATTACK_SHOTS := 3
const ATTACK_GAP := 0.4
## Seconds after a piece before the next one in ▶ All.
const GAP := 0.6
## Seconds Lucian takes to walk back after E.
const WALK_BACK := 0.8
## ▶ All's order; each piece has a button.
const PIECES: Array[StringName] = [&"q", &"w", &"e", &"r", &"attack"]
const LABELS := {&"q": "Q", &"w": "W", &"e": "E", &"r": "R", &"attack": "Attack", &"all": "▶ All"}
const DUMMY_ART := preload("res://assets/art/enemies/training_dummy.svg")
const FLOOR := Color(0.08, 0.09, 0.12)
const TILE_LINE := Color(0.13, 0.15, 0.19)
const TILE := 80.0

var skin: SkinData
## Piece id (and &"all") → its button.
var buttons := {}
var close_button := Button.new()
## The floor, clipped to STAGE_SIZE. Lucian, the dummy and the effects stand on it.
var stage := Control.new()
var lucian := Sprite2D.new()
var dummy := Sprite2D.new()
var effects := Node2D.new()

var _fx: SkinFx
var _tween: Tween
var _gun := 0
var _trail: DashTrail
var _backdrop := MenuBackdrop.new()
var _center := CenterContainer.new()
var _closing := false
var _lucian_motion: UnitMotion
var _dummy_motion: UnitMotion
var _dummy_flash: Tween


func _init(skin_data: SkinData = null) -> void:
	skin = skin_data
	_fx = skin.fx if skin and skin.fx else SkinFx.new()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	play_all()
	UiMotion.open_overlay(_backdrop, _center)


## Plays one piece (&"q", &"w", &"e", &"r" or &"attack"), stopping ▶ All.
func play(piece: StringName) -> void:
	_stop()
	_tween = create_tween()
	_queue(piece)


## Plays every piece in turn, with a gap, over and over.
func play_all() -> void:
	_stop()
	_tween = create_tween().set_loops()
	for piece in PIECES:
		_queue(piece)
		_tween.tween_interval(GAP)


## True while the gear menu, Settings or a pop-up covers the preview: it
## freezes (the loop, the shots and their effects stand still) and plays on
## from the same spot when uncovered.
func set_covered(on: bool) -> void:
	process_mode = Node.PROCESS_MODE_DISABLED if on else Node.PROCESS_MODE_INHERIT


## Closes the preview (at once for the shop) and frees everything it
## spawned once it has faded.
func close() -> void:
	if _closing or is_queued_for_deletion():
		return
	_closing = true
	_stop()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	closed.emit()
	UiMotion.close_overlay(_backdrop, _center, queue_free)


## True from close() on, while it fades.
func is_closing() -> bool:
	return _closing


func _process(_delta: float) -> void:
	if is_instance_valid(_trail):
		_trail.reach(lucian.position)


func _queue(piece: StringName) -> void:
	match piece:
		&"q":
			_tween.tween_callback(_brace.bind(Q_CAST))
			_tween.tween_interval(Q_CAST)
			_tween.tween_callback(_fire_q)
			_tween.tween_interval(LaserBeam.LIFETIME)
		&"w":
			_tween.tween_callback(_brace.bind(W_CAST))
			_tween.tween_interval(W_CAST)
			_tween.tween_callback(_fire_w)
			_tween.tween_interval((DUMMY_AT.x - LUCIAN_AT.x - Lucian.GUN_REACH) / W_SPEED + CrossBlast.LIFETIME)
		&"e":
			var landing := LUCIAN_AT + Vector2(E_DISTANCE, 0)
			_tween.tween_callback(_start_dash)
			_tween.tween_property(lucian, "position", landing, E_DISTANCE / E_SPEED).from(LUCIAN_AT)
			_tween.tween_callback(_end_dash)
			_tween.tween_interval(DashTrail.LIFETIME)
			_tween.tween_property(lucian, "position", LUCIAN_AT, WALK_BACK).from(landing)
		&"r":
			for i in R_SHOTS:
				_tween.tween_callback(_shoot.bind(_fx.r_bullet_look, R_SPEED, true))
				_tween.tween_interval(R_DURATION / R_SHOTS)
		&"attack":
			for i in ATTACK_SHOTS:
				_tween.tween_callback(_shoot.bind(_fx.attack_shot_look, AttackProjectile.SPEED, false))
				_tween.tween_interval(ATTACK_GAP)


func _brace(seconds: float) -> void:
	if _lucian_motion:
		_lucian_motion.brace(seconds)


func _fire_q() -> void:
	var from := LUCIAN_AT + Vector2(Lucian.GUN_REACH, 0)
	effects.add_child(_fx.q_beam(from, Vector2.RIGHT, DUMMY_AT.x - from.x, Q_WIDTH))
	if _lucian_motion:
		_lucian_motion.recoil(1.35)
	_hit_dummy(DUMMY_AT + Vector2(-20.0, 0.0), _spark_color(&"q"), true)
	Sfx.play(_fx.q_sound)


func _fire_w() -> void:
	var from := LUCIAN_AT + Vector2(Lucian.GUN_REACH, 0)
	var missile := LinearProjectile.new()
	missile.launch(from, Vector2.RIGHT, W_SPEED, DUMMY_AT.x - from.x, 16.0)
	missile.set_look(_fx.w_missile_look())
	missile.finished.connect(_burst, CONNECT_DEFERRED)
	effects.add_child(missile)
	if _lucian_motion:
		_lucian_motion.recoil(1.15)
	Sfx.play(_fx.w_sound)


## W's cross where the missile ended (`at` is a global position).
func _burst(at: Vector2) -> void:
	var local := effects.to_local(at)
	effects.add_child(_fx.w_blast(local, Vector2.RIGHT, W_BAR))
	_hit_dummy(local, _spark_color(&"w"), true)


func _start_dash() -> void:
	Sfx.play(_fx.e_sound)
	if _lucian_motion:
		_lucian_motion.dash_stretch(E_DISTANCE / E_SPEED)
	if GameSettings.instance().low_effects():
		return
	_trail = _fx.e_trail(skin.body)
	_trail.setup(LUCIAN_AT, DashTrail.LIGHT)
	effects.add_child(_trail)


func _end_dash() -> void:
	if is_instance_valid(_trail):
		_trail.reach(lucian.position)
		_trail.finish()
	_trail = null


## A shot from the next gun to the dummy, with its muzzle flash, recoil and sound.
func _shoot(make_look: Callable, speed: float, from_r := false) -> void:
	var gun := _gun
	var from := LUCIAN_AT + MUZZLES[gun]
	_gun = 1 - _gun
	var shot := LinearProjectile.new()
	shot.launch(from, Vector2.RIGHT, speed, DUMMY_AT.x - from.x, 10.0)
	shot.set_look(make_look.call())
	shot.finished.connect(_on_shot_hit.bind(_spark_color(&"r" if from_r else &"attack")), CONNECT_DEFERRED)
	effects.add_child(shot)
	if _lucian_motion:
		_lucian_motion.recoil_side(-1.0 if gun == 0 else 1.0)
	Sfx.play(_fx.shot_sound, -6.0)
	if not GameSettings.instance().low_effects():
		var flash := _fx.muzzle_flash()
		flash.position = from
		effects.add_child(flash)


func _on_shot_hit(at: Vector2, spark_color: Color) -> void:
	_hit_dummy(effects.to_local(at), spark_color, false)


func _hit_dummy(at: Vector2, spark_color: Color, big: bool) -> void:
	if _closing or not is_instance_valid(dummy):
		return
	if _dummy_motion:
		_dummy_motion.flinch()
		_dummy_motion.recoil(-0.55 if big else -0.3)
	if Juice.on():
		HitSpark.spawn(effects, at, spark_color, big)
		dummy.modulate = EnemyUnit.HIT_FLASH
		if _dummy_flash:
			_dummy_flash.kill()
		_dummy_flash = create_tween()
		_dummy_flash.tween_property(dummy, "modulate", Color.WHITE, 0.14)


func _spark_color(piece: StringName) -> Color:
	var id := skin.id if skin else &"classic"
	match id:
		&"high_noon":
			return Color("ffae52")
		&"vampire":
			return Color("ff5c77")
		&"pulsefire":
			return Color("78e6ff")
		&"project":
			return Color("ff7838")
	return Color("8cc8ff") if piece == &"w" else Color("ffe8a0")


## Stops what is playing and puts Lucian back. Effects already out finish
## on their own.
func _stop() -> void:
	if _tween:
		_tween.kill()
	_tween = null
	if _dummy_flash:
		_dummy_flash.kill()
	_dummy_flash = null
	dummy.modulate = Color.WHITE
	_end_dash()
	lucian.position = LUCIAN_AT
	if _lucian_motion:
		_lucian_motion.reset()
	if _dummy_motion:
		_dummy_motion.reset()


func _build() -> void:
	# Clicks outside the panel stop here.
	mouse_filter = Control.MOUSE_FILTER_STOP
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_backdrop)
	_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop.add_child(_center)
	var panel := Plate.new(PANEL_PAD)
	panel.custom_minimum_size = PANEL_SIZE
	_center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 14)
	panel.add_child(column)

	var header := HBoxContainer.new()
	column.add_child(header)
	var title := UiStyle.label(Lang.t("%s · Preview") % Lang.t(skin.display_name), 26, UiStyle.TITLE_COLOR)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	close_button.text = "✕"
	UiStyle.style_button(close_button, 22)
	close_button.custom_minimum_size = Vector2(48, 48)
	close_button.pressed.connect(close)
	header.add_child(close_button)

	stage.custom_minimum_size = STAGE_SIZE
	stage.clip_contents = true
	stage.draw.connect(_draw_floor)
	column.add_child(stage)
	dummy.texture = DUMMY_ART
	dummy.position = DUMMY_AT
	stage.add_child(dummy)
	_dummy_motion = UnitMotion.new()
	_dummy_motion.setup(dummy, dummy, 30.0)
	dummy.add_child(_dummy_motion)
	lucian.texture = skin.body
	lucian.position = LUCIAN_AT
	stage.add_child(lucian)
	_lucian_motion = UnitMotion.new()
	_lucian_motion.profile = UnitMotion.Profile.BIPED
	_lucian_motion.setup(lucian, lucian, Lucian.HIT_RADIUS)
	lucian.add_child(_lucian_motion)
	stage.add_child(effects)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 14)
	column.add_child(row)
	for piece: StringName in PIECES + [&"all"]:
		var button := Button.new()
		button.text = Lang.t(LABELS[piece])
		UiStyle.style_button(button, 20)
		button.custom_minimum_size = Vector2(130, 48)
		button.pressed.connect(play_all if piece == &"all" else play.bind(piece))
		row.add_child(button)
		buttons[piece] = button


func _draw_floor() -> void:
	stage.draw_rect(Rect2(Vector2.ZERO, STAGE_SIZE), FLOOR)
	var x := TILE
	while x < STAGE_SIZE.x:
		stage.draw_line(Vector2(x, 0), Vector2(x, STAGE_SIZE.y), TILE_LINE, 1.0)
		x += TILE
	var y := TILE
	while y < STAGE_SIZE.y:
		stage.draw_line(Vector2(0, y), Vector2(STAGE_SIZE.x, y), TILE_LINE, 1.0)
		y += TILE

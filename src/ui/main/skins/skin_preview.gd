class_name SkinPreview
extends Control
## The Skin Shop's preview of one skin's effects: Lucian in that skin and a
## training dummy on a stage floor. Q, W, E, R and basic attacks play with
## the skin's SkinFx at game size and with its sounds. ▶ All loops them and
## starts on opening; a skill's button plays only that one. It deals no
## damage and saves nothing. ✕ or ESC (SkinShop.close_popup) closes it and
## frees everything it spawned.

signal closed

const PANEL_SIZE := Vector2(1200, 680)
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


func _init(skin_data: SkinData = null) -> void:
	skin = skin_data
	_fx = skin.fx if skin and skin.fx else SkinFx.new()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	play_all()


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


## Closes the preview and frees everything it spawned.
func close() -> void:
	if is_queued_for_deletion():
		return
	_stop()
	closed.emit()
	queue_free()


func _process(_delta: float) -> void:
	if is_instance_valid(_trail):
		_trail.reach(lucian.position)


func _queue(piece: StringName) -> void:
	match piece:
		&"q":
			_tween.tween_interval(Q_CAST)
			_tween.tween_callback(_fire_q)
			_tween.tween_interval(LaserBeam.LIFETIME)
		&"w":
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
				_tween.tween_callback(_shoot.bind(_fx.r_bullet_look, R_SPEED))
				_tween.tween_interval(R_DURATION / R_SHOTS)
		&"attack":
			for i in ATTACK_SHOTS:
				_tween.tween_callback(_shoot.bind(_fx.attack_shot_look, AttackProjectile.SPEED))
				_tween.tween_interval(ATTACK_GAP)


func _fire_q() -> void:
	var from := LUCIAN_AT + Vector2(Lucian.GUN_REACH, 0)
	effects.add_child(_fx.q_beam(from, Vector2.RIGHT, DUMMY_AT.x - from.x, Q_WIDTH))
	Sfx.play(_fx.q_sound)


func _fire_w() -> void:
	var from := LUCIAN_AT + Vector2(Lucian.GUN_REACH, 0)
	var missile := LinearProjectile.new()
	missile.launch(from, Vector2.RIGHT, W_SPEED, DUMMY_AT.x - from.x, 16.0)
	missile.set_look(_fx.w_missile_look())
	missile.finished.connect(_burst, CONNECT_DEFERRED)
	effects.add_child(missile)
	Sfx.play(_fx.w_sound)


## W's cross where the missile ended (`at` is a global position).
func _burst(at: Vector2) -> void:
	effects.add_child(_fx.w_blast(effects.to_local(at), Vector2.RIGHT, W_BAR))


func _start_dash() -> void:
	Sfx.play(_fx.e_sound)
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


## A shot from the next gun to the dummy, with its muzzle flash and sound.
func _shoot(make_look: Callable, speed: float) -> void:
	var from := LUCIAN_AT + MUZZLES[_gun]
	_gun = 1 - _gun
	var shot := LinearProjectile.new()
	shot.launch(from, Vector2.RIGHT, speed, DUMMY_AT.x - from.x, 10.0)
	shot.set_look(make_look.call())
	effects.add_child(shot)
	Sfx.play(_fx.shot_sound, -6.0)
	if not GameSettings.instance().low_effects():
		var flash := _fx.muzzle_flash()
		flash.position = from
		effects.add_child(flash)


## Stops what is playing and puts Lucian back. Effects already out finish
## on their own.
func _stop() -> void:
	if _tween:
		_tween.kill()
	_tween = null
	_end_dash()
	lucian.position = LUCIAN_AT


func _build() -> void:
	# Clicks outside the panel stop here.
	mouse_filter = Control.MOUSE_FILTER_STOP
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.55)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = PANEL_SIZE
	panel.add_theme_stylebox_override(&"panel", UiStyle.panel(UiStyle.PANEL_COLOR, UiStyle.BORDER_COLOR, 2, 24.0))
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 14)
	panel.add_child(column)

	var header := HBoxContainer.new()
	column.add_child(header)
	var title := UiStyle.label("%s · Preview" % skin.display_name, 26, UiStyle.TITLE_COLOR)
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
	lucian.texture = skin.body
	lucian.position = LUCIAN_AT
	stage.add_child(lucian)
	stage.add_child(effects)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 14)
	column.add_child(row)
	for piece: StringName in PIECES + [&"all"]:
		var button := Button.new()
		button.text = LABELS[piece]
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

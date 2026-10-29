class_name JourneyNode
extends Control
## One place on the Journey map (JourneyMap): a stage, the Training dummy or
## the Endless portal. A normal stage is a 56 px medallion with its id; a
## mini boss (76 px, grey ring) and a boss (100 px, red ring) show that
## enemy's art, with the id on a plate below. Its state shows: cleared (a
## gold rim and a green check), open (a soft pulse), locked (dim, a small
## lock), fogged (its act is locked: the map's fog covers it), picked (a white
## outline). A click on an open place emits `chosen`. The hover text says the
## stage and its waves, or what to clear first.

## An open place was clicked.
signal chosen

const NORMAL := &"normal"
const MINI_BOSS := &"mini_boss"
const BOSS := &"boss"
const TRAINING := &"training"
const ENDLESS := &"endless"
## The medallion's size, by kind.
const DIAMETERS := {NORMAL: 56.0, MINI_BOSS: 76.0, BOSS: 100.0, TRAINING: 72.0, ENDLESS: 112.0}
## The plate under the medallion: its width by kind (none for a normal
## stage), its height (Endless's has a second line, the best wave) and how
## far it tucks under the medallion.
const PLATE_WIDTHS := {MINI_BOSS: 52.0, BOSS: 56.0, TRAINING: 104.0, ENDLESS: 112.0}
const PLATE_HEIGHT := 24.0
const ENDLESS_PLATE_HEIGHT := 42.0
const PLATE_TUCK := 8.0
const RIM := 5.0
const ID_FONT := 18
const PLATE_FONT := 14
const BEST_FONT := 13
## Art is cropped a little closer than its frame.
const ART_ZOOM := 1.12
## An open stage's pulse: one ring every PULSE_TIME seconds, growing by
## PULSE_GROWTH.
const PULSE_TIME := 1.8
const PULSE_GROWTH := 12.0
## The Endless portal's swirl: turns per second and arms.
const PORTAL_SPIN := 0.12
const PORTAL_ARMS := 3
const PORTAL_SEGMENTS := 24

const MINI_BOSS_COLOR := Color("9aa3b2")
const BOSS_COLOR := Color("e0475a")
const CHECK_COLOR := Color("5ad07a")
const RIM_COLOR := Color("b08d57")
const CLEARED_RIM := UiStyle.GOLD_COLOR
const FACE_COLOR := Color("1d1a15")
const PLATE_COLOR := Color("15130f")
const SELECT_COLOR := Color.WHITE
const LOCKED_TINT := Color(0.58, 0.58, 0.63)
const FOGGED_TINT := Color(0.42, 0.42, 0.47)
const PORTAL_GREEN := Color("5ad0a0")
const PORTAL_PURPLE := Color("9a5cff")
const PORTAL_STONE := Color("2b2733")
const LOCK := preload("res://assets/art/ui/lock.svg")
const DUMMY_ART := preload("res://assets/art/enemies/training_dummy.svg")

## "3-4" for a stage; "" for Training and Endless.
var stage_id := ""
var act := 0
var stage := 0
var kind := NORMAL
var locked := false
## Its act is locked: it lies under the map's fog.
var fogged := false
var cleared := false
var selected := false
## The boss or mini boss (null otherwise), and the art the medallion shows.
var enemy: EnemyData
var art: Texture2D
## The stage's waves, as the old stage cards said them ("5 waves + mini boss").
var waves_text := ""
## Endless: the best wave, under the portal.
var best := 0
## The medallion's center, in the map.
var center := Vector2.ZERO

var _time := 0.0
var _hovered := false


## The place for a stage: its kind, waves and (for a boss or mini boss) its
## enemy and art.
static func for_stage(act_number: int, stage_number: int) -> JourneyNode:
	var node := JourneyNode.new()
	node.act = act_number
	node.stage = stage_number
	node.stage_id = Journey.stage_id(act_number, stage_number)
	var boss_kind := Journey.boss_kind(act_number, stage_number)
	node.kind = boss_kind if boss_kind != &"" else NORMAL
	node.waves_text = waves_line(act_number, stage_number)
	var enemy_id := WavePlan.boss(node.stage_id) if node.kind == BOSS else WavePlan.mini_boss(node.stage_id)
	if enemy_id != &"":
		node.enemy = load(Stage.ENEMY_PATH % enemy_id)
		node.art = node.enemy.art
	node._fit()
	return node


## Training (the dummy) or Endless (the portal).
static func landmark(landmark_kind: StringName) -> JourneyNode:
	var node := JourneyNode.new()
	node.kind = landmark_kind
	if landmark_kind == TRAINING:
		node.art = DUMMY_ART
	node._fit()
	return node


## A stage's waves: "2 waves", "3 waves + boss wave", "4 waves + mini boss".
static func waves_line(act_number: int, stage_number: int) -> String:
	var text := "%d waves" % Journey.waves(act_number, stage_number)
	match Journey.boss_kind(act_number, stage_number):
		&"boss":
			text += " + boss wave"
		&"mini_boss":
			# The mini boss comes last in the last wave, not in a wave of its own.
			text += " + mini boss"
	return text


func _ready() -> void:
	mouse_entered.connect(_set_hovered.bind(true))
	mouse_exited.connect(_set_hovered.bind(false))
	set_process(_animated())


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func is_stage() -> bool:
	return stage_id != ""


func diameter() -> float:
	return DIAMETERS[kind]


func radius() -> float:
	return diameter() * 0.5


## The ring: grey for a mini boss, red for a boss, gold for a cleared stage,
## bronze otherwise; the portal's purple.
func ring_color() -> Color:
	match kind:
		MINI_BOSS:
			return MINI_BOSS_COLOR
		BOSS:
			return BOSS_COLOR
		ENDLESS:
			return PORTAL_PURPLE
		NORMAL:
			return CLEARED_RIM if cleared else RIM_COLOR
	return RIM_COLOR


## Puts the medallion's center at `at` in the map.
func place(at: Vector2) -> void:
	center = at
	position = at - Vector2(size.x * 0.5, radius())


## Its state from the save: `is_locked` (not open), `is_fogged` (its act is
## locked) and `is_cleared`.
func set_state(is_locked: bool, is_fogged: bool, is_cleared: bool) -> void:
	locked = is_locked
	fogged = is_fogged
	cleared = is_cleared
	if fogged:
		modulate = FOGGED_TINT
	elif locked:
		modulate = LOCKED_TINT
	else:
		modulate = Color.WHITE
	mouse_default_cursor_shape = Control.CURSOR_ARROW if locked else Control.CURSOR_POINTING_HAND
	set_meta(&"hover_text", _hover_text())
	set_process(_animated())
	queue_redraw()


func set_selected(on: bool) -> void:
	if selected != on:
		selected = on
		queue_redraw()


## Endless: the best wave under the portal.
func set_best(waves: int) -> void:
	best = waves
	set_meta(&"hover_text", _hover_text())
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT and not locked:
		chosen.emit()
		accept_event()


## Its size: the medallion, and the plate below it.
func _fit() -> void:
	var width: float = maxf(diameter(), PLATE_WIDTHS.get(kind, 0.0))
	var height := diameter()
	if PLATE_WIDTHS.has(kind):
		height += (ENDLESS_PLATE_HEIGHT if kind == ENDLESS else PLATE_HEIGHT) - PLATE_TUCK
	size = Vector2(width, height)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _hover_text() -> String:
	match kind:
		TRAINING:
			return "Training"
		ENDLESS:
			return "Clear Act %d first" % Journey.ENDLESS_ACT if locked else "Endless\nBest wave: %d" % best
	if fogged:
		return "Clear Act %d first" % (act - 1)
	var text := "%s\n%s" % [Journey.stage_name(act, stage), waves_text]
	if locked:
		text += "\nClear %s first" % Journey.stage_id(act, stage - 1)
	return text


## Open stages pulse; an open portal swirls.
func _animated() -> bool:
	if kind == ENDLESS:
		return not locked
	return is_stage() and not locked and not cleared


func _set_hovered(on: bool) -> void:
	_hovered = on
	queue_redraw()


func _draw() -> void:
	var middle := Vector2(size.x * 0.5, radius())
	var r := radius()
	if kind == ENDLESS:
		_draw_portal(middle, r)
	else:
		_draw_medallion(middle, r)
	# The outline goes under the plate and the badges, so they stay readable.
	if selected:
		draw_arc(middle, r + 6.0, 0.0, TAU, 64, SELECT_COLOR, 3.0, true)
	elif _hovered and not locked:
		draw_arc(middle, r + 5.0, 0.0, TAU, 64, Color(1, 1, 1, 0.45), 2.0, true)
	if PLATE_WIDTHS.has(kind):
		_draw_plate(middle, r)
	if cleared:
		_draw_check(middle + Vector2(r, -r) * 0.72)
	if locked and not fogged and kind != ENDLESS:
		_draw_lock(middle + Vector2(r, r) * 0.72)


func _draw_medallion(middle: Vector2, r: float) -> void:
	var glow := JourneyMap.glow()
	if kind == BOSS:
		draw_texture_rect(glow, Rect2(middle - Vector2.ONE * r * 1.8, Vector2.ONE * r * 3.6), false, Color(BOSS_COLOR, 0.28))
	if _animated():
		var t := fmod(_time, PULSE_TIME) / PULSE_TIME
		draw_texture_rect(glow, Rect2(middle - Vector2.ONE * r * 1.7, Vector2.ONE * r * 3.4), false,
			Color(UiStyle.GOLD_COLOR, 0.16 + 0.1 * sin(_time * TAU / PULSE_TIME)))
		draw_arc(middle, r + 3.0 + PULSE_GROWTH * t, 0.0, TAU, 64, Color(UiStyle.TITLE_COLOR, 0.75 * (1.0 - t)), 2.5, true)
	draw_circle(middle + Vector2(0, 4), r + 1.0, Color(0, 0, 0, 0.55))
	var ring := ring_color()
	if cleared and kind != NORMAL:
		draw_circle(middle, r + 3.0, CLEARED_RIM)
	draw_circle(middle, r, ring.darkened(0.3))
	draw_arc(middle, r - RIM * 0.5, PI * 1.08, PI * 1.92, 24, ring.lightened(0.3), RIM * 0.6, true)
	draw_arc(middle, r - RIM * 0.5, PI * 0.12, PI * 0.88, 24, ring.darkened(0.6), RIM * 0.5, true)
	var face := r - RIM
	draw_circle(middle, face, FACE_COLOR)
	if art:
		JourneyMap.draw_round_art(self, art, middle, face - 1.0, ART_ZOOM)
	else:
		draw_circle(middle + Vector2(0, -face * 0.25), face * 0.7, FACE_COLOR.lightened(0.05))
		_draw_centered(stage_id, middle, ID_FONT, UiStyle.GOLD_COLOR if cleared else UiStyle.TITLE_COLOR)
	draw_arc(middle, face, 0.0, TAU, 48, Color(0, 0, 0, 0.65), 1.5, true)


func _draw_portal(middle: Vector2, r: float) -> void:
	var glow := JourneyMap.glow()
	var live := not locked
	draw_texture_rect(glow, Rect2(middle - Vector2.ONE * r * 2.0, Vector2.ONE * r * 4.0), false, Color(PORTAL_PURPLE, 0.32 if live else 0.1))
	draw_texture_rect(glow, Rect2(middle - Vector2.ONE * r * 1.3, Vector2.ONE * r * 2.6), false, Color(PORTAL_GREEN, 0.22 if live else 0.06))
	draw_circle(middle + Vector2(0, 5), r, Color(0, 0, 0, 0.55))
	draw_circle(middle, r, PORTAL_STONE)
	draw_arc(middle, r - 3.0, 0.0, TAU, 72, Color("5d566b"), 5.0, true)
	var spin := _time * TAU * PORTAL_SPIN
	for i in 16:
		var direction := Vector2.from_angle(TAU * i / 16.0 - spin * 0.25)
		draw_line(middle + direction * (r - 10.0), middle + direction * (r - 5.0), Color(PORTAL_GREEN, 0.55 if live else 0.2), 2.0, true)
	var inner := r - 12.0
	draw_circle(middle, inner, Color("0b0812"))
	for arm in PORTAL_ARMS:
		var before := middle
		for k in range(1, PORTAL_SEGMENTS + 1):
			var f := float(k) / PORTAL_SEGMENTS
			var angle := spin + arm * TAU / PORTAL_ARMS + f * 4.4
			var point := middle + Vector2.from_angle(angle) * inner * f
			var color := PORTAL_GREEN.lerp(PORTAL_PURPLE, f)
			color.a = (1.0 - f * 0.5) * (0.95 if live else 0.3)
			draw_line(before, point, color, 1.5 + 6.0 * f, true)
			before = point
	draw_texture_rect(glow, Rect2(middle - Vector2.ONE * inner * 0.6, Vector2.ONE * inner * 1.2), false, Color(0.85, 1.0, 0.92, 0.75 if live else 0.2))
	if locked:
		JourneyMap.draw_chain(self, middle + Vector2(-r, -r * 0.55), middle + Vector2(r, r * 0.55), JourneyMap.CHAIN_COLOR)
		JourneyMap.draw_chain(self, middle + Vector2(-r, r * 0.55), middle + Vector2(r, -r * 0.55), JourneyMap.CHAIN_COLOR)
		draw_circle(middle, 20.0, Color("15161a"))
		draw_arc(middle, 20.0, 0.0, TAU, 32, JourneyMap.CHAIN_COLOR, 2.0, true)
		draw_texture_rect(LOCK, Rect2(middle - Vector2(13, 13), Vector2(26, 26)), false)


func _draw_plate(middle: Vector2, r: float) -> void:
	var width: float = PLATE_WIDTHS[kind]
	var height := ENDLESS_PLATE_HEIGHT if kind == ENDLESS else PLATE_HEIGHT
	var rect := Rect2(middle.x - width * 0.5, middle.y + r - PLATE_TUCK, width, height)
	var style := StyleBoxFlat.new()
	style.bg_color = PLATE_COLOR
	style.border_color = CLEARED_RIM if cleared else ring_color()
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	draw_style_box(style, rect)
	match kind:
		TRAINING:
			_draw_centered("TRAINING", rect.get_center(), PLATE_FONT, UiStyle.TITLE_COLOR)
		ENDLESS:
			_draw_centered("ENDLESS", rect.get_center() + Vector2(0, -8), PLATE_FONT, UiStyle.TITLE_COLOR if not locked else UiStyle.DIM_COLOR)
			_draw_centered("Best %d" % best, rect.get_center() + Vector2(0, 10), BEST_FONT, UiStyle.GOLD_COLOR if not locked else UiStyle.DIM_COLOR)
		_:
			_draw_centered(stage_id, rect.get_center(), PLATE_FONT, UiStyle.GOLD_COLOR if cleared else UiStyle.TITLE_COLOR)


func _draw_check(at: Vector2) -> void:
	draw_circle(at, 11.0, Color("0e2414"))
	draw_arc(at, 11.0, 0.0, TAU, 24, CHECK_COLOR, 2.0, true)
	draw_polyline(PackedVector2Array([at + Vector2(-5, 0), at + Vector2(-1.5, 4), at + Vector2(5, -4)]), CHECK_COLOR, 3.0, true)


func _draw_lock(at: Vector2) -> void:
	draw_circle(at, 11.0, Color("101114"))
	draw_arc(at, 11.0, 0.0, TAU, 24, Color(0.6, 0.62, 0.68), 1.5, true)
	draw_texture_rect(LOCK, Rect2(at - Vector2(8, 8), Vector2(16, 16)), false)


## `text` centered on `at`, outlined.
func _draw_centered(text: String, at: Vector2, font_size: int, color: Color) -> void:
	var font := get_theme_default_font()
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var baseline := at + Vector2(-width * 0.5, (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5)
	draw_string_outline(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Color(0, 0, 0, 0.85))
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

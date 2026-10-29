class_name ThreshFinal
extends Thresh
## Act 6's Thresh, the final fight (6-5). Two phases of his full HP, and he
## never dies.
##
## Phase 1 (Q, E, R): Death Sentence and Flay as in Act 1 with his own
## numbers, and The Box: a ring warning round him, then a ring of spectral
## wall pieces; a piece Lucian touches or crosses breaks, hurts him and slows
## him. At 0 HP he rises with full HP: RISE_TIME taking no damage and doing
## nothing, his warnings, walls and hooks gone, darker, with a green aura.
##
## Phase 2 (Q, W, R): a hook that misses comes again at once (once per cast),
## Dark Passage (his lantern thrown near Lucian; Lantern Souls come out of it
## as his summons, PASSAGE_CAP of them at most), and a harder Box. At 0 HP he
## falls: `fell`, once. The stage frees his souls and takes him away.
##
## 0 HP is only noted in _die (a shot's physics callback can bring it); the
## rise and the fall come in _physics_process. `stopped` (Thresh's) holds
## while he is down, rising or fallen: he takes no damage, thinks nothing and
## throws nothing then.

## At 0 HP in Phase 2 (once): his fight is over.
signal fell(thresh: ThreshFinal)

const FINAL_HOOK_DAMAGE := 160.0
const FINAL_HOOK_WARN := 0.8
const FINAL_HOOK_COOLDOWN := 8.0
const FINAL_FLAY_DAMAGE := 120.0
const FINAL_FLAY_PUSH := 300.0
## Phase 2: a missed hook comes again behind this shorter warning (a pull,
## not a CC).
const REHOOK_WARN := 0.45
## Phase 2: Death Sentence keeps him busy this long past the chain's flight,
## so its miss (and the second throw) comes before any other skill can start.
const REHOOK_SLACK := 0.15
## The Box: used when Lucian is within BOX_RADIUS, centered on Thresh.
const BOX_RADIUS := 450.0
## The ring warning's band: the pieces rise on its middle line.
const BOX_BAND := 60.0
const BOX_WARN := 1.0
const BOX_PIECES := 12
const BOX_TIME := 4.0
const BOX_DAMAGE := 150.0
const BOX_DAMAGE_PHASE_2 := 220.0
const BOX_SLOW := 0.8
const BOX_SLOW_TIME := 2.0
## Lucian's slow id for it.
const BOX_SLOW_ID := &"the_box"
const BOX_COOLDOWN := 22.0
const BOX_COOLDOWN_PHASE_2 := 18.0
const BOX_FIRST := 6.0
## One crossing, one hit: a touch this soon after the last one does nothing
## (its piece still breaks). A crossing at a joint touches both pieces.
const BOX_TOUCH_GAP := 0.3
## Dark Passage: the lantern lands within PASSAGE_REACH of Lucian, behind a
## circle warning; it lies there PASSAGE_TIME, and PASSAGE_SOULS Lantern
## Souls come out of it.
const PASSAGE_REACH := 250.0
const PASSAGE_RADIUS := 100.0
const PASSAGE_WARN := 0.6
const PASSAGE_TIME := 6.0
const PASSAGE_SOULS := 3
## His summoned souls alive or on their way stay at or under this: at 4, a
## Dark Passage brings 2.
const PASSAGE_CAP := 6
const PASSAGE_COOLDOWN := 16.0
const PASSAGE_FIRST := 3.0
## He throws it at Lucian from this far at most.
const PASSAGE_RANGE := 1000.0
## Tries for a lantern spot with room round it, before the fallback.
const PASSAGE_TRIES := 12
## A soul comes out this far from the lantern.
const SOUL_GAP := 60.0
## Phase 2's first hook, this long after he is up.
const PHASE_2_HOOK_FIRST := 1.0
## Seconds he takes no damage and does nothing after rising.
const RISE_TIME := 2.5
## Seconds he stands after a skill's warning ends.
const RECOVER := 0.3
## Phase 2: his art's color times this.
const PHASE_2_SHADE := Color(0.5, 0.56, 0.54)
const AURA_COLOR := Color("4dff9a")
## The aura reaches this far past his body; it swells by AURA_SWELL as he rises.
const AURA_GAP := 22.0
const AURA_SWELL := 0.6
const LANTERN_ART := preload("res://assets/art/ui/title_lantern.svg")
const LANTERN_SCALE := 0.35
## The lantern fades over the last of its time.
const LANTERN_FADE := 0.4

## 1, then 2 once he has risen.
var phase := 1

## 0 HP noted (_die): the rise or the fall comes on the next physics frame.
var _floored := false
var _fallen := false
var _rise_left := 0.0
## This cast's hook has come again already (Phase 2).
var _hooked_again := false
var _box_damage := BOX_DAMAGE
## Seconds until a Box touch hurts again (BOX_TOUCH_GAP).
var _box_gap_left := 0.0
## His warnings, walls, hooks and lanterns: cleared when he rises or falls.
var _placed: Array[Node] = []


func _init() -> void:
	stop_share = 0.0
	hook_damage = FINAL_HOOK_DAMAGE
	hook_warn = FINAL_HOOK_WARN
	hook_cooldown = FINAL_HOOK_COOLDOWN
	flay_damage = FINAL_FLAY_DAMAGE
	flay_push = FINAL_FLAY_PUSH


## Phase 1: Death Sentence and Flay (Thresh's), then The Box.
func _ready() -> void:
	super()
	add_skill(&"the_box", BOX_COOLDOWN, BOX_RADIUS, BOX_FIRST, the_box)


func phase_label() -> String:
	return "Phase %d" % phase


## The RISE_TIME after he rises: no damage taken, nothing done.
func is_rising() -> bool:
	return _rise_left > 0.0


## Phase 2's green aura.
func has_aura() -> bool:
	return phase == 2


## Nothing while he is down, rising or fallen.
func take_damage(info: DamageInfo) -> float:
	return 0.0 if stopped else super(info)


## He never dies: 0 HP is only noted here, where a shot's physics callback
## may be running. No death, no kill for Lucian.
func _die() -> void:
	_floored = true
	stopped = true


## The rise or the fall after 0 HP; the rise's clock; the fight back on
## once he is up.
func _physics_process(delta: float) -> void:
	super(delta)
	_box_gap_left = maxf(_box_gap_left - delta, 0.0)
	if _floored:
		_floored = false
		if phase == 1:
			_rise()
		else:
			_fall()
	elif is_rising():
		_rise_left = maxf(_rise_left - delta, 0.0)
		queue_redraw()
	elif stopped and not _fallen:
		stopped = false
		queue_redraw()


## A new cast: its hook may come again, once (Phase 2), and he stays busy
## until a miss has brought it again (REHOOK_SLACK).
func death_sentence() -> float:
	_hooked_again = false
	return super() + (REHOOK_SLACK if phase == 2 else 0.0)


## The Box: a ring warning round him, then the pieces rise on it (_raise_box).
func the_box() -> float:
	var center := global_position
	var warning := GroundWarning.ring(center, BOX_RADIUS, BOX_BAND, BOX_WARN)
	warning.fired.connect(_raise_box.bind(center))
	_place(warning)
	return BOX_WARN + RECOVER


## Dark Passage: a circle warning on a spot near Lucian, then the lantern
## lands there (_drop_lantern).
func dark_passage() -> float:
	var spot := passage_spot(target.global_position)
	face(spot)
	var warning := GroundWarning.circle(spot, PASSAGE_RADIUS, PASSAGE_WARN)
	warning.fired.connect(_drop_lantern.bind(spot))
	_place(warning)
	return PASSAGE_WARN + RECOVER


## Where the lantern lands: within PASSAGE_REACH of `near`, with its whole
## circle on walkable ground when the map is known (room for its souls).
## After PASSAGE_TRIES misses, `near` moved toward the map's middle until it
## fits (Boss.landing_spot).
func passage_spot(near: Vector2) -> Vector2:
	for attempt in PASSAGE_TRIES:
		var tried := near + Vector2.from_angle(randf() * TAU) * PASSAGE_REACH * sqrt(randf())
		if arena == null or arena.is_walkable(tried, PASSAGE_RADIUS):
			return tried
	return landing_spot(near, arena, PASSAGE_RADIUS)


## Kept with his marks, so the rise and the fall can clear it.
func _place(node: Node) -> void:
	var kept: Array[Node] = []
	for old: Variant in _placed:
		if is_instance_valid(old):
			kept.append(old)
	_placed = kept
	_placed.append(node)
	super(node)


## The chain flies as in Act 1 and is kept with his marks. In Phase 2 a
## miss brings it again (_hook_again), once per cast.
func _throw_hook(toward: Vector2) -> EnemyProjectile:
	var hook := super(toward)
	if hook == null:
		return null
	_placed.append(hook)
	if phase == 2 and not _hooked_again:
		hook.missed.connect(_hook_again)
	return hook


## Phase 2: the hook missed (its range or a wall; one Banshee's Veil blocked
## reached Lucian, and is no miss). It comes again at once, at where Lucian is
## now, behind a REHOOK_WARN line. `missed` never comes inside a physics
## callback, so the warning can go down here.
func _hook_again() -> void:
	if stopped or _hooked_again or not can_fight():
		return
	_hooked_again = true
	var toward := global_position.direction_to(target.global_position)
	face(target.global_position)
	var warning := GroundWarning.line(global_position, toward, HOOK_LENGTH, HOOK_WIDTH, REHOOK_WARN)
	warning.fired.connect(_throw_hook.bind(toward))
	_place(warning)
	busy_left = maxf(busy_left, REHOOK_WARN + HOOK_LENGTH / HOOK_SPEED)


## The pieces rise in a ring round where he cast it. Each one Lucian
## touches or crosses breaks (_box_touched).
func _raise_box(center: Vector2) -> void:
	if stopped or not is_instance_valid(target):
		return
	var box := SpectralWall.ring(center, BOX_RADIUS, BOX_PIECES, BOX_TIME)
	box.target = target
	box.break_on_touch = true
	box.touched.connect(_box_touched)
	_place(box)


## A piece touched (once each): the hit, and the slow only when the hit
## landed (Banshee's Veil blocks both). One crossing, one hit: a touch within
## BOX_TOUCH_GAP of the last one (the next piece at a joint) does nothing.
func _box_touched(_piece: int) -> void:
	if stopped or not is_instance_valid(target) or _box_gap_left > 0.0:
		return
	_box_gap_left = BOX_TOUCH_GAP
	if target.take_damage(skill_hit(_box_damage, DamageInfo.Type.MAGIC, &"the_box")):
		target.add_slow(BOX_SLOW_ID, BOX_SLOW, BOX_SLOW_TIME)


## The lantern lands: it lies there PASSAGE_TIME, and up to PASSAGE_SOULS
## Lantern Souls come out round it as his summons, never more than
## PASSAGE_CAP of them alive or on their way (`summons`, which summon_gone
## lowers; the stage spawns them deferred).
func _drop_lantern(spot: Vector2) -> void:
	if stopped:
		return
	var lantern := Sprite2D.new()
	lantern.texture = LANTERN_ART
	lantern.scale = Vector2.ONE * LANTERN_SCALE
	lantern.position = spot
	_place(lantern)
	var stay := lantern.create_tween()
	stay.tween_interval(PASSAGE_TIME - LANTERN_FADE)
	stay.tween_property(lantern, "modulate:a", 0.0, LANTERN_FADE)
	stay.tween_callback(lantern.queue_free)
	var count := mini(PASSAGE_SOULS, PASSAGE_CAP - summons)
	var turn := randf() * TAU
	for i in count:
		summons += 1
		summon_requested.emit(self, WavePlan.LANTERN_SOUL, spot + Vector2.from_angle(turn + TAU * i / count) * SOUL_GAP)
		# A listener may have ended the fight.
		if stopped:
			return


## Phase 2: full HP, his marks gone, Q/W/R (each waiting for the rise to
## end), the darker art and the aura.
func _rise() -> void:
	phase = 2
	hp = max_hp
	health_bar.set_health(hp, max_hp)
	_rise_left = RISE_TIME
	busy_left = 0.0
	_hooked_again = false
	_box_damage = BOX_DAMAGE_PHASE_2
	_clear_placed()
	skills.clear()
	_cooldowns.clear()
	add_skill(&"death_sentence", hook_cooldown, HOOK_LENGTH, RISE_TIME + PHASE_2_HOOK_FIRST, death_sentence)
	add_skill(&"dark_passage", PASSAGE_COOLDOWN, PASSAGE_RANGE, RISE_TIME + PASSAGE_FIRST, dark_passage)
	add_skill(&"the_box", BOX_COOLDOWN_PHASE_2, BOX_RADIUS, RISE_TIME + BOX_FIRST, the_box)
	_paint()
	queue_redraw()


## Phase 2 at 0 HP: he falls, once. His marks go and the stage is told.
func _fall() -> void:
	_fallen = true
	_clear_placed()
	queue_redraw()
	fell.emit(self)


func _clear_placed() -> void:
	for node: Variant in _placed:
		if is_instance_valid(node):
			(node as Node).queue_free()
	_placed.clear()


## Phase 2's art is darker.
func _paint() -> void:
	super()
	if phase == 2 and sprite:
		sprite.modulate = data.tint * PHASE_2_SHADE


## Phase 2's green aura under his art; it swells while he rises.
func _draw() -> void:
	super()
	if not has_aura():
		return
	var reach := (radius + AURA_GAP) * (1.0 + AURA_SWELL * _rise_left / RISE_TIME)
	draw_circle(Vector2.ZERO, reach, Color(AURA_COLOR, 0.14))
	draw_arc(Vector2.ZERO, reach, 0.0, TAU, 64, Color(AURA_COLOR, 0.7), 4.0, true)

class_name OceanDrake
extends Boss
## Act 3's second mini boss, in 3-4's last wave. Its water shot is a plain
## magic bolt. Tidal Wave: a line warning, then a wide wave along it that
## pushes Lucian back and slows him. Soothing Mist (at or below 70% HP): it
## stands and heals over a few seconds, a mist ring round it; enough damage
## in that time interrupts it, and it stands dazed. The damage is counted in
## _lose_hp and acted on in _physics_process, never inside a damage path.

const WAVE_LENGTH := 1100.0
const WAVE_WIDTH := 180.0
const WAVE_WARN := 0.8
const WAVE_SPEED := 900.0
const WAVE_DAMAGE := 90.0
## A hit pushes Lucian this far along the line, at PUSH_SPEED.
const WAVE_PUSH := 300.0
const PUSH_SPEED := 1200.0
const WAVE_SLOW := 0.3
const WAVE_SLOW_TIME := 2.0
const WAVE_COOLDOWN := 10.0
const WAVE_FIRST := 3.0
## Lucian's slow id for the wave.
const SLOW_ID := &"tidal_wave"
const MIST_TIME := 4.0
## The share of max HP the whole channel heals.
const MIST_HEAL := 0.3
## The share of max HP in damage during the channel that interrupts it.
const MIST_BREAK := 0.08
const MIST_COOLDOWN := 18.0
## Soothing Mist waits until HP is at or below this share.
const MIST_HP := 0.7
## Seconds it stands dazed after an interrupt.
const DAZE_TIME := 1.5
## Seconds it stands after a skill's warning ends.
const RECOVER := 0.3
const WATER := Color("5ad1e6")
const MIST_FILL := Color(0.6, 0.92, 0.95, 0.18)
const MIST_EDGE := Color(0.75, 0.97, 1.0, 0.7)
## The mist ring this far outside the body.
const MIST_RING := 36.0
const INTERRUPTED_COLOR := Color("ffd166")
## "Interrupted!" rises from here, over its body: under the damage numbers
## (DamageNumberSpawner.HEIGHT_ABOVE).
const INTERRUPTED_AT := Vector2(0, 10)
const DAZE_STAR := Color("ffe14a")

var _mist_left := 0.0
## Damage taken since the channel began.
var _mist_damage := 0.0
var _daze_left := 0.0


func _ready() -> void:
	super()
	# Tried first: a low drake heals before it hits.
	add_skill(&"soothing_mist", MIST_COOLDOWN, INF, 0.0, soothing_mist)
	add_skill(&"tidal_wave", WAVE_COOLDOWN, WAVE_LENGTH, WAVE_FIRST, tidal_wave)


func is_channeling() -> bool:
	return _mist_left > 0.0


func is_dazed() -> bool:
	return _daze_left > 0.0


## A line warning at Lucian, then the wave along it.
func tidal_wave() -> float:
	var toward := global_position.direction_to(target.global_position)
	face(target.global_position)
	var warning := GroundWarning.line(global_position, toward, WAVE_LENGTH, WAVE_WIDTH, WAVE_WARN)
	warning.fired.connect(_send_wave.bind(toward))
	warning_parent.add_child(warning)
	return WAVE_WARN + RECOVER


## Stands and heals MIST_HEAL of max HP over MIST_TIME (see _physics_process).
func soothing_mist() -> float:
	_mist_left = MIST_TIME
	_mist_damage = 0.0
	queue_redraw()
	return MIST_TIME


func _can_use(id: StringName) -> bool:
	return id != &"soothing_mist" or hp <= max_hp * MIST_HP


## The water shot: the data's bolt, in water colors.
func _attack() -> void:
	fire_bolt(make_hit(), data.projectile_speed, attack_range + BOLT_OVERREACH).color = WATER


## Only counts the channel's damage: the interrupt comes in _physics_process.
func _lose_hp(amount: float) -> void:
	if is_channeling():
		_mist_damage += amount
	super(amount)


func _physics_process(delta: float) -> void:
	super(delta)
	if not is_alive():
		return
	if is_dazed():
		_daze_left = maxf(_daze_left - delta, 0.0)
		queue_redraw()
	if not is_channeling():
		return
	if _mist_damage >= max_hp * MIST_BREAK:
		_interrupt()
		return
	var step := minf(delta, _mist_left)
	heal(max_hp * MIST_HEAL * step / MIST_TIME)
	_mist_left -= step
	queue_redraw()


## The channel ends early: dazed (busy, so no skills and no attacks) for
## DAZE_TIME, with "Interrupted!" over it.
func _interrupt() -> void:
	_mist_left = 0.0
	_mist_damage = 0.0
	_daze_left = DAZE_TIME
	busy_left = DAZE_TIME
	var note := FloatingText.new("Interrupted!", INTERRUPTED_COLOR)
	note.position = global_position + INTERRUPTED_AT
	warning_parent.add_child(note)
	queue_redraw()


func _send_wave(toward: Vector2) -> void:
	if dead:
		return
	var wave := fire_bolt(skill_hit(WAVE_DAMAGE, DamageInfo.Type.MAGIC, &"tidal_wave"), WAVE_SPEED, WAVE_LENGTH, toward)
	wave.hit_radius = WAVE_WIDTH * 0.5
	wave.color = WATER
	wave.hit_lucian.connect(_wave_hit.bind(toward))


## The wave pushes Lucian along its line (walls stop him) and slows him.
func _wave_hit(toward: Vector2) -> void:
	if not is_instance_valid(target):
		return
	target.displace(target.global_position + toward * WAVE_PUSH, PUSH_SPEED)
	target.add_slow(SLOW_ID, WAVE_SLOW, WAVE_SLOW_TIME)


func _draw() -> void:
	super()
	if is_channeling():
		# A soft ring of mist, and an arc filling as the channel goes on.
		var ring := radius + MIST_RING
		var done := 1.0 - _mist_left / MIST_TIME
		draw_circle(Vector2.ZERO, ring, MIST_FILL)
		draw_arc(Vector2.ZERO, ring, 0.0, TAU, 64, Color(MIST_EDGE, 0.35), 3.0, true)
		draw_arc(Vector2.ZERO, ring + 8.0, -PI * 0.5, -PI * 0.5 + TAU * done, 64, MIST_EDGE, 5.0, true)
	elif is_dazed():
		# Three stars circling over its head.
		var spin := _daze_left * 5.0
		for i in 3:
			var at := Vector2(0, -radius - 6.0) + Vector2.from_angle(spin + TAU * i / 3.0) * Vector2(26.0, 9.0)
			draw_circle(at, 5.0, DAZE_STAR)

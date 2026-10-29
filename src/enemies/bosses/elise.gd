class_name Elise
extends Boss
## Act 5's second mini boss, a spider queen at range. Cocoon: a line warning,
## then a web bolt that stuns on a hit. Rappel (at or below 85% HP): she
## rises, untargetable; a circle warning follows Lucian for RAPPEL_FOLLOW,
## then locks, and at RAPPEL_TIME she drops there. The drop runs on her own
## timer, so she lands even if the warning is gone.

const COCOON_LENGTH := 950.0
const COCOON_WIDTH := 60.0
const COCOON_WARN := 0.7
const COCOON_SPEED := 1300.0
const COCOON_DAMAGE := 100.0
const COCOON_STUN := 1.25
const COCOON_COOLDOWN := 11.0
const COCOON_FIRST := 3.0
const RAPPEL_RADIUS := 180.0
## Seconds the circle follows Lucian, and seconds until she drops.
const RAPPEL_FOLLOW := 1.0
const RAPPEL_TIME := 1.9
const RAPPEL_DAMAGE := 160.0
const RAPPEL_COOLDOWN := 16.0
## Rappel waits until HP is at or below this share.
const RAPPEL_HP := 0.85
## Seconds her art takes to fade as she rises.
const RISE_FADE := 0.3
## Seconds she stands after a skill's warning ends, or after she drops.
const RECOVER := 0.3
const WEB := Color("e8e8f0")

var _rappel_time := -1.0
var _rappel_warning: GroundWarning
var _rappel_spot := Vector2.ZERO
var _fade: Tween


func _ready() -> void:
	super()
	# Tried first: a hurt queen climbs before she spits.
	add_skill(&"rappel", RAPPEL_COOLDOWN, INF, 0.0, rappel)
	add_skill(&"cocoon", COCOON_COOLDOWN, COCOON_LENGTH, COCOON_FIRST, cocoon)


## Up on her thread: from the rise until she drops.
func is_rappelling() -> bool:
	return _rappel_time >= 0.0


## A line warning at Lucian, then the web bolt.
func cocoon() -> float:
	var toward := global_position.direction_to(target.global_position)
	face(target.global_position)
	var warning := GroundWarning.line(global_position, toward, COCOON_LENGTH, COCOON_WIDTH, COCOON_WARN)
	warning.fired.connect(_spit_web.bind(toward))
	warning_parent.add_child(warning)
	return COCOON_WARN + RECOVER


func _spit_web(toward: Vector2) -> void:
	if not is_alive():
		return
	var bolt := fire_bolt(skill_hit(COCOON_DAMAGE, DamageInfo.Type.MAGIC, &"cocoon"), COCOON_SPEED, COCOON_LENGTH, toward)
	bolt.hit_radius = COCOON_WIDTH * 0.5
	bolt.color = WEB
	bolt.hit_lucian.connect(_web_hit)


func _web_hit() -> void:
	if is_instance_valid(target):
		target.add_cc(CrowdControl.Kind.STUN, COCOON_STUN)


## Rises: untargetable, her art fading, a circle on Lucian that follows him
## and locks (see _physics_process). Busy until she has dropped.
func rappel() -> float:
	set_untargetable(true)
	_rappel_time = 0.0
	_rappel_spot = target.global_position
	if _flash_tween:
		_flash_tween.kill()
	visuals.modulate = Color.WHITE
	_fade = create_tween().set_parallel()
	_fade.tween_property(visuals, "modulate:a", 0.0, RISE_FADE)
	_fade.tween_property(health_bar, "modulate:a", 0.0, RISE_FADE)
	_rappel_warning = GroundWarning.circle(_rappel_spot, RAPPEL_RADIUS, RAPPEL_TIME)
	warning_parent.add_child(_rappel_warning)
	return RAPPEL_TIME + RECOVER


func _can_use(id: StringName) -> bool:
	return id != &"rappel" or hp <= max_hp * RAPPEL_HP


## Nothing while she is up: no walking, no shots, no skills.
func _think(delta: float) -> void:
	if not is_rappelling():
		super(delta)


func _physics_process(delta: float) -> void:
	super(delta)
	if not is_alive() or not is_rappelling():
		return
	var before := _rappel_time
	_rappel_time += delta
	if before < RAPPEL_FOLLOW:
		if is_instance_valid(target):
			_rappel_spot = target.global_position
		if _rappel_time >= RAPPEL_FOLLOW:
			_rappel_spot = Boss.landing_spot(_rappel_spot, arena, radius)
		if is_instance_valid(_rappel_warning):
			_rappel_warning.global_position = _rappel_spot
	if _rappel_time >= RAPPEL_TIME:
		_drop()


## She drops on the locked spot, seen and targetable again: a hit on Lucian
## inside the circle.
func _drop() -> void:
	_rappel_time = -1.0
	global_position = _rappel_spot
	set_untargetable(false)
	if _fade:
		_fade.kill()
	visuals.modulate.a = 1.0
	health_bar.modulate.a = 1.0
	if is_instance_valid(target) and GroundWarning.in_circle(_rappel_spot, RAPPEL_RADIUS, target.global_position, Lucian.HIT_RADIUS):
		target.take_damage(skill_hit(RAPPEL_DAMAGE, DamageInfo.Type.MAGIC, &"rappel"))

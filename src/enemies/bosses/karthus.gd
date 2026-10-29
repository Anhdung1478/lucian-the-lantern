class_name Karthus
extends Boss
## Act 5's boss, the lich of the ruined graveyard (5-5). His bolt is a plain
## magic shot. Lay Waste: five circle warnings, one on Lucian and four near
## him, laid 0.15 s apart. Wall of Pain: a line warning across the way
## between them, then a spectral wall that slows Lucian once if he touches or
## crosses it. Requiem (at 75%, 45% and 15% HP): he stands and channels; enough
## damage during it breaks it, else Lucian takes a heavy hit. The damage is
## counted in _lose_hp and acted on in _physics_process, never inside a damage
## path. The circles after the first are laid from _physics_process too.
##
## The revived Karthus (Act 6, 6-2; `revived`) has Lay Waste with fewer, harder
## circles and Defile, an aura always on him, and neither Wall of Pain nor
## Requiem. Defile reaches only DEFILE_RADIUS, so he keeps walking at Lucian
## while he fires, until he is REVIVED_STOP away.

const LAY_COUNT := 5
const LAY_RADIUS := 110.0
## The circles after the first fall this close to Lucian.
const LAY_SPREAD := 300.0
const LAY_GAP := 0.15
const LAY_WARN := 0.7
const LAY_DAMAGE := 110.0
const LAY_COOLDOWN := 6.0
const LAY_FIRST := 2.0
const LAY_REACH := 900.0
## Tries for a circle spot on walkable ground before it falls on Lucian.
const LAY_TRIES := 12
const WALL_LENGTH := 900.0
const WALL_WIDTH := 60.0
const WALL_WARN := 0.6
const WALL_TIME := 5.0
const WALL_SLOW := 0.7
const WALL_SLOW_TIME := 2.5
const WALL_COOLDOWN := 14.0
const WALL_FIRST := 5.0
## Lucian's slow id for the wall.
const SLOW_ID := &"wall_of_pain"
## Requiem comes once at each of these shares of max HP, highest first.
const REQUIEM_HP: Array[float] = [0.75, 0.45, 0.15]
const REQUIEM_TIME := 3.0
## The share of max HP in damage during the channel that breaks it.
const REQUIEM_BREAK := 0.08
const REQUIEM_DAMAGE := 900.0
## The revived Karthus: four circles of 120.
const REVIVED_LAY_COUNT := 4
const REVIVED_LAY_DAMAGE := 120.0
## Defile: an aura round him, always on. It burns Lucian inside it for
## DEFILE_DPS magic a second (a tick every 0.5 s: BurnSet).
const DEFILE_RADIUS := 350.0
const DEFILE_DPS := 80.0
## Lucian's burn id for it (apart from lava's burning_ground).
const DEFILE_ID := &"defile"
const DEFILE_COLOR := Color("a45bd6")
## He walks in until Lucian is this far away: inside Defile, with a margin so
## he does not have to stand on him.
const REVIVED_STOP := 280.0
## Seconds it stands after a skill's warning ends.
const RECOVER := 0.3
const BROKEN_COLOR := Color("ffd166")
## "Broken!" rises from here, over his body: under the damage numbers.
const BROKEN_AT := Vector2(0, 10)
const REQUIEM_COLOR := Color("b57bff")
## The ring on Lucian: its radius pulses between these, PULSE_RATE times a second.
const RING_MIN := 60.0
const RING_MAX := 90.0
const PULSE_RATE := 2.0

## The revived Karthus of Act 6: Lay Waste and Defile (the stage sets it).
var revived := false

var _channel_left := 0.0
## Damage taken since the channel began.
var _channel_damage := 0.0
## Requiems used so far.
var _requiems := 0
## Circles still to lay: {"at": Vector2, "wait": seconds}.
var _lay_queue: Array[Dictionary] = []
## Defile's burn zone, under warning_parent; made on his first frame.
var _defile: HazardZone


func _ready() -> void:
	super()
	if revived:
		add_skill(&"lay_waste", LAY_COOLDOWN, LAY_REACH, LAY_FIRST, lay_waste)
		return
	# Tried first: at its HP, Requiem comes before anything else.
	add_skill(&"requiem", 0.0, INF, 0.0, requiem)
	add_skill(&"lay_waste", LAY_COOLDOWN, LAY_REACH, LAY_FIRST, lay_waste)
	add_skill(&"wall_of_pain", WALL_COOLDOWN, WALL_LENGTH, WALL_FIRST, wall_of_pain)


## The radius of Defile's ring on him: 0 for the Act 5 Karthus.
func defile_ring_radius() -> float:
	return DEFILE_RADIUS if revived else 0.0


func is_channeling() -> bool:
	return _channel_left > 0.0


## {} outside Requiem; during it, the damage so far and what breaks it.
func channel() -> Dictionary:
	if not is_channeling() or not is_alive():
		return {}
	return {"done": _channel_damage, "need": max_hp * REQUIEM_BREAK}


## The first circle on Lucian now, the rest every LAY_GAP after it.
func lay_waste() -> float:
	face(target.global_position)
	var spots := lay_spots(target.global_position)
	for i in spots.size():
		_lay_queue.append({"at": spots[i], "wait": LAY_GAP * i})
	_lay_due(0.0)
	return LAY_GAP * (spots.size() - 1) + LAY_WARN + RECOVER


## Where the circles fall: the first on `center`, the rest at random within
## LAY_SPREAD of it, on walkable ground when the map is known (else on
## `center`, after LAY_TRIES misses).
func lay_spots(center: Vector2) -> Array[Vector2]:
	var spots: Array[Vector2] = [center]
	for i in (REVIVED_LAY_COUNT if revived else LAY_COUNT) - 1:
		var spot := center
		for attempt in LAY_TRIES:
			var tried := center + Vector2.from_angle(randf() * TAU) * LAY_SPREAD * sqrt(randf())
			if arena == null or arena.is_walkable(tried):
				spot = tried
				break
		spots.append(spot)
	return spots


## A line warning across the way between them, then the wall.
func wall_of_pain() -> float:
	var center := (global_position + target.global_position) * 0.5
	var across := global_position.direction_to(target.global_position).orthogonal()
	face(target.global_position)
	var warning := GroundWarning.line(center - across * WALL_LENGTH * 0.5, across, WALL_LENGTH, WALL_WIDTH, WALL_WARN)
	warning.fired.connect(_raise_wall.bind(center, across))
	warning_parent.add_child(warning)
	return WALL_WARN + RECOVER


## He stands and channels for REQUIEM_TIME (see _physics_process). Every
## threshold his HP is already at or below is spent with it: a burst past
## several brings one Requiem, never two in a row.
func requiem() -> float:
	_requiems += 1
	_spend_thresholds()
	_channel_left = REQUIEM_TIME
	_channel_damage = 0.0
	queue_redraw()
	return REQUIEM_TIME


## Spends every threshold his HP is at or below now: one crossing, one Requiem.
func _spend_thresholds() -> void:
	while _requiems < REQUIEM_HP.size() and hp <= max_hp * REQUIEM_HP[_requiems]:
		_requiems += 1


func _can_use(id: StringName) -> bool:
	if id == &"requiem":
		return _requiems < REQUIEM_HP.size() and hp <= max_hp * REQUIEM_HP[_requiems]
	return true


## Only counts the channel's damage: the break comes in _physics_process.
func _lose_hp(amount: float) -> void:
	if is_channeling():
		_channel_damage += amount
	super(amount)


func _physics_process(delta: float) -> void:
	super(delta)
	if not is_alive():
		return
	_keep_defile()
	_lay_due(delta)
	if not is_channeling():
		return
	if _channel_damage >= max_hp * REQUIEM_BREAK:
		_break()
		return
	_channel_left = maxf(_channel_left - delta, 0.0)
	queue_redraw()
	if _channel_left <= 0.0:
		_finish_requiem()


## The revived Karthus walks on while he fires: past his bolt range, in to
## REVIVED_STOP. (The base walks only to its attack range, then stands.)
func _think(delta: float) -> void:
	super(delta)
	# Past the bolt range the base already walked: only the last stretch is his.
	if revived and busy_left <= 0.0 and can_fight() and distance_to_target() > REVIVED_STOP 			and distance_to_target() <= attack_range + Lucian.HIT_RADIUS:
		walk_toward(target.global_position, delta)


## Defile, on every frame: the zone is made on the first (a sibling can't be
## added while the stage is still adding him) and kept on him.
func _keep_defile() -> void:
	if not revived:
		return
	if _defile == null:
		_defile = HazardZone.burning(DEFILE_DPS, DamageInfo.Type.MAGIC)
		_defile.id = DEFILE_ID
		_defile.lucian = target
		# Invisible: the ring is drawn by Karthus (_draw), so it needs no look option.
		_defile.visible = false
		_defile.set_circle(global_position, DEFILE_RADIUS)
		warning_parent.add_child(_defile)
	_defile.position = global_position


func _die() -> void:
	_end_defile()
	super()


func _exit_tree() -> void:
	_end_defile()


func _end_defile() -> void:
	if is_instance_valid(_defile):
		_defile.queue_free()
	_defile = null


## Lays every queued circle whose wait has run out, `delta` after the last call.
func _lay_due(delta: float) -> void:
	var waiting: Array[Dictionary] = []
	for circle in _lay_queue:
		circle.wait -= delta
		if circle.wait <= 0.0:
			_lay_circle(circle.at)
		else:
			waiting.append(circle)
	_lay_queue = waiting


func _lay_circle(at: Vector2) -> void:
	var warning := GroundWarning.circle(at, LAY_RADIUS, LAY_WARN)
	warning.strike(skill_hit(REVIVED_LAY_DAMAGE if revived else LAY_DAMAGE, DamageInfo.Type.MAGIC, &"lay_waste"), target)
	warning_parent.add_child(warning)


## The channel ends early: "Broken!" over him, and he recovers.
func _break() -> void:
	_channel_left = 0.0
	_channel_damage = 0.0
	busy_left = RECOVER
	_spend_thresholds()
	var note := FloatingText.new("Broken!", BROKEN_COLOR)
	note.position = global_position + BROKEN_AT
	warning_parent.add_child(note)
	queue_redraw()


## Nobody broke it: the hit lands on Lucian (Banshee's Veil blocks it).
func _finish_requiem() -> void:
	_channel_damage = 0.0
	busy_left = RECOVER
	_spend_thresholds()
	if is_instance_valid(target):
		target.take_damage(skill_hit(REQUIEM_DAMAGE, DamageInfo.Type.MAGIC, &"requiem"))
	queue_redraw()


func _raise_wall(center: Vector2, across: Vector2) -> void:
	if dead or not is_instance_valid(target):
		return
	var wall := SpectralWall.line(center, across, WALL_LENGTH, WALL_TIME)
	wall.target = target
	wall.touched.connect(_wall_touched)
	warning_parent.add_child(wall)


## Lucian touched the wall: slowed (once per cast, a line is one piece).
func _wall_touched(_piece: int) -> void:
	if is_instance_valid(target):
		target.add_slow(SLOW_ID, WALL_SLOW, WALL_SLOW_TIME)


func _draw() -> void:
	super()
	if revived:
		draw_circle(Vector2.ZERO, DEFILE_RADIUS, Color(DEFILE_COLOR, 0.06))
		draw_arc(Vector2.ZERO, DEFILE_RADIUS, 0.0, TAU, 96, Color(DEFILE_COLOR, 0.75), 4.0, true)
	if is_channeling() and is_instance_valid(target):
		# A ring pulsing on Lucian, and one round Karthus filling as the channel goes on.
		var pulse := 0.5 + 0.5 * sin(_channel_left * TAU * PULSE_RATE)
		var on_lucian := to_local(target.global_position)
		draw_arc(on_lucian, lerpf(RING_MIN, RING_MAX, pulse), 0.0, TAU, 48, Color(REQUIEM_COLOR, 0.9), 5.0, true)
		draw_circle(on_lucian, RING_MIN * 0.5, Color(REQUIEM_COLOR, 0.2))
		var done := 1.0 - _channel_left / REQUIEM_TIME
		draw_arc(Vector2.ZERO, radius + 14.0, -PI * 0.5, -PI * 0.5 + TAU * done, 64, REQUIEM_COLOR, 5.0, true)

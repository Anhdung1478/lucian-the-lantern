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
var _vfx_time := 0.0


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
	_vfx_time += delta
	_keep_defile()
	if revived:
		queue_redraw()
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
	if (revived and busy_left <= 0.0 and can_fight() and distance_to_target() > REVIVED_STOP
			and distance_to_target() <= attack_range + Lucian.HIT_RADIUS):
		walk_toward(target.global_position, delta)


## Defile, on every frame: the zone is made on the first (a sibling can't be
## added while the stage is still adding him) and kept on him.
func _keep_defile() -> void:
	if not revived:
		return
	if _defile == null:
		_defile = HazardZone.burning(DEFILE_DPS * skill_scale, DamageInfo.Type.MAGIC)
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
	warning.fired.connect(_lay_blast_vfx.bind(at))
	warning_parent.add_child(warning)


func _lay_blast_vfx(at: Vector2) -> void:
	if not Juice.on() or not is_alive():
		return
	var blast := _LayWasteVfx.new()
	blast.setup(at, LAY_RADIUS)
	warning_parent.add_child(blast)


## The channel ends early: "Broken!" over him, and he recovers.
func _break() -> void:
	_channel_left = 0.0
	_channel_damage = 0.0
	busy_left = RECOVER
	_spend_thresholds()
	var note := FloatingText.new(Lang.t("Broken!"), BROKEN_COLOR)
	note.position = global_position + BROKEN_AT
	warning_parent.add_child(note)
	queue_redraw()


## Nobody broke it: the hit lands on Lucian (Banshee's Veil blocks it).
func _finish_requiem() -> void:
	_channel_damage = 0.0
	busy_left = RECOVER
	_spend_thresholds()
	if is_instance_valid(target):
		if Juice.on():
			var pillar := _RequiemDetonateVfx.new()
			pillar.setup(target.global_position)
			warning_parent.add_child(pillar)
		target.take_damage(skill_hit(REQUIEM_DAMAGE, DamageInfo.Type.MAGIC, &"requiem"))
	queue_redraw()


func _raise_wall(center: Vector2, across: Vector2) -> void:
	if dead or not is_instance_valid(target):
		return
	var wall := SpectralWall.line(center, across, WALL_LENGTH, WALL_TIME)
	wall.target = target
	wall.style = SpectralWall.Style.KARTHUS
	wall.touched.connect(_wall_touched)
	warning_parent.add_child(wall)


## Lucian touched the wall: slowed (once per cast, a line is one piece).
func _wall_touched(_piece: int) -> void:
	if is_instance_valid(target):
		target.add_slow(SLOW_ID, WALL_SLOW, WALL_SLOW_TIME)


func _draw() -> void:
	super()
	if revived:
		# Enriched Defile: translucent dark-violet necromantic mist arcs & drifting ghostly soul-embers.
		draw_circle(Vector2.ZERO, DEFILE_RADIUS, Color(DEFILE_COLOR, 0.08))
		draw_circle(Vector2.ZERO, DEFILE_RADIUS * 0.55, Color("4b1e7a", 0.07))
		for i in 4:
			var r_arc := DEFILE_RADIUS * (0.42 + 0.16 * i)
			var spin := _vfx_time * (1.2 - 0.18 * i) * (1.0 if i % 2 == 0 else -1.0) + i * 1.6
			var span := 1.4 + 0.35 * sin(_vfx_time * 2.2 + i)
			draw_arc(Vector2.ZERO, r_arc, spin, spin + span, 28, Color("6c2fb8", 0.24), 10.0, true)
			draw_arc(Vector2.ZERO, r_arc, spin + 0.12, spin + span - 0.12, 24, Color("56e8dc", 0.28), 2.5, true)
		for i in 10:
			var ang := _vfx_time * (0.6 + 0.08 * (i % 3)) + i * TAU / 10.0
			var dist := DEFILE_RADIUS * (0.3 + 0.62 * fmod(i * 0.382, 1.0))
			var bob := sin(_vfx_time * 3.5 + i * 1.7) * 14.0
			var ember := Vector2(cos(ang) * dist, sin(ang) * dist + bob)
			var col := Color("78ffe8", 0.55) if i % 2 == 0 else Color("c996ff", 0.55)
			draw_circle(ember, 6.5, Color(col, 0.2))
			draw_circle(ember, 2.8, col)
		draw_arc(Vector2.ZERO, DEFILE_RADIUS, 0.0, TAU, 96, Color(DEFILE_COLOR, 0.78), 4.0, true)
		draw_arc(Vector2.ZERO, DEFILE_RADIUS - 6.0, 0.0, TAU, 72, Color("64f0e0", 0.28), 1.8, true)
	if is_channeling() and is_instance_valid(target):
		# Towering translucent spectral death-beam descending from -650px onto Lucian,
		# narrowing and intensifying as Requiem nears detonation.
		var pulse := 0.5 + 0.5 * sin(_channel_left * TAU * PULSE_RATE)
		var on_lucian := to_local(target.global_position)
		var done := 1.0 - _channel_left / REQUIEM_TIME
		var beam_top := on_lucian + Vector2(0.0, -650.0)
		var beam_w := lerpf(88.0, 24.0, done)
		var beam_alpha := lerpf(0.28, 0.78, done)
		draw_line(beam_top, on_lucian, Color("7b3cff", beam_alpha * 0.42), beam_w * 1.45, true)
		draw_line(beam_top, on_lucian, Color(REQUIEM_COLOR, beam_alpha * 0.75), beam_w * 0.68, true)
		draw_line(beam_top, on_lucian, Color("7efce8", beam_alpha * 0.85), maxf(beam_w * 0.24, 4.0), true)
		draw_line(beam_top, on_lucian, Color("f6f0ff", beam_alpha), maxf(beam_w * 0.1, 2.0), true)
		# Swirling violet-cyan rune rings spiralling down the death-beam toward Lucian.
		for i in 3:
			var fall_frac := fposmod(done * 2.8 + i * 0.333, 1.0)
			var y_pos := lerpf(-600.0, -10.0, fall_frac)
			var ring_c := on_lucian + Vector2(0.0, y_pos)
			var rx := beam_w * (0.62 + 0.18 * (1.0 - fall_frac))
			var ry := rx * 0.3
			var ring_pts := PackedVector2Array()
			for k in 25:
				var a := k * TAU / 24.0 + _vfx_time * 5.0 * (1.0 if i % 2 == 0 else -1.0)
				ring_pts.append(ring_c + Vector2(cos(a) * rx, sin(a) * ry))
			var ring_col := Color("66ffe8", beam_alpha * 0.85) if i % 2 == 0 else Color("d6b3ff", beam_alpha * 0.85)
			draw_polyline(ring_pts, ring_col, 2.4, true)
		# Pulsing target ring on Lucian + channel progress ring around Karthus.
		draw_arc(on_lucian, lerpf(RING_MIN, RING_MAX, pulse), 0.0, TAU, 48, Color(REQUIEM_COLOR, 0.92), 5.0, true)
		draw_arc(on_lucian, lerpf(RING_MIN, RING_MAX, 1.0 - pulse) * 0.78, 0.0, TAU, 36, Color("66ffe8", 0.55 + 0.35 * done), 2.5, true)
		draw_circle(on_lucian, RING_MIN * (0.45 + 0.25 * done), Color(REQUIEM_COLOR, 0.22 + 0.2 * done))
		draw_arc(Vector2.ZERO, radius + 14.0, -PI * 0.5, -PI * 0.5 + TAU * done, 64, REQUIEM_COLOR, 5.0, true)


class _LayWasteVfx extends Node2D:
	const LIFETIME := 0.32
	var _elapsed := 0.0
	var _radius := 110.0
	var _shards: Array[Dictionary] = []

	func setup(at: Vector2, blast_radius: float) -> void:
		position = at
		_radius = blast_radius
		z_index = 6
		for i in 10:
			var ang := TAU * float(i) / 10.0 + randf_range(-0.15, 0.15)
			_shards.append({
				"dir": Vector2.from_angle(ang),
				"speed": randf_range(blast_radius * 1.4, blast_radius * 2.4),
				"size": randf_range(5.0, 9.0),
			})

	func _process(delta: float) -> void:
		_elapsed += delta
		if _elapsed >= LIFETIME:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var t := clampf(_elapsed / LIFETIME, 0.0, 1.0)
		var ease_out := 1.0 - pow(1.0 - t, 2.5)
		var alpha := 1.0 - t
		var cur_r := _radius * (0.3 + 0.78 * ease_out)
		# Ghostly emerald-violet skittle rune explosion.
		draw_circle(Vector2.ZERO, cur_r * 0.8, Color("5a269c", alpha * 0.32))
		draw_circle(Vector2.ZERO, cur_r * 0.42, Color("52ffdc", alpha * 0.65))
		draw_arc(Vector2.ZERO, cur_r, 0.0, TAU, 44, Color("b57bff", alpha * 0.92), lerpf(8.0, 1.8, t), true)
		# Flaring arcane diamond-star rune sigil.
		var sigil := PackedVector2Array()
		for i in 10:
			var ang := i * TAU / 10.0 + t * 1.2
			var rad := (cur_r * 0.85) if i % 2 == 0 else (cur_r * 0.32)
			sigil.append(Vector2.from_angle(ang) * rad)
		draw_colored_polygon(sigil, Color("84ffea", alpha * 0.55))
		draw_polyline(sigil + PackedVector2Array([sigil[0]]), Color("efe6ff", alpha * 0.9), 2.0, true)
		# Spectral shards erupting outward.
		for s: Dictionary in _shards:
			var pos: Vector2 = s.dir * (s.speed * _elapsed * (1.0 - t * 0.35))
			var f: Vector2 = s.dir
			var p := f.orthogonal()
			var sz: float = s.size * (1.0 - t * 0.45)
			var shard := PackedVector2Array([pos + f * sz, pos + p * (sz * 0.38), pos - f * sz, pos - p * (sz * 0.38)])
			draw_colored_polygon(shard, Color("72ffea", alpha * 0.9))


class _RequiemDetonateVfx extends Node2D:
	const LIFETIME := 0.55
	var _elapsed := 0.0

	func setup(at: Vector2) -> void:
		position = at
		z_index = 9

	func _process(delta: float) -> void:
		_elapsed += delta
		if _elapsed >= LIFETIME:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var t := clampf(_elapsed / LIFETIME, 0.0, 1.0)
		var ease_out := 1.0 - pow(1.0 - t, 2.8)
		var alpha := 1.0 - pow(t, 1.35)
		var top := Vector2(0.0, -700.0)
		# Towering Requiem detonation pillar flash.
		var w := lerpf(118.0, 12.0, t)
		draw_line(top, Vector2.ZERO, Color("7e38ff", alpha * 0.45), w * 1.4, true)
		draw_line(top, Vector2.ZERO, Color("66ffe8", alpha * 0.85), w * 0.65, true)
		draw_line(top, Vector2.ZERO, Color.WHITE * Color(1, 1, 1, alpha), maxf(w * 0.28, 3.0), true)
		# Ground shockwave rings & upward-spiralling soul streaks.
		var ring_r := lerpf(32.0, 190.0, ease_out)
		draw_circle(Vector2.ZERO, lerpf(80.0, 20.0, t), Color("a8fff2", alpha * 0.65))
		draw_arc(Vector2.ZERO, ring_r, 0.0, TAU, 56, Color("b57bff", alpha * 0.95), lerpf(12.0, 2.0, t), true)
		draw_arc(Vector2.ZERO, ring_r * 0.72, 0.0, TAU, 48, Color("70ffe8", alpha * 0.85), lerpf(6.0, 1.0, t), true)
		for i in 6:
			var ang := i * TAU / 6.0 + t * 5.0
			var x := cos(ang) * lerpf(55.0, 14.0, t)
			var y0 := -t * 420.0 - i * 45.0
			draw_line(Vector2(x, y0), Vector2(x * 0.7, y0 - 75.0), Color("d6fff8", alpha * 0.85), 3.0, true)

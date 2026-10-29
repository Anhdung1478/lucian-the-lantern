class_name Specter
extends EnemyUnit
## Acts 5 and 6's enemies with a move of their own, by behavior. Bomber
## (the sapling): runs at Lucian; within its range it stops, marks a circle
## on its own spot, and when the mark fires it blasts everything inside and
## vanishes (no rewards). Killed before that, the mark goes and the kill pays
## as any. Charger (the Spectral Rider): marks a line toward Lucian, then runs
## along it, hitting and shoving him; walls and the abyss stop it. Warden (the
## Chain Warden): keeps its distance (a perched one stays put), marks a line,
## then a chain flies along it that pulls Lucian in. Any other behavior walks
## in and hits, as EnemyUnit does.

## Bomber: the blast's radius, and the seconds its warning shows.
const BLAST_RADIUS := 120.0
const BLAST_WARN := 0.6

## Charger: the line's length (also how far it runs), its width, and the
## seconds it shows; its run speed; the hit it lands (the data's damage) shoves
## Lucian this far along the run, at this speed.
const CHARGE_LENGTH := 800.0
const CHARGE_WIDTH := 90.0
const CHARGE_WARN := 0.8
const CHARGE_SPEED := 1400.0
const CHARGE_PUSH := 150.0
const CHARGE_PUSH_SPEED := 1600.0
## Charger: between charges it walks in, but stops this far from Lucian.
const CHARGE_CLOSE := 250.0

## Warden: the line's length (the chain's reach), its width, and the seconds it
## shows; the chain's speed; a hit pulls Lucian this far toward the warden, at
## this speed (Thresh's hook speed).
const CHAIN_LENGTH := 700.0
const CHAIN_WIDTH := 60.0
const CHAIN_WARN := 0.8
const CHAIN_SPEED := 1200.0
const CHAIN_PULL := 300.0
const CHAIN_PULL_SPEED := 1600.0
const CHAIN_COLOR := Color("8fe3b0")

## Bomber: the circle on the ground, while it runs. Charger and warden: the
## line, from its marking until it fires.
var _blast: GroundWarning
var _mark: GroundWarning


func _think(delta: float) -> void:
	match data.behavior:
		&"bomber":
			_bomber(delta)
		&"charger":
			_charger(delta)
		&"warden":
			_warden(delta)
		_:
			super(delta)


## Runs at Lucian. In range it stands, faces him and marks its blast, once.
func _bomber(delta: float) -> void:
	if is_instance_valid(_blast):
		face(target.global_position)
		return
	if distance_to_target() > attack_range + Lucian.HIT_RADIUS:
		walk_toward(target.global_position, delta)
		return
	face(target.global_position)
	# On its own spot, so it reads as the sapling going off; Lucian is
	# within its range, well inside the radius, unless he runs.
	_blast = GroundWarning.circle(global_position, BLAST_RADIUS, BLAST_WARN)
	_blast.strike(make_hit(), target)
	_blast.fired.connect(vanish)
	warning_parent.add_child(_blast)


## Walks in until Lucian is within its range (and no closer than CHARGE_CLOSE
## when the charge is not ready); with the attack ready it marks the line
## toward him, stands while it shows, then runs along it.
func _charger(delta: float) -> void:
	if is_instance_valid(_mark):
		return
	var distance := distance_to_target()
	# A perched rider can't charge (charge() refuses), so it never marks.
	if perched:
		face(target.global_position)
		return
	if _attack_left > 0.0 or distance > attack_range + Lucian.HIT_RADIUS:
		face(target.global_position)
		if distance > attack_range + Lucian.HIT_RADIUS or (_attack_left > 0.0 and distance > CHARGE_CLOSE):
			walk_toward(target.global_position, delta)
		return
	_attack_left = data.attack_interval
	var toward := global_position.direction_to(target.global_position)
	face(target.global_position)
	_mark = GroundWarning.line(global_position, toward, CHARGE_LENGTH, CHARGE_WIDTH, CHARGE_WARN)
	_mark.fired.connect(_run.bind(toward))
	warning_parent.add_child(_mark)


## The mark fired: along its line, hitting Lucian once if he is still there.
func _run(toward: Vector2) -> void:
	_mark = null
	charge(toward, CHARGE_LENGTH, CHARGE_SPEED, _trample.bind(toward))


## The charge reached Lucian: the hit, and (if he took it) a shove along the run.
func _trample(toward: Vector2) -> void:
	if target.take_damage(make_hit()):
		target.displace(target.global_position + toward * CHARGE_PUSH, CHARGE_PUSH_SPEED)


## Keeps keep_min..keep_max from Lucian like a spitter (a perched warden only
## turns to him). In range with the attack ready it marks a line toward him,
## stands while it shows, then the chain flies.
func _warden(delta: float) -> void:
	if is_instance_valid(_mark):
		return
	var distance := distance_to_target()
	if distance <= attack_range + Lucian.HIT_RADIUS and _attack_left <= 0.0:
		_attack_left = data.attack_interval
		var toward := global_position.direction_to(target.global_position)
		face(target.global_position)
		_mark = GroundWarning.line(global_position, toward, CHAIN_LENGTH, CHAIN_WIDTH, CHAIN_WARN)
		_mark.fired.connect(_throw_chain.bind(toward))
		warning_parent.add_child(_mark)
	elif distance > data.keep_max:
		walk_toward(target.global_position, delta)
	elif distance < data.keep_min:
		walk(target.global_position.direction_to(global_position), delta)
	else:
		face(target.global_position)


## The chain flies along the marked line; a hit (a refused hit, Lucian invulnerable, pulls nobody)
## pulls Lucian toward the warden.
func _throw_chain(toward: Vector2) -> void:
	_mark = null
	var chain := fire_bolt(make_hit(), CHAIN_SPEED, CHAIN_LENGTH, toward)
	chain.hit_radius = CHAIN_WIDTH * 0.5
	chain.color = CHAIN_COLOR
	chain.tether = self
	chain.hit_lucian.connect(_pull)


## Lucian slides toward the warden, CHAIN_PULL at most and never closer than
## the warden's radius plus his own (he stops in front of it, as at Thresh's
## hook); the abyss edge or a wall stops him sooner. A chain thrown before the
## warden fell pulls toward nothing.
func _pull() -> void:
	if not is_instance_valid(target) or not is_alive():
		return
	var stop := radius + Lucian.HIT_RADIUS
	var slide := minf(CHAIN_PULL, maxf(distance_to_target() - stop, 0.0))
	target.displace(target.global_position + target.global_position.direction_to(global_position) * slide, CHAIN_PULL_SPEED)


## Killed first: its marks go with it, with no blast or charge. A warning is
## no physics body, so this is fine from a damage path.
func _die() -> void:
	_drop_blast()
	_drop_mark()
	super()


## A vanish from outside ends the marks too.
func escape() -> void:
	if not has_escaped:
		_drop_blast()
		_drop_mark()
	super()


func _drop_mark() -> void:
	if is_instance_valid(_mark):
		_mark.queue_free()
	_mark = null


func _drop_blast() -> void:
	if is_instance_valid(_blast):
		_blast.fired.disconnect(vanish)
		_blast.queue_free()
	_blast = null

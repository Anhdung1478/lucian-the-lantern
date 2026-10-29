class_name Specter
extends EnemyUnit
## Acts 5 and 6's enemies with a move of their own, by behavior. Bomber
## (the sapling): runs at Lucian; within its range it stops, marks a circle
## on its own spot, and when the mark fires it blasts everything inside and
## vanishes (no rewards). Killed before that, the mark goes and the kill pays
## as any. Charger and warden come with Act 6; until then any other behavior
## walks in and hits, as EnemyUnit does.

## Bomber: the blast's radius, and the seconds its warning shows.
const BLAST_RADIUS := 120.0
const BLAST_WARN := 0.6

## Bomber: the circle on the ground, while it runs.
var _blast: GroundWarning


func _think(delta: float) -> void:
	match data.behavior:
		&"bomber":
			_bomber(delta)
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


## Killed first: its mark goes with it, with no blast. A warning is no
## physics body, so this is fine from a damage path.
func _die() -> void:
	_drop_blast()
	super()


## A vanish from outside ends the mark too.
func escape() -> void:
	if not has_escaped:
		_drop_blast()
	super()


func _drop_blast() -> void:
	if is_instance_valid(_blast):
		_blast.fired.disconnect(vanish)
		_blast.queue_free()
	_blast = null

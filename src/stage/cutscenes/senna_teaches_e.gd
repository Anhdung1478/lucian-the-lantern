class_name SennaTeachesE
extends Cutscene
## Act 1's first break: Senna dashes to the side and back to show Lucian how,
## and he learns Relentless Pursuit (E). The stage teaches him the skill when
## the scene is done, skipped or not; the break's countdown waits for it.

## Senna's dash: this far to the side, and how long each way takes.
const DASH_LENGTH := 260.0
const DASH_TIME := 0.18
const PAUSE := 0.35


func _play() -> void:
	var senna := stage.senna
	var lucian := stage.lucian
	await pan_to((senna.global_position + lucian.global_position) * 0.5)
	if skipped:
		return
	await caption("Senna", "Thresh's hook is slow, but you can't dodge it standing still. Watch my feet.")
	if skipped:
		return
	var start := senna.global_position
	var side := start.direction_to(lucian.global_position).orthogonal()
	await _dash(senna, start + side * DASH_LENGTH)
	if skipped:
		return
	await wait(PAUSE)
	if skipped:
		return
	await _dash(senna, start)
	if skipped:
		return
	await caption("Senna", "Dash, then shoot. Your next shot is ready the moment you land.")
	if skipped:
		return
	await caption("", "Lucian learns Relentless Pursuit. Press %s to dash toward the cursor." % GameSettings.instance().key_label(&"skill_e"))


## Senna dashes to `to`, a light trail growing behind her.
func _dash(senna: Senna, to: Vector2) -> void:
	var from := senna.global_position
	var trail := DashTrail.new()
	trail.setup(from)
	add_prop(trail)
	senna.visuals.rotation = from.direction_to(to).angle()
	var glide := func(share: float) -> void:
		senna.global_position = from.lerp(to, share)
		trail.reach(senna.global_position)
	var dash := animate()
	dash.tween_method(glide, 0.0, 1.0, DASH_TIME)
	await step(dash)
	if not skipped:
		trail.finish()

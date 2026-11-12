class_name ClassicBeam
extends FxBeam
## Classic's Q: the Sentinel's light. A white-hot core in a gold body with a
## thin teal edge and a star of light at the muzzle. Light motes drift off
## it, and it fades from Lucian's end outward.

const EDGE := Color(UiStyle.LANTERN_COLOR, 0.8)
const BODY := Color(UiStyle.GOLD_COLOR, 0.4)
const CORE := Color(1.0, 0.95, 0.75, 0.9)
const CENTER := Color.WHITE
const MOTE := Color(1.0, 0.93, 0.65, 0.7)
## The beam is drawn in this many pieces, each fading at its own time.
const SEGMENTS := 16
## The share of LIFETIME the fade takes to travel from one end to the other.
const FADE_SPREAD := 0.4
## Thickness of the teal edge, in px.
const EDGE_WIDTH := 3.0
## The muzzle star shows this many seconds.
const FLARE_TIME := 0.15
const FLARE_RADIUS := 34.0
## One mote for every this many px of beam, at most MOTES.
const MOTE_STEP := 70.0
const MOTES := 14


func _start() -> void:
	for i in mini(int(length / MOTE_STEP), MOTES):
		var at := Vector2(randf_range(0.0, length), randf_range(-width * 0.4, width * 0.4))
		var drift := Vector2(randf_range(-10.0, 30.0), randf_range(-60.0, 60.0))
		sparks.emit(at, drift, randf_range(0.35, 0.55), randf_range(1.5, 3.0), MOTE)


func details() -> int:
	return sparks.size() + (1 if not low and age < FLARE_TIME else 0)


## The alpha of the piece `share` (0 at Lucian, 1 at the far end) of the way
## along: Lucian's end goes first. On Low effects the whole beam fades as one.
func piece_alpha(share: float) -> float:
	if low:
		return fade()
	return 1.0 - clampf((progress() - FADE_SPREAD * share) / (1.0 - FADE_SPREAD), 0.0, 1.0)


func _draw() -> void:
	var step := length / SEGMENTS
	for i in SEGMENTS:
		var a := piece_alpha((i + 0.5) / SEGMENTS)
		if a <= 0.0:
			continue
		var x := i * step
		draw_rect(Rect2(x, -width * 0.5, step, width), Color(BODY, BODY.a * a))
		draw_rect(Rect2(x, -width * 0.5, step, EDGE_WIDTH), Color(EDGE, EDGE.a * a))
		draw_rect(Rect2(x, width * 0.5 - EDGE_WIDTH, step, EDGE_WIDTH), Color(EDGE, EDGE.a * a))
		draw_rect(Rect2(x, -width * 0.22, step, width * 0.44), Color(CORE, CORE.a * a))
		draw_rect(Rect2(x, -width * 0.08, step, width * 0.16), Color(CENTER, a))
	if low:
		return
	sparks.draw_on(self)
	if age < FLARE_TIME:
		var t := age / FLARE_TIME
		ClassicStar.draw(self, Vector2.ZERO, FLARE_RADIUS * (1.0 - 0.3 * t), PI / 4.0, Color(CENTER, 0.8 * (1.0 - t)))
		ClassicStar.draw(self, Vector2.ZERO, FLARE_RADIUS * 0.7, 0.0, Color(EDGE, 0.6 * (1.0 - t)))

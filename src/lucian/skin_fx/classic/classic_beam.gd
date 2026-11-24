class_name ClassicBeam
extends FxBeam
## Classic's Q: the Sentinel's light. A sculpted white-gold piercing lance with
## shimmering teal outer ribbons, a blazing muzzle star at x = 0, a tapered
## lance tip, drifting golden light motes, and a wave fade from Lucian outward.

const EDGE := Color(UiStyle.LANTERN_COLOR, 0.85)
const BODY := Color(UiStyle.GOLD_COLOR, 0.52)
const CORE := Color(1.0, 0.96, 0.78, 0.94)
const CENTER := Color.WHITE
const MOTE := Color(1.0, 0.93, 0.65, 0.82)
## Stations along the beam for the smooth wave-fade and tapered lance silhouette.
const SEGMENTS := 16
## The share of LIFETIME the fade takes to travel from one end to the other.
const FADE_SPREAD := 0.4
## The muzzle star shows this many seconds.
const FLARE_TIME := 0.18
const FLARE_RADIUS := 36.0
## One mote for every this many px of beam, at most MOTES.
const MOTE_STEP := 58.0
const MOTES := 16


func _start() -> void:
	for i in mini(int(length / MOTE_STEP), MOTES):
		var at := Vector2(randf_range(16.0, length), randf_range(-width * 0.42, width * 0.42))
		var drift := Vector2(randf_range(-10.0, 35.0), randf_range(-65.0, 65.0))
		sparks.emit(at, drift, randf_range(0.32, 0.52), randf_range(1.6, 3.2), MOTE)


func details() -> int:
	return sparks.size() + (1 if not low and age < FLARE_TIME else 0)


## The alpha of the piece `share` (0 at Lucian, 1 at the far end) of the way
## along: Lucian's end goes first. On Low effects the whole beam fades as one.
func piece_alpha(share: float) -> float:
	if low:
		return fade()
	return 1.0 - clampf((progress() - FADE_SPREAD * share) / (1.0 - FADE_SPREAD), 0.0, 1.0)


func _draw() -> void:
	if length <= 1.0 or width <= 1.0:
		return
	var xs := PackedFloat32Array()
	var w_outer := PackedFloat32Array()
	var w_core := PackedFloat32Array()
	var w_center := PackedFloat32Array()
	var alphas := PackedFloat32Array()
	var any_lit := false
	for i in SEGMENTS + 1:
		var share := float(i) / SEGMENTS
		var x := share * length
		var a := piece_alpha(share)
		if a > 0.001:
			any_lit = true
		var profile := _taper(share)
		xs.append(x)
		w_outer.append(width * 0.58 * profile)
		w_core.append(width * 0.28 * profile)
		w_center.append(width * 0.11 * profile)
		alphas.append(a)
	if any_lit:
		LaserBeam.draw_ribbon_strip(self, xs, w_outer, alphas, BODY, true)
		LaserBeam.draw_ribbon_strip(self, xs, w_core, alphas, CORE, true)
		LaserBeam.draw_ribbon_strip(self, xs, w_center, alphas, CENTER, false)
		# Shimmering teal Sentinel edge ribbons hugging the sculpted beam silhouette.
		var top_pts := PackedVector2Array()
		var bot_pts := PackedVector2Array()
		for i in SEGMENTS:
			var s0 := float(i) / SEGMENTS
			var s1 := float(i + 1) / SEGMENTS
			var seg_a := piece_alpha((s0 + s1) * 0.5)
			if seg_a <= 0.01:
				continue
			var wave := 0.0 if low else sin(s0 * 14.0 - age * 36.0) * 2.2
			var y0 := width * 0.42 * _taper(s0) + wave
			var y1 := width * 0.42 * _taper(s1) + wave
			var col := Color(EDGE, EDGE.a * seg_a)
			draw_line(Vector2(xs[i], -y0), Vector2(xs[i + 1], -y1), col, 2.4, true)
			draw_line(Vector2(xs[i], y0), Vector2(xs[i + 1], y1), col, 2.4, true)
			if not low:
				top_pts.append(Vector2(xs[i], -y0 * 0.65))
				bot_pts.append(Vector2(xs[i], y0 * 0.65))
		var muzzle_a := piece_alpha(0.0)
		if muzzle_a > 0.01:
			LaserBeam.draw_muzzle_flare(self, Vector2.ZERO, width * 0.52, Color(BODY, BODY.a * muzzle_a), Color(CENTER, muzzle_a))
	if low:
		return
	sparks.draw_on(self)
	if age < FLARE_TIME:
		var t := age / FLARE_TIME
		var ft := 1.0 - t
		ClassicStar.draw(self, Vector2.ZERO, FLARE_RADIUS * (1.0 - 0.28 * t), PI / 4.0, Color(CENTER, 0.9 * ft), 0.18)
		ClassicStar.draw(self, Vector2.ZERO, FLARE_RADIUS * 0.82 * (1.0 - 0.15 * t), 0.0, Color(EDGE, 0.72 * ft), 0.2)


func _taper(share: float) -> float:
	if share < 0.04:
		return lerpf(0.62, 1.06, share / 0.04)
	if share > 0.86:
		return lerpf(0.92, 0.0, (share - 0.86) / 0.14)
	return lerpf(1.06, 0.92, (share - 0.04) / 0.82)

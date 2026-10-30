class_name Sfx
extends Node
## Placeholder sound effects, synthesized in code (there are no audio files
## yet) and played on the SFX bus from a small pool of players. The stage
## adds one Sfx node; Sfx.play() does nothing without it (e.g. in tests).
## Keeps working while paused, for shop and menu sounds.

const POOL := 12
const MIX_RATE := 22050
## The same sound never starts twice within this many seconds.
const MIN_GAP := 0.035

static var _node: Sfx
static var _streams := {}

var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _last_played := {}


## True when an Sfx node is in the tree.
static func exists() -> bool:
	return _node != null


static func play(sound: StringName, volume_db := 0.0, pitch := 1.0) -> void:
	if _node == null:
		return
	_node._play(sound, volume_db, pitch)


## The generated stream for `sound`, made once and cached.
static func stream(sound: StringName) -> AudioStreamWAV:
	if not _streams.has(sound):
		_streams[sound] = _generate(sound)
	return _streams[sound]


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	for i in POOL:
		var player := AudioStreamPlayer.new()
		player.bus = &"SFX"
		add_child(player)
		_players.append(player)
	_node = self


func _exit_tree() -> void:
	if _node == self:
		_node = null


func _play(sound: StringName, volume_db: float, pitch: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_played.get(sound, -1.0) < MIN_GAP:
		return
	_last_played[sound] = now
	var player := _players[_next]
	_next = (_next + 1) % POOL
	player.stream = stream(sound)
	player.volume_db = volume_db
	player.pitch_scale = pitch * randf_range(0.96, 1.04)
	player.play()


## True when `sound` has a recipe of its own, not the fallback beep.
static func has_recipe(sound: StringName) -> bool:
	return not _recipe(sound).is_empty()


static func _generate(sound: StringName) -> AudioStreamWAV:
	var samples := _recipe(sound)
	if samples.is_empty():
		samples = _tone(0.05, 440.0, 440.0, 0.0, 0.0, 30.0)
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = bytes
	return wav


## The samples of `sound`'s recipe, or none when it has no recipe.
static func _recipe(sound: StringName) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	match sound:
		&"shot":
			samples = _tone(0.09, 900.0, 300.0, 0.35, 0.55, 30.0)
		&"hit":
			samples = _tone(0.07, 180.0, 90.0, 0.0, 0.5, 40.0)
		&"coin":
			samples = _tone(0.07, 1320.0, 1320.0, 0.0, 0.0, 20.0)
			samples.append_array(_tone(0.14, 1760.0, 1760.0, 0.0, 0.0, 14.0))
		&"potion":
			for i in 4:
				samples.append_array(_tone(0.06, 500.0 + i * 140.0, 700.0 + i * 140.0, 0.0, 0.0, 25.0))
		&"refresh":
			samples = _tone(0.22, 300.0, 1400.0, 0.9, 0.0, 8.0)
		&"error":
			samples = _tone(0.2, 210.0, 190.0, 0.0, 1.0, 6.0)
		&"craft":
			for note in [880.0, 1108.7, 1318.5]:
				samples.append_array(_tone(0.11, note, note, 0.0, 0.0, 12.0))
		&"zap":
			samples = _tone(0.16, 1800.0, 600.0, 0.6, 1.0, 12.0, 70.0)
		&"hurt":
			samples = _tone(0.12, 220.0, 120.0, 0.4, 0.6, 18.0)
		&"hook":
			samples = _tone(0.25, 700.0, 250.0, 0.7, 0.3, 6.0, 40.0)
		&"shell":
			samples = _tone(0.3, 140.0, 50.0, 0.9, 0.2, 7.0)
		&"buff":
			samples = _tone(0.18, 600.0, 1200.0, 0.0, 0.0, 10.0)
		&"freed":
			# A soft rising chime, each note ringing out (a soul set free).
			for note in [659.3, 987.8, 1318.5]:
				samples.append_array(_tone(0.22, note, note * 1.01, 0.0, 0.0, 7.0))
		&"level_up":
			# A bright rising C major chime, its top note ringing out.
			samples = _notes([1046.5, 1318.5, 1568.0], 0.09, 12.0, 0.15, 4.0)
		&"rank_up":
			samples = _notes([987.8, 1480.0], 0.06, 28.0, 0.4)
		&"cast_q":
			# A bright laser zap.
			samples = _tone(0.2, 2600.0, 1100.0, 0.08, 0.35, 13.0, 110.0)
		&"cast_w":
			# A fiery whoosh, then the pop of the missile leaving.
			samples = _tone(0.12, 250.0, 700.0, 0.85, 0.0, 9.0)
			samples.append_array(_tone(0.09, 520.0, 160.0, 0.3, 0.6, 30.0))
		&"cast_e":
			# An airy dash whoosh.
			samples = _tone(0.2, 900.0, 300.0, 0.95, 0.0, 11.0)
		&"wave":
			# A short low horn.
			samples = _tone(0.5, 174.6, 196.0, 0.03, 0.55, 4.0, 6.0)
		&"boss":
			# A deep gong and roar.
			samples = _tone(0.9, 110.0, 55.0, 0.35, 0.4, 3.5, 9.0)
		&"victory":
			# A short fanfare: C E G and a held high C.
			samples = _notes([523.3, 659.3, 784.0, 1046.5], 0.11, 9.0, 0.35, 3.5)
		&"defeat":
			# A falling sting.
			samples = _notes([392.0, 311.1, 233.1], 0.16, 6.0, 0.45, 2.5)
		&"click":
			samples = _tone(0.025, 2200.0, 1800.0, 0.2, 0.0, 120.0)
		&"essence":
			# A quick high sparkle.
			samples = _notes([1760.0, 2637.0, 2217.5, 3520.0], 0.045, 35.0, 0.0, 3.0)

		# --- V1.1 skin sounds: High Noon, hellfire and a revolver ---
		&"cast_q_high_noon":
			# A roaring fire crackle, noisy and falling.
			samples = _as_loud_as(&"cast_q", _tone(0.24, 1400.0, 380.0, 0.75, 0.2, 9.0, 45.0))
		&"cast_w_high_noon":
			# A whoosh, then a heavy thump.
			var whoosh := _tone(0.12, 220.0, 600.0, 0.85, 0.0, 9.0)
			whoosh.append_array(_tone(0.14, 140.0, 60.0, 0.35, 0.5, 18.0))
			samples = _as_loud_as(&"cast_w", whoosh)
		&"cast_e_high_noon":
			# A dusty whoosh and a two-note spur jingle.
			var dash := _tone(0.16, 700.0, 250.0, 0.95, 0.0, 12.0)
			dash.append_array(_notes([2637.0, 3136.0], 0.05, 30.0))
			samples = _as_loud_as(&"cast_e", dash)
		&"shot_high_noon":
			# A low revolver crack.
			samples = _as_loud_as(&"shot", _tone(0.11, 520.0, 140.0, 0.55, 0.6, 26.0))
		# --- V1.1 skin sounds: PROJECT, square-wave synth ---
		&"cast_q_project":
			# A square-wave synth laser with a fast flutter.
			samples = _as_loud_as(&"cast_q", _tone(0.2, 2200.0, 900.0, 0.0, 0.9, 12.0, 60.0))
		&"cast_w_project":
			# A quick rising bleep, then a pop.
			var bleep := _notes([880.0, 1320.0, 1760.0], 0.04, 20.0, 0.9)
			bleep.append_array(_tone(0.07, 600.0, 200.0, 0.2, 0.9, 35.0))
			samples = _as_loud_as(&"cast_w", bleep)
		&"cast_e_project":
			# A stuttering glitch chirp.
			samples = _as_loud_as(&"cast_e", _tone(0.18, 1600.0, 2400.0, 0.3, 0.9, 10.0, 90.0))
		&"shot_project":
			# A short square blip.
			samples = _as_loud_as(&"shot", _tone(0.07, 1400.0, 900.0, 0.0, 0.9, 30.0))
		# --- V1.1 skin sounds: Pulsefire, a shimmering time rift ---
		&"cast_q_pulsefire":
			# A shimmering sweep that rises, then falls.
			var sweep := _tone(0.1, 1200.0, 2600.0, 0.05, 0.2, 6.0, 40.0)
			sweep.append_array(_tone(0.14, 2600.0, 900.0, 0.05, 0.2, 14.0, 40.0))
			samples = _as_loud_as(&"cast_q", sweep)
		&"cast_w_pulsefire":
			# A deep whomp, then a bell ring.
			var whomp := _tone(0.12, 160.0, 90.0, 0.2, 0.3, 14.0)
			whomp.append_array(_tone(0.25, 1568.0, 1568.0, 0.0, 0.0, 9.0))
			samples = _as_loud_as(&"cast_w", whomp)
		&"cast_e_pulsefire":
			# A rising "rewind" whoosh.
			samples = _as_loud_as(&"cast_e", _tone(0.22, 250.0, 1400.0, 0.85, 0.0, 6.0, 30.0))
		&"shot_pulsefire":
			# A soft high pulse with a flutter.
			samples = _as_loud_as(&"shot", _tone(0.08, 1800.0, 1200.0, 0.05, 0.1, 25.0, 70.0))
		# --- V1.1 skin sounds: Vampire, dark and wet ---
		&"cast_q_vampire":
			# A low, wet, falling zap.
			samples = _as_loud_as(&"cast_q", _tone(0.22, 900.0, 220.0, 0.35, 0.4, 11.0, 25.0))
		&"cast_w_vampire":
			# A low splash thump.
			var splash := _tone(0.1, 180.0, 70.0, 0.5, 0.4, 20.0)
			splash.append_array(_tone(0.1, 900.0, 300.0, 0.9, 0.0, 22.0))
			samples = _as_loud_as(&"cast_w", splash)
		&"cast_e_vampire":
			# Three quick wing flaps.
			var flaps := PackedFloat32Array()
			for i in 3:
				flaps.append_array(_tone(0.07, 300.0, 200.0, 0.9, 0.0, 30.0))
			samples = _as_loud_as(&"cast_e", flaps)
		&"shot_vampire":
			# A muffled low crack.
			samples = _as_loud_as(&"shot", _tone(0.1, 420.0, 150.0, 0.45, 0.5, 28.0))
	return samples


## `samples` scaled to the loudest point of `like`'s recipe, so a skin's
## sound is as loud as the Classic one it replaces.
static func _as_loud_as(like: StringName, samples: PackedFloat32Array) -> PackedFloat32Array:
	var target := _peak(_recipe(like))
	var peak := _peak(samples)
	if peak > 0.0:
		for i in samples.size():
			samples[i] *= target / peak
	return samples


## The loudest sample, 0–1.
static func _peak(samples: PackedFloat32Array) -> float:
	var peak := 0.0
	for value in samples:
		peak = maxf(peak, absf(value))
	return peak


## A tone sweeping from `start_hz` to `end_hz` over `seconds`. `noise` mixes
## in white noise, `square` bends the sine toward a square wave, `decay` is
## how fast it fades, and `tremolo_hz` adds a fast flutter (electric zaps).
static func _tone(seconds: float, start_hz: float, end_hz: float, noise: float, square: float,
		decay: float, tremolo_hz := 0.0) -> PackedFloat32Array:
	var count := int(seconds * MIX_RATE)
	var out := PackedFloat32Array()
	out.resize(count)
	var phase := 0.0
	for i in count:
		var t := float(i) / MIX_RATE
		var hz := lerpf(start_hz, end_hz, t / seconds)
		phase += TAU * hz / MIX_RATE
		var wave := sin(phase)
		wave = lerpf(wave, signf(wave), square)
		var value := lerpf(wave, randf_range(-1.0, 1.0), noise)
		var envelope := exp(-decay * t) * minf(t * 400.0, 1.0)
		if tremolo_hz > 0.0:
			envelope *= 0.6 + 0.4 * sin(TAU * tremolo_hz * t)
		out[i] = value * envelope * 0.6
	return out


## Steady notes one after another (chimes and fanfares), each `seconds`
## long; the last one rings `hold` times as long.
static func _notes(hz: Array, seconds: float, decay: float, square := 0.0, hold := 1.0) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for i in hz.size():
		var length := seconds * (hold if i == hz.size() - 1 else 1.0)
		out.append_array(_tone(length, hz[i], hz[i], 0.0, square, decay))
	return out

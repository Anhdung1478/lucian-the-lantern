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


static func _generate(sound: StringName) -> AudioStreamWAV:
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
		&"buff":
			samples = _tone(0.18, 600.0, 1200.0, 0.0, 0.0, 10.0)
		_:
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

class_name Score
extends RefCounted
## The music, made in code as Sfx makes the sound effects: there are no audio
## files. A piece is a loop of a few bars in five layers, played in sync as one
## AudioStreamSynchronized; Music fades each layer in and out on its own:
## - the drone: a low held chord on the tonic that breathes every two bars;
## - the pulse: the piece's drums, louder with more enemies alive;
## - Lucian's voice: the leitmotif, in the piece's mode;
## - Senna's voice: her answer to his call, then a third over his close;
## - the boss layer: low drums and an ostinato for a boss or mini boss wave.
## Piece 0 is the theme of the title and main screens; pieces 1–6 are the
## acts'. Every piece plays the same leitmotif in its own mode, key and tempo.
##
## A piece takes a fraction of a second to render (Music does it off the main
## thread, once, each layer on a thread of its own). The pulse repeats every
## bar and the drone and boss layers every two, so only the voices are rendered
## at full length; every layer's length is a whole number of bars, so the
## loops stay in step.

enum Layer { DRONE, PULSE, LUCIAN, SENNA, BOSS }

const LAYER_COUNT := 5
const MIX_RATE := 22050
## Piece 0: the title and main screens (and Training).
const THEME := 0
const BEATS_PER_BAR := 4
## A drum pattern's steps are sixteenth notes.
const STEPS_PER_BAR := 16
## The drone repeats every this many bars.
const TILE_BARS := 2
## Each layer is rendered at full scale; Music plays its loudest point this
## loud. The drums are sparse, so they peak higher to be heard as well. All
## five at full mix to well under 1.
const LAYER_PEAKS: Array[float] = [0.15, 0.3, 0.18, 0.14, 0.32]
## Samples from a layer's start copied after its loop end: the player reads
## past the loop point to interpolate, and a seamless loop needs them.
const GUARD := 8
## The voices' single-cycle wave tables.
const TABLE_SIZE := 4096
const TABLE_MASK := TABLE_SIZE - 1
## Room after a layer's end for the last notes' tails, folded back onto its start.
const TAIL_SECONDS := 3.0
## A voice holds each note for this share of its beats, then lets it ring out
## over its release: the notes stay apart.
const ARTICULATION := 0.9

const IONIAN: Array[int] = [0, 2, 4, 5, 7, 9, 11]
const MIXOLYDIAN: Array[int] = [0, 2, 4, 5, 7, 9, 10]
const DORIAN: Array[int] = [0, 2, 3, 5, 7, 9, 10]
const AEOLIAN: Array[int] = [0, 2, 3, 5, 7, 8, 10]
const PHRYGIAN: Array[int] = [0, 1, 3, 5, 7, 8, 10]
const LOCRIAN: Array[int] = [0, 1, 3, 5, 6, 8, 10]
const HARMONIC_MINOR: Array[int] = [0, 2, 3, 5, 7, 8, 11]

## Per piece: its mode (the scale's semitones over the tonic), its tonic (the
## MIDI note Lucian's voice starts on), tempo, loop length in bars (8: the
## leitmotif alone; 12 or more: the leitmotif, its echo, then a rest), drone
## (each [semitones over the tonic two octaves down, gain, extra cycles per
## tile: a slow beat against the same note]), and the pulse and boss patterns
## (PATTERNS).
const PIECES := [
	# The theme: D major, calm.
	{"mode": IONIAN, "tonic": 62, "bpm": 66, "bars": 8,
		"drone": [[0, 1.0, 0], [7, 0.45, 0], [12, 0.6, 0], [12, 0.3, 2]], "pulse": &"heartbeat", "boss": &"toll"},
	# Act 1, The Loss: A minor, a slow lament for Senna.
	{"mode": AEOLIAN, "tonic": 57, "bpm": 60, "bars": 8,
		"drone": [[0, 0.9, 0], [12, 0.7, 0], [19, 0.35, 0], [12, 0.3, 2]], "pulse": &"heartbeat", "boss": &"toll"},
	# Act 2, The Sentinels: E Mixolydian, a march (training with Akshan).
	{"mode": MIXOLYDIAN, "tonic": 64, "bpm": 96, "bars": 12,
		"drone": [[0, 1.0, 0], [7, 0.5, 0], [12, 0.5, 0], [12, 0.3, 2]], "pulse": &"march", "boss": &"charge"},
	# Act 3, The Jungle: C Dorian over drums.
	{"mode": DORIAN, "tonic": 60, "bpm": 104, "bars": 12,
		"drone": [[0, 1.0, 0], [7, 0.5, 0], [12, 0.4, 0], [7, 0.25, 2]], "pulse": &"jungle", "boss": &"stampede"},
	# Act 4, The Darkness: B Phrygian, slow and heavy (fear and grief).
	{"mode": PHRYGIAN, "tonic": 59, "bpm": 76, "bars": 8,
		"drone": [[0, 1.0, 0], [7, 0.5, 0], [13, 0.12, 0], [12, 0.4, 2]], "pulse": &"dread", "boss": &"menace"},
	# Act 5, Shadow Isles: F Locrian over a tritone, eerie.
	{"mode": LOCRIAN, "tonic": 65, "bpm": 70, "bars": 8,
		"drone": [[0, 1.0, 0], [6, 0.45, 0], [12, 0.5, 0], [12, 0.3, 3]], "pulse": &"clock", "boss": &"knell"},
	# Act 6, The Lantern: D harmonic minor, driving, the climax.
	{"mode": HARMONIC_MINOR, "tonic": 62, "bpm": 126, "bars": 16,
		"drone": [[0, 1.0, 0], [7, 0.55, 0], [12, 0.5, 0], [15, 0.15, 0]], "pulse": &"drive", "boss": &"final"},
]

## The leitmotif's first 8 bars, each note [degree of the mode, start beat,
## beats]. Lucian calls (bars 1–2), Senna answers (3–4), he goes on (5–6) and
## they close together, she a third above him (7–8). Without her, his call
## goes unanswered.
const LUCIAN_NOTES := [
	[0, 0, 2], [2, 2, 1], [4, 3, 1], [3, 4, 2], [2, 6, 1], [1, 7, 1],
	[0, 16, 1], [2, 17, 1], [4, 18, 2], [6, 20, 1], [5, 21, 1], [4, 22, 2],
	[3, 24, 2], [2, 26, 2], [1, 28, 2], [0, 30, 2],
]
const SENNA_NOTES := [
	[4, 8, 1], [5, 9, 1], [7, 10, 2], [6, 12, 1], [5, 13, 1], [4, 14, 2],
	[5, 24, 2], [4, 26, 2], [3, 28, 2], [2, 30, 2],
]
## A loop longer than 8 bars goes on with this echo of it (bars 9–12), then rests.
const LUCIAN_ECHO := [[4, 32, 4], [2, 36, 4], [3, 40, 4], [0, 44, 4]]
const SENNA_ECHO := [[9, 38, 2], [7, 40, 6]]
## The two voices: their harmonics' gains, attack (s), decay (per second)
## toward the sustain level, release (s) and a second oscillator this much
## sharper (a slow shimmer; 0 for none). Lucian's is warm and reedy; Senna's
## is purer, softer to start and shimmers.
const LUCIAN_VOICE := {"harmonics": [1.0, 0.35, 0.12, 0.05], "attack": 0.05, "decay": 1.5, "sustain": 0.55,
		"release": 0.35, "chorus": 0.0}
const SENNA_VOICE := {"harmonics": [1.0, 0.1, 0.0, 0.03], "attack": 0.12, "decay": 0.8, "sustain": 0.7,
		"release": 0.6, "chorus": 1.004}

## The drum patterns, each [bars, hits]. A hit is [sixteenth step, instrument,
## semitones over the instrument's base note (pitched ones: PITCH_BASE), gain]
## and, when there is a fifth number, it repeats every that many steps to the
## pattern's end.
const PATTERNS := {
	# A slow heartbeat, two a bar.
	&"heartbeat": [1, [[0, &"thump", 0, 1.0], [3, &"thump", 0, 0.55], [8, &"thump", 0, 0.85], [11, &"thump", 0, 0.45]]],
	&"march": [1, [[0, &"kick", 0, 1.0], [8, &"kick", 0, 0.85], [10, &"kick", 0, 0.45], [4, &"rim", 0, 0.7],
		[12, &"rim", 0, 0.7], [2, &"shaker", 0, 0.45, 4]]],
	&"jungle": [1, [[0, &"tom_low", 0, 1.0], [3, &"tom_high", 0, 0.7], [6, &"tom_high", 0, 0.6], [8, &"tom_low", 0, 0.9],
		[11, &"tom_high", 0, 0.7], [14, &"tom_low", 0, 0.6], [0, &"shaker", 0, 0.3, 1], [0, &"shaker", 0, 0.3, 4]]],
	# A minor second in the bass, under a dull beat.
	&"dread": [1, [[0, &"kick", 0, 1.0], [10, &"kick", 0, 0.6], [4, &"tick", 0, 0.35], [12, &"tick", 0, 0.35],
		[0, &"bass", 0, 0.8], [6, &"bass", 1, 0.55]]],
	# A ghostly clock.
	&"clock": [1, [[0, &"tick", 0, 0.6], [4, &"tock", 0, 0.5], [8, &"tick", 0, 0.6], [12, &"tock", 0, 0.5],
		[0, &"thump", 0, 0.7], [7, &"thump", 0, 0.3], [8, &"thump", 0, 0.5]]],
	&"drive": [1, [[0, &"kick", 0, 1.0], [4, &"kick", 0, 0.7], [8, &"kick", 0, 0.9], [12, &"kick", 0, 0.7],
		[4, &"rim", 0, 0.5], [12, &"rim", 0, 0.5], [2, &"shaker", 0, 0.4, 4],
		[0, &"bass", 0, 0.8], [2, &"bass", 0, 0.5], [4, &"bass", 12, 0.6], [6, &"bass", 0, 0.5],
		[8, &"bass", 0, 0.8], [10, &"bass", 0, 0.5], [12, &"bass", 12, 0.6], [14, &"bass", 7, 0.5]]],
	# Thresh's bell, tolling over the timpani.
	&"toll": [2, [[0, &"bell", 0, 1.0], [16, &"bell", 0, 0.75], [0, &"timpani", 0, 1.0], [8, &"timpani", 0, 0.55],
		[16, &"timpani", -5, 0.9], [24, &"timpani", 0, 0.55], [0, &"bass", 0, 0.8], [16, &"bass", -5, 0.7]]],
	&"charge": [2, [[0, &"bass", 0, 0.9, 8], [2, &"bass", 0, 0.6, 8], [4, &"bass", 12, 0.7, 8], [6, &"bass", 7, 0.6, 8],
		[0, &"timpani", 0, 1.0], [16, &"timpani", 0, 0.9], [28, &"timpani", 0, 0.5], [30, &"timpani", 0, 0.65]]],
	&"stampede": [2, [[0, &"tom_low", 0, 0.6, 2], [3, &"tom_high", 0, 0.5, 4], [0, &"timpani", 0, 1.0], [16, &"timpani", 7, 0.9],
		[0, &"bass", 0, 0.8], [12, &"bass", 0, 0.5], [16, &"bass", 7, 0.8], [28, &"bass", 0, 0.5]]],
	# The minor second again, slower and lower, under the bell.
	&"menace": [2, [[0, &"bass", 0, 0.9, 8], [4, &"bass", 1, 0.7, 8], [0, &"timpani", 0, 1.0], [16, &"timpani", 0, 0.9],
		[0, &"bell", 0, 0.6]]],
	# The bell over a tritone.
	&"knell": [2, [[0, &"bell", 0, 1.0], [16, &"bell", 6, 0.8], [0, &"timpani", 0, 1.0], [16, &"timpani", 6, 0.8],
		[8, &"thump", 0, 0.6], [24, &"thump", 0, 0.6], [0, &"bass", 0, 0.8], [16, &"bass", 6, 0.7]]],
	# The drive under Thresh's bell: the last fight.
	&"final": [2, [[0, &"bass", 0, 0.9, 8], [2, &"bass", 0, 0.6, 8], [4, &"bass", 12, 0.7, 8], [6, &"bass", 1, 0.6, 8],
		[0, &"timpani", 0, 1.0], [8, &"timpani", 0, 0.6], [16, &"timpani", 0, 0.9], [24, &"timpani", 0, 0.6],
		[0, &"bell", 0, 0.9], [16, &"bell", 0, 0.6]]],
}
## A pitched instrument's base note, in semitones from the piece's tonic.
const PITCH_BASE := {&"bass": -24, &"timpani": -12, &"bell": -12}


## The piece's five layers, rendered and looped, in Layer order, all on this
## thread (Music renders them side by side instead).
static func render(piece: int) -> AudioStreamSynchronized:
	var wavs: Array[AudioStreamWAV] = []
	for layer in LAYER_COUNT:
		wavs.append(to_wav(render_layer(piece, layer)))
	return stream_of(wavs)


## The five layers' loops, in Layer order, as one stream that plays them in sync.
static func stream_of(wavs: Array[AudioStreamWAV]) -> AudioStreamSynchronized:
	var stream := AudioStreamSynchronized.new()
	stream.stream_count = LAYER_COUNT
	for layer in LAYER_COUNT:
		stream.set_sync_stream(layer, wavs[layer])
	return stream


## One layer of the piece as samples, exactly as long as its loop
## (layer_bars). It has a seed of its own, so each layer can render on a
## thread of its own.
static func render_layer(piece: int, layer: Layer) -> PackedFloat32Array:
	var data: Dictionary = PIECES[piece]
	var rng := RandomNumberGenerator.new()
	rng.seed = piece * LAYER_COUNT + layer
	var echo: bool = data.bars > 8
	match layer:
		Layer.DRONE:
			return _drone(piece)
		Layer.PULSE:
			return _drums(piece, data.pulse, rng)
		Layer.BOSS:
			return _drums(piece, data.boss, rng)
		Layer.LUCIAN:
			return _voice(piece, LUCIAN_NOTES + (LUCIAN_ECHO if echo else []), LUCIAN_VOICE)
	return _voice(piece, SENNA_NOTES + (SENNA_ECHO if echo else []), SENNA_VOICE)


## A loop of `samples` as a 16-bit mono WAV, scaled to full scale, looping
## forward from its start to its end.
static func to_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var guarded := samples.duplicate()
	guarded.append_array(samples.slice(0, GUARD))
	var data := guarded.to_byte_array()
	# A float WAV file: the engine's loader turns it into 16 bits (and
	# normalizes it) natively, far faster than a loop here would.
	var file := PackedByteArray()
	file.resize(44)
	file.encode_u32(0, 0x46464952) # "RIFF"
	file.encode_u32(4, 36 + data.size())
	file.encode_u32(8, 0x45564157) # "WAVE"
	file.encode_u32(12, 0x20746d66) # "fmt "
	file.encode_u32(16, 16)
	file.encode_u16(20, 3) # IEEE float
	file.encode_u16(22, 1)
	file.encode_u32(24, MIX_RATE)
	file.encode_u32(28, MIX_RATE * 4)
	file.encode_u16(32, 4)
	file.encode_u16(34, 32)
	file.encode_u32(36, 0x61746164) # "data"
	file.encode_u32(40, data.size())
	file.append_array(data)
	var wav := AudioStreamWAV.load_from_buffer(file, {"edit/normalize": true, "edit/trim": false})
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = samples.size()
	return wav


## Samples in one bar of `piece`: a whole number, so every layer's loop ends
## on the same sample.
static func bar_samples(piece: int) -> int:
	return roundi(MIX_RATE * 60.0 / PIECES[piece].bpm * BEATS_PER_BAR)


## The bars one loop of `layer` lasts.
static func layer_bars(piece: int, layer: Layer) -> int:
	match layer:
		Layer.DRONE:
			return TILE_BARS
		Layer.PULSE:
			return PATTERNS[PIECES[piece].pulse][0]
		Layer.BOSS:
			return PATTERNS[PIECES[piece].boss][0]
	return PIECES[piece].bars


static func hz(midi: float) -> float:
	return 440.0 * pow(2.0, (midi - 69.0) / 12.0)


## The MIDI note of `degree` of the piece's mode (7 and up: the octaves above).
static func degree_note(piece: int, degree: int) -> int:
	var data: Dictionary = PIECES[piece]
	var mode: Array = data.mode
	return data.tonic + mode[degree % mode.size()] + 12 * (degree / mode.size())


## The drone: up to four notes held over TILE_BARS bars, each tuned to a whole
## number of cycles there so the tile loops without a seam, swelling once per
## tile.
static func _drone(piece: int) -> PackedFloat32Array:
	var data: Dictionary = PIECES[piece]
	var size := bar_samples(piece) * TILE_BARS
	# Per note: wave-table steps per sample, and gain. Missing notes are silent.
	var steps := [0.0, 0.0, 0.0, 0.0]
	var gains := [0.0, 0.0, 0.0, 0.0]
	for i in mini(data.drone.size(), 4):
		var note: Array = data.drone[i]
		var cycles: float = roundf(hz(data.tonic - 24 + note[0]) * size / MIX_RATE) + note[2]
		steps[i] = cycles * TABLE_SIZE / size
		gains[i] = note[1]
	var s0: float = steps[0]
	var s1: float = steps[1]
	var s2: float = steps[2]
	var s3: float = steps[3]
	var g0: float = gains[0]
	var g1: float = gains[1]
	var g2: float = gains[2]
	var g3: float = gains[3]
	var breath := float(TABLE_SIZE) / size
	var sine := _table([1.0])
	var out := PackedFloat32Array()
	out.resize(size)
	for i in size:
		var value := g0 * sine[int(s0 * i) & TABLE_MASK] + g1 * sine[int(s1 * i) & TABLE_MASK] \
				+ g2 * sine[int(s2 * i) & TABLE_MASK] + g3 * sine[int(s3 * i) & TABLE_MASK]
		# A cosine: loudest on the tile's first beat.
		out[i] = value * (0.8 + 0.2 * sine[(int(breath * i) + TABLE_SIZE / 4) & TABLE_MASK])
	return out


## One loop of a drum pattern (PATTERNS) in `piece`.
static func _drums(piece: int, pattern: StringName, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var bars: int = PATTERNS[pattern][0]
	var bar := bar_samples(piece)
	var steps := bars * STEPS_PER_BAR
	var size := bar * bars
	var out := _layer(size)
	var made := {}
	for hit: Array in PATTERNS[pattern][1]:
		var instrument: StringName = hit[1]
		var key := "%s %d" % [instrument, hit[2]]
		if not made.has(key):
			var midi: float = PIECES[piece].tonic + PITCH_BASE.get(instrument, 0) + hit[2]
			made[key] = _hit(instrument, hz(midi), rng)
		var every: int = hit[4] if hit.size() > 4 else steps
		for step in range(hit[0], steps, every):
			_mix(out, made[key], roundi(step * bar / float(STEPS_PER_BAR)), hit[3])
	return _fold(out, size)


## One voice's notes over a whole loop of `piece`.
static func _voice(piece: int, notes: Array, voice: Dictionary) -> PackedFloat32Array:
	var size: int = bar_samples(piece) * PIECES[piece].bars
	var out := _layer(size)
	var table := _table(voice.harmonics)
	var beat := bar_samples(piece) / float(BEATS_PER_BAR)
	# One envelope per note length.
	var envelopes := {}
	for note: Array in notes:
		var held := roundi(note[2] * beat * ARTICULATION)
		if not envelopes.has(held):
			envelopes[held] = _envelope(held, voice)
		_add_note(out, roundi(note[1] * beat), hz(degree_note(piece, note[0])), envelopes[held], table, voice.chorus)
	return _fold(out, size)


## A note's loudness, sample by sample: it rises over the voice's attack,
## decays toward the sustain level until `held` samples in, then fades to
## -60 dB over the release.
static func _envelope(held: int, voice: Dictionary) -> PackedFloat32Array:
	var attack := clampi(int(voice.attack * MIX_RATE), 1, held)
	var release := int(voice.release * MIX_RATE)
	var sustain: float = voice.sustain
	var decay := exp(-voice.decay / MIX_RATE)
	var fade := pow(0.001, 1.0 / release)
	var out := PackedFloat32Array()
	out.resize(held + release)
	for i in attack:
		out[i] = float(i) / attack
	var above := 1.0 - sustain
	for i in range(attack, held):
		above *= decay
		out[i] = sustain + above
	var level := out[held - 1]
	for i in range(held, held + release):
		level *= fade
		out[i] = level
	return out


## One note from sample `at`: the voice's wave table read at `note_hz`, shaped
## by `envelope`. With a `chorus` ratio, a second reading that much sharper
## beats slowly against the first (a shimmer).
static func _add_note(out: PackedFloat32Array, at: int, note_hz: float, envelope: PackedFloat32Array,
		table: PackedFloat32Array, chorus: float) -> void:
	var step := note_hz * TABLE_SIZE / MIX_RATE
	var phase := 0.0
	if chorus <= 0.0:
		for i in envelope.size():
			out[at + i] += table[int(phase) & TABLE_MASK] * envelope[i]
			phase += step
		return
	var shimmer_step := step * chorus
	var shimmer := 0.0
	for i in envelope.size():
		out[at + i] += (table[int(phase) & TABLE_MASK] + table[int(shimmer) & TABLE_MASK]) * envelope[i]
		phase += step
		shimmer += shimmer_step


## One cycle of a wave with these harmonics' gains (the first is the fundamental).
static func _table(harmonics: Array) -> PackedFloat32Array:
	var table := PackedFloat32Array()
	table.resize(TABLE_SIZE)
	for i in TABLE_SIZE:
		var angle := TAU * i / TABLE_SIZE
		var value := 0.0
		for h in harmonics.size():
			value += harmonics[h] * sin(angle * (h + 1))
		table[i] = value
	return table


## One drum or struck note. `note_hz` is the piece's note, for the pitched ones.
static func _hit(instrument: StringName, note_hz: float, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	match instrument:
		&"thump":
			out = _sweep(0.35, 95.0, 48.0, 9.0)
		&"kick":
			out = _sweep(0.3, 130.0, 45.0, 13.0)
		&"tom_low":
			out = _sweep(0.4, 165.0, 105.0, 9.0)
		&"tom_high":
			out = _sweep(0.32, 245.0, 165.0, 11.0)
		&"tick":
			out = _sweep(0.05, 2200.0, 2200.0, 90.0)
		&"tock":
			out = _sweep(0.06, 1400.0, 1400.0, 80.0)
		&"rim":
			out = _noisy(0.08, 1000.0, 60.0, 0.5, rng)
		&"shaker":
			out = _noisy(0.09, 0.0, 45.0, 1.0, rng)
		&"bass":
			out = _struck(0.5, note_hz, [1.0, 0.45, 0.15], [1.0, 2.0, 3.0], 6.0)
		&"timpani":
			out = _struck(0.8, note_hz, [1.0, 0.5, 0.3], [1.0, 1.5, 2.0], 4.0)
		&"bell":
			out = _struck(2.0, note_hz, [1.0, 0.5, 0.35, 0.2], [1.0, 2.0, 2.76, 5.4], 1.6)
	_fade_out(out)
	return out


## A sine gliding from `start_hz` to `end_hz` (a drum's pitch drop), dying away
## at `decay` per second after a 2 ms rise.
static func _sweep(seconds: float, start_hz: float, end_hz: float, decay: float) -> PackedFloat32Array:
	var count := int(seconds * MIX_RATE)
	var out := PackedFloat32Array()
	out.resize(count)
	var phase := 0.0
	var glide := pow(end_hz / start_hz, 1.0 / count)
	var step := TAU * start_hz / MIX_RATE
	var level := 1.0
	var fall := exp(-decay / MIX_RATE)
	for i in count:
		out[i] = sin(phase) * level * minf(i / 44.0, 1.0)
		phase += step
		step *= glide
		level *= fall
	return out


## Soft noise (smoothed, so it hisses less) mixed with a sine of `tone_hz`
## (0 for none) by `noise`, dying away at `decay` per second.
static func _noisy(seconds: float, tone_hz: float, decay: float, noise: float, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var count := int(seconds * MIX_RATE)
	var out := PackedFloat32Array()
	out.resize(count)
	var smooth := 0.0
	var level := 1.0
	var fall := exp(-decay / MIX_RATE)
	var step := TAU * tone_hz / MIX_RATE
	for i in count:
		smooth += (rng.randf_range(-1.0, 1.0) - smooth) * 0.5
		out[i] = lerpf(sin(step * i), smooth * 1.5, noise) * level * minf(i / 44.0, 1.0)
		level *= fall
	return out


## A struck note: partials at these ratios of `note_hz` with these gains, each
## dying away (the higher ones faster) after a 3 ms rise.
static func _struck(seconds: float, note_hz: float, gains: Array, ratios: Array, decay: float) -> PackedFloat32Array:
	var count := int(seconds * MIX_RATE)
	var out := PackedFloat32Array()
	out.resize(count)
	var sine := _table([1.0])
	for p in gains.size():
		var step: float = note_hz * ratios[p] * TABLE_SIZE / MIX_RATE
		var fall := exp(-decay * sqrt(ratios[p]) / MIX_RATE)
		var level: float = gains[p]
		var phase := 0.0
		for i in count:
			out[i] += sine[int(phase) & TABLE_MASK] * level * minf(i / 66.0, 1.0)
			phase += step
			level *= fall
	return out


## The last 10 ms of a sound fade to silence, so it never stops with a click.
static func _fade_out(sound: PackedFloat32Array) -> void:
	var length := mini(int(0.01 * MIX_RATE), sound.size())
	for i in length:
		sound[sound.size() - 1 - i] *= float(i) / length


## Adds `sound` × `gain` into `out` from sample `at`.
static func _mix(out: PackedFloat32Array, sound: PackedFloat32Array, at: int, gain: float) -> void:
	for i in sound.size():
		out[at + i] += sound[i] * gain


## An empty layer `size` samples long, with room after it for the tails.
static func _layer(size: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(size + int(TAIL_SECONDS * MIX_RATE))
	return out


## The tails past `size` added back onto the start, so the loop rings on
## through its seam; the layer cut to `size`.
static func _fold(out: PackedFloat32Array, size: int) -> PackedFloat32Array:
	for i in range(size, out.size()):
		out[(i - size) % size] += out[i]
	out.resize(size)
	return out

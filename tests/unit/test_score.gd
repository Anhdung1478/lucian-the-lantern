extends GutTest
## The score's synthesis: each piece's layers, their loops and their levels.
## Two pieces are rendered (the theme and Act 6, the busiest), once for the
## whole file; the rest is checked from the data.

const Layer := Score.Layer

## Piece -> its rendered stream, made in before_all.
var _rendered := {}


func before_all() -> void:
	for piece in [Score.THEME, 6]:
		var start := Time.get_ticks_msec()
		_rendered[piece] = Score.render(piece)
		gut.p("Piece %d rendered in %d ms on one thread" % [piece, Time.get_ticks_msec() - start])


func _wav(piece: int, layer: Layer) -> AudioStreamWAV:
	return (_rendered[piece] as AudioStreamSynchronized).get_sync_stream(layer) as AudioStreamWAV


## The loudest sample of a 16-bit WAV, 0–1.
func _peak(wav: AudioStreamWAV) -> float:
	var data := wav.data
	var peak := 0
	for i in range(0, data.size(), 2):
		peak = maxi(peak, absi(data.decode_s16(i)))
	return peak / 32767.0


# --- The data ---------------------------------------------------------------


func test_there_is_the_theme_and_a_piece_per_act() -> void:
	assert_eq(Score.PIECES.size(), Journey.ACTS.size() + 1)
	assert_eq(Score.THEME, 0)


func test_each_piece_has_its_own_mode_key_or_tempo() -> void:
	var seen := {}
	for piece: Dictionary in Score.PIECES:
		var key := "%s %d %d" % [piece.mode, piece.tonic, piece.bpm]
		assert_false(seen.has(key), key)
		seen[key] = true
		assert_eq((piece.mode as Array).size(), 7, "a seven-note mode")


func test_every_layer_loops_a_whole_number_of_bars_that_divides_the_piece() -> void:
	for piece in Score.PIECES.size():
		var bars: int = Score.PIECES[piece].bars
		assert_true(bars == 8 or bars >= 12, "the leitmotif, and the echo when there is one, fit (piece %d)" % piece)
		for layer in Score.LAYER_COUNT:
			assert_eq(bars % Score.layer_bars(piece, layer), 0, "piece %d layer %d" % [piece, layer])


func test_every_pattern_named_exists_and_every_instrument_sounds() -> void:
	var rng := RandomNumberGenerator.new()
	for piece: Dictionary in Score.PIECES:
		assert_true(Score.PATTERNS.has(piece.pulse), piece.pulse)
		assert_true(Score.PATTERNS.has(piece.boss), piece.boss)
	for pattern: StringName in Score.PATTERNS:
		var bars: int = Score.PATTERNS[pattern][0]
		for hit: Array in Score.PATTERNS[pattern][1]:
			assert_lt(hit[0], bars * Score.STEPS_PER_BAR, "%s: its step is in the pattern" % pattern)
			assert_gt(Score._hit(hit[1], 110.0, rng).size(), 0, "%s: %s has a sound" % [pattern, hit[1]])


func test_the_leitmotif_fits_its_eight_bars_and_the_echo_the_next_four() -> void:
	for note: Array in Score.LUCIAN_NOTES + Score.SENNA_NOTES:
		assert_lte(note[1] + note[2], 8 * Score.BEATS_PER_BAR)
	for note: Array in Score.LUCIAN_ECHO + Score.SENNA_ECHO:
		assert_gte(note[1], 8 * Score.BEATS_PER_BAR)
		assert_lte(note[1] + note[2], 12 * Score.BEATS_PER_BAR)


func test_senna_answers_while_lucian_rests_then_sings_a_third_over_his_close() -> void:
	var lucian_beats := {}
	for note: Array in Score.LUCIAN_NOTES:
		for beat in range(note[1], note[1] + note[2]):
			lucian_beats[beat] = note[0]
	for note: Array in Score.SENNA_NOTES:
		if note[1] < 16:
			assert_false(lucian_beats.has(note[1]), "her answer comes while he rests (beat %d)" % note[1])
		else:
			assert_eq(note[0] - lucian_beats[note[1]], 2, "a third above him (beat %d)" % note[1])


func test_no_layer_alone_plays_near_full_scale() -> void:
	for layer in Score.LAYER_COUNT:
		assert_gt(Score.LAYER_PEAKS[layer], 0.0)
		assert_lt(Score.LAYER_PEAKS[layer], 0.34, "layer %d" % layer)


# --- A rendered piece -------------------------------------------------------


func test_a_rendered_piece_is_five_looping_mono_16_bit_layers() -> void:
	for piece: int in _rendered:
		var stream: AudioStreamSynchronized = _rendered[piece]
		assert_eq(stream.stream_count, Score.LAYER_COUNT)
		for layer in Score.LAYER_COUNT:
			var wav := _wav(piece, layer)
			var loop := Score.layer_bars(piece, layer) * Score.bar_samples(piece)
			assert_eq(wav.format, AudioStreamWAV.FORMAT_16_BITS)
			assert_eq(wav.mix_rate, Score.MIX_RATE)
			assert_false(wav.stereo)
			assert_eq(wav.loop_mode, AudioStreamWAV.LOOP_FORWARD)
			assert_eq(wav.loop_begin, 0)
			assert_eq(wav.loop_end, loop, "piece %d layer %d loops on whole bars" % [piece, layer])
			assert_eq(wav.data.size(), (loop + Score.GUARD) * 2)


func test_the_samples_past_the_loop_end_repeat_its_start() -> void:
	# The player reads past the loop point to interpolate: a seamless seam.
	for layer in Score.LAYER_COUNT:
		var wav := _wav(Score.THEME, layer)
		for i in Score.GUARD:
			assert_eq(wav.data.decode_s16((wav.loop_end + i) * 2), wav.data.decode_s16(i * 2), "layer %d, sample %d" % [layer, i])


func test_each_layer_is_rendered_at_full_scale_and_never_silent() -> void:
	for piece: int in _rendered:
		for layer in Score.LAYER_COUNT:
			assert_gt(_peak(_wav(piece, layer)), 0.95, "piece %d layer %d" % [piece, layer])


func test_the_drone_runs_on_through_its_loop_point() -> void:
	# Its notes are tuned to whole cycles in the tile: no jump at the seam.
	var samples := Score.render_layer(Score.THEME, Layer.DRONE)
	var seam := absf(samples[0] - samples[samples.size() - 1])
	var step := absf(samples[1] - samples[0])
	assert_lt(seam, step + 0.05)


func test_every_layer_at_full_mixes_under_full_scale_and_loops_on() -> void:
	for piece: int in _rendered:
		var stream: AudioStreamSynchronized = _rendered[piece]
		for layer in Score.LAYER_COUNT:
			stream.set_sync_stream_volume(layer, linear_to_db(Score.LAYER_PEAKS[layer]))
		var playback := stream.instantiate_playback()
		playback.start(0.0)
		var rate := AudioServer.get_mix_rate()
		var frames := int(rate * Score.PIECES[piece].bars * Score.bar_samples(piece) / Score.MIX_RATE * 1.1)
		var peak := 0.0
		var energy := 0.0
		var done := 0
		while done < frames:
			for frame in playback.mix_audio(1.0, 4096):
				peak = maxf(peak, absf(frame.x))
				energy += frame.x * frame.x
			done += 4096
		gut.p("Piece %d at full: peak %.2f, RMS %.3f" % [piece, peak, sqrt(energy / done)])
		assert_lt(peak, 1.0, "piece %d never clips" % piece)
		assert_gt(peak, 0.3, "piece %d is heard" % piece)
		assert_true(playback.is_playing(), "piece %d plays on past its loop" % piece)

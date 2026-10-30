extends GutTest
## V1.1's effect building blocks: FxSparks particles, FxPiece timing and Low
## effects, beam and cross sizes, trail growth, and projectiles that show a
## ShotLook instead of drawing themselves.

## Emits one spark that lives 0.4 s.
class SparkPiece extends FxPiece:
	func _start() -> void:
		sparks.emit(Vector2.ZERO, Vector2.ZERO, 0.4, 2.0, Color.WHITE)


## Never stops lingering.
class LingerPiece extends FxPiece:
	func _lingers() -> bool:
		return true


## Records how it grew.
class GrowTrail extends FxTrail:
	var grown: Array[Vector2] = []

	func _grown(from_x: float, to_x: float) -> void:
		grown.append(Vector2(from_x, to_x))


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real settings.
	if GameSettings._instance == null or GameSettings._instance.path == GameSettings.DEFAULT_PATH:
		GameSettings._instance = GameSettings.new("user://test_fx_pieces_settings.json")


func after_each() -> void:
	GameSettings.instance().set_value(&"quality", "high")


func test_sparks_move_fall_and_die() -> void:
	var sparks := FxSparks.new()
	sparks.gravity = Vector2(0, 100)
	sparks.emit(Vector2.ZERO, Vector2(100, 0), 0.5, 2.0, Color.WHITE)
	sparks.step(0.1)
	assert_eq(sparks.size(), 1)
	assert_almost_eq((sparks._items[0].velocity as Vector2).y, 10.0, 0.001)
	assert_almost_eq((sparks._items[0].at as Vector2).x, 10.0, 0.001)
	sparks.step(0.45)
	assert_true(sparks.is_empty())


func test_drag_slows_sparks() -> void:
	var sparks := FxSparks.new()
	sparks.drag = 2.0
	sparks.emit(Vector2.ZERO, Vector2(100, 0), 0.5, 2.0, Color.WHITE)
	sparks.step(0.1)
	assert_almost_eq((sparks._items[0].velocity as Vector2).x, 80.0, 0.001)


func test_sparks_never_live_past_0_6_s() -> void:
	var sparks := FxSparks.new()
	sparks.emit(Vector2.ZERO, Vector2.ZERO, 5.0, 2.0, Color.WHITE)
	sparks.step(0.59)
	assert_eq(sparks.size(), 1)
	sparks.step(0.02)
	assert_true(sparks.is_empty())


func test_a_piece_frees_itself_once_its_lifetime_and_sparks_are_over() -> void:
	var piece := SparkPiece.new()
	piece.lifetime = 0.1
	add_child_autofree(piece)
	assert_eq(piece.details(), 1)
	await wait_seconds(0.2)
	assert_true(is_instance_valid(piece), "its spark is still flying")
	await wait_seconds(0.3)
	assert_false(is_instance_valid(piece))


func test_a_lingering_piece_is_still_gone_by_0_6_s() -> void:
	var piece := LingerPiece.new()
	add_child_autofree(piece)
	await wait_seconds(0.4)
	assert_true(is_instance_valid(piece))
	await wait_seconds(0.3)
	assert_false(is_instance_valid(piece))


func test_on_low_effects_a_piece_makes_no_details() -> void:
	GameSettings.instance().set_value(&"quality", "low")
	var piece := SparkPiece.new()
	add_child_autofree(piece)
	assert_true(piece.low)
	assert_eq(piece.details(), 0)


func test_fade_runs_from_1_to_0_over_the_lifetime() -> void:
	var piece := FxPiece.new()
	piece.lifetime = 0.2
	piece.age = 0.05
	assert_almost_eq(piece.fade(), 0.75, 0.001)
	piece.age = 0.3
	assert_eq(piece.fade(), 0.0)
	piece.free()


func test_beam_and_blast_take_their_sizes_and_classic_lifetimes() -> void:
	var beam := FxBeam.new()
	beam.setup(Vector2(5, 5), Vector2.UP, 300.0, 40.0)
	assert_eq([beam.position, beam.length, beam.width, beam.lifetime], [Vector2(5, 5), 300.0, 40.0, LaserBeam.LIFETIME])
	assert_almost_eq(beam.rotation, Vector2.UP.angle(), 0.0001)
	var blast := FxBlast.new()
	blast.setup(Vector2(1, 2), Vector2.RIGHT, Vector2(400, 60))
	assert_eq([blast.position, blast.bar, blast.lifetime], [Vector2(1, 2), Vector2(400, 60), CrossBlast.LIFETIME])
	beam.free()
	blast.free()


func test_laser_beam_and_cross_blast_show_their_sizes() -> void:
	var beam := LaserBeam.new()
	beam.setup(Vector2.ZERO, Vector2.RIGHT, 300.0, 40.0)
	assert_eq([beam.length, beam.width], [300.0, 40.0])
	var blast := CrossBlast.new()
	blast.setup(Vector2.ZERO, Vector2.RIGHT, Vector2(400, 60))
	assert_eq(blast.bar, Vector2(400, 60))
	beam.free()
	blast.free()


func test_a_trail_reports_each_stretch_it_grew() -> void:
	var trail := GrowTrail.new()
	trail.setup(Vector2.ZERO, DashTrail.LIGHT)
	add_child_autofree(trail)
	trail.reach(Vector2(100, 0))
	trail.reach(Vector2(100, 0))
	trail.reach(Vector2(250, 0))
	assert_eq(trail.grown, [Vector2(0, 100), Vector2(100, 250)] as Array[Vector2])


func test_a_look_knows_its_kind_and_reads_low_effects() -> void:
	var plain := ShotLook.new()
	assert_eq(plain.kind, ShotLook.Kind.BULLET)
	plain.free()
	GameSettings.instance().set_value(&"quality", "low")
	var look := PlainShotLook.new(ShotLook.Kind.MISSILE)
	add_child_autofree(look)
	assert_eq(look.kind, ShotLook.Kind.MISSILE)
	assert_true(look.low)


func test_a_linear_projectile_shows_its_look_instead_of_the_streak() -> void:
	var shot := LinearProjectile.new()
	var look := PlainShotLook.new()
	shot.set_look(look)
	assert_eq(shot.look, look)
	assert_eq(look.get_parent(), shot)
	shot.set_look(null)
	assert_eq(shot.look, look, "null keeps the look")
	shot.free()


func test_an_attack_projectile_shows_its_look_instead_of_the_bolt() -> void:
	var shot := AttackProjectile.new()
	var look := PlainShotLook.new(ShotLook.Kind.BOLT)
	shot.set_look(look)
	assert_eq(shot.look, look)
	assert_eq(look.get_parent(), shot)
	shot.free()

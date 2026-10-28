extends GutTest
## Galeforce's curving missiles.

var dummy: TrainingDummy
var hits := 0


func before_each() -> void:
	hits = 0
	dummy = load("res://src/enemies/training_dummy.tscn").instantiate()
	dummy.position = Vector2(500, 0)
	add_child_autofree(dummy)
	dummy.damage_taken.connect(func(_info: DamageInfo, _final: float) -> void: hits += 1)


func launch(direction: Vector2) -> HomingMissile:
	var missile := HomingMissile.new()
	missile.launch(Vector2.ZERO, direction, dummy, DamageInfo.create(10.0, DamageInfo.Type.MAGIC, &"galeforce"))
	add_child_autofree(missile)
	return missile


func test_a_missile_launched_away_still_curves_onto_the_target() -> void:
	launch(Vector2.LEFT)
	await wait_seconds(1.5)
	assert_eq(hits, 1)


func test_a_missile_curves_instead_of_flying_straight() -> void:
	var missile := launch(Vector2.UP)
	await wait_physics_frames(6)
	assert_lt(missile.global_position.y, -5.0, "it first follows its launch direction")
	await wait_seconds(1.5)
	assert_eq(hits, 1)


func test_a_missile_without_a_target_disappears() -> void:
	var missile := launch(Vector2.RIGHT)
	dummy.free()
	await wait_physics_frames(2)
	assert_false(is_instance_valid(missile))

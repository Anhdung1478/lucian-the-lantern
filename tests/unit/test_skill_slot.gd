extends GutTest

const Slot := ChampionProgress.Slot


func test_full_sweep_covers_whole_square() -> void:
	var points := SkillSlot.sweep_polygon(1.0, 64.0)
	# Center, top middle, four corners, back to top middle.
	assert_eq(points.size(), 7)
	assert_almost_eq(points[1], Vector2(32, 0), Vector2(0.01, 0.01))
	assert_almost_eq(points[2], Vector2(64, 0), Vector2(0.01, 0.01))


func test_quarter_sweep_is_the_top_left_quarter() -> void:
	var points := SkillSlot.sweep_polygon(0.25, 64.0)
	# Starts at 9 o'clock, passes the top-left corner, ends at 12 o'clock.
	assert_eq(points.size(), 4)
	assert_almost_eq(points[1], Vector2(0, 32), Vector2(0.01, 0.01))
	assert_almost_eq(points[2], Vector2(0, 0), Vector2(0.01, 0.01))
	assert_almost_eq(points[3], Vector2(32, 0), Vector2(0.01, 0.01))


func test_rank_up_button_states() -> void:
	var lucian: Lucian = load("res://src/lucian/lucian.tscn").instantiate()
	add_child_autofree(lucian)
	var slots := {}
	for slot in [Slot.Q, Slot.W, Slot.R]:
		var ui := SkillSlot.new()
		ui.setup(lucian, lucian.skills[slot], null, "")
		add_child_autofree(ui)
		slots[slot] = ui
	lucian.progress.set_level(2)
	lucian.try_rank_up(Slot.Q)
	lucian.progress.bought[Slot.W] = 0
	await wait_process_frames(1)
	# One point left: Q rank 2 needs level 3, W's rank isn't bought, R needs 6.
	assert_true(slots[Slot.Q]._plus.visible, "Q shows a +")
	assert_true(slots[Slot.Q]._plus.disabled, "Q's + is grey")
	assert_false(slots[Slot.Q]._plus_locked)
	assert_true(slots[Slot.W]._plus.disabled, "W's + is grey")
	assert_true(slots[Slot.W]._plus_locked, "W's + is locked")
	assert_true(slots[Slot.R]._plus.disabled, "R's + is grey")
	lucian.progress.set_level(3)
	await wait_process_frames(1)
	assert_false(slots[Slot.Q]._plus.disabled, "Q can rank up at level 3")
	lucian.try_rank_up(Slot.Q)
	lucian.try_rank_up(Slot.E)
	await wait_process_frames(1)
	assert_false(slots[Slot.Q]._plus.visible, "no points, no +")


func test_the_passive_slot_locks_when_not_learned() -> void:
	var lucian: Lucian = load("res://src/lucian/lucian.tscn").instantiate()
	add_child_autofree(lucian)
	var ui := SkillSlot.new()
	ui.setup(lucian, null, null, "", SkillSlot.PASSIVE_SIZE)
	add_child_autofree(ui)
	await wait_process_frames(1)
	assert_false(ui._lock.visible, "learned: no lock")
	lucian.passive.learned = false
	await wait_process_frames(1)
	assert_true(ui._lock.visible, "unlearned: locked")

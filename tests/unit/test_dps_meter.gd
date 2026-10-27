extends GutTest

var meter: DpsMeter


func before_each() -> void:
	meter = DpsMeter.new()


func test_empty_meter_reads_zero() -> void:
	assert_eq(meter.dps(), 0.0)
	assert_eq(meter.total, 0.0)


func test_single_hit_counts_over_one_second() -> void:
	meter.record(120.0, 10.0)
	assert_almost_eq(meter.dps(), 120.0, 0.001)


func test_dps_over_session() -> void:
	meter.record(100.0, 10.0)
	meter.record(100.0, 11.0)
	meter.record(100.0, 14.0)
	assert_almost_eq(meter.total, 300.0, 0.001)
	assert_almost_eq(meter.elapsed(), 4.0, 0.001)
	assert_almost_eq(meter.dps(), 75.0, 0.001)


func test_idle_gap_starts_a_new_session() -> void:
	meter.record(100.0, 10.0)
	meter.record(50.0, 16.0)
	assert_almost_eq(meter.total, 50.0, 0.001)
	assert_almost_eq(meter.elapsed(), 0.0, 0.001)


func test_reset() -> void:
	meter.record(100.0, 10.0)
	meter.reset()
	assert_eq(meter.total, 0.0)
	assert_eq(meter.dps(), 0.0)
	meter.record(40.0, 10.5)
	assert_almost_eq(meter.total, 40.0, 0.001)

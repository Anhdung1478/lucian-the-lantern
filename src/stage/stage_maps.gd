class_name StageMaps
extends RefCounted
## The map each act's stages are played on (design doc §13).


static func create(act: int, stage: int) -> StageMap:
	match act:
		1:
			return MidLaneMap.new()
		2:
			return TrainingGroundMap.new(stage)
	return TestArena.new()

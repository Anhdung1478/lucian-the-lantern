class_name StageMaps
extends RefCounted
## The map each act's stages are played on (design doc §13).


static func create(act: int, stage: int) -> StageMap:
	match act:
		1:
			return MidLaneMap.new()
		2:
			return TrainingGroundMap.new(stage)
		3:
			# The jungle, then the Elder Dragon's pit for the act's last stage.
			if stage == Journey.stage_count(3):
				return DragonPitMap.new()
			return JungleMap.new(stage)
	return TestArena.new()

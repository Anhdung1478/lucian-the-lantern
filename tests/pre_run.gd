extends GutHookScript
## Runs before the tests: scratch settings and save files, so the player's
## user://settings.json and save slots never change how the tests behave.

const PATH := "user://test_run_settings.json"
const SAVE_PREFIX := "user://test_run_save_slot_"


func run() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	GameSettings._instance = GameSettings.new(PATH)
	var save := SaveGame.new(SAVE_PREFIX)
	for n in range(1, SaveGame.SLOTS + 1):
		for file in [save.path(n), save.backup_path(n)]:
			if FileAccess.file_exists(file):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	save.load_slot(1)
	SaveGame._instance = save

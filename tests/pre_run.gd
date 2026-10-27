extends GutHookScript
## Runs before the tests: a scratch settings file, so the player's
## user://settings.json never changes how the tests behave.

const PATH := "user://test_run_settings.json"


func run() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	GameSettings._instance = GameSettings.new(PATH)

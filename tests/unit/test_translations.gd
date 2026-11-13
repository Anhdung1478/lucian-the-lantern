extends GutTest
## The Vietnamese translation files as a whole: they load, they are the ones
## the project lists, and no translation breaks its English's values or tags.
## Each part of the game has its own test of what it shows.


func after_each() -> void:
	Lang.use(Lang.ENGLISH)


func test_the_project_lists_every_translation_file() -> void:
	var listed: Array[String] = []
	listed.assign(ProjectSettings.get_setting("internationalization/locale/translations"))
	listed.sort()
	assert_eq(listed, LangProbe.files())
	assert_gt(listed.size(), 0)


func test_vietnamese_is_loaded() -> void:
	assert_true(TranslationServer.get_loaded_locales().has("vi"))


func test_no_translation_is_empty() -> void:
	var empty: Array[String] = []
	for english: String in LangProbe.known():
		if String(LangProbe.known()[english]).strip_edges() == "":
			empty.append(english)
	assert_eq(empty, [] as Array[String])


func test_a_translation_keeps_its_englishs_values_in_order() -> void:
	var broken: Array[String] = []
	for english: String in LangProbe.known():
		if LangProbe.values(english) != LangProbe.values(LangProbe.known()[english]):
			broken.append(english)
	assert_eq(broken, [] as Array[String])


func test_a_translation_keeps_its_englishs_tags() -> void:
	var broken: Array[String] = []
	for english: String in LangProbe.known():
		if LangProbe.tags(english) != LangProbe.tags(LangProbe.known()[english]):
			broken.append(english)
	assert_eq(broken, [] as Array[String])


func test_a_translation_keeps_its_englishs_line_breaks_at_the_ends() -> void:
	var broken: Array[String] = []
	for english: String in LangProbe.known():
		var vietnamese: String = LangProbe.known()[english]
		if english.begins_with("\n") != vietnamese.begins_with("\n") or english.ends_with("\n") != vietnamese.ends_with("\n") \
				or english.begins_with(" ") != vietnamese.begins_with(" ") or english.ends_with(" ") != vietnamese.ends_with(" "):
			broken.append(english)
	assert_eq(broken, [] as Array[String])


func test_no_text_is_translated_two_ways() -> void:
	var seen := {}
	var twice: Array[String] = []
	for file in LangProbe.files():
		var translation: Translation = load(file)
		for message in translation.get_message_list():
			var english := String(message)
			var vietnamese := String(translation.get_message(message))
			if seen.has(english) and seen[english] != vietnamese:
				twice.append("%s: %s" % [file.get_file(), english])
			seen[english] = vietnamese
	assert_eq(twice, [] as Array[String])


func test_the_probes_values_and_tags() -> void:
	assert_eq(LangProbe.values("Wave %d/%d of %s, 100%% in %.1f s for {name}"), ["%d", "%d", "%s", "%.1f", "{name}"] as Array[String])
	assert_eq(LangProbe.tags("[color=#fff]a[/color] [b]c[/b]"), ["[/b]", "[/color]", "[b]", "[color=#fff]"] as Array[String])


func test_the_probe_reads_a_scripts_texts() -> void:
	var path := "user://test_probe_script.gd"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("\n".join([
		"extends Node",
		"## A comment with \"Quoted words\" in it.",
		"const NAME := \"Start new game\"",
		"const ID := &\"Not A Text\"",
		"const PATH := \"res://assets/art/Thing.svg\"",
		"const COLOR := \"#ffcf5a\"",
		"const KEY := \"skill_q\"",
		"func _ready() -> void:",
		"\tpush_warning(\"Could not load %s\" % PATH)",
		"\tvar a := \"Killed by %s\" % \"x\"  # \"Trailing comment\"",
		"\tvar b := \"Two\\nlines here\"",
		"\tvar c := 'Single quoted text'",
		"\tget_node(^\"Some Node\")",
	]))
	file.close()
	assert_eq(LangProbe.literals(path), ["Start new game", "Killed by %s", "Two\nlines here", "Single quoted text"] as Array[String])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

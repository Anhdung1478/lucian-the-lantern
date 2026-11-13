class_name LangProbe
extends RefCounted
## The tests' tools for the translations (Lang):
## - known(): every Vietnamese translation, from the files in res://locale/vi.
## - literals() and missing_in(): the texts a player could read in a script,
##   and those of them with no translation.
## - data_texts() and missing_data(): the same for the data resources.
## - plain_texts(): with Lang.probe on, the texts on a built screen that
##   never went through Lang.t().
## - values() and tags(): what a translation must keep from its English.

const LOCALE_DIR := "res://locale/vi"
const UNTRANSLATED := "res://locale/untranslated.txt"
## The data resources' fields that hold text a player reads.
const DATA_FIELDS: Array[String] = ["display_name", "description", "effect_name", "playstyle", "format"]
## Calls whose texts are for the log, not the player.
const LOG_CALLS: Array[String] = ["push_warning(", "push_error(", "assert(", "print(", "printerr(", "print_rich("]
## Texts plain_texts() never reports: the languages' own names.
const ALWAYS_PLAIN: Array[String] = ["English", "Tiếng Việt"]

static var _known := {}
static var _untranslated := {}


## Every .po file in res://locale/vi.
static func files() -> Array[String]:
	var found: Array[String] = []
	for file in DirAccess.get_files_at(LOCALE_DIR):
		if file.ends_with(".po"):
			found.append(LOCALE_DIR.path_join(file))
	found.sort()
	return found


## English text -> its Vietnamese, over every file.
static func known() -> Dictionary:
	if _known.is_empty():
		for file in files():
			var translation: Translation = load(file)
			for message in translation.get_message_list():
				_known[String(message)] = String(translation.get_message(message))
	return _known


## The texts deliberately left in English (res://locale/untranslated.txt).
static func untranslated() -> Dictionary:
	if _untranslated.is_empty():
		for line in FileAccess.get_file_as_string(UNTRANSLATED).split("\n"):
			if line != "" and not line.begins_with("#"):
				_untranslated[line.c_unescape()] = true
	return _untranslated


## Forgets what known() and untranslated() read, after a file changed.
static func reload() -> void:
	_known.clear()
	_untranslated.clear()


## Whether a string in the code looks like text for a player: it has a word,
## and a capital or a space. Paths, ids and colours do not.
static func is_text(literal: String) -> bool:
	if literal.length() < 2 or literal.begins_with("res://") or literal.begins_with("user://"):
		return false
	if _matches("^[a-z0-9_./]+$", literal) or _matches("^#[0-9a-fA-F]{3,8}$", literal):
		return false
	if not _matches("[A-Za-z]{2}", literal):
		return false
	return _matches("[A-Z]", literal) or literal.contains(" ")


## The texts in the script at `path` that a player could read: its string
## literals that pass is_text(). Comments, StringNames (&"..."), node paths
## (^"...", $"...") and the log's calls (LOG_CALLS) are left out.
static func literals(path: String) -> Array[String]:
	var source := FileAccess.get_file_as_string(path)
	var found: Array[String] = []
	var at := 0
	var line_start := 0
	while at < source.length():
		var letter := source[at]
		if letter == "\n":
			line_start = at + 1
		elif letter == "#":
			at = _line_end(source, at)
			continue
		elif letter == "\"" or letter == "'":
			var triple := source.substr(at, 3) == letter.repeat(3)
			var quote := letter.repeat(3) if triple else letter
			var end := _string_end(source, at + quote.length(), quote)
			var before := source[at - 1] if at > 0 else ""
			var literal := source.substr(at + quote.length(), end - at - quote.length()).c_unescape()
			var statement := source.substr(line_start, at - line_start)
			if not (before in ["&", "^", "$"]) and not _logs(statement) and is_text(literal):
				found.append(literal)
			at = end + quote.length()
			continue
		at += 1
	return found


## "file: text" for each text in the scripts at `paths` that has no
## Vietnamese and is not in the untranslated list.
static func missing_in(paths: Array) -> Array[String]:
	var missing: Array[String] = []
	for path: String in paths:
		for literal in literals(path):
			if not known().has(literal) and not untranslated().has(literal):
				missing.append("%s: %s" % [path.get_file(), literal])
	return missing


## Every .gd file under `dir`, and under its folders.
static func scripts_in(dir: String) -> Array[String]:
	var found: Array[String] = []
	for file in DirAccess.get_files_at(dir):
		if file.ends_with(".gd"):
			found.append(dir.path_join(file))
	for folder in DirAccess.get_directories_at(dir):
		found.append_array(scripts_in(dir.path_join(folder)))
	return found


## The texts in the data resources under `dir`: each .tres file's
## DATA_FIELDS that are not empty.
static func data_texts(dir: String) -> Array[String]:
	var found: Array[String] = []
	for file in DirAccess.get_files_at(dir):
		if not file.ends_with(".tres"):
			continue
		var resource := load(dir.path_join(file))
		for field in DATA_FIELDS:
			var value: Variant = resource.get(field)
			if value is String and value != "" and not found.has(value):
				found.append(value)
	for folder in DirAccess.get_directories_at(dir):
		for text in data_texts(dir.path_join(folder)):
			if not found.has(text):
				found.append(text)
	return found


## The data texts under `dir` with no Vietnamese (and not in the untranslated
## list).
static func missing_data(dir: String) -> Array[String]:
	var missing: Array[String] = []
	for text in data_texts(dir):
		if not known().has(text) and not untranslated().has(text):
			missing.append(text)
	return missing


## With Lang.probe on when `root` was built: the texts under `root` that
## still have a plain word, so some part of them never went through
## Lang.t(). Labels, buttons and their lists, rich text (its tags aside),
## placeholders, tooltips and the "hover_text" meta are read, shown or
## hidden. `allowed` are pieces to overlook: a key's name, a save's name.
static func plain_texts(root: Node, allowed: Array = []) -> Array[String]:
	var found: Array[String] = []
	var nodes: Array[Node] = [root]
	nodes.append_array(root.find_children("*", "", true, false))
	for node in nodes:
		for text in _texts_of(node):
			var rest := text
			for piece: String in ALWAYS_PLAIN + allowed:
				rest = rest.replace(piece, "")
			if _matches("[A-Za-z]{2}", rest) and not found.has(text):
				found.append(text)
	return found


## The values a text takes, in order: its format's (%d, %.1f, %s) and then
## its {named} ones, sorted. A translation must have the same.
static func values(text: String) -> Array[String]:
	var found: Array[String] = []
	var regex := RegEx.create_from_string("%[-+ 0]*\\d*(?:\\.\\d+)?[sdfcxXov%]")
	for result in regex.search_all(text):
		if result.get_string() != "%%":
			found.append(result.get_string())
	var named: Array[String] = []
	for result in RegEx.create_from_string("\\{[A-Za-z_0-9]+\\}").search_all(text):
		named.append(result.get_string())
	named.sort()
	return found + named


## A text's BBCode tags, sorted. A translation must have the same.
static func tags(text: String) -> Array[String]:
	var found: Array[String] = []
	for result in RegEx.create_from_string("\\[/?[a-z_]+[^\\]]*\\]").search_all(text):
		found.append(result.get_string())
	found.sort()
	return found


static func _texts_of(node: Node) -> Array[String]:
	var texts: Array[String] = []
	if node is Label:
		texts.append((node as Label).text)
	elif node is RichTextLabel:
		texts.append(RegEx.create_from_string("\\[[^\\]]*\\]").sub((node as RichTextLabel).text, "", true))
	elif node is Button:
		texts.append((node as Button).text)
		if node is OptionButton:
			for i in (node as OptionButton).item_count:
				texts.append((node as OptionButton).get_item_text(i))
	elif node is LineEdit:
		texts.append((node as LineEdit).placeholder_text)
	if node is Control:
		texts.append((node as Control).tooltip_text)
	if node.has_meta(&"hover_text"):
		texts.append(str(node.get_meta(&"hover_text")))
	return texts


static func _matches(pattern: String, text: String) -> bool:
	return RegEx.create_from_string(pattern).search(text) != null


static func _logs(statement: String) -> bool:
	for name in LOG_CALLS:
		if statement.contains(name):
			return true
	return false


static func _line_end(source: String, from: int) -> int:
	var end := source.find("\n", from)
	return source.length() if end < 0 else end


## Where the string that starts before `from` closes: the index of `quote`.
static func _string_end(source: String, from: int, quote: String) -> int:
	var at := from
	while at < source.length():
		if source[at] == "\\":
			at += 2
			continue
		if source.substr(at, quote.length()) == quote:
			return at
		at += 1
	return source.length()

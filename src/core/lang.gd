class_name Lang
extends RefCounted
## The game's language. Every text a player reads is written in English in
## the code and the data, and goes through t() where it is shown: t() answers
## with the text in the language chosen (GameSettings' "language"), or the
## English when the language has no translation of it.
##
## The translations are gettext files, one per part of the game, in
## res://locale/<code>/ (project.godot lists them). English has none: it is
## the text itself.
##
## A text with values in it is translated as its format, then filled:
## Lang.t("Wave %d/%d") % [wave, waves]. A translation keeps its format's
## values in the same order.
##
## Nothing translated is ever saved or used as a key: saves and ids stay in
## English, so a save loads in any language.

const ENGLISH := "en"
const VIETNAMESE := "vi"
## The languages offered, in the order Settings lists them.
const CODES: Array[String] = [ENGLISH, VIETNAMESE]
## Each language's name in that language; never translated.
const NAMES := {ENGLISH: "English", VIETNAMESE: "Tiếng Việt"}

## What mark() leaves alone: a format's values (%d, %.1f, %s, %%), {named}
## values, and BBCode tags with an image's path.
const KEPT := "%[-+ 0]*\\d*(?:\\.\\d+)?[sdfcxXov%]|\\{[A-Za-z_0-9]*\\}|\\[img[^\\]]*\\].*?\\[/img\\]|\\[[^\\]]*\\]"
## How far a marked letter sits from its plain one: the fullwidth forms.
const MARK_SHIFT := 0xFF21 - 0x41

## Tests only: t() answers with mark(text) in place of a translation, so a
## text on screen that still has plain letters never went through t().
static var probe := false

static var _kept: RegEx


## `text` in the language chosen.
static func t(text: String) -> String:
	if probe:
		return mark(text)
	return String(TranslationServer.translate(text))


## The language in use now.
static func code() -> String:
	var locale := TranslationServer.get_locale()
	return VIETNAMESE if locale.begins_with(VIETNAMESE) else ENGLISH


## Turns the game to language `to` (a code in CODES; anything else is
## English). What is on screen already keeps its text: the caller builds its
## screen again.
static func use(to: String) -> void:
	TranslationServer.set_locale(to if CODES.has(to) else ENGLISH)


## `text` with every plain letter swapped for its fullwidth form, values and
## tags kept (see KEPT). Marking a marked text changes nothing.
static func mark(text: String) -> String:
	if _kept == null:
		_kept = RegEx.create_from_string(KEPT)
	var marked := ""
	var from := 0
	for found in _kept.search_all(text):
		marked += _shifted(text.substr(from, found.get_start() - from)) + found.get_string()
		from = found.get_end()
	return marked + _shifted(text.substr(from))


static func _shifted(text: String) -> String:
	var shifted := ""
	for i in text.length():
		var letter := text.unicode_at(i)
		var plain := (letter >= 0x41 and letter <= 0x5A) or (letter >= 0x61 and letter <= 0x7A)
		shifted += String.chr(letter + MARK_SHIFT if plain else letter)
	return shifted

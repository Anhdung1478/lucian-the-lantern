class_name TooltipText
extends RefCounted
## LoL-style tooltip text: a small markup for colored keywords, and per-rank
## value lists such as "80/110/140/170/200" with the current rank lit up.

## Markup tag -> color. AD and physical match the physical damage numbers,
## magic matches the magic ones, mana matches the HUD mana cost, AP matches
## its stat icon.
const COLORS := {
	"ad": "ff9a3c",
	"phys": "ff9a3c",
	"ap": "4a6cf7",
	"magic": "4fa8ff",
	"true": "ffffff",
	"mana": "8fb8ff",
	"hp": "6fd36f",
	"ms": "ffcf5a",
	"kw": "ffcf5a",
}
## The current rank's value, and the other ranks' values.
const BRIGHT := "ffffff"
const DIM := "8a93a3"
## Body text and headings.
const TEXT := "d8dde6"
const GOLD := "ffcf5a"

static var _tags := RegEx.create_from_string("\\[[^\\]]*\\]")


## "[ad]50 AD[/ad]" -> "[color=#ff9a3c]50 AD[/color]".
static func colorize(markup: String) -> String:
	var text := markup
	for tag: String in COLORS:
		text = text.replace("[%s]" % tag, "[color=#%s]" % COLORS[tag]).replace("[/%s]" % tag, "[/color]")
	return text


static func color(text: String, hex: String) -> String:
	return "[color=#%s]%s[/color]" % [hex, text]


## Values per rank joined with "/". The current rank is bright and the others
## dim; with no rank learned the list is left plain.
static func ranked(values: Array[float], rank: int) -> String:
	if values.size() == 1:
		return number(values[0]) if rank < 1 else color(number(values[0]), BRIGHT)
	var parts: PackedStringArray = []
	for i in values.size():
		var text := number(values[i])
		if rank >= 1:
			text = color(text, BRIGHT if i == rank - 1 else DIM)
		parts.append(text)
	return "/".join(parts)


## A scaling such as "(+60/70/80/90/100% AD)", all in the stat's color.
static func ratio(values: Array[float], _rank: int, stat: String) -> String:
	var parts: PackedStringArray = []
	for value in values:
		parts.append(number(value * 100.0))
	return color("(+%s%% %s)" % ["/".join(parts), stat], COLORS[stat.to_lower()])


## Whole numbers without decimals, others with up to two.
static func number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(roundi(value))
	return String.num(value, 2)


## The text without any BBCode tags.
static func plain(bbcode: String) -> String:
	return _tags.sub(bbcode, "", true)

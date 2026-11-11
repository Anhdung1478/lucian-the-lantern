class_name Difficulty
extends RefCounted
## A save's difficulty: one number that scales every enemy's HP (bosses and
## mini bosses too) and all the damage Lucian takes, and on Hard and Extreme
## more blue and orange essence, so replays pay for the tree. Picked when a
## new game starts and fixed after that. Gold, XP, purple, speeds and
## timings stay the same.

const EASY := 0
const NORMAL := 1
const HARD := 2
const EXTREME := 3
const LEVELS: Array[int] = [EASY, NORMAL, HARD, EXTREME]
## The save file's word for each level.
const KEYS: Array[String] = ["easy", "normal", "hard", "extreme"]
const NAMES: Array[String] = ["Easy", "Normal", "Hard", "Extreme"]
const SCALES: Array[float] = [0.8, 1.0, 1.1, 1.3]
## Every kill's blue essence, its orange drop chance and a boss's or mini
## boss's sure orange are multiplied by this (KillRewards).
const ESSENCE_SCALES: Array[float] = [1.0, 1.0, 1.2, 1.5]


static func is_level(level: int) -> bool:
	return level >= EASY and level <= EXTREME


## Enemy HP and the damage Lucian takes are multiplied by this.
static func scale(level: int) -> float:
	return SCALES[level] if is_level(level) else 1.0


## Blue and orange essence from kills are multiplied by this.
static func essence_scale(level: int) -> float:
	return ESSENCE_SCALES[level] if is_level(level) else 1.0


static func name_of(level: int) -> String:
	return NAMES[level] if is_level(level) else NAMES[NORMAL]


## "×1.2".
static func scale_text(level: int) -> String:
	return "×%s" % String.num(scale(level), 1)


## "Enemies have 110% HP and deal 110% damage. Blue and orange essence ×1.2."
static func describe(level: int) -> String:
	var percent := roundi(scale(level) * 100.0)
	var text := "Enemies have %d%% HP and deal %d%% damage." % [percent, percent]
	if essence_scale(level) != 1.0:
		text += " Blue and orange essence ×%s." % String.num(essence_scale(level), 1)
	return text


## The level a save file's word names; Normal for anything else.
static func from_key(key: Variant) -> int:
	return KEYS.find(key) if key is String and key in KEYS else NORMAL

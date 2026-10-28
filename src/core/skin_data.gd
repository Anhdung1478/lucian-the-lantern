class_name SkinData
extends Resource
## One Lucian skin: its art, its Skin Shop card text and what it changes in
## his stats. Data lives in data/skins/<id>.tres; Skins lists them.

## Unique id, e.g. &"high_noon".
@export var id: StringName
@export var display_name := ""
## Purple essence to buy it (0 for Classic).
@export var cost := 0
## The Skin Shop card art and the HUD portrait.
@export var portrait: Texture2D
## Lucian's top-down body sprite.
@export var body: Texture2D
## Card lines shown in green.
@export var bonuses := PackedStringArray()
## Card lines shown in red.
@export var weaknesses := PackedStringArray()
## A short description of how it plays.
@export var playstyle := ""
## Flat stats keyed like ItemStats, added to the item bonus.
@export var flat: Dictionary[StringName, float] = {}
## StatBlock field -> multiplier on the final stats (after item passives).
@export var scale: Dictionary[StringName, float] = {}
## Share of max HP healed on each kill.
@export var kill_heal := 0.0

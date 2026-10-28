class_name SummonerData
extends Resource
## One summoner spell's card: name, icon, cooldown and text. Its numbers live
## in SummonerSpells.

@export var id: StringName
@export var display_name := ""
@export var icon: Texture2D
## Seconds. Ability haste doesn't shorten it.
@export var cooldown := 60.0
## Tooltip markup (TooltipText.colorize tags).
@export_multiline var description := ""

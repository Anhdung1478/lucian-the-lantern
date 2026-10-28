class_name TreeNodeData
extends Resource
## One node of the Evolution Tree: what it is, where it sits, what it costs and
## what each level gives. Data lives in data/tree/<id>.tres.

## Unique id, e.g. &"stat_ad".
@export var id: StringName
@export var display_name := ""
## One short sentence, in TooltipText markup.
@export_multiline var description := ""
@export var icon: Texture2D
## The grove: &"skills", &"stats", &"equipment", &"economy" or &"summoners".
@export var branch: StringName
## (column, row up from the ground); one cell is 150 px.
@export var grid := Vector2.ZERO
@export var max_level := 1
## Blue essence to buy each level (one entry per level).
@export var blue: Array[int] = []
## Orange essence to buy each level (one entry per level).
@export var orange: Array[int] = []
## Nodes that must have level 1 before this one opens.
@export var requires: Array[StringName] = []
## How many of `requires` are enough; 0 means all of them.
@export var requires_count := 0
## Acts that must be cleared before this one opens.
@export var requires_act := 0
## The player stat this node changes, if it is a stat node.
@export var stat_key: StringName
## The value at level 0.
@export var base := 0.0
## What each level adds to the value.
@export var per_level := 0.0
## Whether the value is a fraction shown as a percent (0.03 -> 3).
@export var percent := false
## How the value reads; "{v}" is the number.
@export var format := ""


## The value at `level`: base + per_level x level.
func value(level: int) -> float:
	return base + per_level * level


## What `level` gives, through `format` ("{v}" is the value). Level 0 of a
## node with no base value reads "None".
func value_text(level: int) -> String:
	if level == 0 and base == 0.0:
		return "None"
	var shown := value(level) * (100.0 if percent else 1.0)
	var number := str(roundi(shown)) if is_equal_approx(shown, roundf(shown)) else "%.1f" % shown
	return format.replace("{v}", number)

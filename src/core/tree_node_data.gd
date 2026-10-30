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
## The grove: &"skills", &"stats", &"backpack", &"economy" or &"summoners".
@export var branch: StringName
## (column, row up from the ground) on its branch's page; TreePage centres
## the branch on the page.
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
## The act needed to buy each level (one entry per level like `blue`); empty
## means no rule. The act needed is the larger of this and `requires_act`.
@export var level_acts: Array[int] = []
## The nodes whose levels are added up for `level_sums`.
@export var level_sum_ids: Array[StringName] = []
## Per level, the total of the `level_sum_ids` levels needed to buy it; empty
## means no rule.
@export var level_sums: Array[int] = []
## The player stat this node changes, if it is a stat node.
@export var stat_key: StringName
## The value at level 0.
@export var base := 0.0
## What each level adds to the value.
@export var per_level := 0.0
## The value at levels 0..max_level; when set it replaces base + per_level x level.
@export var level_values: Array[float] = []
## Whether the value is a fraction shown as a percent (0.03 -> 3).
@export var percent := false
## How the value reads; "{v}" is the number.
@export var format := ""


## The value at `level`: `level_values` when set, else base + per_level x level.
func value(level: int) -> float:
	if not level_values.is_empty():
		return level_values[clampi(level, 0, level_values.size() - 1)]
	return base + per_level * level


## What `level` gives, through `format` ("{v}" is the value). Level 0 of a
## node whose value there is 0 reads "None".
func value_text(level: int) -> String:
	if level == 0 and value(0) == 0.0:
		return "None"
	var shown := value(level) * (100.0 if percent else 1.0)
	var number := str(roundi(shown)) if is_equal_approx(shown, roundf(shown)) else "%.1f" % shown
	return format.replace("{v}", number)


## The act needed to buy level `i` + 1 (`i` counts from 0); 0 past the end of `level_acts`.
func act_needed(i: int) -> int:
	return level_acts[i] if i >= 0 and i < level_acts.size() else 0


## The Q + W + E style total needed to buy level `i` + 1; 0 past the end of `level_sums`.
func sum_needed(i: int) -> int:
	return level_sums[i] if i >= 0 and i < level_sums.size() else 0


## "Q" from "Q – Piercing Light": the name up to the first " – ".
func short_name() -> String:
	return display_name.split(" – ")[0]

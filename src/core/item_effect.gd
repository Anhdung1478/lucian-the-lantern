class_name ItemEffect
extends Resource
## One passive or active on an item. Phase 2 only shows its text.

@export var effect_name := ""
@export var active := false
## Seconds; only shown for actives.
@export var cooldown := 0.0
## Tooltip markup, see TooltipText.colorize.
@export_multiline var description := ""

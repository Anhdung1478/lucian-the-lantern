class_name Hud
extends CanvasLayer
## Lucian's bottom panel and the stats panel. Reads Lucian every frame.

## Space between the stats panel and the bottom panel.
const STATS_GAP := 10.0

var lucian: Lucian

@onready var bottom_panel: PanelContainer = %BottomPanel
@onready var stats_panel: StatsPanel = %StatsPanel
@onready var level_label: Label = %LevelLabel
@onready var xp_bar: ProgressBar = %XpBar
@onready var hp_bar: ProgressBar = %HpBar
@onready var hp_label: Label = %HpLabel
@onready var mana_bar: ProgressBar = %ManaBar
@onready var mana_label: Label = %ManaLabel


func setup(target: Lucian) -> void:
	lucian = target
	stats_panel.lucian = target


func _ready() -> void:
	bottom_panel.resized.connect(_place_stats_panel)
	_place_stats_panel()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_stats"):
		stats_panel.visible = not stats_panel.visible
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if lucian == null:
		return
	var progress := lucian.progress
	level_label.text = str(progress.level)
	var xp_needed := progress.xp_for_next()
	xp_bar.value = float(progress.xp) / xp_needed if xp_needed > 0 else 1.0
	var stats := lucian.stats
	hp_bar.value = lucian.hp / stats.max_hp
	hp_label.text = "%d / %d" % [roundi(lucian.hp), roundi(stats.max_hp)]
	mana_bar.value = lucian.mana / stats.max_mana
	mana_label.text = "%d / %d" % [roundi(lucian.mana), roundi(stats.max_mana)]


func _place_stats_panel() -> void:
	# Zero-width rect at the panel's left edge; the minimum size grows it leftward.
	stats_panel.offset_right = -bottom_panel.size.x * 0.5 - STATS_GAP
	stats_panel.offset_left = stats_panel.offset_right

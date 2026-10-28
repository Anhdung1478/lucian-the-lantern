# Phase 4 — Fixes, UI polish & summoner spells — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the Phase 3 feedback items, rework the stats panel (icons, colors, hover cards, extra table), polish the skill bar, add a camera recenter key and a resolution setting, and add all six summoner spells on D/F.

**Architecture:** Same layering as Phases 1–3: pure logic in `src/core/` (GUT-tested first), Lucian behaviour in `src/lucian/` (scene-tested with a real `lucian.tscn` + dummy), UI in `src/ui/` built in code, art as hand-written SVG. Summoner spells copy the `ItemActives` pattern: a child node of Lucian with its own cooldown table. Stat look (icon, color, name, description) lives in one new `StatStyle` table that the stats panels and item cards share.

**Tech Stack:** Godot 4.7.2 (GDScript), GUT for tests, the `tests/tools/screenshot.gd` harness for visual checks.

**Spec:** the user's Phase 4 request (16 points, quoted under Context) + reference image `docs/image/main-stats-image.png` (LoL stats panel: 2 columns × 4 rows, icon + value).

## Context

Phase 3 shipped gold, shop, settings, item passives and actives. Playtesting it, the user asked for:

1. Energize should go up after every attack, ~9 per attack (Statikk's "Electroshock" charge).
2. Debug item picker sorted A→Z by name.
3. Hextech Rocketbelt's bolt arc should fly ~900 from where Lucian stood.
4. Debug "No cooldowns" doesn't refresh **item** cooldowns already running (Phase 1 had the same bug for skills).
5. A skill that can't be ranked up still shows its "+" in a ring, but grey.
6. Rule: basic skills can't reach rank 2/3/4/5 at level 2/4/6/8.
7. Space moves the camera back to Lucian once (it does not switch to follow cam).
8. Every stat gets an icon and a color. The stats table shows icon + amount; item cards show icon → amount → name.
9. Hovering a stat for >1 s shows its description.
10. Ctrl + C toggles the stats table; holding C shows a second, extra table.
11. With Rapid Firecannon equipped and Energize full, the attack range ring shows by itself until that shot hits.
12. Summoner spells: Flash, Ghost, Barrier, Heal, Clarity, Smite.
13. Passive icon smaller (70% of a skill icon).
14. New passive icon: two guns and their light rays.
15. During R, ranked Q and W show grey; during Q, E shows grey.
16. Resolution option in Settings → Graphics.

### Decisions made with the user
| Topic | Decision |
|---|---|
| Passive icon | **70% of a skill icon: 45 px** (skills stay 64 px), centered vertically on the skill row. |
| Choosing D/F spells | **Debug table picker** (two dropdowns), all 6 spells available. Defaults **D = Flash, F = Heal**. Picking the spell already on the other key swaps them. |
| Energize | **+9 charge per basic attack** (was 10). Walking/dash rules unchanged. |
| Grey "+" | Shown **only while there is an unspent skill point**, on every skill that isn't maxed: **gold** if it can rank up now, **grey with a small lock** if its next rank isn't bought (Evolution Tree), **grey** otherwise (R before 6/11/16, Q rank 2 before level 3, …). Grey ones can't be clicked. Hidden on maxed skills and with 0 points. |

### Already true (verify, don't rebuild)
- Point 6 is enforced by `ChampionProgress.required_level()` (`src/core/champion_progress.gd:29`): basic rank *r* needs level 2*r*−1, so rank 2/3/4/5 needs level 3/5/7/9. Phase 4 adds a test covering every rank and the grey "+" that shows it.

### Defaults chosen during planning (placeholders, tune later)
- **Main stats table (2 × 4, like the reference image):** AD | AP, Armor | MR, Attack speed | Ability haste, Crit | Move speed.
- **Extra stats table (held key):** HP regen | Mana regen, Heal & shield power | Armor pen, Magic pen | Life steal, Omnivamp | Attack range, Tenacity. Same look: icon + amount. Regen shows per 5 s like LoL. It sits just above the main table (on its own if the main one is hidden).
- **Stat icons** (`assets/art/stats/<key>.svg`, 64 viewBox, transparent background, stat color fill with dark outline, readable at 18–20 px):

| Key | Icon | Color |
|---|---|---|
| `ad` | one-headed axe | orange `ff9a3c` |
| `ap` | round-headed missile | dark blue `4a6cf7` |
| `armor` | breastplate inside a second frame | yellow `f2c94c` |
| `mr` | circle inside a circle frame | light blue `7fd4ff` |
| `attack_speed` | dagger with speed lines | light yellow `fff3a3` |
| `ability_haste` | hourglass | white `ffffff` |
| `crit_chance` | pointed missile (AP's shape, sharp tip + fins) | red `ff4b4b` |
| `move_speed` (+ `move_speed_pct`) | boot with speed lines | white `ffffff` |
| `max_hp` | heart | green `6fd36f` |
| `max_mana` | droplet | blue `8fb8ff` |
| `hp_regen` | heart + up arrow | green `6fd36f` |
| `mana_regen` | droplet + up arrow | blue `8fb8ff` |
| `heal_shield_power` | cross over a shield | teal `7fe3c4` |
| `armor_pen` | arrow through a breastplate | orange-red `ff7a5a` |
| `magic_pen` | arrow through a circle | violet `b48cff` |
| `lifesteal` | blood drop with a fang | crimson `e0475a` |
| `omnivamp` | swirling drop | magenta `c0508f` |
| `attack_range` | crosshair ring | grey `cfd6e0` |
| `tenacity` | broken chain | tan `c9b28a` |

- **AP in tooltips:** the `[ap]` markup color changes from purple to the new AP blue (`4a6cf7`) so scalings match the stat color.
- **Item card stat line:** `[icon] +65 Attack Damage`: icon, then the amount in the stat color, then the name in normal text.
- **Stat hover card:** after `HoverTip.DELAY` (1 s): stat icon, name, current value in the stat color, a one-line description (table in Task 6).
- **Ctrl + C / hold C:** the existing `toggle_stats` action (still rebindable; bindings carry no modifiers). Ctrl + key toggles the main table; holding the key without Ctrl shows the extra table.
- **Camera:** new rebindable action `center_camera` (Space). One press snaps the camera onto Lucian (clamped to the map). Free-cam stays free; in follow mode it does nothing new.
- **Resolution:** `1280×720, 1366×768, 1600×900 (default), 1920×1080, 2560×1440, 3840×2160`. Only sizes that fit the screen are listed. It sets the window size in **windowed** mode and centers the window; a maximized window is restored first. Greyed out in borderless/fullscreen (those use the screen's resolution). Saved as `"resolution": "1600x900"`.
- **Rocketbelt:** `ROCKETBELT_RANGE` 500 → **900**. Bolts already start where Lucian stood when he used it.
- **RFC ring:** a light-blue ring at the **energized** range (`attack_range × 1.35`). It shows while RFC is equipped and the charge is full, stays until the Energized shot lands (or 1 s, if its target disappears), then hides. The attack-move ring still wins when both apply.
- **Blocked tint:** Q and W (if rank ≥ 1) grey while R fires. E (if rank ≥ 1) grey during Q's 0.3 s cast. Only the look changes; the cast rules stay as they are (Q/W refused during R, E queued during Q).
- **Summoner spells** (numbers are placeholders; no ability haste; each spell keeps its own cooldown, also when moved to the other key; cooldowns tick only while unpaused):

| Spell | Cooldown | Effect |
|---|---|---|
| Flash | 90 s | Blink toward the cursor, up to 400 (shorter if the cursor is closer). It steps back 10 units at a time until Lucian's body fits clear of walls and enemy bodies. A blink doesn't build Energize. |
| Ghost | 60 s | +40% move speed for 6 s; Lucian passes through enemies (collides with walls only) for that time. |
| Barrier | 60 s | Shield of 95 + 18 × level for 2.5 s (shown on the HP bar with the Ichorshield, plus a buff icon). |
| Heal | 60 s | Heals 80 + 15 × level (heal & shield power applies) and gives +30% move speed fading over 1 s. |
| Clarity | 45 s | Restores 50% of max mana. |
| Smite | 30 s | 450 **true** damage to the enemy nearest the cursor within 500 of Lucian, and heals 10% of max HP. Refused (no cooldown spent) with no enemy in reach. |

  Usable during cast times and R; refused while dashing or with a pause screen open. "No cooldowns" also refreshes summoner cooldowns. Nothing hits Lucian yet, so Barrier's shield only shows (like the Ichorshield).
- **Summoner HUD slots:** 48 px icons right of R (after a 10 px gap), in the same band as the skill icons: cooldown sweep and seconds, key label from the binding, hover card (name, key, cooldown, effect).
- **Summoner icons** (`assets/art/summoners/*.svg`, full square art like the skill icons): Flash yellow-white starburst on blue; Ghost pale running silhouette with trails on teal; Barrier gold hex dome on brown; Heal green cross with glow; Clarity blue mana swirl on navy; Smite orange bolt striking down on dark red.
- **Passive icon:** two of Lucian's relic pistols side by side, angled up-right, each muzzle firing a light ray (gold glow + white core) to the icon edge, on the same navy gradient as `icon_q.svg`.

## Global Constraints
- Godot **4.7.2**; GDScript style of the surrounding code: tabs, typed vars, `##` doc comments on classes and public funcs, `&"name"` StringNames, one `class_name` per file.
- Pure logic stays in `src/core/` with no scene dependencies. UI is built in code (no new `.tscn` except data `.tres`).
- New player-facing numbers are constants at the top of their script (or `@export`s on `.tres` data), with a comment when the unit isn't obvious.
- Settings file stays `"version": 1`: new keys fall back to defaults when missing.
- ESC and F3 + Q stay non-rebindable. Every new action goes into `project.godot`, `GameSettings.REBINDABLE` and `ACTION_NAMES`.
- Work on `main`, **one verified commit per task**, never pushed (same as Phases 1–3). Each commit: GUT suite green.
- Docs follow the existing voice: short plain sentences, tables for numbers.

## File map

| File | Change |
|---|---|
| `src/core/energize_charge.gd` | `PER_ATTACK` 9 |
| `src/core/item_catalog.gd` | `by_name()` |
| `src/core/item_stats.gd` | `amount()`; `line()` uses it |
| `src/core/champion_progress.gd` | `next_rank_bought()`, `is_maxed()` |
| `src/core/game_settings.gd` | `resolution` setting, `RESOLUTIONS`, `parse_resolution()`, `apply_resolution()`, `center_camera` action |
| `src/core/summoner_data.gd` | **new** `SummonerData` resource |
| `data/summoners/{flash,ghost,barrier,heal,clarity,smite}.tres` | **new** spell data |
| `src/lucian/lucian.gd` | cheat clears item + summoner cooldowns; `is_skill_blocked()`; RFC ring draw; `enemy_near_cursor()`; ghost / barrier / blink / `fits_at()`; `use_summoner()`; `total_shield()` |
| `src/lucian/skills/piercing_light.gd` | `is_casting()` |
| `src/lucian/items/item_actives.gd` | Rocketbelt range 900; Gunblade uses `enemy_near_cursor()` |
| `src/lucian/items/item_passives.gd` | Spellblade respects the cheat; `shows_rfc_ring()` |
| `src/lucian/summoners/summoner_spells.gd` | **new** `SummonerSpells` node |
| `src/lucian/lucian_controller.gd` | D/F → `use_summoner` |
| `src/stage/stage_camera.gd` | `center_on_target()` on `center_camera` |
| `src/ui/stat_style.gd` | **new** `StatStyle` (icons, colors, names, descriptions, item line) |
| `src/ui/hud/stats_panel.gd` | rewritten: icon + value cells, `MAIN` / `EXTRA` |
| `src/ui/hud/stat_cell.gd` | **new** one stat cell with hover card |
| `src/ui/hud/hud.gd` | Ctrl+C / hold C, extra panel, total shield, summoner slots, smaller passive |
| `src/ui/hud/skill_slot.gd` | grey / locked "+", blocked tint, `icon_size` |
| `src/ui/hud/summoner_slot.gd` | **new** D/F slot |
| `src/ui/tooltip/tooltip_card.gd` | item stat lines with icons; `stat()`, `summoner()` cards |
| `src/ui/tooltip/tooltip_text.gd` | `ap` color |
| `src/ui/debug/debug_table.gd` | sorted items; summoner pickers |
| `src/ui/settings/settings_screen.gd` | Resolution row; hint text |
| `project.godot` | `center_camera` (Space) |
| `assets/art/stats/*.svg` (19), `assets/art/summoners/*.svg` (6), `assets/art/ui/icon_passive.svg` | art |
| `tests/unit/…` | new: `test_stage_camera`, `test_stat_style`, `test_stats_panel`, `test_summoner_spells`; extended: `test_energize`, `test_item_passives`, `test_item_actives`, `test_item_catalog`, `test_item_stats`, `test_champion_progress`, `test_lucian_casting`, `test_game_settings`, `test_tooltips` |
| `tests/tools/screenshot.gd` | scenarios `stats`, `skillbar`, `camera`, `rfc_ring`, `summoners` |
| `docs/…` | `implementation/phase4.md`, `report/phase4.md` (+ `report/phase4/*.png`), `ui_design.md`, `lucian_game_design.md`, `items.md` |

## Running things

```powershell
$godot = "$env:LOCALAPPDATA\Programs\Godot"
& "$godot\godot_console.exe" --headless --path . --import                       # after adding SVG/.tres files
& "$godot\godot_console.exe" --headless --path . -s res://addons/gut/gut_cmdln.gd  # full suite
& "$godot\godot_console.exe" --headless --path . -s res://addons/gut/gut_cmdln.gd -gconfig= -gtest=res://tests/unit/<file>.gd -gexit  # one file
& "$godot\godot.exe" --path . -s res://tests/tools/screenshot.gd -- <scenario> <out_dir>  # needs a window
```

---

### Task 0: Save the plan

- [ ] Copy this plan to `docs/implementation/phase4.md`. Add a "Phase 4: `implementation/phase4.md`" mention to `lucian_game_design.md` §16.
- [ ] Commit with the reference image: `git add docs/implementation/phase4.md docs/lucian_game_design.md docs/image/main-stats-image.png` → `git commit -m "Add the Phase 4 plan"`.

---

### Task 1: Quick fixes: energize +9, sorted debug items, Rocketbelt 900, no-cooldowns refreshes items

**Files:** `src/core/energize_charge.gd`, `src/core/item_catalog.gd`, `src/ui/debug/debug_table.gd`, `src/lucian/items/item_actives.gd`, `src/lucian/items/item_passives.gd`, `src/lucian/lucian.gd`; tests `test_energize.gd`, `test_item_passives.gd`, `test_item_catalog.gd`, `test_item_actives.gd`.

**Interfaces — Produces:** `ItemCatalog.by_name() -> Array[ItemData]`; `Lucian.cheat_no_cooldowns` setter now also clears `item_cooldowns` (Task 8 extends it to summoners).

- [ ] **Step 1: Failing tests.**
  - `test_energize.gd`: `test_attacks_build_nine_charge`: `charge.add_attack()` → `assert_almost_eq(charge.value, 9.0, 0.001)`.
  - `test_item_passives.gd` `test_energize_needs_an_energized_item`: after `basic_hit()` expect `19.0` (10 walked + 9).
  - `test_item_catalog.gd` (uses the real catalog):
    ```gdscript
    func test_by_name_sorts_a_to_z() -> void:
    	var names: Array = (load("res://data/items/catalog.tres") as ItemCatalog).by_name().map(
    		func(item: ItemData) -> String: return item.display_name)
    	assert_eq(names[0], "Archangel's Staff")
    	assert_eq(names[1], "B.F. Sword")
    	for i in names.size() - 1:
    		assert_true(names[i].nocasecmp_to(names[i + 1]) <= 0, "%s before %s" % [names[i], names[i + 1]])
    ```
  - `test_item_actives.gd`:
    ```gdscript
    func test_rocketbelt_bolts_reach_900_units() -> void:
    	dummy.position = Vector2(850, 0)
    	equip(&"hextech_rocketbelt")
    	assert_true(lucian.use_equip_slot(0, dummy.position))
    	await wait_seconds(0.8)
    	assert_has(sources, &"hextech_rocketbelt")


    func test_turning_on_no_cooldowns_refreshes_item_cooldowns() -> void:
    	equip(&"hextech_gunblade")
    	assert_true(lucian.use_equip_slot(0, dummy.position))
    	lucian.cheat_no_cooldowns = true
    	assert_true(lucian.item_cooldown(&"hextech_gunblade").is_ready())
    ```
- [ ] **Step 2:** Run the four files; expect the new asserts to FAIL (10 ≠ 9, `by_name` missing, bolt never reaches, cooldown still running).
- [ ] **Step 3: Implement.**
  - `EnergizeCharge.PER_ATTACK := 9.0`.
  - `ItemCatalog`:
    ```gdscript
    ## Every item by display name, A to Z (case ignored). The debug picker uses it.
    func by_name() -> Array[ItemData]:
    	var sorted: Array[ItemData] = items.duplicate()
    	sorted.sort_custom(func(a: ItemData, b: ItemData) -> bool: return a.display_name.nocasecmp_to(b.display_name) < 0)
    	return sorted
    ```
  - `DebugTable`: new `var _picker_items: Array[ItemData] = []`. In `setup`: `_picker_items = lucian.item_catalog.by_name()`, then fill `_item_picker` from it. `_give_picked_item` adds `_picker_items[_item_picker.selected]`.
  - `ItemActives.ROCKETBELT_RANGE := 900.0` with the comment `## How far the bolts fly from where Lucian stood when he used it.`
  - `Lucian.cheat_no_cooldowns` setter: after clearing skill cooldowns, `for cooldown: Cooldown in item_cooldowns.values(): cooldown.clear()`. Update its comment: "refreshes every skill and item cooldown already running".
  - `ItemPassives.on_basic_attack` Spellblade: `.start(0.0 if lucian.cheat_no_cooldowns else SPELLBLADE_COOLDOWN)`.
- [ ] **Step 4:** Run the four files, then the full suite → PASS.
- [ ] **Step 5:** Commit `"Energize +9 per attack, debug items A-Z, Rocketbelt bolts reach 900, no-cooldowns refreshes item cooldowns"`.

---

### Task 2: Skill bar: grey/locked "+", rank rule test, blocked tint, 45 px passive, new passive icon

**Files:** `src/core/champion_progress.gd`, `src/lucian/lucian.gd`, `src/lucian/skills/piercing_light.gd`, `src/ui/hud/skill_slot.gd`, `src/ui/hud/hud.gd`, `assets/art/ui/icon_passive.svg`; tests `test_champion_progress.gd`, `test_lucian_casting.gd`.

**Interfaces — Produces:** `ChampionProgress.next_rank_bought(slot) -> bool`, `ChampionProgress.is_maxed(slot) -> bool`, `PiercingLight.is_casting() -> bool`, `Lucian.is_skill_blocked(slot) -> bool`, `SkillSlot.setup(target, skill, icon, key, icon_size := ICON_SIZE)`, `SkillSlot.PASSIVE_SIZE := 45.0`.

- [ ] **Step 1: Failing tests.**
  - `test_champion_progress.gd` (use the file's existing progress variable):
    ```gdscript
    func test_basic_ranks_2_to_5_wait_for_levels_3_5_7_9() -> void:
    	for rank in [2, 3, 4, 5]:
    		progress.set_level(2 * rank - 2)
    		progress.ranks[Slot.Q] = rank - 1
    		assert_false(progress.can_rank_up(Slot.Q), "rank %d at level %d" % [rank, 2 * rank - 2])
    		progress.set_level(2 * rank - 1)
    		progress.ranks[Slot.Q] = rank - 1
    		assert_true(progress.can_rank_up(Slot.Q), "rank %d at level %d" % [rank, 2 * rank - 1])


    func test_next_rank_bought_and_maxed() -> void:
    	progress.bought[Slot.W] = 1
    	assert_true(progress.next_rank_bought(Slot.W))
    	progress.ranks[Slot.W] = 1
    	assert_false(progress.next_rank_bought(Slot.W))
    	progress.ranks[Slot.R] = 3
    	assert_true(progress.is_maxed(Slot.R))
    	assert_false(progress.is_maxed(Slot.Q))
    ```
  - `test_lucian_casting.gd`:
    ```gdscript
    func test_q_cast_greys_e() -> void:
    	lucian.progress.set_level(3)
    	lucian.try_rank_up(Slot.Q)
    	lucian.try_rank_up(Slot.E)
    	assert_false(lucian.is_skill_blocked(Slot.E))
    	assert_true(lucian.try_cast(Slot.Q, lucian.global_position + Vector2.RIGHT * 100))
    	assert_true(lucian.is_skill_blocked(Slot.E))
    	await wait_seconds(0.4)
    	assert_false(lucian.is_skill_blocked(Slot.E))


    func test_r_greys_q_and_w_but_not_e() -> void:
    	lucian.progress.set_level(6)
    	lucian.try_rank_up(Slot.R)
    	assert_true(lucian.try_cast(Slot.R, lucian.global_position + Vector2.RIGHT * 100))
    	assert_true(lucian.is_skill_blocked(Slot.Q))
    	assert_true(lucian.is_skill_blocked(Slot.W))
    	assert_false(lucian.is_skill_blocked(Slot.E))
    ```
- [ ] **Step 2:** Run both files → the rank test already PASSES (rule exists), the others FAIL (missing funcs).
- [ ] **Step 3: Implement.**
  - `ChampionProgress`:
    ```gdscript
    ## The next rank of `slot` is bought in the Evolution Tree.
    func next_rank_bought(slot: Slot) -> bool:
    	return ranks[slot] < mini(MAX_RANKS[slot], bought[slot])


    func is_maxed(slot: Slot) -> bool:
    	return ranks[slot] >= MAX_RANKS[slot]
    ```
  - `PiercingLight.is_casting() -> bool: return _fire_in > 0.0` (doc: "Q's cast time is still running.").
  - `Lucian`:
    ```gdscript
    ## Skills another skill holds back, greyed on the HUD: Q and W while R
    ## fires, E during Q's cast time.
    func is_skill_blocked(slot: ChampionProgress.Slot) -> bool:
    	match slot:
    		ChampionProgress.Slot.Q, ChampionProgress.Slot.W:
    			return (skills[ChampionProgress.Slot.R] as TheCulling).is_channeling()
    		ChampionProgress.Slot.E:
    			return (skills[ChampionProgress.Slot.Q] as PiercingLight).is_casting()
    	return false
    ```
  - `SkillSlot`:
    - consts `PASSIVE_SIZE := 45.0` (`## 70% of a skill icon.`), `PLUS_GREY := Color(0.45, 0.47, 0.52)`, `BLOCKED_TINT := Color(0.4, 0.4, 0.4)`; `var _icon_size := ICON_SIZE`, `var _plus_locked := false`.
    - `setup(..., icon_size := ICON_SIZE)`: `custom_minimum_size = Vector2(icon_size, PLUS_HEIGHT + ICON_SIZE + DOTS_HEIGHT)`; `icon_rect = Rect2(0, PLUS_HEIGHT + (ICON_SIZE - icon_size) * 0.5, icon_size, icon_size)`; `_draw_overlay` and the sweep use `_icon_size`; the lock and labels use `icon_rect`.
    - `_process`:
      ```gdscript
      # With a point to spend, every unmaxed skill shows its "+": gold when it
      # can rank up, grey (and locked if the rank isn't bought) when not.
      _plus.visible = progress.skill_points() > 0 and not progress.is_maxed(skill.slot) and not get_tree().paused
      _plus.disabled = not progress.can_rank_up(skill.slot)
      _plus_locked = not progress.next_rank_bought(skill.slot)
      _plus.queue_redraw()
      ```
      Tint order: rank 0 → `UNLEARNED_TINT`; `lucian.is_skill_blocked(skill.slot)` → `BLOCKED_TINT`; no mana → `NO_MANA_TINT`; else white.
    - `_draw_plus`: when `_plus.disabled` use `PLUS_GREY` for ring and "+", ignore hover/press; when `_plus_locked` also draw `LOCK_TEXTURE` 14 × 14 at `center + Vector2(PLUS_RADIUS - 2, -2)`.
  - `Hud.setup`: `_add_skill_slot(null, PASSIVE_ICON, "", SkillSlot.PASSIVE_SIZE)`, with `_add_skill_slot` passing `icon_size` through.
  - Redraw `assets/art/ui/icon_passive.svg` (128 px, `viewBox 0 0 64 64`, same `bg`/`glow` defs as `icon_q.svg`): two pistols (dark steel `#2b2f38` body, gold `#c9a45c` trim), one above the other, angled ~30° up-right, grips bottom-left; from each muzzle a ray (gold `#ffcf5a` 7 px at 0.5 opacity under a white `#fffbe8` 3 px core) to the top-right edge; a small glow circle at each muzzle. Update its comment to `<!-- Lightslinger: two relic pistols firing rays of light -->`.
- [ ] **Step 4:** Import, then run both test files and the full suite → PASS. Visual check: Task 10 `skillbar` scenario (or run it now).
- [ ] **Step 5:** Commit `"Skill bar: grey and locked rank-up buttons, Q/W grey during R and E during Q, smaller passive with new art"`.

---

### Task 3: Space recenters the camera

**Files:** `project.godot`, `src/core/game_settings.gd`, `src/stage/stage_camera.gd`, `src/ui/settings/settings_screen.gd` (none: the Controls tab lists `REBINDABLE` itself); test `tests/unit/test_stage_camera.gd` (new), `test_game_settings.gd`.

**Interfaces — Produces:** action `center_camera`; `StageCamera.center_on_target()`.

- [ ] **Step 1: Failing tests.**
  ```gdscript
  # tests/unit/test_stage_camera.gd
  extends GutTest


  func test_center_jumps_to_lucian_and_stays_free() -> void:
  	var target := Node2D.new()
  	target.position = Vector2(2400, 1350)
  	add_child_autofree(target)
  	var camera := StageCamera.new()
  	add_child_autofree(camera)
  	camera.setup(target, Rect2(0, 0, 4800, 2700))
  	camera.global_position = Vector2(1000, 1000)
  	camera.center_on_target()
  	assert_eq(camera.global_position, Vector2(2400, 1350))
  	assert_eq(camera.mode, StageCamera.Mode.FREE)
  ```
  In `test_game_settings.gd`: `assert_eq(settings.key_label(&"center_camera"), "Space")`.
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3: Implement.**
  - `project.godot` `[input]`: `center_camera` with one `InputEventKey` `physical_keycode = 32`, same shape as `toggle_camera`.
  - `GameSettings.REBINDABLE`: add `&"center_camera"` after `&"toggle_camera"`; `ACTION_NAMES[&"center_camera"] = "Center camera on Lucian"`.
  - `StageCamera`: update the class comment; in `_unhandled_input` add
    ```gdscript
    elif event.is_action_pressed(&"center_camera"):
    	center_on_target()
    	get_viewport().set_input_as_handled()
    ```
    and
    ```gdscript
    ## Jumps back over Lucian once. Free-cam stays free, so edge panning moves
    ## it away again.
    func center_on_target() -> void:
    	global_position = _clamped(_target.global_position)
    ```
- [ ] **Step 4:** Run both files + full suite → PASS.
- [ ] **Step 5:** Commit `"Space recenters the camera on Lucian"`.

---

### Task 4: Resolution setting

**Files:** `src/core/game_settings.gd`, `src/ui/settings/settings_screen.gd`; test `test_game_settings.gd`.

**Interfaces — Produces:** `GameSettings.RESOLUTIONS: Array[String]`, `GameSettings.parse_resolution(text: String) -> Vector2i` (static, `Vector2i.ZERO` when malformed), `GameSettings.apply_resolution()`.

- [ ] **Step 1: Failing tests** (`test_game_settings.gd`, using its scratch-path helper):
  ```gdscript
  func test_resolution_defaults_to_1600x900() -> void:
  	assert_eq(settings.get_value(&"resolution"), "1600x900")


  func test_parse_resolution() -> void:
  	assert_eq(GameSettings.parse_resolution("1920x1080"), Vector2i(1920, 1080))
  	assert_eq(GameSettings.parse_resolution("big"), Vector2i.ZERO)


  func test_resolution_round_trip_and_unknown_sizes_fall_back() -> void:
  	settings.set_value(&"resolution", "1920x1080")
  	assert_eq(GameSettings.new(settings.path).get_value(&"resolution"), "1920x1080")
  	settings.set_value(&"resolution", "123x45")
  	assert_eq(GameSettings.new(settings.path).get_value(&"resolution"), "1600x900")
  ```
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3: Implement.**
  - `DEFAULTS`: `## Window size in windowed mode, "WIDTHxHEIGHT".` `&"resolution": "1600x900",`
  - `const RESOLUTIONS := ["1280x720", "1366x768", "1600x900", "1920x1080", "2560x1440", "3840x2160"]`
  - `parse_resolution`: split on `"x"`, both parts `is_valid_int()` → `Vector2i`, else `Vector2i.ZERO`.
  - `_load`: skip a `resolution` value not in `RESOLUTIONS` (keeps the default).
  - ```gdscript
    ## Sizes and centers the window in windowed mode (a maximized window is
    ## restored first), never past the screen. Fullscreen modes keep the
    ## screen's own size.
    func apply_resolution() -> void:
    	if DisplayServer.get_name() == "headless" or _values[&"window_mode"] != "windowed":
    		return
    	var usable := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
    	var size := parse_resolution(_values[&"resolution"]).min(usable.size)
    	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
    		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
    	DisplayServer.window_set_size(size)
    	DisplayServer.window_set_position(usable.position + (usable.size - size) / 2)
    ```
  - `apply()` calls `apply_resolution()` last.
  - `SettingsScreen._build_graphics`: after Window mode, `_resolution = _option(page, "Resolution", &"resolution", labels, values)`. `values` = the `RESOLUTIONS` that fit `DisplayServer.screen_get_size()` (all of them when headless); `labels` = `value.replace("x", " × ")`. Below it a dim note: "Borderless and fullscreen use the screen's resolution." `_resolution.disabled = settings.get_value(&"window_mode") != "windowed"`.
  - `_on_changed`: `&"resolution"` → `settings.apply_resolution()`; `&"window_mode"` → `apply_display()`, then `apply_resolution()`, then refresh `_resolution.disabled`. Update the class comment's Graphics list.
- [ ] **Step 4:** Run the file + full suite → PASS. Manual: pick 1280×720 in windowed mode → the window resizes and centers; borderless → option greyed.
- [ ] **Step 5:** Commit `"Resolution setting in Graphics"`.

---

### Task 5: Stat icons, colors and item card lines

**Files:** `assets/art/stats/*.svg` (19, keys from the table above), `src/ui/stat_style.gd` (new), `src/core/item_stats.gd`, `src/ui/tooltip/tooltip_card.gd`, `src/ui/tooltip/tooltip_text.gd`; tests `test_item_stats.gd`, `tests/unit/test_stat_style.gd` (new).

**Interfaces — Produces:**
```gdscript
ItemStats.amount(key: StringName, value: float) -> String        # "+65", "+25%"
StatStyle.KEYS: Array[StringName]                                 # every styled key (ItemStats.NAMES keys + hp_regen, mana_regen, attack_range)
StatStyle.icon(key) -> Texture2D
StatStyle.color(key) -> Color
StatStyle.stat_name(key) -> String
StatStyle.description(key) -> String                              # TooltipText markup
StatStyle.item_line(key, value: float) -> String                  # BBCode: [img] icon, colored amount, name
```
- [ ] **Step 1: Failing tests.**
  - `test_item_stats.gd`: `assert_eq(ItemStats.amount(&"ad", 65.0), "+65")`, `assert_eq(ItemStats.amount(&"attack_speed", 0.25), "+25%")`; existing `line` asserts unchanged.
  - `tests/unit/test_stat_style.gd`:
    ```gdscript
    extends GutTest


    func test_every_stat_has_icon_color_name_and_description() -> void:
    	for key in StatStyle.KEYS:
    		assert_not_null(StatStyle.icon(key), str(key))
    		assert_ne(StatStyle.stat_name(key), "", str(key))
    		assert_ne(StatStyle.description(key), "", str(key))
    	for key: StringName in ItemStats.NAMES:
    		assert_has(StatStyle.KEYS, key)


    func test_item_line_is_icon_then_amount_then_name() -> void:
    	var line := StatStyle.item_line(&"ad", 65.0)
    	var icon_at := line.find("res://assets/art/stats/ad.svg")
    	var amount_at := line.find("+65")
    	var name_at := line.find("Attack Damage")
    	assert_true(icon_at >= 0 and icon_at < amount_at and amount_at < name_at, line)
    	assert_string_contains(line, StatStyle.color(&"ad").to_html(false))


    func test_ap_is_dark_blue_everywhere() -> void:
    	assert_eq(StatStyle.color(&"ap").to_html(false), TooltipText.COLORS["ap"])
    ```
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3: Implement.**
  - Draw the 19 SVGs (64 × 64, transparent, fill = stat color, `stroke="#1a1d24"` 2–3 px so they read on dark panels; simple silhouettes per the table). Then run the `--import` command.
  - `ItemStats.amount` (percent → `"+%d%%"` of value × 100, else `"+%d"`); `line` = `"%s %s" % [amount(key, value), NAMES[key]]`.
  - `src/ui/stat_style.gd`: `class_name StatStyle extends RefCounted`, `##` comment ("How each stat looks: icon, color, name and hover text. Item stat keys plus the panel-only hp_regen, mana_regen and attack_range."). Const dictionaries `ICONS` (preloads), `COLORS` (table above), `EXTRA_NAMES` (`hp_regen` "Health Regen", `mana_regen` "Mana Regen", `attack_range` "Attack Range"), `DESCRIPTIONS`. `move_speed_pct` resolves to `move_speed` for icon/color/description. `stat_name` = `ItemStats.NAMES.get(key, EXTRA_NAMES.get(key, String(key)))`. `item_line`:
    ```gdscript
    ## An item card stat line: the icon, the amount in the stat's color, then the name.
    static func item_line(key: StringName, value: float) -> String:
    	return "[img=20x20]%s[/img] %s %s" % [icon(key).resource_path,
    		TooltipText.color(ItemStats.amount(key, value), color(key).to_html(false)), ItemStats.NAMES[key]]
    ```
    `DESCRIPTIONS` (markup):
    | Key | Text |
    |---|---|
    | ad | Basic attacks deal this much [phys]physical damage[/phys]. Many skills grow with it. |
    | ap | Makes skills and item effects that scale with Ability Power stronger. |
    | armor | Lowers [phys]physical damage[/phys] taken: 100 armor blocks half. |
    | mr | Lowers [magic]magic damage[/magic] taken: 100 magic resist blocks half. |
    | attack_speed | Basic attacks per second (up to 2.5). |
    | ability_haste | Shortens skill cooldowns: 100 haste halves them. |
    | crit_chance | Chance for a basic attack to critically strike for 175% damage. |
    | move_speed | Units Lucian moves per second. |
    | max_hp | Lucian's health. |
    | max_mana | Spent to cast skills. |
    | hp_regen | [hp]Health[/hp] restored every 5 seconds. |
    | mana_regen | [mana]Mana[/mana] restored every 5 seconds. |
    | heal_shield_power | Makes heals and shields on Lucian stronger. |
    | armor_pen | Ignores this share of the target's armor. |
    | magic_pen | Ignores this share of the target's magic resist. |
    | lifesteal | Basic attacks heal Lucian for this share of their damage. |
    | omnivamp | All damage heals Lucian for this share of it. |
    | attack_range | How far basic attacks reach. |
    | tenacity | Shortens crowd control on Lucian. |
  - `TooltipCard.item`: `stats.append(StatStyle.item_line(key, shown.stats[key]))`.
  - `TooltipText.COLORS["ap"] = "4a6cf7"`; `StatStyle.COLORS[&"ap"] = Color(TooltipText.COLORS["ap"])`, so the two can't drift apart.
- [ ] **Step 4:** Run `test_item_stats`, `test_stat_style`, `test_tooltips` (item cards still build for every item) + full suite → PASS.
- [ ] **Step 5:** Commit `"Stat icons and colors; item cards show icon, amount and name"`.

---

### Task 6: Stats panels: icon + value, hover cards, Ctrl+C toggle, hold C for more

**Files:** `src/ui/hud/stats_panel.gd` (rewrite), `src/ui/hud/stat_cell.gd` (new), `src/ui/tooltip/tooltip_card.gd`, `src/ui/hud/hud.gd`, `src/core/game_settings.gd` (action name), `src/ui/settings/settings_screen.gd` (hint); test `tests/unit/test_stats_panel.gd` (new).

**Interfaces — Consumes:** `StatStyle` (Task 5). **Produces:** `StatsPanel.MAIN`, `StatsPanel.EXTRA`, `StatsPanel.keys`, `StatsPanel.value_text(lucian, key) -> String` (static), `StatCell.new(key)`, `TooltipCard.stat(key, value: String) -> Control`, `Hud.extra_stats: StatsPanel`.

- [ ] **Step 1: Failing tests** (`test_stats_panel.gd`; Lucian from `lucian.tscn` like the other scene tests):
  ```gdscript
  func test_value_texts() -> void:
  	lucian.cheat_crit_chance = 0.5
  	assert_eq(StatsPanel.value_text(lucian, &"crit_chance"), "50%")
  	assert_eq(StatsPanel.value_text(lucian, &"attack_speed"), "%.2f" % lucian.stats.attack_speed)
  	assert_eq(StatsPanel.value_text(lucian, &"attack_range"), "500")
  	assert_eq(StatsPanel.value_text(lucian, &"hp_regen"), TooltipText.number(snappedf(lucian.stats.hp_regen * 5.0, 0.1)))
  	for key in StatsPanel.MAIN + StatsPanel.EXTRA:
  		assert_ne(StatsPanel.value_text(lucian, key), "", str(key))


  func test_panels_have_one_cell_per_stat() -> void:
  	var extra := StatsPanel.new()
  	extra.keys = StatsPanel.EXTRA
  	add_child_autofree(extra)
  	var grid := extra.get_child(0)
  	assert_eq(grid.get_child_count(), 9)
  	assert_true(grid.get_child(0) is StatCell)


  func test_stat_cards_build() -> void:
  	for key in StatsPanel.MAIN + StatsPanel.EXTRA:
  		var card := TooltipCard.stat(key, "1")
  		assert_not_null(card, str(key))
  		card.free()


  func test_ctrl_key_toggles_and_holding_shows_extra() -> void:
  	var hud: Hud = load("res://src/ui/hud/hud.tscn").instantiate()
  	add_child_autofree(hud)
  	hud.setup(lucian, Wallet.new())
  	var press := InputEventKey.new()
  	press.physical_keycode = KEY_C
  	press.pressed = true
  	press.ctrl_pressed = true
  	hud._unhandled_input(press)
  	assert_false(hud.stats_panel.visible)
  	Input.action_press(&"toggle_stats")
  	await wait_process_frames(2)
  	assert_true(hud.extra_stats.visible)
  	Input.action_release(&"toggle_stats")
  	await wait_process_frames(2)
  	assert_false(hud.extra_stats.visible)
  ```
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3: Implement.**
  - `StatCell` (`HBoxContainer`, separation 6, `mouse_filter = MOUSE_FILTER_PASS`): a 20 × 20 `TextureRect` (`StatStyle.icon`, mouse ignored) and a value `Label` (font 16, `UiStyle.TEXT_COLOR`, min width 44, mouse ignored). `set_value(text)`, `tooltip_content()` → `TooltipCard.stat(key, _value.text)`, `tooltip_place()` → `HoverTip.Place.ABOVE`. `##` comment: "One stat in the stats panel: its icon and value. Hover it for a second to read what it does."
  - `StatsPanel` rewrite: consts `MAIN` / `EXTRA` (orders from Defaults), `var keys: Array[StringName] = MAIN`, `_ready` builds a 2-column `GridContainer` (h 18, v 4) of `StatCell`s. `_process` returns early when hidden; otherwise sets each cell from `value_text`. `value_text`: `attack_speed` → `"%.2f"`, `crit_chance` → `lucian.crit_chance()` as `%`, `move_speed` → `lucian.current_move_speed()`, `attack_range` → `lucian.attack_range()`, `hp_regen` / `mana_regen` → per 5 s via `TooltipText.number(snappedf(x * 5.0, 0.1))`, other `ItemStats.is_percent` keys → `%`, else `roundi`. Values are read from `lucian.stats.get(key)`.
  - `TooltipCard.stat(key, value)`: `_card(icon, StatStyle.stat_name(key), "Stat", TooltipText.color(value, StatStyle.color(key).to_html(false)))` + `_body(card, TooltipText.colorize(StatStyle.description(key)))`.
  - `Hud`:
    - `var extra_stats := StatsPanel.new()` with `keys = StatsPanel.EXTRA`, same `panel` stylebox as `bottom_panel`, anchored like `stats_panel` (PRESET_CENTER_BOTTOM, grow begin/begin), added to `$Root`, hidden; `extra_stats.lucian = target` in `setup`.
    - `_unhandled_input`:
      ```gdscript
      # Ctrl + the stats key toggles the main panel. Holding the key alone shows
      # the extra stats (see _process).
      if event.is_action_pressed(&"toggle_stats") and (event as InputEventWithModifiers).ctrl_pressed:
      	stats_panel.visible = not stats_panel.visible
      	get_viewport().set_input_as_handled()
      ```
    - `_process`: `extra_stats.visible = Input.is_action_pressed(&"toggle_stats") and not Input.is_key_pressed(KEY_CTRL)`. When visible, place it: the same left/right offsets as `stats_panel`, and `offset_bottom = -12.0 - (stats_panel.size.y + STATS_GAP if stats_panel.visible else 0.0)`.
    - Update the class comment.
  - `GameSettings.ACTION_NAMES[&"toggle_stats"] = "Stats panel (Ctrl: toggle, hold: more)"`; the Controls hint gets one more line: "Ctrl + the stats key toggles the stats panel; hold it for more stats."
- [ ] **Step 4:** Run `test_stats_panel` + full suite → PASS. Visual check: Task 10 `stats` scenario.
- [ ] **Step 5:** Commit `"Stats panel with stat icons and hover cards; Ctrl+C toggles it, holding C shows more stats"`.

---

### Task 7: Rapid Firecannon range ring

**Files:** `src/lucian/items/item_passives.gd`, `src/lucian/lucian.gd`; test `test_item_passives.gd`.

**Interfaces — Produces:** `ItemPassives.shows_rfc_ring() -> bool`, `ItemPassives.RFC_RING_WAIT := 1.0`.

- [ ] **Step 1: Failing test** (`test_item_passives.gd`, using its `equip` helper and dummy):
  ```gdscript
  func test_rfc_ring_shows_from_full_energize_until_the_shot_lands() -> void:
  	equip(&"rapid_firecannon")
  	assert_false(lucian.passives.shows_rfc_ring())
  	lucian.passives.energize.value = 100.0
  	assert_true(lucian.passives.shows_rfc_ring())
  	var info := lucian.basic_attack(dummy)
  	assert_true(lucian.passives.shows_rfc_ring(), "the Energized shot is still flying")
  	dummy.take_damage(info)
  	assert_false(lucian.passives.shows_rfc_ring())


  func test_rfc_ring_gives_up_when_the_shot_never_lands() -> void:
  	equip(&"rapid_firecannon")
  	lucian.passives.energize.value = 100.0
  	lucian.basic_attack(dummy)
  	await wait_seconds(1.2)
  	assert_false(lucian.passives.shows_rfc_ring())
  ```
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3: Implement.**
  - `ItemPassives`: `## Seconds the RFC ring waits for the Energized shot before giving up (its target may vanish).` `const RFC_RING_WAIT := 1.0`; `var _rfc_shot_left := 0.0`. In `on_basic_attack`'s consume branch: `if has(&"rapid_firecannon"): _rfc_shot_left = RFC_RING_WAIT`. In `_energized_hit`: `_rfc_shot_left = 0.0`. In `_physics_process`: `_rfc_shot_left = maxf(_rfc_shot_left - delta, 0.0)`.
    ```gdscript
    ## Rapid Firecannon's longer reach is shown as a ring from full Energize
    ## until the Energized shot lands.
    func shows_rfc_ring() -> bool:
    	return has(&"rapid_firecannon") and (energize.is_ready() or _rfc_shot_left > 0.0)
    ```
  - `Lucian`: `const RFC_RING_COLOR := Color(0.62, 0.85, 1.0, 0.45)`; `var _rfc_ring_shown := false`. In `_physics_process`, right after `_tick_buffs(delta)` (before any early return):
    ```gdscript
    if passives.shows_rfc_ring() != _rfc_ring_shown:
    	_rfc_ring_shown = not _rfc_ring_shown
    	queue_redraw()
    ```
    `_draw`: keep the attack-move ring first; `elif _rfc_ring_shown:` draw `stats.attack_range * (1.0 + ItemPassives.RFC_RANGE)` in `RFC_RING_COLOR`, the same arc call.
- [ ] **Step 4:** Run the file + full suite → PASS. Visual check: Task 10 `rfc_ring`.
- [ ] **Step 5:** Commit `"Rapid Firecannon shows its range ring while Energized until the shot lands"`.

---

### Task 8: Summoner spells (data, logic, Lucian, keys)

**Files:** `src/core/summoner_data.gd` (new), `data/summoners/*.tres` (6, new), `assets/art/summoners/*.svg` (6, new), `src/lucian/summoners/summoner_spells.gd` (new), `src/lucian/lucian.gd`, `src/lucian/lucian_controller.gd`, `src/lucian/items/item_actives.gd`, `src/ui/hud/hud.gd` (shield total only); test `tests/unit/test_summoner_spells.gd` (new).

**Interfaces — Produces:**
```gdscript
class SummonerData extends Resource: id: StringName, display_name: String, icon: Texture2D, cooldown: float, description: String
SummonerSpells.SPELLS: Array[SummonerData]          # flash, ghost, barrier, heal, clarity, smite
SummonerSpells.find(id) -> SummonerData              # static
SummonerSpells.slots: Array[StringName]              # [&"flash", &"heal"]; index 0 = D, 1 = F
SummonerSpells.spell_in(slot: int) -> SummonerData
SummonerSpells.set_spell(slot: int, id: StringName)  # swaps when id is on the other key
SummonerSpells.cooldown(id) -> Cooldown
SummonerSpells.clear_cooldowns()
SummonerSpells.use(slot: int, aim: Vector2) -> bool
Lucian.summoners: SummonerSpells
Lucian.use_summoner(slot: int, aim: Vector2) -> bool
Lucian.enemy_near_cursor(aim: Vector2, reach: float) -> Enemy   # nearest the cursor among enemies within reach (+radius) of Lucian
Lucian.fits_at(point: Vector2) -> bool
Lucian.blink_to(point: Vector2)
Lucian.set_ghosted(seconds: float); Lucian.is_ghosted() -> bool
Lucian.barrier: float; Lucian.add_barrier(amount: float, seconds: float); Lucian.total_shield() -> float
```
- [ ] **Step 1: Failing tests** (`test_summoner_spells.gd`; Lucian at the origin, dummy at `(0, -2000)` unless moved; `await wait_physics_frames(2)` in `before_each` so bodies are in the physics space; `sources` collected like `test_item_actives`):
  ```gdscript
  func test_spell_data_is_complete() -> void:
  	var ids := []
  	for spell in SummonerSpells.SPELLS:
  		assert_ne(spell.display_name, "", str(spell.id))
  		assert_not_null(spell.icon, str(spell.id))
  		assert_between(spell.cooldown, 30.0, 90.0, str(spell.id))
  		assert_ne(spell.description, "", str(spell.id))
  		ids.append(spell.id)
  	assert_eq(ids, [&"flash", &"ghost", &"barrier", &"heal", &"clarity", &"smite"])


  func test_defaults_and_swapping() -> void:
  	assert_eq(lucian.summoners.slots, [&"flash", &"heal"])
  	lucian.summoners.set_spell(1, &"flash")
  	assert_eq(lucian.summoners.slots, [&"heal", &"flash"])


  func test_flash_blinks_400_toward_the_cursor_and_keeps_its_cooldown_on_the_other_key() -> void:
  	assert_true(lucian.use_summoner(0, Vector2(1000, 0)))
  	assert_almost_eq(lucian.global_position, Vector2(400, 0), Vector2(0.5, 0.5))
  	assert_false(lucian.use_summoner(0, Vector2(1000, 0)), "on cooldown")
  	lucian.summoners.set_spell(1, &"flash")
  	assert_false(lucian.use_summoner(1, Vector2(1000, 0)), "the cooldown moved with it")


  func test_flash_stops_short_of_an_enemy_body() -> void:
  	dummy.position = Vector2(350, 0)
  	await wait_physics_frames(2)
  	lucian.use_summoner(0, Vector2(400, 0))
  	assert_lt(lucian.global_position.x, 350.0)
  	assert_true(lucian.fits_at(lucian.global_position))


  func test_ghost_speeds_up_and_passes_through_enemies() -> void:
  	lucian.summoners.set_spell(0, &"ghost")
  	var speed := lucian.current_move_speed()
  	assert_true(lucian.use_summoner(0, Vector2.ZERO))
  	assert_almost_eq(lucian.current_move_speed(), speed * 1.4, 0.01)
  	assert_eq(lucian.collision_mask, Layers.WORLD)
  	lucian.set_ghosted(0.1)
  	await wait_seconds(0.2)
  	assert_eq(lucian.collision_mask, Layers.WORLD | Layers.ENEMY_BODY)


  func test_barrier_heal_and_clarity() -> void:
  	lucian.summoners.slots = [&"barrier", &"heal"]
  	assert_true(lucian.use_summoner(0, Vector2.ZERO))
  	assert_almost_eq(lucian.total_shield(), 95.0 + 18.0, 0.01)
  	lucian.hp = 100.0
  	assert_true(lucian.use_summoner(1, Vector2.ZERO))
  	assert_almost_eq(lucian.hp, 195.0, 0.01)
  	lucian.summoners.slots = [&"clarity", &"heal"]
  	lucian.mana = 0.0
  	assert_true(lucian.use_summoner(0, Vector2.ZERO))
  	assert_almost_eq(lucian.mana, lucian.stats.max_mana * 0.5, 0.01)


  func test_barrier_runs_out() -> void:
  	lucian.add_barrier(50.0, 0.1)
  	await wait_seconds(0.2)
  	assert_eq(lucian.total_shield(), 0.0)


  func test_smite_deals_true_damage_and_heals() -> void:
  	dummy.position = Vector2(400, 0)
  	lucian.summoners.set_spell(0, &"smite")
  	lucian.hp = 100.0
  	assert_true(lucian.use_summoner(0, dummy.position))
  	assert_eq(sources, [&"smite"])
  	assert_almost_eq(finals[0], 450.0, 0.01)
  	assert_almost_eq(lucian.hp, 100.0 + lucian.stats.max_hp * 0.1, 0.01)


  func test_smite_needs_an_enemy_in_reach() -> void:
  	lucian.summoners.set_spell(0, &"smite")
  	assert_false(lucian.use_summoner(0, dummy.position))
  	assert_true(lucian.summoners.cooldown(&"smite").is_ready())


  func test_no_cooldowns_refreshes_summoners() -> void:
  	lucian.use_summoner(0, Vector2(100, 0))
  	lucian.cheat_no_cooldowns = true
  	assert_true(lucian.summoners.cooldown(&"flash").is_ready())
  ```
  (`finals` collects `final_amount` next to `sources`.)
- [ ] **Step 2:** Run → FAIL (classes missing).
- [ ] **Step 3: Implement.**
  - `SummonerData` (`## One summoner spell's card: name, icon, cooldown and text. Its numbers live in SummonerSpells.`), exports as in Interfaces, `@export_multiline var description := ""`.
  - Six `.tres` files (`script_class="SummonerData"`), cooldowns from the Defaults table, descriptions in markup, e.g. Flash: `"Blink up to [kw]400[/kw] units toward the cursor. Walls and enemies stop it short."`, Barrier: `"Gain a shield of [kw]95 (+18 per level)[/kw] for [kw]2.5 s[/kw]."`, Heal: `"Restore [hp]80 (+15 per level) health[/hp] and gain [ms]30% move speed[/ms] that fades over 1 s."`, Ghost: `"Gain [ms]40% move speed[/ms] and pass through enemies for [kw]6 s[/kw]."`, Clarity: `"Restore [mana]50% of max mana[/mana]."`, Smite: `"Deal [true]450 true damage[/true] to the enemy nearest the cursor within [kw]500[/kw] units and restore [hp]10% max health[/hp]."`
  - Six summoner SVGs (designs in Defaults; 128 px, `viewBox 0 0 64 64`, full background) + `--import`.
  - `SummonerSpells` (`extends Node`): constants `FLASH_RANGE 400`, `FLASH_STEP 10`, `GHOST_SPEED 0.4`, `GHOST_TIME 6`, `BARRIER_BASE 95`, `BARRIER_PER_LEVEL 18`, `BARRIER_TIME 2.5`, `HEAL_BASE 80`, `HEAL_PER_LEVEL 15`, `HEAL_SPEED 0.3`, `HEAL_SPEED_TIME 1`, `CLARITY_MANA 0.5`, `SMITE_RANGE 500`, `SMITE_DAMAGE 450`, `SMITE_HEAL 0.1`; `SPELLS` preloads; `_cooldowns := {}` (id → Cooldown) reduced in `_physics_process`.
    ```gdscript
    ## Casts the spell on `slot` (0 = D, 1 = F) toward `aim`. False on cooldown,
    ## while dashing, or for Smite with no enemy in reach.
    func use(slot: int, aim: Vector2) -> bool:
    	var spell := spell_in(slot)
    	if spell == null or lucian.is_dashing() or not cooldown(spell.id).is_ready():
    		return false
    	match spell.id:
    		&"flash":
    			_flash(aim)
    		&"ghost":
    			lucian.add_speed_buff(&"ghost", 0.0, GHOST_SPEED, GHOST_TIME)
    			lucian.set_ghosted(GHOST_TIME)
    			Sfx.play(&"potion")
    		&"barrier":
    			lucian.add_barrier(BARRIER_BASE + BARRIER_PER_LEVEL * lucian.progress.level, BARRIER_TIME)
    			Sfx.play(&"potion")
    		&"heal":
    			lucian.heal(HEAL_BASE + HEAL_PER_LEVEL * lucian.progress.level)
    			lucian.add_speed_buff(&"heal", 0.0, HEAL_SPEED, HEAL_SPEED_TIME, true)
    			Sfx.play(&"potion")
    		&"clarity":
    			lucian.restore_mana(lucian.stats.max_mana * CLARITY_MANA)
    			Sfx.play(&"potion")
    		&"smite":
    			if not _smite(aim):
    				return false
    	cooldown(spell.id).start(0.0 if lucian.cheat_no_cooldowns else spell.cooldown)
    	return true
    ```
    `_flash`: `from`, `direction = lucian.aim_direction(aim)`, `distance = minf(from.distance_to(aim), FLASH_RANGE)`; while `distance > 0 and not lucian.fits_at(from + direction * distance)`: `distance -= FLASH_STEP`; `lucian.blink_to(from + direction * maxf(distance, 0.0))`; `DashTrail` from `from` to the new spot unless `low_effects()`; `Sfx.play(&"zap")`. `_smite`: `target = lucian.enemy_near_cursor(aim, SMITE_RANGE)`; null → false; `take_damage(lucian.make_damage(SMITE_DAMAGE, DamageInfo.Type.TRUE, &"smite"))`, `lucian.heal(lucian.stats.max_hp * SMITE_HEAL)`, a `ChainLightning` from Lucian to the target in `Color("ffb347")`, `Sfx.play(&"zap")`, true.
  - `Lucian`:
    - `var summoners := SummonerSpells.new()`, set up and added in `_ready` like `actives` (name `"SummonerSpells"`). `use_summoner(slot, aim) -> bool: return summoners.use(slot, aim)`.
    - Cheat setter: also `summoners.clear_cooldowns()`.
    - `enemy_near_cursor(aim, reach)`: the loop now inside `ItemActives._gunblade`; `_gunblade` calls it with `GUNBLADE_RANGE`.
    - `fits_at(point)`: `PhysicsShapeQueryParameters2D` with `$CollisionShape2D.shape`, `Transform2D(0.0, point)`, `collision_mask = _body_mask()`, `exclude = [get_rid()]`, bodies only; true when `intersect_shape(query, 1)` is empty.
    - `blink_to(point)`: `global_position = point`; `_last_position = point` (a blink doesn't build Energize).
    - Ghost: `var _ghost_left := 0.0`; `set_ghosted(seconds)` sets it and `collision_mask = _body_mask()`; `is_ghosted()`; `_body_mask() -> int: return Layers.WORLD if is_ghosted() or is_dashing() else Layers.WORLD | Layers.ENEMY_BODY`. `_dash_step`'s end uses `collision_mask = _body_mask()`. `_tick_buffs` counts `_ghost_left` down and resets the mask when it hits 0.
    - Barrier: `var barrier := 0.0`, `_barrier_left`, `_barrier_duration`; `add_barrier()`; `_tick_buffs` clears it at 0; `total_shield() -> float: return shield + barrier`. `buffs()` adds `{"id": &"barrier", "name": "Barrier", "icon": SummonerSpells.find(&"barrier").icon, "text": "A shield that absorbs %d damage." % roundi(barrier), "count": str(roundi(barrier)), "left": _barrier_left, "duration": _barrier_duration, "ready": false}` while `barrier > 0`.
    - `SPEED_BUFF_NAMES` adds `&"ghost": "Ghost"`, `&"heal": "Heal"`.
  - `Hud`: HP text and `_draw_shield` use `lucian.total_shield()`.
  - `LucianController`: `const SUMMONER_ACTIONS: Array[StringName] = [&"summoner_d", &"summoner_f"]`; loop like `ITEM_ACTIONS`, calling `lucian.use_summoner(slot, _cursor())`.
- [ ] **Step 4:** Import; run `test_summoner_spells`, `test_item_actives` (Gunblade still works), `test_tooltips` (buff count unchanged without Barrier) + full suite → PASS.
- [ ] **Step 5:** Commit `"Summoner spells: Flash, Ghost, Barrier, Heal, Clarity and Smite on D and F"`.

---

### Task 9: Summoner HUD slots, tooltip card, debug picker

**Files:** `src/ui/hud/summoner_slot.gd` (new), `src/ui/hud/hud.gd`, `src/ui/tooltip/tooltip_card.gd`, `src/ui/debug/debug_table.gd`; test `test_tooltips.gd`.

**Interfaces — Consumes:** `SummonerSpells` (Task 8). **Produces:** `SummonerSlot.new(lucian, slot: int)`, `TooltipCard.summoner(spell: SummonerData, key: String) -> Control`.

- [ ] **Step 1: Failing test** (`test_tooltips.gd`):
  ```gdscript
  func test_summoner_cards_build() -> void:
  	for spell in SummonerSpells.SPELLS:
  		var card := TooltipCard.summoner(spell, "D")
  		assert_not_null(card, str(spell.id))
  		card.free()
  ```
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3: Implement.**
  - `TooltipCard.summoner`: header (icon, `display_name`, `"Summoner spell [%s]" % key`), a body line `Cooldown: N s` (dim label), separator, `TooltipText.colorize(spell.description)`.
  - `SummonerSlot` (`extends Control`; `##` "One summoner spell on the HUD: icon, cooldown sweep and seconds, key label. Hover for its card."): `const SIZE := 48.0`; `custom_minimum_size = Vector2(SIZE, SkillSlot.PLUS_HEIGHT + SkillSlot.ICON_SIZE + SkillSlot.DOTS_HEIGHT)`; icon rect `Rect2(0, SkillSlot.PLUS_HEIGHT + (SkillSlot.ICON_SIZE - SIZE) * 0.5, SIZE, SIZE)`. `_process` → `queue_redraw()`. `_draw` follows `HudItemSlot._draw`: fill, `draw_texture_rect(spell.icon, …)`, sweep translated to the icon rect, seconds, frame, key from `GameSettings.instance().key_label(LucianController.SUMMONER_ACTIONS[slot])`. `_has_point(point)` → only the icon rect counts for hovering. `tooltip_content()` → `TooltipCard.summoner(...)`; `tooltip_place()` → `ABOVE`.
  - `Hud.setup`: after the skill slots, a 10 px spacer `Control` and `SummonerSlot.new(target, 0)`, `SummonerSlot.new(target, 1)` into `skill_row`.
  - `DebugTable` Lucian tab, new section "Summoner spells": a row `D` [OptionButton] `F` [OptionButton], both listing `SummonerSpells.SPELLS` names. `item_selected` → `lucian.summoners.set_spell(slot, SPELLS[index].id)`, then re-`select()` both pickers from `lucian.summoners.slots` (`select()` emits nothing, so there's no loop). Pickers are filled and synced in `setup`.
- [ ] **Step 4:** Run `test_tooltips` + full suite → PASS. Visual check: Task 10 `summoners`.
- [ ] **Step 5:** Commit `"Summoner slots on the HUD with cards; debug picker for D and F"`.

---

### Task 10: Screenshots, docs, report

**Files:** `tests/tools/screenshot.gd`, `docs/ui_design.md`, `docs/lucian_game_design.md`, `docs/items.md`, `docs/implementation/phase4.md`, `docs/report/phase4.md`, `docs/report/phase4/*.png`.

- [ ] **Step 1: New screenshot scenarios** (add to the `match` in `_run`, same style as the existing ones, each printing expected vs actual):
  - `stats`: `stats_0_main` (main panel), `stats_1_extra` (`Input.action_press(&"toggle_stats")`), `stats_2_hover` (`HoverTip.show_for` a cell), `stats_3_item_card` (Infinity Edge card with stat icons).
  - `skillbar`: level 2 with Q rank 1 and one point left → gold W/E "+", grey Q (needs level 3) and R; `progress.bought[W] = 0` → grey "+" with a lock: `skillbar_0_plus`. Cast R → `skillbar_1_r_greys_qw`; cast Q → `skillbar_2_q_greys_e`. The 45 px passive with its new art shows in all of them.
  - `camera`: free-cam moved 1200 px away (`camera_0_away`), `center_on_target()` (`camera_1_back`), print the camera vs Lucian position.
  - `rfc_ring`: RFC equipped, energize 100 → `rfc_ring_0_ready`; after the shot lands → `rfc_ring_1_gone`.
  - `summoners`: D/F slots on the HUD (`summoners_0_hud`), Flash before/after with a trail, Barrier + Ghost buffs on the buff bar, Smite bolt with a true-damage number, cooldown sweeps, card hover (`summoners_1…5`).
  - Rerun: `hud`, `tooltip`, `buffs`, `energized`, `actives` (Rocketbelt arc reaches farther), `settings` (Graphics tab shows Resolution; Controls lists "Center camera on Lucian").
- [ ] **Step 2: Docs.**
  - `ui_design.md`: §1 HUD (passive 70% size; grey/locked "+" rules; blocked tint; summoner slots), Stats panel section (main/extra tables, icons/colors table, hover cards, Ctrl+C / hold C), item info pop-up (icon → amount → name), tooltip color list (AP blue), §5 Graphics (Resolution), Controls (Space).
  - `lucian_game_design.md`: §2 Controls table (Ctrl + C toggle, hold C, Space recenters); §5 note that rank *r* needs level 2*r*−1; §8 the numbers table and "D/F are picked in the debug table until the Evolution Tree exists"; §16 Phase 4 link.
  - `items.md`: Energize +9 per attack; Rocketbelt bolts fly 900 from where Lucian started; RFC ring note.
  - `docs/implementation/phase4.md`: append "Implementation notes (Phase 4 done)", the same format as Phase 3 (what changed while building, commits merged, review fixes).
  - `docs/report/phase4.md`: the Phase 3 report's format: what's new per point (1–16), screenshots table, a manual playtest checklist, open questions.
- [ ] **Step 3:** Full GUT run + every new and rerun scenario; check each printed value against the expectation.
- [ ] **Step 4:** Run `superpowers:requesting-code-review` on the Phase 4 diff; fix what holds up and note it under "Fixes from the code review".
- [ ] **Step 5:** Commit `"Add the Phase 4 report with screenshots"` (and a separate commit for review fixes if any).

## Verification

**Automated:** full GUT suite green after every task (command above). New/extended files: `test_energize`, `test_item_catalog`, `test_item_actives`, `test_item_passives`, `test_champion_progress`, `test_lucian_casting`, `test_stage_camera`, `test_game_settings`, `test_item_stats`, `test_stat_style`, `test_stats_panel`, `test_summoner_spells`, `test_tooltips`.

**Screenshots:** `stats`, `skillbar`, `camera`, `rfc_ring`, `summoners` + reruns, saved to `docs/report/phase4/`.

**Manual playtest checklist (goes into the report):**
1. Equip Statikk: each basic attack raises the Energized number by 9.
2. F3 + Q → Items: picker runs A→Z.
3. Rocketbelt: bolts fly about 900 from the start point.
4. Use Gunblade, then tick "No cooldowns": the slot's cooldown clears at once (same for D/F).
5. Level 2 with a point: Q "+" grey until level 3; R "+" grey until 6.
6. Space snaps the free camera back to Lucian; edge-panning still works after.
7. Stats: Ctrl + C hides/shows the table; holding C shows the extra one; hover a stat 1 s → card; item cards show icons.
8. RFC + full Energize: the blue ring appears and disappears when the shot lands.
9. D/F: every spell works; swap them in the debug table; cooldowns show on the HUD and keep running when moved to the other key.
10. Cast R: Q/W grey. Cast Q: E grey for its cast time.
11. Settings → Graphics → Resolution: the window resizes and centers; greyed in fullscreen; kept after a restart.

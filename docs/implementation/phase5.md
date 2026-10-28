# Phase 5: Main screen, save system, Evolution Tree, Skin Shop and Journey (implementation plan)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The game opens on a main screen instead of the stage. That screen has three working sections:
- **Journey:** Training starts. Acts and Endless are designed and shown, but locked or "coming later".
- **Evolution Tree:** a forest of 31 nodes, bought with essences, that changes what Lucian has in Training.
- **Skin Shop:** buy and equip 5 skins that change his stats and colors.

Behind them:
- A 3-slot save system: slot 1 for now, with backups.
- A gear menu.
- A save prompt whenever the player leaves.
- An F3 + Q debug table on the main screen.
- New art: essence icons, gear, skull, 31 tree node icons and 4 skins.

**Architecture:** Same layering as Phases 1–4:
- **Pure logic** in `src/core/`, tested with GUT first: `Essences`, `SaveGame`, `EvolutionTree`, `Journey`, `StageSetup`, `SkinData` / `Skins`.
- **Data** as `.tres`: `data/tree/*`, `data/skins/*`.
- **UI** built in code under `src/ui/main/`.
- **A new root scene** `src/main/game.tscn` (`Game`). It shows `MainScreen`, swaps in `stage.tscn` for Training, and comes back when the stage ends.
- **The bridge:** the stage gets everything permanent through one `StageSetup` built from the save. A plain `StageSetup.new()` is today's sandbox (everything unlocked), so `stage.tscn` run on its own (tests, screenshots, F6) behaves exactly as in Phase 4.

**Tech Stack:** Godot 4.7.2 (GDScript), GUT 9.7.1, the `tests/tools/screenshot.gd` harness, hand-written SVG.

**Spec:**
- `docs/main_screen.md`: sections, gear menu, tree UI, skins, Journey.
- `docs/lucian_game_design.md`: §8 summoners, §9 currencies, §10 skins, §11 Evolution Tree, §12 acts, §14 Endless, §15 save system.
- The user's Phase 5 request (quoted under Context).

## Context

The user's Phase 5 list:
1. Add the main screen. Starting the game opens it directly.
2. Add every main screen feature (`docs/main_screen.md`): Journey, Evolution Tree, Skin Shop.
3. Add the save system.
4. Design the act, Endless and Training choosers. Only Training works now; the rest comes later.
5. The Evolution Tree and Skin Shop work now.
6. A debug table on the main screen, toggled with F3 + Q like the stage's, hidden by default.
7. The debug table adds blue, orange and purple essence.
8. Design the blue, orange and purple essence icons.
9. Design icons for every Evolution Tree node.

The save rule was settled just before this plan (already in the docs):
- The game saves **only when a stage is done** (cleared, left or failed), from the gear menu's **Save**, and on a **Yes** to **"Save before leaving?"**.
- Main screen purchases never save by themselves.
- The current slot is slot 1 until a slot selection screen exists.

### Decisions made with the user
| Topic | Decision |
|---|---|
| Essences | **Blue / orange / purple**, as the docs say ("green" in the request was a typo). |
| Picking D/F spells | A **loadout panel in Journey**, next to Start. It lists only bought spells. F is chained until the 2nd slot is bought. Picking the spell already on the other key swaps them. The choice is saved with the progress. |
| Skin art | **5 card portraits** (Classic reuses today's portrait). In the stage, **Lucian's body sprite and HUD portrait** follow the equipped skin. |
| Tree icons | **New art for every node (31 SVGs)**, even where a skill, stat or spell icon already exists. |
| Spell nodes | **Separate nodes:** an unlock node per spell, an upgrade node (3 levels) above each, and the 2nd slot node. |
| Training | **The tree decides.** A new save starts with no skill ranks, no passive, 1 equip slot, 2 shop items and no spells. The stage debug table can still override these for that run. `stage.tscn` on its own stays the Phase 4 sandbox. |

### Defaults chosen during planning (placeholders, tune later)
- **Startup:** the game loads slot 1 (a new game if there's no file; nothing is written until the first save). It opens on **Journey → Training**.
- **New game:** 0 essences, nothing bought, Classic owned and equipped, D and F empty, nothing cleared, best Endless wave 0.
- **Tree nodes have levels:**
  - Q, W and E are one node each with 5 levels, R one node with 3.
  - Equip slots are one node (5 levels: slots 2–6), Merchant stock one node (2 levels: 3 and 4 items).
  - The doc's cost tables map onto the levels unchanged.
  - **E level 1 costs 0** and is hidden until Act 1 is cleared ("free Act 1 reward"). A tree reset takes it back like any level, and it's free to rebuy.
- **Values the doc leaves open:**
  - **Stat nodes, per level:** AD +4, AP +8, HP +40, Armor +4, MR +4, Attack Speed +3%, Mana +40. These count as **bonus** stats (yellow in the stats panel).
  - **Refresh cost node:** 2 levels at 200 blue, then 500 blue + 5 orange. Each level is −25 gold (100 → 75 → 50).
  - **Spell upgrades, per level:** Flash and Ghost get 10% shorter cooldowns. Barrier shield, Heal healing, Clarity mana and Smite damage get +15%.
- **Stage gold, bonus XP and essence drop nodes** can be bought and are saved. Nothing in Training gives gold, XP or essences yet, so they change nothing until enemies exist. No unused hooks are added for them.
- **Skin numbers:**
  - Bonus attack speed and move speed go through the bonus keys (`attack_speed`, `move_speed_pct`), like items.
  - AD, AP and max HP % are multipliers on the final stats, after item passives.
  - Vampire's "kills heal 2% max HP" works on real kills. Training dummies never die, so it is unit-tested only.
- **Buying a skin doesn't equip it.** There is no confirm step; the button is disabled (price in red) when the player can't afford it.
- **Gear menu:** "Leave to main menu" is shown **disabled** ("The title screen comes later"). There is no title screen yet.
- **Save as copy:** a pop-up lists slots 1–3. The current slot is disabled; the others read "empty" or "saved <date time>". A slot that exists asks **"Overwrite slot N?"** (Yes / No). The current slot doesn't change.
- **Save feedback:** a short toast at the top center, "Saved to slot 1" / "Copied to slot 2" (red "Could not save" on failure).
- **Leaving:**
  - **"Save before leaving?"** (Yes / No, no Cancel, as asked) shows for: Exit the game (gear menu or ESC menu), closing the window, and the ESC menu's Exit inside a stage.
  - **Leave this stage** (ESC menu) now works. It auto-saves and returns to the main screen (Training: nothing to clear, so "left").
- **ESC on the main screen:** answers No on a Yes/No pop-up that allows it (overwrite, reset tree; never the save prompt), else closes the open pop-up (spell menu, slot picker, gear menu), else opens the gear menu. Settings reads its own ESC, as in the stage.
- **Endless** opens after **Act 3** (main_screen.md). §14 of the design doc says "after beating Thresh"; Task 12 fixes §14 to match.
- **Journey content:**
  - **Act tabs:** the act's name, its story line and its stages as cards. Each card shows waves ("3 waves + boss wave"), a grey skull for a mini boss and a red skull for the boss, and a chain (locked) or check (cleared). Start is disabled: "Acts come in a later phase".
  - **Training tab:** a short text and a working **Start Training** button.
  - **Endless tab:** the rules, a map choice (Random or one of the 6 act maps), "Best wave: N" and Start disabled ("Endless comes in a later phase").
- **Main debug table (F3 + Q):**
  - **Essences tab:** blue +100 / +1000 / +10000 / Reset, orange +1 / +10 / +100 / Reset, purple +1 / +10 / +100 / Reset.
  - **Progress tab:** acts cleared (0–6), Max tree (free), Clear tree (no refund), Reset progress (a new game in memory, not saved).
  - **Stage debug table:** gains "None" in the D/F pickers (picking F opens the F slot for that run) and a "Buy all ranks" button (all ranks and the passive, for that run). The shop-slots spin starts from the run's value.

### Evolution Tree nodes (31)

B = blue, O = orange. Grid = (column, row up from the ground); one cell is 150 px. Groves from left to right: Skills, Stats, Equipment, Economy, Summoners.

| id | Name | Grid | Lv | Blue per level | Orange per level | Requires | Value text (`format`, `base`, `per_level`) |
|---|---|---|---|---|---|---|---|
| `skill_q` | Q – Piercing Light | (1,0) | 5 | 100, 200, 350, 500, 800 | 0, 0, 0, 5, 10 | — | `Rank {v}` |
| `skill_w` | W – Ardent Blaze | (2,0) | 5 | 100, 200, 350, 500, 800 | 0, 0, 0, 5, 10 | — | `Rank {v}` |
| `skill_e` | E – Relentless Pursuit | (3,0) | 5 | 0, 200, 350, 500, 800 | 0, 0, 0, 5, 10 | Act 1 cleared | `Rank {v}` |
| `passive` | Passive – Lightslinger | (0,1) | 1 | 150 | 0 | any 1 of Q, W, E | `Learned` |
| `skill_r` | R – The Culling | (2,2) | 3 | 600, 1200, 2000 | 10, 20, 30 | Q, W, E, Passive | `Rank {v}` |
| `stat_ad` | Attack Damage | (5,0) | 5 | 50, 100, 200, 350, 500 | 0, 0, 0, 3, 8 | — | `+{v} AD`, per 4, key `ad` |
| `stat_ap` | Ability Power | (6,0) | 5 | same | same | — | `+{v} AP`, per 8, key `ap` |
| `stat_hp` | Health | (7,0) | 5 | same | same | — | `+{v} Health`, per 40, key `max_hp` |
| `stat_armor` | Armor | (8,0) | 5 | same | same | — | `+{v} Armor`, per 4, key `armor` |
| `stat_mr` | Magic Resist | (9,0) | 5 | same | same | — | `+{v} Magic Resist`, per 4, key `mr` |
| `stat_attack_speed` | Attack Speed | (10,0) | 5 | same | same | — | `+{v}% Attack Speed`, per 0.03, percent, key `attack_speed` |
| `stat_mana` | Mana | (11,0) | 5 | same | same | — | `+{v} Mana`, per 40, key `max_mana` |
| `equip_slots` | Equip Slots | (13,0) | 5 | 150, 300, 600, 1000, 1500 | 0, 0, 5, 15, 30 | — | `{v} equip slots`, base 1 |
| `stage_gold` | Stage Gold | (15,0) | 3 | 100, 250, 500 | 0, 0, 5 | — | `+{v}% stage gold`, per 0.1, percent |
| `bonus_xp` | Bonus XP | (16,0) | 3 | 100, 250, 500 | 0, 0, 5 | — | `+{v}% XP`, per 0.1, percent |
| `essence_drop` | Essence Drops | (17,0) | 3 | 100, 250, 500 | 0, 0, 5 | — | `+{v}% essence drops`, per 0.1, percent |
| `merchant_stock` | Merchant Stock | (18,0) | 2 | 300, 800 | 0, 10 | — | `{v} shop items`, base 2 |
| `refresh_cost` | Cheaper Refresh | (19,0) | 2 | 200, 500 | 0, 5 | — | `Refresh: {v} gold`, base 100, per −25 |
| `flash` / `ghost` / `barrier` | Flash / Ghost / Barrier | (21,0) / (22,0) / (23,0) | 1 | 150 | 0 | — | `Unlocked` |
| `heal` / `clarity` / `smite` | Heal / Clarity / Smite | (25,0) / (26,0) / (27,0) | 1 | 150 | 0 | — | `Unlocked` |
| `flash_upgrade` / `ghost_upgrade` | Flash / Ghost Upgrade | (21,1) / (22,1) | 3 | 150, 300, 400 | 0, 0, 5 | its spell | `{v}% cooldown`, per −0.1, percent |
| `barrier_upgrade` | Barrier Upgrade | (23,1) | 3 | same | same | `barrier` | `+{v}% shield`, per 0.15, percent |
| `heal_upgrade` | Heal Upgrade | (25,1) | 3 | same | same | `heal` | `+{v}% healing`, per 0.15, percent |
| `clarity_upgrade` | Clarity Upgrade | (26,1) | 3 | same | same | `clarity` | `+{v}% mana restored`, per 0.15, percent |
| `smite_upgrade` | Smite Upgrade | (27,1) | 3 | same | same | `smite` | `+{v}% damage`, per 0.15, percent |
| `summoner_slot_2` | Second Summoner Slot | (24,1) | 1 | 400 | 5 | any 2 spells | `Unlocked` |

A value is shown as `base + per_level × level`. Level 0 of a node with base 0 reads "None". Upgrade-node ids are always `<spell>_upgrade`.

### Art (all hand-written SVG)

**Essence icons** (`assets/art/ui/essence_{blue,orange,purple}.svg`, 64 × 64, viewBox 64, transparent, dark `#1a1d24` outline, readable at 24 px). One family, rarer = fancier:
- **Blue** `5aa9ff`: one tall crystal shard with a light inner facet and a small glow.
- **Orange** `ffa040`: two crossed shards with an ember core.
- **Purple** `b46cff`: a cut gem with a crown of three points and a white sparkle.

**UI:**
- `assets/art/ui/gear.svg`: a steel gear with 8 teeth, 64 viewBox.
- `assets/art/ui/skull.svg`: a skull, white-grey, 64 viewBox. Tinted grey for a mini boss and red for a boss with `modulate`.

**Tree node icons** (`assets/art/tree/<id>.svg`, `width/height 128`, viewBox 64, full-square art). The tree look is a **dark green-to-navy gradient** (`#1d3328` → `#0c1018`) so they read apart from the HUD icons, with gold `#c9a45c` trim where useful:

| id | Icon |
|---|---|
| `skill_q` | A gold-white beam piercing three dark diamonds in a row |
| `skill_w` | An orange flare bursting into a 4-way cross with a star mark at its center |
| `skill_e` | A light-blue curved dash arrow with two fading afterimages behind it |
| `passive` | Two crossed relic pistols with a double muzzle spark |
| `skill_r` | One pistol spraying a wide fan of gold bullets |
| `stat_ad` | A sword pointing up, orange `ff9a3c`, over a rising chevron |
| `stat_ap` | A glowing blue `4a6cf7` orb floating over an open book |
| `stat_hp` | A green `6fd36f` heart with a white plus |
| `stat_armor` | A yellow `f2c94c` riveted shield plate |
| `stat_mr` | A light-blue `7fd4ff` rune circle with a ward glyph |
| `stat_attack_speed` | Two light-yellow `fff3a3` daggers crossed, with speed lines |
| `stat_mana` | A blue `8fb8ff` crystal flask, half full |
| `equip_slots` | A 3 × 2 grid of item slots, the last one opening with a gold glow |
| `stage_gold` | A pile of gold coins with a green up-arrow |
| `bonus_xp` | A purple-blue star over a rising bar (level up) |
| `essence_drop` | Three small essence shards (blue, orange, purple) falling into an open palm |
| `merchant_stock` | A merchant's stall with an awning over 4 item tiles |
| `refresh_cost` | Two circular arrows around a coin, with a minus sign |
| `flash` | A yellow-white starburst inside a round bronze medallion |
| `ghost` | A pale teal running silhouette inside a medallion |
| `barrier` | A gold hex dome inside a medallion |
| `heal` | A green cross inside a medallion |
| `clarity` | A blue swirl inside a medallion |
| `smite` | An orange bolt striking down, inside a medallion |
| `flash_upgrade` … `smite_upgrade` | The same symbol **without** a medallion, larger, with three gold chevrons rising on the right |
| `summoner_slot_2` | Two medallion sockets side by side, the right one lighting up |

**Skins** (`assets/art/lucian/skins/<id>_portrait.svg` and `<id>_body.svg`):
- **Portraits** use the classic portrait's framing (viewBox 96, `width/height 384` so the 288 px card is sharp). The classic `lucian_portrait.svg` also goes to 384 (the HUD rect ignores the texture size: `expand_mode = 1`).
- **Bodies** use exactly the classic body's size and viewBox, so the sprite doesn't change size.

| Skin | Look |
|---|---|
| Classic | Existing art |
| High Noon | Dusty brown duster, wide-brim hat, red scarf, bronze revolvers; sunset-orange background |
| PROJECT | Black armor with cyan neon lines, a visor over the eyes, chrome guns; digital blue background |
| Pulsefire | White-blue armor with glowing cyan pulse cores, a holo visor; electric blue background |
| Vampire | Crimson-and-black coat with a high collar and red lining, silver guns, faint red eye glow; dark purple background with a moon |

## Global Constraints
- Godot **4.7.2**. GDScript style of the surrounding code: tabs, typed vars, `##` doc comments on classes and public funcs, `&"name"` StringNames, one `class_name` per file.
- Pure logic stays in `src/core/` with no scene dependencies. UI is built in code; the only new `.tscn` is `src/main/game.tscn` (the root scene needs one).
- **No autoloads:** `SaveGame` follows `GameSettings` (class_name, static lazy `instance()`, test-overridable path), so GUT and `-s` scripts work. Task 12 updates the doc's "SaveManager as an Autoload" note.
- Save files: `user://save_slot_N.json` + `user://save_slot_N_backup.json`, JSON with `"version": 1`, string ids, `int()` on load, unknown keys and ids ignored.
- `stage.tscn` run on its own keeps Phase 4 behavior: everything unlocked, the stage debug table as before.
- ESC and F3 + Q stay non-rebindable. Settings stay in `user://settings.json`, shared by all slots.
- New player-facing numbers are constants at the top of their script or `@export`s on `.tres` data.
- Work on `main`, **one verified commit per task**, never pushed. Each commit: GUT suite green. Every commit message ends with `Co-Authored-By: Claude <noreply@anthropic.com>`.
- Docs follow the existing voice: short plain sentences, tables for numbers.

## File map

| File | Change |
|---|---|
| `src/core/essences.gd` | **new** `Essences` |
| `src/core/save_game.gd` | **new** `SaveGame` (slots, backup, copy, finish_stage) |
| `src/core/tree_node_data.gd`, `src/core/tree_catalog.gd` | **new** node data + catalog |
| `src/core/evolution_tree.gd` | **new** `EvolutionTree` (levels, rules, buy, reset) |
| `src/core/journey.gd` | **new** `Journey` (acts, stage ids, open rules) |
| `src/core/skin_data.gd`, `src/core/skins.gd` | **new** skin data + list |
| `src/core/stage_setup.gd` | **new** `StageSetup` (sandbox defaults, `from_save`) |
| `src/core/shop.gd`, `src/ui/shop/shop_panel.gd` | `refresh_cost` per shop |
| `data/tree/*.tres` (31 + `catalog.tres`), `data/skins/*.tres` (5) | **new** data |
| `src/lucian/lucian.gd` | `apply_setup()`, `apply_skin()`, `tree_bonus`, skin scale, kill heal |
| `src/lucian/skills/lightslinger.gd` | `learned` |
| `src/lucian/summoners/summoner_spells.gd` | `open_slots`, `upgrades`, `cooldown_of()`, `upgrade_text()` |
| `src/stage/stage.gd` | `setup(run)`, `finished`, `exit_requested`, leave / exit wiring |
| `src/main/game.gd`, `src/main/game.tscn` | **new** root: screens, save prompt, window close |
| `src/ui/menu/game_menu.gd` | Leave this stage enabled; `leave_requested`, `exit_requested` |
| `src/ui/menu/confirm_popup.gd` | **new** Yes/No pop-up |
| `src/ui/main/main_screen.gd`, `essence_bar.gd`, `section_bar.gd`, `gear_menu.gd` | **new** shell |
| `src/ui/main/journey/*.gd` | **new** `JourneySection`, `JourneyTab`, `ActPage`, `StageCard`, `TrainingPage`, `EndlessPage`, `LoadoutPanel`, `SpellMenu` |
| `src/ui/main/tree/*.gd` | **new** `TreeSection`, `TreeMap`, `TreeNodeView`, `NodeInfoPanel`, `CostBar` |
| `src/ui/main/skins/*.gd` | **new** `SkinShop`, `SkinCard` |
| `src/ui/debug/debug_panel.gd` | **new** base: F3 + Q, frame, widget helpers (moved out of `DebugTable`) |
| `src/ui/debug/debug_table.gd` | extends `DebugPanel`; None in D/F pickers; Buy all ranks |
| `src/ui/debug/main_debug_table.gd` | **new** main screen debug |
| `src/ui/hud/hud.gd`, `skill_slot.gd`, `summoner_slot.gd` | skin portrait; passive lock; empty / chained summoner slot |
| `src/ui/tooltip/tooltip_card.gd` | `summoner(spell, key, upgrade := "")` |
| `src/audio/sfx.gd` | `static func exists()` |
| `project.godot` | `run/main_scene="res://src/main/game.tscn"` |
| `tests/pre_run.gd` | scratch save prefix |
| `assets/art/ui/{essence_blue,essence_orange,essence_purple,gear,skull}.svg`, `assets/art/tree/*.svg` (31), `assets/art/lucian/skins/*.svg` (8), `assets/art/lucian/lucian_portrait.svg` (size) | art |
| `tests/unit/…` | new: `test_essences`, `test_save_game`, `test_evolution_tree`, `test_tree_data_files`, `test_journey`, `test_skins`, `test_stage_setup`, `test_game`, `test_main_screen`, `test_tree_section`, `test_skin_shop`, `test_journey_section`, `test_main_debug`; extended: `test_summoner_spells`, `test_lucian_casting`, `test_shop`, `test_skill_slot` |
| `tests/tools/screenshot.gd` | `main_*` scenarios start `game.tscn`; `art_sheet`, `training_setup`, `skins_stage` |
| `docs/…` | `implementation/phase5.md`, `report/phase5.md` (+ `report/phase5/*.png`), `main_screen.md`, `lucian_game_design.md`, `ui_design.md` |

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

- [ ] Copy this plan to `docs/implementation/phase5.md`. Add "Phase 5: `implementation/phase5.md`" to `lucian_game_design.md` §16.
- [ ] Commit it together with the save-rule doc edits already in the working tree: `git add docs/implementation/phase5.md docs/lucian_game_design.md docs/main_screen.md docs/ui_design.md` → `git commit -m "Add the Phase 5 plan; save only when a stage is done"`.

---

### Task 1: Essences and SaveGame

**Files:** `src/core/essences.gd`, `src/core/save_game.gd`, `tests/pre_run.gd`; tests `tests/unit/test_essences.gd`, `tests/unit/test_save_game.gd`.

Note: `SaveGame` holds an `EvolutionTree` (Task 3) and validates skins and stage ids (Tasks 3–4). In this task:
- Create `SaveGame` **without** the `tree` field, the skin whitelist and the cleared-id check.
- Task 3 adds the tree and the cleared-id check (`Journey`).
- Task 4 adds the skin whitelist.

**Interfaces — Produces:**
- `Essences`:
  - `BLUE`, `ORANGE`, `PURPLE`, `KINDS`
  - `amount(kind) -> int`, `add(kind, n)`, `set_amount(kind, n)`
  - `can_afford(blue, orange := 0, purple := 0) -> bool`, `spend(blue, orange := 0, purple := 0) -> bool`
  - `to_dict()`, `from_dict(d)`, `signal changed`
- `SaveGame`:
  - `VERSION`, `SLOTS := 3`, `DEFAULT_PREFIX`, `static instance()`, `_init(file_prefix := DEFAULT_PREFIX)`
  - Fields: `slot`, `essences`, `owned_skins`, `skin`, `loadout`, `cleared`, `endless_best`
  - Files: `path(n)`, `backup_path(n)`, `slot_exists(n)`, `saved_at(n) -> String`
  - Actions: `load_slot(n)`, `save() -> bool`, `copy_to(n) -> bool`, `finish_stage(result, stage_id := "") -> bool`, `reset()`, `set_loadout(i, id)`
  - `to_dict()`, `signal changed`

- [ ] **Step 1: Failing tests.**
  - `test_essences.gd`:
    ```gdscript
    extends GutTest

    var essences: Essences


    func before_each() -> void:
    	essences = Essences.new()


    func test_spend_pays_every_kind_at_once() -> void:
    	essences.add(Essences.BLUE, 600)
    	essences.add(Essences.ORANGE, 10)
    	assert_true(essences.spend(500, 5))
    	assert_eq(essences.amount(Essences.BLUE), 100)
    	assert_eq(essences.amount(Essences.ORANGE), 5)


    func test_nothing_is_paid_when_one_kind_is_short() -> void:
    	essences.add(Essences.BLUE, 1000)
    	assert_false(essences.spend(100, 1))
    	assert_eq(essences.amount(Essences.BLUE), 1000)


    func test_round_trip_turns_json_floats_back_into_ints() -> void:
    	essences.from_dict({"blue": 12.0, "orange": 3.0, "purple": -4.0, "green": 9})
    	assert_eq(essences.to_dict(), {"blue": 12, "orange": 3, "purple": 0})
    	assert_typeof(essences.amount(Essences.BLUE), TYPE_INT)
    ```
  - `test_save_game.gd`. Use the prefix `"user://test_save_slot_"`; `before_each` / `after_each` delete slots 1–3 and their backups. Tests:
    - `test_new_game_defaults`: 0 essences, `owned_skins == [&"classic"]`, `skin == &"classic"`, `loadout == [&"", &""]`, `cleared` empty, `endless_best == 0`, and no file on disk.
    - `test_save_then_load_restores_everything`: set essences, skin list, loadout, `cleared = ["1-1"]` and `endless_best = 7`; `save()`; then `SaveGame.new(PREFIX)` + `load_slot(1)` gives equal values, with ints as `TYPE_INT`.
    - `test_save_copies_the_old_file_to_the_backup`: save with 100 blue, then with 200 blue; the backup reads 100.
    - `test_broken_main_file_loads_the_backup`: write `"{not json"` into the main file after two saves; `load_slot(1)` gives the backup's values.
    - `test_both_files_broken_is_a_new_game`.
    - `test_copy_to_writes_another_slot_and_keeps_the_current_one`: `copy_to(2)` → `slot_exists(2)`, `slot == 1`, and slot 2 loads the same essences.
    - `test_finish_stage_saves`: `finish_stage(&"left")` → file exists. `finish_stage(&"cleared", "1-1")` → `"1-1"` in `cleared` (once, even if repeated).
    - `test_loading_ignores_unknown_keys`: a file with `"version": 1, "foo": 3` loads fine.
    - `test_saved_at_reads_the_time_written`: after `save()`, `saved_at(1)` is not empty and `saved_at(2) == ""`.
    - `test_instance_uses_the_test_prefix`: `SaveGame.instance().prefix == "user://test_run_save_slot_"`.
- [ ] **Step 2:** Run both files and expect FAIL (classes missing).
- [ ] **Step 3: Implement.**
  - `Essences`:
    ```gdscript
    class_name Essences
    extends RefCounted
    ## Blue, orange and purple essence: permanent currencies, spent outside stages.

    signal changed

    const BLUE := &"blue"
    const ORANGE := &"orange"
    const PURPLE := &"purple"
    const KINDS: Array[StringName] = [BLUE, ORANGE, PURPLE]

    var _amounts := {BLUE: 0, ORANGE: 0, PURPLE: 0}


    func amount(kind: StringName) -> int:
    	return _amounts[kind]


    func add(kind: StringName, value: int) -> void:
    	if value <= 0:
    		return
    	_amounts[kind] += value
    	changed.emit()


    ## Debug: sets one kind (never below 0).
    func set_amount(kind: StringName, value: int) -> void:
    	_amounts[kind] = maxi(value, 0)
    	changed.emit()


    func can_afford(blue: int, orange := 0, purple := 0) -> bool:
    	return _amounts[BLUE] >= blue and _amounts[ORANGE] >= orange and _amounts[PURPLE] >= purple


    ## Pays all three at once, or nothing.
    func spend(blue: int, orange := 0, purple := 0) -> bool:
    	if not can_afford(blue, orange, purple):
    		return false
    	_amounts[BLUE] -= blue
    	_amounts[ORANGE] -= orange
    	_amounts[PURPLE] -= purple
    	changed.emit()
    	return true


    func to_dict() -> Dictionary:
    	return {"blue": _amounts[BLUE], "orange": _amounts[ORANGE], "purple": _amounts[PURPLE]}


    ## JSON numbers load as floats; anything else counts as 0.
    func from_dict(data: Dictionary) -> void:
    	for kind in KINDS:
    		var value: Variant = data.get(String(kind), 0)
    		_amounts[kind] = maxi(int(value), 0) if (value is int or value is float) else 0
    	changed.emit()
    ```
  - `SaveGame` (key parts; the rest follows `GameSettings`):
    ```gdscript
    class_name SaveGame
    extends RefCounted
    ## Permanent progress in one of 3 save slots (user://save_slot_N.json, each
    ## with a _backup.json). Nothing saves by itself on the main screen: the game
    ## saves when a stage is done, from the gear menu, and on "Save before
    ## leaving?". Not an autoload (like GameSettings), so tests and -s scripts work.

    signal changed

    const VERSION := 1
    const SLOTS := 3
    const DEFAULT_PREFIX := "user://save_slot_"
    const CLASSIC := &"classic"

    static var _instance: SaveGame

    var prefix := DEFAULT_PREFIX
    ## The current slot: every save writes to it. Slot 1 until a slot
    ## selection screen exists.
    var slot := 1
    var essences := Essences.new()
    var owned_skins: Array[StringName] = [CLASSIC]
    var skin := CLASSIC
    ## Spell ids on D and F (&"" for none), picked in Journey.
    var loadout: Array[StringName] = [&"", &""]
    ## Stage ids ("1-1" … "6-5") cleared at least once.
    var cleared: Array[String] = []
    var endless_best := 0


    ## The running game's progress: slot 1, loaded on first use.
    static func instance() -> SaveGame:
    	if _instance == null:
    		_instance = SaveGame.new()
    		_instance.load_slot(1)
    	return _instance


    func _init(file_prefix := DEFAULT_PREFIX) -> void:
    	prefix = file_prefix


    func path(of_slot: int) -> String:
    	return "%s%d.json" % [prefix, of_slot]


    func backup_path(of_slot: int) -> String:
    	return "%s%d_backup.json" % [prefix, of_slot]


    func slot_exists(of_slot: int) -> bool:
    	return FileAccess.file_exists(path(of_slot)) or FileAccess.file_exists(backup_path(of_slot))


    ## Makes `of_slot` current and loads it: the main file, else its backup,
    ## else a new game.
    func load_slot(of_slot: int) -> void:
    	slot = of_slot
    	reset()
    	for file in [path(of_slot), backup_path(of_slot)]:
    		var data := _read(file)
    		if not data.is_empty():
    			_apply(data)
    			return


    func save() -> bool:
    	return _write(slot)


    ## Copies the current progress into another slot; the current slot stays.
    func copy_to(of_slot: int) -> bool:
    	return _write(of_slot)


    ## A stage is done (cleared, left or failed): the only auto-save.
    func finish_stage(result: StringName, stage_id := "") -> bool:
    	if result == &"cleared" and stage_id != "" and not stage_id in cleared:
    		cleared.append(stage_id)
    		changed.emit()
    	return save()


    ## The "saved_at" written in `of_slot`, or "" when it has none.
    func saved_at(of_slot: int) -> String:
    	for file in [path(of_slot), backup_path(of_slot)]:
    		var data := _read(file)
    		if not data.is_empty():
    			return str(data.get("saved_at", ""))
    	return ""


    ## A new game, in memory only.
    func reset() -> void:
    	essences.from_dict({})
    	owned_skins = [CLASSIC]
    	skin = CLASSIC
    	loadout = [&"", &""]
    	cleared = []
    	endless_best = 0
    	changed.emit()


    ## Puts spell `id` on D (0) or F (1); if it was on the other key, they swap.
    func set_loadout(index: int, id: StringName) -> void:
    	if id != &"" and loadout[1 - index] == id:
    		loadout[1 - index] = loadout[index]
    	loadout[index] = id
    	changed.emit()


    func to_dict() -> Dictionary:
    	return {
    		"version": VERSION,
    		"saved_at": Time.get_datetime_string_from_system(false, true),
    		"essences": essences.to_dict(),
    		"skins": {"owned": owned_skins.map(func(id: StringName) -> String: return String(id)), "equipped": String(skin)},
    		"loadout": loadout.map(func(id: StringName) -> String: return String(id)),
    		"cleared": cleared.duplicate(),
    		"endless_best": endless_best,
    	}


    ## Old backup first: the file being replaced becomes the backup.
    func _write(of_slot: int) -> bool:
    	var file_path := path(of_slot)
    	if FileAccess.file_exists(file_path):
    		DirAccess.copy_absolute(ProjectSettings.globalize_path(file_path), ProjectSettings.globalize_path(backup_path(of_slot)))
    	var file := FileAccess.open(file_path, FileAccess.WRITE)
    	if file == null:
    		push_warning("Could not save to %s" % file_path)
    		return false
    	file.store_string(JSON.stringify(to_dict(), "\t"))
    	return true


    func _read(file_path: String) -> Dictionary:
    	if not FileAccess.file_exists(file_path):
    		return {}
    	var json := JSON.new()
    	if json.parse(FileAccess.get_file_as_string(file_path)) != OK or not json.data is Dictionary:
    		push_warning("Save file %s is broken" % file_path)
    		return {}
    	return json.data
    ```
    `_apply(data)` reads each key with a type check and falls back to the new-game value:
    - `essences.from_dict(data.get("essences", {}))`
    - owned skins: Strings → StringNames; Classic is always kept.
    - `skin`: must be owned, else Classic.
    - `loadout`: 2 entries, Strings → StringNames, else `[&"", &""]`.
    - `cleared`: Strings only.
    - `endless_best = maxi(int(...), 0)`

    It ends with `changed.emit()`.
  - `tests/pre_run.gd`: also delete `user://test_run_save_slot_{1,2,3}.json` and the `_backup` files, then `SaveGame._instance = SaveGame.new("user://test_run_save_slot_")` (with `load_slot(1)`).
- [ ] **Step 4:** Run both files, then the full suite → PASS.
- [ ] **Step 5:** Commit `"Essences and a save system: 3 slots with backups, saved only when asked or when a stage is done"`.

---

### Task 2: Art: essences, gear, skull and 31 tree node icons

**Files:** `assets/art/ui/essence_blue.svg`, `essence_orange.svg`, `essence_purple.svg`, `gear.svg`, `skull.svg`; `assets/art/tree/<id>.svg` × 31 (ids and designs in the **Art** tables above); `tests/tools/screenshot.gd` (`art_sheet`).

- [ ] **Step 1:** Draw the 5 UI icons. Same conventions as the stat icons: a header comment `<!-- Name: description -->`, transparent background, `#1a1d24` outline 2–3 px, round joins, readable at 24 px.
- [ ] **Step 2:** Draw the 31 node icons: `width="128" height="128" viewBox="0 0 64 64"`, the tree gradient background (`#1d3328` → `#0c1018`), one idea per icon, readable at 56 px.
- [ ] **Step 3:** `--import`, then add an `art_sheet` screenshot scenario. It builds a plain Control grid instead of a stage: every new icon at 64 px and 32 px with its file name under it. Run it and look at every icon. Redraw any that don't read at 32 px.
- [ ] **Step 4:** Full suite → PASS (no code depends on the art yet). Commit `"Essence, gear and skull icons and 31 Evolution Tree node icons"` with the sheet PNG left out of git (it goes into the report in Task 12).

---

### Task 3: Evolution Tree data and rules; Journey

**Files:**
- Create: `src/core/tree_node_data.gd`, `src/core/tree_catalog.gd`, `src/core/evolution_tree.gd`, `src/core/journey.gd`, and `data/tree/<id>.tres` × 31 + `data/tree/catalog.tres`.
- Modify: `src/core/save_game.gd` (tree + cleared check).
- Tests: `test_evolution_tree.gd`, `test_tree_data_files.gd`, `test_journey.gd`; extend `test_save_game.gd`.

**Interfaces — Produces:**
- `TreeNodeData`: `id`, `display_name`, `description`, `icon`, `branch`, `grid: Vector2`, `max_level`, `blue: Array[int]`, `orange: Array[int]`, `requires: Array[StringName]`, `requires_count`, `requires_act`, `stat_key`, `base`, `per_level`, `percent`, `format`; plus `value(level) -> float` and `value_text(level) -> String`.
- `EvolutionTree`:
  - `CATALOG`, `RESET_COST := 5`, `acts_cleared`, `signal changed`
  - Lookups: `nodes()`, `node(id)`, `level(id)`, `value(id)`
  - Buying: `is_open(id)`, `is_maxed(id)`, `cost(id) -> Vector2i` (blue, orange of the next level), `can_buy(id, essences)`, `buy(id, essences) -> bool`
  - Reset: `spent() -> Vector2i`, `has_bought()`, `can_reset(essences)`, `reset(essences) -> bool`
  - Debug: `max_all()`, `clear()`
  - `to_dict()`, `from_dict(d)`
- `Journey` (static):
  - Data: `ACTS`, `ENDLESS_ACT := 3`, `ENDLESS_MAPS`
  - Ids: `stage_id(act, stage) -> String`, `stage_count(act)`, `is_stage_id(id)`, `all_stage_ids(through_act) -> Array[String]`
  - Rules: `act_cleared(act, cleared)`, `acts_cleared(cleared) -> int`, `is_act_open(act, cleared)`, `is_stage_open(act, stage, cleared)`, `is_endless_open(cleared)`
  - Cards: `boss_kind(act, stage) -> StringName` (`&"boss"`, `&"mini_boss"` or `&""`), `waves(act, stage) -> int`
- `SaveGame.tree: EvolutionTree` (saved as `"tree": {"skill_q": 2, …}`), and `SaveGame.set_cleared(ids: Array[String])` (debug), which keeps `tree.acts_cleared` in step.

- [ ] **Step 1: Failing tests.**
  - `test_tree_data_files.gd` checks the real catalog:
    - 31 nodes with unique ids.
    - Each icon is loaded.
    - `blue.size() == orange.size() == max_level`.
    - Each id in `requires` exists.
    - The costs match the table above, row by row (a `COSTS` dict copied from the design doc).
    - The upgrade ids are `<spell>_upgrade`.
  - `test_evolution_tree.gd` (each test builds `EvolutionTree.new()` and `Essences.new()` with plenty of essence):
    ```gdscript
    func test_buying_spends_and_levels_up() -> void:
    	assert_true(tree.buy(&"skill_q", essences))
    	assert_eq(tree.level(&"skill_q"), 1)
    	assert_eq(essences.amount(Essences.BLUE), 10000 - 100)
    	assert_eq(tree.cost(&"skill_q"), Vector2i(200, 0))


    func test_passive_needs_any_one_basic_skill() -> void:
    	assert_false(tree.is_open(&"passive"))
    	tree.buy(&"skill_w", essences)
    	assert_true(tree.is_open(&"passive"))


    func test_r_needs_q_w_e_and_the_passive() -> void:
    	tree.acts_cleared = 1
    	for id in [&"skill_q", &"skill_w", &"skill_e"]:
    		tree.buy(id, essences)
    	assert_false(tree.is_open(&"skill_r"))
    	tree.buy(&"passive", essences)
    	assert_true(tree.is_open(&"skill_r"))


    func test_e_rank_1_is_free_after_act_1() -> void:
    	assert_false(tree.is_open(&"skill_e"))
    	tree.acts_cleared = 1
    	assert_eq(tree.cost(&"skill_e"), Vector2i.ZERO)
    	assert_true(tree.buy(&"skill_e", Essences.new()))


    func test_second_summoner_slot_needs_two_spells() -> void:
    	tree.buy(&"flash", essences)
    	assert_false(tree.is_open(&"summoner_slot_2"))
    	tree.buy(&"heal", essences)
    	assert_true(tree.is_open(&"summoner_slot_2"))


    func test_maxed_node_cannot_be_bought() -> void:
    	for i in 3:
    		tree.buy(&"stage_gold", essences)
    	assert_true(tree.is_maxed(&"stage_gold"))
    	assert_false(tree.buy(&"stage_gold", essences))


    func test_reset_costs_5_purple_and_refunds_blue_and_orange() -> void:
    	essences.set_amount(Essences.PURPLE, 5)
    	for i in 4:
    		tree.buy(&"stat_ad", essences)  # 50 + 100 + 200 + 350 blue, 3 orange
    	var blue_before := essences.amount(Essences.BLUE)
    	assert_true(tree.reset(essences))
    	assert_eq(essences.amount(Essences.BLUE), blue_before + 700)
    	assert_eq(essences.amount(Essences.ORANGE), 1000)
    	assert_eq(essences.amount(Essences.PURPLE), 0)
    	assert_eq(tree.level(&"stat_ad"), 0)


    func test_reset_refused_without_purple_or_purchases() -> void
    func test_value_text() -> void:
    	assert_eq(tree.node(&"stat_ad").value_text(0), "None")
    	assert_eq(tree.node(&"stat_ad").value_text(2), "+8 AD")
    	assert_eq(tree.node(&"stat_attack_speed").value_text(1), "+3% Attack Speed")
    	assert_eq(tree.node(&"equip_slots").value_text(0), "1 equip slots")
    	assert_eq(tree.node(&"refresh_cost").value_text(2), "Refresh: 50 gold")
    	assert_eq(tree.node(&"flash_upgrade").value_text(1), "-10% cooldown")


    func test_from_dict_drops_unknown_ids_and_clamps_levels() -> void:
    	tree.from_dict({"skill_q": 9.0, "nope": 1, "skill_r": -2})
    	assert_eq(tree.level(&"skill_q"), 5)
    	assert_eq(tree.to_dict(), {"skill_q": 5})
    ```
    In these tests, `essences` starts with 10000 blue and 1000 orange.
  - `test_journey.gd`:
    - 22 stages in all.
    - `waves(3, 4) == 5`.
    - `boss_kind(3, 2) == &"mini_boss"`, `boss_kind(3, 5) == &"boss"`, `boss_kind(1, 1) == &"boss"`, `boss_kind(2, 1) == &""`.
    - `acts_cleared(["1-1", "2-1", "2-2", "2-3"]) == 2`.
    - `is_act_open(3, ["1-1"])` is false.
    - `is_stage_open(2, 2, ["1-1"])` is false, and true once `"2-1"` is cleared.
    - `is_endless_open(Journey.all_stage_ids(3))` is true; with only 2 acts it's false.
    - `is_stage_id("7-1")` is false.
  - `test_save_game.gd` gains:
    - The tree levels round-trip.
    - An unknown cleared id is dropped.
    - `set_cleared(Journey.all_stage_ids(1))` sets `tree.acts_cleared == 1`.
- [ ] **Step 2:** Run them and expect FAIL.
- [ ] **Step 3: Implement.**
  - `TreeNodeData` (Resource; the fields listed above, each with a `##` comment), plus:
    ```gdscript
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
    ```
  - `TreeCatalog` (Resource): `@export var nodes: Array[TreeNodeData] = []`, "listed by hand like ItemCatalog".
  - `data/tree/<id>.tres`, one per row of the node table. Example:
    ```
    [gd_resource type="Resource" script_class="TreeNodeData" format=3]

    [ext_resource type="Script" path="res://src/core/tree_node_data.gd" id="1_data"]
    [ext_resource type="Texture2D" path="res://assets/art/tree/stat_ad.svg" id="2_icon"]

    [resource]
    script = ExtResource("1_data")
    id = &"stat_ad"
    display_name = "Attack Damage"
    description = "Lucian starts every stage with more [ad]AD[/ad]."
    icon = ExtResource("2_icon")
    branch = &"stats"
    grid = Vector2(5, 0)
    max_level = 5
    blue = Array[int]([50, 100, 200, 350, 500])
    orange = Array[int]([0, 0, 0, 3, 8])
    stat_key = &"ad"
    per_level = 4.0
    format = "+{v} AD"
    ```
    Descriptions are one short sentence each, using `TooltipText` markup:
    - Skill nodes: "Buys ranks of Q. In a stage, skill points only go into bought ranks."
    - Economy nodes: "Bought and saved now; it starts working once enemies give gold, XP or essences."
  - `EvolutionTree`:
    ```gdscript
    class_name EvolutionTree
    extends RefCounted
    ## Levels bought in the Evolution Tree and the rules for buying them. A node
    ## opens once enough of its requirements have level 1 (and, for E, once
    ## Act 1 is cleared). Reset costs 5 purple and gives back every blue and
    ## orange spent.

    signal changed

    const CATALOG: TreeCatalog = preload("res://data/tree/catalog.tres")
    const RESET_COST := 5

    ## Acts cleared, kept in step by SaveGame.
    var acts_cleared := 0:
    	set(value):
    		acts_cleared = value
    		changed.emit()

    ## Node id -> level, for nodes above 0.
    var _levels := {}


    func nodes() -> Array[TreeNodeData]:
    	return CATALOG.nodes


    func node(id: StringName) -> TreeNodeData:
    	for data in CATALOG.nodes:
    		if data.id == id:
    			return data
    	return null


    func level(id: StringName) -> int:
    	return _levels.get(id, 0)


    func value(id: StringName) -> float:
    	return node(id).value(level(id))


    func is_open(id: StringName) -> bool:
    	var data := node(id)
    	if acts_cleared < data.requires_act:
    		return false
    	var met := data.requires.filter(func(required: StringName) -> bool: return level(required) > 0).size()
    	return met >= (data.requires.size() if data.requires_count == 0 else data.requires_count)


    func is_maxed(id: StringName) -> bool:
    	return level(id) >= node(id).max_level


    ## Blue and orange for the next level; zero when maxed.
    func cost(id: StringName) -> Vector2i:
    	if is_maxed(id):
    		return Vector2i.ZERO
    	var data := node(id)
    	return Vector2i(data.blue[level(id)], data.orange[level(id)])


    func can_buy(id: StringName, essences: Essences) -> bool:
    	var price := cost(id)
    	return is_open(id) and not is_maxed(id) and essences.can_afford(price.x, price.y)


    func buy(id: StringName, essences: Essences) -> bool:
    	if not can_buy(id, essences):
    		return false
    	var price := cost(id)
    	essences.spend(price.x, price.y)
    	_levels[id] = level(id) + 1
    	changed.emit()
    	return true
    ```
    The rest:
    - `spent()` sums `blue` / `orange` over each node's bought levels.
    - `has_bought()` is `not _levels.is_empty()`.
    - `can_reset(e)` is `has_bought() and e.can_afford(0, 0, RESET_COST)`.
    - `reset(e)`: if allowed, spend `RESET_COST` purple, add `spent()` back, `_levels.clear()`, emit.
    - `max_all()` sets every node to `max_level` (debug). `clear()` empties the levels (debug).
    - `to_dict()` gives `{String(id): level}`.
    - `from_dict()` keeps only known ids, clamps to `0..max_level` with `int()`, and drops zeros.
  - `Journey`:
    ```gdscript
    const ACTS := [
    	{"name": "The Loss", "story": "Lucian and Senna fight together, until Thresh takes her soul.", "waves": [2], "mini_bosses": []},
    	{"name": "The Sentinels", "story": "Lucian trains with Akshan to prove he's ready to hunt Thresh.", "waves": [2, 3, 3], "mini_bosses": []},
    	{"name": "The Jungle", "story": "Lucian crosses the jungle, facing the drakes and the Elder Dragon.", "waves": [3, 4, 4, 5, 5], "mini_bosses": [2, 4]},
    	{"name": "The Darkness", "story": "Lucian faces his own fear and grief as Dark Lucian.", "waves": [4, 5, 5], "mini_bosses": []},
    	{"name": "Shadow Isles", "story": "Lucian fights through Maokai, Elise and Karthus.", "waves": [5, 5, 6, 6, 6], "mini_bosses": [2, 4]},
    	{"name": "The Lantern", "story": "Lucian defeats Thresh and frees Senna.", "waves": [6, 6, 7, 7, 7], "mini_bosses": [2, 4]},
    ]
    ```
    An act is cleared when its last stage is cleared. `acts_cleared` counts cleared acts in a row from Act 1. `ENDLESS_MAPS := ["Random", "Mid lane", "Training ground", "Jungle", "Dark mid lane", "Dead forest", "Thresh's domain"]`.
  - `SaveGame`:
    - `var tree := EvolutionTree.new()`. `reset()` calls `tree.clear()`.
    - `to_dict()` adds `"tree": tree.to_dict()`, and `_apply()` reads it.
    - `cleared` keeps only `Journey.is_stage_id` entries.
    - `set_cleared(ids)` (debug) replaces the list.
    - `reset`, `_apply`, `finish_stage` and `set_cleared` all end with `tree.acts_cleared = Journey.acts_cleared(cleared)`.
- [ ] **Step 4:** `--import`, run the new files, then the full suite → PASS.
- [ ] **Step 5:** Commit `"Evolution Tree: 31 nodes as data, buying, requirements and reset; Journey acts and unlock rules"`.

---

### Task 4: Skins: data, art and Lucian's stats and look

**Files:**
- Create: `src/core/skin_data.gd`, `src/core/skins.gd`, `data/skins/{classic,high_noon,project,pulsefire,vampire}.tres`, and `assets/art/lucian/skins/*.svg` × 8.
- Modify: `assets/art/lucian/lucian_portrait.svg` (size 384), `src/lucian/lucian.gd`, `src/ui/hud/hud.gd`, `src/core/save_game.gd` (skin whitelist).
- Tests: `test_skins.gd`; extend `test_save_game.gd`.

**Interfaces — Produces:**
- `SkinData`:
  - Identity and art: `id`, `display_name`, `cost` (purple), `portrait`, `body`
  - Card text: `bonuses: PackedStringArray`, `weaknesses: PackedStringArray`, `playstyle`
  - Effects: `flat: Dictionary` (bonus stat keys), `scale: Dictionary` (StatBlock field → multiplier), `kill_heal` (share of max HP)
- `Skins.ALL: Array[SkinData]`, `Skins.CLASSIC := &"classic"`, `Skins.find(id) -> SkinData` (Classic when unknown).
- `Lucian.skin: SkinData`, `Lucian.apply_skin(skin)`, `Lucian.tree_bonus: Dictionary` (used in Task 5).

- [ ] **Step 1: Failing tests** (`test_skins.gd`, using a real `lucian.tscn` + dummy as in `test_lucian_items.gd`):
  - The data matches the doc table: 5 skins, their costs (0 / 25 / 30 / 20 / 25), and their bonus and weakness lines.
  - `Skins.find(&"nope") == Skins.find(&"classic")`.
  - `apply_skin(high_noon)`: AD is `base AD × 1.15` at level 1 with no items. Attack speed is lower than Classic's.
  - `apply_skin(project)`: move speed is Classic's × 1.15, AD × 0.9.
  - `apply_skin(pulsefire)`: ability haste 15.
  - `apply_skin(vampire)`: max HP × 0.8 and lifesteal 0.15. A kill heals 2% max HP: an `Enemy` (not a dummy, which never reaches 0) with `hp = 0.0` as after a killing blow, Lucian at half HP, then `lucian.on_damage_dealt(enemy, info, 1.0)` with a non-basic `info` (so life steal stays out of it) → HP up by exactly `max_hp × 0.02`.
  - The body texture is `vampire.body`.
  - `test_save_game.gd`: a skin in the file that isn't in `Skins.ALL` is dropped from `owned_skins`, and an equipped skin that isn't owned falls back to Classic.
- [ ] **Step 2:** Run and expect FAIL.
- [ ] **Step 3: Implement.**
  - Draw the 4 portraits and 4 bodies (Art table). Set the classic portrait to `width/height 384`. Run `--import`.
  - Skin `.tres` files. The effects are in the table below; the card lines are copied from the doc.

    | Skin | `flat` | `scale` | `kill_heal` |
    |---|---|---|---|
    | High Noon | `attack_speed: -0.15` | `ad: 1.15` | — |
    | PROJECT | `attack_speed: 0.2`, `move_speed_pct: 0.15` | `ad: 0.9` | — |
    | Pulsefire | `ability_haste: 15.0`, `attack_speed: -0.1` | `ap: 1.15` | — |
    | Vampire | `lifesteal: 0.15` | `max_hp: 0.8` | `0.02` |
  - `Skins`: `const ALL: Array[SkinData] = [preload(...classic), …]`. `find(id)` returns the match, else `ALL[0]`.
  - `Lucian`:
    ```gdscript
    ## The equipped skin: its body art, stat changes and kill heal.
    var skin: SkinData = Skins.ALL[0]
    ## Flat stats from the Evolution Tree's stat nodes, keyed like ItemStats.
    var tree_bonus := {}


    func apply_skin(new_skin: SkinData) -> void:
    	skin = new_skin
    	($Visuals/Body as Sprite2D).texture = skin.body
    	_refresh_stats(true)


    ## Items, tree and skin flat stats together, for UnitStats.at_level().
    func _stat_bonus() -> Dictionary:
    	var total := inventory.equipped_bonus()
    	for source: Dictionary in [tree_bonus, skin.flat]:
    		for key: StringName in source:
    			total[key] = total.get(key, 0.0) + source[key]
    	return total


    ## Skin multipliers (AD, AP, max HP), after item passives.
    func _scale_by_skin(block: StatBlock) -> void:
    	for key: StringName in skin.scale:
    		block.set(key, block.get(key) * skin.scale[key])
    ```
    - In `_ready` (`lucian.gd:134-135`) and `_refresh_stats` (`:726-727`): `stats = base_stats.at_level(progress.level, _stat_bonus())`, then `passives.adjust_stats(stats)`, then `_scale_by_skin(stats)`.
    - In `on_damage_dealt`, after the life steal block: `if skin.kill_heal > 0.0 and target.hp <= 0.0: heal(stats.max_hp * skin.kill_heal)`.
  - `Hud.setup`: `portrait.texture = target.skin.portrait`. Task 5 applies the skin before `hud.setup`, so no signal is needed.
  - `SaveGame._apply` keeps only ids `Skins.find` knows (exact match). Classic is always kept.
- [ ] **Step 4:** Run `test_skins`, `test_save_game`, the stats panel tests, then the full suite → PASS.
- [ ] **Step 5:** Commit `"Skins: High Noon, PROJECT, Pulsefire and Vampire with stats, portraits and body art"`.

---

### Task 5: StageSetup: the tree and skin reach the stage

**Files:**
- Create: `src/core/stage_setup.gd`.
- Modify:
  - Lucian side: `src/lucian/lucian.gd`, `src/lucian/skills/lightslinger.gd`, `src/lucian/summoners/summoner_spells.gd`
  - Shop: `src/core/shop.gd`, `src/ui/shop/shop_panel.gd`
  - Stage and HUD: `src/stage/stage.gd`, `src/ui/hud/skill_slot.gd`, `src/ui/hud/summoner_slot.gd`, `src/ui/tooltip/tooltip_card.gd`
  - Debug: `src/ui/debug/debug_table.gd`
- Tests: `test_stage_setup.gd`; extend `test_summoner_spells.gd`, `test_lucian_casting.gd`, `test_shop.gd`, `test_skill_slot.gd`.

**Interfaces — Consumes:** `SaveGame`, `EvolutionTree.level/value/nodes`, `Skins.find`.

**Interfaces — Produces:**
- `StageSetup`:
  - Skills and gear: `bought: Array[int]`, `passive: bool`, `equip_slots`, `shop_slots`, `refresh_cost`
  - Spells: `summoners: Array[StringName]`, `summoner_slots`, `summoner_upgrades: Dictionary`
  - Stats and look: `stat_bonus: Dictionary`, `skin: SkinData`
  - `SPELL_IDS`, `static from_save(save) -> StageSetup`
- `Lucian.apply_setup(setup)`.
- `Lightslinger.learned`.
- `SummonerSpells`: `open_slots`, `upgrades`, `COOLDOWN_UPGRADES`, `cooldown_of(spell) -> float`, `upgrade_text(id) -> String`.
- `Shop.refresh_cost`.
- `Stage.run: StageSetup`, `Stage.setup(run)`.
- `TooltipCard.summoner(spell, key, upgrade := "")`.

- [ ] **Step 1: Failing tests.**
  - `test_stage_setup.gd`:
    ```gdscript
    func test_a_new_save_gives_almost_nothing() -> void:
    	var setup := StageSetup.from_save(SaveGame.new("user://test_setup_"))
    	assert_eq(setup.bought, [0, 0, 0, 0] as Array[int])
    	assert_false(setup.passive)
    	assert_eq(setup.equip_slots, 1)
    	assert_eq(setup.shop_slots, 2)
    	assert_eq(setup.refresh_cost, 100)
    	assert_eq(setup.summoners, [&"", &""] as Array[StringName])
    	assert_eq(setup.summoner_slots, 1)
    	assert_eq(setup.skin.id, &"classic")


    func test_bought_nodes_reach_the_setup() -> void:
    	var save := SaveGame.new("user://test_setup_")
    	save.essences.from_dict({"blue": 99999, "orange": 999, "purple": 0})
    	for id in [&"skill_q", &"skill_q", &"stat_ad", &"stat_ad", &"equip_slots", &"merchant_stock", &"refresh_cost", &"flash", &"heal", &"summoner_slot_2", &"heal_upgrade"]:
    		assert_true(save.tree.buy(id, save.essences), String(id))
    	save.set_loadout(0, &"flash")
    	save.set_loadout(1, &"heal")
    	var setup := StageSetup.from_save(save)
    	assert_eq(setup.bought[0], 2)
    	assert_eq(setup.stat_bonus, {&"ad": 8.0})
    	assert_eq(setup.equip_slots, 2)
    	assert_eq(setup.shop_slots, 3)
    	assert_eq(setup.refresh_cost, 75)
    	assert_eq(setup.summoners, [&"flash", &"heal"] as Array[StringName])
    	assert_almost_eq(setup.summoner_upgrades[&"heal"], 0.15, 0.001)


    func test_f_stays_empty_without_the_second_slot() -> void
    func test_a_spell_not_bought_is_dropped_from_the_loadout() -> void
    func test_spell_ids_match_the_summoner_list() -> void:
    	assert_eq(StageSetup.SPELL_IDS, SummonerSpells.SPELLS.map(func(s: SummonerData) -> StringName: return s.id))


    func test_new_setup_is_the_phase_4_sandbox() -> void  # [5,5,5,3], passive, 6 slots, flash/heal, 2 open
    ```
  - Lucian/stage behavior (`test_lucian_casting.gd` / `test_summoner_spells.gd`, real `lucian.tscn`):
    - `apply_setup` with `passive = false`: after a Q cast, `lucian.passive.charged` is false.
    - `apply_setup` with `bought = [0, 0, 0, 0]`: `progress.can_rank_up(Q)` is false at level 1 with a point.
    - `equip_slots = 1` → `inventory.unlocked_equip == 1`.
    - `stat_bonus = {&"ad": 8.0}` → `stats.ad == base AD + 8`, and HP and mana are full afterwards.
    - `summoner_slots = 1`, `summoners = [&"flash", &"heal"]` → `use_summoner(1, …)` is false and `spell_in(1)` is null.
    - Flash with upgrade `-0.2` → its cooldown starts at 72 s.
    - Heal with `0.3` → heals `(80 + 15 × level) × 1.3` (× heal & shield power as today).
  - `test_shop.gd`: `shop.refresh_cost = 50` → a refresh costs 50.
  - `test_skill_slot.gd`: the passive slot shows its lock when `lucian.passive.learned` is false.
- [ ] **Step 2:** Run and expect FAIL.
- [ ] **Step 3: Implement.**
  - `StageSetup`:
    ```gdscript
    class_name StageSetup
    extends RefCounted
    ## What Lucian starts a stage with: Evolution Tree purchases, the equipped
    ## skin and the Journey loadout. A plain StageSetup.new() is the sandbox
    ## that stage.tscn uses on its own (tests, screenshots, F6): every rank
    ## bought, 6 equip slots, Flash and Heal.

    const SPELL_IDS: Array[StringName] = [&"flash", &"ghost", &"barrier", &"heal", &"clarity", &"smite"]

    var bought: Array[int] = [5, 5, 5, 3]
    var passive := true
    var equip_slots := Inventory.EQUIP_SIZE
    var shop_slots := 2
    var refresh_cost := MerchantStock.REFRESH_COST
    ## Spell ids on D and F (&"" for none), and how many of the keys are open.
    var summoners: Array[StringName] = [&"flash", &"heal"]
    var summoner_slots := 2
    ## Spell id -> upgrade value: a cooldown share off for Flash and Ghost
    ## (negative), an effect share added for the others.
    var summoner_upgrades := {}
    ## Flat stats from the tree's stat nodes, keyed like ItemStats.
    var stat_bonus := {}
    var skin: SkinData = Skins.ALL[0]


    static func from_save(save: SaveGame) -> StageSetup:
    	var tree := save.tree
    	var setup := StageSetup.new()
    	setup.bought = [tree.level(&"skill_q"), tree.level(&"skill_w"), tree.level(&"skill_e"), tree.level(&"skill_r")]
    	setup.passive = tree.level(&"passive") > 0
    	setup.equip_slots = int(tree.value(&"equip_slots"))
    	setup.shop_slots = int(tree.value(&"merchant_stock"))
    	setup.refresh_cost = int(tree.value(&"refresh_cost"))
    	setup.summoner_slots = 1 + tree.level(&"summoner_slot_2")
    	setup.summoners = []
    	for i in 2:
    		var id := save.loadout[i]
    		setup.summoners.append(id if i < setup.summoner_slots and tree.level(id) > 0 else &"")
    	for id in SPELL_IDS:
    		var upgrade := StringName("%s_upgrade" % id)
    		if tree.level(upgrade) > 0:
    			setup.summoner_upgrades[id] = tree.value(upgrade)
    	for data in tree.nodes():
    		if data.stat_key != &"" and tree.level(data.id) > 0:
    			setup.stat_bonus[data.stat_key] = setup.stat_bonus.get(data.stat_key, 0.0) + tree.value(data.id)
    	setup.skin = Skins.find(save.skin)
    	return setup
    ```
    `tree.level(&"")` is 0 (empty loadout entries stay empty).
  - `Lightslinger`: `## Bought in the Evolution Tree. Unlearned, skills never charge the second shot.` → `var learned := true`. `charge()` returns early when not learned.
  - `SummonerSpells`:
    - `var open_slots := 2` ("D always; F once the 2nd slot is bought").
    - `var upgrades := {}`.
    - `const COOLDOWN_UPGRADES: Array[StringName] = [&"flash", &"ghost"]`.
    - `spell_in(slot)` returns null when `slot >= open_slots`. `slots[slot]` may be `&""`; `find` already returns null for it.
    - `cooldown_of(spell) = spell.cooldown * (1.0 + upgrades.get(spell.id, 0.0))` for the cooldown spells, else `spell.cooldown`. `use()` starts the cooldown with it.
    - `_effect(id) = 1.0 + upgrades.get(id, 0.0)` for the effect spells (else 1), multiplying `BARRIER_BASE + …`, `HEAL_BASE + …`, `CLARITY_MANA` and `SMITE_DAMAGE`.
    - `upgrade_text(id)`: `"Upgraded: %d%% shorter cooldown"` or `"Upgraded: %d%% stronger"`, or `""`.
  - `Lucian.apply_setup(setup)`:
    ```gdscript
    ## Everything permanent Lucian starts the stage with. Called by the stage
    ## before the HUD and debug table read him.
    func apply_setup(setup: StageSetup) -> void:
    	progress.bought = setup.bought.duplicate()
    	passive.learned = setup.passive
    	inventory.unlocked_equip = setup.equip_slots
    	summoners.slots = setup.summoners.duplicate()
    	summoners.open_slots = setup.summoner_slots
    	summoners.upgrades = setup.summoner_upgrades.duplicate()
    	tree_bonus = setup.stat_bonus.duplicate()
    	apply_skin(setup.skin)
    	hp = stats.max_hp
    	mana = stats.max_mana
    ```
  - `Shop`: `var refresh_cost := MerchantStock.REFRESH_COST`, used by `refresh()`. `ShopPanel` shows `shop.refresh_cost` (set the button text when the shop opens, not in `_build`).
  - `Stage`:
    - `var run := StageSetup.new()`.
    - `func setup(stage_run: StageSetup) -> void: run = stage_run` ("call before adding the stage to the tree").
    - In `_ready`, before `hud.setup`: `lucian.apply_setup(run)` and `shop_slots = run.shop_slots`.
    - `_open_shop` sets `shop.refresh_cost = run.refresh_cost`.
  - `SkillSlot`: the passive slot (skill null) shows `_lock` when `not lucian.passive.learned` and greys its icon (the existing grey shader).
  - `SummonerSlot`: with no spell, draw only the frame. When `slot >= lucian.summoners.open_slots`, also draw `chain.svg` like `ItemCell`. Tooltips:
    - Locked: `TooltipCard.note("Locked: buy the 2nd summoner slot in the Evolution Tree.")`
    - Empty: `TooltipCard.note("No spell: pick one in Journey before starting.")`
    - Otherwise: `TooltipCard.summoner(spell, key, lucian.summoners.upgrade_text(spell.id))`, which adds the green line under the description when it isn't empty.
  - `DebugTable`:
    - The D/F pickers get **"None"** at index 0 (then the 6 spells). Picking for F sets `summoners.open_slots = 2`.
    - The selection is read from `slots` (`&""` → 0).
    - The shop-slots spin starts at `stage.shop_slots`.
    - A **Buy all ranks** button in the Lucian tab sets `progress.bought = ChampionProgress.MAX_RANKS.duplicate()` and `passive.learned = true`, then refreshes the HUD's "+" (it polls already; check).
- [ ] **Step 4:** Run the touched files, then the full suite → PASS. The Phase 4 tests must still pass unchanged, which proves the sandbox default.
- [ ] **Step 5:** Commit `"Stages start from the Evolution Tree, skin and loadout (StageSetup); the sandbox stays when the stage runs alone"`.

---

### Task 6: Game root, scene flow, save prompt and leaving a stage

**Files:**
- Create: `src/main/game.gd`, `src/main/game.tscn`, `src/ui/menu/confirm_popup.gd`.
- Modify: `src/ui/menu/game_menu.gd`, `src/stage/stage.gd`, `src/audio/sfx.gd`, `project.godot`.
- Test: `tests/unit/test_game.gd`.

`MainScreen` doesn't exist until Task 7. In this task, `Game.show_main_screen()` adds a **bare `MainScreen` stub**: `class_name MainScreen extends Control` with the two signals below. Task 7 fills it in.

**Interfaces — Produces:**
- `ConfirmPopup` (CanvasLayer, layer 80, `PROCESS_MODE_ALWAYS`): `ask(text: String, on_yes: Callable, on_no := Callable(), escape_means_no := true)`, `answer(yes: bool)`, `is_open() -> bool`.
- `GameMenu`: signals `leave_requested`, `exit_requested`.
- `Stage`: `signal finished(result: StringName)` (`&"left"` now; `&"cleared"` / `&"failed"` come with waves), `signal exit_requested`.
- `Game`: `screen: Node`, `show_main_screen()`, `start_stage(run: StageSetup)`, `ask_to_quit()`, `quit_game: Callable` (tests replace it).
- `MainScreen` signals: `start_requested(run: StageSetup)`, `exit_requested`.
- `Sfx.exists() -> bool`.

- [ ] **Step 1: Failing tests** (`test_game.gd`; `pre_run` already points `SaveGame` at scratch files):
  ```gdscript
  extends GutTest

  var game: Game
  var quit_called := false


  func before_each() -> void:
  	quit_called = false
  	SaveGame.instance().reset()
  	for file in [SaveGame.instance().path(1), SaveGame.instance().backup_path(1)]:
  		if FileAccess.file_exists(file):
  			DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
  	game = load("res://src/main/game.tscn").instantiate()
  	game.quit_game = func() -> void: quit_called = true
  	add_child_autofree(game)


  ## The prompt and the ESC menu pause the tree; never leave GUT paused.
  func after_each() -> void:
  	get_tree().paused = false


  func test_starts_on_the_main_screen() -> void:
  	assert_is(game.screen, MainScreen)


  func test_training_swaps_in_the_stage_with_its_setup() -> void:
  	var run := StageSetup.new()
  	run.equip_slots = 2
  	game.start_stage(run)
  	await wait_frames(2)
  	assert_is(game.screen, Stage)
  	assert_eq((game.screen as Stage).lucian.inventory.unlocked_equip, 2)


  func test_leaving_the_stage_saves_and_returns() -> void:
  	game.start_stage(StageSetup.new())
  	await wait_frames(2)
  	(game.screen as Stage).screens.menu.leave_requested.emit()
  	await wait_frames(2)
  	assert_true(FileAccess.file_exists(SaveGame.instance().path(1)))
  	assert_is(game.screen, MainScreen)
  	assert_false(get_tree().paused)


  func test_quit_asks_and_yes_saves() -> void:
  	game.ask_to_quit()
  	assert_true(game.prompt.is_open())
  	game.prompt.answer(true)
  	assert_true(FileAccess.file_exists(SaveGame.instance().path(1)))
  	assert_true(quit_called)


  func test_quit_no_leaves_without_saving() -> void
  func test_window_close_asks() -> void:
  	game.notification(NOTIFICATION_WM_CLOSE_REQUEST)
  	assert_true(game.prompt.is_open())
  ```
  `ConfirmPopup.answer(yes: bool)` is public, for tests and its own buttons.
- [ ] **Step 2:** Run and expect FAIL.
- [ ] **Step 3: Implement.**
  - `game.tscn`: one `Node` named `Game` with `game.gd`.
  - `Game`:
    ```gdscript
    class_name Game
    extends Node
    ## The root scene. Shows the main screen, swaps in a stage for Training and
    ## comes back when it ends (the stage-done auto-save). Leaving the game,
    ## from a menu or the window's close button, asks "Save before leaving?".

    const STAGE_SCENE := preload("res://src/stage/stage.tscn")

    ## The MainScreen or the Stage being played.
    var screen: Node
    var prompt := ConfirmPopup.new()
    ## Replaced in tests, which must not close the test run.
    var quit_game := func() -> void: get_tree().quit()


    func _ready() -> void:
    	GameSettings.instance().apply()
    	get_tree().auto_accept_quit = false
    	add_child(Sfx.new())
    	add_child(prompt)
    	show_main_screen()


    func _notification(what: int) -> void:
    	if what == NOTIFICATION_WM_CLOSE_REQUEST:
    		ask_to_quit()


    func show_main_screen() -> void:
    	var main := MainScreen.new()
    	main.start_requested.connect(start_stage)
    	main.exit_requested.connect(ask_to_quit)
    	_swap(main)


    func start_stage(run: StageSetup) -> void:
    	var stage: Stage = STAGE_SCENE.instantiate()
    	stage.setup(run)
    	stage.finished.connect(_on_stage_finished)
    	stage.exit_requested.connect(ask_to_quit)
    	_swap(stage)


    ## "Save before leaving?": Yes saves to the current slot (inside a stage
    ## that keeps what was collected, as leaving it would), then the game closes.
    func ask_to_quit() -> void:
    	if prompt.is_open():
    		return
    	get_tree().paused = true
    	prompt.ask("Save before leaving?", _quit.bind(true), _quit.bind(false), false)


    func _quit(save: bool) -> void:
    	if save:
    		SaveGame.instance().save()
    	quit_game.call()


    ## Deferred: the stage is still inside its own menu's signal here.
    func _on_stage_finished(result: StringName) -> void:
    	SaveGame.instance().finish_stage(result)
    	show_main_screen.call_deferred()


    ## The old screen goes at once; the prompt stays last so it gets input first.
    func _swap(next: Node) -> void:
    	if screen:
    		remove_child(screen)
    		screen.queue_free()
    	get_tree().paused = false
    	screen = next
    	add_child(next)
    	move_child(next, 0)
    ```
  - `ConfirmPopup`:
    - Built like `GameMenu`: a backdrop, a centered `UiStyle.panel()`, a message label at 26 px, and **Yes** / **No** buttons at 200 × 56.
    - `_input` swallows every key while open (`set_input_as_handled`). ESC answers No only when `escape_means_no`.
    - `answer(yes)` hides the pop-up, then calls the matching callable.
  - `GameMenu`: Leave this stage → `leave_requested.emit()` (no longer disabled). Exit the game → `exit_requested.emit()`. Update the class comment.
  - `Stage`:
    - In `_ready`, connect `screens.menu.leave_requested` → `finished.emit(&"left")` and `screens.menu.exit_requested` → `_exit()`.
    - `_exit()` emits `exit_requested`. With nobody connected (the stage run alone), it calls `get_tree().quit()` as before.
    - `add_child(Sfx.new())` only when `not Sfx.exists()`.
  - `Sfx.exists()`: `return _node != null`.
  - `project.godot`: `run/main_scene="res://src/main/game.tscn"`.
- [ ] **Step 4:** Run `test_game`, `test_cast_modes` (it loads the stage alone), then the full suite → PASS. Run the game once (`godot --path .`): it opens on the (empty) main screen stub, and closing the window asks.
- [ ] **Step 5:** Commit `"Game root scene: main screen first, Training swaps in the stage, Leave this stage auto-saves, leaving the game asks to save"`.

---

### Task 7: Main screen shell: essences, sections, gear menu, settings, save and copy

**Files:**
- Create: `src/ui/main/main_screen.gd` (fills in the stub), `src/ui/main/essence_bar.gd`, `src/ui/main/section_bar.gd`, `src/ui/main/gear_menu.gd`.
- Test: `tests/unit/test_main_screen.gd`.

**Layout** (1920 × 1080 virtual):
- **Background:** a dark radial gradient, drawn.
- **Top bar** (72 px):
  - Gear button (48 px, `gear.svg`, flat) at (16, 12).
  - Then the essences: 36 px icon + amount at 24 px, gap 28, in blue / orange / purple text.
  - Each essence has a hover card (`TooltipCard.note`): name, where it drops, what it buys (§9).
- **Bottom bar** (88 px): `SectionBar`, three 280 × 60 buttons centered (**Evolution Tree · Skin Shop · Journey**), styled with `UiStyle.style_button(selected)`.
- **Section area** between the bars: one child per section, only the chosen one visible. Task 7 uses placeholder Controls; Tasks 8–10 replace them.
- **Toast:** a label at the top center, fading over 1.6 s.

**MainScreen** also adds:
- a `GearMenu` (layer 40)
- a `SettingsScreen` (layer 45) set up with `GameSettings.instance()`
- its own `ConfirmPopup` for overwrite and reset (layer 80)
- a `HoverTip` (layer 100)
- `Sfx` comes from `Game`.

**GearMenu** (layer 40, backdrop + `UiStyle.panel()`, title "MENU", 340 × 56 buttons):

| Button | Does |
|---|---|
| Close | hides the menu |
| Save | `SaveGame.instance().save()` → toast "Saved to slot N" (or red "Could not save") |
| Save as copy | switches the panel to the slot list: "Slot 1 (current)" disabled, "Slot 2 · empty" / "Slot 2 · saved 2026-10-28 14:03", Back. An existing slot asks "Overwrite slot N?" → `copy_to(n)` → toast "Copied to slot N" |
| Settings | hides the menu and opens Settings; Back returns to the menu |
| Leave to main menu | disabled, hover "The title screen comes later" |
| Exit the game | `MainScreen.exit_requested` (Game asks to save) |

**ESC** (`open_menu`): skip while Settings is open or the `ConfirmPopup` is open (it handles its own ESC). Otherwise close the spell menu if one is open, else the slot list (back to the menu), else the gear menu, else open the gear menu.

**Interfaces — Produces:**
- `MainScreen`: `sections: Array[Control]`, `show_section(i)`, `show_toast(text, error := false)`, `confirm: ConfirmPopup`, `gear: GearMenu`.
- `GearMenu`: `open()`, `close()`, `show_slots()`, signals `settings_requested`, `exit_requested`, `saved(ok: bool)`, `copied(slot: int, ok: bool)`.
- `SectionBar`: `signal section_chosen(index)`, `select(index)`.
- `EssenceBar`: `setup(essences: Essences)`, `signal gear_pressed`.
- `MainScreen.SECTION_TREE := 0`, `SECTION_SKINS := 1`, `SECTION_JOURNEY := 2`.

- [ ] **Step 1: Failing tests** (`test_main_screen.gd`: `MainScreen.new()` added with `add_child_autofree`; scratch save):
  - It opens on Journey.
  - The essence labels show the amounts and update after `essences.add`.
  - The gear menu's Save writes slot 1 and shows the toast.
  - Save as copy to an empty slot 2 writes it without asking; when slot 2 exists, `confirm.is_open()` is true until answered.
  - Leave to main menu is disabled.
  - Exit emits `exit_requested`.
  - ESC opens the gear menu, and ESC again closes it.
  - Buying a tree node directly (`SaveGame.instance().tree.buy`) writes no file.
- [ ] **Step 2:** Run and expect FAIL.
- [ ] **Step 3:** Implement as specified. Reuse:
  - `UiStyle` (panel, buttons, labels)
  - `HoverTip`
  - `TooltipCard.note`
  - `SettingsScreen` (with `back_requested` → close + reopen the gear menu)
  - `Sfx.play(&"coin")` on Save, `&"error"` on a failure
- [ ] **Step 4:** Run the file, then the full suite → PASS.
- [ ] **Step 5:** Commit `"Main screen shell: essences, section bar, gear menu with Save, Save as copy, Settings and Exit"`.

---

### Task 8: Journey: act, Training and Endless tabs; loadout; Start Training

**Files:**
- Create: `src/ui/main/journey/{journey_section,journey_tab,act_page,stage_card,training_page,endless_page,loadout_panel,spell_menu}.gd`.
- Modify: `main_screen.gd` (replace the Journey placeholder; `start_training` → `start_requested.emit(StageSetup.from_save(SaveGame.instance()))`).
- Test: `tests/unit/test_journey_section.gd`.

**Layout:**
- **Tabs** across the top of the section: `Act 1 … Act 6 · Training · Endless`, 150 × 48 each, using `UiStyle.style_button(selected)`. A locked tab (`JourneyTab.locked`) is disabled and draws `chain.svg` over itself (as `ItemCell` does). Its hover text is "Clear Act N first" (Endless: "Clear Act 3 first").
- **Page area** on the left, about 1400 px:
  - **ActPage:**
    - Title "ACT 1 · THE LOSS" (34 px, `TITLE_COLOR`) and the story line (`DIM_COLOR`).
    - A row of `StageCard`s (200 × 230): "Stage N", "3 waves" or "5 waves + boss wave", and a skull (36 px; grey `9aa3b2` for a mini boss, red `e0475a` for a boss).
    - A card is locked (chain), open, or cleared (a green check drawn in the corner).
    - **Start** (disabled, "Acts come in a later phase").
  - **TrainingPage:**
    - Title "TRAINING", then: "Practice on training dummies with what you have bought in the Evolution Tree and your equipped skin. No essences are earned. Leave from the ESC menu to come back here."
    - **Start Training** (enabled, 320 × 64, gold).
  - **EndlessPage:**
    - Title "ENDLESS" and the rules (§14: waves never end, mini boss every 5, act boss every 10, a modifier pick every 10).
    - A map choice: 7 toggle buttons from `Journey.ENDLESS_MAPS`. The choice is kept in the page only and is not saved yet.
    - "Best wave: N" from `SaveGame.endless_best`.
    - **Start** (disabled, "Endless comes in a later phase").
- **LoadoutPanel** (right, 380 px, on every tab):
  - Title "SUMMONER SPELLS".
  - Two 72 px `SpellPick` buttons with the key labels from `GameSettings.key_label(&"summoner_d" / &"summoner_f")`.
  - F is chained (and disabled) until `summoner_slot_2` is bought, with hover "Buy the 2nd summoner slot in the Evolution Tree".
  - Clicking a slot opens `SpellMenu`: a small panel beside it with one icon button per **bought** spell, plus **None**. It closes on a pick, on ESC, or on a click outside.
  - A pick calls `SaveGame.set_loadout(i, id)`, which swaps when needed.
  - With no spells bought, the menu reads "Buy spells in the Evolution Tree".
- Everything refreshes on `SaveGame.changed` and `tree.changed` (the debug table can change both).

**Interfaces — Produces:** `JourneySection` with `signal start_training`, `tabs: Array[JourneyTab]`, `show_tab(i)`, `TRAINING_TAB := 6`, `ENDLESS_TAB := 7`; `LoadoutPanel.picks: Array[Button]`, `LoadoutPanel.open_menu(i)`; `SpellMenu.pick(id)`.

- [ ] **Step 1: Failing tests:**
  - A new save locks tabs Act 2–6 and Endless; Act 1 and Training are open.
  - `set_cleared(Journey.all_stage_ids(3))` opens Act 4 and Endless.
  - Act 3's cards show skulls on stages 2, 4 and 5.
  - In Act 1, stage 1 is open and a cleared card is marked.
  - Start Training emits `start_training`, and `MainScreen.start_requested` carries a setup with `equip_slots == 1`.
  - The F pick is disabled until `summoner_slot_2` is bought.
  - Picking Flash on D then on F swaps the loadout.
  - The menu lists only bought spells.
- [ ] **Step 2:** Run and expect FAIL.
- [ ] **Step 3:** Implement as specified. Reuse `Journey.*`, `UiStyle`, the `SummonerSpells.find(id).icon` art and `chain.svg` / `skull.svg`.
- [ ] **Step 4:** Run the file, then the full suite → PASS. Then play: Start Training → the stage opens with locks on Q/W/E/R and the passive, 1 equip slot, and D/F empty or chained. ESC → Leave this stage → back on Journey.
- [ ] **Step 5:** Commit `"Journey: act, Training and Endless tabs with unlock chains, stage cards, D/F loadout, Start Training"`.

---

### Task 9: Evolution Tree screen

**Files:**
- Create: `src/ui/main/tree/{tree_section,tree_map,tree_node_view,node_info_panel,cost_bar}.gd`.
- Modify: `main_screen.gd` (replace the placeholder).
- Test: `tests/unit/test_tree_section.gd`.

**TreeMap** (Control, `clip_contents`; holds a child `Map` Control that is moved and scaled):
- **Layout:**
  - `CELL := 150.0`. A node's center is `(MARGIN + col × CELL, GROUND_Y − row × CELL)`, with `MARGIN := 160`, `GROUND_Y := 620`.
  - Map size: `(MARGIN × 2 + 27 × CELL, 760)`.
- **Drawing on `Map`**, back to front:
  1. A ground band (dark brown) under row 0.
  2. Root strokes (2–3 curved brown lines) under each grove.
  3. The grove label under the ground ("SKILLS", "STATS", "EQUIPMENT", "ECONOMY", "SUMMONERS"; 22 px, `DIM_COLOR`).
  4. Requirement lines from each node to each of its `requires`: 4 px. **Bright gold** `ffcf5a` when the node has a level, else dim `3a4150`.
- **Nodes:** one `TreeNodeView` per node, added to `Map` at its center.
- **Pan:** left-drag pans. The press only becomes a drag after 6 px, so a click still selects a node. The pan is clamped so the map can't leave the screen.
- **Zoom:** the wheel zooms 0.6–1.4 in 0.1 steps, around the cursor.
- **Start view:** the Skills grove at the left edge, at zoom 1.0.

**TreeNodeView** (72 × 72 + a 22 px level badge below):

| State | Look |
|---|---|
| Hidden (`not is_open`) | Dark frame `2a2f3a`, no icon, a grey "?" (32 px) |
| Open, affordable | Icon, gold frame `UiStyle.BORDER_COLOR` |
| Open, can't afford | Icon, red frame `ff6a5a` |
| Bought, more levels | Icon, bright frame `ffe9a8` with a soft glow |
| Maxed | Icon, green frame `6fd36f` |
| Selected | An extra white outline |

- The badge reads "2/5" (hidden: nothing).
- Hover shows a short card: the name and the current value text.
- A click emits `chosen(id)`.

**NodeInfoPanel** (bottom-right, 440 px wide, `UiStyle.panel()`, shown once a node is chosen):
- Name (26 px).
- "LVL 2 / 5".
- `value_text(level) → value_text(level + 1)` ("+8 AD → +12 AD"). A maxed node shows only the current value, in green.
- The description (`TooltipText.colorize`).
- When the node is hidden:
  - The name reads "???".
  - A "Requires: Q – Piercing Light, W – Ardent Blaze or E – Relentless Pursuit" line is built from `requires` / `requires_count` / `requires_act`: "or" when `requires_count == 1`, "any 2 of …" when it's 2, and "Clear Act 1" for the act requirement.
- **CostBar** (400 × 56, the buy button):
  - It draws the owned essence against the cost for each kind needed: an icon, "120 / 350". The amount is red when short.
  - A fill shows `min(owned / cost)` over the kinds needed, at 1.0 when the cost is 0.
  - It's clickable only when `can_buy`; a click buys, plays `&"coin"` and refreshes everything.
  - States: "MAXED" (green, disabled) and "LOCKED" (grey, disabled). A cost of 0 shows "Free".

**Reset tree** (top-right of the section, 260 × 52): "Reset tree  5 [purple icon]". Disabled when `not can_reset`. It asks "Reset the Evolution Tree for 5 purple essence? Every blue and orange essence spent comes back." → `reset` → `&"refresh"` sound.

**Interfaces — Produces:** `TreeSection.map: TreeMap`, `info: NodeInfoPanel`, `select(id)`, `reset_button`; `TreeMap.views: Dictionary` (id → `TreeNodeView`), `TreeMap.zoom`, `TreeMap.pan_by(offset)`, `TreeMap.zoom_at(point, factor)`; `TreeNodeView.state() -> StringName` (`&"hidden"`, `&"open"`, `&"poor"`, `&"bought"`, `&"maxed"`); `CostBar.buy()`.

- [ ] **Step 1: Failing tests:**
  - With a new save: `skill_q` is `&"poor"`, `passive` is `&"hidden"`, and `skill_e` is `&"hidden"`.
  - With 1000 blue: `skill_q` is `&"open"`. After `select(&"skill_q")` + `info.cost_bar.buy()`: level 1, `&"bought"`, and `passive` is now `&"poor"` or `&"open"`.
  - After 5 buys: `&"maxed"` and the bar reads MAXED.
  - The info text for `stat_ad` at level 2 contains "+8 AD → +12 AD".
  - `zoom_at` clamps to 0.6–1.4.
  - A drag under 6 px still selects the node; a longer drag pans and doesn't select.
  - Reset asks first; Yes refunds and every node returns to level 0.
  - No save file is written by any of this.
- [ ] **Step 2:** Run and expect FAIL.
- [ ] **Step 3:** Implement as specified. Reuse `EvolutionTree`, the essence icons, `UiStyle` and `ConfirmPopup`.
- [ ] **Step 4:** Run the file, then the full suite → PASS.
- [ ] **Step 5:** Commit `"Evolution Tree screen: a forest map with pan and zoom, node states, info panel with the cost bar, Reset tree"`.

---

### Task 10: Skin Shop

**Files:**
- Create: `src/ui/main/skins/{skin_shop,skin_card}.gd`.
- Modify: `main_screen.gd`.
- Test: `tests/unit/test_skin_shop.gd`.

**Layout:**
- 5 `SkinCard`s (320 × 640) in a centered row, gap 24.
- Each card, top to bottom:
  - the portrait, 288 × 288, in a frame
  - the name (26 px)
  - bonuses, one line each, green `6fd36f` ("—" for Classic)
  - weaknesses, red `ff6a5a`
  - the playstyle (`DIM_COLOR`, wrapped)
  - the button, pinned to the bottom
- The equipped card has a bright gold border.

| Situation | Button |
|---|---|
| Not owned | **Purchase  25 [purple icon]**. Disabled with the price in red when purple is short |
| Owned, not equipped | **Equip** |
| Equipped | **Equipped** (disabled) |

- Purchase: `essences.spend(0, 0, cost)`, appends to `owned_skins`, emits `SaveGame.changed`, plays `&"coin"`. It doesn't equip.
- Equip: sets `SaveGame.skin`, emits `changed`.

`SaveGame` gains `buy_skin(id) -> bool` and `equip_skin(id) -> bool`, so the rule lives in core. Add their tests to `test_save_game.gd` in this task.

- [ ] **Step 1: Failing tests:**
  - A new save shows Classic as Equipped and the others as Purchase, disabled.
  - With 25 purple, buying High Noon leaves 0 purple and the button reads Equip.
  - Equip makes it Equipped and Classic's button Equip.
  - `StageSetup.from_save` then has `skin.id == &"high_noon"`.
  - No file is written.
- [ ] **Step 2:** Run and expect FAIL.
- [ ] **Step 3:** Implement as specified.
- [ ] **Step 4:** Run the file, then the full suite → PASS. Then play: buy and equip Vampire, Start Training → the red-collared body and the Vampire HUD portrait show, and max HP is lower.
- [ ] **Step 5:** Commit `"Skin Shop: cards with art, bonuses and weaknesses; purchase and equip"`.

---

### Task 11: Debug tables: shared base, main screen table

**Files:**
- Create: `src/ui/debug/debug_panel.gd`, `src/ui/debug/main_debug_table.gd`.
- Modify: `src/ui/debug/debug_table.gd`, `main_screen.gd`.
- Test: `tests/unit/test_main_debug.gd`.

**Interfaces — Produces:** `DebugPanel` (CanvasLayer):
- Setup: `_ready` sets layer 50, `PROCESS_MODE_ALWAYS` and hidden.
- `_input`: F3 + Q toggles. The exact code moves from `DebugTable._input`.
- `_build_frame(title: String) -> VBoxContainer`: the red-bordered panel, 400 px at (12, 12).
- Widget helpers: `_tab`, `_section`, `_label`, `_row`, `_button`, `_check`, `_spin` (moved unchanged).
- `_panel` (used by `DebugTable.set_docked_right`).

`DebugTable extends DebugPanel` with no behavior change. `MainDebugTable extends DebugPanel`:
- **Essences tab:** one row per kind: a label, +100 / +1000 / +10000 (blue) or +1 / +10 / +100 (orange, purple), and **Reset** (`set_amount(kind, 0)`).
- **Progress tab:**
  - **Acts cleared** spin (0–6) → `SaveGame.set_cleared(Journey.all_stage_ids(n))`.
  - **Max tree (free)** → `tree.max_all()`.
  - **Clear tree (no refund)** → `tree.clear()`.
  - **Reset progress** → `SaveGame.reset()` ("a new game in memory; nothing is saved until you save").

- [ ] **Step 1: Failing tests:**
  - F3 + Q (`Input.parse_input_event` with F3 held, as the stage debug test does) shows the table, and again hides it.
  - It starts hidden.
  - +1000 blue adds 1000.
  - Acts cleared 3 opens the Endless tab in Journey.
  - Max tree makes every node `maxed`.
  - Reset progress gives 0 essences and the Classic skin.
  - The stage `DebugTable` still toggles (the existing tests cover it).
- [ ] **Step 2:** Run and expect FAIL.
- [ ] **Step 3:** Implement: extract the base first (run the full suite: green), then add the main table.
- [ ] **Step 4:** Full suite → PASS.
- [ ] **Step 5:** Commit `"Debug table on the main screen (F3 + Q): essences, acts cleared, max or clear the tree, reset progress"`.

---

### Task 12: Screenshots, docs, report

**Files:** `tests/tools/screenshot.gd`; `docs/main_screen.md`, `docs/lucian_game_design.md`, `docs/ui_design.md`, `docs/implementation/phase5.md` (implementation notes), `docs/report/phase5.md`, `docs/report/phase5/*.png`.

- [ ] **Step 1: Screenshot scenarios.**
  - `_initialize` points `SaveGame._instance` at `user://screenshot_save_slot_` (deleting old files). It instantiates `res://src/main/game.tscn` for scenarios starting with `main_` or equal to `training_setup` / `skins_stage`; the stage for the others.
  - New scenarios: `art_sheet` (from Task 2), plus:

    | Scenario | Shows |
    |---|---|
    | `main_journey` | Training tab and the loadout, then the spell menu open |
    | `main_acts` | Act 1 with a new save; then debug acts cleared 2 → Act 3 with skulls and chains |
    | `main_endless` | Endless locked, then open |
    | `main_tree` | A new save; after +10000 blue / +100 orange, some nodes bought and the info panel open; zoomed out to 0.6 |
    | `main_tree_max` | Max tree: every icon, lit lines |
    | `main_skins` | Skin Shop with 0 purple, then with 100 purple and Vampire equipped |
    | `main_gear` | Gear menu, slot list, overwrite question, save prompt |
    | `main_debug` | Main debug table, both tabs |
    | `training_setup` | Start Training from a new save (locks, chains), then with Max tree |
    | `skins_stage` | Each skin in the stage: body, portrait, stats panel |

  - Each prints `expect … : actual` lines, as before.
- [ ] **Step 2:** Run every new scenario. Look at each PNG and fix anything off (node lines crossing frames, text overflow, unreadable icons). Copy the chosen PNGs to `docs/report/phase5/`.
- [ ] **Step 3: Docs.**
  - `main_screen.md`:
    - "Built in Phase 5": the node table (link to the design doc), forest layout, node states (no longer "proposed"), info panel and cost bar.
    - Journey pages and the loadout panel.
    - The gear menu (Leave to main menu disabled until the title screen exists), ESC and the toast.
  - `lucian_game_design.md`:
    - §8: spells are bought in the tree, F is chained until the 2nd slot, the loadout lives in Journey, and the upgrade numbers. Remove the "until the Evolution Tree exists" line.
    - §11: nodes with levels, E level 1 free after Act 1, stat amounts per level, refresh cost numbers (no more TBD), economy nodes saved but inactive until enemies give gold, XP or essences.
    - §14: Endless unlocks after Act 3.
    - §15 implementation notes: `SaveGame` (not an autoload, like `GameSettings`), the file layout, `saved_at`, the loadout saved.
    - §16: Phase 5 link.
  - `ui_design.md`:
    - §4: Leave this stage works (auto-saves, back to the main screen).
    - §6: Evolution Tree screen, Skin shop and Stage select ticked; "Main menu and save slot selection" stays open.
- [ ] **Step 4: Report** `docs/report/phase5.md`, in the same shape as `report/phase4.md`:
  - summary, test counts before → after
  - "What you asked for → what was built" (the 9 points)
  - the decisions, screenshots and playtest checklist
- [ ] **Step 5:** Full suite → PASS. Commit `"Phase 5 screenshots, docs and report"`.

---

## Verification

**Automated:** the full GUT suite is green after every task (command above).
- New files: `test_essences`, `test_save_game`, `test_evolution_tree`, `test_tree_data_files`, `test_journey`, `test_skins`, `test_stage_setup`, `test_game`, `test_main_screen`, `test_journey_section`, `test_tree_section`, `test_skin_shop`, `test_main_debug`.
- Extended files: `test_summoner_spells`, `test_lucian_casting`, `test_shop`, `test_skill_slot`.
- The Phase 1–4 tests pass unchanged: the `stage.tscn` sandbox is intact.

**Screenshots:** `art_sheet`, `main_journey`, `main_acts`, `main_endless`, `main_tree`, `main_tree_max`, `main_skins`, `main_gear`, `main_debug`, `training_setup`, `skins_stage`, saved to `docs/report/phase5/`.

**Manual playtest checklist (goes into the report):**
1. Launch the game: it opens on Journey → Training. No save file is created yet (`%APPDATA%\Godot\app_userdata\…\lucian_the_lantern\` or the custom user dir).
2. F3 + Q opens the main debug table; add essences; F3 + Q hides it.
3. Evolution Tree:
   - Drag to pan and wheel to zoom.
   - Buy Q twice: the frames go from red to gold to lit, and the line to the passive lights up once the passive is bought.
   - Hidden nodes show "?".
   - Max a node and it turns green.
   - Reset tree for 5 purple: everything comes back.
4. Skin Shop: buy and equip PROJECT; Classic shows Equip.
5. Journey:
   - Acts 2–6 and Endless are chained.
   - Debug acts cleared 3 opens them.
   - Stage cards show skulls.
   - Start is disabled outside Training.
6. Loadout: buy Flash and Heal and the 2nd slot; put Flash on D and Heal on F; swap them.
7. Start Training:
   - The bought ranks are the only "+" without a lock.
   - The passive is locked until bought.
   - The equip slots match.
   - D/F match the loadout.
   - The skin's body and portrait show.
   - The tree stats show yellow.
8. ESC → Leave this stage: back on Journey, and a save file now exists with everything bought.
9. Buy something more on the main screen, then Exit → "Save before leaving?" → No: after relaunching, that purchase is gone.
10. Gear → Save → toast. Save as copy → slot 2, then again → "Overwrite slot 2?".
11. Close the window with X during Training → the prompt shows; Yes saves.
12. Break `save_slot_1.json` by hand: the game loads the backup.

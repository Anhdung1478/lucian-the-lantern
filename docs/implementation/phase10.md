# Phase 10: Evolution Tree redesign and new rules, backpack slots, new backgrounds, Settings and title art, Senna's gun

> **Project:** `E:\Project\lucian-the-latern` (Godot 4.7.2 game).
> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development (or superpowers:executing-plans). One verified commit per task. Task 0 copies this plan to `docs/implementation/phase10.md`.

## Context

The user's Phase 10 request:

- **Evolution Tree view:** redesign it for a better view. Today it is one wide strip that you pan, with small nodes along the bottom and a mostly empty screen above them.
- **Main screen:** use another background.
- **Lucian's model:** his second gun is Senna's, so the two guns must look different.
- **Evolution Tree rules:**
  - **Skills:** R rank 1 needs the passive and Q + W + E ≥ 5. Rank 2 needs ≥ 9. Rank 3 needs ≥ 13.
  - **Equipment:** slot 3 needs Act 2 cleared and slot 5 needs Act 4. Rename the group "Backpack".
  - **New backpack-slots node:** the player starts with 5 backpack cells, not counting the equip slots. Upgrades add +5, +6, +6, +7, +8, +8, +9.
  - **Ghost:** free after stage 1.
  - **FREE badge:** a small FREE badge on the bottom Evolution Tree section for free upgrades the player hasn't taken.
  - **Stats:** add HP and mana regen.
- **Skin Shop:** a better background.
- **Settings:** a less plain design.
- **Main menu:** Lucian and Senna on the left and Thresh on the right, to tell the story, plus more decoration.

**Where the game stands**
- HEAD is `9bc1c88`, with Phase 9 done.
- About 1516 GUT tests. Task 0 runs the suite to record the real number.
- There is no autoload and no new `.tscn`. All UI is built in code, and all art is SVG or drawn in code.

**What exploration found**

- **The tree:**
  - Data:
    - `TreeNodeData` (`src/core/tree_node_data.gd`) holds `branch`, `grid`, `blue[]`/`orange[]` per level, `requires[]`/`requires_count`/`requires_act`, and `value = base + per_level × level`.
    - The 31 nodes are listed in `data/tree/catalog.tres`.
  - Rules live in `EvolutionTree` (`src/core/evolution_tree.gd`):
    - `is_open` only checks a node's first level. There are no per-level rules.
    - `acts_cleared` is derived from `SaveGame.cleared`.
  - The UI is in `src/ui/main/tree/`: `TreeSection`, the pannable `TreeMap` (`COLUMNS = 27`), 72 px `TreeNodeView`s, a pop-up `NodeInfoPanel` at the bottom right, and `CostBar`.
- **Skills and spells:**
  - R today requires Q, W, E and the passive, each at level 1.
  - E is free and bought automatically on the first Act 1 clear (`SaveGame._update_acts_cleared`).
  - Ghost costs 150 B and has no requirement.
- **Inventory** (`src/core/inventory.gd`) is a fixed 49-cell backpack (7×7) plus 6 equip slots in one index space. `unlocked_equip` locks equip slots, and items are never saved between stages.
- **Regen:**
  - The `hp_regen` and `mana_regen` per-second bonus keys already reach `UnitStats.at_level` through `StageSetup.stat_bonus`.
  - `assets/art/stats/regen.svg` exists.
- **Backgrounds:**
  - `MainScreen` and `TitleScreen` each have a plain radial-gradient `TextureRect`.
  - The Skin Shop has no background of its own.
  - `JourneyMap` has public static drawing helpers: `glow()`, `blob()`, `draw_chain()` and `draw_round_art()`.
- **Settings:** `SettingsScreen` styles its panel, tabs and buttons in gold and navy. Its sliders, `OptionButton`s, `CheckButton`s, scrollbar and separator use Godot's default grey.
- **Lucian's guns:**
  - In `assets/art/lucian/lucian_body.svg`, the two guns are mirrored copies: his own at y = −15 and Senna's at y = +15.
  - The muzzles are `MuzzleLeft`/`MuzzleRight` at (46, ±15) in `lucian.tscn`.
  - Each of the 5 skins has its own body SVG of the same size, which `test_skins.gd` checks.
- **Character art:** Senna (`npc/senna.svg`) and Thresh (`enemies/thresh.svg`) exist only as small top-down sprites. There is no standing art of them.

### Decisions made with the user
| Topic | Decision |
|---|---|
| Tree layout | **Branch pages with tabs.** Tabs along the bottom of the tree (Skills, Stats, Backpack, Economy, Summoners). Each page draws one branch large and centred on an illustrated tree, with no panning. The info panel stays on the right. Tabs with a free upgrade get a FREE badge. |
| Free Ghost | **Free to claim.** After 1-1, Ghost costs 0, and the player clicks it in the tree. E keeps its automatic grant. |
| Menu art | **Backlit silhouettes.** Dark standing figures lit from behind by moonlight, with colour accents: Lucian's gold muzzle glints, Senna's teal light, Thresh's green lantern and chains. |
| Senna's gun | **All five skins.** Each skin's right-hand gun becomes that skin's own take on Senna's relic gun. |

### Defaults chosen here (placeholders, tuned later; each goes into the docs in the last task)
- **R** needs the passive, plus Q + W + E ranks of 5 / 9 / 13 for ranks 1 / 2 / 3. It no longer needs Q, W and E each at rank 1 or more.
- **Equip slots:** slot 2 has no requirement. Slots 3–4 need Act 2 cleared, and slots 5–6 need Act 4. Slots 4 and 6 follow from the purchase order anyway.
- **Backpack Slots** (7 levels):

  | Level | Cells | Cost |
  |---|---|---|
  | 0 | 5 | — |
  | 1 | 10 | 50 B |
  | 2 | 16 | 100 B |
  | 3 | 22 | 200 B |
  | 4 | 29 | 350 B + 3 O |
  | 5 | 37 | 500 B + 8 O |
  | 6 | 45 | 800 B + 15 O |
  | 7 | 54 | 1200 B + 25 O |

  The first three levels are cheap, so the early game stays gentle. No act requirement.
- **Health Regen** gives +0.5/s per level (+2.5/s at 5). **Mana Regen** gives +0.6/s per level (+3.0/s at 5). Both use the stat cost table: 50/100/200/350/500 B and 0/0/0/3/8 O.
- **Ghost:** needs Act 1 (stage 1-1), costs 0, and is not bought automatically. `ghost_upgrade` follows through its `requires`.
- **Old saves keep their levels** even when they exceed the new rules. Such a node shows as bought with a LOCKED next level. Reset refunds from the current tables, so a dev save that paid 150 B for Ghost gets 0 back.
- **The FREE badge** appears on:
  - the main screen's bottom "Evolution Tree" button;
  - the tree's branch tabs;
  - the nodes themselves.

  "Free" means: the next level's rules are met, and its cost is 0.
- **Main screen background:** "Grove at night" behind the tree and the Journey, with sky, stars, moon halo, hill silhouettes, mist and drifting light motes. The **Skin Shop** gets "Hall of Relics": a stone gallery with one arch and spotlight per card, tinted by that skin.
- **Title "more decoration":**
  - the moon;
  - Shadow Isles cliffs and ruined Helia arches;
  - dead trees and gravestones;
  - drifting ground mist;
  - soul wisps leaving Thresh's lantern;
  - a faint spectral chain reaching from Thresh toward Senna along the ground;
  - teal motes around Senna.
- **Settings** gets a left tab rail with icons and rows as cards, plus a code-built `Theme` that gives the sliders, dropdowns and their pop-ups, the on/off switches and the scrollbars the gold and navy look.

---

## Design: Evolution Tree rules (data and logic)

### `TreeNodeData` additions
All are exported arrays, default `[]`, meaning "no rule":

| Field | Meaning |
|---|---|
| `level_values: Array[float]` | The value at levels 0..max_level, so `max_level + 1` entries. When set it replaces `base + per_level × level`. |
| `level_acts: Array[int]` | The act needed to buy each level, one entry per level like `blue`. The act actually needed is `maxi(requires_act, level_acts[i])`. |
| `level_sum_ids: Array[StringName]` | The nodes whose levels are added up. |
| `level_sums: Array[int]` | Per level, the total of those levels needed to buy it. |

**Helpers**
- `act_needed(i)` and `sum_needed(i)` return 0 past the end of the array.
- `short_name()` gives "Q" from "Q – Piercing Light".
- `value_text`'s "None" check becomes `value(0) == 0.0`. Re-verify every existing node's text.

### `EvolutionTree` API
- `BRANCHES = [&"skills", &"stats", &"backpack", &"economy", &"summoners"]` and `branch_nodes(branch)`.
- **Level checks:**
  - `is_level_open(id, i)` is true when all of these hold:
    - `acts_cleared ≥ act_needed(i)`;
    - the existing `requires` / `requires_count` check passes;
    - `level_sum(id) ≥ sum_needed(i)`.
  - `is_open(id)` becomes `is_level_open(id, 0)`.
  - `next_level_open(id)` means not maxed and `is_level_open(id, level(id))`.
  - `can_buy` uses `next_level_open`.
- **Requirement text** moves here from `NodeInfoPanel`, together with `_join`:
  - `requirement_text(id, i)` and `next_requirement_text(id)`. The second returns "" when the node is maxed or its next level is open.
  - Strings to pin in tests:

    | Case | Text |
    |---|---|
    | R on a new save | "Requires: Passive – Lightslinger and 5 levels in Q + W + E (now 0)" |
    | R at rank 1 | "Requires: 9 levels in Q + W + E (now 7)" |
    | Equip slots at level 1 | "Requires: Clear Act 2" |
    | Ghost | "Requires: Clear Act 1" |
- **Free upgrades:** `is_free(id)` is `next_level_open(id) and cost(id) == Vector2i.ZERO`. `free_ids(branch := &"")` and `has_free(branch := &"")` build on it.
- **What triggers a refresh:** only `tree.changed`. It fires on the acts setter, buy, reset, `max_all`, `clear` and `from_dict`. Connect named methods, not lambdas, because the main screen is rebuilt on every visit.
- **Unchanged:** `reset`. `max_all` stays a debug bypass. `from_dict` keeps saved levels with no clamping.
- **Small UI edits in the same task, so the suite stays coherent:**
  - `cost_bar.gd` lines 84 and 135 use `next_level_open`.
  - `node_info_panel.gd` shows `next_requirement_text`.

### Data
| Node | Change |
|---|---|
| `skill_r.tres` | `requires = [&"passive"]`, `level_sum_ids = [q, w, e]`, `level_sums = [5, 9, 13]` |
| `equip_slots.tres` | `level_acts = [0, 2, 2, 4, 4]`, `branch = &"backpack"`, a truthful description ("Opens more equip slots; only equipped items give stats.") |
| `ghost.tres` | `requires_act = 1`, `blue = [0]` |
| `stat_hp_regen.tres`, `stat_mana_regen.tres` (new) | `stat_key` `hp_regen` / `mana_regen`, formats "+{v}/s Health Regen" and "+{v}/s Mana Regen", new icons `assets/art/tree/stat_hp_regen.svg` and `stat_mana_regen.svg` (the `tree/stat_hp.svg` backdrop with a heart or drop and the up-arrow from `stats/regen.svg`) |
| `backpack_slots.tres` (new) | `max_level = 7`, `level_values = [5, 10, 16, 22, 29, 37, 45, 54]`, format "{v} backpack slots", icon `tree/backpack_slots.svg` |
| `catalog.tres` | 31 → 34 nodes: the regen nodes after `stat_mana`, `backpack_slots` after `equip_slots` |

- **Grove name:** the `&"equipment"` branch id becomes `&"backpack"`. That is save-safe, because saves key levels by node id and node ids never change.
- **Act 1 reward:** `stage.gd` `ACT_1_REWARDS` gains "Ghost is free to claim in the Evolution Tree".

### Backpack capacity (`Inventory`)
- **Size:** `BACKPACK_SIZE = 54` (a 9×6 grid), so `EQUIP_START = 54` and `SIZE = 60`.
- **`unlocked_backpack`:** a new field that defaults to `BACKPACK_SIZE`, so `Inventory.new()` stays fully open for the existing tests. Its setter mirrors `unlocked_equip`: clamp to 1..54, move items out of newly locked cells into the first empty unlocked cell, and leave them in place if there is none.
- **Locked cells:** `is_locked(i)` covers backpack cells at `i ≥ unlocked_backpack`. `space_for`, `add` and `_first_empty_backpack_cell` loop over unlocked cells only. `drop_outcome` returns RETURN when either end is locked.
- **Call sites:**

  | Where | Change |
  |---|---|
  | `shop.gd` | New `Result.CELL_LOCKED`, checked before `can_put` |
  | `shop_panel.gd` | New message "That cell is locked" |
  | `backpack_screen.gd` | `COLUMNS := 9` |
  | `item_cell.gd` | Already chains any locked cell. It gets the hover note "Buy Backpack Slots in the Evolution Tree". |
  | `debug_table.gd` | A "Backpack slots" spinbox |
- **Plumbing:** `StageSetup.backpack_slots` defaults to 54 in the sandbox and comes from `tree.value(&"backpack_slots")` (5 on a new save). `lucian.gd` `apply_setup` sets `unlocked_backpack` **before** `unlocked_equip`.

---

## Design: the tree pages (UI)

**Layout inside `TreeSection`** (the 1920 × 920 area between the main screen's bars)
- **Page canvas:** the left side, about 1408 wide.
- **Info column:** the right side, 440 wide, at the same width and margins as `JourneyPanel`, so the two sections feel alike. It is **always shown**:
  - With nothing picked, it shows the branch name, a one-line blurb, "Levels bought x / y" and "Pick a node".
  - With a node picked, it shows today's content plus `next_requirement_text`.
  - For R, it also shows "Q + W + E ranks: 7 / 9".
- **Reset tree:** stays at the top right of the page canvas.
- **`BranchTabs`** (new, `src/ui/main/tree/branch_tabs.gd`): a 64 px strip at the bottom of the page.
  - It holds 5 tabs. Each has an icon, the name, "x / y" levels, and a FREE badge.
  - The selected tab is lit gold.
  - The tree opens on the first branch with a free upgrade, otherwise on Skills.
- **ESC** clears the selection (`close_popup` returns true when something was selected).

**`TreePage`** (new, `src/ui/main/tree/tree_page.gd`; it replaces `TreeMap`, which is deleted)
- **One page per branch.** `grid` now means "(column, row up) on its branch's page". The page centres the branch's bounding box. The cell is about 180 × 150.
- **Drawing:**
  - A glowing trunk rises from roots at the bottom centre.
  - Curved limbs (bezier, like today's roots) reach each node.
  - Requirement links are drawn as vines: dim, then gold once the dependent node is bought.
  - A header at the top shows the branch name and a blurb.
  - Faint leaves and light motes.
  - Colours come from the grove backdrop's palette.
- **Node layouts** (re-author `grid` in the .tres files):

  | Page | Layout |
  |---|---|
  | Skills | Q, W, E along the bottom row. The passive sits above W, and R crowns the trunk. R's Q + W + E rule is drawn as a **segmented ring** around R (13 ticks, marks at 5 / 9 / 13, filled by the current total), not as three more lines. |
  | Stats | Three limbs of three: OFFENSE (AD, AP, Attack Speed), DEFENSE (HP, Armor, MR) and SUSTAIN (Mana, Health Regen, Mana Regen), each labelled. |
  | Backpack | Equip Slots and Backpack Slots, each with a preview under it. Equip shows a strip of 6 slots with locks and "Act 2" / "Act 4" tags. Backpack shows a 9×6 mini-grid with the open cells lit. |
  | Economy | Two limbs: REWARDS (stage gold, bonus XP, essence drop) and MERCHANT (stock, refresh cost). |
  | Summoners | The six spells along the bottom row, each spell's upgrade above it, and the 2nd summoner slot at the top centre. |
- **`TreeNodeView`:**
  - It grows from 72 to 96 px, with a larger level badge.
  - A small lock sits at the corner when the node is bought but its next level is closed.
  - A FREE badge sits at the top-right corner when `tree.is_free(id)`.
- **`TreeSection.views`** (id → view, across all pages) replaces `map.views` for tests and the screenshot tool.

**`FreeBadge`** (new, `src/ui/main/free_badge.gd`)
- A small pill with "FREE" in 13 px text, a green-gold fill and a slow pulse.
- It is used on the node views, `BranchTabs` and `SectionBar`.
- `SectionBar.set_badge(index, on)` sets the bottom-bar badge. `MainScreen` refreshes it from `tree.has_free()` on `tree.changed`.

## Design: backgrounds

- **`MainBackdrop`** (new, `src/ui/main/main_backdrop.gd`) is a full-screen control drawn in code. It replaces the gradient in `MainScreen._build`. `show_section` sets its `scene`:
  - **GROVE** (Tree and Journey): a night sky gradient from deep teal to indigo, seeded stars, a moon halo at the top left, two layers of hill and forest silhouettes, mist bands, a vignette, and about 40 slowly drifting light motes. Only the motes animate; everything else is static.
  - **GALLERY** (Skin Shop):
    - A dark stone back wall with five tall arches lined up with the five cards (it uses `SkinCard` size and `SkinShop` spacing constants).
    - In each arch, a soft glow and a light cone from above, tinted with a per-skin accent constant (Classic gold, High Noon amber, PROJECT cyan, Pulsefire blue, Vampire crimson), plus pillars and banners between the arches.
    - A polished floor with a reflection fade, and dust motes.
  - Reuse `JourneyMap.glow()`, `blob()` and `draw_chain()`. Mouse filter is IGNORE.

## Design: Settings

- **The panel** is about 1120 × 720, in `UiStyle.panel()`.
  - **Header:** a lantern emblem and "SETTINGS", over a gold rule with a diamond in the middle, in the Journey panel's style.
  - **Left rail** (240 px): 4 tabs, each with an icon and a label. The selected tab gets a gold fill and a left accent bar. The new icons are `assets/art/ui/settings_audio.svg`, `settings_controls.svg`, `settings_graphics.svg` and `settings_gameplay.svg`.
  - **Right side:**
    - Each page starts with a title and a dim one-line subtitle.
    - Each row is a card (a subtle fill and a 1 px border that brightens on hover), with the label, an optional dim description under it, and the control on the right.
  - **Footer:** Back at the bottom right, in gold as the primary button. The Controls page keeps "Reset to defaults".
- **`UiStyle.theme()`** (new, built once in code and cached): styles for
  - `HSlider`: a dark rounded track, a gold `grabber_area`, and grabber SVGs `slider_grabber.svg` / `slider_grabber_hl.svg`;
  - `OptionButton`: navy with a gold border and a gold arrow `option_arrow.svg`;
  - `PopupMenu`: a navy panel, a gold-tint hover and matching font colours;
  - `CheckButton`: `toggle_on.svg`, `toggle_off.svg` and disabled variants;
  - `VScrollBar`: thin, with a gold grabber;
  - `HSeparator`.

  Set it on the settings panel. **Check that it reaches the `OptionButton` pop-ups.** If it doesn't, set `get_popup().theme` explicitly.
- **Keep the public API and internals that others read:**
  - `setup`, `open`, `close`, `show_tab`, `listen`, `is_listening`, `back_requested`;
  - `_tab_buttons`, `_bind_buttons`, `_resolution`.

  The title screen, the main screen, the stage's `Screens/Settings` and `screenshot.gd` all use them.

## Design: Lucian's two guns

- **In all five bodies**, the left gun (y = −15) stays Lucian's slim relic pistol. The right gun (y = +15) becomes Senna's relic gun:
  - a chunkier, darker body (about y 9..21 instead of 11..19);
  - a heavy stock block;
  - two glowing ring bands;
  - a muzzle cap;
  - a muzzle light in the ring colour.
- **The muzzle stays at x ≈ 46**, so `MuzzleRight` doesn't move.
- **Per skin:**

  | Skin | Lucian's gun | Senna's gun |
  |---|---|---|
  | Classic | slim silver-gold | gunmetal `#2c363e`/`#3a4650` with teal `#b8fff0` rings |
  | High Noon | bronze revolver | dark iron with ember-orange rings |
  | PROJECT | chrome | boxy gunmetal with cyan rings |
  | Pulsefire | white | heavier white and blue, with a core |
  | Vampire | silver with a red gem | black iron with crimson rings |
- `lucian_body_one_gun.svg` (left gun only) is unchanged. Sizes stay 128, as `test_skins.gd` checks.

## Design: the title screen

- **`TitleBackdrop`** (new, `src/ui/title/title_backdrop.gd`) is drawn in code and animated in `_process`. It replaces the gradient and has mouse filter IGNORE. It draws:
  - a teal-black night sky with stars and a large pale moon at the upper left;
  - layered Shadow Isles cliffs, ruined Helia arches and spires at the right, dead trees and gravestones;
  - drifting ground-mist bands;
  - green spectral mist on Thresh's side;
  - soul wisps rising from Thresh's lantern;
  - a faint spectral chain (`JourneyMap.draw_chain`) from Thresh along the ground toward Senna;
  - teal motes around Senna;
  - a lantern glow pulse.
- **Three new SVGs** in `assets/art/ui/`, with large `width`/`height` over a smaller `viewBox` (the portrait trick) so they import sharp:

  | File | Size | Pose |
  |---|---|---|
  | `title_lucian.svg` | about 560 × 1000 | Front-left, a gun in each hand, his own slim and Senna's heavier. Gold glint on one, teal on the other. |
  | `title_senna.svg` | about 520 × 1000 | Behind Lucian, a little faded and ghostly teal (her soul is taken). Hooded, with her relic cannon. |
  | `title_thresh.svg` | about 700 × 1100 | Right side, looming. Hood with glowing eyes, chains, the green lantern held out. |

  All three are dark bodies with a moonlight rim stroke on one edge, plus accent glows.
- **Placement:** the figures are bottom-anchored `TextureRect`s, scaled to the 1080 height. Lucian and Senna sit at roughly x 80–620 and Thresh at roughly x 1300–1860.
- **Unchanged:** the centred column (lantern, title, buttons), which keeps its labels, because tests find buttons by text.

---

## Architecture

**New files**
- **Tree UI:** `src/ui/main/tree/tree_page.gd` (TreePage), `src/ui/main/tree/branch_tabs.gd` (BranchTabs), `src/ui/main/free_badge.gd` (FreeBadge).
- **Backdrops:** `src/ui/main/main_backdrop.gd` (MainBackdrop), `src/ui/title/title_backdrop.gd` (TitleBackdrop).
- **Tree data:** `data/tree/stat_hp_regen.tres`, `stat_mana_regen.tres`, `backpack_slots.tres`.
- **Art:**
  - `assets/art/tree/`: `stat_hp_regen.svg`, `stat_mana_regen.svg`, `backpack_slots.svg`;
  - `assets/art/ui/`: the `settings_*.svg` icons, `slider_grabber*.svg`, `option_arrow.svg`, `toggle_*.svg`, `title_lucian.svg`, `title_senna.svg`, `title_thresh.svg`.
  - Commit each one's `.import` file after running `--import`.
- **Tests:** `tests/unit/test_settings_screen.gd`, `tests/unit/test_main_backdrop.gd`.

**Changed files**
- **Rules and data:** `src/core/tree_node_data.gd`, `evolution_tree.gd`, `inventory.gd`, `stage_setup.gd`, `shop.gd`; `src/lucian/lucian.gd`; `src/stage/stage.gd` (`ACT_1_REWARDS`).
- **Tree UI:** `src/ui/main/tree/*` (`TreeMap` deleted), `src/ui/main/section_bar.gd`, `main_screen.gd`.
- **Other UI:** `src/ui/backpack/backpack_screen.gd`, `item_cell.gd`; `src/ui/shop/shop_panel.gd`; `src/ui/settings/settings_screen.gd`; `src/ui/ui_style.gd`; `src/ui/title/title_screen.gd`; the debug table.
- **Data and art:** `data/tree/*.tres` (grids, R, equip slots, Ghost, catalog); `assets/art/lucian/lucian_body.svg`, `assets/art/lucian/skins/*_body.svg`.
- **Screenshot tool:** `tests/tools/screenshot.gd`.

## Global constraints (as in Phases 6–9)
- **Code style:** Godot 4.7.2 GDScript in the style of the surrounding code: tabs, typed vars, `##` doc comments, `&"name"` StringNames, one `class_name` per file. No autoloads, no new `.tscn`.
- **Numbers:** new player-facing numbers are constants at the top of their script, or exports on a `.tres`.
- **Reuse, don't fork:**
  - drawing helpers from `JourneyMap`;
  - button and panel looks from `UiStyle`;
  - tree rules only through `EvolutionTree`, never re-checked in the UI.
- **Commits:** on a `phase10` branch in this folder, one verified commit per task (full GUT suite green), never pushed. Every message ends with a blank line, then `Co-Authored-By: Claude <noreply@anthropic.com>`, then `Claude-Session: https://claude.ai/code/session_013QapQ3hSg35TNDC9mdbCVi`. At the end, ask the user before fast-forwarding `main`.
- **Docs voice:** short plain sentences, tables for numbers.

## Running things
```powershell
$godot = "$env:LOCALAPPDATA\Programs\Godot"
& "$godot\godot_console.exe" --headless --path . --import          # after any new or changed SVG
& "$godot\godot_console.exe" --headless --path . -s res://addons/gut/gut_cmdln.gd
& "$godot\godot_console.exe" --headless --path . -s res://addons/gut/gut_cmdln.gd -gconfig= -gtest=res://tests/unit/<file>.gd -gexit
& "$godot\godot.exe" --path . -s res://tests/tools/screenshot.gd -- <scenario> <out_dir>   # real window, keep the mouse off it
```

---

## Tasks
Each task follows the same checklist: write failing tests, run them, implement, get the full suite green, then commit. No code is written in advance. Visual tasks also take a quick screenshot with an existing or temporary scenario to check by eye before committing.

### Task 0: Branch and save the plan
- Create a `phase10` branch from `main`.
- Run the suite and record the test count.
- Copy this plan to `docs/implementation/phase10.md` and add its §16 line to `lucian_game_design.md`.
- Commit: "Add the Phase 10 plan".

### Task 1: Per-level rules in the tree (no data change yet)
- **Files:** `tree_node_data.gd`, `evolution_tree.gd` (`BRANCHES` waits for Task 3), `cost_bar.gd`, `node_info_panel.gd`.
- **Tests:**
  - `test_evolution_tree.gd`: `TreeNodeData.new()` units for `level_values`, `act_needed`, `sum_needed` and `short_name`; `is_level_open`, `next_level_open`, `requirement_text` and `next_requirement_text`; `is_free`, `free_ids` and `has_free` on E.
  - `test_tree_section.gd`: the requirement-text tests (lines 224–231) move to `tree.requirement_text`.
- **Commit:** "The Evolution Tree checks rules per level".

### Task 2: R needs the passive and 5 / 9 / 13 Q + W + E ranks
- **Files:** `skill_r.tres`.
- **Tests:**
  - Replace `test_r_needs_q_w_e_and_the_passive`.
  - R stays hidden until the passive and a total of 5 (Q4 W0 E1 opens it).
  - R2 needs 9 and R3 needs 13.
  - Old saves keep R at 3, with the next level closed.
  - The panel texts.
- **Commit:** "R ranks need the passive and 5, 9, 13 levels in Q + W + E".

### Task 3: Equip slot acts, and the Equipment grove becomes Backpack
- **Files:** `equip_slots.tres`, `evolution_tree.gd` (`BRANCHES`, `branch_nodes`), `tree_node_data.gd` doc.
- **Tests:**
  - Level 2 is refused until Act 2 and level 4 until Act 4, each with "Requires: Clear Act N".
  - Every branch is in `BRANCHES`.
  - `test_stage_setup` is unchanged.
- **Commit:** "Equip slot 3 needs Act 2 and slot 5 Act 4; the Equipment grove is now Backpack".

### Task 4: Ghost is free to claim after stage 1-1
- **Files:** `ghost.tres`, `stage.gd` `ACT_1_REWARDS`.
- **Tests:**
  - Ghost is hidden before Act 1 and free after.
  - Clearing 1-1 leaves Ghost at 0, with `free_ids == [ghost]`.
  - After a reset, `free_ids` is `[skill_e, ghost]`.
  - The data COSTS table.
  - The Act 1 reward line (`test_act1.gd`).
- **Commit:** "Ghost is free to claim once stage 1-1 is cleared".

### Task 5: Health Regen and Mana Regen stat nodes
- **Files:** the 2 `.tres` files, the 2 SVGs with their `.import` files, `catalog.tres`.
- **Tests:**
  - Data counts become 33, plus the COSTS table.
  - The value texts.
  - `StageSetup.stat_bonus` gets `hp_regen` / `mana_regen`.
  - Lucian's `stats.hp_regen` and `stats.mana_regen` rise.
- **Commit:** "Health Regen and Mana Regen in the Evolution Tree".

### Task 6: A 54-cell backpack (9×6) with locked cells
- **Files:** `inventory.gd`, `shop.gd`, `shop_panel.gd`, `backpack_screen.gd`, `item_cell.gd` (the hover note).
- **Tests:**
  - `test_inventory`: 54 / 60; everything open by default; the lock edges with 5 open; `add`/`space_for` use only open cells; `put` is refused on a locked cell; lowering moves items; lowering the equip slots skips locked cells.
  - `test_shop`: NO_ROOM and CELL_LOCKED.
  - `test_loot`: a drop stays on the ground.
  - `test_backpack_drag`: a drop on a locked cell returns; the grid has 9 columns.
  - Update the hard-coded 49 / 55 values.
- **Check:** take a screenshot of the backpack with the shop open at 1920 wide.
- **Commit:** "The backpack has 54 cells and only the unlocked ones take items".

### Task 7: The Backpack Slots node
- **Files:** `backpack_slots.tres`, its SVG and `.import`, `catalog.tres`, `stage_setup.gd`, `lucian.gd`, `debug_table.gd`.
- **Tests:**
  - Counts become 34.
  - `level_values` and the text "5 backpack slots".
  - The top value equals `Inventory.BACKPACK_SIZE`.
  - Setups: a new save gets 5, two levels give 16, the sandbox gets 54.
  - `apply_setup` sets `unlocked_backpack` before `unlocked_equip`.
  - `test_game` passes the run through.
- **Commit:** "Backpack Slots: 5 cells at the start, up to 54 from the Evolution Tree".

### Task 8: Tree pages with branch tabs
- **Files:** `tree_page.gd` (new), `branch_tabs.gd` (new), `tree_section.gd`, `tree_node_view.gd` (96 px, lock corner), `node_info_panel.gd` (permanent column, branch summary, R's sum line), `tree_map.gd` (deleted), and the `grid` values in every tree `.tres`.
- **Tests (`test_tree_section.gd` rewritten):**
  - 34 views across 5 pages, with only one page visible.
  - Tabs switch pages, and the tree opens on the first branch with a free upgrade, or on Skills.
  - No two nodes share a cell within a branch.
  - Every view stays inside its page at 1920×1080.
  - Node states and badges keep working, plus the lock corner.
  - The info column with nothing picked, then picking a node.
  - ESC clears the selection.
  - Reset still works, and nothing writes a file.
  - Remove the pan and zoom tests.
- **Commit:** "The Evolution Tree is five branch pages with tabs".

### Task 9: FREE badges
- **Files:** `free_badge.gd` (new), `tree_node_view.gd`, `branch_tabs.gd`, `section_bar.gd` (`set_badge`), `main_screen.gd` (named-method refresh on `tree.changed`).
- **Tests:**
  - A new save shows no badge.
  - After 1-1: badges on the Evolution Tree button, the Summoners tab and the Ghost node (E is bought automatically).
  - Claiming Ghost clears them.
  - A reset shows them on Skills and Summoners.
  - A freed main screen leaves no connection on the save's tree.
- **Commit:** "A FREE badge marks free upgrades on the tree button, tabs and nodes".

### Task 10: New main screen background and the Skin Shop gallery
- **Files:** `main_backdrop.gd` (new), `main_screen.gd`.
- **Tests (`test_main_backdrop.gd`):**
  - The scene follows `show_section`.
  - Mouse filter is IGNORE, and the backdrop is the first child.
  - The gallery arches line up with the card centres.
  - It draws without errors in both scenes.
- **Check:** screenshots of the tree and the shop.
- **Commit:** "A night grove behind the main screen and a hall of relics behind the Skin Shop".

### Task 11: Settings redesign
- **Files:** `settings_screen.gd`, `ui_style.gd` (`theme()`), the new settings SVGs and their `.import` files.
- **Tests (`test_settings_screen.gd`):**
  - 4 tabs; `show_tab` shows one page.
  - The theme reaches sliders, dropdowns (including their pop-up) and switches.
  - Each control still writes `GameSettings` (one slider, one dropdown, one switch).
  - Rebinding still works.
  - Back emits `back_requested`, and ESC closes.
- **Check:** screenshots of all 4 tabs from the title and in a stage.
- **Commit:** "Settings: a tab rail, row cards and styled controls".

### Task 12: Lucian's own gun and Senna's gun
- **Files:** `lucian_body.svg` and the 4 `skins/*_body.svg`, re-imported.
- **Tests:** `test_skins` sizes still match, and the muzzle markers are unchanged.
- **Check:** `art_sheet` and `skins_stage` screenshots.
- **Commit:** "Lucian's second gun is Senna's relic gun on every skin".

### Task 13: Title screen art
- **Files:** `title_backdrop.gd` (new), `title_screen.gd`, the 3 title SVGs and their `.import` files.
- **Tests (`test_title_screen.gd`):**
  - The backdrop and the three figures exist, ignore the mouse, and their textures load.
  - Lucian and Senna are left of centre and Thresh right of it.
  - All buttons are still found by text and still work.
- **Check:** screenshots of the title and slot pages.
- **Commit:** "Title screen: Lucian and Senna face Thresh under the Shadow Isles moon".

### Task 14: Screenshots, docs, report
- **`screenshot.gd`:**
  - Update `main_tree`, `main_tree_max` and `tree_icons` to pages and tabs, and drop pan and zoom.
  - Remove the Ghost purchase at about line 1300.
  - Add the new scenarios:

    | Scenario | Shows |
    |---|---|
    | `tree_rules` | R needs 9; equip slot needs Act 2 |
    | `tree_free` | Badges after 1-1, and claiming Ghost |
    | `backpack_slots` | The 9×6 backpack with 5 open, in a stage |

  - Re-shoot `main_skins`, `settings` (4 tabs), `title`, `title_slots`, `skins_stage` and `art_sheet` into `docs/report/phase10/`.
- **Docs:**
  - `lucian_game_design.md`: §11 rule sentence, R rows, Equipment → Backpack table with acts, the Backpack Slots table, regen rows, Ghost free, 34 nodes; the inventory text (54 cells, 5 open); §16.
  - `main_screen.md`: Section 1, "Built in Phase 10", and the Section 2 background.
  - `ui_design.md`: §2 backpack, §5 Settings, §7 Title.
  - `act1_the_loss.md`: the Ghost reward.
- **Report:** `docs/report/phase10.md` in the Phase 9 layout.
- **Plan notes:** `## Implementation notes (Phase 10 done)` in the plan.
- **Commits:** "Phase 10 screenshots" and "Phase 10 docs and report".

## Verification
- **Suite:** the full GUT suite is green after every task. Record the final count; Task 0's baseline plus the new tests.
- **Screenshots:** check them by eye against the request:
  - the tree pages have no big empty areas and nodes are readable;
  - the FREE badges show after 1-1;
  - R's ring meter;
  - the backpack at 5 / 54 open;
  - the grove and gallery backgrounds;
  - Settings with no grey default widgets left, including dropdown pop-ups;
  - the two guns clearly different on every skin at game zoom;
  - the title figures don't crowd the buttons at 1920×1080 or at the 1600×900 window.
- **Manual playtest checklist (in the report):**
  1. On a new save, clear 1-1. FREE shows on the tree button. Claim Ghost and put it in D.
  2. Buy Q / W / E up to 5 total; R opens. Check that R2 asks for 9.
  3. In a stage, fill the 5 backpack cells and check "Backpack full", then buy Backpack Slots and check it in the next stage.
  4. Equip slot 3 shows LOCKED "Clear Act 2" until Act 2.
  5. Health and Mana Regen show "+x/s" on the HUD.
  6. Use Settings from the title, the main screen and a stage.

## Risks to watch
- **Theme reach:** `OptionButton` pop-ups are Windows. Confirm the theme reaches them; if not, set the popup's theme directly.
- **SVG imports:** new SVGs need their `.import` files committed. Without them icons load as null and the data tests fail.
- **Early game:** 5 starting backpack cells may feel tight in Act 1–2. The first levels are cheap (50 / 100 B) and potions stack. The playtest checklist covers it. Keep [early-difficulty] in mind.
- **Hand-made SVG figures** are the hardest art in the phase. Budget a visual pass (shoot, look, adjust) inside Task 13. If the silhouettes read poorly, simplify them rather than add detail.
- **Animated backdrops** redraw every frame. Keep the static layers cached (draw once into a child that never redraws, and redraw only the motes), and check the FPS display stays at the cap.
- **`test_tree_section.gd` is largely rewritten** in Task 8. Keep every behaviour it covered that still exists: states, badges, the info panel, cost bar, hover, reset, ESC, no file writes.
- **Old dev saves** may sit above the new rules (bought, with a LOCKED next level). The pages must show that state cleanly.

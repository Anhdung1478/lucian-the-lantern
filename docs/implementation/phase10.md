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


---

## Implementation notes (Phase 10 done)

Everything in the plan is in place, one commit per task (Tasks 0–13), plus a review-fix commit for Tasks 8 and 9. Task 14 is two commits: the screenshots, then these docs and the report (`docs/report/phase10.md`). The numbers in *Design* were placeholders; the game design doc §10–§11 ("Built in Phase 10"), `main_screen.md` and `ui_design.md` give the built ones. Changes and details settled while building:

| Task | Commits |
|---|---|
| 0 Plan | `60a905a` |
| 1 Per-level rules | `77b505a` |
| 2 R needs 5 / 9 / 13 | `d68a56f` |
| 3 Equip slot acts, the Backpack grove | `fe6c8db` |
| 4 Ghost free after 1-1 | `62c2326` |
| 5 Health Regen and Mana Regen | `7b4aa32` |
| 6 A 54-cell backpack | `5fe05c7` |
| 7 Backpack Slots | `36f4f96` |
| 8 Tree pages with tabs | `7c5f71d`, review fix `220d7bb` |
| 9 FREE badges | `076fd72`, review fix `b6d4a92` |
| 10 Grove and gallery backgrounds | `bd96a40` |
| 11 Settings | `c40888e` |
| 12 Senna's gun | `f6df41c` |
| 13 Title art | `cece518` |
| 14a Screenshots | `d0b34bb` |
| 14b Docs and report | "Phase 10 docs and report" |

### Deviations and rulings
The plan's *Decisions made with the user* and *Defaults chosen here* stand as written. The controller's rulings, each with its reason:
- **R1, `screenshot.gd` keeps compiling.** A task that removed or renamed something the screenshot tool uses (Task 8 deleting `TreeMap`) updated the tool in the same task, just enough for it to compile and run. Task 14 added the new scenarios. A tool that doesn't compile would have blocked every later task's screenshot check.
- **R2, the gallery reads the shop's sizes.** `MainBackdrop` lines its arches up with `SkinCard.SIZE`, `SkinShop.GAP` and `MainScreen.TOP_BAR` / `BOTTOM_BAR`, which already existed. No number is copied.
- **R3, batches.** Tasks 1–4 ran as one dispatch and Tasks 5–7 as another, one commit per task. Each commit ran its focused tests, and the full suite ran before each batch's last commit.
- **R4, Task 0 by the controller:** the plan copy, the §16 line and the baseline suite (1516 tests).
- **R5, commit trailers.** Every commit ends with both `Co-Authored-By: Claude <noreply@anthropic.com>` (the user's rule) and the session's `Claude-Session:` line.
- **R6, the tree's palette.** Task 8 kept the night-grove colours as constants in `TreePage`, since the grove backdrop didn't exist yet. Task 10 moved the shared sky colours to `MainBackdrop`.
- **R7, no second moon.** The grove backdrop draws only what shows around the framed tree page and Journey map: the sky, stars, mist bands, a vignette and motes. There is no moon or hill, since `TreePage` draws its own inside its frame. The sky, the stars and the motes became shared static helpers (`MainBackdrop.draw_sky`, `draw_stars`, `draw_mote`), used by `TreePage`, `MainBackdrop` and `TitleBackdrop`.
- **Tasks 1–4:**
  - `requirement_text` lists only what is still missing, so R at rank 1 reads "Requires: 9 levels in Q + W + E (now 7)", without the passive. It returns "" when everything is met.
  - `level_acts[i]` and `level_sums[i]` are the rules for buying level i + 1, indexed like `blue`.
  - `from_dict` still clamps to the max level only, so old saves keep levels above the new rules.
- **Tasks 5–7:**
  - The regen nodes sat at grid (7, 1) and (11, 1), and Backpack Slots at (14, 0), until Task 8 re-authored every grid for the pages.
  - `drop_outcome` returns RETURN when either end is locked. So an item stranded in a locked cell can't be dragged out, only sold. Only lowering the debug spinner with no room left can strand one.
  - The "Buy Backpack Slots in the Evolution Tree" hover shows on locked backpack cells only.
  - `Shop.Result.CELL_LOCKED` is new, checked before `can_put`.
- **Task 8, the pages:**
  - **Accepted beyond the plan:**
    - each node's name on a plate under it, so vines never cross it;
    - the info column's node list, grouped like the page, whose rows pick a node;
    - the per-level LEVELS ladder;
    - the moon and the side trees;
    - the `node_chosen` signal.

    They fill what were empty areas, as the request asked.
  - The page centres the branch's columns, and its rows from the ground (row 0) to the top row, not from the lowest node. That keeps room under the Backpack page's nodes for their previews.
  - Skills spreads to columns 0, 2.5 and 5. Each bough leaves the trunk on its own side, so they never cross.
  - R's ring leaves its bottom 144° open for the badge and the name.
  - The equip strip outlines the next slot only when its level is open. Otherwise that slot shows a lock.
  - `JourneyPanel._divider()` became the public static `JourneyPanel.divider()`.
  - `tree_page.gd` is 733 lines, almost all drawing.
- **Task 9:** after 1-1 the badge shows on the Ghost node, the Summoners tab and the tree button. `FreeBadge` syncs its pulse in `_ready`, because entering the tree turns processing on without a visibility change.
- **Task 10:**
  - More unlit arches continue past the five cards, as far as the screen goes. That also covers wider screens.
  - `draw_mote` is shared too, so the tree's, the main screen's and the title's motes look alike.
  - `main_backdrop.gd` is 611 lines, about 330 of them the gallery.
- **Task 11:**
  - **Accepted beyond the plan:** `SettingsRow` (the card, in its own class) and `option_check.svg` (the gold diamond in dropdown lists). Without the SVG, the lists kept Godot's grey radio circles.
  - The theme reaches the dropdowns' pop-up lists without being set on them. A test pins it.
  - The panel is opaque, because at 0.96 the title's logo showed through. Volumes show as whole numbers.
  - A card's controls let the mouse through to the card (PASS), so the card lights when its slider is hovered. The wheel now scrolls the Controls list over its buttons too.
  - The old 4-line Controls hint was split: its first sentence is the page subtitle, and the rest is a 2-line hint. "Ctrl + the stats key toggles the stats panel (hold it for more)" was dropped, since the action's own name says it.
  - `settings_screen.gd` is 518 lines.
- **Task 12:**
  - The art sheet gained a second page, `art_sheet_1_bodies`: the five bodies at 2× and at game size.
  - High Noon's rings are ember `#ff6a2a`. The first orange matched the revolver.
  - The dark gun bodies of High Noon, PROJECT and Vampire are lighter than the plan's hexes, so they show on the floor. PROJECT also got a dim neon rim.
  - On PROJECT and Vampire, Senna's muzzle light is the same colour family as Lucian's, as the ring colours asked.
- **Task 13:**
  - Godot's SVG importer (ThorVG) draws nothing for `<mask>`, so Senna fades with alpha gradients instead.
  - The figures at 1920 × 1080: Senna x 0–398, Lucian x 190–679, Thresh x 1258–1880. Lucian's rect ends 21 px before the slot list's column (x 700); a test pins it.
  - Anything in the right half moves with the right edge, so on a wider screen only the middle widens.
  - `title_backdrop.gd` is 509 lines, about 135 of them constants.

### Visual pass (Task 14)
Every scenario Phase 10 added or changed was run in a window, and every PNG was looked at: 64 in all.
- **No game bug found.** All printed checks matched.
- **Checked against the request:**
  - the pages fill their frames, and the nodes read;
  - the FREE badges show after 1-1 and go once Ghost is claimed;
  - R's ring;
  - the backpack at 5 / 54 open;
  - the grove and the gallery;
  - no grey default widget in Settings, dropdown lists included;
  - the two guns differ on every skin at game zoom;
  - the title figures stay clear of the buttons in the 1600 × 900 window.
- **Noticed, not changed:**
  - the Economy and Backpack pages have open sky in their middle;
  - Max tree leaves the "Act 2" and "Act 4" tags dim, because it skips the act rules;
  - a picked hidden node shows its description and ladder (the known leak);
  - the Summoners list nearly fills the info column.

### Screenshot harness
- **Carried from earlier tasks:**
  - Task 8 moved `main_tree`, `main_tree_max` and `tree_icons` to `section.views`, the tabs and `show_branch`, and dropped the pan, zoom and drag shots. `main_tree` clears Act 1 before its buys; its printed expectations had been stale since Q needed Act 1. It shoots every tab and prints each tab's draw mode.
  - Task 9 added `tree_free`.
  - Task 11 added `title_settings`, the dropdown step in `settings`, and the `hover()` helper.
  - Task 12 added the art sheet's bodies page.
- **Task 14:**
  - New Game scenarios:
    - `tree_rules`: R needs 9, Equip Slots needs Act 2, then Act 2 cleared;
    - `backpack_slots`: 5 of 54 cells in Training, a locked cell's hover, "Backpack full", then 16 cells after two levels.
  - `main_journey` no longer buys Ghost on a new save, since Ghost needs Act 1 now. Its menu expectation is [flash, heal, smite].
  - `main_tree` prints R's expected requirement text.
  - `art_sheet` adds the 15 new icons: the regen and Backpack Slots nodes and the 12 Settings SVGs (51 in all).
  - `title_settings` scrolls E's row into view before its listening shot.
- 64 PNGs in `docs/report/phase10/`, all 1600 × 900, each with its `.import`, as in Phase 9.

### Fixes from reviews
- **Task 8 (Important):** `TreePage` and `NodeInfoPanel` had copied the Journey's frame, text, glow and rule drawing, and `TreePage` changed a shared `FontVariation` while drawing. Fixed in `220d7bb`:
  - `JourneyMap.draw_frame`, `draw_text` and `text_font` (a cache of spaced fonts that are never changed) are shared statics;
  - so are `JourneyPanel.frame_style`, `draw_top_glow` and `draw_rule`;
  - the Journey looks the same: a pixel diff found changes only in animated spots.
- **Task 8, the lit tab:** one early run showed the Skills tab lit on other pages. It was a synthetic mouse release lost in the harness, and it didn't come back in 6 runs. `main_tree` now prints every tab's draw mode at shot time.
- **Task 9 (Important):** a badge visible as the tree opened didn't pulse. Fixed in `b6d4a92`, with a test for 4 cases.
- **Found by the implementers in self-review:**
  - The info column's rows were freed with `queue_free`, so every rebuild left GUT orphans until the frame ended. They are freed at once now.
  - Hovering a Settings slider darkened its card. The cards' controls are PASS now, with a test.

### Left as is (small, from the reviews)
- **Tasks 1–4:** `requirement_text` declares `var names` in two blocks (legal). The `free_ids` tests assert catalog order (skill_e before ghost), on purpose.
- **Tasks 5–7:**
  - An item stranded in a locked cell can be sold but not dragged out (debug only).
  - `Shop.Result.CELL_LOCKED` sits mid-enum and shifts the later ints; nothing stores them.
  - The locked-cell hover has no full stop, and no test pins it or the debug spinner.
- **Task 8:**
  - No test pins the grid-to-page centring (`test_nodes_sit_on_their_grid_cells` was dropped).
  - `NodeInfoPanel` grows with its content and has no clip.
- **Task 9:** the badge anchoring is repeated in `section_bar.gd` and `branch_tabs.gd`.
- **Task 10:**
  - `main_backdrop.gd` is about 600 lines; the gallery could be its own class.
  - The shared draw helpers live on a `Control`, and some tuning literals in the gallery's drawing are inline.
  - The motes move under Settings.
  - The gallery's stone shading shifts slightly with the window width.
- **Task 11:**
  - The Controls hint's dropped line is not lost: `GameSettings.ACTION_NAMES[&"toggle_stats"]` is "Stats panel (Ctrl: toggle, hold: more)", the label of its own row.
  - `_style_tab` casts a stylebox without a null check, and restyles four boxes per tab on every `show_tab`.
  - No test pins the "too big" resolution marks.
  - `settings_screen.gd` is 518 lines; `_draw_emblem` could live with the Journey panel's glow helpers.
- **Task 12:** Classic's and High Noon's Senna-gun bodies are lighter than the plan's hexes.
- **Task 13:** the title's effects keep redrawing under Settings; `title_backdrop.gd` is 509 lines; Lucian's rect is 21 px from the slot list (test-guarded).
- **Not from Phase 10's game code:** `test_monsters`'s raptor-spread test can fail under load.
- **Plan checklists:** the task checklists in this file are left unticked; the commits above are the record.
- **Tests:** the suite is **1604 tests, all passing** (24651 asserts, about 633 s), up from 1516 before the phase: 88 new. GUT's 2 warnings are the known unfreed children in `test_act4` and `test_lucian_skills`. There are no orphans and no leak lines at exit.

### Fixes from the final review
The whole-branch review found no critical or important issue. These were fixed:
- **`test_backpack_drag.gd`** leaked a tooltip card (3 nodes), the source of the 3 orphans and the exit leak lines. The test frees the card now and checks its text.
- **A hidden node** picked in the tree now shows "???" with no value, description, sum line or ladder. It keeps the requirement line.
- **`test_the_info_column_fits_its_panel_for_every_branch_and_node`** guards the info column's height, on a new save and on a max tree.
- **`test_level_sums_acts_and_values_match_max_level`** checks that `level_sums`, `level_acts` and `level_values` line up with `max_level`.
- **`TABS_RECT`** is built from `PAGE_RECT`, and `MINI_COLUMNS` is `BackpackScreen.COLUMNS`.
- **Test cleanups:** the `test_skins` muzzle comment says it checks the markers in `lucian.tscn`, and the incidental (0, 0) assertion is gone from `test_tree_data_files`.
- **Commits:** "Final review fixes: no tooltip leak in the backpack test, a hidden node shows nothing in the info column, fit and data guards", then this docs commit.

### Running the checks

```
godot_console --headless --path . --import
godot_console --headless --path . -s res://addons/gut/gut_cmdln.gd
godot --path . -s res://tests/tools/screenshot.gd -- <scenario> <output_dir>
```

Phase 10's scenarios: `tree_rules`, `backpack_slots`, `tree_free` and `title_settings`. Phase 10 also changed `main_tree`, `main_tree_max`, `tree_icons`, `main_journey`, `settings` and `art_sheet`. Run them in a window and keep the mouse off it. Run `--import` first: Phase 10 added 18 SVGs.

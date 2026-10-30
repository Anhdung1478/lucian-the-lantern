# Phase 10 report: Evolution Tree pages and new rules, backpack slots, new backgrounds, Settings and title art, and Senna's gun

**Date:** 2026-10-30 · **Branch:** `phase10` (commits from `60a905a` to this report, not pushed; `main` gets them by a fast-forward) · **Plan:** `docs/implementation/phase10.md`

## Summary

Your Phase 10 request had seven points, and the tree rules among them had six parts. All are built and checked:
- **The Evolution Tree** is five branch pages with tabs: Skills, Stats, Backpack, Economy and Summoners. Each page draws one branch large on an illustrated tree, with no panning. The info column on the right is always shown.
- **The tree's new rules:**
  - R's three ranks need the passive and 5, 9 and 13 levels in Q + W + E.
  - Equip slots 3–4 need Act 2 cleared, and slots 5–6 need Act 4.
  - The Equipment group is now **Backpack**.
  - Ghost is free after stage 1-1.
- **Backpack Slots:** a new game opens 5 backpack cells. Seven levels add +5, +6, +6, +7, +8, +8 and +9, up to 54.
- **A FREE badge** sits on the bottom bar's Evolution Tree button, and on the tabs and nodes, when an upgrade is free to take.
- **Health Regen and Mana Regen** are new stat nodes.
- **New backgrounds:**
  - a night grove behind the tree and the Journey;
  - a hall of relics behind the Skin Shop, with one lit arch per skin.
- **Settings** has a tab rail with icons, rows as cards, and gold-and-navy sliders, dropdowns, switches and scroll bars.
- **The title screen** shows Lucian and Senna on the left, facing Thresh on the right under the Shadow Isles moon, with cliffs, ruins, graves, mist, souls and a spectral chain.
- **Lucian's second gun is Senna's** on all five skins.

The test suite grew from **1516 to 1601 tests**, and all of them pass. Every new screen was checked in screenshots from a real game window. This last pass found no wrong state; the bugs found earlier in the phase are fixed (see *Verification*).

Your choices during planning:

| Topic | Your choice |
|---|---|
| Tree layout | **Branch pages with tabs.** Tabs along the bottom of the tree (Skills, Stats, Backpack, Economy, Summoners). Each page draws one branch large and centred on an illustrated tree, with no panning. The info panel stays on the right. Tabs with a free upgrade get a FREE badge. |
| Free Ghost | **Free to claim.** After 1-1, Ghost costs 0, and you click it in the tree. E keeps its automatic grant. |
| Menu art | **Backlit silhouettes.** Dark standing figures lit from behind by moonlight, with colour accents: Lucian's gold muzzle glint, Senna's teal light, Thresh's green lantern and chains. |
| Senna's gun | **All five skins.** Each skin's right-hand gun becomes that skin's own take on Senna's relic gun. |

## What you asked for → what was built

| # | Request | Built |
|---|---|---|
| 1 | A better Evolution Tree view (it was one wide strip to pan, with small nodes at the bottom and an empty screen above) | **Five branch pages** with tabs along the bottom (`main_screen.md`, Section 1, "Built in Phase 10"). Each page fills its frame with one branch: a glowing trunk, curved boughs, vines for the requirement links, and captions such as OFFENSE, DEFENSE and SUSTAIN. Nodes grow from 72 to 96 px, with their names under them. The info column is always shown: the branch's summary and node list, or the picked node with its levels and what it still needs. |
| 2 | Main screen: another background | **Grove at night** behind the tree and the Journey: a teal-to-indigo night sky, stars, mist bands, a vignette and drifting warm light motes. |
| 3 | Lucian's second gun is Senna's, so the two guns must look different | On all five bodies, the right-hand gun is that skin's take on **Senna's relic gun**: chunkier and darker, with a heavy stock, two glowing ring bands and a muzzle cap. His own gun stays slim (game design doc §10). |
| 4a | R rank 1 needs the passive and Q + W + E ≥ 5; rank 2 ≥ 9; rank 3 ≥ 13 | As asked. R wears a 13-segment ring on its page, lit up to the total. The info column reads "Q + W + E ranks: 7 / 9" and "Requires: 9 levels in Q + W + E (now 7)". |
| 4b | Equipment: slot 3 needs Act 2 and slot 5 Act 4; rename the group "Backpack" | Slots 3–4 need Act 2 and slots 5–6 need Act 4. The group, its tab and its page are **Backpack**. The page shows the six slots, with "Act 2" and "Act 4" under them. |
| 4c | A backpack-slots node: 5 cells at the start, and upgrades of +5, +6, +6, +7, +8, +8, +9 | **Backpack Slots**, 7 levels: 5 → 10 → 16 → 22 → 29 → 37 → 45 → 54 cells. The backpack is now 9 × 6 = 54 cells, and locked cells show a chain. |
| 4d | Ghost: free after stage 1 | After 1-1, Ghost costs 0 and you claim it in the tree. Act 1's result lists "Ghost is free to claim in the Evolution Tree". |
| 4e | A small FREE badge on the bottom Evolution Tree section for free upgrades not taken | A pulsing **FREE** pill on the bottom bar's Evolution Tree button. It also marks the branch's tab and the node. It goes once the upgrade is taken. |
| 4f | Stats: add HP and mana regen | **Health Regen** (+0.5/s a level) and **Mana Regen** (+0.6/s a level), 5 levels each, under SUSTAIN on the Stats page. |
| 5 | Skin Shop: a better background | **Hall of Relics:** a stone gallery with one arch behind each card. In each arch, a lantern, a light cone and a plinth glow in that skin's colour, and a polished floor mirrors them. |
| 6 | Settings: a less plain design | A lantern medallion header, a **tab rail with icons**, each setting on a **card** with a short description, and every control restyled in gold and navy, dropdown lists included (`ui_design.md` §5). |
| 7 | Main menu: Lucian and Senna on the left and Thresh on the right, to tell the story, plus more decoration | Three large backlit figures. Senna is a fading teal spirit behind Lucian, and Thresh looms with his lantern. Around them: the moon, Shadow Isles cliffs with Helia's ruins, dead trees, graves, drifting mist, souls rising from the lantern, teal motes around Senna, and a spectral chain from Thresh toward Senna (`ui_design.md` §7). |

### Under the request

| Part | Built |
|---|---|
| Per-level rules | `EvolutionTree.is_level_open(id, level)` checks the acts cleared, the requirements and a level sum. New `TreeNodeData` fields: `level_values`, `level_acts`, `level_sum_ids` and `level_sums`. `requirement_text` lists only what is still missing. |
| Free upgrades | `is_free`, `free_ids` and `has_free`: the next level is open and costs nothing. The badges refresh on `tree.changed` through a named method, so a freed main screen leaves no connection behind. |
| Backpack capacity | `Inventory.BACKPACK_SIZE` is 54 (9 × 6), plus `unlocked_backpack`. Adding items, the space checks and drops use only open cells. The shop refuses a locked cell ("That cell is locked"). A stage reads its open cells from the tree before its equip slots. The stage run on its own opens all 54, and the stage debug table has a "Backpack slots" spinner. |
| Regen nodes | `stat_hp_regen` and `stat_mana_regen` feed the existing `hp_regen` and `mana_regen` stat bonuses. The HUD's "+x/s" shows them. |
| Tree pages | `TreePage` (one per branch, drawn in code), `BranchTabs`, a 96 px `TreeNodeView` with a lock corner and a FREE badge, and `NodeInfoPanel` as a permanent column. `TreeMap` is deleted. The frame, text and glow helpers are shared with the Journey. |
| FREE badge | `FreeBadge`, a 48 × 20 pill that pulses only while it shows; `SectionBar.set_badge`. |
| Backgrounds | `MainBackdrop` (grove and gallery) and `TitleBackdrop`. Each scene is drawn once. Only the motes, mist and souls redraw every frame, and only while their screen shows. Sky, stars and motes are shared helpers. |
| Settings | `SettingsRow` (the card) and `UiStyle.theme()`. 12 new SVGs: 4 tab icons, 2 slider handles, the dropdown arrow and check, and 4 switches. |
| Title art | Three large SVG figures (`title_lucian`, `title_senna`, `title_thresh`) over `TitleBackdrop`. |
| Guns | The five body SVGs. The muzzle markers stay at (46, ±15), now pinned by a test. |

## Choices made where the request was open

Settled during planning (placeholders, easy to change):
- **Equip slots 4 and 6** need the same act as slots 3 and 5 (Act 2 and Act 4). The buying order makes that so anyway.
- **Backpack Slots' costs:** 50, 100 and 200 blue for the first three levels, then orange from level 4. There is no act rule.
- **Regen per level:** +0.5/s health and +0.6/s mana, on the stat cost table.
- **Ghost** needs Act 1 and costs 0, and is not given automatically (E still is).
- **Old saves keep their levels,** even above the new rules. Such a node shows as bought, with a lock, and its next level reads LOCKED. A reset refunds today's prices, so a Ghost bought for 150 blue gives back nothing.
- **The FREE badge** also shows on the tab and the node, not only on the bottom button. "Free" means the next level's rules are met and it costs nothing.
- **The two main-screen scenes, the title's list of decorations, and the Settings layout** are from the plan.

Settled while building (rulings that change what you see):
- **The grove has no moon or hills.** It shows only sky, stars, mist and motes around the tree page and the Journey map. Each tree page already draws its own moon and hills inside its frame, so a second moon would have shown.
- **Extras on the tree pages:**
  - each node's name on a plate under it;
  - the branch's node list in the info column, with clickable rows;
  - the per-level LEVELS ladder;
  - the moon and the side trees.

  They fill what would have been empty areas.
- **The tree opens on the first branch with a free upgrade,** each time the main screen opens.
- **Settings:**
  - The panel is opaque, because the title's logo showed through.
  - Volumes read as whole numbers.
  - The Controls hint lost one line (see *Known limits*).
- **A card's controls pass the mouse to the card,** so hovering a slider lights its card. As a side effect, the wheel scrolls the Controls list even over its buttons.
- **A gold diamond marks the chosen entry in dropdown lists** (`option_check.svg`, one SVG more than planned). Without it the lists kept Godot's grey radio circles.
- **Senna's gun colours:**
  - High Noon's rings are a hotter ember (`#ff6a2a`), so they don't blend with the bronze revolver.
  - The dark gun bodies were lightened, so they show on the floor.
  - On PROJECT and Vampire, both muzzle lights are the same colour family (cyan, crimson), as the ring colours asked. The guns still differ by body and rings.
- **Senna's fade on the title** uses alpha gradients, because Godot's SVG importer doesn't draw `<mask>`.
- **More arches, unlit, run on past the five cards** in the hall, to the screen's edges.
- **Requirement texts list only what is still missing.** For example, R at rank 1 doesn't repeat the passive.
- **An item stuck in a locked cell** can't be dragged out, only sold. This only happens when the debug spinner lowers the open cells with no room left.

## Verification

- **Unit and scene tests (GUT):** **1601 of 1601 pass** (24494 asserts, 627 s), up from 1516 before the phase: 85 new.
  - New test files: `test_settings_screen` (19 tests) and `test_main_backdrop` (6).
  - Extended: `test_evolution_tree`, `test_tree_data_files`, `test_inventory`, `test_shop`, `test_loot`, `test_backpack_drag`, `test_stage_setup`, `test_lucian_casting`, `test_game`, `test_save_game`, `test_act1`, `test_main_screen`, `test_main_debug`, `test_skins` and `test_title_screen`.
  - `test_tree_section` was largely rewritten for the pages. Every behaviour that still exists kept its test: states, badges, the info column, the cost bar, hover, reset, ESC and no file writes. The pan and zoom tests are gone.
- **Screenshot runs in a real window:** 14 scenarios, 64 PNGs. Four are new this phase (`tree_rules`, `backpack_slots`, `tree_free` and `title_settings`), and 10 earlier ones were re-shot. Every printed check matched. The ones that matter most:
  - **R at rank 1** with Q 3, W 3 and E 1: the ring lit to 7, "Q + W + E ranks: 7 / 9", "Requires: 9 levels in Q + W + E (now 7)", LOCKED, and a lock at R's corner.
  - **Equip Slots at level 1** after Act 1: "Requires: Clear Act 2" and LOCKED. With Act 2 cleared, slot 3 opens (300 blue) and its "Act 2" tag turns green. Slot 5 then asks for "Clear Act 4".
  - **A new save in Training:** 5 of 54 cells open and 49 chained. A sixth item doesn't fit, and walking onto loot reads "Backpack full". After two levels of Backpack Slots, the next stage has 16 open.
  - **After 1-1:** FREE on the Evolution Tree button, the Summoners tab and Ghost. A new save shows none, and all of them go once Ghost is claimed.
  - **Max tree:** all 34 nodes maxed, every page full and lit.
  - **Settings:** no grey default widget, dropdown lists included, from the title and in a stage.
  - **The two guns** differ on every skin at game zoom (`skins_stage`, `art_sheet_1_bodies`).
  - **The title figures** stay clear of the buttons and the slot list in the 1600 × 900 window. At 1920 × 1080, tests pin them left and right of the column.
- **Looking at the screenshots** found no wrong state this time. The fixes were in the harness only:
  - `main_journey` no longer buys Ghost on a new save, since Ghost needs Act 1 now.
  - The art sheet adds Phase 10's 15 new icons.
  - The Settings "listening" shot scrolls E's row into view.
- **Found and fixed during the tasks:**
  - The tree pages first copied the Journey's frame, text and glow code. They now share it (Task 8's review).
  - The info column's rows were freed late, which left orphans in the tests (Task 8).
  - A FREE badge shown on entering the tree didn't pulse (Task 9's review).
  - Hovering a Settings slider darkened its card instead of lighting it (Task 11).
  - The title screen showed through the Settings panel (Task 11).
  - High Noon's Senna rings matched the revolver's orange, and the dark gun bodies vanished on the floor (Task 12).
  - Senna's cloak was invisible on the title, because `<mask>` doesn't render, and she stood hidden behind Lucian (Task 13).

## Balance: the new numbers

**Nothing is measured yet.** No play times were measured this phase. Every number here is a placeholder from the plan.

| Rule | Number |
|---|---|
| R rank 1 / 2 / 3 | The passive, plus 5 / 9 / 13 levels in Q + W + E (15 at most) |
| Equip slots 3–4 / 5–6 | Act 2 / Act 4 cleared |
| Ghost | Free after 1-1 (was 150 blue) |
| Health Regen | +0.5/s a level, +2.5/s at level 5 |
| Mana Regen | +0.6/s a level, +3/s at level 5 |
| Regen costs | The stat table: 50 / 100 / 200 / 350 / 500 blue, plus 3 and 8 orange at levels 4 and 5 |

| Backpack Slots level | Open cells | Cost |
|---|---|---|
| 0 (start) | 5 | — |
| 1 | 10 | 50 blue |
| 2 | 16 | 100 blue |
| 3 | 22 | 200 blue |
| 4 | 29 | 350 blue + 3 orange |
| 5 | 37 | 500 blue + 8 orange |
| 6 | 45 | 800 blue + 15 orange |
| 7 | 54 | 1200 blue + 25 orange |

What they change:
- **R comes later.** Rank 3 needs 13 of the 15 Q, W and E ranks; before, it needed one rank of each.
- **Equip slots 3–6 wait for Acts 2 and 4.** The balance goal (4–5 equip slots in 5–7 hours) still fits.
- **Backpack Slots costs 3200 blue and 51 orange** in all: a new blue sink for the length target.
- **Watch the 5 starting cells in Acts 1–2.** You found Act 1 too hard before. The first two levels are cheap (50 and 100 blue) and potions stack 9 to a cell, but Act 1's first play has no blue to spend before it. If 5 cells feel tight, the start is one number: the first of `level_values` in `data/tree/backpack_slots.tres`.

## Screenshots

All PNGs are 1600 × 900 (the window). The motes, mist, souls and badge pulse move, so they differ a little between runs.

### The tree pages

| | |
|---|---|
| ![New save](phase10/main_tree_0_new_save.png) A new save: Skills, every node hidden, R's empty ring with its 5 / 9 / 13 marks, and no FREE badge anywhere | ![Stats picked](phase10/main_tree_1_bought_info.png) After Act 1 and some buys: Stats with OFFENSE, DEFENSE and SUSTAIN (where Health Regen and Mana Regen sit), and Attack Damage picked: "LVL 2 / 5", "+8 AD → +12 AD", its LEVELS ladder and the cost bar |
| ![Hover](phase10/main_tree_3_hover.png) Q hovered: its card reads "Q – Piercing Light / Rank 2". The vines are gold once the passive is bought | ![Stats tab](phase10/main_tree_4_stats.png) The Stats tab with nothing picked: the branch summary, "Levels bought 3 / 45" and the node list by caption |
| ![Backpack](phase10/main_tree_4_backpack.png) The Backpack page: the equip strip (2 of 6 open, locks, "Act 2" and "Act 4") and the 9 × 6 mini backpack, 5 of 54 lit and the next 5 outlined | ![Economy](phase10/main_tree_4_economy.png) Economy: REWARDS and MERCHANT |
| ![Summoners](phase10/main_tree_4_summoners.png) Summoners: Flash bought, Ghost with its FREE badge, Flash Upgrade open, the other upgrades and the Second Summoner Slot hidden | ![Skills tab](phase10/main_tree_4_skills.png) The Skills tab after the buys: Q 2, W 1, E 1 and the passive. R's ring is lit to 4, under its 5 mark |

### The new rules

| | |
|---|---|
| ![R needs 9](phase10/tree_rules_0_r_needs_9.png) R at rank 1 with Q 3, W 3 and E 1: the ring lit to 7, the lock at R's corner, "Q + W + E ranks: 7 / 9", "Requires: 9 levels in Q + W + E (now 7)", and LOCKED | ![Equip needs Act 2](phase10/tree_rules_1_equip_needs_act_2.png) Equip Slots at level 1 after Act 1: "Requires: Clear Act 2", LOCKED, and the lock at its corner |
| ![Act 2 cleared](phase10/tree_rules_2_act_2_cleared.png) Act 2 cleared: the "Act 2" tag turns green, slot 3 is outlined as next, and the cost bar reads 7800 / 300 | ![R hidden](phase10/main_tree_2_hidden_info.png) R before it opens (Q + W + E at 4): "Requires: 5 levels in Q + W + E (now 4)". The description and ladder showing here is a known limit |

### FREE badges

| | |
|---|---|
| ![Button](phase10/tree_free_0_button.png) After 1-1, from the Skin Shop: FREE on the bottom bar's Evolution Tree button | ![Summoners](phase10/tree_free_1_summoners.png) The Summoners page: FREE on Ghost and on the Summoners tab |
| ![Skills](phase10/tree_free_2_skills.png) The Skills page: E at 1 / 5 (given by Act 1), and the Summoners tab still badged | ![Claimed](phase10/tree_free_3_claimed.png) Ghost claimed: 1 / 1, Ghost Upgrade open, and every badge gone |

### Max tree (debug)

| | |
|---|---|
| ![Skills](phase10/main_tree_max_0_skills.png) Skills, every vine gold and R's ring full | ![Stats](phase10/main_tree_max_1_stats.png) Stats, 45 / 45 |
| ![Backpack](phase10/main_tree_max_2_backpack.png) Backpack: 6 of 6 slots and 54 of 54 cells. The act tags stay dim, because Max tree skips the act rules | ![Economy](phase10/main_tree_max_3_economy.png) Economy |
| ![Summoners](phase10/main_tree_max_4_summoners.png) Summoners, the six vines of the Second Summoner Slot lit along the trunk | ![Picked](phase10/main_tree_max_5_summoners_picked.png) Heal Upgrade picked: "+45% healing", its three levels, MAXED |

### The backpack

| | |
|---|---|
| ![5 open](phase10/backpack_slots_0_five_open.png) A new save in Training: the 9 × 6 backpack with 5 cells open and full, 49 chained, and the equip row with slot 1 open | ![Hover](phase10/backpack_slots_1_locked_hover.png) A chained cell hovered: "Buy Backpack Slots in the Evolution Tree" |
| ![Full](phase10/backpack_slots_2_full.png) Walking onto a Negatron Cloak with the 5 cells full: "Backpack full", and it stays on the ground | ![16 open](phase10/backpack_slots_3_sixteen_open.png) Backpack Slots at level 2: 16 cells open in the next stage |

### The backgrounds

| | |
|---|---|
| ![Hall](phase10/main_skins_0_zero.png) The Hall of Relics: an arch, a lantern, a light cone and a plinth in each skin's colour, and the polished floor | ![Vampire](phase10/main_skins_1_vampire.png) Vampire bought and equipped, with its crimson arch |
| ![Journey new](phase10/journey_map_0_new_save.png) The grove around the Journey's map on a new save: the starry margins and the top bar | ![Mid game](phase10/journey_map_1_mid_game.png) Acts cleared = 3: FREE on the Evolution Tree button (Ghost, after 1-1) |
| ![Boss picked](phase10/journey_map_2_boss_picked.png) 3-5 picked, unchanged | ![Hover fogged](phase10/journey_map_3_hover_fogged.png) "Clear Act 4 first", unchanged |
| ![All cleared](phase10/journey_map_4_all_cleared.png) Every act cleared, Training picked | |

### Settings

| | |
|---|---|
| ![Audio](phase10/settings_0_audio.png) In a stage, from the ESC menu: the lantern header, the tab rail, the Audio cards with gold sliders and whole numbers | ![Listening](phase10/settings_1_listening.png) Controls: Skill Q waiting for a key, lit gold "Press a key..." |
| ![Rebound](phase10/settings_2_controls.png) Q bound to Z, then W bound to Z: the two swap (Q on W, W on Z), and the HUD follows | ![Graphics](phase10/settings_3_graphics.png) Graphics: gold dropdowns and switches, with the old notes as descriptions |
| ![Dropdown](phase10/settings_3_graphics_dropdown.png) The Resolution list: navy, the chosen size with a gold diamond, "too big" sizes greyed | ![Gameplay](phase10/settings_4_gameplay.png) Gameplay: Skill queue |
| ![HUD keys](phase10/settings_5_hud_keys.png) Back in the stage: the HUD keys follow the new bindings | ![Title audio](phase10/title_settings_0_audio.png) From the title: the panel is opaque over the figures |
| ![Title controls](phase10/title_settings_1_controls.png) Controls: MOVE AND ATTACK, SKILLS, and Reset to defaults beside the title | ![Title graphics](phase10/title_settings_2_graphics.png) Graphics |
| ![Title gameplay](phase10/title_settings_3_gameplay.png) Gameplay | ![Hover](phase10/title_settings_4_hover.png) The Music card hovered: its border and slider brighten |
| ![FPS list](phase10/title_settings_5_dropdown.png) The FPS cap list open, an entry lit gold | ![Listening E](phase10/title_settings_6_listening.png) Skill E waiting for a key |
| ![Controls end](phase10/title_settings_7_controls_end.png) The end of the Controls list: INTERFACE, and the thin gold scroll bar | |

### The title screen

| | |
|---|---|
| ![Title](phase10/title_0_menu.png) Lucian and Senna face Thresh under the moon: the ruins on the cliff, the graves, the mist, the souls rising from the lantern and the chain on the ground | ![Load hover](phase10/title_1_load_disabled.png) Load game hovered: "No saved games yet" |
| ![Slots](phase10/title_slots_0_new_game.png) Start new game's 520 px slot list, clear of Lucian and Thresh | ![Overwrite](phase10/title_slots_1_overwrite.png) "Overwrite slot 2?" dims the scene |
| ![Load](phase10/title_slots_2_load.png) Load game: only slot 2 can be picked | |

### Senna's gun

| | |
|---|---|
| ![Bodies](phase10/art_sheet_1_bodies.png) The five bodies at 2× and at game size: Lucian's slim gun on top, Senna's chunky gun with two ring bands below | ![Classic](phase10/skins_stage_0_classic.png) Classic in Training at zoom 1.6: silver-gold and teal |
| ![High Noon](phase10/skins_stage_1_high_noon.png) High Noon: the bronze revolver and ember rings | ![PROJECT](phase10/skins_stage_2_project.png) PROJECT: chrome and a boxy gun with cyan rings; MS 397 |
| ![Pulsefire](phase10/skins_stage_3_pulsefire.png) Pulsefire: white, and blue with a core | ![Vampire](phase10/skins_stage_4_vampire.png) Vampire: silver with a red gem, and black iron with crimson rings |
| ![Art sheet](phase10/art_sheet_0.png) 51 icons at 64 and 32 px: the regen and Backpack Slots nodes, the four Settings tab icons, the slider handles, the dropdown arrow and check, and the switches | |

### The tree's icons (re-shot)

| | |
|---|---|
| ![Skills](phase10/tree_icons_0_skills.png) Max tree: the skill nodes use the HUD's icons | ![Summoners](phase10/tree_icons_1_summoners.png) The six spells and their upgrades |
| ![Picked](phase10/tree_icons_2_picked.png) Heal Upgrade picked | ![HUD](phase10/tree_icons_3_hud.png) Training after Max tree: Flash and Heal, and "+3.3/s" and "+5.8/s" on the bars, with the regen nodes maxed |

## Known limits

- **A hidden node says too much when picked.** R before it opens reads "???", but still shows its description, "None → Rank 1" and the LEVELS ladder with its costs. The leak is older; the ladder adds to it.
- **The info column can grow too tall.** It has no scroll or clip. The Summoners list (13 rows) nearly fills it.
- **Some scenes keep moving under Settings:** the main screen's motes, and the title's mist and souls. The cost is small.
- **The Controls hint lost a line:** "Ctrl + the stats key toggles the stats panel (hold it for more)". The binding's own name still says "Stats panel (Ctrl: toggle, hold: more)".
- **An item stuck in a locked backpack cell** can't be dragged out, only sold. This only happens when the debug spinner lowers the open cells with no room left.
- **The "Buy Backpack Slots" hover** shows only on locked backpack cells, not on locked equip slots.
- **Max tree (debug) leaves the "Act 2" and "Act 4" tags dim,** because it skips the act rules.
- **The sounds were never heard,** including Phase 9's 11. Phase 10 adds none.
- **Wider screens:** the title keeps its figures at the edges, and the hall adds arches. The tree and the Journey keep fixed positions, so extra width stays empty on the right (as in Phase 9).
- **Tests:** every test passes, with notes:
  - GUT's 2 warnings are test scripts that leave a node or two unfreed (`test_act4`, `test_lucian_skills`).
  - `test_backpack_drag.gd`'s locked-cell tests leave 3 orphans, and Godot prints leak lines at exit.
  - `test_monsters`'s raptor-spread test waits on wall-clock time and can fail under load; it passes on a re-run.
  - The full suite takes about 10 minutes.

## Manual playtest checklist (for you)

Your save and settings live in `%APPDATA%\lucian_the_lantern\`. F3 + Q opens the debug tables: on the main screen, Acts cleared, essences and Max tree; in a stage, God mode, the Waves tab, Level +1 and the new "Backpack slots" spinner.

1. **On a new save, clear 1-1.** On the main screen, FREE shows on the Evolution Tree button. The tree opens on Summoners, with FREE on its tab and on Ghost. Claim Ghost (it reads Free), and every badge goes. Then on the Journey, put Ghost on D.
2. **Buy Q, W and E up to 5 levels in all** (E already has 1; for example Q 2 and W 2), and the passive. R opens. Buy it (600 blue and 10 orange; the main screen's debug table can add essences): its next rank reads "Requires: 9 levels in Q + W + E (now 5)", and R's ring fills as you buy.
3. **In a stage, fill the 5 backpack cells** from the merchant or from loot. Loot then stays on the ground with "Backpack full". Buy Backpack Slots in the tree (50 blue), and check that the next stage has 10 cells open. *Note how tight 5 cells feel in Acts 1–2.*
4. **Equip Slots:** after buying slot 2, the next level reads LOCKED and "Requires: Clear Act 2", and the Backpack page shows the lock. It opens once Act 2 is cleared.
5. **Health Regen and Mana Regen:** buy a level of each, and check the "+x/s" on the HUD's health and mana bars in a stage. Lucian's own regen is 0.8/s and 2.8/s at level 1.
6. **Use Settings from the title, the main screen (gear) and a stage (ESC).** Check each tab, a dropdown list, a switch and a rebind.
7. **The title screen** at your usual window size: the figures don't crowd the buttons or the slot list.
8. **Each skin in Training:** the two guns look different.

## Feedback and suggestions

- **Play Acts 1–2 on a new save first,** and watch the 5 cells. If they feel tight, start at 10, or make level 1 cheaper (`level_values` and `blue` in `data/tree/backpack_slots.tres`).
- **R's 5 / 9 / 13 push R later.** If it comes too late to feel good, 4 / 8 / 12 is one line (`level_sums` in `data/tree/skill_r.tres`).
- **The Economy and Backpack pages** have open sky in their middle, where the scene shows. If you want them fuller, their nodes can spread or grow.
- **Small decisions that are yours:**
  - the FREE badge on tabs and nodes too (you asked for the bottom button);
  - the tree opening on the first branch with a free upgrade.
- **Music** is still missing, and every sound is a generated placeholder.

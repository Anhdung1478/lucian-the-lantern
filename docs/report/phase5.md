# Phase 5 report: main screen, save system, Evolution Tree, Skin Shop and Journey

**Date:** 2026-10-28 · **Branch:** `main` (commits from `8c04b30` to this report, not pushed) · **Plan:** `docs/implementation/phase5.md`

## Summary

All 9 points on your Phase 5 list are built and checked:
- the game opens on a main screen with three sections: Journey, Evolution Tree, Skin Shop
- a save system with 3 slots and backups (slot 1 for now)
- the act, Training and Endless choosers in Journey; only Training starts for now
- a working Evolution Tree (31 nodes) and Skin Shop (5 skins), and Training is built from them
- an F3 + Q debug table on the main screen that adds blue, orange and purple essence
- new art: the three essence icons and 31 tree node icons (plus a gear, a skull and 4 skins)

The test suite grew from **413 to 579 tests**, and all of them pass. Every new screen was checked in screenshots from a real game window. That visual pass fixed four things (see *Visual pass*). A separate reviewer read each task; one task (the Skin Shop) needed a round of fixes.

Your choices during planning:
- **Essences:** blue, orange and purple, as the docs say ("green" was a typo).
- **Picking D/F spells:** a loadout panel in Journey. It lists only bought spells; F is chained until the 2nd slot is bought; picking the spell already on the other key swaps them; the choice is saved.
- **Skin art:** 5 card portraits (Classic reuses its portrait). In a stage, Lucian's body and HUD portrait follow the skin.
- **Tree icons:** new art for every node, even where a skill, stat or spell icon already existed.
- **Spell nodes:** an unlock node per spell, an upgrade node (3 levels) above each, and the 2nd slot node.
- **Training:** the tree decides. A new save starts with no skill ranks, no passive, 1 equip slot, 2 shop items and no spells. `stage.tscn` run on its own stays the Phase 4 sandbox.

## What you asked for → what was built

| # | Request | Built |
|---|---|---|
| 1 | Add the main screen; starting the game opens it | `src/main/game.tscn` is the new main scene. It opens on **Journey → Training**: essences and the gear button top-left, **Evolution Tree · Skin Shop · Journey** at the bottom. Start Training swaps in the stage; ESC → Leave this stage saves and comes back. |
| 2 | Every main screen feature (`main_screen.md`) | Journey, Evolution Tree and Skin Shop (below), plus the gear menu: Close, Save, Save as copy, Settings, Leave to main menu (disabled until a title screen exists) and Exit the game. ESC closes what is open, else opens the gear menu. |
| 3 | The save system | 3 slots (`save_slot_N.json`, each with a backup), slot 1 for now. The game saves **only when a stage is done**, on **Save**, and on a **Yes** to "Save before leaving?" (Exit, or closing the window). Main screen purchases never save by themselves. A broken file loads its backup. |
| 4 | Design the act, Endless and Training choosers; only Training works | Tabs **Act 1–6 · Training · Endless**. An act shows its name, its story and a card per stage (waves, a grey skull for a mini boss, a red one for the boss, a chain while locked, a green check once cleared). Endless shows the rules, a map choice and the best wave, and opens after **Act 3**. Only **Start Training** works; the other Start buttons say they come in a later phase. |
| 5 | The Evolution Tree and Skin Shop work | **Tree:** 31 nodes in one forest, five groves, dragged and zoomed. Nodes show hidden / affordable / too expensive / bought / maxed. Clicking one opens a panel with its value now → next and a cost bar that buys it. Reset tree costs 5 purple and refunds everything. **Skin Shop:** 5 cards; buy with purple, then equip. Training uses both. |
| 6 | A debug table on the main screen, F3 + Q, hidden by default | Two tabs: **Essences** and **Progress** (acts cleared 0–6, Max tree, Clear tree, Reset progress). Nothing in it saves. |
| 7 | The debug table adds blue, orange and purple | Blue +100 / +1000 / +10000, orange and purple +1 / +10 / +100, and a Reset for each. |
| 8 | Essence icons | Blue: a tall crystal shard. Orange: two crossed shards with an ember core. Purple: a cut gem with a crown of three points and a sparkle. They read at 24 px and are used in the top bar, the cost bar, Reset tree and the skin buttons. |
| 9 | Icons for every tree node | 31 new icons on a dark green-to-navy background with gold trim, one idea each (sheet below). |

### Evolution Tree (placeholder numbers)

Costs are in the game design doc §11; where each node sits is in `main_screen.md`.

| Node | Levels | Each level gives |
|---|---|---|
| Q, W, E | 5 | One rank to learn in a stage. E's first level is free and appears once Act 1 is cleared. |
| R | 3 | One rank |
| Passive | 1 | Lightslinger works |
| AD / AP / Health / Armor / MR / Attack Speed / Mana | 5 | +4 / +8 / +40 / +4 / +4 / +3% / +40, as bonus stats (yellow) |
| Equip Slots | 5 | One more equip slot (1 → 6) |
| Merchant Stock | 2 | One more shop item (2 → 4) |
| Cheaper Refresh | 2 | −25 gold per refresh (100 → 50) |
| Stage Gold, Bonus XP, Essence Drops | 3 | +10%. Saved, but nothing changes until enemies give gold, XP or essences |
| Flash, Ghost, Barrier, Heal, Clarity, Smite | 1 | The spell can go on D or F |
| Spell upgrades | 3 | Flash, Ghost: −10% cooldown. Barrier, Heal, Clarity, Smite: +15% shield, healing, mana or damage |
| Second Summoner Slot | 1 | Opens F (needs 2 spells) |

### Skins in a stage

Checked in the `skins_stage` run, at level 1 with nothing bought (Classic: 60 AD, 0.65 attack speed, 335 move speed, 600 HP).

| Skin | Cost (purple) | Lucian in Training |
|---|---|---|
| Classic | Free | 60 AD, 0.65 AS, 335 MS, 600 HP |
| High Noon | 25 | 69 AD, 0.5525 AS |
| PROJECT | 30 | 54 AD, 0.78 AS, 385.25 MS |
| Pulsefire | 20 | 0.585 AS, 15 ability haste (and +15% AP) |
| Vampire | 25 | 480 HP, 15% life steal; kills heal 2% max HP |

## Choices made where the request was open

Settled during planning (placeholders, easy to change):
- **Startup:** the game loads slot 1, or starts a new game without writing anything until the first save. It opens on Journey → Training.
- **New game:** 0 essences, nothing bought, Classic owned and equipped, D and F empty, nothing cleared.
- **Tree nodes have levels** (Q, W, E, R, equip slots and merchant stock are one node each), and the doc's cost tables map onto the levels. A tree reset takes back E's free first level too; it is free again.
- **Numbers the doc left open:** the stat amounts per level, Cheaper Refresh (200B, then 500B + 5O, −25 gold each), and the spell upgrades (−10% cooldown or +15% per level).
- **Skins:** attack speed and move speed add like items; AD, AP and max HP percentages multiply the final stats. Buying doesn't equip and has no confirm step; a Purchase button you can't afford is disabled with its price in red.
- **Gear menu:** Leave to main menu is disabled ("The title screen comes later"). Save as copy lists slots 1–3, asks "Overwrite slot N?" for a used slot, and keeps slot 1 as the current one. A toast confirms each save.
- **Leaving:** "Save before leaving?" (Yes / No) for Exit the game (gear menu or ESC menu) and for closing the window. Leave this stage saves and returns to the main screen.
- **Endless opens after Act 3**, as `main_screen.md` says; the design doc's "after beating Thresh" is corrected.

Settled while building:
- **Tree layout:** the passive sits half a row higher, the six spell upgrades two rows above their spells, and the 2nd slot node a quarter row up, so no line crosses a node or its badge.
- **The map's right end** can be dragged out from under the info panel, so the last spells are never hidden behind it.
- **A node with a level is never shown as hidden.** This only matters after the debug Max tree, which skips requirements.
- **The Smite upgrade** raises its damage, not its heal.
- **Mini boss stages** read "4 waves + mini boss wave"; a second click on a D/F key closes its spell menu.
- **A spell you no longer own** (after a tree reset) shows as empty in the loadout; your pick is kept for when you buy it again.

## Verification

- **Unit and scene tests (GUT):** **579 of 579 pass**, up from 413 at the plan commit.
  - New test files: `test_essences`, `test_save_game`, `test_evolution_tree`, `test_tree_data_files`, `test_journey`, `test_skins`, `test_stage_setup`, `test_game`, `test_main_screen`, `test_journey_section`, `test_tree_section`, `test_skin_shop`, `test_main_debug`.
  - New cases were added to `test_summoner_spells`, `test_lucian_casting`, `test_shop` and `test_skill_slot`. No line of an older test was changed, so `stage.tscn` on its own still behaves as in Phase 4.
- **Screenshot runs in a real window:**
  - New scenarios: `art_sheet`, `main_journey`, `main_acts`, `main_endless`, `main_tree`, `main_tree_max`, `main_skins`, `main_gear`, `main_debug`, `training_setup`, `skins_stage`. Each prints its expected and actual values, and every check matched.
  - They start the real game, so they also cover Start Training, Leave this stage (back on Journey, save file written) and "Save before leaving?".
  - `main_tree` drags the map with the mouse held down on top of a node, through the real window's input: the map moves 240 px and no node gets chosen. A plain click on a node still chooses it.
  - Earlier stage scenarios rerun: `hud`, `summoners`, `gold`.
- <a id="visual-pass"></a>**Visual pass:** looking at every screenshot found four problems. All are fixed, with a test each:
  - **Journey opened on Act 1**, not on Training as planned.
  - **The chain on a locked tab touched its name** ("Endless" most of all). The name now starts right of the chain.
  - **Nodes showed through the node info panel.** The panel is now opaque.
  - **The "Saved to slot 1" toast sat on top of the Journey tabs**, which made both hard to read. It now shows inside the top bar.
- **Review:** a separate reviewer read each task. The Skin Shop review found 2 important problems:
  - The Purchase buttons didn't follow essence that changed on its own (for example from the debug table).
  - Its test hid that by sending the save's change signal by hand.

  Both are fixed. The smaller findings, left as they are for now, are listed at the end of the plan (*Left as is*).

### Visual pass, before and after

| | |
|---|---|
| ![Tab chain](phase5/fix_1_tab_chain.png) Locked tabs: the name clears the chain | ![Info panel](phase5/fix_2_info_panel.png) The node info panel, now opaque |
| ![Toast](phase5/fix_3_toast.png) The toast, now in the top bar (and Journey opens on Training) | |

### Screenshots

| | |
|---|---|
| ![Journey](phase5/main_journey_0_training.png) The game opens here: Journey → Training on a new save, D empty, F chained, Acts 2–6 and Endless locked | ![Spell menu](phase5/main_journey_1_spell_menu.png) Four spells and the 2nd slot bought: F's menu lists them, Heal (already on F) lit |
| ![Act 3](phase5/main_acts_1_act3.png) Debug acts cleared 2: Act 3 with a grey skull on stages 2 and 4, a red one on 5, stages 2–5 chained | ![Act 2 cleared](phase5/main_acts_2_act2_cleared.png) Act 2 cleared: green checks |
| ![Endless locked](phase5/main_endless_0_locked.png) Endless locked: "Clear Act 3 first" | ![Endless](phase5/main_endless_1_open.png) Endless after Act 3: rules, map choice, best wave, Start for a later phase |
| ![Tree new](phase5/main_tree_0_new_save.png) A new save: Q, W and the stats in red (too expensive); the passive, E and R hidden | ![Tree bought](phase5/main_tree_1_bought_info.png) After some buys: lit frames and gold lines; Attack Damage chosen, "+8 AD → +12 AD" and the cost bar |
| ![Hidden node](phase5/main_tree_2_hidden_info.png) R chosen while hidden: "???", what it requires, LOCKED | ![Hover](phase5/main_tree_3_hover.png) Hovering Q: its name and rank |
| ![Zoom 0.6](phase5/main_tree_4_zoom_06.png) Zoomed out to 0.6: Skills to Economy | ![Max tree left](phase5/main_tree_max_0_left.png) Debug Max tree at 0.6: every node green, every line gold |
| ![Max tree right](phase5/main_tree_max_1_right.png) Max tree, the right end: Economy and Summoners | ![Summoners](phase5/main_tree_max_2_summoners.png) The Summoners grove at zoom 1, Heal Upgrade maxed |
| ![Skins](phase5/main_skins_0_zero.png) Skin Shop with 0 purple: prices in red | ![Vampire](phase5/main_skins_1_vampire.png) 100 purple: Vampire bought and equipped (75 left), Classic shows Equip |
| ![Gear menu](phase5/main_gear_0_menu.png) The gear menu; Leave to main menu disabled, with its hover note | ![Toast](phase5/main_gear_1_toast.png) Save: "Saved to slot 1" |
| ![Slots](phase5/main_gear_2_slots.png) Save as copy after copying to slot 2: its date and time | ![Overwrite](phase5/main_gear_3_overwrite.png) Slot 2 is used: "Overwrite slot 2?" |
| ![Save prompt](phase5/main_gear_4_save_prompt.png) Exit the game: "Save before leaving?" | ![Debug essences](phase5/main_debug_0_essences.png) F3 + Q: the Essences tab |
| ![Debug progress](phase5/main_debug_1_progress.png) The Progress tab | ![Art sheet](phase5/art_sheet_0.png) The new icons at 64 and 32 px |
| ![Training new](phase5/training_setup_0_new_save.png) Start Training on a new save: every rank locked, the passive grey with a lock, D empty, F chained, 1 equip slot | ![F card](phase5/training_setup_2_f_chained.png) F's card: "Locked: buy the 2nd summoner slot in the Evolution Tree." |
| ![Stage debug](phase5/training_setup_3_debug_table.png) The stage debug table: D and F "None", Buy all ranks | ![Max tree stage](phase5/training_setup_4_max_tree.png) Training after Max tree: ranks open, stats in yellow, Flash and Heal, 6 equip slots |
| ![Upgrade card](phase5/training_setup_5_upgrade_card.png) Heal's card: "Upgraded: 45% stronger" | ![Refresh](phase5/training_setup_6_shop_refresh.png) The merchant after Max tree: 4 items, "Refresh 50" |
| ![PROJECT](phase5/skins_stage_2_project.png) PROJECT in Training: body, portrait, 54 AD, 0.78 AS, 385 MS | ![Vampire stage](phase5/skins_stage_4_vampire.png) Vampire: body, portrait, 480 HP, 15% life steal (holding C) |

## Known limits

- **Only Training starts.** Acts and Endless are shown and unlock as designed, but there are no waves or killable enemies yet, so nothing in play earns essences: the debug table is the only source for now.
- **Stage Gold, Bonus XP and Essence Drops** can be bought but change nothing until enemies drop gold, XP or essences.
- **Vampire's kill heal** only shows in the tests: training dummies never die.
- **Slot 1 only.** There is no title screen or slot selection yet, so Leave to main menu stays disabled. Save as copy writes the other slots, but nothing loads them yet.
- **First-time boss purple** isn't tracked yet (no bosses).
- **The main debug table** covers the essences in the top-left while it is open.
- **One older test file** (`test_lucian_skills`, unchanged this phase) still leaves 4 shot nodes behind; GUT warns about it and every test passes.

## Manual playtest checklist (for you)

Your save and settings live in `%APPDATA%\lucian_the_lantern\`. To start from a new game, delete `save_slot_1.json` and `save_slot_1_backup.json` there first.

1. Launch the game: it opens on Journey → Training, and no save file is created yet.
2. F3 + Q opens the main debug table; add essences; F3 + Q hides it.
3. Evolution Tree:
   - Drag to pan and use the wheel to zoom. **Also start a drag with the mouse pressed on top of a node:** the map should pan, and the node shouldn't get chosen.
   - Buy Q twice: its frame goes from red to gold to lit. The lines to the passive turn gold once the passive is bought.
   - Hidden nodes show "?".
   - Max a node and it turns green.
   - Reset tree for 5 purple: everything spent comes back.
4. Skin Shop: buy and equip PROJECT; Classic then shows Equip.
5. Journey:
   - Acts 2–6 and Endless are chained.
   - Debug Acts cleared 3 opens Acts 2–4 and Endless.
   - The stage cards show skulls.
   - Start is disabled everywhere but Training.
6. Loadout: buy Flash, Heal and the 2nd slot; put Flash on D and Heal on F; then pick Heal on D and check they swap.
7. Start Training:
   - Only bought ranks have a "+" without a lock.
   - The passive is locked until bought.
   - The equip slots match the tree.
   - D and F match the loadout.
   - The skin's body and portrait show.
   - The tree's stats show in yellow.
8. ESC → Leave this stage: you're back on Journey, and a save file now exists with everything bought.
9. Buy something more on the main screen, then Exit the game → "Save before leaving?" → No. After relaunching, that purchase is gone.
10. Gear → Save → the toast. Save as copy → slot 2, then again → "Overwrite slot 2?".
11. Close the window with X during Training: the prompt shows, and Yes saves.
12. Break `save_slot_1.json` by hand: the game loads the backup.

## Feedback and suggestions

- **Waves and killable enemies are now the biggest gap.** They would make essences drop, the economy nodes work, Vampire's kill heal show and the acts startable.
- **The numbers are placeholders.** Node costs and amounts (spell upgrades included) are in `data/tree/*.tres`, and skin effects in `data/skins/*.tres`.
- **The title screen and slot selection** are the next missing screens. Leave to main menu and loading slots 2 and 3 wait for them.

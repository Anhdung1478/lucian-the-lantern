# Phase 9 report: Endless mode, the world-map Journey, Cancel on every exit, and sounds

**Date:** 2026-10-30 · **Branch:** `phase9`, in the worktree `lucian-the-latern-phase9` (commits from `1b04898` to this report, not pushed; `main` gets them by a fast-forward) · **Plan:** `docs/implementation/phase9.md`

## Summary

Your Phase 9 request had seven points. All are built and checked:
- **Endless mode** plays. Waves never end, with a mini boss every 5 waves, a boss every 10, a modifier to pick after each boss, and a best wave that is saved.
- **Mana regen ×1.75:** 2.8/s at level 1 (was 1.6), about 6.97/s at level 18.
- **A level-up sound,** with a gold burst, and **10 more sounds**: rank-up, Q, W and E, the wave horn, the boss gong, victory, defeat, button clicks and essences.
- **The Evolution Tree's skill and spell icons** are now the stage's own.
- **The Journey is a world map:** six act regions on one winding road through all 22 stages, Training and the Endless portal as landmarks, and a side panel for the picked place.
- **Lucian's base move speed** is 345 (was 335).
- **Every exit has a Cancel.** "Save before leaving?" is Yes / No / Cancel, and Leave this stage and the title's Exit game now ask first.

The test suite grew from **1342 to 1512 tests**, and all of them pass. Every new screen was checked in screenshots from a real game window. Looking at them found one wrong state, which is fixed (see *Verification*).

Your choices during planning:

| Topic | Your choice |
|---|---|
| Endless roster | **All acts mixed.** Any normal or elite from any act can come on any map. The map changes only the terrain. |
| Endless difficulty | **The same ramp on every map.** Wave 1 is as easy as Act 1. Strength grows every wave and passes Act 6's late waves around wave 35. |
| Journey overview | **A world map.** One painted map: six act regions, a winding road through all 22 stage nodes, and Training and Endless as landmarks. A side panel shows the picked node and its Start. |
| Cancel | Every "Save before leaving?" becomes **Yes / No / Cancel** (ESC = Cancel). **New prompts:** "Leave this stage" asks **Leave / Cancel**, and the title screen's Exit game and window X ask **Exit / Cancel**. |

## What you asked for → what was built

| # | Request | Built |
|---|---|---|
| 1 | Design and implement Endless mode | **Endless** (game design doc §14, "Built in Phase 9"). Start it from the Journey's portal once Act 3 is cleared, on one of six maps or Random. Generated waves from every act's enemies, a strength ramp by wave, a boss alone every 10th wave and a mini boss closing every other 5th, repeat purple on every boss kill, 5 modifiers plus Nothing to pick after each boss, the best wave on the HUD and in the save, and a **RUN OVER** end screen with Retry and Main screen. |
| 2 | Mana regen ×1.75 of the base | The base and the per-level growth: 8.0 → **14.0** and 0.7 → **1.225** per 5 s. Item and Blue-buff regen are not scaled. |
| 3 | A level-up sound, and other missing sounds | `level_up` (a rising chime) with a **gold ring and "Level 7"** over Lucian, and `rank_up`, `cast_q`, `cast_w`, `cast_e`, `wave`, `boss`, `victory`, `defeat`, `click`, `essence`. All 24 sounds are listed in `ui_design.md` §8. |
| 4 | Evolution Tree skill and summoner icons the same as in the stage | The 11 skill and spell nodes use the HUD's art. The six spell upgrades are redrawn from their spell's art with three gold chevrons. |
| 5 | A better Journey overview | **A world map** drawn in code: regions, the road, medallions (bosses and mini bosses show their art), fog and chains on locked acts, Lucian's token on the next stage, Training and the Endless portal. The side panel shows the stage's boss, purple, waves, story and enemies, or Endless's rules and a thumbnail of the chosen map (`main_screen.md`). |
| 6 | Lucian's base move speed +10 | **345.** |
| 7 | A Cancel on every exit | **Yes / No / Cancel** on "Save before leaving?" (gear menu, ESC menu, window X). **Leave / Cancel** on Leave this stage ("Leave this run? Your best wave is kept." in Endless). **Exit / Cancel** on the title's Exit game and window X. ESC is Cancel on all of them. |

### Under the request

| Part | Built |
|---|---|
| Endless waves | `EndlessPlan` (pure): min(8 + w, 30) normal enemies of 2 kinds, min(w / 4, 4) elites, a mini boss last in waves 5, 15, 25…, a boss alone in waves 10, 20, 30…, never the same boss or mini boss twice in a row. 12 normal, 11 elite, 6 mini boss and 5 boss ids (no Act 1 Thresh). |
| Endless runner | `EndlessRunner` makes each wave as it starts and never ends. After a boss wave it holds the break until the pick. |
| Endless in the stage | `EndlessDirector`, a child of the stage only in Endless: each spawn's strength, the modifier pick, the best wave, the RUN OVER rows. The stage itself kept small hooks (810 lines). |
| Strength | Normal and elite HP × (1 + 0.06n)(1 + 0.05n), damage × (1 + 0.025n)(1 + 0.05n), n = w − 1. Boss HP 15000, mini boss 9000, +30% per tier; their damage +15% per tier. |
| Rewards | Gold, XP and blue pay like Act 1 for waves 1–10, Act 2 for 11–20, and so on. Every boss and mini boss pays its **repeat** purple on the kill (2, 4 for Thresh, 1 for a mini boss); the save's boss list is never touched. Loot on every kill. |
| Modifiers | `ModifierPick`: 3 cards over the paused game, a click picks, the new one replaces the old. Shown first in the buff row with no timer. |
| Best wave | The most waves cleared in one run, kept in memory as each wave is won and saved when the run ends. "Best 22" under the stage info; "Best wave: 22" on the Journey. |
| RUN OVER | The end screen's optional title: Waves cleared, Time, Kills, Damage, Gold, Level, Modifier, and "New best: 22 waves!". Retry (same map choice) and Main screen (the Journey on Endless). |
| Exit prompts | `ConfirmPopup` gains `ask_or_cancel` (Yes / No / Cancel), `confirm` (an action / Cancel) and `cancel()`. Its three buttons are built once and relabeled. `Game` asks every exit. |
| Sounds | 11 new generated sounds in `Sfx`, and a `_notes()` helper for chimes. The click is connected once per button, at −10 dB. |
| Level-up burst | `LevelUpBurst`: a gold ring with sparks rising from Lucian's feet over his head, and "Level N", for 1.2 s. Only the text on Low quality. |
| World map | `JourneyMap`, `JourneyNode`, `JourneyPanel` and `MapThumbnail`, all drawn in code. The old tabs, act pages and cards are removed. |
| Map thumbnail | The chosen map's walls, abyss, mist, start and spawns, read from a `StageMaps.create` instance that never enters the tree and is freed at once, so nothing bakes. |
| Debug | "Jump to boss wave" goes to the next tenth wave in Endless; "Jump to the last wave" is hidden there. |

### Endless at a glance

| Wave | 1 | 5 | 10 | 20 | 35 | 50 |
|---|---|---|---|---|---|---|
| Normal enemies | 9 | 13 | (boss wave) | (boss wave) | 30 | (boss wave) |
| Elites | 0 | 1 | — | — | 4 | — |
| Normal and elite HP | ×1 | ×1.49 | ×2.23 | ×4.17 | ×8.21 | ×13.59 |
| Normal and elite damage | ×1 | ×1.32 | ×1.78 | ×2.88 | ×5.0 | ×7.68 |
| Boss or mini boss HP | — | 9000 (mini boss) | 15000 | 19500 | 17100 (mini boss) | 33000 |
| Rewards like Act | 1 | 1 | 1 | 2 | 4 | 5 |

| # | Modifier (downside / reward) |
|---|---|
| 1 | Enemies move 20% faster / +30% gold |
| 2 | Elites twice as often / ×1.5 orange drop rate |
| 3 | −10% max HP / +15% blue |
| 4 | −5% AD / +10% gold |
| 5 | Bosses and mini bosses +25% max HP / ×1.5 purple |
| 6 | Nothing / Nothing |

## Choices made where the request was open

Settled during planning (placeholders, easy to change):
- **Mana regen ×1.75** scales the growth too, not only the level-1 value, so it stays ×1.75 at every level.
- **The six maps** are built from one stage of each act: the Training ground's ring of 10 pillars, the Jungle with water and Honeyfruit, the Dead forest with 3 mist banks and the nest, Thresh's domain with 4 wide bridges.
- **Best wave** means the most waves cleared in one run: dying in wave 23 records 22.
- **The strength ramp and the boss HP** (15000 and 9000, fixed by wave whoever comes, so the random pick doesn't swing the run).
- **The pick comes after each boss wave** and waits; the game pauses while it is open.
- **Act 1's Thresh never comes in Endless:** his fight stops at 50% and needs Senna.

Settled while building (rulings that change what you see):
- **Damage at wave 35 is ×5.0, not ×5.2:** the plan's check value was an arithmetic slip; the formula stands.
- **A normal wave can be up to 2 enemies short** when both of its kinds are packs, because packs come whole and the cap of 30 must hold.
- **The break reads "Wave 24 in 0:12",** with the story's clock, not "in 12".
- **"None"** is the Modifier row both before any pick and after Nothing.
- **"New best: 1 wave!"** is singular; otherwise "N waves".
- **An Endless final Thresh's fall counts as a kill:** gold, XP and a loot roll, as the other bosses pay.
- **After an Endless run, the Journey keeps your map chosen** (found in the screenshots, see *Verification*).
- **A rank learned from Senna in Act 1 is silent:** `rank_up` is for your own choices.
- **Extras on the Journey panel:** the stage's ENEMIES row, "No boss on replays" on 1-1 once cleared, the small captions "PRACTICE" and "WAVES NEVER END", and the wording of the four Endless rules.

## Verification

- **Unit and scene tests (GUT):** **1512 of 1512 pass** (23489 asserts), up from 1342 at the end of Phase 8: 170 new.
  - New test files: `test_sounds`, `test_endless_plan`, `test_endless_runner`, `test_endless_modifiers`, `test_endless_stage`, `test_endless_modifiers_stage`.
  - Extended: `test_data_files`, `test_game`, `test_title_screen`, `test_main_screen`, `test_tree_data_files`, `test_kill_rewards`, `test_save_game`, `test_stage_setup`, `test_stage_result`, `test_journey`, `test_main_debug`.
  - `test_journey_section` was rewritten for the map: every old assertion was ported to the new API, none dropped, and 19 new tests added.
  - The Endless boss tests kill bosses through the real wave path, Thresh's fall included, and check for engine errors.
- **Screenshot runs in a real window:** 9 new scenarios and 9 that Phase 9 changed, 70 PNGs. Every printed check matched. The ones that matter most:
  - A new save locks Acts 2–6 and Endless. With Acts cleared = 3, only Acts 5–6 stay locked, the token is on 4-1, and the road is lit to 3-5.
  - The wave 10 boss stands at the boss point with 15000 HP and is not the stage's boss. Its kill pays +2 purple, and the save's boss list doesn't change. Thresh at wave 20 has 19500 HP and falls with no cutscene, paying +4.
  - The pick pauses the game and holds the break; after it, "Wave 11 in 0:20 [Skip]" and the modifier's row.
  - After a run, the save has `endless_best` 22, no `"endless"` in `cleared`, and `bosses` unchanged.
  - Every exit prompt has the right text and buttons, and Cancel and ESC leave things as they were.
  - The tree's 11 skill and spell icons are the same textures as the HUD's.
- **Looking at the screenshots** found one wrong state, fixed with a test: after an Endless run, Main screen opened the Journey on Endless but reset the map to Random, so Start would have rolled a new map. Your map choice now stays.
  - Harness fixes (not game bugs): the mouse is moved off the HUD so a slot's tooltip doesn't cover the shots, and the camera frames Lucian and the boss together.
- **Found and fixed during the tasks:** a debug jump during the pick could leave the break held for good; a double click on the cards could apply two modifiers; the held break showed a frozen countdown and Skip; RUN OVER read "Waves N / -1"; an Endless Thresh's fall paid nothing.

## Endless balance

**Nothing is measured yet.** The ramp is from the plan:
- Wave 1 is as easy as Act 1. Normal and elite HP pass Act 6's last story wave (×7.6) at wave 34, and damage passes it (×4.3) at wave 31.
- Bosses grow slower: +30% HP and +15% damage every 10 waves. Wave 50's boss has 33000 HP.
- Rewards climb one "act" every 10 waves, with no cap. With repeat purple on each boss (2, or 4 for Thresh) and mini boss (1), a run that clears wave 30 (3 mini bosses, 3 bosses) pays 9–13 purple, plus blue and orange; modifier #5 makes it about half again.

**The screenshots' numbers mean nothing for real play.** The Endless shots were staged with the debug tools: `endless_run_over` skips to wave 22 and sets the clock (22:11) and the level (16), so its 34 kills and 123 damage come from 1–2 real waves. Real numbers come from the playtest below: the end screen's Waves cleared and Time.

## Screenshots

The Endless shots are random each run (the enemies, the mini boss and the offer), except the seeded boss in `endless_boss`. The kills, damage and times on them are staged by debug tools and mean nothing for real play. All PNGs are 1600 × 900 (the window), except the art sheet.

### The world map

| | |
|---|---|
| ![New save](phase9/journey_map_0_new_save.png) A new save: Acts 2–6 under fog with chains, the Endless portal chained, the token on 1-1, which is picked (Thresh, "First kill: +10") | ![Mid game](phase9/journey_map_1_mid_game.png) Acts cleared = 3: Acts 1–3 checked, the road gold to 3-5, the token on 4-1 ("Start stage 1"), 4-2 and 4-3 locked inside Act 4, Acts 5–6 fogged, the portal open with "Best 14" |
| ![Boss picked](phase9/journey_map_2_boss_picked.png) 3-5 picked: the Elder Dragon with its Boss tag, "+2 again", "5 waves + boss wave", "Cleared", and the 10-icon ENEMIES row | ![Hover fogged](phase9/journey_map_3_hover_fogged.png) The cursor on fogged 5-3: "Clear Act 4 first" |
| ![All cleared](phase9/journey_map_4_all_cleared.png) All 22 stages cleared: the whole road lit, no token, Training picked with "Start Training" | ![Act 1 new](phase9/main_acts_0_act1.png) `main_acts` on a new save: the same map |
| ![Act 3 open](phase9/main_acts_1_act3.png) Acts cleared = 2: 3-1 picked ("Start stage 1"); 3-2 to 3-5 locked, with lock badges | ![Act 2 cleared](phase9/main_acts_2_act2_cleared.png) 2-3 picked: Akshan, "First kill: +10", "Cleared" |

### The Endless panel

| | |
|---|---|
| ![Jungle](phase9/journey_endless_0_jungle.png) "ENDLESS / Best wave: 22", the four rules, the 7 chips with Jungle lit, and the Jungle's thumbnail: walls, the pit and the spawns | ![Dead forest](phase9/journey_endless_1_dead_forest.png) The Dead forest's thumbnail: tree dots, 3 mist banks, the start and the spawns (dim, but it reads) |
| ![Thresh's domain](phase9/journey_endless_2_thresh_domain.png) Thresh's domain: plateaus and bridges over the abyss | ![Random](phase9/journey_endless_3_random.png) Random: the "?" card, "A map is rolled each run" |
| ![Endless locked](phase9/main_endless_0_locked.png) The chained portal hovered: "Clear Act 3 first" | ![Endless open](phase9/main_endless_1_open.png) After Act 3: the Endless panel with "Best wave: 0" and Random |

### Endless in play

| | |
|---|---|
| ![Wave 4](phase9/endless_wave_0_fight.png) The Jungle, wave 4: Murkwolves, Lantern Souls and an elite Chain Warden on Lucian. "Endless · Jungle  Wave 4  Enemies: 12", "Best 14" under it | ![Break](phase9/endless_wave_1_break.png) The break: "Mini boss wave in 0:18 [Skip]", "Best 14", the merchant |
| ![Mini boss](phase9/endless_wave_2_mini_boss.png) Wave 5: Maokai (9000 / 9000) on Lucian, its bar under the Best line, "Mini boss wave  Enemies: 15" | ![Boss wave](phase9/endless_boss_0_wave.png) Thresh's domain, wave 10: the Elder Dragon alone at the boss point, "Boss wave  Enemies: 1" |
| ![Boss won](phase9/endless_boss_1_won.png) After its kill: the purple counter at 2, and the pick opens (−5% AD / Elites twice as often / Nothing) | ![Thresh](phase9/endless_boss_2_thresh.png) Wave 20: final Thresh, "Thresh  Phase 1", 19500 / 19500, his hook line on Lucian |

### The modifier pick and the end of a run

| | |
|---|---|
| ![Cards](phase9/endless_pick_0_cards.png) The pick over the paused Training ground: −10% max HP / +15% blue, Enemies move 20% faster / +30% gold, Nothing. No countdown and no Skip | ![Picked](phase9/endless_pick_1_picked.png) The first card picked: "Wave 11 in 0:19 [Skip]"; the heart row in the buff bar, hovered: "Endless modifier", "−10% max HP", "+15% blue" |
| ![Other cards](phase9/endless_pick_2_other_cards.png) **A built set, not a real offer:** the three other modifiers, so every card is seen. The longest downside wraps to 2 lines and fits | ![RUN OVER](phase9/endless_run_over_0_result.png) RUN OVER, "Endless · Dark mid lane": 22 waves cleared, Modifier −10% max HP, "New best: 22 waves!", Retry and Main screen. Waves 1–21 were skipped and the time and level set by the harness |
| ![After the run](phase9/endless_run_over_1_journey.png) Main screen: the Journey on Endless, "Best wave: 22", and Dark mid lane still chosen (the fix) | |

### The exit prompts

| | |
|---|---|
| ![Leave to menu](phase9/exit_cancel_0_leave_to_menu.png) Gear → Leave to main menu: "Save before leaving?" Yes / No / Cancel | ![Cancelled](phase9/exit_cancel_1_leave_cancelled.png) After Cancel: the gear menu is still open |
| ![Leave stage](phase9/exit_cancel_2_leave_stage.png) Training's ESC menu → Leave this stage: "Leave this stage? Essences collected so far are kept." Leave / Cancel | ![Back in menu](phase9/exit_cancel_3_back_in_menu.png) After Cancel: still paused in the ESC menu |
| ![Exit in stage](phase9/exit_cancel_4_exit_in_stage.png) ESC menu → Exit the game: "Save before leaving?" Yes / No / Cancel over the menu | ![Leave run](phase9/exit_cancel_5_leave_run.png) In an Endless run: "Leave this run? Your best wave is kept." Leave / Cancel |
| ![Title exit](phase9/exit_cancel_6_title_exit.png) The title's Exit game: "Exit the game?" Exit / Cancel. The window X asks the same (checked, not shot) | ![Save prompt](phase9/main_gear_4_save_prompt.png) `main_gear`: "Save before leaving?" now with Cancel |

### The tree's icons and the level-up burst

| | |
|---|---|
| ![Skills](phase9/tree_icons_0_skills.png) Max tree: the Skills grove (passive, Q, W, E, R) with the HUD's icons, and the Stats grove | ![Summoners](phase9/tree_icons_1_summoners.png) The Summoners grove: six spells and six upgrades, each the spell's art with three gold chevrons |
| ![Close](phase9/tree_icons_2_close.png) The same at zoom 1.4: the chevrons are outlined and read on every spell, gold Barrier too | ![HUD](phase9/tree_icons_3_hud.png) Training at zoom 1.4: the HUD's skills and Flash and Heal, the same art |
| ![Burst](phase9/level_up_0_burst.png) 2-1, 0.15 s after a level from XP: the gold ring with sparks at Lucian's middle, "Level 2" over him | ![Rising](phase9/level_up_1_rising.png) Later in the rise: the ring under his HP bar |
| ![Close burst](phase9/level_up_2_close.png) Zoom 1.6: "Level 3" | ![Low](phase9/level_up_3_low_effects.png) Low quality: "Level 4" alone, no ring |

### Scenarios Phase 9 changed (re-shot)

| | |
|---|---|
| ![Journey new](phase9/main_journey_0_new_save.png) The Journey on a new save: 1-1 picked, D "None", F chained | ![Spell menu](phase9/main_journey_1_spell_menu.png) F's spell menu opens left of the panel: Flash, Ghost, Heal, Smite, None |
| ![Swapped](phase9/main_journey_2_swapped.png) Flash picked for F: D and F swap (Heal, Flash) | ![Art sheet](phase9/art_sheet_0.png) 36 icons at 64 and 32 px: the tree's skill and spell nodes now point at `ui/icon_*.svg` and `summoners/*.svg`, beside the six redrawn `tree/*_upgrade.svg` |
| ![Gear menu](phase9/main_gear_0_menu.png) The gear menu | ![Toast](phase9/main_gear_1_toast.png) Save: "Saved to slot 1" |
| ![Slots](phase9/main_gear_2_slots.png) Save as copy's slot list | ![Overwrite](phase9/main_gear_3_overwrite.png) "Overwrite slot 2?" still Yes / No |
| ![Training new](phase9/training_setup_0_new_save.png) Training on a new save: MS 345 in the stats panel and "+2.8/s" on the mana bar | ![D empty](phase9/training_setup_1_d_empty.png) The empty D key's card |
| ![F chained](phase9/training_setup_2_f_chained.png) F's card: the 2nd summoner slot isn't bought | ![Stage debug](phase9/training_setup_3_debug_table.png) The stage debug table |
| ![Max tree stage](phase9/training_setup_4_max_tree.png) Training after Max tree: ranks open, bonus stats in yellow, Flash and Heal, 6 equip slots | ![Upgrade card](phase9/training_setup_5_upgrade_card.png) An upgraded spell's card |
| ![Refresh](phase9/training_setup_6_shop_refresh.png) The merchant after Max tree: 4 items and the cheaper refresh | ![Classic](phase9/skins_stage_0_classic.png) Classic in Training: MS 345 |
| ![High Noon](phase9/skins_stage_1_high_noon.png) High Noon: MS 345 | ![PROJECT](phase9/skins_stage_2_project.png) PROJECT: MS 397 (345 × 1.15 = 396.75) |
| ![Pulsefire](phase9/skins_stage_3_pulsefire.png) Pulsefire: MS 345 | ![Vampire](phase9/skins_stage_4_vampire.png) Vampire: MS 345 |
| ![Tree new](phase9/main_tree_0_new_save.png) The Evolution Tree on a new save | ![Tree bought](phase9/main_tree_1_bought_info.png) After some buys, with a node's info panel |
| ![Hidden node](phase9/main_tree_2_hidden_info.png) A hidden node's info: "???" and what it requires | ![Hover](phase9/main_tree_3_hover.png) A node hovered |
| ![Zoom 0.6](phase9/main_tree_4_zoom_06.png) Zoomed out to 0.6 | ![Zoom right](phase9/main_tree_5_zoom_06_right.png) Zoom 0.6, dragged to the right end |
| ![Max left](phase9/main_tree_max_0_left.png) Max tree, the left end: the skill nodes with the stage's icons | ![Max right](phase9/main_tree_max_1_right.png) Max tree, the right end: Economy and Summoners |
| ![Max summoners](phase9/main_tree_max_2_summoners.png) The Summoners grove at zoom 1: the spell art and the redrawn upgrades | |

## Known limits

- **The sounds were never heard.** All 11 new ones were tuned from their numbers, headless. `essence` (a high sparkle) and `cast_q` at full volume may be loud; about −4 dB may suit them.
- **Endless balance is unmeasured** (see *Endless balance*). Every number is a placeholder: the constants at the top of `EndlessPlan` and `EndlessModifiers`.
- **Ground hazards aren't scaled** by a boss's tier: the Infernal Drake's burning ground and the revived Karthus's Defile stay at their story strength.
- **Endless's rewards have no cap:** wave 61 pays like an "Act 7" (7 blue a normal kill, gold and XP × 2.5).
- **A normal wave can be a little short** (up to 2 enemies) when both of its kinds are packs.
- **Senna teaching E in Act 1 makes no sound.**
- **Wider screens:** the Journey uses fixed positions, so on a screen wider than 16:9 the extra width stays empty on the right. The map and the panel also sit 8 px inside their area.
- **A HUD tooltip can stay over a just-opened menu** when the mouse rests on a slot (not new; Godot needs a mouse move to update hover).
- **Mini-detail fixes deferred** (the full list is in `phase9.md`, *Left as is*): small redraw and test-quality items on the map, the pick and the Endless tests, and a stale comment or two.
- **Tests:** every test passes, with notes:
  - GUT's 2 warnings are test scripts that leave a node or two unfreed (`test_act4`, `test_lucian_skills`).
  - `test_monsters`'s raptor-spread test waits on wall-clock time and can fail under load; it passes on a re-run.
  - The full suite takes about 10 minutes.

## Manual playtest checklist (for you)

Your save and settings live in `%APPDATA%\lucian_the_lantern\`. F3 + Q opens the debug tables (main screen: Acts cleared, essences, Max tree; stage: God mode, the Waves tab with skip and "Jump to boss wave", Level +1, spawn any enemy).

1. **Main debug → Acts cleared = 3 → Journey:** the world map shows Acts 1–3 lit, Act 4 open, Acts 5–6 fogged, and the Endless portal open.
2. **Endless → Jungle → Start.** Waves 1–4 mix enemies from every act. Wave 5 ends with a mini boss. Wave 10 has a boss alone at the boss point. Its kill pays repeat purple (+2, or +4 for Thresh).
3. **After wave 10, pick a modifier.** The break waits until you pick. #3 lowers max HP, and the buff row shows it (hover it for both lines).
4. **Die → RUN OVER,** "New best: N waves!" → Main screen → the Journey on Endless shows the new best, with your map still chosen.
5. **ESC → Leave this stage → Cancel:** still paused in the menu. **Leave:** the main screen.
6. **Gear → Exit the game → Cancel:** still on the main screen, the gear menu open. **The title's Exit asks too** ("Exit the game?"), and so does the window X.
7. **Level up in a stage:** a chime and a gold burst. Q, W and E have sounds. The wave horn, the boss gong, victory and defeat. Buttons click softly. *Listen for anything too loud, especially the essence sparkle and Q.*
8. **Evolution Tree:** Q, W, E, R, the passive and the six spells look like the HUD.
9. **The stats panel** shows MS 345, and the mana bar's regen reads 2.8/s at level 1 (hold C for the extra stats).
10. **The save file:** after a run, `"endless_best"` holds the waves cleared, `"cleared"` has no `"endless"`, and `"bosses"` is unchanged by Endless.
11. **Endless for time:** play one honest run per map you like and note Waves cleared and Time. That is the first real data for the ramp.

## Feedback and suggestions

- **Play one long Endless run first.** If waves 30–40 feel like a wall, lower `HP_GROWTH` (0.06) or `WAVE_GROWTH` (0.05) in `EndlessPlan`; if the bosses melt, raise `BOSS_HP` (15000) or `TIER_HP` (0.3).
- **Listen to the new sounds** and tell me which are too loud or wrong. Volumes are one number each.
- **The modifiers are a first set.** #2 and #5 are the ones whose rewards matter most for farming (orange and purple); if one is always picked, its downside can grow.
- **Small decisions that are yours:** the break's "Wave 24 in 0:12" clock (the plan said "in 12"), "None" for both no pick and Nothing, and whether Endless rewards should stop climbing at Act 6.
- **Music** is still missing, and every sound is a generated placeholder.

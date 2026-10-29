# Phase 9: Endless mode, a world-map Journey, Cancel on every exit, sounds and small tuning

> **Project:** `E:\Project\lucian-the-latern` (Godot 4.7.2 game), not the omnicourses repo this session opened in.
> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development (or superpowers:executing-plans). One verified commit per task. Task 0 copies this plan to `docs/implementation/phase9.md`.

## Context

The user's Phase 9 request:
- Design and implement Endless mode.
- Mana regen ×1.75 of the base.
- A level-up sound, plus other missing sounds.
- Evolution Tree skill and summoner icons the same as the in-stage icons.
- A better Journey overview ("the current one is so common").
- Lucian's base move speed +10.
- A **Cancel** choice on every exit that aborts the exit.

**Where the game stands** (HEAD `b2ad250`, Phase 8 Tasks 0–12 done):
- All 22 story stages play.
- The Endless tab exists (rules, a 7-way map choice, "Best wave: N"), but its Start is disabled. `SaveGame.endless_best` is saved but never written.
- **Phase 8's Task 13** (screenshots, docs, report) is in progress in another session, in the same folder. `tests/tools/screenshot.gd` has 573 uncommitted lines. Phase 9 starts **now, in parallel**, isolated as described in *Working beside Phase 8*.

### Working beside Phase 8
- **A separate worktree:** `git worktree add ..\lucian-the-latern-phase9 -b phase9 main`, from `b2ad250`. That folder is a clean checkout without the uncommitted Phase 8 files.
  - Run `--import` there once.
  - Every Phase 9 command and commit happens there, never in `E:\Project\lucian-the-latern`.
- **Phase 9 doesn't touch Phase 8's files until Phase 8 lands:**
  - `tests/tools/screenshot.gd`
  - `docs/act5_*.md`, `act6_*.md`, `lucian_game_design.md`, `ui_design.md`, `main_screen.md`
  - `docs/report/`
- **What waits:**
  - Task 0 only adds `docs/implementation/phase9.md`. Its §16 line moves to Task 10.
  - Every `screenshot.gd` edit in Tasks 1, 3 and 9 moves to Task 10. That script runs only with `-s` and isn't part of the GUT suite, so the suite stays green.
- **Before Task 10:**
  1. Check that Phase 8's "Phase 8 screenshots, docs and report" commit is on `main`.
  2. Run `git rebase main` on `phase9`, fix any conflicts (most likely in code Task 13 fixed after looking at its screenshots), and run the full suite.
  3. Then do Task 10.
- **The end:** fast-forward `main` to `phase9` and remove the worktree. Ask the user first.
- **Shared test files:** both folders share Godot's user dir (`lucian_the_lantern`), so their GUT runs use the same `test_run_*` scratch files. Don't run the full suite at the same moment as Phase 8. If a save or settings test fails oddly, run it again before debugging.

**What exploration found:**
- `WaveRunner` (`src/core/wave_runner.gd`) takes a fixed wave list and indexes past the end.
- Scaling lives in `EnemyData.hp_scale/damage_scale/reward_scale(act, wave)`. Bosses always return 1.
- Boss purple is paid only through `run.boss` in `Stage._on_cleared`. Mini boss purple is paid in `_award_mini_boss` (first or repeat).
- Bosses work on any map: they use `arena.boss_point`, and camps fall back to spawn points. Two exceptions:
  - **`thresh_1`** stops at 50% forever and needs Senna. It stays out of Endless.
  - **`thresh_final`** ends the run when he is `run.boss`. He is safe when he isn't, because `_on_thresh_fell` then calls `_thresh_leaves`.
- **Exits today:**
  - "Save before leaving?" offers Yes / No, and **both leave**.
  - "Leave this stage" and the title screen's Exit ask nothing.
  - `ConfirmPopup` has no signals and is answered with `answer(bool)` in tests.
- **Icons:** only the **Evolution Tree** differs from the stage.
  - The tree uses `assets/art/tree/{skill_q…r,passive,flash…smite}.svg`.
  - The HUD uses `assets/art/ui/icon_*.svg` and `assets/art/summoners/*.svg`.
  - The Journey loadout already uses the summoner art.
- **Sounds:** `src/audio/sfx.gd` generates 13 sounds in code.
  - Level-up, skill rank-up, Q/W/E casts, wave start, boss arrival, stage clear and defeat, and UI clicks are all silent.
  - Level-up has no visual either.
- **Base stats:** `data/lucian_stats.tres` has `move_speed = 335`, `mana_regen_per_5 = 8.0` and growth `0.7`. No test pins the live values.

### Decisions made with the user
| Topic | Decision |
|---|---|
| Endless roster | **All acts mixed.** Any normal or elite from any act can come on any map. The map changes only the terrain. |
| Endless difficulty | **The same ramp on every map.** Wave 1 is as easy as Act 1. Strength grows every wave and passes Act 6's late waves around wave 35. |
| Journey overview | **A world map.** One painted map: six act regions, a winding road through all 22 stage nodes, and Training and Endless as landmarks. A side panel shows the picked node and its Start. |
| Cancel | Every "Save before leaving?" becomes **Yes / No / Cancel** (ESC = Cancel). **New prompts:** "Leave this stage" asks **Leave / Cancel**, and the title screen's Exit game and window X ask **Exit / Cancel**. |

### Defaults chosen here (placeholders, tuned later; each goes into the docs in Task 10)
- **Mana regen ×1.75** scales the base **and** the per-level growth: 8.0 → 14.0 and 0.7 → 1.225 per 5 s. That is 2.8/s at level 1 and about 6.97/s at 18. Item and Blue-buff regen are not scaled.
- **Move speed** goes from 335 to 345.
- **Best wave** means the most waves cleared in one run. Dying in wave 23 records 22.
- **Icons:** the tree's skill and summoner nodes point at the stage art. The 11 old `tree/` copies are deleted. The six `tree/*_upgrade.svg` are redrawn from the stage spell art with the three gold chevrons, so they still match their spell.

---

## Design — Endless mode

### A run
- **Start:** from the Journey's Endless panel with the chosen map. "Random" rolls one of the six maps at Start, and again on Retry.
- **`StageSetup.for_endless(save, map_choice, rng)`** builds on `from_save` and adds:
  - `endless = true`, `boss = &""`, `stage_id = "endless"`
  - `display_name = "Endless · Jungle"`
  - `map_choice`, so Retry can repeat it
  - `act` and `stage` = the map's act and variant (below). They are used **only for the map**.
- **Waves never end.** The merchant comes in every break, as in story. The level cap stays at 18.
- **A run ends** only when Lucian dies or the player leaves. Quitting with Yes counts as leaving.

| Map choice | `act`, `stage` variant | Why |
|---|---|---|
| Mid lane | 1, 1 | |
| Training ground | 2, 3 | The ring of 10 pillars |
| Jungle | 3, 4 | Water and Honeyfruit: sustain for long runs |
| Dark mid lane | 4, 1 | |
| Dead forest | 5, 3 | 3 mist banks and the nest |
| Thresh's domain | 6, 1 | 4 wide bridges, 2 ledges |

### Waves (`EndlessPlan`, pure, `src/core/endless_plan.gd`)
- **Every wave w ≥ 1 follows these rules:**
  - **w % 10 == 0 is a boss wave:** one random act boss, alone. It never repeats the previous one.
  - **w % 5 == 0 (and not 10):** a normal wave, plus one random mini boss as its last entry. It never repeats the previous one.
  - **Any other w:** a normal wave.
- **A normal wave:**
  - `min(8 + w, 30)` normal enemies, drawn from **2 kinds** picked from the normal pool. A pack counts as its size.
  - Plus `min(w / 4, 4)` elites from the elite pool. Modifier #2 doubles this, up to 8.
- **Output:** each wave is an `Array[StringName]` produced by `WavePlan.expand`.
- **RNG:** one seeded `RandomNumberGenerator` per run. Tests fix the seed.

| Pool | Ids |
|---|---|
| Normal | `melee_minion`, `ranged_minion`, `shadow_melee_minion`, `shadow_ranged_minion`, `raptors`, `wolves`, `krugs` (packs), `gromp`, `sapling`, `spiderling`, `mist_walker`, `lantern_soul` |
| Elite | `siege_minion`, `super_minion`, `shadow_siege_minion`, `shadow_super_minion`, `blue_sentinel`, `red_brambleback`, `rift_scuttler`, `maiden_of_the_mist`, `broodmother`, `spectral_rider`, `chain_warden` |
| Mini boss | `infernal_drake`, `ocean_drake`, `maokai`, `elise`, `karthus_revived`, `hecarim` |
| Boss | `akshan`, `elder_dragon`, `dark_lucian`, `karthus`, `thresh_final` (**not** `thresh_1`) |

Camp enemies, perched Chain Wardens and the nest already fall back to spawn points on other maps.

### Strength (replaces the act/wave scaling in Endless)
| Who | Formula (w = wave) | Check |
|---|---|---|
| Normal and elite HP | base × (1 + 0.06(w−1)) × (1 + 0.05(w−1)) | w1 ×1, w10 ×2.2, w35 ×8.2 (Act 6's last wave is ×7.6) |
| Normal and elite damage | base × (1 + 0.025(w−1)) × (1 + 0.05(w−1)) | w35 ×5.2 |
| Boss HP (each phase for Thresh) | **15000** × (1 + 0.3(k−1)), k = w / 10 | Fixed by wave, so the random pick doesn't swing the run |
| Mini boss HP | **9000** × (1 + 0.3(k−1)), k = (w + 5) / 10 | |
| Boss and mini boss damage | basic `damage` and every `Boss.skill_hit` × (1 + 0.15(k−1)) | |

- Bosses spawn at `arena.boss_point` because their kind is `boss`. They are **never** `run.boss` or `boss_unit`.
- `EnemyUnit.skill_scale` (default 1.0) multiplies `Boss.skill_hit`.

### Rewards
- **Gold, XP and blue** use the story formulas with act **a = 1 + (w − 1) / 10** (integer division) in place of the act number. A normal kill gives a blue and an elite 5a. Orange chances are the same as in story.
- **Bosses and mini bosses** pay `KillRewards`' blue and orange as in story. They always pay the **repeat** purple (`purple_repeat`) **on the kill**, and `save.bosses` is never touched.
  - Final Thresh's fall takes the existing non-boss path (`_thresh_leaves`, no cutscene) and pays it too.
- Loot drops on every kill. There is no "last kill" in Endless.

### Modifiers (§14)
- **The pick:** after each boss wave (10, 20, …), the break waits for a pick.
  - A centered `ModifierPick` overlay shows 3 cards: 2 random from #1–5, plus **Nothing**. The current modifier is never offered.
  - The tree pauses while it's open, and ESC does nothing there. A click picks.
  - The new pick **replaces** the old one, with the `buff` sound.
- **On screen:** shown in the buff bar as a row with no timer. Its hover text gives both lines.

| # | Downside | How | Reward | How |
|---|---|---|---|---|
| 1 | Enemies move 20% faster | `move_speed` ×1.2 at spawn | +30% gold | gold ×1.3 |
| 2 | Elites twice as often | `EndlessPlan` elite count ×2 | ×1.5 orange drop rate | orange chance ×1.5 |
| 3 | −10% max HP | Lucian's run scale `{max_hp: 0.9}`, applied like a skin's scale | +15% blue | blue ×1.15 |
| 4 | −5% AD | run scale `{ad: 0.95}` | +10% gold | gold ×1.1 |
| 5 | Bosses and mini bosses +25% max HP | at spawn | ×1.5 purple | `roundi(repeat × 1.5)` |
| 6 | Nothing | — | Nothing | — |

Icons reuse existing art: `stats/move_speed`, `ui/essence_orange`, `stats/max_hp`, `stats/ad`, `ui/skull`.

### HUD, the end of a run, and saving
- **Stage info:**
  - During a wave: "Wave 23", "Mini boss wave" or "Boss wave", with no "/ N".
  - In a break: "Wave 24 in 12".
  - A dim "Best 22" underneath.
- **The result** (`StageResult`, with a new optional title):
  - Title **"RUN OVER"**, then "Endless · Jungle".
  - Rows: Waves cleared, Time, Kills, Damage dealt, Damage taken, Gold earned, Level reached, Modifier.
  - A green "New best: 22 waves!" when the run beat the old best.
  - Buttons: **Retry** (a new run with the same map choice) and **Main screen** (Journey on the Endless landmark). There is no Next.
- **Saving:**
  - `SaveGame.record_endless(waves) -> bool` keeps the max **in memory** each time a wave is cleared, the way essences already work.
  - The usual auto-save at the end (death, Leave, Yes when quitting) writes it. `finish_stage` never adds `"endless"` to `cleared`.
- **Debug:**
  - "Jump to boss wave" jumps to the wave before the next multiple of 10.
  - "Jump to the last wave" is hidden in Endless.

---

## Design — Journey as a world map

**Layout:** canvas 1920×1080. The content area runs from y 72 to 992.
- **`JourneyMap`** (x 32–1448) is drawn in code: a dark parchment world.
- **`JourneyPanel`** (440 wide, x 1448–1888, full content height) is opaque.
- The bottom section bar stays.

**Regions:** six act regions, laid out along a winding road (positions in a const table `JourneyMap.NODES`):
- **Top row, left to right:**
  - **Act 1** The Loss: lane, river line.
  - **Act 2** The Sentinels: stone tiles, pillars.
  - **Act 3** The Jungle: dark green tree clumps; the pit as its last node.
- **Middle row, right to left:** **Act 4** The Darkness: purple haze.
- **Bottom row, left to right:**
  - **Act 5** Shadow Isles: teal mist, dead trees.
  - **Act 6** The Lantern: abyss, chains, a lantern glow; the round platform as 6-5.
- Each region is a soft blob in its palette with code-drawn details and its name in caps.

**The road** is a stone path through every stage node (a `Curve2D`). It glows gold up to the latest cleared node and is dim beyond.

**Nodes:**
| Stage | Look |
|---|---|
| Normal | 56 px medallion with "3-1" |
| Mini boss | 76 px, grey ring, the mini boss's art |
| Boss | 100 px, red ring, the boss's art (from its `.tres` `art`) |

**Node states:**
| State | Look |
|---|---|
| Cleared | Gold rim and a green check |
| Open, not cleared | A soft pulse |
| Locked, inside an open act | Dim, with a small lock |
| In a locked act | The region is under dark fog with a chain; hovering says "Clear Act N first" |
| Picked | A white outline |

**Lucian's token:** the equipped skin's portrait (48 px) floats over the next stage (the first open one not yet cleared).

**Landmarks:**
- **Training:** a dummy medallion beside 1-1.
- **Endless:** a swirling green-purple portal in the bottom-right corner, off the road. It is chained until Act 3 is cleared ("Clear Act 3 first") and shows "Best 22" under it.

**Hover** shows the stage name and its waves.

**Side panel**, by what is picked:
- **A stage:**
  - "ACT 3 · THE JUNGLE" and "Stage 3-4".
  - The boss or mini boss portrait with its name and a "Boss" / "Mini boss" tag.
  - The waves line. Its exact strings are today's card text, e.g. "5 waves + mini boss".
  - The act's story line.
  - "Cleared" (green) or "Not cleared yet".
  - The boss purple: "First kill: +5" or "+1 again".
  - **Start** ("Start", or "Start stage 4").
- **Training:** the description and **Start Training**.
- **Endless:**
  - "ENDLESS" and "Best wave: 22".
  - Four rule rows with icons: mini boss every 5, boss every 10, a modifier every 10, blue and orange plus repeat purple.
  - The map choice: 7 chips and a **400×180 thumbnail** of the chosen map. The thumbnail is drawn from a `StageMaps.create(act, variant)` instance that is never added to the tree. Its polygons are filled in `_init`, so there is no nav bake. "Random" shows a "?" card.
  - **Start**.
- **The summoner spells**, a compact `LoadoutPanel` (D/F, 64 px), sit at the panel's bottom on every node. The spell menu opens to the left, as today.

**Which node opens:**
- the act just played (`focus_act`);
- Endless after an Endless run;
- otherwise the next stage, else Training.

**Kept API:**
- `JourneySection` signals `start_training` and `start_stage(act, stage)`, plus a new `start_endless(map_choice)`.
- `open_on(act)`, `refresh()`, `close_popup()`, `focus_act`.

**Replaced API:** `tabs`, `act_pages`, `StageCard` and `EndlessPage` give way to:
- `map.nodes`: `JourneyNode`, with `stage_id`, `kind`, `locked`, `cleared`, `selected`;
- `map.training`, `map.endless`;
- `panel.start_button`, `panel.map_buttons`, `panel.map_choice()`, `panel.best_label`.

Every behavior in `test_journey_section.gd` is ported to the new API, none dropped.

---

## Design — Cancel on every exit

**`ConfirmPopup`** (`src/ui/menu/confirm_popup.gd`):
- `ask()` is unchanged: Yes / No. Overwrite, Reset tree and "Could not save…" stay as they are.
- **New** `ask_or_cancel(text, on_yes, on_no, on_cancel := Callable())`: Yes / No / Cancel.
- **New** `confirm(text, action_label, on_action, on_cancel := Callable())`: [action] / Cancel.
- **New** `cancel()`, for the Cancel button, ESC and tests.
- The buttons are built once and shown or relabeled per ask.

| Exit | Prompt | Cancel / ESC |
|---|---|---|
| Gear → Leave to main menu (`Game.ask_to_leave`) | "Save before leaving?" Yes / No / **Cancel** | Closes the prompt. The gear menu is still open. |
| Gear or ESC menu → Exit the game, window X off the title (`Game.ask_to_quit`) | "Save before leaving?" Yes / No / **Cancel** | `_keep_playing`: restores the pause as it was |
| ESC menu → **Leave this stage** (new) | "Leave this stage? Essences collected so far are kept." **Leave / Cancel**. In Endless: "Leave this run? Your best wave is kept." | Back to the ESC menu, still paused |
| Title → Exit game, window X on the title (new) | "Exit the game?" **Exit / Cancel** | Stays on the title |

- **Leave this stage:** the stage's menu `leave_requested` now goes to `Game`, which asks. **Leave** calls `stage.leave()`, which emits `finished(&"left", &"main")` as before.
- Run alone, the stage keeps Leave disabled, as today.

---

## Design — Sounds

New names in `Sfx`, generated in code like the others. A small `_notes()` helper chains tones for chimes.

| Sound | When | Character |
|---|---|---|
| `level_up` | Lucian gains a level (on increases only, never at stage start) | A rising 3-note bright chime |
| `rank_up` | A skill rank is learned | A short two-note blip |
| `cast_q`, `cast_w`, `cast_e` | Piercing Light, Ardent Blaze, Relentless Pursuit | A bright laser zap; a fiery whoosh-pop; an airy dash whoosh |
| `wave` | Each normal wave starts (`wave_started`) | A short low horn |
| `boss` | A boss or mini boss enters | A deep gong/roar; replaces `wave` on a boss wave |
| `victory`, `defeat` | Stage cleared; defeat or Endless run over (at `show_result`) | A short fanfare; a falling sting |
| `click` | Any button styled by `UiStyle.style_button` (connected once per button, behind a meta flag), quiet (−10 dB) | A soft tick |
| `essence` | Orange or purple gained (`Stage.add_essences`) | A sparkle |

- **Level-up visual:** `LevelUpBurst` (`src/combat/level_up_burst.gd`, like `heal_burst.gd`): a gold ring rising around Lucian, plus a `FloatingText` "Level 7".

---

## Architecture

The layering is the same as Phases 1–8:
- **Pure logic** in `src/core/`, tested first with GUT.
- **Data** as `.tres`.
- **Nodes and UI** built in code, with no new `.tscn`.

**New:**
- `src/core/endless_plan.gd`: `EndlessPlan`.
  - Pools.
  - `wave(w, rng, elite_mult)`.
  - `pick_boss` / `pick_mini_boss(rng, last)`.
  - `hp_scale(w)`, `damage_scale(w)`, `boss_hp(w)`, `mini_boss_hp(w)`, `boss_power(w)`, `reward_act(w)`.
- `src/core/endless_modifiers.gd`: `EndlessModifiers`.
  - The 6 rows as data.
  - `offer(rng, current) -> Array[int]`.
  - Each row's multipliers.
- `src/core/endless_runner.gd`: `EndlessRunner extends WaveRunner`.
  - Generates each wave in `_start_next`.
  - Never finishes; `total_waves() = -1`.
  - Has `is_boss_wave()` / `is_mini_boss_wave()`.
  - Has `waves_cleared`.
  - Emits `boss_cleared(wave)` before the break; the break waits while `held` is true.
- `src/ui/stage/modifier_pick.gd`, `src/combat/level_up_burst.gd`.
- `src/ui/main/journey/{journey_map,journey_node,journey_panel,map_thumbnail}.gd`.
- **Removed:** `act_page.gd`, `stage_card.gd`, `journey_tab.gd`, `endless_page.gd`, `training_page.gd`. Their content moves into the map and the panel.

**Changed:**
| File | Change |
|---|---|
| `stage_setup.gd` | `endless`, `map_choice`, `for_endless`; reward multipliers `gold_mult`, `blue_mult`, `orange_mult`, `purple_mult` (default 1) |
| `kill_rewards.gd` | Reads those multipliers |
| `save_game.gd` | `record_endless` |
| `stage.gd` | The Endless branches: runner, spawn scaling and placement, purple on boss kills, the modifier flow, the result. Keep it lean: helpers go in `EndlessPlan`. |
| `enemy_unit.gd` / `boss.gd` | `skill_scale` |
| `lucian.gd` | `set_run_scale(dict)`, applied next to the skin's scale; level-up sound and burst |
| `stage_info.gd`, `hud.gd` | The Endless text, the modifier row |
| `stage_result.gd` | An optional title |
| `game.gd` | Endless routing, the prompts |
| `confirm_popup.gd`, `title_screen.gd`, `game_menu.gd` | The prompts |
| `sfx.gd`, `ui_style.gd` | The new sounds, the click |
| `main_screen.gd` | `start_endless` → `start_requested` |
| `debug_table.gd` | The Endless jumps |

## Global constraints (as in Phases 6–8)
- **Code style:** Godot 4.7.2 GDScript as the code around it: tabs, typed vars, `##` doc comments, `&"name"` StringNames, one `class_name` per file. No autoloads, no new `.tscn`.
- **The sandbox:** `stage.tscn` run alone stays the sandbox. `StageSetup.new()` has `act = 0` and `endless = false`.
- **Numbers:** new player-facing numbers are constants at the top of their script, or exports on a `.tres`.
- **Physics flush rule:** nothing in a damage path adds a body or runs a query. Endless boss kills pay purple deferred, as mini bosses do.
- **Reuse, don't fork:**
  - waves through `WavePlan.expand`;
  - runner behavior through `WaveRunner`;
  - purple through the `_award_mini_boss` path;
  - final Thresh through `_thresh_leaves`;
  - stat changes through the skin-scale path.
- **Commits:** on the `phase9` branch in its worktree, one verified commit per task (full GUT suite green), never pushed. `main` gets them by a fast-forward at the end. Every commit message ends with `Claude-Session: https://claude.ai/code/session_013QapQ5n9VdUwgAKVn4Gvfr`. This session's attribution line takes the place of the old `Co-Authored-By` line.
- **Docs voice:** short plain sentences, tables for numbers.

## Running things
```powershell
$godot = "$env:LOCALAPPDATA\Programs\Godot"
& "$godot\godot_console.exe" --headless --path . --import
& "$godot\godot_console.exe" --headless --path . -s res://addons/gut/gut_cmdln.gd
& "$godot\godot_console.exe" --headless --path . -s res://addons/gut/gut_cmdln.gd -gconfig= -gtest=res://tests/unit/<file>.gd -gexit
& "$godot\godot.exe" --path . -s res://tests/tools/screenshot.gd -- <scenario> <out_dir>
```

---

## Tasks
Each task follows the house checklist: write the failing tests → run them, they fail → implement → run the full suite, green → commit. No pre-written code.

### Task 0: The worktree, and save the plan
- Create the `phase9` worktree (*Working beside Phase 8*) and run `--import` there. Run the full suite once: green at `b2ad250`.
- Copy this plan to `docs/implementation/phase9.md`. The §16 line waits for Task 10.
- Commit: "Add the Phase 9 plan".

### Task 1: Lucian's base move speed 345 and mana regen ×1.75
- **Files:** `data/lucian_stats.tres` (345; 14.0 and 1.225), `tests/unit/test_data_files.gd`.
- **Tests:**
  - The real data gives MS 345, and mana regen 2.8/s at level 1 and ≈6.97/s at level 18.
  - The Blue buff's +10/s stays unscaled.
  - Update the stale "335" comments in `test_item_actives.gd` and `test_summoner_spells.gd`. The screenshot string "MS 335" waits for Task 10.
- **Commit:** "Lucian walks at 345 and regains mana 1.75× faster".

### Task 2: Cancel on every exit
- **Files:** `confirm_popup.gd`, `game.gd`, `stage.gd` (`leave()`; the menu's leave goes to Game), `game_menu.gd`, `title_screen.gd`.
- **Tests** (`test_game.gd`, `test_title_screen.gd`, `test_main_screen.gd`; new `cancel()` cases):
  - Cancel on Exit the game: no quit, no save, the pause is restored (in a stage and on the main screen).
  - Cancel on Leave to main menu: the main screen stays and the gear menu is still open.
  - ESC on these prompts = Cancel.
  - Leave this stage asks first: Leave goes to the main screen and saves; Cancel goes back to the ESC menu, paused.
  - The title's Exit and window X ask "Exit the game?"; Exit quits and Cancel stays.
  - Overwrite, Reset tree and "Could not save…" are still Yes / No.
- **Commit:** "Every exit can be cancelled: Yes / No / Cancel when saving, and Leave this stage and Exit game ask first".

### Task 3: The stage's icons in the Evolution Tree
- **Files:**
  - `data/tree/{skill_q,skill_w,skill_e,skill_r,passive}.tres` → `ui/icon_*.svg`.
  - `data/tree/{flash,ghost,barrier,heal,clarity,smite}.tres` → `summoners/*.svg`.
  - Delete the 11 old `assets/art/tree/*.svg` (+ `.import`).
  - Redraw `assets/art/tree/*_upgrade.svg` from the stage spell art, with the three gold chevrons.
  - The art-sheet paths in `screenshot.gd` wait for Task 10.
- **Tests** (`test_tree_data_files.gd`):
  - Skill and summoner nodes use the exact stage icon that `hud.gd` or `SummonerData.icon` uses.
  - Every other node keeps `tree/<id>.svg`.
- **Commit:** "The Evolution Tree shows the same skill and summoner icons as the stage".

### Task 4: Level-up sound and burst, and the missing sounds
- **Files:** `sfx.gd`, new `level_up_burst.gd`, `lucian.gd` (`level_changed` → sound and burst), `champion_progress.gd` / `skill_slot.gd` (`rank_up`), `piercing_light.gd` / `ardent_blaze.gd` / `relentless_pursuit.gd`, `stage.gd` (`wave`, `boss`, `victory` / `defeat`, `essence`), `ui_style.gd` (`click`).
- **Tests** (new `test_sounds.gd`, using `Sfx._last_played` as `test_status_effects.gd` does):
  - Every new name makes a stream that isn't the fallback beep.
  - A level gained plays `level_up` and adds a burst; stage start doesn't.
  - Learning a rank plays `rank_up`.
  - Q, W and E each play their cast sound.
  - A wave start plays `wave`; a boss spawn plays `boss`.
  - A clear plays `victory` and a defeat plays `defeat`.
  - Pressing a styled button plays `click` once, even if it was restyled.
  - Orange gained plays `essence`; blue alone doesn't.
- **Commit:** "A level-up chime and burst; sounds for rank-ups, Q/W/E, waves, bosses, the result, essences and buttons".

### Task 5: Endless logic (pure)
- **Files:** new `endless_plan.gd`, `endless_modifiers.gd`, `endless_runner.gd`; `stage_setup.gd` (`for_endless`, the multipliers), `kill_rewards.gd`, `save_game.gd` (`record_endless`).
- **Tests** (new `test_endless_plan.gd`, `test_endless_runner.gd`; extend `test_kill_rewards.gd`, `test_save_game.gd`, `test_stage_setup.gd`):
  - Wave 5 ends with a mini boss, wave 10 is one boss alone, and wave 7 has neither.
  - A boss or mini boss never repeats the last one.
  - `thresh_1` is never picked.
  - Every pool id loads and has the right kind (packs included).
  - Wave sizes follow the formula and are capped; #2 doubles the elites.
  - The scales match the table (w1 = 1, w35 > 7.6).
  - The runner never emits `cleared`, counts `waves_cleared`, and holds the break after a boss wave until released.
  - Reward multipliers change gold, blue and the orange chance.
  - `record_endless` keeps the max and survives save/load.
  - `for_endless` resolves Random to a real map and keeps `map_choice`.
- **Commit:** "Endless logic: generated waves with mini bosses every 5 and bosses every 10, the strength ramp, modifiers, the best wave".

### Task 6: Endless in the stage
- **Files:** `stage.gd`, `enemy_unit.gd`, `boss.gd` (`skill_scale`), `stage_info.gd`, `hud.gd`, `debug_table.gd`.
- **Tests** (new `test_endless_stage.gd`, using `test_stage_waves.gd`'s helpers with an Endless factory):
  - The stage uses an `EndlessRunner` on the chosen map.
  - A wave-1 melee minion has its base HP, and wave 20's HP follows the table.
  - A boss spawns at `boss_point` with `boss_hp(w)`, and its skill hits are scaled.
  - A boss kill pays repeat purple and leaves `save.bosses` alone.
  - Final Thresh's fall pays repeat purple with no cutscene, and the run goes on.
  - The merchant comes in breaks.
  - Stage info reads "Wave 7", "Mini boss wave", "Boss wave" and "Best 3".
  - Clearing a wave records the best in memory.
  - The debug "Jump to boss wave" reaches the next tenth wave.
- **Commit:** "Endless plays: generated waves on any map, scaled enemies and bosses, repeat purple on boss kills".

### Task 7: Modifiers
- **Files:** new `modifier_pick.gd`; `stage.gd` (open on `boss_cleared`, apply, release the break), `lucian.gd` (`set_run_scale`), `hud.gd` / `buff_bar.gd` (the row).
- **Tests** (new `test_endless_modifiers_stage.gd`):
  - After wave 10 the pick shows 3 cards with Nothing among them, and the break doesn't count down until a pick.
  - Each of #1–5 has its effect: enemy speed, elite count, Lucian max HP / AD (with the HP share kept), boss HP, and the reward multipliers.
  - A new pick replaces the old one and undoes its effect.
  - Nothing clears it.
  - The buff bar shows the row with no timer.
- **Commit:** "Endless modifiers: pick one of three after each boss wave; it replaces the last".

### Task 8: The end of a run, and Start
- **Files:** `stage.gd` (the result rows, "New best"), `stage_result.gd` (title), `game.gd` (finish routing: record, `finish_stage(result, "")`, Retry → `for_endless(map_choice)`, Main → Journey on Endless; the Endless leave text), `main_screen.gd` (`start_endless`), the old `endless_page.gd` (Start works; replaced in Task 9).
- **Tests** (`test_game.gd`, `test_endless_stage.gd`, `test_stage_result.gd`, `test_journey_section.gd`):
  - Death shows "RUN OVER" with Waves cleared and "New best" only when it is better.
  - Retry starts a new Endless run with the same choice.
  - Main opens Journey on Endless.
  - Leave and quit-Yes both save the best.
  - `cleared` never gets `"endless"`.
  - Start is enabled once Act 3 is cleared and starts the chosen map.
- **Commit:** "Endless can be started from the Journey; the run-over screen, the best wave saved, Retry and Main screen".

### Task 9: Journey as a world map
- **Files:** new `journey_map.gd`, `journey_node.gd`, `journey_panel.gd`, `map_thumbnail.gd`; rewrite `journey_section.gd`; remove the old page, card and tab scripts; adapt `loadout_panel.gd` (compact); `main_screen.gd` (focus Endless). The `screenshot.gd` helpers wait for Task 10.
- **Tests** (rewrite `test_journey_section.gd`, porting every behavior; `test_main_debug.gd`, `test_game.gd`):
  - 22 nodes plus 2 landmarks, none overlapping, all inside the map rect and clear of the panel.
  - Lock rules and hover texts ("Clear Act N first", "Clear Act 3 first").
  - Kinds and portraits for mini boss and boss nodes; the waves strings unchanged.
  - Cleared marks; the road lit to the latest clear.
  - The token sits on the next stage.
  - Picking a node fills the panel; Start text and enabled state.
  - `start_stage`, `start_training` and `start_endless(choice)` are emitted.
  - The thumbnail draws without adding the map to the tree (no nav bake, no leaks).
  - The loadout menu still works and ESC closes it.
  - `open_on` picks the right node.
- **Commit:** "Journey is a world map: six act regions on one road, Training and the Endless portal, a side panel with Start and the spells".

### Task 10: Screenshots, docs, report
- **First:** rebase `phase9` onto `main` once Phase 8's Task 13 has landed, and run the full suite.
- **Then the `screenshot.gd` edits held back from earlier tasks:**
  - the "MS 345" string (Task 1);
  - the art-sheet paths (Task 3);
  - the Journey helpers `start_training`, `main_journey`, `main_acts`, `main_endless` (Task 9).
- **New scenarios in `tests/tools/screenshot.gd`:**
  - `journey_map` (new save, mid-game, all cleared)
  - `journey_endless` (the panel with a thumbnail)
  - `endless_wave`, `endless_boss`, `endless_pick`, `endless_run_over`
  - `exit_cancel` (each prompt)
  - `tree_icons`
  - `level_up`
- **Look at every PNG.** Fix what doesn't read, with a test for each fix where one fits.
- **Docs:**
  - `lucian_game_design.md`: §14 "Built in Phase 9" with every number; §15 (the prompts and Cancel; the title Exit now asks); §16.
  - `main_screen.md`: Journey "Built in Phase 9" (the world map); the gear-menu table and the ESC order (line 53).
  - `ui_design.md`: §4 ESC menu (Leave asks); §7 title Exit; the HUD's Endless stage info and modifier row; the result's RUN OVER; a new **Sounds** table with all 24 names (13 old, 11 new).
  - `implementation/phase1.md`: a note on the new base speed and regen.
  - `implementation/phase9.md`: "Implementation notes".
- **Report:** `docs/report/phase9.md` (+ `report/phase9/*.png`) in the Phase 8 layout.
- **Commit:** "Phase 9 screenshots, docs and report".

---

## Verification
1. **GUT:** the full suite is green after every task.
2. **Screenshots** (Task 10): run every scenario and inspect each PNG:
   - the world map in three progress states
   - the Endless panel thumbnail
   - an Endless boss wave
   - the modifier cards
   - RUN OVER
   - each exit prompt with its Cancel
   - the tree's new icons
   - the level-up burst
3. **Manual playtest** (also goes into the report checklist):
   1. Main debug → Acts cleared = 3 → Journey: the world map shows Acts 1–3 lit, Act 4 open, Acts 5–6 fogged, and the Endless portal open.
   2. Endless → Jungle → Start. Waves 1–4 mix enemies from every act. Wave 5 ends with a mini boss. Wave 10 has a boss alone at the boss point. Its kill pays repeat purple.
   3. After wave 10, pick a modifier. The break waits. #3 lowers max HP and the buff row shows it.
   4. Die → RUN OVER, "New best: N waves!" → Main screen → Journey on Endless shows the new best.
   5. ESC → Leave this stage → Cancel → still paused in the menu → Leave → main screen.
   6. Gear → Exit the game → Cancel → still on the main screen. The title's Exit asks too.
   7. Level up in a stage: chime and gold burst. Q/W/E have sounds. Wave horn, boss gong, victory and defeat.
   8. Evolution Tree: Q/W/E/R/passive and the six spells look like the HUD.
   9. The stats panel shows MS 345 and mana regen 2.8/s at level 1.
4. **Save file:** after a run, `"endless_best"` holds the waves cleared, `"cleared"` has no `"endless"`, and `"bosses"` is unchanged by Endless.

## Risks to watch
- **`stage.gd` is 719 lines.** Endless must stay in small helpers, with formulas in `EndlessPlan`. If it grows past ~850 lines, move the Endless flow into an `EndlessDirector` node.
- **Final Thresh in Endless:** he must never be `boss_unit` or `run.boss`, or the run ends in the story cutscene. Test it.
- **The modifier hold and pausing:** the break must not tick during the pick, and the merchant must still come.
- **Rewriting Journey's tests:** port each assertion one for one. Don't drop coverage.
- **The click sound:** `style_button` is called again on re-style, so connect once (meta flag). Keep it quiet so menus don't feel noisy.
- **The map thumbnail:** `StageMaps.create` must not bake or leak. Free the instance right after reading its polygons.

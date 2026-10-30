# Main Screen Design

> Part of the Lucian game design. The main screen is shown outside of stages. Layout ideas are about 70–80% similar to the references used.

## Overview

The main screen has **3 sections**:

| # | Section | Purpose |
|---|---|---|
| 1 | **Evolution Tree** | Spend blue and orange essence on permanent upgrades |
| 2 | **Skin Shop** | Buy and equip skins with purple essence |
| 3 | **Journey** | Choose an act and stage, Training, or Endless |

The player's essences (blue, orange, purple) are shown in the **top-left** corner.

### Gear menu
- A **gear** button in the **top-left corner** (the essences are shown right next to it).
- Clicking it opens a pop-up in the **center** of the screen with these buttons:

| Button | Action |
|---|---|
| **Close** | Closes the pop-up |
| **Save** | Saves to the current save slot |
| **Save as copy** | Copies the current progress into another slot (asks before overwriting) |
| **Settings** | Opens the game settings |
| **Leave to main menu** | Asks **"Save before leaving?"** (Yes / No / Cancel), then returns to the title screen / save slot selection. Cancel stays, with the menu open |
| **Exit the game** | Asks **"Save before leaving?"** (Yes / No / Cancel), then closes the game. Cancel stays, with the menu open |

- **Nothing on the main screen saves by itself.** Evolution Tree and Skin Shop purchases are kept by **Save**, a **Yes** when leaving, or the auto-save when the next stage is done (see the game design doc §15).

### Navigation
- **Sections** (Evolution Tree, Skin Shop, Journey): switched with a bar at the **bottom** of the screen.
- **Sub-sections** (e.g. Act 1–6, Training, Endless): tabs at the **top** of the screen. *(Phase 9: Journey has no tabs; it is one world map. See Section 3.)*

### Built in Phase 5
- **The game opens on the main screen**, on **Journey → Training**. It loads save slot 1, or starts a new game when there is none (no file is written until the first save). *(Since Phase 6 the title screen comes first; see below.)*
- **Top bar** (72 px): the gear button (48 px), then blue, orange and purple essence (36 px icon and the amount). Hovering an essence shows where it drops and what it buys.
- **Bottom bar** (88 px): **Evolution Tree · Skin Shop · Journey**, three 280 × 60 buttons; the open section's button is lit.
- **Gear menu** (a centered pop-up over a dark backdrop, title "MENU"):

| Button | Built |
|---|---|
| Close | Closes the pop-up |
| Save | Saves to the current slot (slot 1 for now) and closes the pop-up. A toast says "Saved to slot 1" (red "Could not save" if writing failed) |
| Save as copy | Turns the pop-up into a slot list: "Slot 1 (current)" (disabled), then "Slot 2 · empty" or "Slot 2 · saved 2026-10-28 14:03", and Back. An empty slot is written at once; a used one asks **"Overwrite slot 2?"** (Yes / No). Toast: "Copied to slot 2". The current slot stays slot 1 |
| Settings | The same Settings screen as in a stage; Back returns to the menu |
| Leave to main menu | **Disabled** until the title screen exists. Hover: "The title screen comes later" *(works since Phase 6)* |
| Exit the game | Asks **"Save before leaving?"** (Yes / No), then closes the game. Closing the window asks the same. If the save fails: "Could not save. Quit anyway?" (No goes back) *(Yes / No / Cancel since Phase 9)* |

- **Toast:** a short message at the top center, inside the top bar, fading out over 1.6 s.
- **ESC**, in this order:
  1. On a Yes / No question, ESC answers **No** (Overwrite, Reset tree); "Save before leaving?" needs a click. Settings reads its own ESC, as in a stage. *(Phase 9: ESC is Cancel on "Save before leaving?"; see below.)*
  2. An open pop-up in the section closes: the spell menu in Journey, the node info panel in the Evolution Tree.
  3. The slot list goes back to the menu; an open gear menu closes.
  4. Otherwise ESC opens the gear menu.
- **Debug table (F3 + Q, hidden by default):** an **Essences** tab (blue +100 / +1000 / +10000, orange and purple +1 / +10 / +100, Reset for each) and a **Progress** tab (Acts cleared 0–6, Max tree (free), Clear tree (no refund), Reset progress: a new game in memory). Nothing there saves.

### Built in Phase 6
- **The game opens on the title screen** (`ui_design.md` §7): Start new game, Load game, Settings, Exit game. A new game goes straight into Act 1, then to the main screen. Loading a slot opens the main screen.
- **The current slot** is the one picked on the title screen. Save writes to it, and the toast names it ("Saved to slot 2").
- **Leave to main menu** works: "Save before leaving?" (Yes / No), then the title screen. If the save fails: "Could not save. Leave anyway?". *(Yes / No / Cancel since Phase 9.)*
- **Save as copy** uses the title screen's slot list, so a used slot also shows its play time: "Slot 2 · 1h 02m · saved 2026-10-29 03:10".
- The debug table's Progress tab adds **Forget boss purple**: every boss gives its first-time purple again.

### Built in Phase 9
- **Every exit can be cancelled.** Phase 5 built "Save before leaving?" with Yes / No and no Cancel, as asked then (`implementation/phase5.md`). In Phase 9 the user asked for a Cancel on every exit, which replaces that decision.

| Button | Asks | Cancel / ESC |
|---|---|---|
| Leave to main menu | "Save before leaving?" Yes / No / **Cancel** | Closes the question; the gear menu is still open |
| Exit the game (and the window's close button) | "Save before leaving?" Yes / No / **Cancel** | Closes the question; the gear menu is still open, and nothing is paused |

- "Could not save. Leave anyway?" and "Could not save. Quit anyway?" keep Yes / No. ESC does nothing on them.
- Overwrite slot and Reset tree keep Yes / No.
- The three buttons are built once in `ConfirmPopup` and shown or relabeled for each question.
- **ESC**, in this order:
  1. An open question reads ESC first. On "Save before leaving?" (and the title's "Exit the game?") ESC is **Cancel**. On a Yes / No question it answers **No** (Overwrite, Reset tree). On "Could not save…" it does nothing. Settings reads its own ESC, as in a stage.
  2. An open pop-up in the section closes: the spell menu in Journey, the node info panel in the Evolution Tree.
  3. The slot list goes back to the menu; an open gear menu closes.
  4. Otherwise ESC opens the gear menu.
- **Sounds:** every styled button clicks softly (−10 dB), on the main screen and the title too (`ui_design.md` §8).

---

## Section 1 – Evolution Tree

Reference: a node-graph tree with icons in square frames connected by lines (see the screenshot the design was based on).

### Layout
- **One big map shown as a forest:** no separate pages for skills, stats, equipment, summoners and economy. Every branch lives on the same canvas, each growing from its own roots.
- Each upgrade is a **square node with an icon**. Lines connect a node to its requirements.
- The player can **drag to move** around the map and **zoom** with the mouse wheel.
- Essences in the top-left.
- **Reset tree** button (costs 5 purple, refunds all blue and orange).

### Node states
| State | Look |
|---|---|
| Hidden (requirements not met) | Dark frame with a **"?"** |
| Available, can afford | Normal frame |
| Available, can't afford | **Red** frame |
| Bought (more levels left) | Lit frame, line to it becomes bright |
| Maxed | **Green** frame |

### Node info panel
Clicking a node opens a panel (bottom-right, like the reference):
- **Name** of the upgrade
- **Current value → next value** (e.g. `+40% → +60%`)
- **Short description**
- **Level:** e.g. `LVL 2 / 5`
- **Cost bar:** shows owned essence against the cost, and works as the **buy button**

### Built in Phase 5

**31 nodes** in five groves, left to right: Skills, Stats, Equipment, Economy, Summoners. Costs and what each level gives are in the game design doc §11; this table is where each node sits. Grid = (column, row up from the ground); one cell is 150 px.

| Grove | Node (id) | Grid | Levels | Requires |
|---|---|---|---|---|
| Skills | Q – Piercing Light (`skill_q`) | (1, 0) | 5 | Clear Act 1 |
| Skills | W – Ardent Blaze (`skill_w`) | (2, 0) | 5 | Clear Act 1 |
| Skills | E – Relentless Pursuit (`skill_e`) | (3, 0) | 5 | Clear Act 1 (level 1 given then) |
| Skills | Passive – Lightslinger (`passive`) | (0, 1.5) | 1 | Any 1 of Q, W, E |
| Skills | R – The Culling (`skill_r`) | (2, 2) | 3 | Q, W, E and the passive |
| Stats | Attack Damage, Ability Power, Health, Armor, Magic Resist, Attack Speed, Mana (`stat_ad` … `stat_mana`) | (5, 0) … (11, 0) | 5 each | — |
| Equipment | Equip Slots (`equip_slots`) | (13, 0) | 5 | — |
| Economy | Stage Gold, Bonus XP, Essence Drops (`stage_gold`, `bonus_xp`, `essence_drop`) | (15, 0), (16, 0), (17, 0) | 3 each | — |
| Economy | Merchant Stock (`merchant_stock`) | (18, 0) | 2 | — |
| Economy | Cheaper Refresh (`refresh_cost`) | (19, 0) | 2 | — |
| Summoners | Flash, Ghost, Barrier (`flash`, `ghost`, `barrier`) | (21, 0), (22, 0), (23, 0) | 1 each | — |
| Summoners | Heal, Clarity, Smite (`heal`, `clarity`, `smite`) | (25, 0), (26, 0), (27, 0) | 1 each | — |
| Summoners | The six upgrades (`flash_upgrade` … `smite_upgrade`) | above their spell, row 2 | 3 each | That spell |
| Summoners | Second Summoner Slot (`summoner_slot_2`) | (24, 1.25) | 1 | Any 2 spells |

**The forest:**
- A dark soil band runs under every grove, with three curved roots under each and the grove's name in the soil.
- A line joins each node to each node it needs. It turns **gold** once the node has a level; until then it is dim.
- **Drag** (left button) pans the map. A press only becomes a drag after 6 px, so a click still picks a node. **The wheel** zooms from 0.6 to 1.4 in 0.1 steps, around the cursor. The map can't leave the screen, and its right end can be dragged out from under the info panel.
- It opens on the Skills grove at zoom 1, with the ground at the bottom.

**Nodes** are 72 px squares with a level badge under them ("2/5"; hidden nodes have none). Hovering one shows its name and what it gives now.

| State | Look |
|---|---|
| Hidden | Dark frame, no icon, a grey "?" |
| Open, can afford | Icon, gold frame |
| Open, can't afford | Icon, red frame |
| Bought, more levels left | Icon, pale gold frame with a soft glow |
| Maxed | Icon, green frame |
| Chosen | An extra white outline |

A node with a level is never hidden (this only matters after the debug table's Max tree, which skips requirements).

**Info panel** (bottom-right, 440 px wide, opaque):
- The name, "LVL 2 / 5", and "+8 AD → +12 AD". A maxed node shows only its value, in green.
- The description.
- A hidden node reads "???" and adds a red line built from its requirements, e.g. "Requires: Q – Piercing Light, W – Ardent Blaze or E – Relentless Pursuit", "Requires: any 2 of …", "Requires: Clear Act 1".
- **Cost bar** (400 × 56, the buy button): for each essence the next level needs, its icon and "owned / cost" (red when short). A gold fill shows how close the player is (the smallest share over the kinds needed). It can only be clicked when the level can be bought; a click buys it with a coin sound. It reads **MAXED** (green), **LOCKED** (grey) or **Free** (E's first level after Act 1).

**Reset tree** (top-right): "Reset tree 5" with the purple icon. Disabled until something is bought and 5 purple are owned. It asks "Reset the Evolution Tree for 5 purple essence? Every blue and orange essence spent comes back." Buying and resetting never save by themselves.

### Built in Phase 9
**The tree shows the stage's icons.** The skill nodes (Q, W, E, R, the passive) use the HUD's skill icons (`assets/art/ui/icon_*.svg`). The six spell nodes use the summoner art (`assets/art/summoners/*.svg`), as the HUD and the Journey's spells do. The 11 old `tree/` copies are gone. The six spell upgrades (`tree/*_upgrade.svg`) are redrawn from their spell's art with three outlined gold chevrons, so each still matches its spell. Every other node keeps its `tree/<id>.svg`.

---

## Section 2 – Skin Shop

A **full-screen** section showing every skin, including **Classic Lucian**.

### Each skin card
- **Big art** of the skin.
- Below the art:
  - **Bonuses** (green) and **weaknesses** (red)
  - A **short description** of its playstyle
  - **Button:**

| Situation | Button |
|---|---|
| Not owned | **Purchase** (shows purple cost) |
| Owned, not equipped | **Equip** |
| Currently equipped | **Equipped** (disabled) |

- Classic Lucian is always owned, so it shows **Equip** or **Equipped**.

### Skins
| Skin | Cost | Bonus | Weakness |
|---|---|---|---|
| Classic | Free | — | — |
| High Noon | 25 purple | +15% AD | −15% Attack Speed |
| PROJECT | 30 purple | +20% Attack Speed, +15% Move Speed | −10% AD |
| Pulsefire | 20 purple | +15% AP, +15 Ability Haste | −10% Attack Speed |
| Vampire | 25 purple | +15% Lifesteal, kills heal 2% max HP | −20% max HP |

### Built in Phase 5
- Five cards (320 × 640) in a centered row: the portrait (288 px), the name, bonuses in green, weaknesses in red ("—" for Classic), the playstyle, and the button at the bottom.
- The equipped card has a bright gold border.
- **Purchase 25** shows the purple icon. Without enough purple it is disabled and its price turns red.
- **Buying doesn't equip**; there is no confirm step. Neither buying nor equipping saves by itself.
- In a stage, Lucian's body sprite and the HUD portrait follow the equipped skin. How the stat changes work is in the game design doc §10.

---

## Section 3 – Journey

### Tabs at the top
`Act 1` · `Act 2` · `Act 3` · `Act 4` · `Act 5` · `Act 6` · `Training` · `Endless`

*(Phase 9 replaced the tabs with a world map: the acts are regions, the stages are places on one road, and Training and Endless are landmarks. The unlock rules below still hold. See "Built in Phase 9".)*

### Unlock rules
| Tab | Unlocks when |
|---|---|
| Act 1 | Always open |
| Act 2–6 | The previous act is cleared |
| Endless | **Act 3** is cleared |

- Locked tabs are covered by a **chain lock**. *(Phase 9: a locked act lies under fog with a chain and a lock.)*

### Inside an act tab
- Shows the act's stages in order.
- A stage unlocks when the previous stage is cleared.
- Cleared stages can be replayed.
- Mini boss and boss stages are marked with a **skull** icon. *(Phase 9: a bigger medallion with the mini boss's or boss's art, and a grey or red ring.)*

### Built in Phase 5
Only **Training** can be started; acts and Endless are shown and unlock as designed, but their Start buttons wait for a later phase. *(The acts start since Phases 6–8, Endless since Phase 9.)*

- **Tabs** (150 × 48): the open one is lit. It opens on **Training**. A locked tab is disabled, with a small chain left of its name; hovering says "Clear Act 1 first" (Endless: "Clear Act 3 first"). *(Phase 6 changed which tab opens; Phase 9 removed the tabs. See below.)*
- **Act page:**
  - The title ("ACT 3 · THE JUNGLE") and the act's story line.
  - One card per stage (200 × 230): "Stage 2", its waves ("4 waves + mini boss wave", "5 waves + boss wave"), a skull (grey for a mini boss, red for the boss).
  - A locked card shows a chain; a cleared card gets a green check and a green frame.
  - **Start** is disabled ("Acts come in a later phase"). *(Acts 1–2 start since Phase 6, Acts 3–4 since Phase 7, Acts 5–6 since Phase 8.)*
- **Training page:** what Training is ("Practice on training dummies with what you have bought in the Evolution Tree and your equipped skin. No essences are earned. Leave from the ESC menu to come back here.") and a gold **Start Training** button.
- **Endless page:** the rules (waves never end, a mini boss every 5 waves, an act boss every 10, a modifier pick every 10), a map choice (Random or one of the six act maps; kept on the page, not saved yet), "Best wave: N" and **Start** disabled ("Endless comes in a later phase"). *(Start works since Phase 9.)*
- **Loadout panel** (right side, on every tab): "SUMMONER SPELLS" with two 72 px buttons under their keys (**D** and **F**, following the bindings).
  - A click opens a small menu beside the panel: one icon per **bought** spell (the one already there is lit) and **None**. It closes on a pick, ESC, a click outside, or a second click on the same key.
  - Picking the spell that is on the other key swaps the two.
  - With no spell bought, the menu reads "Buy spells in the Evolution Tree".
  - **F** is chained and disabled until the Second Summoner Slot is bought ("Buy the 2nd summoner slot in the Evolution Tree").
  - A spell no longer bought (after a tree reset) shows as empty; the pick itself is kept.
  - The choice is saved with the progress.
- **Start Training** builds the stage from the save: only bought ranks can be learned, the passive only works once bought, the equip slots, shop items, refresh cost and stat bonuses come from the tree, D and F from the loadout (F stays empty without the 2nd slot), and the look from the skin. The stage debug table can still change all of this for that run.

### Built in Phase 6
**Acts 1 and 2 start.**
- **Picking a stage:** a click on an open card picks it; a gold outline marks it. A locked card can't be picked. The page opens on the first open stage not cleared yet, else the last open one.
- **Start** plays the picked stage: "Start" for a one-stage act, "Start stage 2" otherwise. The stage is built from the save like Training, plus its waves, map and boss. Act 1's first play is the tutorial (`act1_the_loss.md`).
- **Acts 3–6:** the cards can be picked, but Start stays disabled ("Act 3 comes in a later phase"). Endless's Start is still disabled. *(Acts 3–4 start since Phase 7, Acts 5–6 since Phase 8, Endless since Phase 9.)*
- **Which tab opens:**
  - after a stage (Continue on its result, or Leave this stage), the act just played;
  - otherwise (a loaded slot, after Training), the first act with an open stage not cleared yet, else Training.
- A cleared stage can be played again. Act 1's card always reads "2 waves + boss wave", though a replay has no boss.

### Built in Phase 7
**Acts 3 and 4 start**, like Acts 1 and 2: an act's Start works as soon as its first stage has waves.
- **Act 3's cards:** "3 waves", "4 waves + mini boss" (grey skull), "4 waves", "5 waves + mini boss" (grey skull), "5 waves + boss wave" (red skull). The drake comes last in the last wave, not in a wave of its own, so its card no longer says "+ mini boss wave".
- **Act 4's cards:** "4 waves", "5 waves", "5 waves + boss wave" (red skull).
- **Acts 5–6** can be picked once open, but Start stays disabled ("Act 5 comes in a later phase"). *(They start since Phase 8.)*
- **Endless** still opens once Act 3 is cleared, and its Start stays disabled ("Endless comes in a later phase"). *(Start works since Phase 9.)*
- **The end screen's buttons start stages directly** (`ui_design.md`, "Stage result"):
  - **Retry** starts the same stage again, built fresh from the save, without passing through the main screen.
  - **Next stage** starts the next one: 1-1 → 2-1, 2-3 → 3-1, 3-2 → 3-3. It shows only after a clear, when that stage can be played.
  - **Main screen** opens the main screen on the act just played, as Continue did.
  - Each saves first. If the save fails, Retry and Next land on the main screen instead, with the red "Could not save" toast.
- After Retry or Next, the next end screen leads back here the same way, so the main screen only shows when the player asks for it.

### Built in Phase 8
**Acts 5 and 6 start.** An act's Start works as soon as `WavePlan` has the act's first stage (5-1, 6-1) and the act is open: Act 5 once Act 4 is cleared, Act 6 once Act 5 is cleared. All 22 stages can now be played.
- **Act 5's cards:** "5 waves", "5 waves + mini boss" (grey skull), "6 waves", "6 waves + mini boss" (grey skull), "6 waves + boss wave" (red skull).
- **Act 6's cards:** "6 waves", "6 waves + mini boss", "7 waves", "7 waves + mini boss", "7 waves + boss wave".
- **The first clear of 6-5** shows `TheEndScreen` after the stage-end screen's button (`ui_design.md`), then the main screen on Act 6 (or 6-5 again after Retry). Next stage after 6-5 goes to the main screen as before.
- **Which tab opens** when every act is cleared: Training.
- **Endless** still opens once Act 3 is cleared, and its Start stays disabled ("Endless comes in a later phase"). *(Start works since Phase 9.)*

### Built in Phase 9
**Journey is a world map,** and **Endless starts.** The tab row, the act pages and the stage cards are gone. The section is a painted map with a side panel beside it, over the bottom section bar.

| Part | On screen (1920 × 1080) |
|---|---|
| The map (`JourneyMap`) | x 32–1448, y 80–984 (1416 × 904) |
| The side panel (`JourneyPanel`), opaque | x 1448–1888, y 80–984 (440 × 904) |

**The map** is drawn in code on dark parchment, with stains, a gold frame and corner diamonds, and a compass rose where the road turns down from Act 4 to Act 5.

| Act | Where | Look |
|---|---|---|
| 1 The Loss | Top row, left | The lane, and the river past 1-1 |
| 2 The Sentinels | Top row | Stone tiles and pillars |
| 3 The Jungle | Top row, right | Dark green tree clumps; the Elder Dragon's pit rings 3-5 |
| 4 The Darkness | Middle row, right to left | Purple haze, dark shards and motes |
| 5 Shadow Isles | Bottom row, left | Teal mist, dead trees, Karthus's graves |
| 6 The Lantern | Bottom row, right | The abyss with green mist, rock islands under 6-1 to 6-4, hanging chains, the lantern and its glow, and the round rune platform under 6-5 |

- Each region is a soft blob in its colors, with "ACT 3" over its name in spaced capitals.
- **The road** is a cobbled stone path, one curve through all 22 stages in play order, with a bend between rows. It glows gold up to the latest cleared stage and is dim beyond.

**Places:**

| Place | Look |
|---|---|
| Normal stage | A 56 px medallion with its id ("3-1") |
| Mini boss stage | 76 px, a grey ring, the mini boss's art, its id on a plate below |
| Boss stage | 100 px, a red ring and a red glow, the boss's art, its id on a plate |
| Training | A 72 px dummy beside 1-1, joined to it by a dotted footpath, with a "TRAINING" plate |
| Endless | A 112 px swirling green-purple portal in the bottom-right corner, off the road, with an "ENDLESS / Best 22" plate |

| State | Look |
|---|---|
| Cleared | A gold rim and a green check |
| Open, not cleared | A pulse ring every 1.8 s and a glow |
| Locked, in an open act | Dim, with a small lock |
| In a locked act | Under the region's dark fog, with a chain X and a lock; the region's name turns grey |
| Picked | A white outline |
| Hovered | A faint outline |

- The Endless portal is chained and dim, with a lock, until Act 3 is cleared.
- **Hover texts:**
  - A stage: its name and waves ("Stage 3-4 · The Jungle", "5 waves + mini boss"), plus "Clear 3-3 first" when it is locked in an open act.
  - A locked act, its region or its stages: "Clear Act 4 first".
  - Training: "Training". Endless: "Endless" and "Best wave: 22", or "Clear Act 3 first" while locked.
- **Lucian's token:** the equipped skin's portrait (48 px, a gold ring and a pointer) bobs over the next stage, the first open one not yet cleared. Once every stage is cleared, it is gone.
- A click on an open place picks it. A locked place can't be picked.

**The side panel**, by what is picked. A soft glow in the place's color falls from its top.
- **A stage:**
  - "ACT 3 · THE JUNGLE" and "Stage 3-4".
  - The boss or mini boss: a round 112 px portrait, a "Boss" or "Mini boss" tag, and its name.
  - Its purple: "First kill: +5" or "+1 again". 1-1 once cleared reads "No boss on replays" (dimmed): Act 1's replays have no Thresh.
  - The waves, with the old cards' strings ("5 waves + mini boss", "5 waves + boss wave").
  - The act's story line.
  - "Cleared" (green, with a check) or "Not cleared yet".
  - **ENEMIES:** a 44 px round icon for each of the stage's enemies, once each, in wave order (the mini boss is in the portrait). Each icon's hover is its name.
  - **Start:** "Start" for Act 1's one stage, else "Start stage 4".
- **Training:** "PRACTICE", "TRAINING", the dummy, the text (as before) and **Start Training**.
- **Endless:**
  - "WAVES NEVER END", "ENDLESS" and "Best wave: 22" in gold.
  - Four rules with icons: "A mini boss every 5 waves", "A boss every 10 waves", "A modifier to pick after each boss", "Blue, orange, and repeat purple".
  - **MAP:** 7 chips: Random, Mid lane, Training ground, Jungle, Dark mid lane, Dead forest, Thresh's domain. Only the chosen one is lit. Random is the default.
  - A **400 × 180 thumbnail** of the chosen map, in the act's colors: its floor, walls, abyss, round walls, mist, Lucian's start (gold) and the spawn points (red). It is read from a `StageMaps.create` instance that is freed at once and never enters the tree, so nothing bakes. Random shows a "?" card: "A map is rolled each run".
  - **Start** starts a run on the chosen map (game design doc §14). Random rolls a map at Start.
- **The summoner spells** sit at the bottom for every pick: the D/F loadout, compact (400 wide, 64 px keys). Its menu opens left of the panel, 32 px clear of it, and opens upward when it would run off the screen. It works as before.
- **Start** (400 × 64) sits at a fixed place above the spells.

**Which place opens:**
1. After a story stage: the act just played, at its first open stage not cleared yet (its last when all are).
2. After an Endless run (Main screen, Leave, or a failed save on Retry): Endless, with the run's map still chosen, if Endless is open.
3. Otherwise (a loaded slot, after Training): the next stage, where the token is.
4. With every stage cleared: Training.

A pick that becomes locked (the debug table) falls back the same way. Nothing here saves.

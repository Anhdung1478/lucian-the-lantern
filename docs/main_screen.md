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

- **Little on the main screen saves by itself.** Evolution Tree and Skin Shop purchases are kept by **Save**, a **Yes** when leaving, **pressing Start** (any Start: a stage, Endless or Training; V1.4.2), or the auto-save when the next stage is done (see the game design doc §15).
- **Start saves first.** If the save fails, the stage doesn't start. A red toast reads "Could not save, so the stage didn't start", the error sound plays, and you stay on the main screen. *(V1.4.2.)*
- **Built in V1.2:** the pop-up is the same ornate card as the stage's ESC menu (`ui_design.md` §4).
  - Under **MENU** it shows "Slot N · <play time>".
  - Close is gold. Save shows "Slot N". Save as copy shows "To another slot". Leave to main menu shows "Title screen".
  - Leave and Exit turn red on hover.
  - Save as copy's page is titled **SAVE AS COPY**, "Pick a slot", with a Back row.
- **Built in V1.3, locked in V1.4.2, removed in V1.4.3:** a **Difficulty** row (skull icon) after Save as copy; its hint named the current level (Easy ×0.8, Normal ×1.0, Hard ×1.1, Extreme ×1.3).
  - V1.3 let you change it here, on a page titled **DIFFICULTY**. In V1.4.2 the row was greyed and couldn't be pressed. Its hover text said "Set when this game started". The level is picked once, on the title screen's new-game page, and an old save keeps the level it has.
  - The DIFFICULTY page, its toast and its ESC step are gone.
  - **Since V1.4.3 the row is gone too.** Difficulty is chosen only on the title's difficulty page after "New game", and is never shown or changed during a game. The rows are Close, Save, Save as copy, Settings, Leave to main menu and Exit the game.

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
  - *(V1.4.2: while the gear menu is open, ESC goes to it first, before a pop-up that is hidden under it. So a tree purchase pop-up stays open when the menu closes.)*
- **Arrow keys and Enter (V1.4.2):** with the gear menu open, Up and Down light a row (the list wraps) and Enter presses it. The slot page works the same, and skips the greyed current slot. Nothing is lit until the first arrow key. Space is untouched: it is still Center camera. Confirm pop-ups open with their first button lit, so Enter answers it; Left and Right move across the buttons (`ui_design.md`, "Menu keys").
- **The skin preview stops while covered (V1.4.2):** an open Skin Shop preview is frozen while the gear menu, Settings or a confirm pop-up covers it, and resumes when it is closed. *(V1.4.3: Settings' backdrop is see-through, so while it is open the Tree, the Skin Shop and the Journey all stop moving and redrawing, and resume when it closes.)*
- **Debug table (F3 + Q, hidden by default):** an **Essences** tab (blue +100 / +1000 / +10000, orange and purple +1 / +10 / +100, Reset for each) and a **Progress** tab (Acts cleared 0–6, Max tree (free), Clear tree (no refund), Reset progress: a new game in memory). Nothing there saves. *(V1.5.0: F3 + Q opens it, and the stage's debug table, only in a debug build. In the released game it does nothing.)*

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
  3. The slot list goes back to the menu; an open gear menu closes. *(V1.4.2: the gear menu comes before step 2, so a pop-up under it stays open.)*
  4. Otherwise ESC opens the gear menu.
- **Sounds:** every styled button clicks softly (−10 dB), on the main screen and the title too (`ui_design.md` §8).

### Built in Phase 10
- **A new background.** The plain gradient is gone. `MainBackdrop` draws a scene behind the sections, set by the open section:

| Scene | Behind | Look |
|---|---|---|
| Grove at night | Evolution Tree and Journey | A deep teal to indigo night sky with 220 stars, ten brighter stars with soft glints along the top bar, three mist bands, a vignette, and 40 warm light motes rising slowly. It shows around the framed tree page and Journey map. There is no moon or hill here: the tree's pages draw their own. |
| Hall of Relics | Skin Shop | A stone gallery with one lit arch per skin card (Section 2) |

- Only the motes move; the rest is drawn once per scene. The backdrop never takes the mouse.
- **FREE badge.** A small green-gold "FREE" pill, pulsing slowly, sits at the top right of the bottom bar's **Evolution Tree** button whenever the tree has a free upgrade to claim, such as Ghost after 1-1 (game design doc §11). It goes once the upgrade is claimed. *(V1.5.0: R's rank 1 is one too, once Act 2 is cleared, the passive is bought and Q + W + E reach 5.)* The tree's tabs and nodes wear the same badge (Section 1).
- **ESC** in the Evolution Tree clears the picked node; the info column goes back to the branch's summary.

---

## Section 1 – Evolution Tree

Reference: a node-graph tree with icons in square frames connected by lines (see the screenshot the design was based on).

### Layout
- **One big map shown as a forest:** no separate pages for skills, stats, equipment, summoners and economy. Every branch lives on the same canvas, each growing from its own roots. *(Phase 10: one page per branch, with tabs. See "Built in Phase 10".)*
- Each upgrade is a **square node with an icon**. Lines connect a node to its requirements.
- The player can **drag to move** around the map and **zoom** with the mouse wheel. *(Phase 10: no panning or zoom; each page fits the screen.)*
- Essences in the top-left.
- **Reset tree** button (costs 5 purple, refunds all blue and orange).
- *(V2.0)* **The forge** (`ForgeBar`, a child of `TreeSection`) sits left of Reset tree on every branch page, 20 px clear of it: two buttons, **120 [blue] → 1 [orange]** and **1200 [blue] → 10 [orange]**, with the essence icons. A button forges that much orange from blue at once, with the coin sound, and the essences bar updates. It is greyed out while the blue is short, with the hover "Needs 120 blue essence" ("Needs 1200 blue essence"); when it is lit the hover reads "Forge 1 orange essence from 120 blue. This cannot be undone." ("Forge 10 orange essence from 1200 blue. ..."). There is no confirm. The forge changes the essences in memory only, like a purchase: the next Save, Start or Yes keeps it. A tree reset does not give the blue back, and forged orange stays (game design doc §9, §11).

### Node states
| State | Look |
|---|---|
| Hidden (requirements not met) | Dark frame with a **"?"** |
| Available, can afford | Normal frame |
| Available, can't afford | **Red** frame |
| Bought (more levels left) | Lit frame, line to it becomes bright |
| Maxed | **Green** frame |

### Node info panel
Clicking a node opens a panel (bottom-right, like the reference): *(Phase 10: a column on the right that is always shown.)*
- **Name** of the upgrade
- **Current value → next value** (e.g. `+40% → +60%`)
- **Short description**
- **Level:** e.g. `LVL 2 / 5`
- **Cost bar:** shows owned essence against the cost, and works as the **buy button** *(V1.3.1: it asks first; see "Built in V1.3.1")*

### Built in Phase 5

**31 nodes** in five groves, left to right: Skills, Stats, Equipment, Economy, Summoners. Costs and what each level gives are in the game design doc §11; this table is where each node sits. Grid = (column, row up from the ground); one cell is 150 px.

*(Phase 10: 34 nodes on five pages, Equipment renamed Backpack, and new grids; see "Built in Phase 10". R's and Ghost's requirements changed too (game design doc §11). V1.4 adds the Boots node: 35.)*

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
- **Cost bar** (400 × 56, the buy button): for each essence the next level needs, its icon and "owned / cost" (red when short). A gold fill shows how close the player is (the smallest share over the kinds needed). It can only be clicked when the level can be bought; a click buys it with a coin sound. *(V1.3.1: a click asks first, so a double-click can't buy two levels; see "Built in V1.3.1".)* It reads **MAXED** (green), **LOCKED** (grey) or **Free** (E's first level after Act 1). *(Since Phase 10 also Ghost after 1-1, and LOCKED for a bought node whose next level is closed. Since V1.5.0 also R's rank 1 after Act 2.)*

**Reset tree** (top-right): "Reset tree 5" with the purple icon. Disabled until something is bought and 5 purple are owned. It asks "Reset the Evolution Tree for 5 purple essence? Every blue and orange essence spent comes back." Buying and resetting never save by themselves. *(Since V1.4.1: disabled until some blue or orange essence is spent, since free levels alone (E after Act 1, Ghost, and since V1.5.0 R's rank 1 after Act 2) give nothing back; hovering it then says "Nothing to refund: no blue or orange essence spent", or "Needs 5 purple essence". The question names the refund: "… 700 blue and 3 orange essence come back.")*

### Built in Phase 9
**The tree shows the stage's icons.** The skill nodes (Q, W, E, R, the passive) use the HUD's skill icons (`assets/art/ui/icon_*.svg`). The six spell nodes use the summoner art (`assets/art/summoners/*.svg`), as the HUD and the Journey's spells do. The 11 old `tree/` copies are gone. The six spell upgrades (`tree/*_upgrade.svg`) are redrawn from their spell's art with three outlined gold chevrons, so each still matches its spell. Every other node keeps its `tree/<id>.svg`.

### Built in Phase 10
**Branch pages with tabs** (the user's choice in planning). The forest strip, its panning and its zoom are gone. The section is laid out like the Journey: a framed page on the left and a column on the right.

| Part | On screen (1920 × 1080) |
|---|---|
| The page (`TreePage`): one per branch, one shown | x 32–1448, y 80–920 (1416 × 840) |
| The tabs (`BranchTabs`) | Under the page, y 920–984, 24 px in from its sides |
| The info column (`NodeInfoPanel`), always shown | x 1448–1888, y 80–984 (440 × 904): the Journey panel's size, frame and glow |
| Reset tree | The page's top right, as before |

**Tabs:** Skills, Stats, Backpack, Economy, Summoners. Each shows an icon, the name and "levels bought / all" ("Stats 3 / 45"). The open tab is lit gold. A tab with a free upgrade wears a FREE badge on its top edge. The tree opens on the first branch with a free upgrade, otherwise on Skills. This is chosen each time the main screen opens.

**Each page** draws one branch large, as a tree in a night grove:
- a starry sky, a moon, hills, dark side trees and a green canopy haze;
- a glowing trunk rising from roots, and curved boughs out to every node;
- a vine for each requirement link, wound along the boughs: dim until the node that needs it is bought, then gold;
- faint leaves and 28 drifting light motes;
- at the top left, "EVOLUTION TREE", the branch's name and a one-line blurb.

| Page | Layout |
|---|---|
| Skills | Q, W and E along the bottom, the passive above W, and R crowning the trunk. R wears a ring of 13 segments, lit up to the Q + W + E total, with marks at 5, 9 and 13. |
| Stats | Three boughs of three, with captions: OFFENSE (AD, AP, Attack Speed), DEFENSE on the trunk (Health, Armor, Magic Resist) and SUSTAIN (Mana, Health Regen, Mana Regen). |
| Backpack | Equip Slots, Boots (since V1.4, on the trunk between them) and Backpack Slots, each over a plaque. Equip Slots shows the 6 slots: open ones lit, the rest locked, with "Act 2" under slots 3–4 and "Act 4" under slots 5–6 (green once that level is open). Boots shows Boots of Speed and Slightly Magical Boots, each lit once bought ("1 / 2"). Backpack Slots shows the 9 × 6 backpack with the open cells lit ("5 / 54"). The next level's slots or cells are outlined once it can be bought. |
| Economy | REWARDS (Stage Gold, Bonus XP, Essence Drops) and MERCHANT (Merchant Stock, Cheaper Refresh). |
| Summoners | The six spells along the bottom, each spell's upgrade above it, and the Second Summoner Slot at the top of the trunk. |

**Nodes** are 96 px (72 before), with a larger level badge and the node's name on a dark plate under it ("???" while hidden). Two new marks:
- a small **lock** at the bottom-right corner when the node is bought but its next level is closed (R at rank 1 below 9 Q + W + E; Equip Slots at level 1 before Act 2);
- a **FREE** badge at the top-right corner when its next level is free (Ghost after 1-1; since V1.5.0 R after Act 2).

**The info column:**
- **Nothing picked:** "EVOLUTION TREE", the branch's name and blurb, "Levels bought 3 / 45" with a gold bar, "Pick a node", then one row per node of the branch (icon, name, level), grouped under the page's captions. A click on a row picks that node.
- **A node picked:** the branch, the name, a 96 px portrait in the node's state colours, "LVL 1 / 3", "Rank 1 → Rank 2", and the description. For R, "Q + W + E ranks: 7 / 9". In red, what the next level still needs ("Requires: 9 levels in Q + W + E (now 7)"). Then LEVELS: one row per level with its value and cost ("Free" when it costs nothing), the bought ones lit and the next one framed. The cost bar sits at the bottom, like the Journey's Start.
- ESC or a tab click clears the pick.

**FREE badges** (`FreeBadge`): a 48 × 20 pill reading "FREE" in 13 px, green with a gold border, pulsing every 1.8 s. It shows on the bottom bar's Evolution Tree button, the tabs and the nodes, for any next level whose rules are met and which costs nothing. It updates whenever the tree changes.

### Built in V1.2
**A living lantern tree** (`TreeArt`) replaces the bare trunk.
- **Trunk:** warm bark with a root flare, grooves, a knot and a moonlit rim on its right.
- **Roots:** they grip a grassy mound with glowing mushrooms.
- **Boughs:** they taper out to the nodes, with leafy twigs.
- **Canopy:** layered leaf clumps (dark, mid, light) around every limb group. None covers the header or Reset tree, and the leaves darken under each node.
- **Lanterns:** a small lantern hangs from each bough that has room for one and **lights once its node is bought**.
- **Light flow:** gold motes climb from the roots to every bought node. None on Low effects.

**Node states, at a glance:**

| State | Icon | Frame | Level bar | Extra |
|---|---|---|---|---|
| Hidden | "?" | dark | none | |
| Not bought (open or too dear) | greyscale | thin silver | empty | ▲ (gold, top-left) while you can buy it now |
| In progress | colour | gold, gold glow | lit gold up to the level | ▲ while the next level can be bought; lock when it is closed |
| Done | colour | green, green glow | all green, "MAX" | ✔ crest (top-right) |

- **The badge** under a node is a level bar: the number over one segment per level.
- **FREE** still shows on a free upgrade, in place of ▲.
- **The info column's list and portrait** show not-bought icons in greyscale too.

### Built in V1.3.1

**Buying a tree level asks first.** The cost bar opens a pop-up (`TreePurchasePopup`) over the tree, on the menus' ornate card. A double-click on the bar used to buy two levels; now its second click lands on the pop-up.
- **Title:** **BUY UPGRADE**, with the node's name under it.
- **A table:**

| Row | Shows |
|---|---|
| Level | "LVL 2 → 3 / 5" |
| Effect | the value now → after ("+8 AD → +12 AD") |
| Price | the blue and orange it costs, or **Free** |
| You have | blue and orange owned (hidden when free) |
| After purchase | what is left, red if short (hidden when free) |

- A note: "Only Reset tree gives essence back."
- **Buy** (gold) buys one level with the coin sound and closes; it is off while the level can't be bought. **Cancel** or **ESC** closes it and keeps the pick. Hiding the tree closes it.

### Built in V1.4

**The Boots node** (`data/tree/boots.tres`) joins the Backpack page: 35 nodes, and "Backpack 0 / 14".
- **Where:** grid (2, 1.5), on the trunk between the Equip Slots and Backpack Slots plaques, with 20 px between the three plaques.
- **Levels:** 1 Boots of Speed (300 blue), 2 Slightly Magical Boots (800 blue + 10 orange). The info panel reads "None → Boots of Speed → Slightly Magical Boots" (the node's `level_texts`).
- **Its plaque:** BOOTS and "level / 2", the two boots side by side with their names (faded until bought, the next one outlined when it can be bought), and "Worn on every map."
- **The page's blurb:** "Equip slots for gear, boots to wear, and cells to carry more."

---

### Built in V2.1
- **Sections** swap with a crossfade, the section bar's highlight slides, and the essence counts count.
- **The tree's side panel** rests on "Levels bought". Hidden nodes are counted ("%d more to discover"), not listed. A known node's panel ends with a NODES list of the branch's known nodes (one column up to 5, else two; the open node is framed; a click steps to it). The buy bar reads "Buy ...". Maxed and Locked are in sentence case.
- The gear menu and the toast move in the same way; the toast sits on a small plate.

## Section 2 – Skin Shop

A **full-screen** section showing every skin, including **Classic Lucian**.

### Each skin card
- **Big art** of the skin.
- Below the art:
  - **Bonuses** (green) and **weaknesses** (red)
  - A **short description** of its playstyle
  - A small **Preview** button (V1.1), for owned and unowned skins alike
  - **Button:**

| Situation | Button |
|---|---|
| Not owned | **Purchase** (shows purple cost) |
| Owned, not equipped | **Equip** |
| Currently equipped | **Equipped** (disabled) |

- Classic Lucian is always owned, so it shows **Equip** or **Equipped**.
- *(V2.0)* The big art on each card is a new front-facing bust with its own background: Classic in teal mist, High Noon under a low sun over mesas, PROJECT on a neon grid with a holo ring, Pulsefire in a time rift with a clock face, Vampire under a blood moon with bats and spires. The HUD's round portrait uses the same pictures.

### Skins
| Skin | Cost | Bonus | Weakness |
|---|---|---|---|
| Classic | Free | — | — |
| High Noon | 25 purple | +15% AD | −15% Attack Speed |
| PROJECT | 30 purple | +20% Attack Speed, +8% Move Speed | −10% AD |
| Pulsefire | 20 purple | +30% W Damage, +25 Ability Haste | −10% Attack Speed |
| Vampire | 25 purple | +15% Lifesteal, kills heal 2% max HP | −20% max HP |

*(V1.5.0: PROJECT's move speed was +15%; Pulsefire gave +15% AP and +15 ability haste. The cards and the purchase pop-up show the new lines.)*

### Built in Phase 5
- Five cards (320 × 640) in a centered row: the portrait (288 px), the name, bonuses in green, weaknesses in red ("—" for Classic), the playstyle, and the button at the bottom.
- The equipped card has a bright gold border.
- **Purchase 25** shows the purple icon. Without enough purple it is disabled and its price turns red.
- **Buying doesn't equip**; there is no confirm step. Neither buying nor equipping saves by itself.
- In a stage, Lucian's body sprite and the HUD portrait follow the equipped skin. How the stat changes work is in the game design doc §10.

### Built in Phase 10
**The Hall of Relics**, a background of its own (`MainBackdrop`'s gallery scene), drawn once:
- A stone wall of block courses under a cornice.
- One tall arch behind each card, centred on it, with 11 voussoirs and a keystone gem in that skin's colour. More arches, unlit, run on past the five to the screen's edges.
- In each lit arch: an iron lantern hanging from the keystone on a chain, its glass and flame in the skin's colour, a soft light cone down to the floor, a glow behind the card, and a plinth lit in that colour.
- Fluted piers between the arches, each with a navy banner trimmed in gold.
- A polished floor of tiles in perspective, with a pool of light at each plinth, and the light cones, the cards and the piers mirrored in it, dark.
- 60 dust motes drift in the beams and over the pools of light. Only they move.

| Skin | Its colour |
|---|---|
| Classic | Gold `#f2c75c` |
| High Noon | Amber `#ff8f3a` |
| PROJECT | Cyan `#3fe6ff` |
| Pulsefire | Blue `#4a8dff` |
| Vampire | Crimson `#e8283f` |

**Lucian's second gun is Senna's** on every skin's body in a stage (game design doc §10). The cards' portraits are unchanged.

### Built in V1.1
**The Preview pop-up** plays a skin's skill effects before you buy it.
- **Size and title:** about 1200 x 680 px, a dark panel with the title "<Skin> · Preview". Clicks outside the panel are blocked.
- **The stage:** a clipped floor. Lucian (that skin's body) stands on the left facing right, and the training dummy stands on the right, about 700 px away. Effects play at game size.
- **Buttons:** Q, W, E, R, Attack and ▶ All.
  - Each of the first five plays that one effect: Q's beam, W's missile and cross, E's dash and trail, R's 22 bullets over 3 s with the muzzle flash, and three basic shots.
  - ▶ All plays the five in order, with a 0.6 s gap, and loops. **The loop starts by itself when the pop-up opens.** Pressing Q, W, E, R or Attack stops the loop and plays that one. ▶ All starts it again.
- **Closing:** the ✕ button or ESC. The pop-up also closes if you leave the Skin Shop. Closing frees everything it spawned.
- **No damage, nothing saved.** The shots hit only enemies, and the main screen has none.
- **Sound** plays on the SFX bus.
- **Low effects** applies: only the main shapes, and no muzzle flash or dash trail.

### Built in V1.2
**Purchase asks first.** A card's **Purchase** opens a pop-up (`SkinPurchasePopup`) over the blurred shop, on the menus' ornate card.
- **Title:** **PURCHASE SKIN**, with the skin's name under it.
- **The portrait:** in a frame lit with the skin's colour.
- **A table:**

| Row | Shows |
|---|---|
| Bonuses | green |
| Weaknesses | red |
| Price | the cost in purple |
| You have | purple owned |
| After purchase | what is left (red if short) |

- **A note:** "Buying does not equip it."
- **Purchase N** (gold) buys and closes. It is off while the price can't be paid.
- **Cancel**, or ESC, closes and spends nothing.
- **Leaving the Skin Shop** closes it.
- **The Preview and the purchase pop-up** replace each other.

---

### Built in V2.1
The skin preview uses the menus' backdrop and a plate; the price buttons are one centred group, and Classic shows no dashes.

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
  - One card per stage (200 × 230): "Stage 2", its waves ("4 waves + mini boss wave", "5 waves + boss wave"; V2.0: Act 2 reads "4 waves", "5 waves" and "5 waves + boss wave"), a skull (grey for a mini boss, red for the boss).
  - A locked card shows a chain; a cleared card gets a green check and a green frame.
  - **Start** is disabled ("Acts come in a later phase"). *(Acts 1–2 start since Phase 6, Acts 3–4 since Phase 7, Acts 5–6 since Phase 8.)*
- **Training page:** what Training is ("Practice on training dummies with what you have bought in the Evolution Tree and your equipped skin. No essences are earned. Leave from the ESC menu to come back here.") and a gold **Start Training** button.
- **Endless page:** the rules (waves never end, a mini boss every 5 waves, an act boss every 10, a modifier pick every 10), a map choice (Random or one of the six act maps; since V1.4.2 it is kept in the save, with its other data, and is written by the next save, such as the one Start makes), "Best wave: N" and **Start** disabled ("Endless comes in a later phase"). *(Start works since Phase 9.)*
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
- **Picking a stage:** a click on an open card picks it; a gold outline marks it. A locked card can't be picked. The page opens on the first open stage not cleared yet, else the last open one. *(V1.5.0: the Journey opens on the first open stage not cleared in the whole game, else Training; see "Which place opens".)*
- **Start** plays the picked stage: "Start" for a one-stage act, "Start stage 2" otherwise. The stage is built from the save like Training, plus its waves, map and boss. Act 1's first play is the tutorial (`act1_the_loss.md`).
- **Acts 3–6:** the cards can be picked, but Start stays disabled ("Act 3 comes in a later phase"). Endless's Start is still disabled. *(Acts 3–4 start since Phase 7, Acts 5–6 since Phase 8, Endless since Phase 9.)*
- **Which tab opens:**
  - after a stage (Continue on its result, or Leave this stage), the act just played;
  - otherwise (a loaded slot, after Training), the first act with an open stage not cleared yet, else Training.
  - *(V1.5.0: always the second rule, after a stage too. See "Which place opens" at the end.)*
- A cleared stage can be played again. Act 1's card always reads "2 waves + boss wave", though a replay has no boss.

### Built in Phase 7
**Acts 3 and 4 start**, like Acts 1 and 2: an act's Start works as soon as its first stage has waves.
- **Act 3's cards:** "3 waves", "4 waves + mini boss" (grey skull), "4 waves", "5 waves + mini boss" (grey skull), "5 waves + boss wave" (red skull). The drake comes last in the last wave, not in a wave of its own, so its card no longer says "+ mini boss wave". *(V2.0: "5 waves", "6 waves + mini boss", "6 waves", "7 waves + mini boss", "7 waves + boss wave".)*
- **Act 4's cards:** "4 waves", "5 waves", "5 waves + boss wave" (red skull). *(V2.0: "6 waves", "7 waves", "7 waves + boss wave".)*
- **Acts 5–6** can be picked once open, but Start stays disabled ("Act 5 comes in a later phase"). *(They start since Phase 8.)*
- **Endless** still opens once Act 3 is cleared, and its Start stays disabled ("Endless comes in a later phase"). *(Start works since Phase 9.)*
- **The end screen's buttons start stages directly** (`ui_design.md`, "Stage result"):
  - **Retry** starts the same stage again, built fresh from the save, without passing through the main screen.
  - **Next stage** starts the next one: 1-1 → 2-1, 2-3 → 3-1, 3-2 → 3-3. It shows only after a clear, when that stage can be played.
  - **Main screen** opens the main screen on the act just played, as Continue did. *(V1.5.0: on the latest open stage instead, or Training once every stage is cleared.)*
  - Each saves first. If the save fails, Retry and Next land on the main screen instead, with the red "Could not save" toast.
- After Retry or Next, the next end screen leads back here the same way, so the main screen only shows when the player asks for it.

### Built in Phase 8
**Acts 5 and 6 start.** An act's Start works as soon as `WavePlan` has the act's first stage (5-1, 6-1) and the act is open: Act 5 once Act 4 is cleared, Act 6 once Act 5 is cleared. All 22 stages can now be played.
- **Act 5's cards:** "5 waves", "5 waves + mini boss" (grey skull), "6 waves", "6 waves + mini boss" (grey skull), "6 waves + boss wave" (red skull). *(V2.0: "6 waves", "6 waves + mini boss", "7 waves", "7 waves + mini boss", "7 waves + boss wave".)*
- **Act 6's cards:** "6 waves", "6 waves + mini boss", "7 waves", "7 waves + mini boss", "7 waves + boss wave". *(V2.0: "8 waves", "8 waves + mini boss", "9 waves", "9 waves + mini boss", "9 waves + boss wave".)*
- **The first clear of 6-5** shows `TheEndScreen` after the stage-end screen's button (`ui_design.md`), then the main screen on Act 6 (or 6-5 again after Retry). Next stage after 6-5 goes to the main screen as before. *(V1.5.0: the main screen opens on Training then, since every stage is cleared.)*
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
- **The road** is a cobbled stone path, one curve through all 22 stages in play order, with a bend between rows. It glows gold up to the latest cleared stage and is dim beyond. *(V2.0: the lit part has a layered warm glow, and small lights run along it from the last cleared stage to the next; a new save has none. They move only with effects on.)*

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
| Cleared | A gold rim, a warm glow and a green check *(V2.0: a larger check)* |
| Open, not cleared | A pulse ring every 1.8 s and a glow *(V2.0: a gold glow and ring, two pulse rings half a beat apart, and a stronger glow on the next stage; with effects off, one still faint ring)* |
| Locked, in an open act | Dim, with a small lock *(V2.0: a stone medallion with a readable number)* |
| In a locked act | Under the region's fog, with a chain X and a lock; the region's name turns grey *(V2.0: a thin cool-grey fog at 50% (was a near-black 84%) with drifting wisps, so the dimmed terrain shows through; the stages are stone medallions with a readable number)* |
| Picked | A white outline *(V2.0: stronger)* |
| Hovered | A faint outline *(V2.0: stronger)* |

- The Endless portal is chained and dim, with a lock, until Act 3 is cleared.
- *(V1.4.3)* The portal's swirl and the token's bob run only while the Journey shows. On the Tree or the Skin Shop they stop, and a place that opens meanwhile starts when the Journey shows again. *(V2.0: the pulse rings, the fog's wisps and the road's lights are extras: they run only while the Journey shows and effects are on (`Juice.on()`). With effects off the Journey is still and complete: the pulse is one faint ring, the road glows without lights and the fog has no wisps.)*
- *(V2.0)* **The redraw:**
  - **Bosses** wear a gold laurel around their medallion: bronze before the stage is cleared, bright once it is (`has_laurel()`).
  - **Act titles** ("ACT 3") have a gold rule with a diamond. A cleared act has a green check after its "ACT n", and the current act's title is the brightest.
  - **Fog:** the terrain of a locked act shows dimmed through the fog, and its chains and locks stay (see the states above).
- **Hover texts:**
  - A stage: its name and waves ("Stage 3-4 · The Jungle", "5 waves + mini boss"; V2.0: "7 waves + mini boss"), plus "Clear 3-3 first" when it is locked in an open act.
  - A locked act, its region or its stages: "Clear Act 4 first".
  - Training: "Training". Endless: "Endless" and "Best wave: 22", or "Clear Act 3 first" while locked.
- **Lucian's token:** the equipped skin's portrait (48 px, a gold ring and a pointer) bobs over the next stage, the first open one not yet cleared. Once every stage is cleared, it is gone. *(V1.4.3: it floats over the picked place instead, a stage, Training or the Endless portal, and moves when another is picked. The next stage has no mark of its own: the Journey opens on it (below), or on Training once every stage is cleared, so the token starts there.)*
- A click on an open place picks it. A locked place can't be picked.

**The side panel**, by what is picked. A soft glow in the place's color falls from its top.
- **A stage:**
  - "ACT 3 · THE JUNGLE" and "Stage 3-4".
  - The boss or mini boss: a round 112 px portrait, a "Boss" or "Mini boss" tag, and its name.
  - Its purple: "First kill: +5" or "+1 again". 1-1 once cleared reads "No boss on replays" (dimmed): Act 1's replays have no Thresh.
  - The waves, with the old cards' strings ("5 waves + mini boss", "5 waves + boss wave").
  - The act's story line.
  - "Cleared" (green, with a check) or "Not cleared yet".
  - *(V2.0)* **Resolve:** while the stage has Resolve stacks, a green line with the Resolve icon under the status: "Resolve 3 / 5: +30% damage, -30% taken" (the share follows the difficulty: 10% a stack on Easy and Normal, 5% on Hard, 3% on Extreme). Hovering it says "Lucian fell here 3 times." and "Each defeat makes this stage a little easier, up to 5 times, until it is cleared." There is no line with no stacks, on a cleared stage, with the Gameplay setting off or on Extreme. Game design doc §3.
  - **ENEMIES:** a 44 px round icon for each of the stage's enemies, once each, in wave order (the mini boss is in the portrait). Each icon's hover is its name. *(V2.0: the icons are 52 px and sit in a dark tray anchored above Start.)*
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
1. ~~After a story stage: the act just played, at its first open stage not cleared yet (its last when all are).~~
2. ~~After an Endless run (Main screen, Leave, or a failed save on Retry): Endless, with the run's map still chosen, if Endless is open.~~
3. Otherwise (a loaded slot, after Training): the next stage, the first open one not yet cleared. *(Since V1.4.3 the token floats over the pick, so it starts there.)*
4. With every stage cleared: Training.

*(V1.5.0: rules 1 and 2 are gone, so the Journey always opens on the latest open stage, the first open one not yet cleared (3), or on Training once every stage is cleared (4). That holds after a story stage, after Training, after Endless and on a loaded slot. After the tutorial it is 2-1, since Act 1 has one stage, so a new player's first Start goes on instead of playing 1-1 again. Switching between the Tree, the Skin Shop and the Journey keeps the player's pick. The Endless map choice is still saved, so picking the portal shows it.)*

A pick that becomes locked (the debug table) falls back the same way. Nothing here saves.

### Built in V2.1
- The Journey panel reads top to bottom: the facts, ENEMIES, then the spells and Start at its foot. The spell menu opens upward inside the panel.
- The panel's body turns over when the place changes, and the selection ring fades between places.

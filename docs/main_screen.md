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
| **Leave to main menu** | Asks **"Save before leaving?"** (Yes / No), then returns to the title screen / save slot selection |
| **Exit the game** | Asks **"Save before leaving?"** (Yes / No), then closes the game |

- **Nothing on the main screen saves by itself.** Evolution Tree and Skin Shop purchases are kept by **Save**, a **Yes** when leaving, or the auto-save when the next stage is done (see the game design doc §15).

### Navigation
- **Sections** (Evolution Tree, Skin Shop, Journey): switched with a bar at the **bottom** of the screen.
- **Sub-sections** (e.g. Act 1–6, Training, Endless): tabs at the **top** of the screen.

### Built in Phase 5
- **The game opens on the main screen**, on **Journey → Training**. It loads save slot 1, or starts a new game when there is none (no file is written until the first save).
- **Top bar** (72 px): the gear button (48 px), then blue, orange and purple essence (36 px icon and the amount). Hovering an essence shows where it drops and what it buys.
- **Bottom bar** (88 px): **Evolution Tree · Skin Shop · Journey**, three 280 × 60 buttons; the open section's button is lit.
- **Gear menu** (a centered pop-up over a dark backdrop, title "MENU"):

| Button | Built |
|---|---|
| Close | Closes the pop-up |
| Save | Saves to the current slot (slot 1 for now) and closes the pop-up. A toast says "Saved to slot 1" (red "Could not save" if writing failed) |
| Save as copy | Turns the pop-up into a slot list: "Slot 1 (current)" (disabled), then "Slot 2 · empty" or "Slot 2 · saved 2026-10-28 14:03", and Back. An empty slot is written at once; a used one asks **"Overwrite slot 2?"** (Yes / No). Toast: "Copied to slot 2". The current slot stays slot 1 |
| Settings | The same Settings screen as in a stage; Back returns to the menu |
| Leave to main menu | **Disabled** until the title screen exists. Hover: "The title screen comes later" |
| Exit the game | Asks **"Save before leaving?"** (Yes / No), then closes the game. Closing the window asks the same |

- **Toast:** a short message at the top center, inside the top bar, fading out over 1.6 s.
- **ESC**, in this order:
  1. On a Yes / No question, ESC answers **No** (Overwrite, Reset tree); "Save before leaving?" needs a click. Settings reads its own ESC, as in a stage.
  2. An open pop-up in the section closes: the spell menu in Journey, the node info panel in the Evolution Tree.
  3. The slot list goes back to the menu; an open gear menu closes.
  4. Otherwise ESC opens the gear menu.
- **Debug table (F3 + Q, hidden by default):** an **Essences** tab (blue +100 / +1000 / +10000, orange and purple +1 / +10 / +100, Reset for each) and a **Progress** tab (Acts cleared 0–6, Max tree (free), Clear tree (no refund), Reset progress: a new game in memory). Nothing there saves.

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
| Skills | Q – Piercing Light (`skill_q`) | (1, 0) | 5 | — |
| Skills | W – Ardent Blaze (`skill_w`) | (2, 0) | 5 | — |
| Skills | E – Relentless Pursuit (`skill_e`) | (3, 0) | 5 | Clear Act 1 |
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

### Unlock rules
| Tab | Unlocks when |
|---|---|
| Act 1 | Always open |
| Act 2–6 | The previous act is cleared |
| Endless | **Act 3** is cleared |

- Locked tabs are covered by a **chain lock**.

### Inside an act tab
- Shows the act's stages in order.
- A stage unlocks when the previous stage is cleared.
- Cleared stages can be replayed.
- Mini boss and boss stages are marked with a **skull** icon.

### Built in Phase 5
Only **Training** can be started; acts and Endless are shown and unlock as designed, but their Start buttons wait for a later phase.

- **Tabs** (150 × 48): the open one is lit. It opens on **Training**. A locked tab is disabled, with a small chain left of its name; hovering says "Clear Act 1 first" (Endless: "Clear Act 3 first").
- **Act page:**
  - The title ("ACT 3 · THE JUNGLE") and the act's story line.
  - One card per stage (200 × 230): "Stage 2", its waves ("4 waves + mini boss wave", "5 waves + boss wave"), a skull (grey for a mini boss, red for the boss).
  - A locked card shows a chain; a cleared card gets a green check and a green frame.
  - **Start** is disabled ("Acts come in a later phase").
- **Training page:** what Training is ("Practice on training dummies with what you have bought in the Evolution Tree and your equipped skin. No essences are earned. Leave from the ESC menu to come back here.") and a gold **Start Training** button.
- **Endless page:** the rules (waves never end, a mini boss every 5 waves, an act boss every 10, a modifier pick every 10), a map choice (Random or one of the six act maps; kept on the page, not saved yet), "Best wave: N" and **Start** disabled ("Endless comes in a later phase").
- **Loadout panel** (right side, on every tab): "SUMMONER SPELLS" with two 72 px buttons under their keys (**D** and **F**, following the bindings).
  - A click opens a small menu beside the panel: one icon per **bought** spell (the one already there is lit) and **None**. It closes on a pick, ESC, a click outside, or a second click on the same key.
  - Picking the spell that is on the other key swaps the two.
  - With no spell bought, the menu reads "Buy spells in the Evolution Tree".
  - **F** is chained and disabled until the Second Summoner Slot is bought ("Buy the 2nd summoner slot in the Evolution Tree").
  - A spell no longer bought (after a tree reset) shows as empty; the pick itself is kept.
  - The choice is saved with the progress.
- **Start Training** builds the stage from the save: only bought ranks can be learned, the passive only works once bought, the equip slots, shop items, refresh cost and stat bonuses come from the tree, D and F from the loadout (F stays empty without the 2nd slot), and the look from the skin. The stage debug table can still change all of this for that run.

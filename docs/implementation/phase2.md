# Phase 2 — Menu, backpack, items, crafting, tooltips

## Context

Phase 1 (`docs/implementation/phase1.md`) gave a playable slice: Lucian moves, attacks the training dummy, casts P/Q/W/E/R and levels up, with a HUD and an F3+Q debug table. Items, the backpack and the menus are designed in `docs/ui_design.md` §2 and §4 and in `docs/lucian_game_design.md` §6, but there is no code for them yet.

Phase 2 adds:
- the ESC menu
- the backpack screen (P) with drag and drop
- the 8 fragments and 33 legendaries, with crafting and the recipe table
- LoL-style hover tooltips for items and skills

The merchant, enemies, drops and potions come in later phases and build on these parts.

### Decisions made with the user
| Topic | Decision |
|---|---|
| "Interaction item system" | Backpack drag & drop (move, swap, equip into 1–6, drop outside to cancel) **and** item effects in combat |
| Item power | **Stats only.** Passives and actives are written in full in the tooltips and implemented in the phase that adds real enemies. |
| Icons | Hand-written SVG for all 41 items (same approach as the Phase 1 skill icons) |
| ESC menu | Resume / Settings / Leave this stage / Exit the game. Only **Resume** and **Exit the game** (quits the app) work. The other two are disabled and show a "Not available yet" tooltip. |

### Defaults chosen during planning
- **Items come from the debug table.** Nothing dies and there is no merchant yet. The Items section has:
  - an item picker with a Give button
  - Random fragment
  - Clear backpack
  - equip slots 1–6
  - "Lucian HP 50%", so lifesteal can be seen
  - a readout of AH / life steal / omnivamp / pen
- **All 6 equip slots unlocked by default**, like Phase 1's "every rank counts as bought". `Inventory.unlocked_equip` drives the chain locks.
  - If the debug count drops, items in slots that become locked move to the backpack.
- **Only equip slots 1–6 give stats.** The backpack is storage. Duplicate items stack their stats.
- **Not in Phase 2:**
  - potions and the right-click Use
  - selling: the 7th equip-row cell is drawn empty and will become the red sell slot later
  - item actives on 1–6
  - shared item cooldowns
  - unique-passive rules
  - crit-damage items: Infinity Edge's bonus is passive text for now
- **Pause.** Opening the backpack or the menu sets `get_tree().paused`.
  - Stopped: Lucian, the controller, the camera, enemies and projectiles. Their timers all run in `_physics_process`, so cooldowns, regen and buffs freeze.
  - Still running (`PROCESS_MODE_ALWAYS`): the HUD, the debug table, the backpack, the menu and the tooltip layer.
  - The controller disarms attack-move and drops the RMB hold on `NOTIFICATION_PAUSED`.
  - No rank-ups while paused: the HUD "+" hides, to match Ctrl+Q, which is paused with the controller.
- **Keys.** P toggles the backpack, but not while the menu is open. ESC closes the backpack if it is open; otherwise it toggles the menu.
  - Both are read in `_input`, so a focused debug SpinBox can't eat them.
  - Closing the backpack mid-drag returns the item to its cell.
- **Tooltips:**
  - They appear after **1.0 s** of hovering, even if the mouse moves a little inside the control.
  - Skill tooltips are anchored above the HUD bar, like LoL. Item tooltips go beside their cell.
  - No tooltips while the left button is held, so none appear during a drag.
- **Item stat changes keep the HP and mana percentage.** Level-ups keep the existing "add the gained max" rule. Without this, unequipping and re-equipping a Tear at 0 mana would give free mana.
- **Ability haste applies when a cooldown starts.** Equipping haste doesn't shorten cooldowns that are already running.
- **Combat stats:**
  - Lifesteal heals on basic and Lightslinger hits.
  - Omnivamp heals on all damage.
  - Percent armor and magic pen only reduce positive resists.
  - Crit chance caps at 100%.
  - Heal & shield power and tenacity are stored but do nothing yet.
- **Canvas layers:**

  | Layer | Contents |
  |---|---|
  | 10 | HUD |
  | 30 | Backpack |
  | 40 | Menu |
  | 50 | Debug table |
  | 100 | Hover tooltips and the craft pop-up |

  The debug table stays top-left. While the backpack is open it moves to the top-right, because the recipe table takes the top-left then. At the start position, top-right would cover the dummy.
- **DPS meter** runs on game time (it skips paused frames), so pauses don't split its sessions.

## Item data (placeholders, LoL-based ~70–80%)

**Fragments:**

| Code | Fragment | Stat | Cost |
|---|---|---|---|
| AD | B.F. Sword | +35 AD | 1300 |
| AS | Recurve Bow | +25% attack speed | 1000 |
| AP | Needlessly Large Rod | +60 AP | 1200 |
| AR | Chain Vest | +40 armor | 800 |
| CR | Cloak of Agility | +15% crit | 600 |
| HP | Giant's Belt | +350 HP | 900 |
| MP | Tear of the Goddess | +300 mana | 400 |
| MR | Negatron Cloak | +40 MR | 900 |

**Legendaries:**
- The 33 recipes are exactly the table in design doc §6.
- Stats and passive/active text follow each current LoL item, adapted. For example, Infinity Edge: +65 AD, +25% crit, *Perfection: +40% crit damage*.
- Cost is about the LoL price.
- All 41 items are written first to **`docs/items.md`** (stats, effect text, cost) and then turned into `.tres` files. That doc is the place to review and tune numbers.

## Architecture

### Pure core (`src/core/`, GUT-tested)

**`ItemStats`** (static): the item stat keys, each with its display name, a percent flag and how it applies.
- Item stats get their **own keys**, not StatBlock property names, because some don't map 1:1:
  - `attack_speed` is bonus AS% and goes through the AS ratio
  - `move_speed_pct` has no StatBlock field
- The keys:

  | Key | Kind |
  |---|---|
  | `ad`, `ap`, `armor`, `mr`, `max_hp`, `max_mana`, `ability_haste`, `move_speed` | flat |
  | `attack_speed` | bonus % |
  | `crit_chance` | flat, capped |
  | `move_speed_pct` | percent |
  | `lifesteal`, `omnivamp`, `armor_pen`, `magic_pen`, `heal_shield_power`, `tenacity` | flat |

- A data test checks that every key used in a `.tres` exists. An unknown key would otherwise fail silently.

**`StatBlock`** gains `lifesteal`, `omnivamp`, `armor_pen`, `magic_pen`, `heal_shield_power`, `tenacity`.

**`UnitStats.at_level(level, bonus := {})`** applies item stats through `ItemStats`:
- AS = `base + ratio × (growth·g + bonus AS)`, capped at 2.5
- crit capped at 1.0
- existing callers keep working; `test_unit_stats` gets new cases

**`DamageInfo`** gains `armor_pen` and `magic_pen`.
- All of Lucian's hits go through one new helper, `Lucian.make_damage(amount, type, source, crit)`, which fills them in. The call sites are `lucian.gd:179`, `piercing_light.gd`, `ardent_blaze.gd:65`, `the_culling.gd:68` and `relentless_pursuit.gd` if it deals damage.
- `Enemy.take_damage` passes pen to `DamageCalc.mitigate(amount, type, armor, mr, armor_pen, magic_pen)`. `DamageCalc` stays pure and pen still works after the attacker is freed.

**`ItemData`** (Resource):
- `id`, `display_name`, `kind {FRAGMENT, LEGENDARY}`, `code` (the 2-letter fragment code)
- `icon`, `cost`
- `stats: Dictionary[StringName, float]`
- `components: Array[StringName]`
- `effects: Array[ItemEffect]`

**`ItemEffect`** (Resource): `effect_name`, `active: bool`, `cooldown`, and a `description` written in tooltip markup.

**`ItemCatalog`** (`data/items/catalog.tres`):
- An explicit list of every `ItemData`, so it works in exports.
- Methods: `find(id)`, `fragments()`, `legendaries()`, and `combine(a, b)`, an order-insensitive recipe lookup that returns null when the pair isn't a recipe.

**`Inventory`** (RefCounted, built with the catalog):
- One index space: 0–48 backpack, 49–54 equip. `items` uses null for empty cells.
- `unlocked_equip = 6`
- `add(item) → bool` puts the item in the first empty backpack cell.
- `remove(i)`, `clear()`, `is_locked(i)`
- `drop_outcome(from, to, craft_ready) → {RETURN, MOVE, SWAP, CRAFT}` is the whole drop rule:
  - RETURN when `to` is −1, locked, or the same cell
  - MOVE onto an empty cell
  - CRAFT for a recipe pair with `craft_ready`
  - SWAP otherwise
- `apply_drop(...)` carries the outcome out. A crafted legendary lands in `to` and `from` is emptied.
- `equipped_bonus()` sums the unlocked equip slots.
- Lowering `unlocked_equip` returns items to the backpack.
- Signal `changed`.

### Lucian
- `@export var item_catalog: ItemCatalog` and `var inventory: Inventory`.
- `_refresh_stats(keep_ratio)` replaces `_on_level_changed`:
  - `stats = base_stats.at_level(level, inventory.equipped_bonus())`
  - a level change adds the gained max HP/mana (existing rule)
  - an inventory change keeps the current/max ratio
- `on_damage_dealt` heals from lifesteal and omnivamp.

### Screens and pause (`src/ui/`)

**`ScreenSwitcher`** (Node, ALWAYS, child of Stage):
- owns the Backpack and the GameMenu
- reads P and ESC in `_input`
- the only code that sets `get_tree().paused`
- tells the debug table to move right while the backpack is open

**`GameMenu`** (`src/ui/menu/`):
- a dim backdrop that stops the mouse
- a centered MENU panel with 4 buttons, `focus_mode = NONE`
- Exit calls `get_tree().quit()`

**`BackpackScreen`** (`src/ui/backpack/`), layout:
- a dim backdrop and a panel titled BACKPACK with a 7×7 grid of 64 px tan `ItemCell`s
- a gap, then a darker equip row of 7 cells: 1–6 plus the empty 7th
- the panel is centered in y 0–880, so it stays clear of the HUD panel (y 892–1068)
- locked cells show `chain.svg`
- until the icons exist, a cell without an icon draws a colored frame with the item's code or initials

**Drag gesture** (custom, not Godot's built-in drag and drop; its target checks only run when the mouse moves):
- The pressed cell keeps mouse focus, so the release reaches it even outside the panel.
- The item is picked up after holding for **0.2 s** or moving more than 6 px. A quick click does nothing.
- A ghost icon follows the cursor, and the source cell shows empty.
- `_process` finds the cell under the cursor by its rectangle.
- On release, `Inventory.drop_outcome` decides what happens.

**Crafting:**
- When the item and the hovered cell form a recipe, a **`CraftPopup`** shows next to the target, on layer 100.
- The pop-up holds the result's item card, and a line runs clockwise around its border from the top-left over **1.0 s**.
- A new target restarts the line.
- Releasing after the line completes crafts. Releasing before it swaps.

**`RecipeTable`**, top-left while the backpack is open:
- a ScrollContainer of 33 rows: `[icon] + [icon] = [icon]`
- each icon shows its item's tooltip

**HUD item grid:** 3×2 cells of 40 px, right of the skills-and-bars column, so the panel stays 176 px tall. It shows the unlocked equip slots and their item tooltips. The HUD switches to ALWAYS.

### Tooltips (`src/ui/tooltip/`)

**`TooltipText`** (static, tested):
- Palette:

  | Use | Color |
  |---|---|
  | AD / physical | orange |
  | AP | purple |
  | magic | blue |
  | true | white |
  | mana | `8fb8ff` |
  | HP | green |
  | MS / keywords | gold |

- `colorize(markup)` turns `[ad] [ap] [phys] [magic] [true] [mana] [hp] [ms] [kw]` into BBCode.
- `ranked(values, rank)` gives `80/110/140/170/200`, with the current rank bright and the rest dim.
- `ratio(values, rank, stat)` gives `(+60/70/80/90/100% AD)`.

**`TooltipCard`** builders return Controls in a dark navy panel with a gold border, the HUD panel style. The RichTextLabel uses `fit_content` and a fixed width.
- **Item card:**
  - icon, name, cost in gold
  - stat lines such as "+65 Attack Damage"
  - **"Passive — Name:"** / **"Active — Name (60 s):"** followed by the colorized description
  - legendaries add "Recipe: B.F. Sword + B.F. Sword"
  - the same card is used in the hover tooltip and the craft pop-up
- **Skill card:**
  - icon, name, `[Q]`, "Rank 2/5"
  - mana cost and cooldown as per-rank lists
  - the description
  - a "Rank 5:" bonus line, highlighted once that rank is reached

**`HoverTip`** (CanvasLayer 100, ALWAYS, child of Stage):
- Each frame it reads the hovered control and walks up to the nearest one that has `tooltip_content()`. That can be `SkillSlot`, `ItemCell`, a recipe icon or a HUD item cell. The "+" button counts as part of its slot.
- It adds up hover time and shows the card after 1.0 s.
- It places the card by kind and clamps it to the screen.
- `show_for(control)` lets the screenshot tool and tests open a tooltip directly.

**Skill text:** `LucianSkill.describe()` is virtual, and each skill builds its LoL-style sentence from its `SkillData` and its own `@export`s, so the text always matches the numbers.
- Example: *"Fires a laser through the target that deals 80/110/140/170/200 (+60/…% AD) physical damage to every enemy in a line."*
- `Lightslinger.describe()` uses its exports, because the passive has no SkillData.

### Art
- `assets/art/items/<id>.svg`: 41 hand-written 64 px SVGs. They stay readable at 40 px (HUD) and 36 px (recipe table), and each has a distinct silhouette and color.
- `assets/art/ui/chain.svg`

## Build order (one commit per verified step, on `main`)

0. Save this plan as `docs/implementation/phase2.md`.
1. **Core stats (TDD):**
   - `ItemStats`, the new StatBlock fields
   - `at_level` with bonuses: AS math, caps
   - pen on `DamageInfo` and in `mitigate`, and `Lucian.make_damage` at every hit site
   - update `test_unit_stats` and `test_damage_calc`
2. **Items core (TDD):**
   - `ItemData`, `ItemEffect`, `ItemCatalog`
   - `Inventory`, including `drop_outcome` and `apply_drop`
   - `TooltipText`
3. **Item content:**
   - `docs/items.md`
   - 41 `.tres` files and `catalog.tres`
   - an integrity test: 8 fragments and 33 legendaries; the recipe pairs are unique and match the design doc (the 3 free pairs stay free); all stat keys are known; every item has a name, at least one stat and a cost
4. **Lucian integration:**
   - the inventory and `_refresh_stats` with both rules
   - lifesteal and omnivamp
   - the debug Items section, the stats readout and the 50% HP button; the debug table goes to layer 50 and ALWAYS; the DPS meter on game time
   - the scene test `test_lucian_items`
5. **Pause and ESC menu:** `ScreenSwitcher`, `GameMenu`, the controller's pause handling, the "+" hidden while paused.
6. **HoverTip and the skill tooltips:**
   - the cards
   - `describe()` for P/Q/W/E/R
   - hover on `SkillSlot`
7. **Backpack screen:** grid, equip row, chains, the recipe table, item tooltips, and the debug table moving right.
8. **Drag:** move, swap and equip, plus return when dropped outside or on a locked cell, or when the backpack closes.
9. **Crafting:** `CraftPopup` with the border line, the 1 s hold, and craft vs swap.
10. **HUD item grid.**
11. **Icons**, in 2–3 commits: fragments and chain, then the legendaries in batches.
    - each batch is checked on an `icons` contact-sheet screenshot
    - the data test then asserts that every item has an icon
12. **Polish:**
    - a full GUT run and all screenshots
    - update `ui_design.md`; tick the design-doc open topics
    - implementation notes in `phase2.md`

## Verification

**Unit tests:**
```
godot_console --headless --path . --import
godot_console --headless --path . -s res://addons/gut/gut_cmdln.gd
```
- **`test_inventory`:**
  - add fills the first empty cell; a full backpack
  - each `drop_outcome` case: empty, swap, locked, same cell, outside, recipe with and without hold
  - craft puts the result in the target and empties the source
  - `equipped_bonus` counts only unlocked slots; duplicates stack
  - lowering `unlocked_equip` returns items
  - the `changed` signal
- **`test_item_catalog`:** `combine` is order-insensitive; data integrity as in build step 3.
- **`test_unit_stats`:** flat bonuses; bonus AS uses the ratio and the cap; crit cap; MS %.
- **`test_damage_calc`:** pen reduces positive resists only.
- **`test_lucian_items`** (scene):
  - HP equip/unequip keeps the HP percentage
  - item AD survives a level-up
  - lifesteal heals on a basic hit
  - pen raises the final damage against the dummy
- **`test_tooltip_text`:**
  - `ranked` and `ratio` formatting
  - markup → BBCode
  - each skill's `describe()` contains its per-rank numbers

**Screenshots** (`tests/tools/screenshot.gd`):
- New mouse helpers convert canvas positions to window pixels (the window is 1600×900, the canvas 1920×1080) and set `button_mask` on motion events.
- New scenarios:
  - `menu`
  - `backpack`: items, the recipe table, chains via a lowered slot count
  - `craft`: a real mouse drag, shot at 0.5 s into the hold (border half drawn), then after the craft
  - `tooltip_skill`, `tooltip_item`: via a 1.1 s hover, plus `show_for`
  - `hud_items`
  - `icons`: a contact sheet of all 41

**Manual playtest checklist:**
- P pauses: the dummy, regen and cooldowns freeze, and skills can't be cast. P and ESC close it. ESC opens the menu; Resume and Exit work.
- Give items from the debug table, then:
  - move one to an empty cell
  - swap two
  - equip into 1–6
  - drop outside: the item returns
  - drop on a locked slot: refused
  - close with P mid-drag: the item returns
- Fragment onto its partner: the pop-up appears with its line. An early release swaps; a late release crafts.
- Equipping changes the stats panel and HP/mana, and AD items raise the damage numbers. Lifesteal heals after "HP 50%".
- Tooltips show after about 1 s on skills, the passive, backpack cells, recipe icons and HUD items, and read like LoL.

## Implementation notes (Phase 2 done)

Everything in the build order above is in place. Changes and details settled while building:

- **Legendary stats** follow their LoL item, adjusted so they usually carry the stat types of their two fragments (e.g. Bloodthirster = AD + MR, so it gets some MR). `docs/items.md` is generated from the same table as the `.tres` files; the `.tres` files hold the live values.
- **`Lucian.make_damage()`** builds every hit Lucian deals (basic attacks, passive, Q, W, R), so each one carries his armor and magic pen.
- **`HoverTip`** polls `Viewport.gui_get_hovered_control()` each frame and walks up to the nearest control with `tooltip_content()` (or a `hover_text` meta). Godot's built-in tooltips were not used: their timer restarts on every mouse motion, they always sit at the cursor, and scripts can't open them for screenshots.
- **Backpack drag** is custom, not Godot's drag and drop. The pressed cell keeps getting mouse events until release, wherever the mouse goes, so a release outside the backpack still reaches it. Alt-tabbing away or closing the backpack mid-drag puts the item back.
- **Cells, the recipe table, HUD slots and cards share `ItemIcon.draw_item()`**, which falls back to a colored tile with the item's code if an icon is missing.
- **The debug table's "Clear items"** empties the equip slots too, not just the backpack.
- **The E rank-5 bonus** is described in E's tooltip but still waits for killable enemies, as in Phase 1.
- **Fixes from the first playtest:**
  - A dragged fragment held back over its own cell showed the craft pop-up for its double recipe (B.F. Sword → Infinity Edge). `Inventory.craft_result` now refuses `from == to`.
  - **Skill queueing** (new): a skill pressed during a cast time or the E dash used to be dropped. It is now queued and cast when the lock ends, aimed where the key was pressed (`Lucian.queue_casts`, on by default; toggled in the debug table until the Settings screen exists).
- **Screenshot harness:** `mouse_move` / `mouse_button` send real mouse events and warp the OS cursor to the same spot, so stray OS motion events agree with the script. `wait_for_tooltip()` re-hovers if a stray event still moves the hover, and prints how long the card took.

### Running the checks

Godot 4.7.2 lives in `%LOCALAPPDATA%\Programs\Godot` (`godot.exe`, `godot_console.exe`).

```
godot_console --headless --path . --import
godot_console --headless --path . -s res://addons/gut/gut_cmdln.gd
godot --path . -s res://tests/tools/screenshot.gd -- <scenario> <output_dir>
```

New scenarios: `menu`, `tooltip`, `backpack`, `craft`, `hud_items`, `icons`. As in Phase 1, the window takes focus; moving the real mouse over it during a run can disturb the mouse-driven scenarios.

# UI Design

> Part of the Lucian game design. Layout is based on LoL so it feels familiar, but only about **70–80% similar**.

## Screen layout overview

```
+--------------------------------------------------------------+
|        [Stage name]  Wave 2/4  Enemies: 12  [Skip 0:20] [Gold]|
|              [========= Boss HP bar =========]   [B][O][P]   |
|                                                              |
|                                                              |
|                       (battlefield)                         |
|                                                              |
|                                                              |
|                 . . . buff icons . . .                      |
|  [Stats]  [Portrait][Lv]  [P][Q][W][E][R]  [D][F]   +------+ |
|  (C key)  [HP bar ][MP bar]  [1][2][3][4][5][6]     |radar | |
|           [XP bar ]                                  +------+ |
+--------------------------------------------------------------+
```

---

## 1. HUD

### Bottom center – Lucian's panel
- **Portrait** showing the current skin, with the **level number** and an **XP bar**.
- **HP bar** and **mana bar**.
- **Skill icons:** Passive, Q, W, E, R. The passive is smaller (45 px, 70% of a 64 px skill icon), centered on the skill row.
  - Cooldown timer and rank dots on each.
  - **Mana cost** shown as a number in the **top-left corner** of each skill icon.
  - **"+" buttons:** while there is an unspent skill point, every skill that isn't maxed shows a "+" in a ring above it. **Gold** when it can rank up now (click it or press Ctrl + the skill key); **grey** when it can't yet (Q/W/E rank *r* needs level 2*r* − 1, R needs level 6 / 11 / 16); **grey with a small lock** when the next rank isn't bought in the Evolution Tree. No "+" with 0 points or on a maxed skill.
  - Unbought skills show a **lock icon**.
  - **Greyed out** while another skill holds it back: Q and W (once learned) while R fires, E during Q's cast time.
- **Hover a skill or the passive** for about **1 second** to see its card, like LoL: name, key, rank, mana cost and cooldown per rank, and a description where per-rank values show the current rank lit up and scalings in their stat color (AD orange, AP blue). The max rank bonus is listed last and lights up once reached.
- **Summoner spells** (D / F): 48 px icons right of R, with a cooldown sweep and seconds and the key. Hover one for its card (name, key, cooldown, effect).
- **Item slots 1–6:** in a 3 × 2 grid right of the HP / mana bars. Only unlocked slots are shown, with cooldowns for active items (sweep and seconds) and a potion stack's count. Hovering one shows the item's card.
- **Key labels** (skills and item slots) follow the bindings in Settings.

### Buff icons (above the skill bar)
- **Very small icons** (36 px) in a row just above the HUD panel, starting over the portrait, like LoL.
- Shows: Blue / Red buff (with timer), current Endless modifier, status effects (slow, stun, burn, etc.).
- **Phase 3 shows:** potions being drunk, move speed buffs (W, Fervor, Stormrazor, Rocketbelt, and since Phase 4 Ghost and Heal), the Bloodthirster shield, Barrier, and item passive states:
  - **Energized** (only while an Energized item is equipped): the charge 0–100; glows gold at 100.
  - **Kraken Slayer**: the hit count; glows before the 3rd hit.
  - Spellblade ready, Spear of Shojin stacks, Jak'Sho stacks, Archangel's mana charge.
- A dark sweep shows the time that has run out; a number shows stacks, charge or shield.
- **Hover** the cursor over an icon to see its effect.
- **Enemy statuses** (Carve stacks, Grievous Wounds, slow, Hatefog) show as tiny icons above the enemy's HP bar.
- A shield (Ichorshield and Barrier together) shows as a white segment after the HP on Lucian's HP bar, and as "(+N)" in its text.
- With **Rapid Firecannon** equipped and the Energized charge full, a light-blue ring shows its longer attack range until the Energized shot lands.

### Stats panel (left of the portrait)
- Like LoL's: each stat is its **icon + value**, two per row. Main panel: AD | AP, Armor | MR, Attack speed | Ability haste, Crit | Move speed.
- **Ctrl + C** toggles it on or off.
- **Hold C** to show the extra stats above it (in its place when it is hidden): HP regen | Mana regen (per 5 s), Heal & shield power | Armor pen, Magic pen | Life steal, Omnivamp | Attack range, Tenacity.
- **Hover a stat** for 1 second: a card with its icon, name, value and what it does.

| Stat | Icon | Color |
|---|---|---|
| AD | one-headed axe | orange |
| AP | round-headed missile | dark blue |
| Armor | breastplate inside a second frame | yellow |
| Magic resist | circle inside a circle frame | light blue |
| Attack speed | dagger with speed lines | light yellow |
| Ability haste | hourglass | white |
| Crit chance | pointed missile | red |
| Move speed | boot with speed lines | white |
| Health / HP regen | heart / heart + up arrow | green |
| Mana / Mana regen | droplet / droplet + up arrow | blue |
| Heal & shield power | cross over a shield | teal |
| Armor / Magic pen | arrow through a breastplate / a circle | orange-red / violet |
| Life steal | fang and a drop of blood | crimson |
| Omnivamp | swirling drop | magenta |
| Attack range | crosshair | grey |
| Tenacity | broken chain | tan |

Icons live in `assets/art/stats/`, colors and texts in `src/ui/stat_style.gd`.

### Top center – Stage info
- Stage name, **wave counter** (e.g. Wave 2/4) and **enemies remaining**.
- **Break timer** between waves: a 20-second countdown with a **Skip** button to start the next wave right away.
- **Boss HP bar** during the boss wave, with the boss name.
  - Thresh's bar also shows **Phase 1 / 2**.

### Top right – Loot
- Stage gold: a coin and the amount, in the HUD panel style (Phase 3).
- Essences collected in this stage (blue, orange, purple).

### Top center – FPS
- "FPS N", only when **Show FPS** is on in Settings.

### Bottom right – Radar (minimap)
- Shows only dots, no terrain.

| Marker | Look |
|---|---|
| Lucian | Blue dot |
| Normal enemy | Red dot |
| Elite | Bigger red dot |
| Mini boss / Boss | Red skull icon (same size as the elite dot) |

### On the battlefield
- **HP bars** above enemies, with a special icon for elites.
- **Damage numbers:**

| Damage type | Color |
|---|---|
| Physical | Orange |
| Magic | Blue |
| True | White |
| Critical hit | Bigger text |

- **Skill warnings:** line and circle indicators for enemy attacks.

---

## 2. Backpack (P)

- Press **P** to open. The game **pauses immediately**.
- Can be opened at any time, including during a wave.
- While open, the player **cannot use skills or item actives**.
- Title at the top: **BACKPACK**.

```
+-----------------------------+
|          BACKPACK           |
+-----------------------------+
| [ ][ ][ ][ ][ ][ ][ ]       |
| [ ][ ][ ][ ][ ][ ][ ]       |
| [ ][ ][ ][ ][ ][ ][ ]       |
| [ ][ ][ ][ ][ ][ ][ ]   7x7 |
| [ ][ ][ ][ ][ ][ ][ ]   =49 |
| [ ][ ][ ][ ][ ][ ][ ]       |
| [ ][ ][ ][ ][ ][ ][ ]       |
+-----------------------------+

  [1][2][3][4][5][6][S]   <- equip row, outside the backpack
```

### Layout
- **Rows 1–7:** 49 backpack slots (7 per row), in a light tan style like the reference image.
- **Row 8 – equip row:**
  - Placed **further away** from the other rows, so it looks like it sits **outside the backpack** (like the darker bottom row in the reference image), with its own darker style.
  - Slots **1–6:** equipped items. Locked slots show a chain.
  - **7th slot:** **empty** when only the backpack is open. Becomes the **sell slot** when the merchant's shop is open: the **only cell filled red**.

### Mouse controls
| Action | Result |
|---|---|
| **Left-click (press and release quickly)** | Does nothing, for all items |
| **Hold left-click** | Picks up the item to drag it (the only left-click action): after 0.2 s, or as soon as the mouse moves |
| **Release the hold** | Drops the item |
| **Right-click a potion** | Shows a small pop-up **Use** button beside the cell; click it to use the potion. Any other click hides it |

### Drag and drop
| Drop target | Result |
|---|---|
| Empty cell | Item moves there |
| Outside the backpack | Item returns to its original cell |
| Locked equip slot | Item returns to its original cell |
| Same type of potion | Stacks into the target cell (max **9** per cell); the rest returns to the original cell |
| An item it can **craft** with | See *Crafting* below |
| Any other item | The two items **swap** places |
| Sell slot (shop open) | Item is **sold immediately** |

### Crafting
1. Drag an item onto another item that forms a valid recipe.
2. While hovering, a **small pop-up table** shows the legendary item that would be crafted, so the player can read it and decide.
3. A **line runs around the pop-up's border**, starting at the top-left, going all the way around and back to the top-left. This is the **minimum hold time** to craft: **1 second**.
4. **Release after the line completes** → the two items are combined. The legendary appears in the target cell, and the original cell becomes empty.
5. **Release before the line completes** → the two items just **swap**.

If the two items are not a valid recipe, no pop-up appears and they swap.

### Potions
- Up to **9 potions** stack in one cell.
- **Right-click → Use.** The game is paused, so healing **starts when the backpack is closed**.
- Or place it in an equip slot and press **1–6** during play.

### Recipe table
- Shown automatically when the backpack is open, in the **top-left of the screen**. The backpack sits in the **center**.
- **Hidden** while the merchant's shop is open.
- Each line shows only: **item + item = item** (e.g. `[B.F. Sword] + [B.F. Sword] = [Infinity Edge]`).
- Scrollable, since there are 33 recipes.

```
+------------------------+
| RECIPES                |
| [AD] + [AD] = [IE]     |        +---------------+
| [AD] + [AP] = [Gunbl.] |        |   BACKPACK    |
| [AD] + [AS] = [Kraken] |        |   (center)    |
| ...          (scroll)  |        |               |
+------------------------+        +---------------+
```

### Item info pop-up
- **Hover** the cursor over a cell with an item for about **1 second** → a pop-up shows that item's stats and effect.
- Works in the **backpack**, the **merchant's shop**, the **recipe table** and the **HUD item slots**.
- Layout like LoL: icon, name and cost; stat lines; each passive / active with its name; for a legendary, its recipe.
- Each stat line is the **stat icon, the amount in the stat's color, then the name**, e.g. `[axe] +65 Attack Damage`.

---

## 3. Merchant's shop

- Opens when Lucian walks to the merchant during the break between waves.
- The game **pauses** while it is open (including the break timer).
- While open, the player **cannot use skills or item actives**.

```
+---------------------+   +-----------------------------+
|      BACKPACK       |   |  [ Items ]  [ Potions ]     |
|  (same as section 2)|   +-----------------------------+
|                     |   |  [item][item][lock][lock]   |
|                     |   |                             |
|                     |   |                   [Refresh] |
+---------------------+   +-----------------------------+
```

- **Left:** the player's backpack (the 7th equip-row slot becomes the red **sell slot**). **Right:** the merchant's shop.
- **Selling:** drag an item into the sell slot to sell it immediately.
- **Tabs at the top of the shop:**
  - **Items:** fragments and legendary items.
  - **Potions:** HP and MP potions.
- **Items tab:** always shows **4 slots** in a row. Slots not yet unlocked (Evolution Tree) are covered by a **chain lock**.
- **Refresh** button in the **bottom-right corner** of the shop (costs stage gold).

### Built in Phase 3
- **Opening:** right-click the merchant. Lucian walks over; the shop opens once he is within 250 units (right away if he already is). Hovering the merchant shows a gold ring.
- **Header:** "MERCHANT" and the stage gold. The recipe table is hidden; the backpack and the shop are centered side by side.
- **Slots:** 64 px, the price with a coin under each (red when it can't be afforded). A bought slot shows **SOLD** for the rest of the visit, even after a refresh.
- **Buying:** right-click a shop item to buy it into the first cell it fits, or **hold-drag** it onto a backpack or equip cell. Dropping it on an occupied cell (other than a stack of the same potion with room) buys nothing.
- **Refused purchase** (not enough gold, no room): a red message in the bottom row and the price flashes red, with an error sound.
- **Selling:** the 7th equip-row cell turns red and reads **SELL**. Dragging an item over it shows "+N" and "Sells for N gold"; releasing sells it (a whole potion stack at once).
- **Closing:** ESC or P. The game stays paused while the shop is open.

---

## 4. Menu (ESC)

- Press **ESC** to open. The game **pauses**.
- Can only be opened when the backpack or merchant's shop is **not** open.
- Options:
  - **Resume**
  - **Settings** (cast mode, camera, volume, etc.)
  - **Leave this stage** (keeps all essences collected)
  - **Exit the game** (progress is saved first)

## 5. Settings (from the ESC menu)

- Replaces the menu while open; **Back** or ESC returns to it. The game stays paused.
- Every change applies right away and is saved to `user://settings.json`.
- **Tabs:**

| Tab | Contents |
|---|---|
| Audio | Master, Music and Sound effects volume (0–100). Releasing a slider plays a test sound. No music yet. |
| Controls | Every rebindable action with its key or mouse button (including Center camera, Space). Click one, then press a key or mouse button; ESC cancels. A key already used by another action swaps the two. **Reset to defaults.** ESC (menu) and F3 + Q (debug) can't be rebound; Ctrl + a skill key still ranks the skill up, and Ctrl + the stats key toggles the stats panel. |
| Graphics | Window mode (windowed, borderless fullscreen, fullscreen), Resolution (1280×720, 1366×768, 1600×900, 1920×1080, 2560×1440, 3840×2160; only sizes that fit the screen; sets and centers the window, greyed out in borderless/fullscreen), VSync, FPS cap (30/60/120/144/unlimited), Quality (Low: no anti-aliasing, no dash trails or muzzle flashes; Medium: 2× MSAA; High: 4× MSAA), Show FPS. |
| Gameplay | Skill queue (on by default; see the game design doc §2). |

- **Not yet:** cast modes (normal / quick / quick with indicator) and camera options.

---

## 6. Screens to design

- [x] Backpack layout
- [x] Crafting (drag and drop)
- [x] Recipe table
- [x] Item info pop-up
- [x] Merchant's shop layout (built in Phase 3)
- [x] ESC menu
- [x] Settings
- [ ] Evolution Tree screen
- [ ] Skin shop
- [ ] Main menu and save slot selection
- [ ] Stage select

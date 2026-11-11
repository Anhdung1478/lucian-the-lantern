# UI Design

> Part of the Lucian game design. Layout is based on LoL so it feels familiar, but only about **70–80% similar**.

## Screen layout overview

```
+--------------------------------------------------------------+
|FPS     [Stage name  Wave 2/4  Enemies: 12]  [Gold][B][O][P]   |
|          [====== Boss name, HP bar ======]                   |
|                 [ Act 1 tip ]                                |
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

*(V2.0: the sketch still holds. The stage info gains a row of wave pips, the next-wave preview takes the boss bar's place before a wave, and a wave banner shows under the tips. See "The Lantern look (V2.0)" and §1.)*

## The Lantern look (V2.0)
From V2.0 every stage screen follows one style, the title's and the Journey's: dark navy, gold trim, the lantern's teal glow. The old text below describes the layout and the behaviour; the V2.0 notes say how each part looks now.

- **`Plate`** (`src/ui/plate.gd`) is the frame of every stage panel: a navy-to-teal gradient (`UiStyle.PLATE_TOP` to `PLATE_BOTTOM`), a 2 px gold line (`UiStyle.BORDER_COLOR`), and, when `ornate`, a fainter inner line with a gold diamond at each corner. `Plate.draw_on` paints the same frame on any `CanvasItem`. The HUD's bottom bar is an ornate plate about 0.92 opaque, so a little of the fight shows through. Pop-ups and questions keep `MenuCard`.
- **`UiStyle`'s tokens:** `GOLD_COLOR` for what matters, `TITLE_COLOR` (pale gold) for headings, `TEXT_COLOR`, `DIM_COLOR` for notes, `LANTERN_COLOR` (teal) for light and for Senna, `GOOD_COLOR` and `BAD_COLOR` for gains and losses, `CELL_COLOR` and `CELL_BORDER` for cells, `RIM_FRAGMENT`, `RIM_LEGENDARY`, `RIM_BOOTS` and `RIM_POTION` for item rims. `UiStyle.cell_style()` and `item_rim()` build a cell and pick its rim. No beige and no brown panels are left.
- **Headings** are spaced capitals in pale gold, with a short gold rule and a diamond where there is room.
- **Cells** (items, skills, spells) are dark wells with a thin rim that follows the item's kind and turns gold on hover or when chosen.
- **Buttons** use `UiStyle.style_button`.
- **Motion** is short and soft: fades and slides of 0.1 to 0.25 s. Nothing blinks. Low quality (`GameSettings.low_effects()`) turns the extras off.
- **The battlefield** is drawn in code, like the Journey's map: soft shapes, layered tints, a light from the top-left, shadows that ground every wall and unit, and small things that move. Hitboxes, walls and paths never changed. The kit is `MapArt` (`src/stage/maps/map_art.gd`, the drawing helpers every map's `_draw` uses) and `MapAmbience` (`map_ambience.gd`, the slow fireflies, glints and dust; off on Low quality). See the game design doc §12/§13.
- **Readability first.** Enemies, red warnings and Lucian stay the clearest things on screen.

---

## 1. HUD

### Bottom center – Lucian's panel
- **Portrait** showing the current skin, with the **level number** and an **XP bar**.
- **HP bar** and **mana bar**, each with its regeneration per second at the right end ("+0.8/s").
- **Skill icons:** Passive, Q, W, E, R. The passive is smaller (45 px, 70% of a 64 px skill icon), centered on the skill row.
  - Cooldown timer and rank dots on each.
  - **Mana cost** shown as a number in the **top-left corner** of each skill icon.
  - **"+" buttons:** while there is an unspent skill point, every skill that isn't maxed shows a "+" in a ring above it. **Gold** when it can rank up now (click it or press Ctrl + the skill key); **grey** when it can't yet (Q/W/E rank *r* needs level 2*r* − 1, R needs level 6 / 11 / 16); **grey with a small lock** when the next rank isn't bought in the Evolution Tree. No "+" with 0 points or on a maxed skill.
  - Unbought skills show a **lock icon**. Until it is bought in the Evolution Tree, the passive is greyed out with a lock and never shows its charged ring.
  - **Greyed out** while another skill holds it back: Q and W (once learned) while R fires, E during Q's cast time.
- **Hover a skill or the passive** for about **1 second** to see its card, like LoL: name, key, rank, mana cost and cooldown per rank, and a description where per-rank values show the current rank lit up and scalings in their stat color (AD orange, AP blue). The max rank bonus is listed last and lights up once reached.
  - A skill with no rank bought starts its card with a red line saying why: "Locked: buy it in the Evolution Tree." In Act 1's tutorial, Q and W say "Locked: clear Act 1 to unlock it in the Evolution Tree.", and E says "Locked: Senna teaches it at the first break." until she does.
- **Summoner spells** (D / F): 48 px icons right of R, with a cooldown sweep and seconds and the key. Hover one for its card (name, key, cooldown, effect, and a green "Upgraded: …" line once its upgrade is bought). An empty key shows only its frame ("No spell: pick one in Journey before starting."); F shows a chain until the 2nd slot is bought.
- **Item slots 1–6:** in a 3 × 2 grid right of the HP / mana bars. Only unlocked slots are shown, with cooldowns for active items (sweep and seconds). Hovering one shows the item's card.
- **Gear column** *(since V1.4)*: right of the item slots (its own column, not in their grid). On top, the Health and Mana potion cells (keys 7 and 8) with their stack counts; an empty one shows its potion faded. Under them, the boots, with no key, and nothing at all while there are none. Hovering shows the card.
- **Range on hover:** hovering a learned skill, an item with an aimed active (Galeforce, Rocketbelt, Gunblade) or Flash / Smite shows its range around Lucian at once, pointing where he faces: a ray for Q, W (ending in its cross), E and the item dashes (ending in a ring where Lucian lands), two dashed rays for R, a circle for Gunblade, Smite and Flash (Flash's shows the landing ring while aiming). Drawn in pale blue under Lucian.
- **Key labels** (skills, item slots and potion cells) follow the bindings in Settings.
- **Built in Phase 9:** the Evolution Tree shows these same skill and summoner icons (`main_screen.md`). Learning a rank plays `rank_up`, and Q, W and E each have a cast sound (§8).

**Built in V2.0 (the Lantern look; layout and behaviour as above):**
- **The bottom bar** is an ornate plate. The **portrait** is round, in a gold ring, with the level in a gold badge on the ring and a slim gold XP bar.
- **Health and mana bars** (`HudBar`) have a dark well with a thin rim and a gradient fill with a light line along its top. Health has a tick every 100 HP, a taller one every 1000 (ticks closer than 5 px are left out); mana has none. The white shield segment after the health stays. A **ghost** chunk (pale) shows the damage just taken and drains away in 0.4 s.
- **Cells:** skill, summoner, item, potion and boots cells are dark wells with a rim by item kind (fragment, legendary, boots, potion). The key label sits in a small tab at the cell's corner. Rank dots are small gold diamonds.
- **Low health:** below 30% health a soft red vignette pulses at the screen's edges (`LowHealthVignette`, one pulse every 2.4 s). It grows as health falls, is gone at 30% or more, when Lucian is dead and on Low quality, and never takes the mouse.

### Buff icons (above the skill bar)
- **Very small icons** (36 px) in a row just above the HUD panel, starting over the portrait, like LoL.
- Shows: Blue / Red buff (with timer), current Endless modifier, status effects (slow, stun, burn, etc.).
- **Death's Dance (V1.4.2):** an **Ignore Pain** icon shows while its delayed damage is still to come. The number is the damage left, it counts down as the bleed ticks, and a sweep shows the time left. It leaves when the bleed ends, or when Defy's cleanse removes it. *(V1.4.3: it stays when the item comes off, unequipped or sold, since the damage still lands. Only Defy and Guardian Angel clear it.)*
- **Phase 3 shows:** potions being drunk, move speed buffs (W, Fervor, Stormrazor, and since Phase 4 Ghost and Heal), the Bloodthirster shield, Barrier, and item passive states:
  - **Energized** (only while an Energized item is equipped): the charge 0–100; glows gold at 100.
  - **Kraken Slayer**: the hit count; glows before the 3rd hit.
  - Spellblade ready, Spear of Shojin stacks, Jak'Sho stacks, Archangel's mana charge.
- A dark sweep shows the time that has run out; a number shows stacks, charge or shield.
- **Hover** the cursor over an icon to see its effect. *(V1.4.3: the card stays live while hovered. The time left, counts and values update, and when another buff moves into the hovered icon, the card shows that one.)*
- *(V2.0)* **Look:** a buff icon is a rounded cell with a rim, in the cells' style. **Resolve** shows as one (a fist under a rising chevron) while the stage has stacks and the Gameplay setting is on: the number is the stacks, there is no sweep. Its card reads "+30% damage dealt, -30% damage taken. You fell here 3 times." (§5; game design doc §3).
- **Built in Phase 8:** three crowd-control debuffs, in the style of `debuff_slow.svg` (64 × 64, a tinted dark backdrop, `#1a1d24` outlines): **Rooted** (a boot bound by green vines), **Stunned** (yellow stars circling a head) and **Feared** (a frightened purple ghost). Each has a sweep for its time and a one-line text on hover. They sit after "Slowed", the strongest first (stun, fear, root).
- **Enemy statuses** (Carve stacks, Grievous Wounds, slow, Hatefog) show as tiny icons above the enemy's HP bar. *(V1.4.2: an enemy's bar redraws only when its health or a status changes, and about 10 times a second while a timed status is shown, so the time-spent shading still moves.)*
- **Built in Phase 7:** the **Blue** and **Red** jungle buffs (a blue rune shield, a red flame shield) with their 60 s sweep; **Slowed** (the strongest slow on Lucian) and **Burning** while a burn ticks on him. Over an enemy's bar, slow and burn icons.
- A shield (Ichorshield and Barrier together) shows as a white segment after the HP on Lucian's HP bar, and as "(+N)" in its text.
- With **Rapid Firecannon** equipped and the Energized charge full, a light-blue ring shows its longer attack range until the Energized shot lands.
- **Built in Phase 9: the Endless modifier row.** In an Endless run with a modifier, its icon comes first in the row and never moves: `stats/move_speed` (#1), `ui/essence_orange` (#2), `stats/max_hp` (#3), `stats/ad` (#4) or `ui/skull` (#5). It has no sweep and no number. Its hover card reads "Endless modifier", then the downside in red and the reward in green ("−10% max HP", "+15% blue"). There is no row before the first pick or after Nothing.

### Stats panel (left of the portrait)
- Like LoL's: each stat is its **icon + value**, two per row. Main panel: AD | AP, Armor | MR, Attack speed | Ability haste, Crit | Move speed.
- **Ctrl + C** toggles it on or off.
- **Hold C** to show the extra stats above it (in its place when it is hidden), also 2 × 4: Health / mana regen (one cell, "0.8 / 1.6" per second) | Heal & shield power, Armor pen | Magic pen, Life steal | Omnivamp, Attack range | Tenacity.
- A value shows in **yellow** when something adds to what Lucian's level alone gives: items, item passives, buffs (move speed counts its buffs, attack range counts Rapid Firecannon), or the debug crit cheat.
- **Hover a stat** for 1 second: a card with its icon, name and value, then the split, e.g. "60 base + 22 bonus" with the bonus in yellow (regen has a health and a mana line), and what the stat does. *(V1.4.3: the card updates while hovered when the value or its split changes.)*

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
| Health | heart | green |
| Mana | droplet | blue |
| Health / mana regen | heart and droplet under an up arrow | green |
| Heal & shield power | cross over a shield | teal |
| Armor / Magic pen | arrow through a breastplate / a circle | orange-red / violet |
| Life steal | fang and a drop of blood | crimson |
| Omnivamp | swirling drop | magenta |
| Attack range | crosshair | grey |
| Tenacity | broken chain | tan |

Icons live in `assets/art/stats/`, colors and texts in `src/ui/stat_style.gd`.

### Short key names (V1.4.2)
The labels on the HUD's item and potion slots, skill slots, summoner slots and the backpack's cells are small, so a long key name is shortened there (`GameSettings.short_key_label`). The skill and summoner slots' hover cards use the same short name in their header ("[M4]", "Summoner spell [Bcksp]"), because a long name such as "Backspace" would overflow a skill card's box (V1.4.3). Settings, sentence-style hints and tips (the potion cards' and empty potion cells' "press 7 to drink", stage tips, the cutscene) and the Journey's D / F labels keep the full name (`GameSettings.key_label`).

| Key | Short label |
|---|---|
| Mouse 4, Mouse 5, other buttons | M4, M5, M6 … |
| Wheel up, wheel down | WhU, WhD |
| Backspace, Space, Escape, Enter | Bcksp, Spc, Esc, Ent |
| Delete, Insert, Page Up, Page Down, Caps Lock | Del, Ins, PgUp, PgDn, Caps |
| Keypad N | Num N |
| Arrows | Up, Dn, Lt, Rt |
| Backtick | ` |
| Anything else longer than 5 characters | Cut to 5 |

Godot names the key "Backspace" (not "BackSpace"), so that is the full name Settings shows. The fix wave added short labels for the brackets, the backslash, the slash and the keypad operators, so they don't all collide after the 5-character cut.

### Top center – Stage info
- Stage name, **wave counter** (e.g. Wave 2/4) and **enemies remaining**.
- **Break timer** between waves: a 20-second countdown with a **Skip** button to start the next wave right away.
- **Boss HP bar** during the boss wave, with the boss name.
  - Thresh's bar also shows **Phase 1 / 2**.

**Built in Phase 6:**
- One panel at the top center, in the HUD panel style, 20 px text: the stage's name in gold ("Act 1 · The Loss", "Stage 2-3 · The Sentinels"), then:
  - before a wave: "Wave 2 in 0:17" in gold and a **Skip** button (hover: what Skip does);
  - during a wave: "Wave 1/2" (or "Boss wave") and "Enemies: 13", which counts the ones still to spawn.
- Training shows only its name.
- Only Skip takes clicks; the rest lets right-clicks through to the battlefield.
- **Boss bar** under it while a boss lives: the boss's name over a 600 × 22 red bar with "HP / max". It finds the boss by itself and hides when the boss dies or leaves. The phase text is for Act 6's Thresh.
- **Phase 7:** the boss bar also shows a mini boss while no boss is out (a boss takes it over). It keeps a boss that is untargetable for a moment (Sky Dive, Dark Lucian's dash).
- **Phase 8:**
  - **The break bar:** while a boss channels something that damage breaks (the Ocean Drake's Soothing Mist, Karthus's Requiem), a thin yellow bar (`#ffd166`, 8 px, 4 px under the HP bar) fills with the damage done against the damage needed. It goes when the channel ends. The bar's height grows by 12 px for every boss.
  - **The phase text:** `Boss.phase_label()` after the name, in the same line: "Thresh   Phase 1", then "Thresh   Phase 2" from the rise on. Other bosses show none.
  - **Elise's Rappel:** while she is up her art and bar fade out, but her name and bar stay on the boss bar.
- **Phase 9 (Endless):** Endless has no last wave, so the counter has no "/ N".
  - During a wave: "Endless · Jungle  Wave 23  Enemies: 12", or "Mini boss wave" / "Boss wave" in place of "Wave 23".
  - Before a wave: "Wave 24 in 0:12" (or "Mini boss wave in 0:18", "Boss wave in 0:20") in gold, with Skip.
  - A dim **"Best 22"** line (16 px) under the row, centered: the save's best, read live. Only Endless has it.
  - While the modifier pick is open, the countdown and Skip hide: the panel shows only the name and the Best line.
  - The boss bar sits under the Best line, so an Endless boss's or mini boss's bar never covers it.

**Built in V2.0:**
- **The plate:** the stage info is a plain `Plate`. The stage's name is a heading in small spaced capitals between two gold rules. The row under it has **wave pips**, then "Wave 2/3" (or "Boss wave") and "Enemies: N". Texts, the countdown and Skip are as above.
- **Wave pips** (`WavePips`): one diamond per wave. **Gold** is a wave cleared, **bright with a soft glow** is the wave being fought, **dim** are those to come. The boss wave's pip is larger. Endless has none.
- **The boss bar** is an ornate plate under the stage info (`Hud.BOSS_BAR_TOP` is 92). The name (and `Boss.phase_label()`) is a heading in spaced capitals over a wide red bar with the same gradient as Lucian's health bar, a ghost of the damage just done, and no ticks. Karthus's break bar sits under it.
- **The next-wave preview** (`WavePreview`, R2): before wave 1 and in every break, a plain plate in the boss bar's place shows **NEXT** and each enemy type of the next wave as a 34 px icon in a dark cell with "×N" beside it, in spawn order. A boss or mini boss comes first, with a gold rim and its name. Hovering an icon names the enemy. It only takes hover, never a click. Endless rolls a wave's enemies when the wave starts, so it only says "Mini boss wave" or "Boss wave" (nothing before an ordinary one). It is hidden during a wave, on the end screen, while the modifier pick is open, and in Training. It reads `WaveRunner.next_ids()` and `next_kind()`; `WavePlan.preview_rows()` groups the ids.
- **The wave banner** (`WaveBanner`): at each wave's start, "WAVE 3" in spaced capitals between gold rules on a dark band that fades out at its ends. A wave with a mini boss reads **MINI BOSS** over its name. The boss wave reads **BOSS** over the boss's name, larger and in red. It slides in and fades for 0.2 s, stays 1.6 s, and fades out. It sits at `Hud.TIPS_TOP + 70` (`TIPS_TOP` is 180, under the tips), runs only while the game does, hides with the HUD and never takes input.

### Top right – Loot
- Stage gold: a coin and the amount, in the HUD panel style (Phase 3).
- Essences collected in this stage (blue, orange, purple).
- **Built in Phase 6:** each essence shows in the same panel, right of the gold, once at least one has dropped in this stage.

### Top left – FPS
- "FPS N", only when **Show FPS** is on in Settings. It moved here from the top center in Phase 6.

### Bottom right – Radar (minimap)
- Shows only dots, no terrain.

| Marker | Look |
|---|---|
| Lucian | Blue dot |
| Normal enemy | Red dot |
| Elite | Bigger red dot |
| Mini boss / Boss | Red skull icon (same size as the elite dot) |

**Built in Phase 6:**
- A dark panel 260 px wide; its height follows the map's shape (160 px for the mid lane). It sits 12 px in from the corner and never takes clicks.

| Marker | Look |
|---|---|
| Lucian | Blue dot (r 6) with a white ring, drawn last |
| Normal enemy | Red dot (r 4) |
| Elite | Red dot (r 7) |
| Boss | Red skull, 16 px |
| Mini boss | Red skull, 12 px *(Phase 7)* |
| Senna | Small pale-blue dot |
| Merchant | Gold dot, during breaks |

An untargetable enemy (the Elder Dragon in the air, Dark Lucian mid-dash) leaves the radar until it is back *(Phase 7)*.

*(V2.0: the radar is a plate with a gold diamond at each corner of its frame. The dots are as above.)*

### Act 1 tips
- On Act 1's first play, tips show one at a time under the boss bar, in a gold-bordered panel, 7 s each. The list is in `act1_the_loss.md`.
- The time only runs while the game does. A replay has no tips.
- *(V1.5.0)* The same banner shows Endless's milestones, the first time a save wins wave 10, 20, 30 or 40: "Wave 10 won for the first time: +300 blue and +5 orange essence" (game design doc §14).
- *(V2.0)* The tip banner is a plain plate with a gold diamond before the text. It sits at `Hud.TIPS_TOP` (180), under the boss bar and the next-wave preview.

### On the battlefield
- **Lucian's HP bar** above his head: green, with his shields as a white segment after the HP.
- **HP bars** above enemies, with a special icon for elites.
- **Damage numbers:**

| Damage type | Color |
|---|---|
| Physical | Orange |
| Magic | Blue |
| True | White |
| Critical hit | Bigger text |
| An enemy's heal *(V1.5.0)* | Green "+N", Heal's green, at the normal size |

- *(V1.5.0)* **Enemy heals** show as a green "+N" over the enemy: the Ocean Drake's mist, the Maiden of the Mist's drain and summons, and Thresh's harvest. (The Black Mist heals only veiled enemies, so its regen never shows a number.) Heals within 0.4 s of the first are added into one number, so a steady regen shows one number at a time, and one that rounds to 0 shows nothing. A veiled enemy shows none. Grievous Wounds lowers the number with the heal.
- **Skill warnings:** line and circle indicators for enemy attacks.

**Built in Phase 6:**
- Damage numbers over Lucian are 80% the size of those over enemies.
- **Ground warnings** are red: an outline, and a fill that grows until the attack lands. Shapes: a circle (siege shell, Heroic Swing), a line (Thresh's hook, Avengerang), a cone (Flay) and a thin lock line that follows Lucian (Comeuppance).
- An elite's HP bar has a small gold diamond at its left end; a boss's bar is wider. Statuses such as Empower show as small icons above the bar.
- Items on the ground: the item's icon over a bobbing glow (gold for a legendary). "Backpack full" rises in red when Lucian can't pick one up.
- Essences rise over a kill as "+1" with their icon.

**Built in Phase 7:**
- A mini boss has a boss-size health bar.
- More ground warnings in the same red style: Fire Breath and Elder Breath cones, Meteor Fall's four circles, Tidal Wave's wide line, the Sky Dive landing circle, Piercing Light's line and The Culling's wide line. The ground left burning after Fire Breath and Meteor Fall glows like lava.
- **Elder's Mark:** a sigil over Lucian's head and a violet ring round him that empties over 4 s; the ring turns red while he is under 25% HP.
- **Sky Dive:** only a dark shadow shows while the dragon is up.
- The Tidal Wave is a wide wave front with a foam crest, not a ball (visual pass).
- Floating text: "Escaped!" over a Scuttler that gets away, "Interrupted!" in gold over the Ocean Drake, with stars circling its head while it is dazed.
- **Terrain:** lava pools (a molten orange glow with a dark crust), shallow water (pale blue with ripples), Honeyfruit (golden fruit; an empty stalk while it regrows), Blast Cones (a yellow-green bulb, 108 px, glowing while ripe; a bud swelling back while it regrows). *(V1.4.3: a ripe cone also draws a faint ring in its soft yellow at its 350 reach, brighter while Lucian stands inside. While a shot would throw him, a ring his body's size marks where he would land, with a faint dashed line from him to it. The marks lie over the lava and under the units, and none show while it regrows.)*
- **A + Left-click:** pressing A shows Lucian's attack range as a ring and turns the cursor into a cross until the click.

**Built in Phase 8:**
- **The red word under Lucian's health bar:** "Rooted", "Stunned" or "Feared" while it lasts, in red (`#ff4040`) at 18 px with a thick black outline, so it reads over any floor (the visual pass raised it from 14 px). The strongest shows: stun, then fear, then root.
- **More ground warnings**, in the same red style: a **ring** band (The Box), a thin line (Wall of Pain, a rider's charge, a warden's chain, Maokai's vine line, Elise's Cocoon), the wide Onslaught band (300), circles (Lay Waste, Twisted Advance, Rappel, Dark Passage, the sapling's blast on its own spot) and the Defile ring, a purple ring that stays on Karthus.
- **Spectral walls** (Wall of Pain, The Box): pale, glowing slabs that fade out at the end. A Box piece that Lucian breaks goes at once.
- **The vine wave** is a wide green front, as the Tidal Wave is blue.
- **The Black Mist:** pale green-grey banks under the units that breathe slowly. A veiled enemy is a black silhouette with no bar and no radar dot. *(V1.5.0: and no green heal number, though the mist heals it while it is veiled.)*
- **Karthus's Requiem:** a pulsing purple ring on Lucian and a filling ring round Karthus, with the break bar on the boss bar. "Broken!" rises in gold over him.
- **Freed souls** rise and brighten into teal-white and fade upward; the dissolve of Thresh's body at the ending also fades his aura and bar.
- **The abyss** is near-black with slow green swirls; the Chain Warden ledges are rock islands with chains.
- **Hecarim's charge** has a glowing teal trail, and his ride shows four ghost riders beside him.

**Built in Phase 9:**
- **The level-up burst** (`LevelUpBurst`), on every level gained (never at a stage's start, never for a level lost on the debug table), with the `level_up` chime:
  - A gold ring (`#ffcf5a`), seen at a slant (96 × 32), with 8 sparks. It starts at Lucian's feet, rises 96 px to over his head while it shrinks to 70% and turns, and fades out.
  - "Level 7" in gold floats up from just over his HP bar.
  - It lasts 1.2 s (the floating text's time) and moves with him.
  - On Low quality only the text shows.

**Built in V2.0 (units and combat):**
- **`Juice.on()`** (`src/combat/juice.gd`) gates the extras below. It is false on Low quality and when the game runs headless (the tests and the bots), true otherwise. Shadows and health bars are no extras: they always show.
- **Shadows and motion.** Every unit has a soft shadow on the ground. With `Juice.on()`: a walk sway, a lunge on a melee hit, a recoil on a shot, a squash when hit, a spawn fade-in and a death burst.
- **Health bars.** An enemy's bar has a dark frame and a gradient fill. A pale **ghost** of the lost health holds 0.3 s, then drains (with `Juice.on()`). An elite's bar has a gold rim and diamond. Lucian's bar is green with a tick every 100 HP. The damage-number rules above are unchanged.
- **The target ring** (`TargetRing`): a thin red ring on the ground under the enemy Lucian is ordered to attack. It fades in on a new target and goes when the order goes.
- **Shots** have a soft glow and trail (`ShotGlow`; not on skin shots). A hit makes a small **spark** (`HitSpark`). Damage numbers **pop** when they appear; a crit's is bigger.
- **Warnings:** a ground warning keeps its red fill. It gains a dark underline and marching dashes along its edge (the dashes move only with `Juice.on()`).
- **Terrain pieces:** the Black Mist banks are layered mist with a darker heart and wisps, drifting slowly (the drift only with `Juice.on()`). Lava (every burn `HazardZone`) is a dark crust with glowing cracks, a hot core and a slow pulse. Shallow water has deeper steps, ripples and glints. The Blast Cone and the Honeyfruit are drawn in code (`MapArt.leaf`), with a shadow, leaves and a bright head; `assets/art/stage/blast_cone.svg` and `honeyfruit.svg` are no longer used. The maps themselves: game design doc §12/§13.

### The End screen (`TheEndScreen`)
Built in Phase 8. Shown by `Game` on the **first clear of 6-5 only**, after the stage-end screen's button, then it goes where that button said.

```
                    [ title lantern, 200 px, green glow ]
                              THE END
                         Senna is free.
                      Story time: 6:23:41
                        Lucian: The Lantern
                          Made with Godot 4
      A fan game. League of Legends characters belong to Riot Games.
                           [ Continue ]
```

- A near-black background. **THE END** in gold at 84 px, "Senna is free." in green (`#8fe3b0`) at 34, "Story time" at 28 in the text color, the three credit lines small and dim. **Continue** is 420 × 64.
- **Story time** is the slot's play time as H:MM:SS (the stage-end screen's clock is M:SS and rounds up, so it isn't reused).
- **Continue:** Main screen → the main screen on Act 6; Retry → 6-5 again. If the save failed, the main screen shows the "Could not save" toast. *(V1.5.0: the Journey opens on Training then, since every stage is cleared.)*
- **ESC does nothing here** (it is consumed). The window's close button still asks to quit.
- The first two credit lines ("Lucian: The Lantern", "Made with Godot 4") are placeholders.

**Built in V2.0:** the sketch above is the old look. Now `TheEndScreen` shows **the title's scene** (Lucian and Senna, Thresh hidden) under a dawn tint, and an ornate card stands on the right (centred in the part right of 36% of the width, so it never covers Lucian's arm or Senna). The card holds THE END, "Senna is free.", the story time and the credits, with **Continue** under them. The texts, ESC and the continue targets are as above.

### Stage result: the end screen
*(Phase 6 had a 560 px panel with one Continue button over the HUD. Phase 7 replaced it with this full-screen summary.)*

```
┌──────────────────────────────────────────────────────┐   full-screen dim 0.85 + a soft
│                    STAGE CLEARED                     │   gold (clear) or dark red
│               Stage 3-2 · The Jungle                 │   (defeat) radial glow
├──────────────────────────┬───────────────────────────┤
│ STATS                    │ REWARDS                   │
│ Time             0:20    │ ◆ +275 blue essence       │
│ Waves            4 / 4   │ ◆ +7 orange essence       │
│ Kills            49      │ ◆ +5 purple essence       │
│ Damage dealt     41.2k   │ +5 purple essence         │
│ Damage taken     6,140   │   (Infernal Drake, first  │
│ Gold earned      3,609   │   kill)                   │
│ Level reached    5       │ Stage 3-3 is open         │
├──────────────────────────┴───────────────────────────┤
│      [ Retry ]      [ Next stage ]      [ Main screen ]     │
└──────────────────────────────────────────────────────┘
```

- **When:** at the end of a stage, cleared or lost. The game pauses, the HUD hides, and ESC and P do nothing while it shows.
- **Banner:** **STAGE CLEARED** in gold, or **DEFEATED** in red. Losing Act 1 before its first clear reads **GAME OVER** in red. Under it, the stage's name.
- **Stats** (left column): Time, Waves, Kills, Damage dealt, Damage taken, Gold earned, Level reached. Numbers have commas under 10,000 and read "41.2k" above.
- **Rewards** (right column): each essence collected, with its icon and color ("+275 blue essence"; "No essences" when there are none), then the lines in green: first-clear or repeat purple, a mini boss's purple, Act 1's lines, "Stage 3-3 is open" or "Act 4 is open".
- **Buttons** (each auto-saves first; **Main screen** is lit in gold):

| Outcome | Buttons |
|---|---|
| Cleared | Retry · Next stage (hidden when there is no next stage to play) · Main screen |
| Defeated | Retry · Main screen |
| Game over | Back to title |

- **Retry** starts the stage again. **Next stage** starts the next one. **Main screen** opens the main screen on that act *(V1.5.0: on the latest open stage, or Training once every stage is cleared; `main_screen.md`)*. **Back to title** goes to the title screen. If the save fails, Retry and Next go to the main screen with a red "Could not save" toast.
- **Built:** the panel is 1040 px wide in the HUD panel style. Title 56, stage name 26, section heads 20 (dim), rows 22 (label left, value right), reward lines 20. Buttons 260 × 60, text 24.
- **Sounds (Phase 9):** `victory` with STAGE CLEARED, `defeat` with DEFEATED, GAME OVER and RUN OVER (§8).

**Built in V2.0 (`StageResult`):** the layout above stays; the look and one block are new.
- **The card:** the game stays blurred behind an **ornate plate**, 1040 px wide. The **lantern medallion** sits on its top edge: warm and lit for STAGE CLEARED, dim and red for DEFEATED, GAME OVER and RUN OVER. The title is large (60), in spaced capitals, with a soft glow in the outcome's colour (gold or red). The stage's name sits between two short gold rules. The screen's own radial glow is gold (clear) or dark red (defeat).
- **STATS and REWARDS** are two columns with spaced-capital heads. A stats row is a faint dark well with an icon in its left margin (Time, Kills, Damage dealt, Damage taken, Gold earned; the other rows have a gold diamond). Each essence has its icon.
- **Count-up:** the essence amounts count up from 0 over about 0.6 s, fast at first. On Low quality the final numbers show at once.
- **Resolve line:** after a defeat that gives the next try Resolve stacks, a green line in REWARDS: "Resolve 3 / 5: +30% damage, -30% damage taken on your next try" (§5; game design doc §3). With the setting off, on a cleared stage and on Extreme there is none.
- **WHAT HIT YOU** (`DeathRecap`, R3): after DEFEATED, GAME OVER and RUN OVER, a third block under the two columns, only when Lucian took damage in the stage (`StageStats.record_hit` keeps the sources). Its lines:
  1. **"Killed by <name>"** in red. A burn names its source: "Killed by burning ground" for a ground zone, "Killed by Gromp's burn" for an enemy's burn.
  2. **The top three damage sources** as shares of the damage taken, side by side ("Gromp 52%   Krug 30%   Burning ground 18%").
  3. **One tip**, in the lantern's teal, chosen by the top source.
  4. **"You can afford an upgrade in the Evolution Tree."** when the save's essences can buy some open node.

  A clear never shows the block.

| Top source | Tip |
|---|---|
| A boss or mini boss | "Watch the boss's red marks: each skill shows where it lands before it hits." |
| A siege enemy (red marks) | "Red marks on the ground show where a hit will land. Step out before they fill." |
| An elite | "Elites hit hard. Kill the small ones around them first, then keep your distance." |
| A ranged enemy (ranged, spit) | "Ranged enemies: step sideways between their shots, or walk in and kill them first." |
| Any other enemy (melee) | "Melee enemies: shoot, step back, shoot again. They can't hit what they can't reach." |
| Burning ground | "Burning ground keeps hurting while you stand on it. Walk out at once." |

**RUN OVER (Endless, built in Phase 9).** When Lucian dies in an Endless run, the same screen shows the run:

```
                 RUN OVER                      (red, like DEFEATED)
          Endless · Dark mid lane
 STATS                      REWARDS
 Waves cleared      22      ◆ +208 blue essence
 Time            22:11      ◆ +1 orange essence
 Kills              34      New best: 22 waves!
 Damage dealt      123
 Damage taken      313
 Gold earned     4,850
 Level reached      16
 Modifier  −10% max HP
        [ Retry ]      [ Main screen ]
```

- The title is the optional `title_text` of `StageResult.show_result`; its red color and glow are the defeat's.
- **Stats:** Waves cleared first, in place of "Waves N / M", then the usual rows, then **Modifier**: the current modifier's downside, or "None" (none picked yet, or Nothing).
- **Rewards:** the essences, then a green **"New best: 22 waves!"** ("New best: 1 wave!" for one) when the run cleared more waves than the best it started with. *(V1.5.0: and a green line for each milestone paid in the run, "Wave 10 won for the first time: +300 blue and +5 orange essence"; its essence is in the essence lines.)*
- **Buttons:** **Retry** (a new run on the same map choice; Random rolls again) and **Main screen** (the Journey on Endless, with the run's map still chosen). There is no Next. *(V1.5.0: Main screen opens the Journey on the latest open stage, or Training once every stage is cleared. The map choice is still saved.)*
- With the longest Modifier text ("Bosses and mini bosses +25% max HP") the panel grows to about 1074 px wide.

### Endless: the modifier pick (`ModifierPick`)
Built in Phase 9. After each Endless boss wave (10, 20, …) the break waits for a pick.

```
┌────────────────────────────────────────────────────────┐
│                  Choose a modifier                     │
│  ┌────────────┐   ┌──────────────────┐   ┌──────────┐  │
│  │     ♥      │   │       boot       │   │          │  │
│  │ −10% max HP│   │ Enemies move 20% │   │ Nothing  │  │
│  │ +15% blue  │   │ faster  +30% gold│   │ Nothing  │  │
│  └────────────┘   └──────────────────┘   └──────────┘  │
└────────────────────────────────────────────────────────┘
```

- A centered panel over a 0.55 black backdrop, on layer 36: over the HUD (10) and the backpack (30), under the menus, the result and the prompts. The backdrop eats clicks, so the HUD's Skip under it can't be pressed.
- The title "Choose a modifier" (32, gold). **3 cards** (280 × 230 buttons): 2 modifiers drawn from #1–5 (never the current one), then **Nothing** last.
- A card shows the modifier's icon (64 px; none for Nothing), its downside in red and its reward in green (20 px). A long downside wraps to 2 lines.
- The game is paused, and the backpack and the menu are closed. ESC and P do nothing. A click picks (only the first click counts), plays `buff`, closes the panel and lets the full 20 s break count down.
- The modifiers and what they do are in the game design doc §14.

**Built in V2.0 (`ModifierPick`, `ModifierCard`):** the title reads **CHOOSE A MODIFIER** in spaced capitals between gold rules, over three ornate cards (320 × 250). Each card has the modifier's icon in a medallion on its top edge (Nothing has a diamond), the downside in red over a rule and the reward in green. A hovered card **lifts** 10 px and its rim turns gold with a soft light (on Low quality only the rim changes). The button keeps its place, so the mouse never falls off a lifted card. The layer, the backdrop, the pause and the pick are as above.

### Cutscenes
- Black bars (120 px) at the top and bottom; the HUD hides.
- The speaker's name in gold over the caption, in the bottom bar.
- **Skip** at the top right. Space or a left-click moves to the next caption.
- **Built in Phase 8:** `SennaFreed`, the ending (`act6_the_lantern.md`), uses the same bars, captions and Skip; a white fade follows it.

---

## 2. Backpack (P)

- Press **P** to open. The game **pauses immediately**.
- Can be opened at any time, including during a wave.
- While open, the player **cannot use skills or item actives**.
- Title at the top: **BACKPACK**.
- *(V1.4.3)* It recentres whenever the window changes size (fullscreen from the ESC menu's Settings, say), shown or not, with the merchant's shop beside it when that is open.

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

*(Phase 10: 6 rows of 9, 54 cells, and only the open ones take items; see "Built in Phase 10".)*

### Layout
- **Rows 1–7:** 49 backpack slots (7 per row), in a light tan style like the reference image. *(Rows 1–6, 9 per row, since Phase 10.)*
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
| **Right-click a potion** | ~~Shows a small pop-up **Use** button~~ Does nothing since V1.4.1: potions are drunk with keys 7 and 8 |

### Drag and drop
| Drop target | Result |
|---|---|
| Empty cell | Item moves there |
| Outside the backpack | Item returns to its original cell |
| Locked equip slot | Item returns to its original cell |
| Same type of potion | Stacks into the target cell (max **9** per cell); the rest returns to the original cell |
| An item it can **craft** with | ~~See *Crafting* below~~ Since V1.4.1 they just swap: crafting is the merchant's Craft tab (§3) |
| Any other item | The two items **swap** places |
| Sell slot (shop open) | Item is **sold immediately** |

### Crafting
*(Until V1.4.1. Since then, crafting is only at the merchant's **Craft** tab, for a fee (§3): a fragment dropped on its partner swaps, and the pop-up below is gone.)*

1. Drag an item onto another item that forms a valid recipe.
2. While hovering, a **small pop-up table** shows the legendary item that would be crafted, so the player can read it and decide.
3. A **line runs around the pop-up's border**, starting at the top-left, going all the way around and back to the top-left. This is the **minimum hold time** to craft: **1 second**.
4. **Release after the line completes** → the two items are combined. The legendary appears in the target cell, and the original cell becomes empty.
5. **Release before the line completes** → the two items just **swap**.

If the two items are not a valid recipe, no pop-up appears and they swap.

### Potions
- Up to **9 potions** stack in one cell.
- ~~**Right-click → Use.** The game is paused, so healing **starts when the backpack is closed**.~~ *(Removed in V1.4.1.)*
- Put it in its potion cell and press **7** (Health) or **8** (Mana) during play; nothing happens while Lucian can't act. *(Since V1.4; before, any equip slot and 1–6. Potions no longer go in equip slots.)*

### Built in V1.4
```
  [1][2][3][4][5][6][S]   <- equip strip
  [B]          [7][8]     <- gear strip, as wide
```
- **The gear strip** sits under the equip strip, in the same dark style: the **boots cell** on the left (steel border), then the **Health** and **Mana potion cells** on the right (red-brown border, keys 7 and 8 in the corner). None of them is ever locked.
- **Empty cells show what goes in them, faded** (about 30%): the potion cells their potion, the boots cell Boots of Speed. Hovering an empty one says "Health potions go here: press 7 to drink one" or "Buy Boots in the Evolution Tree". *(V1.4.3: a cell whose item sits in a merchant's Craft input draws empty too, and can't be dragged, sold or dropped on. Hovering it says "In the Craft tab: drag it back here, or right-click its input". §3.)*
- **Potion cells** take only their own potion (Health or Mana), 9 at most. Bought potions fill them first, then the backpack. They are never refilled by themselves.
- **Equip slots refuse potions**, both ways: a potion dropped on one goes back, and so does a swap that would send one there. A potion bought onto one says "That item can't go there".
- **The boots never move.** Dragging them anywhere sends them back, except onto the merchant's Boots tab (§3; the Craft tab since V1.4.1). *(V1.4.3: while they sit in a Craft input, the boots cell shows the faded Boots placeholder.)* Dropped on the sell slot, they read **NO** and "Boots can't be sold".
- The screen keeps one cell per inventory index in order (0–62), then the sell slot.

### Recipe table
- Shown automatically when the backpack is open, in the **top-left of the screen**. The backpack sits in the **center**.
- ~~**Hidden** while the merchant's shop is open.~~ *(Since V1.4.1 it stays while the shop is open, since crafting happens there; it sits clear of the backpack.)*
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
- **Recipe hints (V1.4.2):** a fragment's card in the shop lists what it builds into with the items you hold: "Builds into **Muramana** with Tear (you have it)", one line for each partner you own in a backpack or equip cell. At most 3 lines, then "+N more". An extra line, "Upgrades your Boots into X", shows when the fragment fits the boots you wear. With no partner owned, the usual footer stays. Cards elsewhere (backpack, HUD) don't show hints.
- Each stat line is the **stat icon, the amount in the stat's color, then the name**, e.g. `[axe] +65 Attack Damage`.

### Built in Phase 10
- **54 cells: 6 rows of 9.** The equip row below is unchanged.
- **Only the open cells take items.** A new game opens 5: the first 5 cells. The others show a chain, like a locked equip slot, and hovering one says "Buy Backpack Slots in the Evolution Tree". The tree's Backpack Slots opens more, up to all 54 (game design doc §11).
- Which cells are open is read from the tree when a stage starts, before the equip slots, so items leaving a locked equip slot land in an open cell. A stage run on its own opens all 54.
- **Drag and drop:** a drop on a locked cell returns the item to its cell.
- **When the open cells are full:** loot stays on the ground ("Backpack full" over Lucian), a right-click buy says "No room in the backpack", and a buy dragged onto a locked cell says "That cell is locked". *(V1.4.2: **empty, unlocked equip slots are used before this.** A fragment or legendary goes to an open equip slot once the backpack is full, and applies its stats at once. Loot and shop buys both do it. Potions never go to equip slots, and the backpack comes first. The messages above show only when the equip slots are full too.)* *(V1.5.0: the equip slots are no longer used, so loot stays on the ground with "Backpack full" as soon as the open cells are full. A buy that would go into the backpack is declined with a pop-up, "Your backpack is full.", in place of the red "No room in the backpack". See "Built in V1.5.0" below and §3.)*
- **Debug:** the stage debug table has a "Backpack slots" spinner (1–54).

### Built in V1.5.0
- **A full backpack takes nothing.** Buys and loot go only into the open backpack cells (and a potion into its potion cell first), never into an empty equip slot: V1.4.2's spill is gone. Loot stays on the ground with the red "Backpack full" (at most every 3 s). A buy with no open cell free is declined with a pop-up (§3).
- **One penetration item.** Of Lord Dominik's Regards, Mortal Reminder and Void Staff, only one can be in the equip slots. A drop or swap that would equip a second one sends the item back, with the error sound and a one-button pop-up on the menus' card: "Only one penetration item can be equipped, and Lord Dominik's Regards already is." OK, Enter or ESC closes it. A move or swap inside the equip row is allowed. Shadowflame's flat penetration doesn't count, nor do boots (`items.md`).
- The pop-up (`ConfirmPopup.tell`) closes without answering when the backpack closes under it.

### Built in V2.0
**A new look; the layout, the cells and the rules are as above.** The light tan and darker bottom row the Layout section describes are gone.
- **The backpack** is an ornate plate headed BACKPACK. Its cells are dark wells whose rim follows the item (fragment, legendary, boots, potion). A locked cell is darker, with the chain.
- **The equip row and the gear row** sit on plain plates, with the keys in corner tabs.
- **The recipe table** is a plate headed RECIPES. Each line names its legendary after "[fragment] + [fragment] = [legendary]". A recipe whose two fragments Lucian holds is **lit gold** (a gold wash and a thin gold frame) and comes first, so what can be crafted shows without scrolling; a held fragment has a gold rim. A note under the heading reads "Lit gold: you hold both fragments." (`RecipeTable`, `RecipeRow`).
- **Fade-in:** the backpack and the shop fade in over 0.12 s (not on Low quality).

---

## 3. Merchant's shop

- Opens when Lucian walks to the merchant during the break between waves.
- The game **pauses** while it is open (including the break timer).
- While open, the player **cannot use skills or item actives**.

```
+---------------------+   +-----------------------------+
|      BACKPACK       |   | [ Items ] [ Potions ] [Craft]|
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
- **Items tab:** always shows **4 slots** in a row. Slots not yet unlocked (Evolution Tree) are covered by a **chain lock**. *(V1.4.3: right-clicking one says "That slot is locked", not "Already sold", and hovering it says "Buy Merchant Stock in the Evolution Tree".)*
- **Refresh** button in the **bottom-right corner** of the shop (costs stage gold). *(V1.3.1: greyed out, and refused for free, once every open slot is sold: there is nothing left to re-roll.)*

### Built in Phase 3
- **Opening:** right-click the merchant. Lucian walks over; the shop opens once he is within 250 units (right away if he already is). Hovering the merchant shows a gold ring.
- **Header:** "MERCHANT" and the stage gold. ~~The recipe table is hidden;~~ *(it stays since V1.4.1)* the backpack and the shop are centered side by side.
- **Slots:** 64 px, the price with a coin under each (red when it can't be afforded). A bought slot shows **SOLD** for the rest of the visit, even after a refresh.
- **Buying:** right-click a shop item to buy it into the first cell it fits, or **hold-drag** it onto a backpack or equip cell. Dropping it on an occupied cell (other than a stack of the same potion with room) buys nothing. *(V1.4.2: a drop on a taken cell buys into a free cell instead, and says "No room in the backpack" only when none is free. A locked or wrong cell keeps its message.)* *(V1.5.0: a right-click, or a drop on a taken cell, buys into the backpack only. With no backpack cell free, a pop-up says "Your backpack is full." and nothing is bought. A drop on a free equip slot still buys there, unless it would equip a second penetration item.)*
- **Refused purchase** (not enough gold, no room): a red message in the bottom row and the price flashes red, with an error sound. *(V1.5.0: no room, and the one-penetration rule, are told in a pop-up instead of the red message; see "Built in V1.5.0".)*
- **Selling:** the 7th equip-row cell turns red and reads **SELL**. Dragging an item over it shows "+N" and "Sells for N gold"; releasing sells it (a whole potion stack at once).
- **Closing:** ESC or P. The game stays paused while the shop is open.

### Built in V1.4
- **Three tabs:** Items, Potions and **Boots**. Refresh shows on Items only. The hint line under the tab follows it.
- **The Boots tab:** `[boots] + [fragment] → [new boots]`, the fee (coin and gold, red when it can't be paid), an **Upgrade** button and a note line.
  - Drag the boots (from their cell) onto the first slot and a fragment (from any cell) onto the second. Anything else is refused: "Only boots go there" / "Only a fragment goes there". A right-click empties a slot.
  - The slots hold the inventory cell, not the item, so nothing has to be given back: they are emptied when the shop closes and whenever their cell no longer holds what they take. *(Replaced in V1.4.3: an item in an input leaves the backpack view until it is given back; see "Built in V1.4.3".)*
  - The third slot shows what the two make. **Upgrade** is off until they make something; pressing it pays the fee, uses up the fragment, puts the new boots in the boots cell and plays the craft sound.
  - The note: "No boots: buy them in the Evolution Tree" with an empty boots cell; otherwise what to drag next, "That fragment doesn't upgrade …", "… are fully upgraded." or "Old → New".

### Built in V1.4.1
- **The Boots tab becomes the Craft tab**, for both crafts: `[input] + [input] → [result]`, the fee, a **Craft** button and a note line. The backpack no longer crafts.
  - **Two fragments** make their legendary. The fee is the legendary's cost minus the two fragments' costs, so crafting never makes gold when the legendary is sold. The legendary takes the first input's cell (an equip slot stays equipped); the second is emptied. *(V1.5.0: when the first input's cell is an equip slot the one-penetration rule closes to the legendary, it takes the second's instead; with both closed, Craft is refused with the rule's pop-up.)*
  - **The boots and a fragment** (either way round) make the upgraded boots, for their old fee.
  - Each input takes a fragment or the boots; anything else says "Only fragments and boots are crafted". The placeholder reads ITEM. A right-click empties an input; they are emptied when the shop closes. *(V1.4.3: also when the tab changes, and the item comes back to its cell; see below.)*
  - **Craft** is off until the two make something; the fee is red when it can't be paid ("Not enough gold"). Pressing it pays the fee, uses both items up and plays the craft sound. *(V1.4.3: it asks first, and a craft empties both inputs; see below.)*
  - The note: "Drag in two fragments, or your boots and a fragment.", "Now drag in a fragment.", "… are fully upgraded.", "X doesn't upgrade …", "No legendary is made from X and Y." or "X + Y → Z".
- **The recipe table stays** beside the backpack while the shop is open.
- **Cards:** a fragment's says "Craft it with another fragment at the merchant's Craft tab."; a legendary's "Recipe: X + Y + N gold at the merchant."
- **No Use button** in the backpack (see §2, Potions).

### Built in V1.4.2
- **Undo sale:** a button in the bottom row, on every tab (you can sell from any tab). It is greyed while nothing is sold. Its hover card names the last sale: "Buy back Muramana for 2030 gold".
  - Each press buys back the **last** thing you sold, and again for the one before it, until you leave the merchant. A new visit starts with nothing to undo.
  - It costs the gold you got for it. Without enough gold it says "Not enough gold" and keeps the sale. The item returns to its old cell if that is still empty and fits; otherwise to any free cell, or "No room in the backpack". *(V1.5.0: an old equip cell takes it only if the one-penetration rule allows; otherwise, or when it is taken, it goes to a free backpack cell. With none, the "Your backpack is full." pop-up shows and the sale stays to undo.)*
  - **Limits:** the stacks and cooldowns of an equipped item that is sold and bought back are not restored.

### Built in V1.4.3
- **A Craft input holds its item out of the backpack.** An item dragged into an input leaves the backpack view: its cell draws empty and can't be dragged, sold or dropped on, so one fragment can't fill both inputs. Hovering the cell says "In the Craft tab: drag it back here, or right-click its input". The boots cell shows its faded Boots placeholder. The item stays in its inventory cell, which still counts as taken.
  - **It comes back** when it is dragged out of the input (onto a free cell it moves there; anywhere else it returns), on a right-click on the input, when the merchant's tab changes, and when the merchant closes.
  - Dragging one input onto the other moves it there, or swaps the two when both are full.
- **Craft asks first:** "Craft Muramana from Tear of the Goddess and Tear of the Goddess for 1600 gold?" *(2100 before V1.5.0's fragment prices.)* Yes crafts; No (or ESC) changes nothing. Enter is Yes. A fee you can't pay is refused at once with "Not enough gold", without asking.
- **A craft empties both inputs.** The legendary shows in the first input's cell, and upgraded boots in the boots cell.
- **A locked slot:** right-clicking a chained Items slot says "That slot is locked" (it said "Already sold"). Hovering it says "Buy Merchant Stock in the Evolution Tree", the tree node that opens it.
- **The Potions tab's hint** names the potion keys as bound now, in full ("Potions fill the 7 and 8 cells first, then the backpack."), and follows a rebind.

### Built in V1.5.0
- **A full backpack refuses a buy.** A buy goes into the backpack (a potion into its potion cell first). With no open backpack cell free, a one-button pop-up says **"Your backpack is full."** (OK, Enter or ESC closes it), the price flashes red with the error sound, and nothing is paid. It replaces the red "No room in the backpack". The one way past it: drag the item onto a free equip slot, which still buys it there.
- **One penetration item.** A buy dropped on a free equip slot, a craft, or an Undo sale that would put a second of Lord Dominik's Regards, Mortal Reminder and Void Staff in the equip slots is refused or sent elsewhere (above), and the pop-up names the one equipped: "Only one penetration item can be equipped, and Mortal Reminder already is."
- **Lower craft fees.** The fragments cost 650–1100, so the fees run 900–1600 (`items.md`). The Craft question, the fee line and the legendary cards' "Recipe: X + Y + N gold" follow.
- An open notice closes, unanswered, when the merchant closes.

### Built in V2.0
**A new look; the tabs, prices and rules are as above.**
- **The merchant** is an ornate plate headed MERCHANT, with the Items, Potions and Craft tabs and the stage gold beside them. The panel keeps one size on every tab, so the backpack beside it never moves. It fades in with the backpack (0.12 s, not on Low quality).
- **Each item for sale is a row** (`ShopSlot`): its icon in a well whose rim follows the item, its name, a line with its main stats (a potion's effect), and its price with a coin on the right. A bought slot reads **SOLD**; a locked slot reads "Locked" with its chain and the Evolution Tree node that opens it. A potion row shows its key in the well's corner.
- **The Craft tab** is a bench: the two inputs, "+", an arrow, the result, a note, the fee and the Craft button. The tab shows where it stands, and the note, the button and the fee follow it:

| State | Note | Button |
|---|---|---|
| Empty | "Drag in two fragments, or your boots and a fragment." (dim) | Craft, off |
| One item in | "Now drag in a fragment." (or "<Boots> are fully upgraded.") | Craft, off |
| No recipe | "No legendary is made from X and Y." (red) | "No recipe", off |
| Cannot afford | "X + Y → Z" | "Not enough gold", off; the fee is red |
| Ready | "X + Y → Z" (pale gold) | Craft, lit gold |

The result cell is gold once the craft can be paid for, shows a red cross when the two inputs make nothing, and a faint "?" until both are in (`CraftSlot`).

---

## 4. Menu (ESC)

- Press **ESC** to open. The game **pauses**.
- Can only be opened when the backpack or merchant's shop is **not** open.
- Options:
  - **Resume**
  - **Settings** (cast mode, camera, volume, etc.)
  - **Leave this stage** (keeps all essences collected; the game auto-saves). Works since Phase 5: the stage counts as left, the game saves to the current slot and goes back to the main screen. Since Phase 6, Journey opens on the act just played (after Training: the first act with a stage left to clear, else Training). *(V1.5.0: always on the latest open stage, or Training once every stage is cleared.)* When `stage.tscn` runs on its own, it stays disabled ("Not available yet").
  - **Exit the game** (asks **"Save before leaving?"** Yes / No; see the game design doc §15)
- **Built in Phase 9: both exits ask, and both can be cancelled.**
  - **Leave this stage** asks **"Leave this stage? Essences collected so far are kept."** with **Leave / Cancel**. In Endless it asks **"Leave this run? Your best wave is kept."** Leave ends the stage as before. Cancel, or ESC, goes back to this menu, still paused. The menu only emits its request; `Game` asks.
  - **Exit the game** asks **"Save before leaving?"** with **Yes / No / Cancel**. Cancel, or ESC, goes back to this menu, still paused.
  - The question sits over the menu (`Game`'s prompt, layer 90) and reads ESC first, so the menu doesn't close under it.
  - After a Leave, the Journey opens on the act just played, or on Endless after an Endless run (`main_screen.md`). *(V1.5.0: on the latest open stage, or Training once every stage is cleared, whatever was left.)*
- **Menu keys (V1.4.2): arrow keys and Enter work the menus.** (`MenuKeys`, `src/ui/menu/menu_keys.gd`.)
  - **Where:** the title menu and its slot and difficulty pages, this ESC menu, the main screen's gear menu and its slot page, and every confirm pop-up.
  - **Keys:** Up and Down (and Left and Right) move a lit row. Greyed and hidden rows are skipped, and the list wraps around. Enter or Keypad Enter presses the lit row. A held Enter is ignored (it doesn't repeat), so it can't answer the next pop-up.
  - **The lit look** is the row's own hover look (the gold row and bar, or the button's hover colours). Nothing is lit until the first arrow key, so mouse play looks as before. Once something is lit, the mouse moving onto a row lights that one, so the mouse and the keys agree.
  - **Pop-ups** open with their first button lit (Yes, or the action), so Enter answers at once. Left and Right move across the side-by-side buttons. ESC still answers as before. *(V1.5.0: a notice with OK alone, such as "Your backpack is full.", starts with OK lit, and ESC is OK too.)*
  - **Space** is untouched: it is still Center camera. Not covered: the skin and tree purchase pop-ups, the stage result panel, The End and Settings.
- **Built in V1.2: an ornate card.**
  - The menu is a card (`MenuCard`) over the game, which is blurred, darkened and vignetted behind it (`MenuBackdrop`).
  - The card has a navy-to-teal gradient, a double gold frame with a diamond at each corner, and a round lantern medallion over its top edge.
  - Under the spaced **MENU** title is the stage's name ("Stage 2-3 · The Sentinels", "Training", "Endless · Jungle") between two gold rules.
  - Each row (`MenuEntry`) has an icon. **Resume** is gold. **Settings** has the hint "Audio, controls, graphics".
  - **Leave this stage** and **Exit the game** turn red on hover. The other rows turn gold, with a bar at the left.
  - The Yes / No pop-ups use the same card.

## 5. Settings (from the ESC menu)

- Replaces the menu while open; **Back** or ESC returns to it. The game stays paused.
- Every change applies right away and is saved to `user://settings.json`. *(V1.4.3: it is written to `settings.json.tmp` and renamed. A failed rename keeps the `.tmp`, and loading falls back to it when `settings.json` is missing or broken; a `.tmp` that loads is renamed back to `settings.json` at once.)*
- **Tabs:**

| Tab | Contents |
|---|---|
| Audio | Master, Music and Sound effects volume (0–100). Releasing a slider plays a test sound. *(V1.4.3: a slider applies live while it is dragged and is saved once, when let go; a wheel or key step is saved at once.)* ~~No music yet.~~ *(V1.5.0: the Music slider sets the score, §8.)* |
| Controls | Every rebindable action with its key or mouse button (including Center camera, Space). Click one, then press a key or mouse button; ESC cancels. A double-click doesn't bind the left button (the second press is ignored); a separate later click still does. A key already used by another action swaps the two. **Reset to defaults.** ESC (menu) and F3 + Q (debug) can't be rebound *(V1.5.0: F3 + Q works only in a debug build; in the released game it does nothing)*; Ctrl + a skill key still ranks the skill up, and Ctrl + the stats key toggles the stats panel. Each skill, summoner and item key also has a **cast mode** picker: Quick cast, Quick + indicator, Normal cast (Reset to defaults sets them back to Quick cast). |
| Graphics | Window mode (windowed, borderless fullscreen, fullscreen), Resolution (1280×720, 1366×768, 1600×900, 1920×1080, 2560×1440, 3840×2160; sizes too big for a window on this screen, title bar included, are greyed out and marked "too big"; sets and centers the window, greyed out in borderless/fullscreen; *V1.3.1:* only at launch and when changed here, so starting a stage leaves a maximized or resized window alone), VSync, FPS cap (30/60/120/144/unlimited), Quality (Low: no anti-aliasing, no dash trails, muzzle flashes or summoner spell effects (Flash sparks, Ghost afterimages, Barrier bubble, Heal and Clarity bursts); Medium: 2× MSAA; High: 4× MSAA), Show FPS. |
| Gameplay | Cast queue (on by default; see the game design doc §2). It was called Skill queue before V1.4.2. *(V2.0: and Resolve, on by default.)* |

- **Not yet:** cast modes (normal / quick / quick with indicator) and camera options.

### Built in Phase 10
**A new look; the same settings and the same behaviour.** It is one screen, opened from the title, the main screen's gear menu and a stage's ESC menu.

| Part | Look |
|---|---|
| Panel | 1120 × 720, opaque navy with a gold border. A lantern medallion sits on its top edge with a green glow, over "SETTINGS" in spaced gold capitals and a gold rule with a diamond, as on the Journey panel. |
| Tab rail | 240 px on the left: Audio, Controls, Graphics and Gameplay, each with its own icon (a speaker, a mouse, a monitor, a gamepad). The open tab has a gold-tint fill and a gold bar at its left edge. Under the tabs: "Every change applies at once and is saved." |
| Pages | A title in spaced capitals, a dim one-line subtitle, a gold line, then one card per setting: its name, a short dim description where there is one, and its control on the right. A card's border brightens on hover. |
| Footer | Back, in gold, at the bottom right. Controls keeps **Reset to defaults**, beside its title. |

| Page | Subtitle and content |
|---|---|
| Audio | "Volumes change at once. Letting go of a slider plays a test sound." The three volumes, shown as whole numbers ("80"). "No music yet" is now the Music row's description. *(V1.5.0: it reads "Each act's score, which follows the fight.")* |
| Controls | "Click a binding, then press a key or click it again with a mouse button." The list is grouped: MOVE AND ATTACK, SKILLS, SUMMONER SPELLS, ITEMS, INTERFACE. A 2-line hint sits under it. A binding waiting for a key is lit gold and reads "Press a key...". |
| Graphics | "The window, the frame rate and how much the effects cost." The old notes are the Resolution and Quality rows' descriptions. |
| Gameplay | "How Lucian takes your orders." Cast queue, with its note as the description: a skill, item active or summoner spell pressed during a cast time or a dash is cast when it ends. *(V2.0: a second card, **Resolve**, a switch, on by default: "After each defeat on a stage, Lucian deals more damage and takes less there (up to 5 times)." Off turns every stack off at once, in a stage too; the defeats are still counted, so turning it on again brings the stacks back. Game design doc §3.)* |

**No grey default widget is left.** A theme made in code (`UiStyle.theme()`) styles every control:
- **sliders:** a dark rounded track, a gold fill, and a gold diamond handle that brightens on hover;
- **dropdowns:** navy with a gold border and a gold chevron. Their lists are navy too: the hovered entry is gold-tinted, the chosen one has a gold diamond, and "too big" sizes stay greyed;
- **switches:** a gold track with a check when on, a dark track with a steel knob when off;
- **scroll bars:** thin, with a gold handle;
- **separators:** a thin gold line.

---

## 6. Screens to design

- [x] Backpack layout
- [x] Crafting (drag and drop; at the merchant's Craft tab since V1.4.1)
- [x] Recipe table
- [x] Item info pop-up
- [x] Merchant's shop layout (built in Phase 3)
- [x] ESC menu
- [x] Settings
- [x] Evolution Tree screen (built in Phase 5, see `main_screen.md`)
- [x] Skin shop (built in Phase 5, see `main_screen.md`)
- [x] Main menu and save slot selection (the title screen, built in Phase 6, below)
- [x] Stage select (Journey: act, Training and Endless tabs, built in Phase 5; a world map since Phase 9; see `main_screen.md`)
- [x] Stage end screen (stats, rewards, Retry / Next stage / Main screen; built in Phase 7, above)

## 7. Title screen

The game opens here (built in Phase 6).

- A dark green radial background, Thresh's lantern (200 px) with its green glow, **LUCIAN** in gold and **THE LANTERN** in pale green. *(Phase 10: a Shadow Isles night with Lucian, Senna and Thresh replaces the background; see below.)*
- Four buttons (420 × 64): **Start new game**, **Load game**, **Settings**, **Exit game**.
  - **Load game** is disabled with no saved slot (hover: "No saved games yet").
  - **Settings** opens the shared Settings screen; Back or ESC closes it.
  - **Exit game** quits at once. So does the window's close button on this screen: nothing is unsaved here. *(Phase 9: both ask first; see below.)*
  - **Built in Phase 9:** **Exit game** and the window's close button ask **"Exit the game?"** with **Exit / Cancel**. Exit quits. Cancel, or ESC, stays on the title. There is no save question: nothing here is unsaved.
- **Start new game** and **Load game** turn the buttons into a slot list, titled "START NEW GAME" or "LOAD GAME", with **Back** (ESC works too):

| Slot | Reads |
|---|---|
| Empty | "Slot 3 · empty" (disabled in Load game) |
| Used | "Slot 2 · 1h 02m · saved 2026-10-29 03:10": its play time and when it was saved |

- **Built in V1.4.2:** if the new game can't be written to its slot, the game doesn't start. You stay on the difficulty page, and a red line on every page reads "Could not write slot N. The game can't start until it can save." with the error sound. The slot and the data in memory go back to what they were. Back, or going to the slot list, clears the line.
- A new game on a used slot asks "Overwrite slot 2? Its progress will be lost." (Yes / No). Yes writes the new game at once and starts Act 1. An empty slot starts at once.
- **Built in V1.3:** after the slot (and its Overwrite question), **CHOOSE DIFFICULTY**: "Enemy HP and damage. It can't be changed later.", then four buttons, **Easy ×0.8**, **Normal ×1.0** (in gold), **Hard ×1.1** and **Extreme ×1.3**, and Back. Hovering one says what it does ("Enemies have 110% HP and deal 110% damage. Blue and orange essence ×1.2."; before V1.5.0, "Blue essence ×1.2."). A pick writes the new game and starts Act 1. Back or ESC returns to the slot list.
- Loading a slot opens the main screen on Journey.
- The slot buttons are 520 px wide, so the longest text keeps room around it. The gear menu's Save as copy uses the same list.
- **Built in V2.0:** each difficulty's hover text has a second line about Resolve. Easy and Normal: "Resolve: each defeat on a stage gives +10% damage dealt and -10% damage taken there, up to 5 times." Hard: the same with 5%. Extreme: "No Resolve: a defeat makes no stage easier." (game design doc §17).
- **Built in V2.0:** every change of screen **fades in from black** over 0.25 s (the title, the main screen, a stage and the end screen; `Game` switches them). `ScreenFade` is a black cover on layer 100, above every pop-up, that never takes input. Off on Low quality and when run headless.

### Built in Phase 10
**The story on the title screen:** Lucian and Senna on the left face Thresh on the right, under the Shadow Isles moon. The figures are backlit silhouettes (the user's choice in planning): dark bodies with a moonlight rim on one edge, and colour accents. The centred column (lantern, title, buttons, slot list) is unchanged.

| Figure | Where (1920 × 1080) | Look |
|---|---|---|
| Senna | x 0–398, 790 tall, behind Lucian | A hooded spirit in ghostly teal that fades toward the ground (her soul is taken), her relic cannon on her shoulder with teal rings and a glowing core |
| Lucian | x 190–679, 870 tall | In his long coat, facing right. His own slim pistol is aimed, with a gold glint at its muzzle. Senna's heavy relic gun is raised beside his head, with teal rings. |
| Thresh | x 1258–1880, 1010 tall | Looming and facing left: a tall hood with green eyes, spiked shoulders, chains across his body and down to the ground, the sickle on a chain, and the green lantern held out |

- **The scene** (`TitleBackdrop`), drawn once:
  - a teal-black sky with stars, and a large pale moon at the upper left with halos;
  - far isles under a haze, and a Shadow Isles cliff at the right, with Helia's ruined arches and spires on it (some broken, with faint green windows);
  - four dead trees and nine gravestones;
  - a faint spectral chain along the ground, from Thresh toward Senna;
  - a soft dark shade behind the column, so the buttons read.
- **What moves:** three bands of ground mist, green mist on Thresh's side, the lantern's glow pulse, nine souls rising from the lantern with fading trails, 22 teal motes around Senna, three lights running along the chain, and a gold twinkle on Lucian's muzzle.
- On a wider screen, Lucian and Senna keep to the left edge and Thresh to the right; only the middle widens. Nothing here takes the mouse, so every button works as before.

## 8. Sounds

All 24 sounds are placeholders, generated in code by `Sfx` (`src/audio/sfx.gd`): there are no audio files. Phases 3–8 made 13 of them; Phase 9 added 11.
- They play on the **SFX** bus, so the Sound effects slider (Settings → Audio) sets them all. Each plays with a small random pitch (±4%), and the same sound never starts twice within 0.035 s. *(V1.4.2: a new sound takes a free player first. With none free, it takes the oldest that isn't playing a stinger (`boss`, `victory`, `defeat`, `wave`, `level_up`, `rank_up`, `freed`), so busy fights don't cut off a stinger. A stinger is cut only when all 12 players hold stingers.)*
- `Game` and a stage run on its own each add one `Sfx` node, so the title screen and the main screen have sounds too.
- **Volume** is the play's own level: 0 dB is full.
- Phase 9's sounds were tuned from their numbers only. Nobody has listened to them yet.

| Sound | When it plays | Volume | What it is |
|---|---|---|---|
| `shot` | Lucian's gunshots: each basic attack, the passive's second shot, each R bullet. Also Senna's shots, Akshan's Comeuppance bullets, Dark Lucian's Culling bullets, Galeforce's missiles and the ending's shot through the lantern | Lucian −6 dB; Senna −10; Akshan −4; Dark Lucian −8; Galeforce 0 (pitch ×1.4); the ending 0 | A short noisy "pew", 900 → 300 Hz |
| `hit` | An enemy takes a hit (not a burn tick) | −12 dB | A short low thud |
| `coin` | A buy, sale or refresh in the shop; loot picked up; a tree level or a skin bought; Save or Save as copy done; a volume slider let go (a test sound) | 0 dB | Two high notes |
| `potion` | A potion drunk; Ghost, Barrier, Heal or Clarity cast; a Honeyfruit eaten | 0 dB | Four rising blips |
| `refresh` | The Evolution Tree reset; Hextech Rocketbelt | 0 dB; Rocketbelt −2 | A noisy rising sweep |
| `error` | A refused buy, sale or refresh in the shop; a save that failed on the main screen | 0 dB | A low buzz |
| `craft` | A craft at the merchant's Craft tab (a legendary, or upgraded boots) | 0 dB | Three rising notes |
| `zap` | Flash, Smite, Hextech Gunblade, an Energized hit; Dark Lucian's Piercing Light | 0 dB; Dark Lucian −4 (pitch ×0.6) | An electric zap with a flutter |
| `hurt` | Lucian takes a hit (not a burn tick, not in stasis) | −8 dB | A short low grunt |
| `hook` | Thresh's Death Sentence (Act 1 and the final fight); the hook in Act 1's cutscene | 0 dB | A falling whir |
| `shell` | A siege minion's shell lands; a Blast Cone pops | 0 dB; Blast Cone −6 | A low noisy boom |
| `buff` | Banshee's Veil blocks a skill; Guardian Angel saves Lucian; an Endless modifier is picked | 0 dB | A rising sweep |
| `freed` | A Lantern Soul goes free; Senna is freed in the ending | Soul −6 dB; the ending 0 | A soft rising chime |
| **New in Phase 9** | | | |
| `level_up` | Lucian gains a level: only when the level goes up, never at a stage's start or for a level lost on the debug table. With the level-up burst (§1) | 0 dB | A bright rising chime: C, E, G, the top note ringing |
| `rank_up` | A skill rank is learned (the HUD's "+" or Ctrl + the key). A refused rank-up and Senna teaching E are silent | 0 dB | A short two-note blip |
| `cast_q` | Piercing Light's laser fires (after its 0.3 s cast) | 0 dB | A bright laser zap |
| `cast_w` | Ardent Blaze's missile leaves (after its 0.2 s cast) | 0 dB | A fiery whoosh, then a pop |
| `cast_e` | Relentless Pursuit's dash starts | 0 dB | An airy dash whoosh |
| `wave` | Each wave starts, except a boss wave | 0 dB | A short low horn |
| `boss` | A boss or a mini boss enters (any, in story or Endless). On a boss wave it takes the horn's place; a mini boss wave has the horn, then the gong when the mini boss comes | 0 dB | A deep gong and roar |
| `victory` | The end screen: STAGE CLEARED | 0 dB | A short fanfare: C, E, G and a held high C |
| `defeat` | The end screen: DEFEATED, GAME OVER or RUN OVER | 0 dB | A falling three-note sting |
| `click` | Any button styled by `UiStyle.style_button` is pressed: menus, the main screen, the title, prompts, the modifier cards. Connected once per button, so a restyled button still clicks once | **−10 dB** | A soft tick |
| `essence` | Orange or purple essence gained in a stage (`Stage.add_essences`). Blue alone is quiet; it comes with every kill | 0 dB | A quick high sparkle |

- On a boss stage's clear, `essence` (the purple) and `victory` play together. A mini boss kill pays orange and purple in the same frame; the 0.035 s gap keeps that to one `essence`.

### Music (built in V1.5.0)
The score is made in code too, by `Score` (`src/audio/score.gd`): there are no audio files. `Music` (`src/audio/music.gd`), a node the `Game` owns, plays it on the **Music** bus, so the Music slider (Settings → Audio) sets it. It follows each screen the Game shows.

- **Pieces:** a theme, then one piece per act. Every piece plays the same leitmotif in its own mode, key and tempo, over its own drone and drums. A piece is a loop of 8 to 16 bars.

| Piece | Plays on | Key and mode | Tempo | Bars |
|---|---|---|---|---|
| Theme | The title, the main screen, The End and Training | D major | 66 BPM | 8 |
| Act 1, The Loss | Act 1 | A minor | 60 BPM | 8 |
| Act 2, The Sentinels | Act 2 | E Mixolydian | 96 BPM | 12 |
| Act 3, The Jungle | Act 3 | C Dorian | 104 BPM | 12 |
| Act 4, The Darkness | Act 4 | B Phrygian | 76 BPM | 8 |
| Act 5, Shadow Isles | Act 5 | F Locrian | 70 BPM | 8 |
| Act 6, The Lantern | Act 6 | D harmonic minor | 126 BPM | 16 |

- An Endless run plays the piece of its map's act.
- **Layers:** each piece has five, looped in sync and faded in and out on their own.

| Layer | What it is | When it plays |
|---|---|---|
| Drone | A low held chord on the tonic that breathes every two bars | Always |
| Pulse | The piece's drums | In a wave. It follows the enemies left to beat (those still to spawn included): silent at none, full at 12 or more |
| Lucian's voice | The leitmotif | Always, except after a defeat |
| Senna's voice | Her answer to his call, then a third over his close | In Act 1's piece, and in the theme until Act 1 is cleared (in the tutorial, only while she is there). Then she is gone until 6-5 is cleared or the ending is seen, and from then on she sings in every piece. The title screen always has her |
| Boss | Low drums and an ostinato | From when a boss or mini boss appears until its wave ends, and through a boss wave |

- **Between waves** (the countdown, a break, a cutscene, and all of Training): no pulse and no boss layer; the drone plays at 70% and the voices at 80%. A cleared stage's result plays calm: the drone and the voices at full.
- **A defeat** (Lucian dead, and his result) leaves the drone alone, at 60%.
- **Timing:** a layer takes 2 s to fade in or out, and a new piece crossfades over the old one in 3 s. While the game is paused (the ESC menu, the backpack, the shop) the music plays on, 6 dB quieter; the result screen doesn't count as a pause.
- **Rendering:** each piece is rendered once, when it is first needed, off the main thread (each layer on a thread of its own), at 22,050 Hz; the old piece plays on meanwhile. At most three are kept in memory, the theme always. Run headless (the tests, the bots), nothing renders or plays, but the volumes still follow the game.

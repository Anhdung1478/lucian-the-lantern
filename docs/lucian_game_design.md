# Lucian: The Lantern — Game Design Document (Draft v1)

> Personal project, not for public release. All numbers are placeholders to be tuned during playtesting.

---

## 1. Overview

| | |
|---|---|
| **Genre** | 2D top-down roguelite wave shooter |
| **Inspiration** | League of Legends (champion, items, stats, controls) |
| **Engine** | Godot 4 |
| **Team** | Solo developer |
| **Platform** | PC (mouse + keyboard) |
| **Graphics** | Top-down view like LoL, simpler and less detailed |
| **Character** | Lucian (more champions could be added later) |
| **Target length** | A skilled player can beat the story in about 5 hours |

**Design rule:** this is not LoL. Everything taken from LoL (stats, items, skills, UI, enemies) should stay only about **70–80% similar**, adapted to fit this game.

**Core loop:** Clear waves of enemies in a stage → earn stage gold, XP and essences → buy and craft items between waves → finish the stage → spend essences on permanent upgrades in the Evolution Tree → push into harder stages.

---

## 2. Controls

| Input | Action |
|---|---|
| Right-click | Move |
| Left-click on enemy | Attack |
| A + left-click | Attack-move |
| Q / W / E / R | Skills |
| D / F | Summoner spells *(proposed)* |
| 1–6 | Item actives *(proposed)* |
| P | Open backpack (pauses the game) |
| ESC | Open menu: resume, settings, leave stage, exit (pauses the game) |
| C | Toggle stats panel |
| Y | Toggle camera between free-cam and Lucian cam (follows Lucian). Default: free-cam |

**Cast modes (chosen in settings):** normal cast, quick cast, or quick cast with indicator.

**Skill queueing (setting, on by default):** a skill pressed during another skill's cast time or the E dash is cast as soon as it ends, aimed where the key was pressed. Only the latest press is kept. Q / W pressed during R are still refused.

---

## 3. Stage Rules

- Every stage starts with an **empty backpack**, **level 1**, and **0 stage gold**.
- A stage is made of **waves**. The stage ends when **all enemies are cleared**.
- The last stage of each act has **1 extra wave**, in which the boss appears.
- Waves per stage increase across the game (boss wave not included):

| Act | Waves per stage |
|---|---|
| 1 | 2 |
| 2 | 2 · 3 · 3 |
| 3 | 3 · 4 · 4 · 5 · 5 |
| 4 | 4 · 5 · 5 |
| 5 | 5 · 5 · 6 · 6 · 6 |
| 6 | 6 · 6 · 7 · 7 · 7 |

- Mini bosses appear in the last wave of their stage.

### Break between waves
- After a wave is cleared, the next wave starts in **20 seconds**.
- The **merchant** appears on the map during this break. Lucian walks to him to buy or sell. When the break ends, he disappears.
- A **Skip** button (top center) starts the next wave right away.
  - Skipping counts as if the remaining time has passed for **HP and mana regeneration** (Lucian gets the regen he would have gotten).
  - **Skill cooldowns, summoner spell cooldowns and buff timers do not advance** from the skipped time.
- Opening the merchant's shop **pauses the game** (including the break timer), like the backpack.
- While the backpack or merchant's shop is open, the player **cannot use skills or items**.
- Dying or quitting a stage: the player **keeps all essences** collected.
- Cleared stages **can be replayed** to farm essences.

### Enemy rules
| Type | Skills | Notes |
|---|---|---|
| Normal enemy | None | Melee or ranged, AD or AP damage |
| Elite | None | Can have a **special normal attack** (e.g. siege minion's shell) or a **special trait** |
| Mini boss | 2 skills | |
| Boss | At least 3 skills | Exception: Thresh in Act 1 has only 2 |

---

## 4. Stats & Leveling

**Stats (like LoL):** AD, AP, Attack Speed, Crit Chance, Armor, Magic Resist, HP, Mana, Lifesteal, Omnivamp, Ability Haste, Move Speed, Armor Penetration, Magic Penetration, Heal & Shield Power, Tenacity.

*Lethality is not used (no item gives it).*

- **Base stats:** based on Lucian in LoL as a starting point, then adjusted (about 70–80% similar).
- **Damage formulas:** based on LoL's Armor / MR formulas *(proposed)*.
- **Levels:** 1 → 18 within each stage. Gain XP by killing enemies.
- Each level gives **bonus stats** and **1 skill point**.

---

## 5. Lucian's Skills

| Skill | Effect |
|---|---|
| **Passive – Lightslinger** | After using a skill, the next attack shoots twice. |
| **Q – Piercing Light** | Laser through a target, hitting every enemy in a line. |
| **W – Ardent Blaze** | Missile that explodes in a cross and marks enemies (magic damage, AP scaling). Hitting a marked enemy gives movement speed. |
| **E – Relentless Pursuit** | Short dash. Passive hits lower its cooldown. |
| **R – The Culling** | Fires a stream of bullets in one direction while Lucian can move. |

**Story start:**
- In Act 1, Lucian has **only one gun**.
- After Senna is killed, Lucian takes her gun and **learns E** from her. **E rank 1 is given for free** after Act 1.

**How skills work:**
- Skill ranks must first be **bought in the Evolution Tree**.
- In a stage, skill points can only be spent on ranks that have been bought.
- Skill points that can't be spent are **wasted** (they are not saved or converted).
- R can only be ranked at **level 6, 11 and 16**, like LoL.
- Q / W / E have 5 ranks. R has 3 ranks.
- Normal ranks add damage and lower cooldown.

**Max rank bonuses:**

| Skill | Bonus |
|---|---|
| Q (rank 5) | Laser becomes wider and longer |
| W (rank 5) | Bigger explosion area |
| E (rank 5) | A kill lowers E cooldown by 1 second |
| R (rank 3) | Bullets pierce; damage drops 15% per enemy hit, minimum 30% |

---

## 6. Items

### Backpack & equipment
- **Backpack:** 49 slots (7 × 7).
- **Equip slots:** start with 1, unlock up to 6 in the Evolution Tree.
- Items can be **sold** to the merchant for **70%** of their buy price (**Guardian Angel: 40%**). Legendary items **cannot be broken** back into fragments.
- **Crafting:** drag one fragment onto another that forms a recipe and hold for a short time (see `ui_design.md`).
- **Shared item cooldowns:** every copy of the same item shares **one cooldown** (e.g. all Galeforces, all Guardian Angels). Selling an item on cooldown and getting another copy does **not** reset it.
- **Duplicates allowed.** Stats stack, but each **unique effect only counts once**.
- **Energized attacks** work like LoL (moving and attacking build stacks; at 100 the next attack is energized).
- A **crafting recipe table** is shown in game so players can plan builds.
- Stats, costs and passive / active text of every item: `items.md`.

### Sources
- Enemies drop **fragments**, and very rarely a **legendary item**.
- The merchant sells fragments and, at a lower chance, legendary items.

### Fragments (8)
| Code | Fragment | Stat |
|---|---|---|
| AD | B.F. Sword | Attack Damage |
| AS | Recurve Bow | Attack Speed |
| AP | Needlessly Large Rod | Ability Power |
| AR | Chain Vest | Armor |
| CR | Cloak of Agility | Crit Chance |
| HP | Giant's Belt | Health |
| MP | Tear of the Goddess | Mana |
| MR | Negatron Cloak | Magic Resist |

### Recipes
Only these pairs combine. **Stats and unique passives/actives are based on LoL** and adapted to this game (about 70–80% similar).

| Recipe | Legendary |
|---|---|
| AD + AD | Infinity Edge |
| AD + AP | Hextech Gunblade |
| AD + AS | Kraken Slayer |
| AD + AR | Mortal Reminder |
| AD + CR | Stormrazor |
| AD + HP | Black Cleaver |
| AD + MP | Spear of Shojin |
| AD + MR | Bloodthirster |
| AS + AP | Statikk Shiv |
| AS + AR | Lord Dominik's Regards |
| AS + AS | Runaan's Hurricane |
| AS + CR | Navori Flickerblade |
| AS + HP | Nashor's Tooth |
| AS + MP | Void Staff |
| AP + AP | Rabadon's Deathcap |
| AP + AR | Malignance |
| AP + CR | Shadowflame |
| AP + HP | Morellonomicon |
| AP + MP | Archangel's Staff |
| AP + MR | Banshee's Veil |
| AR + AR | Thornmail |
| AR + CR | Immortal Shieldbow |
| AR + HP | Death's Dance |
| AR + MP | Fimbulwinter |
| AR + MR | Guardian Angel |
| CR + CR | Rapid Firecannon |
| CR + HP | Galeforce |
| CR + MP | Essence Reaver |
| HP + MP | Hextech Rocketbelt |
| HP + MR | Spirit Visage |
| MP + MP | Muramana |
| MP + MR | Jak'Sho, The Protean |
| MR + MR | Kaenic Rookern |

**33 of 36 pairs used.** Still free (left for later): **AS + MR**, **CR + MR**, **HP + HP**.

---

## 7. Merchant

- Appears on the map during the **20-second break between waves**, and disappears when the break ends or is skipped.
- Opening the shop **pauses the game**.
- Has **2 shops** (tabs):

### Items shop
- Sells **2 items** (upgradeable to 4 in the Evolution Tree). Locked slots are shown with a chain.
- Sells fragments and, at a lower chance, legendary items.
- **Refresh** costs stage gold.
- A slot that was bought from **stays empty** for that merchant visit, even after a refresh. Only unbought slots get new items.

### Potions shop
- Sells **HP potions** and **MP potions** for stage gold.
- Potions stack up to **9** per slot.

### Potions
- **HP potion** restores HP, **MP potion** restores mana, **gradually** over a few seconds (not instantly).
- Use: left-click in the backpack, or put it in an equip slot (1–6) and press its key.
- Works during waves and during the break.
- Does **not** heal while the game is paused (backpack, shop or menu open).
- Like all items, potions are lost when the stage ends.

---

## 8. Summoner Spells

| Spell | Effect |
|---|---|
| Flash | Instant short blink toward the mouse |
| Ghost | Big move speed for a few seconds, pass through enemies |
| Heal | Restore HP and gain a short burst of move speed |
| Barrier | Shield that absorbs damage for a short time |
| Smite | True damage to one enemy and heals Lucian. No bonus vs elites or bosses. Killing an elite with Smite raises its orange essence drop chance. |
| Clarity | Restore a large amount of mana |

- Cooldowns: **30–90 seconds**. They do **not** reset between waves.
- **1st slot is free**, the **2nd slot** is bought in the Evolution Tree.
- **Every spell must be bought** in the Evolution Tree.
- Upgrades: shorter cooldown, more heal, more mana, more damage, bigger shield.

---

## 9. Currencies

| Currency | Source | Use | Resets? |
|---|---|---|---|
| **Stage gold** | Enemies | Merchant, refresh | Yes, every stage |
| **Blue essence** | All enemies | Evolution Tree | No |
| **Orange essence** | Rare from enemies, more from elites | Evolution Tree (better upgrades need blue + orange) | No |
| **Purple essence** | Mini bosses and bosses | Skins, Evolution Tree reset | No |

### Drop rates (placeholder)

| Source | Blue | Orange | Purple (first kill / repeat) |
|---|---|---|---|
| Normal enemy | = act number (Act 1 = 1 … Act 6 = 6) | 1% chance of 1 | — |
| Elite | 5× normal | 10% chance of 1 | — |
| Rift Scuttler (elite) | High | High (escapes if not killed quickly) | — |
| Mini boss | 50 | 3 | 5 / 1 |
| Act boss (Acts 1–5) | 100 | 5 | 10 / 2 |
| Thresh (final) | 100 | 5 | 20 / 4 |

Act 1's Thresh appears only on the first clear, so he gives no repeat purple.

**First-time purple total:** 100 (6 mini bosses × 5 + 5 act bosses × 10 + final Thresh × 20).

---

## 10. Skins

Skins can only be changed **outside stages**.

| Skin | Cost (purple) | Bonus | Weakness | Playstyle |
|---|---|---|---|---|
| Classic | Free | — | — | Balanced |
| High Noon | 25 | +15% AD | −15% Attack Speed | Slow, heavy shots |
| PROJECT | 30 | +20% Attack Speed, +15% Move Speed | −10% AD | Fast, always moving, faster energized stacks |
| Pulsefire | 20 | +15% AP, +15 Ability Haste | −10% Attack Speed | Skill-focused, W and R as main damage |
| Vampire *(custom)* | 25 | +15% Lifesteal, kills heal 2% max HP | −20% max HP | Risky but sustainable |

---

## 11. Evolution Tree

A node opens once **all of its requirements** are bought. B = blue essence, O = orange essence.

**Reset:** costs **5 purple** and refunds all blue and orange essence.

### Skills
| Node | Cost | Requires |
|---|---|---|
| Q / W rank 1 | 100B each | — |
| E rank 1 | Free (Act 1 reward) | Clear Act 1 |
| Passive | 150B | Any 1 of Q, W, E rank 1 |
| R rank 1 | 600B + 10O | Q, W, E rank 1 and Passive |
| Q / W / E rank 2 | 200B | Previous rank |
| Q / W / E rank 3 | 350B | Previous rank |
| Q / W / E rank 4 | 500B + 5O | Previous rank |
| Q / W / E rank 5 | 800B + 10O | Previous rank |
| R rank 2 | 1200B + 20O | R rank 1 |
| R rank 3 | 2000B + 30O | R rank 2 |

### Equipment
| Node | Cost |
|---|---|
| Equip slot 2 | 150B |
| Equip slot 3 | 300B |
| Equip slot 4 | 600B + 5O |
| Equip slot 5 | 1000B + 15O |
| Equip slot 6 | 1500B + 30O |

### Stats
AD, AP, HP, Armor, MR, Attack Speed, Mana — 5 levels each.
Costs: 50B → 100B → 200B → 350B + 3O → 500B + 8O.

### Summoners
| Node | Cost | Requires |
|---|---|---|
| Unlock each spell | 150B | — |
| 2nd summoner slot | 400B + 5O | 2 spells unlocked |
| Spell upgrades (3 levels each) | 150B → 300B → 400B + 5O | That spell unlocked |

### Economy
| Node | Cost |
|---|---|
| Stage gold +10% (3 levels) | 100B → 250B → 500B + 5O |
| Bonus XP +10% (3 levels) | 100B → 250B → 500B + 5O |
| Essence drop rate +10% (3 levels) | 100B → 250B → 500B + 5O |
| Merchant 3 items | 300B |
| Merchant 4 items | 800B + 10O |
| Refresh cost −25% (2 levels) | TBD |

**Balance goal:** in about 5 hours a skilled player can afford all skills, R, 4–5 equip slots and some stats, but not the full tree. The rest is a goal for Endless mode.

---

## 12. Story & Acts

**22 stages total.**

| Act | Name | Stages | Enemies | Elites | Mini bosses | Boss |
|---|---|---|---|---|---|---|
| 1 | The Loss | 1 | Melee & ranged minions | Siege minions | — | Thresh (scripted) |
| 2 | The Sentinels | 3 | Melee & ranged minions | Siege & super minions | — | Akshan (weakened) |
| 3 | The Jungle | 5 | Raptors, Krugs, Murkwolves (packs), Gromp (alone) | Blue Sentinel, Red Brambleback, Rift Scuttler | Infernal Drake (stage 2), Ocean Drake (stage 4) | Elder Dragon |
| 4 | The Darkness | 3 | Shadow minions (melee & ranged) | Shadow siege & super minions | — | Dark Lucian |
| 5 | Shadow Isles | 5 | Maokai's saplings, Elise's spiderlings | Maiden of the Mist, Broodmother | Maokai (stage 2), Elise (stage 4) | Karthus |
| 6 | The Lantern | 5 | Mist Walkers, Lantern Souls | Spectral Riders, Chain Wardens | Karthus – revived (stage 2), Hecarim (stage 4) | Thresh (2 phases) |

### Story summary
- **Act 1 – The Loss:** Lucian and Senna fight together until Thresh kills Senna and traps her soul in his lantern.
- **Act 2 – The Sentinels:** Lucian trains with Akshan to prove he's ready to hunt Thresh.
- **Act 3 – The Jungle:** Lucian crosses the jungle, facing the drakes and the Elder Dragon.
- **Act 4 – The Darkness:** Lucian faces his own fear and grief as Dark Lucian.
- **Act 5 – Shadow Isles:** Lucian fights through Maokai, Elise and Karthus.
- **Act 6 – The Lantern:** Lucian defeats Thresh, shoots through the lantern and frees Senna.

### Enemy & boss design files
Detailed enemy, elite, mini boss and boss designs for each act live in separate files:
- `enemies/act1_the_loss.md`
- `enemies/act2_the_sentinels.md`
- `enemies/act3_the_jungle.md`
- `enemies/act4_the_darkness.md`
- `enemies/act5_shadow_isles.md`
- `enemies/act6_the_lantern.md`

---

## 13. Maps

### General rules
- **Size:** about 2–3 screens wide (camera follow and free-cam both matter).
- **One map per act.** Stages in the same act share the map with small changes (spawn points, obstacles, hazards).
- **Spawn points:** fixed places that fit the theme (lane end, jungle camps, mist).
- **Cover:** every map has walls or pillars to dodge behind.
- **No brush** (no bushes to hide in).
- **Merchant:** appears near the center of the map between waves.

### Maps by act
| Act | Map | Layout |
|---|---|---|
| 1 | Mid lane | Long diagonal lane with the river crossing the middle. Lucian and Senna start bottom-left; minions come from top-right. Few walls. Thresh rises from the river for the boss wave. |
| 2 | Training ground | Open arena with stone pillars (cover from Akshan's Comeuppance). Training dummies as decoration. |
| 3 | Jungle | Narrow paths between walls; monsters come from their camps. Stage 2 adds lava and Blast Cones, stage 4 adds shallow water and Honeyfruit, stage 5 is the Elder Dragon's pit (round arena with walls around the edge). |
| 4 | Dark mid lane | Act 1 layout in dark colors. Normal vision. |
| 5 | Dead forest | Twisted trees as obstacles. Saplings come out of trees, spider nests spawn spiderlings. Karthus fights in a ruined graveyard. |
| 6 | Thresh's domain | Cliffs with chains and narrow paths; Chain Wardens on ledges. Final fight on a round, open platform with no walls. |

---

## 14. Endless Mode

- **Unlocks** after beating Thresh.
- **Map:** random from all acts, or chosen by the player.
- Waves never end; enemies get stronger every wave.
- **Mini boss every 5 waves**, **act boss every 10 waves** (random, stronger than in story).
- Merchant between waves as usual.
- Level cap stays at 18.
- Gives **blue and orange essences** (a farming mode). Bosses and mini bosses give the **repeat** purple amount.
- **Best wave** is saved as a personal record.

### Modifiers
Every 10 waves, the player picks 1 of 3 choices:
- **2 random modifiers** rolled from #1–5.
- **"Nothing"** (#6) is always shown.

A new pick **replaces** the previous modifier (they do not stack).

| # | Downside | Reward |
|---|---|---|
| 1 | Enemies move 20% faster | +30% gold |
| 2 | Elites appear twice as often | ×1.5 orange essence drop rate |
| 3 | −10% max HP | +15% blue essence |
| 4 | −5% AD | +10% gold |
| 5 | Bosses and mini bosses +25% max HP | ×1.5 purple essence |
| 6 | Nothing | Nothing |

---

## 15. Save System

### Slots
- **3 save slots.** The player picks a slot when starting the game.
- **Save as copy:** the current progress can be copied into another slot (asks for confirmation before overwriting).
- Files: `user://save_slot_1.json`, `save_slot_2.json`, `save_slot_3.json`, each with its own `_backup.json`.
- Settings are saved separately in `user://settings.json` and shared by all slots.

### What is saved (permanent progress only)
- Blue, orange and purple essences
- Bought Evolution Tree nodes
- Unlocked summoner spells, owned skins, equipped skin
- Cleared stages, and which bosses / mini bosses already gave first-time purple
- Endless best wave

Nothing inside a stage is saved (items, gold, level, enemies), since stages always reset.

### When to save
- After each wave
- When a stage ends, or the player dies or quits
- After any Evolution Tree purchase or reset, skin purchase or skin change
- When settings change (settings file only)

### Implementation notes (Godot 4)
- **SaveManager** as an Autoload.
- JSON format with a `"version"` field for future changes.
- Convert numbers back with `int()` when loading (JSON numbers load as floats).
- Save IDs (e.g. `"q_rank_2"`), not display names.
- Copy the old save to the backup file before writing; load the backup if the main file is broken.
- Debug button to give essences / unlock everything during testing.

---

## 16. Open Topics

- [x] Enemy & boss designs for each act (separate files)
- [x] Map layouts for each act
- [x] Full Endless modifier list
- [x] Unspent skill points: wasted
- [x] Wave count per stage across the 22 stages
- [x] Implementation / MVP plan (Phase 1: `implementation/phase1.md`, Phase 2: `implementation/phase2.md`)
- [x] Item stats and effects (`items.md`)
- [ ] UI (see `ui_design.md`): HUD, backpack, crafting, recipe table and ESC menu done; other screens to design
- [x] Save system
- [ ] Art style, sound

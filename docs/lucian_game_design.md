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
| **Target length** | A skilled player needs at least 5–7 hours to beat the story |

**Design rule:** this is not LoL. Everything taken from LoL (stats, items, skills, UI, enemies) should stay only about **70–80% similar**, adapted to fit this game.

**Core loop:** Clear waves of enemies in a stage → earn stage gold, XP and essences → buy and craft items between waves → finish the stage → spend essences on permanent upgrades in the Evolution Tree → push into harder stages.

### Pacing
Minutes for a skilled player's first clear of each act, counting a few deaths, shopping, and the replays needed to afford Evolution Tree nodes.

| Act | Stages | Waves (+ boss / mini boss waves) | Minutes |
|---|---|---|---|
| 1 | 1 | 2 + 1 | 8–10 (tutorial and cutscene) |
| 2 | 3 | 8 + 1 | 30–40 |
| 3 | 5 | 21 + 3 | 70–90 |
| 4 | 3 | 14 + 1 | 45–60 |
| 5 | 5 | 28 + 3 | 80–100 |
| 6 | 5 | 33 + 3 | 90–120 |
| **All** | 22 | 106 + 12 | **323–420 (5.4–7 h)** |

**Rules of thumb:**
- A wave should take a skilled player **about 2 minutes** of fighting.
- A boss should take **2–3 minutes**.
- A break is used, on average, for about 30 s of shopping.
- About a third of each act's time is deaths and replays: farming essence for the tree (see the balance goal in §11).

**Measuring it:** each stage's result panel shows its time, and the slot lists (title screen, Save as copy) show each slot's total play time. Both clocks skip paused time, so shopping (the shop pauses the game) isn't in them, while the budget counts about 30 s of shopping per break. If Act 2 clears in under 25 minutes, raise `EnemyData.ACT_HP` and the bosses' HP before changing rewards.

---

## 2. Controls

| Input | Action |
|---|---|
| Right-click | Move (hold to keep following the cursor). A dash (E, Galeforce, Rocketbelt) or Flash drops a move or merchant visit ordered before it, even with the button still held: right-click again, during the dash or after it, to walk on. |
| Left-click on enemy | Attack |
| A + left-click | Attack-move |
| Q / W / E / R | Skills |
| D / F | Summoner spells |
| 1–6 | Item actives and potions in equip slots 1–6 |
| P | Open backpack (pauses the game) |
| ESC | Open menu: resume, settings, leave stage, exit (pauses the game) |
| Ctrl + C | Toggle the stats panel |
| Hold C | Show the extra stats (health / mana regen, heal & shield power, penetration, life steal, omnivamp, range, tenacity) |
| Y | Toggle camera between free-cam and Lucian cam (follows Lucian). Default: free-cam |
| Space | Move the camera back over Lucian; hold it to keep the camera on him (free-cam stays free once let go) |

**Cast modes (Settings → Controls, one per key):** for Q / W / E / R, D / F and item keys 1–6.
- **Quick cast** (default): casts toward the cursor on press.
- **Quick cast with indicator:** holding the key shows the range toward the cursor; releasing it casts. Left-click does nothing meanwhile.
- **Normal cast:** pressing the key shows the range; left-click casts. Pressing the same key again keeps aiming; another cast key switches to it.

Right-click or ESC cancels an aim in either mode (right-click doesn't move Lucian, ESC doesn't open the menu).

Casts with no aim (potions, Ghost, Barrier, Heal, Clarity) and casts that aren't ready (cooldown, mana, Q / W during R) always go on press. Pressing R while it fires still stops it.

**Range indicators:** a ray for Q, W (ending in the cross it bursts into), E and the item dashes (with a ring where Lucian lands), two dashed rays for R, a circle for Gunblade (700), Smite (500) and Flash (400; a blink, so a circle, with the landing ring while aiming). They show while aiming (toward the cursor), and while a learned skill, an item active or Flash / Smite is hovered on the HUD (where Lucian faces).

**Dashes** (E, Galeforce, Rocketbelt) go as far as the cursor, up to their range, so a cursor right on Lucian dashes 0.

**Targeted casts** (Gunblade, Smite) hit the enemy nearest the cursor within range. Aimed at an enemy out of range, Lucian walks over and casts once it is in range; any new order (move, attack) drops it, a dash or Flash doesn't.

**Key bindings** can be changed in Settings → Controls (all but ESC and the debug F3 + Q).

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

### Built in Phase 6
Acts 1 and 2 play this way. Training keeps its dummies and has no waves.

**Stage flow:**
1. **"Wave 1 in 0:05"** at the top center, with Skip.
2. A wave spawns in **groups of 3 every 1.2 s**, taking turns over the map's spawn points.
3. Once every enemy of the wave is dead, a **20 s break**: the merchant comes at its start and leaves at its end.
4. After the last wave, one more break, then the **boss wave** (if the stage has a boss).
5. The **result panel**.

- **Skip** starts the next wave now and gives Lucian the HP and mana regen of the time skipped, at once. Cooldowns and buffs don't move.
- **Enemies** attack only Lucian. They walk straight at him, sliding along walls; one that gets stuck sidesteps for a moment. They bump into each other and into Lucian. There is no navigation mesh.
- **Enemy bolts** are stopped by walls and pillars. Lucian's homing shots still fly over walls.
- **Enemy hits** reach Lucian within his radius (30) of his center. Red ground warnings (circle, line, cone, lock line) fill up before an attack lands.
- **Scaling** (bosses don't scale): per act after the first, HP × (1 + 0.6 · (act − 1)), damage and rewards × (1 + 0.25 · (act − 1)). Each wave after the first adds +15% HP and damage. A stage can also lower some enemies' HP on its own: in Act 1 (1-1), melee and ranged minions have 20% less HP.
- **Death:** Lucian turns grey and fades for 1.5 s, then DEFEATED shows. Enemies stand still while he is dead or in stasis. Guardian Angel's stasis comes first.
- **Game over:** losing Act 1 before its first clear (the tutorial) shows **GAME OVER** instead, and **Back to title** returns to the title screen. It still auto-saves, so the essences collected are kept.
- **Result panel** (pauses the game; ESC and P do nothing): **STAGE CLEARED**, **DEFEATED** or **GAME OVER**, the stage name, "Waves cleared: 2 / 3 · Time 4:32", the essences collected and any first-clear lines. **Continue** auto-saves and opens the main screen on that act (Back to title after a game over).
- **The stage time** only runs while the game does: the backpack, the shop, the ESC menu and the result panel stop it.

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
| **Passive – Lightslinger** | After using a skill, the next attack shoots twice. Lucian's shots (basic attacks, this second shot, R's bullets) take turns between his guns, left first. |
| **Q – Piercing Light** | Laser through a target, hitting every enemy in a line. |
| **W – Ardent Blaze** | Missile that explodes in a cross and marks enemies (magic damage, AP scaling). Hitting a marked enemy gives movement speed. |
| **E – Relentless Pursuit** | Short dash toward the cursor (up to 280, as far as the cursor). Passive hits lower its cooldown. |
| **R – The Culling** | Fires a stream of bullets in one direction while Lucian can move. |

**Story start:**
- In Act 1, Lucian has **only one gun**.
- After Senna is killed, Lucian takes her gun and **learns E** from her. **E rank 1 is given for free** after Act 1.

**How skills work:**
- Skill ranks must first be **bought in the Evolution Tree**.
- In a stage, skill points can only be spent on ranks that have been bought.
- Skill points that can't be spent are **wasted** (they are not saved or converted).
- R can only be ranked at **level 6, 11 and 16**, like LoL.
- Q / W / E rank *r* needs level 2*r* − 1 (rank 2 at level 3, rank 3 at 5, rank 4 at 7, rank 5 at 9), like LoL.
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
  - Placeholders: Health Potion 200 HP over 5 s, Mana Potion 150 mana over 5 s, 50 gold each.
- Use: right-click it in the backpack and press **Use**, or put it in an equip slot (1–6) and press its key.
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

### Built in Phase 4

Placeholder numbers. Ability haste doesn't shorten them, and each spell keeps its own cooldown, also when moved to the other key.

| Spell | Cooldown | Effect |
|---|---|---|
| Flash | 90 s | Blink up to 400 toward the cursor. If that spot is inside a wall or an enemy, land just short of it (so Flash can cross them). A blink leaves no trail: yellow sparks ring the spot Lucian left. Like a dash, it drops a move ordered before it. |
| Ghost | 60 s | +40% move speed and pass through enemies for 6 s. Pale afterimages trail behind Lucian as he runs. |
| Barrier | 60 s | Shield of 95 + 18 × level for 2.5 s; heal and shield power makes it stronger. A golden bubble shows around Lucian while it lasts. |
| Heal | 60 s | Heal 80 + 15 × level, +30% move speed fading over 1 s. A green ring spreads out and crosses rise around Lucian. |
| Clarity | 45 s | Restore 50% of max mana. Blue motes spiral into Lucian. |
| Smite | 30 s | 450 true damage to the enemy nearest the cursor within 500, heal 10% of max HP. |

### Built in Phase 5
- **Every spell is bought in the Evolution Tree** (its own node, 150B). A new game has none.
- **D is open from the start. F is chained** until the **Second Summoner Slot** node is bought (400B + 5O, needs any 2 spells).
- **D and F are picked in Journey's loadout panel**, among the bought spells (or None). Picking the spell already on the other key swaps them. The pick is saved with the progress.
- **Upgrades:** one node per spell, 3 levels, bought after the spell:

| Spell | Per level | At level 3 |
|---|---|---|
| Flash | −10% cooldown | 63 s |
| Ghost | −10% cooldown | 42 s |
| Barrier | +15% shield | ×1.45 |
| Heal | +15% healing | ×1.45 |
| Clarity | +15% mana restored | ×1.45 |
| Smite | +15% damage (not its heal) | ×1.45 |

- An upgraded spell's card adds a green line: "Upgraded: 30% shorter cooldown" or "Upgraded: 45% stronger".
- On the HUD, an empty D shows only its frame, and a locked F shows a chain; each has a hover card saying why.
- `stage.tscn` run on its own (F6, tests) keeps the Phase 4 sandbox: both slots open, Flash on D and Heal on F, swapped in the debug table (which now also offers None).

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

### Built in Phase 6
Every kill pays out at once, Senna's kills too:
- **Stage gold and XP:** the enemy's own amounts (in the act files), × (1 + 0.25 · (act − 1)).
- **Blue and orange:** as in the table above. A boss gives 100 blue and 5 orange.
- **Purple:** only from bosses, through the save's list of bosses already beaten (`"bosses"`, §15): the first-time amount once, the repeat amount after.
- **Essences go into the save as they drop.** Leaving the stage, dying, or a Yes to "Save before leaving?" keeps them; a No loses them. They rise over the kill as "+1" with their icon, and the HUD counts them next to the stage gold.

**The Evolution Tree's economy nodes** (§11) raise them, +10% per level:

| Node | Raises |
|---|---|
| Stage Gold | Gold per kill |
| Bonus XP | XP per kill |
| Essence Drops | Blue per kill (rounded), and the chance of orange |

**Item loot:** a kill can drop an item on the ground, where the enemy died.

| Enemy | Drop |
|---|---|
| Normal | 0.3% a legendary; else 4% a fragment |
| Elite | 3% a legendary; else 25% a fragment |
| Boss | A fragment for sure, plus 15% a legendary |

- The kill that ends a stage (the boss, or the last enemy of the last wave) drops nothing: the result comes up at once, and items don't carry over. The boss row waits for Endless.
- Loot stays until the stage ends. It shows as the item's icon over a bobbing glow (gold for a legendary).
- Lucian picks it up by walking within 60 of it, into the backpack.
- With no room it stays, and "Backpack full" shows at most once every 3 s.

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

**Built in Phase 5:**
- Bought and equipped in the Skin Shop (`main_screen.md`). Lucian's body sprite and the HUD portrait follow the equipped skin.
- Attack speed, move speed, ability haste and lifesteal are added like item stats. The AD, AP and max HP percentages multiply the final stats, after item passives.
- Vampire's kill heal works on real kills; training dummies never die, so only the tests show it for now.

---

## 11. Evolution Tree

A node opens once **all of its requirements** are bought (or any 1 / any 2 of them, where the table says so). B = blue essence, O = orange essence.

**Reset:** costs **5 purple** and refunds all blue and orange essence.

**Nodes have levels** (built in Phase 5; 31 nodes, laid out in `main_screen.md`):
- Q, W and E are one node each with 5 levels, R one node with 3. Equip slots are one node with 5 levels (slots 2–6), Merchant stock one node with 2 (3 and 4 items). Each level costs what the tables below say for that rank, slot or step.
- A node opens once its requirements have level 1; its later levels need nothing more.
- **E level 1 is free** and stays hidden until Act 1 is cleared. A reset takes it back like any level, and it is free to buy again.
- In a stage, skill points only go into bought ranks, and the passive only works once bought.

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

| Stat | Per level | At level 5 |
|---|---|---|
| AD | +4 | +20 |
| AP | +8 | +40 |
| HP | +40 | +200 |
| Armor | +4 | +20 |
| MR | +4 | +20 |
| Attack Speed | +3% | +15% |
| Mana | +40 | +200 |

They count as **bonus** stats (yellow in the stats panel) from the start of every stage.

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
| Refresh cost −25 gold (2 levels: 100 → 75 → 50 gold) | 200B → 500B + 5O |

Stage gold, bonus XP and essence drops work since Phase 6: +10% gold, XP or blue per kill for each level, and the essence node also raises the chance of orange (§9).

**Balance goal:** in 5–7 hours a skilled player can afford all skills, R, 4–5 equip slots and some stats, but not the full tree. The rest is a goal for Endless mode.

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
- **Merchant:** appears near the center of the map between waves. *(Phase 3: on the training map he stands at the center from the start; the debug table adds or removes him. Phase 6: on the act maps he comes at the start of each break and stands at the map's merchant point.)*

### Maps by act
| Act | Map | Layout |
|---|---|---|
| 1 | Mid lane | Long diagonal lane with the river crossing the middle. Lucian and Senna start bottom-left; minions come from top-right. Few walls. Thresh rises from the river for the boss wave. |
| 2 | Training ground | Open arena with stone pillars (cover from Akshan's Comeuppance). Training dummies as decoration. |
| 3 | Jungle | Narrow paths between walls; monsters come from their camps. Stage 2 adds lava and Blast Cones, stage 4 adds shallow water and Honeyfruit, stage 5 is the Elder Dragon's pit (round arena with walls around the edge). |
| 4 | Dark mid lane | Act 1 layout in dark colors. Normal vision. |
| 5 | Dead forest | Twisted trees as obstacles. Saplings come out of trees, spider nests spawn spiderlings. Karthus fights in a ruined graveyard. |
| 6 | Thresh's domain | Cliffs with chains and narrow paths; Chain Wardens on ledges. Final fight on a round, open platform with no walls. |

### Built in Phase 6
Maps are drawn in code. Walls (jungle, rocks, pillars, the border) block Lucian, enemies and enemy bolts.

| Act | Map | Size | Details |
|---|---|---|---|
| 1 | Mid lane | 5200 × 3200 | A 900-wide diagonal lane, jungle walls on both sides, the river across its middle (walkable), 3 rocks. See `act1_the_loss.md`. |
| 2 | Training ground | 4600 × 2800 | Stone tiles, three gates, 6 decorative dummies by the walls, and 6, 8 or 10 pillars by stage (a ring of 10 in stage 3). See `act2_the_sentinels.md`. |
| — | Training | 4800 × 2700 | The Phase 3 test arena, with its dummy and no waves |

The radar takes the map's shape. Acts 3–6 have no map yet.

---

## 14. Endless Mode

- **Unlocks** once **Act 3** is cleared.
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
- **3 save slots.** The player picks a slot on the **title screen**. That is the **current slot**: every save writes to it.
  - **Start new game** lists the 3 slots. A used slot asks "Overwrite slot N? Its progress will be lost." The new game is **written at once** (`SaveGame.start_new`), so the overwrite is real. Then Act 1 starts.
  - **Load game** lists the same slots, with the empty ones disabled. The button itself is disabled ("No saved games yet") when no slot exists. It opens the main screen.
  - Each used slot shows its play time and when it was saved: "Slot 2 · 1h 02m · saved 2026-10-29 03:10".
- **Save as copy:** the current progress can be copied into another slot (asks for confirmation before overwriting).
- **Leave to main menu** (gear menu) asks "Save before leaving?", then goes back to the title screen.
- Files: `user://save_slot_1.json`, `save_slot_2.json`, `save_slot_3.json`, each with its own `_backup.json`.
- Settings are saved separately in `user://settings.json` and shared by all slots.

### What is saved (permanent progress only)
- Blue, orange and purple essences
- Bought Evolution Tree nodes (summoner spells included)
- The spells picked for D and F
- Owned skins, equipped skin
- Cleared stages, and which bosses / mini bosses already gave first-time purple
- Endless best wave
- Play time: every second outside the title screen, pauses not counted

Nothing inside a stage is saved (items, gold, level, enemies), since stages always reset.

### When to save
- **Auto-save only when a stage is done:** cleared, left (ESC → Leave this stage) or failed (Lucian dies). Nothing is saved between waves.
- **Nothing on the main screen auto-saves.** Evolution Tree purchases and resets, skin purchases and skin changes are kept only by the next auto-save, the **Save** button in the gear menu, or a **Yes** when leaving.
- **Leaving the game** (Exit the game in the ESC menu or the gear menu, Leave to main menu, or closing the window) asks **"Save before leaving?"** (Yes / No).
  - **Yes:** saves to the current slot right away, then leaves. Inside a stage, this keeps the essences collected so far, as leaving the stage would.
  - **No:** leaves without saving. Everything since the last save is lost.
  - If the save fails, it asks **"Could not save. Quit anyway?"** (Leave to main menu: "Could not save. Leave anyway?"): Yes leaves, No goes back to the game. A failed auto-save after a stage shows a red "Could not save" on the main screen.
- The title screen has nothing unsaved: its **Exit game** and the window's close button quit at once, with no question.
- Settings are not part of the save: they are written to `user://settings.json` on every change.

### Implementation notes (Godot 4)
- **`SaveGame`** (`src/core/save_game.gd`) is **not an autoload**. Like `GameSettings`, it is a class with a static `instance()` that loads slot 1 on first use, so GUT tests and `-s` scripts can point it at scratch files.
- One JSON file per slot, with a `"version"` field for future changes:

| Key | Holds |
|---|---|
| `version` | 1 |
| `saved_at` | Local date and time of the save, e.g. `"2026-10-28 14:03:12"` (Save as copy's slot list shows it) |
| `essences` | `{"blue": 1200, "orange": 5, "purple": 0}` |
| `tree` | Node id → level, for bought nodes only: `{"skill_q": 2, "stat_ad": 3}` |
| `skins` | `{"owned": ["classic", "vampire"], "equipped": "vampire"}` |
| `loadout` | The spells on D and F: `["flash", "heal"]` (`""` for none) |
| `cleared` | Cleared stage ids: `["1-1", "2-1"]` |
| `bosses` | Bosses that already gave their first-time purple: `["thresh_1", "akshan"]` |
| `endless_best` | Best Endless wave |
| `play_time` | Whole seconds played in this slot: `3720` |

- Numbers are converted back with `int()` when loading (JSON numbers load as floats). Unknown keys, node ids, skins, spell ids and stage ids are dropped, so an old or edited file still loads.
- IDs are saved, not display names.
- A save is written to a temp file first. Then the old save becomes the backup (only if it still reads, so a broken file never replaces a good backup) and the temp file replaces it. If anything fails, the old file and backup stay as they were. The backup loads if the main file is broken. With both broken, it's a new game.
- `"version"` stays 1: Phase 6 only added keys. A file without `"bosses"` or `"play_time"` loads with none.
- `SaveGame.start_new(slot)` makes that slot current, resets the progress and writes it at once. `award_boss(id, first, repeat)` returns the purple due and records the boss; the stage adds the essence.
- The main screen's debug table (F3 + Q) gives essences, sets the acts cleared, maxes or clears the tree, resets the progress, and forgets the bosses' first-time purple.

---

## 16. Open Topics

- [x] Enemy & boss designs for each act (separate files)
- [x] Map layouts for each act
- [x] Full Endless modifier list
- [x] Unspent skill points: wasted
- [x] Wave count per stage across the 22 stages
- [x] Implementation / MVP plan (Phase 1: `implementation/phase1.md`, Phase 2: `implementation/phase2.md`, Phase 3: `implementation/phase3.md`, Phase 4: `implementation/phase4.md`, Phase 5: `implementation/phase5.md`, Phase 6: `implementation/phase6.md`)
- [x] Item stats and effects (`items.md`)
- [x] UI (see `ui_design.md` and `main_screen.md`): HUD (with the stage info, boss bar and radar), backpack, crafting, recipe table, ESC menu, merchant's shop, Settings, the main screen (Journey, Evolution Tree, Skin Shop), and the title screen with save slot selection
- [x] Save system
- [ ] Art style, sound (Phase 3 has generated placeholder sound effects and audio buses; no music yet)

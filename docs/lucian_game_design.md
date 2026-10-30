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

**Measuring it:** each stage's end screen shows its time, and the slot lists (title screen, Save as copy) show each slot's total play time. Both clocks skip paused time, so shopping (the shop pauses the game) isn't in them, while the budget counts about 30 s of shopping per break. If Act 2 clears in under 25 minutes, or Act 3 in under 60, raise `EnemyData.ACT_HP` and the bosses' HP before changing rewards.

**As built (Phase 7):** Act 3's waves hold about 275k HP, plus 35k for the two drakes and the dragon; Act 4's about 313k, plus 18k for Dark Lucian. The drakes come last in their stage's last wave, not in a wave of their own, so Act 3 has 21 waves plus the Elder Dragon's boss wave.

---

## 2. Controls

| Input | Action |
|---|---|
| Right-click | Move (hold to keep following the cursor). A dash (E, Galeforce, Rocketbelt) or Flash drops a move or merchant visit ordered before it, even with the button still held: right-click again, during the dash or after it, to walk on. |
| Left-click on enemy | Attack (a Blast Cone too) |
| A + left-click | Attack what the player means: the enemy under the cursor, else the weakest in range, else the nearest (see below) |
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

**A + Left-click (built in Phase 7).** A arms it: Lucian's attack range shows as a ring and the cursor turns to a cross. The left-click then picks one target, in this order:
1. The enemy (or Blast Cone) under the cursor, even out of range.
2. Else the enemy with the **lowest HP %** within his attack range; on a tie, the nearer one.
3. Else the **nearest enemy on the map**: he walks to it (around walls) and shoots once in range.
4. With no enemy at all, he walks to the clicked point.

It is one target: after that kill Lucian stops and idles. A dead or untargetable enemy is never picked. Act 1's tip reads "Press A, then LMB: attack the enemy under the cursor, or the weakest one in range." (the keys follow the bindings).

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
- **Enemies** attack only Lucian. They walk straight at him, sliding along walls; one that gets stuck sidesteps for a moment. They bump into each other and into Lucian. There is no navigation mesh. *(Phase 7: they path around walls; see below.)*
- **Enemy bolts** are stopped by walls and pillars. Lucian's homing shots still fly over walls.
- **Enemy hits** reach Lucian within his radius (30) of his center. Red ground warnings (circle, line, cone, lock line) fill up before an attack lands.
- **Scaling** (bosses don't scale): per act after the first, HP × (1 + 0.6 · (act − 1)), damage and rewards × (1 + 0.25 · (act − 1)). Each wave after the first adds +15% HP and damage. A stage can also lower some enemies' HP on its own: in Act 1 (1-1), melee and ranged minions have 20% less HP.
- **Death:** Lucian turns grey and fades for 1.5 s, then DEFEATED shows. Enemies stand still while he is dead or in stasis. Guardian Angel's stasis comes first.
- **Game over:** losing Act 1 before its first clear (the tutorial) shows **GAME OVER** instead, and **Back to title** returns to the title screen. It still auto-saves, so the essences collected are kept.
- **Result panel** (pauses the game; ESC and P do nothing): **STAGE CLEARED**, **DEFEATED** or **GAME OVER**, the stage name, "Waves cleared: 2 / 3 · Time 4:32", the essences collected and any first-clear lines. **Continue** auto-saves and opens the main screen on that act (Back to title after a game over). *(Phase 7: the end screen replaces it; see below.)*
- **The stage time** only runs while the game does: the backpack, the shop, the ESC menu and the result panel stop it.

### Built in Phase 7
Acts 3 and 4 play this way too (`act3_the_jungle.md`, `act4_the_darkness.md`): packs from their camps, jungle buffs, terrain, two mini bosses, the Elder Dragon, the dark lane and Dark Lucian.

**The end screen** (`StageResult`) replaces the result panel. It covers the whole screen; the game pauses, the HUD hides, and ESC and P do nothing.
- A banner: **STAGE CLEARED** in gold, or **DEFEATED** / **GAME OVER** in red, over a soft gold or dark red glow. The stage's name under it.
- **Stats:** Time, Waves, Kills, Damage dealt, Damage taken, Gold earned, Level reached.
  - Kills count every enemy death in the stage; an escaped Scuttler isn't one.
  - Damage dealt is the HP Lucian's hits really took (capped at the HP left). Debug kills add nothing.
  - Damage taken is after armor and MR, before shields, as the numbers over Lucian show.
  - Numbers have commas under 10,000 ("9,999") and read "41.2k" above.
- **Rewards:** each essence collected with its icon ("No essences" when there are none), then the green lines: first-clear and first-kill purple, Act 1's lines, and **"Stage 3-3 is open"** or **"Act 4 is open"** on a first clear.
- **Buttons** (Main screen is the lit one; each auto-saves first):

| Outcome | Buttons |
|---|---|
| Cleared | **Retry** · **Next stage** (only when the next stage can be played) · **Main screen** |
| Defeated | **Retry** · **Main screen** |
| Game over (the tutorial) | **Back to title** |

- **Retry** starts the same stage again, built fresh from the save. **Next stage** starts the next one (after 2-3, it is 3-1). **Main screen** opens the main screen on that act. If the save fails, Retry and Next go to the main screen instead, with its "Could not save" toast.

**Walking around walls:** enemies and Lucian walk straight while nothing blocks the line to their goal. When a wall does, they follow a path baked from the map's walls (agent radius 36), asked again every 0.4 s or when the goal moves 120. Lucian's moves, attack chases, merchant visits and cast walks use it; a click inside a wall walks to the closest reachable point. The enemies' sidestep stays as a fallback. Until the map's navigation is ready, and whenever a path comes back empty, everyone walks straight. Acts 1–2 benefit too.

**Status effects:**
- **Slows** work on Lucian and on enemies. The strongest one wins; tenacity doesn't shorten them. Gunblade's 40% uses the same rule.
- **Burns** deal damage every 0.5 s for their time, physical, magic or true (armor and MR lower them as usual). A tick makes no hit sound and no flash. It isn't a basic attack or a skill, so it triggers no on-hit effect, no Thornmail, and Banshee's Veil doesn't spend itself on one.
- On Lucian they show in the buff row ("Slowed", "Burning", the strongest slow); on an enemy, as icons over its HP bar.
- **Timed stat buffs** (the jungle buffs) raise HP regen, mana regen and ability haste for their time.
- Death clears them all.

**Untargetable enemies** (the Elder Dragon's Sky Dive, Dark Lucian's E): they leave the enemies, so attacks, homing shots in flight, A + Left-click, Senna and the radar drop them, and they take no damage, burns included. Lucian keeps an attack order on one and shoots again once it is back; the boss bar keeps it too.

**Thrown over walls:** a Blast Cone throws Lucian. He can't act in flight, nothing pushes him then, and he lands on walkable ground. The throw builds no Energize.

**Mini bosses** come last in their stage's last wave (`kind = mini_boss`). They don't scale. Their purple is paid on the kill.

### Built in Phase 8
Acts 5 and 6 play this way too (`act5_shadow_isles.md`, `act6_the_lantern.md`). **All 22 stages can be played.** Only Endless waits. *(Phase 9: Endless plays too; see §14.)*

**Crowd control on Lucian.** Root, stun and fear come from Maokai, Elise, Hecarim and nothing else. One entry point, `Lucian.add_cc`; the timers live in `CrowdControl`.

| Kind | Effect |
|---|---|
| Root | He can't walk, use E, Flash or an item dash (Galeforce, Rocketbelt). A move order waits and runs when the root ends. Attacks in range, Q, W, R and items that don't move him still work. |
| Stun | He can't act. It drops the windup, the queued cast, a dash and R, as a displacement does. |
| Fear | He can't act. It drops the same, and he runs straight away from the source at 60% of his speed, sliding along walls. Walls and the abyss stop him; enemy bodies don't, so nothing can push him along. It builds no Energize. With a root at the same time, the fear still walks him (the fear wins). |

- **Tenacity** shortens root, stun and fear (a time × (1 − tenacity)); the same kind keeps the longer time. **Slows are not shortened**, as before.
- A stun or fear during a pull lets the pull finish and holds him after it. A root doesn't end a dash already under way.
- Dead, in stasis, `invulnerable` or thrown over a wall: he refuses CC. Death clears it.
- **A skill's CC lands only when its hit lands:** Banshee's Veil blocks the damage and the CC with it.
- **Fairness:** every root, stun or fear comes from a warning of 0.7 s or more, or from a bolt or wave he can see, and lasts 1.5 s at most (1.0, 1.25 and 1.25 s are the built values). It shows in the buff row ("Rooted", "Stunned", "Feared", with icons) and as a short red word under his health bar (the strongest: stun, then fear, then root).

**Summons** (the Maiden's ghouls, the Broodmother's spiderlings, Thresh's Lantern Souls): the wave counts one the moment it is asked for and waits for it. Each summoner has a cap on its live summons. A summoner's death leaves them. A summon pays 25% (§9).

**Vanishing:** a sapling that explodes and Thresh's souls at his fall leave with no rewards at all, no note and no kill. It is the Scuttler's escape without "Escaped!". **Freed:** a Lantern Soul that dies (or vanishes) rises and fades as teal-white light with a soft chime, and pays like any kill.

**The Black Mist** (Act 5): a normal or elite enemy in a mist bank, more than 350 from Lucian, is veiled: a dark silhouette with no health bar and no radar dot. It can still be targeted and hit, and its warnings show. Bosses and mini bosses are never veiled.

**The abyss** (Act 6) blocks walking, dashes, Flash, pulls and enemy bodies, but not bolts, chains or Lucian's shots. A pull stops at its edge. Chain Warden ledges are abyss for physics.

**Final Thresh** never dies at 0 HP in Phase 1: he rises (2.5 s, no damage, full HP, darker, "Phase 2"). At 0 HP in Phase 2 the ending plays. **Karthus's Requiem** shows a break bar under the boss bar; 8% of his max HP in damage breaks it.

**The ending:** the cutscene (skippable), STAGE CLEARED with "Senna is free" and "The story is complete", then, on the first clear only, `TheEndScreen` with the slot's story time. Replays skip it.

**Debug:** the stage debug table gains "Boss HP 5%" and "Jump to the last wave" (every enemy goes, no rewards, and the last wave comes next).

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
- In Act 1, Lucian has **only one gun** (his body art shows one pistol).
- At Act 1's first break, Senna **teaches him E**: he can use it (rank 1) for the rest of the stage.
- After Senna is killed, Lucian takes up her gun (two guns from then on).
- Clearing Act 1 puts **E at level 1** in the Evolution Tree for free, and opens **Q and W** there. Until then Q and W are locked.

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

- The kill that ends a stage (the boss, or the last enemy of the last wave) drops nothing: the result comes up at once, and items don't carry over. The boss row waits for Endless. *(Phase 9: Endless uses it, since every Endless kill drops loot; see §14.)*
- Loot stays until the stage ends. It shows as the item's icon over a bobbing glow (gold for a legendary).
- Lucian picks it up by walking within 60 of it, into the backpack.
- With no room it stays, and "Backpack full" shows at most once every 3 s.

### Built in Phase 7
- **Blue per kill:** 3 in Act 3 and 4 in Act 4 (elites 15 and 20), as the table says.
- **Mini bosses** (the Infernal and Ocean Drakes) pay on the kill: 300 gold, **50 blue, 3 orange**, and **5 purple the first time, 1 after**. The purple rises over Lucian and adds a line to the end screen ("+5 purple essence (Infernal Drake, first kill)", or "repeat"). They are in the save's `"bosses"` list with the bosses.
- **Rift Scuttler:** caught, it pays an elite's rewards plus **45 blue** (raised by Essence Drops like all blue) and **4 orange** for sure. After 15 s alive it escapes with nothing: no gold, no XP, no essence, and not a kill.
- **Jungle buffs:** the Blue Sentinel and the Red Brambleback leave Lucian their buff (60 s) when they die (`act3_the_jungle.md`).
- **Item loot**, the mini-boss row:

| Enemy | Drop |
|---|---|
| Mini boss | A fragment for sure, plus 8% a legendary |

- As before, the kill that ends the stage drops nothing.

### Built in Phase 8
- **Blue per kill:** 5 in Act 5 and 6 in Act 6 (elites 25 and 30), as the table says.
- **Summons pay 25% of their gold and XP, and no blue, no orange and no loot** (so they can't be farmed). The ghouls, the Broodmother's spiderlings and Thresh's Lantern Souls are summons when a summoner calls them; a Lantern Soul that comes from a wave pays in full.
- **Vanished enemies pay nothing** (a sapling that explodes, Thresh's souls at his fall).
- **Mini bosses and bosses of Acts 5–6** (all in the save's `"bosses"` list):

| Boss | Where | Gold | Blue | Orange | Purple (first / repeat) |
|---|---|---|---|---|---|
| Maokai (mini boss) | 5-2 | 300 | 50 | 3 | 5 / 1 |
| Elise (mini boss) | 5-4 | 300 | 50 | 3 | 5 / 1 |
| Karthus (boss) | 5-5 | 300 | 100 | 5 | 10 / 2 |
| Karthus, revived (mini boss) | 6-2 | 300 | 50 | 3 | 5 / 1 |
| Hecarim (mini boss) | 6-4 | 300 | 50 | 3 | 5 / 1 |
| Thresh (boss) | 6-5 | — (his fall pays essences only, as in Act 1) | 100 | 5 | 20 / 4 |

- A mini boss's purple is paid on the kill; a boss's at the stage's clear. Thresh's blue and orange are paid where he fell, as his fall ends the fight; his clear adds "Senna is free" and, the first time, "The story is complete".
- Mini bosses drop a fragment for sure plus 8% a legendary. The kill that ends the stage (Thresh's fall) drops nothing.

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
- **Q, W and E** stay hidden until Act 1 is cleared. Clearing it puts **E at level 1** for free (Senna taught it). A reset takes it back like any level, and it is free to buy again.
- In a stage, skill points only go into bought ranks, and the passive only works once bought.

### Skills
| Node | Cost | Requires |
|---|---|---|
| Q / W rank 1 | 100B each | Clear Act 1 |
| E rank 1 | Free, given when Act 1 is cleared | Clear Act 1 |
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

**Built so far:** Acts 1–2 (Phase 6), Acts 3–4 (Phase 7) and Acts 5–6 (Phase 8) can be played: **all 22 stages**. Endless plays since Phase 9 (§14).

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

The radar takes the map's shape. Acts 5–6 have no map yet. *(Phase 6 said Acts 3–6; Acts 3 and 4 came in Phase 7, Acts 5 and 6 in Phase 8.)*

### Built in Phase 7
Every map now bakes a navigation mesh from its walls (agent radius 36), so enemies and Lucian walk around them (§3).

| Act | Map | Size | Details |
|---|---|---|---|
| 3, stages 1–4 | Jungle | 5600 × 3600 | Paths 420 wide and round clearings in dense jungle: the pit at the top, the center, the start at the bottom, and a clearing for each camp (raptors and Gromp in the top corners, wolves and Krugs at the side edges, Blue and Red low on each side, the Scuttler on the river). The paths make two loops. A riverbed runs from the pit to the start: dry in 3-1 and 3-3, lava pools and Blast Cones in 3-2, shallow water and Honeyfruit in 3-4. |
| 3, stage 5 | The Elder Dragon's pit | 3600 × 3600 | A round stone floor (r 1650) with rock all round it, 6 rocks for cover, waves from the north, east and west rim. |
| 4 | Dark mid lane | 5200 × 3200 | Act 1's layout in black and purple. Dark Lucian rises from the river. |

No wall polygon has a hole: a hole would collide as solid wall. The jungle keeps each loop's inner jungle as a wall of its own, and the pit's rock is 8 arc pieces. Maps draw under the units, at `StageMap.FLOOR_Z`. Details and terrain numbers are in `act3_the_jungle.md` and `act4_the_darkness.md`.

### Built in Phase 8
| Act | Map | Size | Details |
|---|---|---|---|
| 5 | Dead forest (`DeadForestMap`) | 5400 × 3400 | A dark grey-teal clearing between two ragged walls of black trees. 14, 16, 18, 18 and 10 twisted trees (r 45–90) as cover, 2 to 4 Black Mist banks (r 420–500) that veil enemies, a spider nest in the east from 5-3, Maokai's ring of six trunks in 5-2 and Elise's camp in 5-4. 5-5 keeps its trees west of x 3450 and ends in Karthus's ruined graveyard (flagstones, 8 tombstones, a broken crypt wall). The start is in the west, the merchant at the center, and four spawn points in the tree lines. |
| 6, stages 1–4 | Thresh's domain (`ThreshDomainMap`) | 5600 × 3400 | Three slate plateaus (west, center, east) over an abyss, joined by stone bridges with soul lanterns: 4 × 280 wide in 6-1 and 6-2, 3 × 200 wide in 6-3 and 6-4 (the north-west bridge broken). 11 rock spikes as cover. 2 ledges for Chain Wardens (4 from 6-3). The revived Karthus's altar in 6-2 and Hecarim's east end in 6-4. |
| 6, stage 5 | The final platform | 5600 × 3400 | A round carved disc (r 1400) with a rune ring, no walls, a pale dais at its heart for Thresh, and four bridge stubs; waves come from the north, east and south stubs. |

The abyss is several polygons on its own physics layer (no polygon has a hole). Details and numbers are in `act5_shadow_isles.md` and `act6_the_lantern.md`.

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

### Built in Phase 9
Endless plays. Every number is a placeholder: the constants sit at the top of `src/core/endless_plan.gd` and `endless_modifiers.gd`.

**A run:**
- **Start** from the Journey's Endless portal (`main_screen.md`). It opens once Act 3 is cleared. The side panel picks the map: **Random** or one of six. Random rolls a map at Start, and again on Retry.
- The map changes only the ground. Every map has the same enemies and the same ramp.

| Map choice | Built from | Why |
|---|---|---|
| Mid lane | Act 1, stage 1 | |
| Training ground | Act 2, stage 3 | The ring of 10 pillars |
| Jungle | Act 3, stage 4 | Water and Honeyfruit: sustain for long runs |
| Dark mid lane | Act 4, stage 1 | |
| Dead forest | Act 5, stage 3 | 3 mist banks and the spider nest |
| Thresh's domain | Act 6, stage 1 | 4 wide bridges, 2 ledges |

- The stage is named "Endless · Jungle". It starts like a story stage: empty backpack, level 1, 0 gold, and the tree, skin and spells from the save. Wave 1 comes after 5 s.
- **Waves never end.** Every wave is followed by the 20 s break with the merchant. The level cap stays at 18.
- **A run ends** when Lucian dies (RUN OVER) or the player leaves (Leave this run, or Yes / No when quitting). There is nothing to clear.

**Waves** (w = the wave number):

| Wave | What comes |
|---|---|
| w % 10 = 0 | **One boss, alone**, at the map's boss point. Never the boss of the last boss wave. |
| w % 5 = 0 (not 10) | A normal wave with **a mini boss** as its last enemy. Never the last mini boss. |
| Any other | A normal wave |

- **A normal wave:** min(8 + w, 30) normal enemies of **2 kinds** from the normal pool, then min(w / 4, 4) elites, each drawn from the elite pool (repeats allowed). Modifier #2 doubles the elites, up to 8.
  - A pack counts as its size (raptors 5, Murkwolves 3, Krugs 3) and comes whole. When both kinds are packs, the wave can be up to 2 short of the count; it never goes over it.
- The enemies come as in the story: groups of 3 every 1.2 s from the spawn points. Camp enemies, perched Chain Wardens and the nest fall back to the spawn points on maps that lack them.

| Pool | Enemies |
|---|---|
| Normal (12) | Melee, ranged, shadow melee and shadow ranged minions; Raptors, Murkwolves and Krugs (packs); Gromp; sapling; spiderling; Mist Walker; Lantern Soul |
| Elite (11) | Siege, super, shadow siege and shadow super minions; Blue Sentinel; Red Brambleback; Rift Scuttler; Maiden of the Mist; Broodmother; Spectral Rider; Chain Warden |
| Mini boss (6) | Infernal Drake, Ocean Drake, Maokai, Elise, Karthus (revived), Hecarim |
| Boss (5) | Akshan, Elder Dragon, Dark Lucian, Karthus, Thresh (final). Act 1's Thresh never comes: his fight needs Senna. |

**Strength.** It replaces the act and wave scaling. n = w − 1; k is the boss's tier.

| Who | Formula | Wave 1 | Wave 10 | Wave 20 | Wave 35 | Wave 50 |
|---|---|---|---|---|---|---|
| Normal and elite HP | base × (1 + 0.06n) × (1 + 0.05n) | ×1 | ×2.23 | ×4.17 | ×8.21 | ×13.59 |
| Normal and elite damage | base × (1 + 0.025n) × (1 + 0.05n) | ×1 | ×1.78 | ×2.88 | ×5.0 | ×7.68 |

| Who | Formula | Values |
|---|---|---|
| Boss HP (each phase, for Thresh) | 15000 × (1 + 0.3(k − 1)), k = w / 10 | Wave 10: 15000 · 20: 19500 · 30: 24000 · 50: 33000 |
| Mini boss HP | 9000 × (1 + 0.3(k − 1)), k = (w + 5) / 10 | Wave 5: 9000 · 15: 11700 · 25: 14400 · 45: 19800 |
| Boss and mini boss damage | basic damage and every skill hit × (1 + 0.15(k − 1)) | ×1, ×1.15, ×1.3, … |

- Wave 1 is as easy as Act 1. The HP passes Act 6's last story wave (×7.6) at wave 34.
- A boss's HP is fixed by its wave, whoever comes, so the random pick doesn't swing the run.
- The ground hazards bosses leave (the Infernal Drake's burning ground, Karthus's Defile) are not scaled.
- Bosses come at the boss point, mini bosses from their camp or the spawn points. An Endless boss is never the stage's boss, so its kill ends nothing. Final Thresh still rises into Phase 2 at full HP. His fall in Phase 2 has no cutscene: he leaves, and the run goes on.

**Rewards:**
- **Gold, XP and blue** use the story's rules with the act a = 1 + (w − 1) / 10 (whole numbers): waves 1–10 pay like Act 1, waves 11–20 like Act 2, and so on, with no cap. A normal kill gives a blue, an elite 5a. The orange chances are the story's (1% and 10%).
- **Bosses and mini bosses** pay the story's essences (a boss 100 blue and 5 orange, a mini boss 50 and 3). They always pay their **repeat purple, on the kill**: 2 for Akshan, the Elder Dragon, Dark Lucian and Karthus, 4 for Thresh, 1 for a mini boss. The save's `"bosses"` list is never touched, and the end screen gets no purple line.
- **Final Thresh's fall counts as a kill:** 300 gold, XP, a loot roll and his 4 purple.
- **Loot drops on every kill,** a boss's too (§9: a fragment for sure, plus 15% a legendary). There is no last kill in Endless.
- The tree's economy nodes work as in the story. A modifier's reward multiplies on top of them.

**Modifiers** (the table above):
- After each boss wave (10, 20, …) the break **waits**. A **"Choose a modifier"** panel shows **3 cards**: 2 of #1–5 at random (never the current one), then Nothing. The game pauses, the backpack and the menu close, and ESC and P do nothing. A click picks, with the `buff` sound. Then the full 20 s break counts down.
- The pick **replaces** the old modifier; Nothing clears it.

| # | Card (downside / reward) | How it works |
|---|---|---|
| 1 | Enemies move 20% faster / +30% gold | Every enemy's move speed × 1.2 at spawn, summons and splits too. Gold × 1.3. |
| 2 | Elites twice as often / ×1.5 orange drop rate | Elites per wave × 2 (up to 8). The orange chance × 1.5; a boss's sure orange is not. |
| 3 | −10% max HP / +15% blue | Lucian's max HP × 0.9, applied like a skin's scale (his HP share is kept). Blue × 1.15, a boss's too. |
| 4 | −5% AD / +10% gold | Lucian's AD × 0.95. Gold × 1.1. |
| 5 | Bosses and mini bosses +25% max HP / ×1.5 purple | Their max HP × 1.25 at spawn. Purple = round(repeat × 1.5): 3 for a boss, 6 for Thresh, 2 for a mini boss. |
| 6 | Nothing / Nothing | No modifier |

- The enemy speed and boss HP apply from the next spawn; the rest at once. XP has no multiplier.
- The modifier is the first icon in the buff row, with no timer: `stats/move_speed`, `ui/essence_orange`, `stats/max_hp`, `stats/ad` or `ui/skull`. Its hover card is "Endless modifier" with both lines (`ui_design.md`).

**The HUD's stage info:**
- During a wave: "Endless · Jungle  Wave 23  Enemies: 12", or "Mini boss wave" / "Boss wave". There is no "/ N".
- In a break: "Wave 24 in 0:12" (or "Mini boss wave in …", "Boss wave in …") and Skip. While the pick is open, the countdown and Skip hide.
- A dim "Best 22" line under it, read live. The boss bar sits under that line.

**Best wave:**
- It is the most waves cleared in one run: dying in wave 23 records 22. Waves skipped by a debug jump don't count.
- It is kept in memory each time a wave is won (`SaveGame.record_endless`). The run's end-of-stage save (death or Leave) or a Yes when quitting writes it.
- `"cleared"` never gets `"endless"`, and `"bosses"` is unchanged by Endless.

**The end of a run** (the end screen, on death):
- **RUN OVER** in red, then "Endless · Jungle". The `defeat` sound plays.
- **Stats:** Waves cleared, Time, Kills, Damage dealt, Damage taken, Gold earned, Level reached, Modifier (its downside, or "None").
- **Rewards:** the essences, plus a green **"New best: 22 waves!"** ("1 wave" for one) when the run beat the best it started with.
- **Retry** starts a new run on the same map choice (Random rolls again). **Main screen** opens the Journey on Endless, with the run's map still chosen. There is no Next.
- Leaving a run shows no end screen: it saves and opens the Journey on Endless the same way.

**Debug:** "Jump to boss wave" jumps to the next tenth wave (from wave 3 to 10, from 10 to 20) and closes an open pick first. "Jump to the last wave" is hidden. The wave line reads "Wave 7 (Endless)".

---

## 15. Save System

### Slots
- **3 save slots.** The player picks a slot on the **title screen**. That is the **current slot**: every save writes to it.
  - **Start new game** lists the 3 slots. A used slot asks "Overwrite slot N? Its progress will be lost." The new game is **written at once** (`SaveGame.start_new`), so the overwrite is real. Then Act 1 starts.
  - **Load game** lists the same slots, with the empty ones disabled. The button itself is disabled ("No saved games yet") when no slot exists. It opens the main screen.
  - Each used slot shows its play time and when it was saved: "Slot 2 · 1h 02m · saved 2026-10-29 03:10".
- **Save as copy:** the current progress can be copied into another slot (asks for confirmation before overwriting).
- **Leave to main menu** (gear menu) asks "Save before leaving?" (Yes / No / Cancel), then goes back to the title screen.
- Files: `user://save_slot_1.json`, `save_slot_2.json`, `save_slot_3.json`, each with its own `_backup.json`.
- Settings are saved separately in `user://settings.json` and shared by all slots.

### What is saved (permanent progress only)
- Blue, orange and purple essences
- Bought Evolution Tree nodes (summoner spells included)
- The spells picked for D and F
- Owned skins, equipped skin
- Cleared stages, and which bosses / mini bosses already gave first-time purple
- Endless best wave (the most waves cleared in one run)
- Play time: every second outside the title screen, pauses not counted

Nothing inside a stage is saved (items, gold, level, enemies), since stages always reset.

### When to save
- **Auto-save only when a stage is done:** cleared, left (ESC → Leave this stage) or failed (Lucian dies). Nothing is saved between waves.
  - An Endless run is done when Lucian dies or the run is left. Its best wave is kept in memory each time a wave is won, so that save writes it (§14).
- **Nothing on the main screen auto-saves.** Evolution Tree purchases and resets, skin purchases and skin changes are kept only by the next auto-save, the **Save** button in the gear menu, or a **Yes** when leaving.
- **Every exit can be cancelled** (since Phase 9). Cancel, or ESC, closes the question and nothing else happens.

| Exit | Question | Cancel / ESC |
|---|---|---|
| Gear menu → Leave to main menu | **"Save before leaving?"** Yes / No / **Cancel** | The gear menu is still open |
| Exit the game (ESC menu or gear menu); the window's close button anywhere but the title | **"Save before leaving?"** Yes / No / **Cancel** | The game goes on, paused only if it was paused before; an open ESC menu or gear menu stays open |
| ESC menu → Leave this stage | **"Leave this stage? Essences collected so far are kept."** Leave / **Cancel**. In Endless: **"Leave this run? Your best wave is kept."** | Back in the ESC menu, still paused |
| Title screen → Exit game; the window's close button on the title | **"Exit the game?"** Exit / **Cancel** | Stays on the title |

- **"Save before leaving?"**
  - **Yes:** saves to the current slot right away, then leaves. Inside a stage, this keeps the essences collected so far, as leaving the stage would. In Endless it keeps the best wave too.
  - **No:** leaves without saving. Everything since the last save is lost.
  - If the save fails, it asks **"Could not save. Quit anyway?"** (Leave to main menu: "Could not save. Leave anyway?"): Yes leaves, No goes back to the game. These two keep Yes / No, and ESC does nothing on them. A failed auto-save after a stage shows a red "Could not save" on the main screen.
- **Leave this stage:** Leave ends the stage as left: the auto-save, then the main screen. A stage run on its own keeps Leave disabled.
- The title screen has nothing unsaved, so its **Exit game** and the window's close button only ask **"Exit the game?"**. Exit quits. *(Before Phase 9 they quit at once.)*
- The other Yes / No questions stay as they were: Overwrite slot, Reset tree. ESC answers No on them.
- *Phase 5 built "Save before leaving?" with Yes / No and no Cancel, as the user asked then. In Phase 9 the user asked for a Cancel on every exit, which replaces that decision.*
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
| `endless_best` | Best Endless wave: the most waves cleared in one run (dying in wave 23 records 22) |
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
- [x] Implementation / MVP plan (Phase 1: `implementation/phase1.md`, Phase 2: `implementation/phase2.md`, Phase 3: `implementation/phase3.md`, Phase 4: `implementation/phase4.md`, Phase 5: `implementation/phase5.md`, Phase 6: `implementation/phase6.md`, Phase 7: `implementation/phase7.md`, Phase 8: `implementation/phase8.md`, Phase 9: `implementation/phase9.md`, Phase 10: `implementation/phase10.md`)
- [x] Item stats and effects (`items.md`)
- [x] UI (see `ui_design.md` and `main_screen.md`): HUD (with the stage info, boss bar and radar), backpack, crafting, recipe table, ESC menu, merchant's shop, Settings, the main screen (Journey, Evolution Tree, Skin Shop), and the title screen with save slot selection
- [x] Save system
- [ ] Art style, sound (Phase 3 has generated placeholder sound effects and audio buses; Phase 9 adds 11 more, 24 in all, listed in `ui_design.md` §8; no music yet)

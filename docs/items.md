# Items

> Placeholder numbers, LoL-based and about 70–80% similar. The live values are in
> `data/items/**/*.tres`; keep this list in sync when tuning.

Each legendary's stats follow its LoL item, adjusted so it usually carries the stat types
of the two fragments it is crafted from. Only items in **equip slots 1–6** and the **boots
cell** give stats and passives; the backpack is storage. Each item's passive counts **once**,
however many copies are equipped. Since Phase 3 most passives and all three actives work in
combat; see *What works in combat* at the end.

**Icons** (`assets/art/items/`, drawn in 64 units and stored at 128 px): *(V2.0)* each icon is the
item alone on a soft aura, with no frame of its own; the cell it sits in draws a rim by kind
(fragment, legendary, boots, potion). `docs/ui_design.md` has the cells.

**Energized** attacks work like LoL: moving and attacking build stacks; at 100 the next attack is Energized.
In this game: +9 per basic attack, +1 per 24 units walked, and dashes count double (Flash doesn't
count). The charge only builds while an Energized item is equipped.

The merchant buys items back for **70%** of their cost (**Guardian Angel: 40%**). Boots are
never sold.

**Crafting** *(since V1.4.1)* happens only at the merchant's **Craft** tab, never in the
backpack. Two fragments make their legendary for a **fee: the legendary's cost minus the two
fragments' costs** (Muramana: 2900 − 650 − 650 = 1600), so a crafted legendary costs what buying
it would. The legendary takes the first fragment's cell. A crafted legendary always sells for
less than its two fragments sell for plus the craft fee paid (Muramana sells for 2030; two Tears
sell for 910, plus the 1600 fee), so crafting and then selling never makes gold. The same tab
upgrades the boots (see *Boots*). *(V1.5.0: the fragments' new prices put the fees at 900–1600,
from 800–2100; Muramana's was 2900 − 400 − 400 = 2100. The legendaries' prices didn't change.)*

**Craft inputs** *(since V1.4.3)*: an item dragged into a Craft input leaves the backpack view
until it comes back (dragged out, a right-click on the input, a tab change, or the merchant
closing). **Craft** asks first ("Craft Muramana from Tear of the Goddess and Tear of the Goddess
for 1600 gold?"), and a fee you can't pay is refused at once. A craft empties both inputs.

**Buyback** *(since V1.4.2)*: the merchant's **Undo sale** button buys back what you sold, last
sale first, for the gold you got, until you leave the merchant. The item goes back to its old
cell if that is empty, or to a free cell. Stacks and cooldowns of an equipped item that was sold
and bought back are not restored. *(V1.5.0: an old equip cell takes it back only if the
one-penetration rule allows it. Otherwise, or when the old cell is taken, it goes to a free
backpack cell; with none, "Your backpack is full." and the sale stays to undo.)*

**Recipe hints** *(since V1.4.2)*: in the shop, a fragment's card lists what it builds into with
the items you hold ("Builds into Muramana with Tear (you have it)"; at most 3 lines, then "+N
more"), and "Upgrades your Boots into X" when it fits your boots.

**Full backpack** *(V1.4.2, removed in V1.5.0)*: ~~a fragment or legendary with no backpack cell
free goes to an empty, unlocked equip slot instead. Potions never do.~~ Since V1.5.0 buys and
pickups go only into the backpack (and a potion into its own potion cell). With the backpack
full, the merchant declines a buy with a pop-up, "Your backpack is full.", but a shop item
dragged onto a free equip slot is still bought there (if the one-penetration rule allows it).
Loot stays on the ground, with the "Backpack full" note.

**One penetration item** *(since V1.5.0)*: Lord Dominik's Regards, Mortal Reminder and Void Staff,
the legendaries with percent armor or magic penetration, can't share the equip slots: only one
of them can be equipped. A drag, swap or buy that would equip a second one is refused, and a
pop-up names the one equipped ("Only one penetration item can be equipped, and Void Staff already
is."). Moving one inside the equip row is allowed, and the backpack holds any number. A craft puts
its legendary in the first input's cell, or the second's when the rule closes the first; with
both closed it is refused. Boots (Sorcerer's and Spellslinger's Shoes) and Shadowflame's flat
magic penetration don't count.

## Fragments

| Code | Fragment | Stat | Cost |
|---|---|---|---|
| AD | B.F. Sword | +30 Attack Damage | 1100 |
| AS | Recurve Bow | +24% Attack Speed | 950 |
| AP | Needlessly Large Rod | +52 Ability Power | 1050 |
| AR | Chain Vest | +42 Armor | 850 |
| CR | Cloak of Agility | +19% Critical Strike Chance | 750 |
| HP | Giant's Belt | +350 Health | 900 |
| MP | Tear of the Goddess | +490 Mana | 650 |
| MR | Negatron Cloak | +40 Magic Resist | 900 |

*(V1.5.0: the fragments cost 650–1100, from 400–1300, and their stats follow the new cost. Before:
B.F. Sword +35 AD for 1300, Recurve Bow +25% for 1000, Rod +60 AP for 1200, Chain Vest +40 for
800, Cloak +15% for 600, Tear +300 mana for 400. Giant's Belt and Negatron Cloak are unchanged.)*

## Potions

| Potion | Effect | Cost | Stack |
|---|---|---|---|
| Health Potion | Restores 200 HP over 5 s | 50 | 9 per cell |
| Mana Potion | Restores 150 mana over 5 s | 50 | 9 per cell |

- Since V1.4 each potion has its own **potion cell** under the equip slots: Health on key **7**,
  Mana on key **8** (both rebindable). A cell holds 9, like a backpack cell, and is never locked.
- Bought potions fill their potion cell first, then the backpack. The cells are not refilled
  from the backpack: drag more in by hand. An empty cell shows its potion faded.
- Potions can't go in equip slots 1–6. Drink one with its key (7 or 8), from its potion cell.
  *(Since V1.4.1 the backpack has no right-click **Use** button: it let Lucian drink while
  stunned, feared, in stasis or dead.)* A potion can't be drunk while Lucian can't act.
- Several drinks run at the same time. Healing is raised by heal & shield power (Spirit Visage).

## Boots

Added in V1.4. Stats and passives follow LoL (patch 26.x); the live values are in
`data/items/boots/*.tres`.

- **Tier 1** is bought once in the Evolution Tree (Backpack branch, the **Boots** node) and kept
  forever: level 1 is Boots of Speed (300 blue), level 2 Slightly Magical Boots (800 blue +
  10 orange). Lucian starts **every map** wearing them: story stages, the tutorial, Training and
  Endless.
- Boots sit in their own **boots cell**, under the equip slots. It has no key; the boots give
  stats and passives only. Boots never leave it: they can't be dragged out, sold, bought or
  dropped, and the merchant never sells them.
- They are upgraded only at the merchant's **Boots** tab (the **Craft** tab since V1.4.1): drag the boots and a fragment into its
  two slots, press Craft and confirm (it asks since V1.4.3), and pay the fee. The fragment is used
  up, and the new boots show in the boots cell. Tier 2 comes from either tier-1 pair plus
  its line's fragment; tier 3 from that tier 2 plus the same fragment. Giant's Belt has no line.
  *(V2.0: the recipe table beside the backpack lists these 14 recipes under BOOTS, after the
  legendaries. The two tier-1 pairs share the first cell of a tier-2 line, since they make the
  same boots. A line is lit gold while Lucian wears its boots and holds its fragment.)*
- *Slightly Quicker:* Slightly Magical Boots give +10 move speed over Boots of Speed, and every
  pair upgraded from them keeps it (it comes from the tree level, so a save needs nothing new).

| Line (fragment) | Tier 2 (fee) | Tier-2 stats / passive | Tier 3 (fee) | Tier-3 stats / passive |
|---|---|---|---|---|
| AS (Recurve Bow) | Berserker's Greaves (300) | +30% AS, +45 MS | Gunmetal Greaves (500) | +45% AS, +5% life steal, +45 MS |
| CR (Cloak of Agility) | Boots of Swiftness (700) | +55 MS, +25% slow resist | Swiftmarch (500) | +65 MS, +25% slow resist; *Noxian Fervor* |
| AD (B.F. Sword) | Gluttonous Greaves (800) | +45 MS, +4% omnivamp; *Slay* | Immortal Path (500) | the same plus *Now and Forever* |
| MP (Tear) | Ionian Boots of Lucidity (350) | +10 AH, +45 MS, +10 summoner haste | Crimson Lucidity (500) | +20 AH, +45 MS, +20 summoner haste; *Noxian Haste* |
| MR (Negatron Cloak) | Mercury's Treads (550) | +20 MR, +45 MS, +30% tenacity | Chainlaced Crushers (500) | +25 MR, +45 MS, +30% tenacity; *Noxian Persistence* |
| AR (Chain Vest) | Plated Steelcaps (600) | +25 AR, +45 MS; *Plating* | Armored Advance (500) | +35 AR, +45 MS; *Plating*, *Noxian Endurance* |
| AP (Rod) | Sorcerer's Shoes (800) | +12 flat magic pen, +45 MS | Spellslinger's Shoes (500) | +20 flat magic pen, +8% magic pen, +45 MS |

Tier 1 gives +25 MS. LoL's pages don't say whether Chainlaced Crushers keep the tenacity and
Armored Advance keep Plating; here they do, so a tier 3 is never weaker than its tier 2.

New stats for boots: **slow resist** (a 40% slow with 25% slow resist slows 30%), **summoner
spell haste** (shortens summoner cooldowns like ability haste does skills: 100 halves them) and
**flat magic penetration** (taken off the target's magic resist after the percent, never below 0).

## Legendaries

### Infinity Edge

**AD + AD** (B.F. Sword + B.F. Sword) · 3400 gold

- +65 Attack Damage
- +20% Critical Strike Chance
- *Passive — Perfection:* Critical strikes deal 40% more damage.

### Hextech Gunblade

**AD + AP** (B.F. Sword + Needlessly Large Rod) · 3300 gold

- +40 Attack Damage
- +70 Ability Power
- +10% Omnivamp
- *Active — Lightning Bolt (60 s cooldown):* Blasts the target enemy for 175 (+30% AP) magic damage and slows it by 40% for 2 s.

### Kraken Slayer

**AD + AS** (B.F. Sword + Recurve Bow) · 3100 gold

- +40 Attack Damage
- +35% Attack Speed
- +4% Move Speed
- *Passive — Bring It Down:* Every third basic attack deals 140 bonus physical damage, up to 50% more against enemies with low health.

### Mortal Reminder

**AD + AR** (B.F. Sword + Chain Vest) · 3200 gold

- +35 Attack Damage
- +20% Critical Strike Chance
- +30% Armor Penetration
- *Passive — Sepsis:* Dealing physical damage applies Grievous Wounds (40% less healing) for 3 s.
- *(V1.5.0)* A penetration item: it can't be equipped beside Lord Dominik's Regards or Void Staff.

### Stormrazor

**AD + CR** (B.F. Sword + Cloak of Agility) · 3100 gold

- +50 Attack Damage
- +15% Attack Speed
- +20% Critical Strike Chance
- *Passive — Bolt:* Energized attacks deal 90 bonus magic damage and grant 35% move speed for 1.5 s.

### Black Cleaver

**AD + HP** (B.F. Sword + Giant's Belt) · 3000 gold

- +40 Attack Damage
- +350 Health
- +20 Ability Haste
- *Passive — Carve:* Dealing physical damage lowers the target's armor by 5% for 6 s, stacking up to 6 times.
- *Passive — Fervor:* Damaging an enemy grants 20 move speed for 2 s.

### Spear of Shojin

**AD + MP** (B.F. Sword + Tear of the Goddess) · 3100 gold

- +45 Attack Damage
- +300 Mana
- +20 Ability Haste
- *Passive — Focused Will:* Hitting an enemy with a skill grants a stack for 6 s, up to 4. Each stack makes skills deal 3% more damage.

### Bloodthirster

**AD + MR** (B.F. Sword + Negatron Cloak) · 3400 gold

- +55 Attack Damage
- +30 Magic Resist
- +15% Life Steal
- *Passive — Ichorshield:* Healing from life steal above full health becomes a shield that absorbs up to 300 damage.

### Statikk Shiv

**AS + AP** (Recurve Bow + Needlessly Large Rod) · 3000 gold

- +30% Attack Speed
- +45 Ability Power
- +4% Move Speed
- *Passive — Electroshock:* Energized attacks release chain lightning that hits up to 5 enemies for 90 (+20% AP) magic damage.

### Lord Dominik's Regards

**AS + AR** (Recurve Bow + Chain Vest) · 3200 gold

- +30 Attack Damage
- +25% Attack Speed
- +30% Armor Penetration
- *Passive — Giant Slayer:* Deal up to 15% more damage to enemies with more max health than Lucian.
- *(V1.5.0)* A penetration item: it can't be equipped beside Mortal Reminder or Void Staff.

### Runaan's Hurricane

**AS + AS** (Recurve Bow + Recurve Bow) · 2800 gold

- +45% Attack Speed
- +20% Critical Strike Chance
- +4% Move Speed
- *Passive — Wind's Fury:* Basic attacks also fire bolts at up to 2 other enemies near the target, each dealing 55% AD physical damage. The bolts can crit.

### Navori Flickerblade

**AS + CR** (Recurve Bow + Cloak of Agility) · 2650 gold

- +35% Attack Speed
- +25% Critical Strike Chance
- +4% Move Speed
- *Passive — Transcendence:* Basic attacks lower the remaining cooldowns of Q, W and E by 12%.

### Nashor's Tooth

**AS + HP** (Recurve Bow + Giant's Belt) · 3000 gold

- +40% Attack Speed
- +60 Ability Power
- +200 Health
- *Passive — Icathian Bite:* Basic attacks deal 15 (+20% AP) bonus magic damage on hit.

### Void Staff

**AS + MP** (Recurve Bow + Tear of the Goddess) · 3000 gold

- +70 Ability Power
- +20% Attack Speed
- +35% Magic Penetration
- *No passive.*
- *(V1.5.0)* A penetration item: it can't be equipped beside Lord Dominik's Regards or Mortal Reminder.

### Rabadon's Deathcap

**AP + AP** (Needlessly Large Rod + Needlessly Large Rod) · 3600 gold

- +110 Ability Power
- *Passive — Magical Opus:* Increases Lucian's total Ability Power by 30%.

### Malignance

**AP + AR** (Needlessly Large Rod + Chain Vest) · 2900 gold

- +75 Ability Power
- +30 Armor
- +20 Ability Haste
- *Passive — Scorn:* R gains 20 extra ability haste.
- *Passive — Hatefog:* R hits scorch the ground under the enemy for 3 s, dealing 60 (+5% AP) magic damage per second and lowering its magic resist by 10.

### Shadowflame

**AP + CR** (Needlessly Large Rod + Cloak of Agility) · 3200 gold

- +90 Ability Power
- +15% Critical Strike Chance
- +15 Magic Penetration (flat, like Sorcerer's Shoes) *(V1.5.0; it was +10%, so it isn't a penetration item under the one-item rule)*
- *Passive — Cinderbloom:* Magic damage against enemies below 40% health deals 20% more damage.

### Morellonomicon

**AP + HP** (Needlessly Large Rod + Giant's Belt) · 2900 gold

- +70 Ability Power
- +300 Health
- +15 Ability Haste
- *Passive — Affliction:* Dealing magic damage applies Grievous Wounds (40% less healing) for 3 s.

### Archangel's Staff

**AP + MP** (Needlessly Large Rod + Tear of the Goddess) · 3000 gold

- +60 Ability Power
- +450 Mana
- +20 Ability Haste
- *Passive — Awe:* Gain Ability Power equal to 2% of max mana.
- *Passive — Mana Charge:* Hitting an enemy with a skill grants 3 max mana, up to 360.

### Banshee's Veil

**AP + MR** (Needlessly Large Rod + Negatron Cloak) · 3000 gold

- +80 Ability Power
- +40 Magic Resist
- *Passive — Annul:* Grants a spell shield that blocks the next enemy skill. It comes back 40 s after it breaks.

### Thornmail

**AR + AR** (Chain Vest + Chain Vest) · 2700 gold

- +80 Armor
- +200 Health
- *Passive — Thorns:* When hit by a basic attack, deal 20 (+10% bonus armor) magic damage to the attacker and apply Grievous Wounds for 3 s.

### Immortal Shieldbow

**AR + CR** (Chain Vest + Cloak of Agility) · 3200 gold

- +45 Attack Damage
- +20% Critical Strike Chance
- +30 Armor
- *Passive — Lifeline:* When damage would drop Lucian below 30% health, gain a shield of 300-650 (by level) for 3 s. 90 s cooldown. *(Since V1.5.0 only the shields that would absorb the hit's damage type count toward that: a magic-only shield doesn't hold Lifeline back from a physical hit.)*

### Death's Dance

**AR + HP** (Chain Vest + Giant's Belt) · 3200 gold

- +40 Attack Damage
- +40 Armor
- +250 Health
- *Passive — Ignore Pain:* 30% of damage taken is delayed and taken over 3 s instead. *(Since V1.4.2 an **Ignore Pain** icon shows in the buff row while damage is still to come: the number is the damage left, and it goes when the bleed ends or Defy clears it. Since V1.4.3 the damage still to come, and its icon, stay when the item comes off (unequipped, or sold and bought back): only Defy and Guardian Angel clear it. A hit taken without the item isn't delayed.)*
- *Passive — Defy:* Killing an enemy clears the delayed damage. Killing an elite, mini boss or boss also restores 15% max health over 2 s. *(Since V1.5.0; before, every kill healed.)*

### Fimbulwinter

**AR + MP** (Chain Vest + Tear of the Goddess) · 2800 gold

- +40 Armor
- +450 Mana
- +15 Ability Haste
- *Passive — Awe:* Gain bonus health equal to 8% of max mana.
- *Passive — Everlasting:* Slowing or stunning an enemy grants a shield of 100 (+5% max mana) for 3 s. 8 s cooldown.

### Guardian Angel

**AR + MR** (Chain Vest + Negatron Cloak) · 3200 gold

- +40 Attack Damage
- +40 Armor
- +30 Magic Resist
- *Passive — Rebirth:* When Lucian would die, he is held in stasis for 4 s and revives with 50% base health and 30% max mana. 300 s cooldown. *(Since V1.4.3 his cooldowns keep counting down in stasis; only his buff timers stop. See "What works in combat".)*

### Rapid Firecannon

**CR + CR** (Cloak of Agility + Cloak of Agility) · 2650 gold

- +25% Attack Speed
- +25% Critical Strike Chance
- +4% Move Speed
- *Passive — Sharpshooter:* Energized attacks deal 60 bonus magic damage and reach 35% further.

### Galeforce

**CR + HP** (Cloak of Agility + Giant's Belt) · 3200 gold

- +45 Attack Damage
- +20% Critical Strike Chance
- +250 Health
- *Active — Cloudburst (90 s cooldown):* Dash toward the cursor (a short distance at most) and fire three missiles that curve onto the enemy with the lowest health nearby, each dealing 60 (+15% bonus AD) magic damage.

### Essence Reaver

**CR + MP** (Cloak of Agility + Tear of the Goddess) · 3000 gold

- +45 Attack Damage
- +20% Critical Strike Chance
- +20 Ability Haste
- *Passive — Spellblade:* After a skill, the next basic attack deals bonus physical damage equal to 100% base AD (+40% bonus AD) and restores mana equal to 40% of that damage. 1.5 s cooldown.

### Hextech Rocketbelt

**HP + MP** (Giant's Belt + Tear of the Goddess) · 2600 gold

- +60 Ability Power
- +300 Health
- +15 Ability Haste
- *Active — Supersonic (40 s cooldown):* Dash toward the cursor and fire an arc of bolts that fly ahead of you, dealing 100 (+10% AP) magic damage.

### Spirit Visage

**HP + MR** (Giant's Belt + Negatron Cloak) · 2900 gold

- +350 Health
- +45 Magic Resist
- +10 Ability Haste
- *Passive — Boundless Vitality:* Healing and shields Lucian receives are 25% stronger.

### Muramana

**MP + MP** (Tear of the Goddess + Tear of the Goddess) · 2900 gold

- +35 Attack Damage
- +600 Mana
- +15 Ability Haste
- *Passive — Awe:* Gain AD equal to 2.5% of max mana.
- *Passive — Shock:* Skill hits deal bonus physical damage equal to 3% max mana; basic attacks deal 1.5%.

### Jak'Sho, The Protean

**MP + MR** (Tear of the Goddess + Negatron Cloak) · 3100 gold

- +300 Mana
- +40 Armor
- +40 Magic Resist
- *Passive — Voidborn Resilience:* Each second in combat grants 5% bonus armor and magic resist, up to 30%.

### Kaenic Rookern

**MR + MR** (Negatron Cloak + Negatron Cloak) · 2900 gold

- +80 Magic Resist
- +250 Health
- *Passive — Magebane:* After 15 s without taking magic damage, gain a shield against magic damage equal to 15% max health.


## What works in combat

Numbers not given above were picked during Phase 3 (`docs/implementation/phase3.md`) and tuned
in Phase 4 (`docs/implementation/phase4.md`). The defensive items work since Phase 6, when
enemies started hitting Lucian.

| Item | Works as |
|---|---|
| Infinity Edge | Crit damage +40% (175% → 215%). |
| Kraken Slayer | Every 3rd basic attack (the main shot) adds 140 physical, up to +50% as the target's health drops. The count never resets. Buff icon shows the count and glows before the 3rd. |
| Mortal Reminder, Morellonomicon | Physical / magic damage applies Grievous Wounds (3 s) to the enemy: 40% less healing. *(V1.5.0: more enemies heal, and it cuts every heal: the Ocean Drake's mist, the Black Mist's regen, the Maiden of the Mist's drain and Thresh's harvest. See `act5_shadow_isles.md` and `act6_the_lantern.md`.)* |
| Stormrazor | Energized: +90 magic and +35% move speed for 1.5 s. |
| Black Cleaver | Physical damage: Carve, −5% armor per stack for 6 s, up to 6. Any damage: Fervor, +20 move speed for 2 s. |
| Spear of Shojin | The first skill hit of each cast adds a stack (6 s, up to 4); each makes Q/W/R hits deal 3% more. |
| Bloodthirster | Life steal healing past full HP becomes a shield, up to 300. It fades out of combat. |
| Statikk Shiv | Energized: chain lightning on the target, then each nearest enemy within 500, up to 5; 90 (+20% AP) magic each. |
| Lord Dominik's Regards | Up to 15% more damage, at 1500+ more max HP than Lucian (linear). |
| Runaan's Hurricane | Each basic attack also shoots up to 2 other enemies within 450 of the target for 55% AD (can crit, no on-hit). |
| Navori Flickerblade | Each basic attack cuts the remaining Q/W/E cooldowns by 12%. |
| Nashor's Tooth | Basic attacks and Lightslinger shots: +15 (+20% AP) magic on hit. |
| Rabadon's Deathcap | AP ×1.3 (after Awe). |
| Malignance | R gets +20 ability haste. R hits leave Hatefog (once per 3 s): radius 150, 60 (+5% AP) magic per second for 3 s, −10 MR inside. |
| Shadowflame | Magic damage to enemies below 40% HP: +20%. |
| Archangel's Staff | AP from 2% max mana. The first skill hit of each cast adds 3 max mana, up to 360 (kept for the stage). |
| Fimbulwinter | Max HP from 8% max mana. *Everlasting:* slowing an enemy (Hextech Gunblade's active) gives a shield of 100 (+5% max mana) for 3 s. 8 s cooldown. |
| Rapid Firecannon | Energized: +60 magic, and the attack reaches 35% further. A light-blue ring shows that reach from full charge until the Energized shot lands. |
| Essence Reaver | After a skill, the next basic attack adds 100% base AD + 40% bonus AD physical and restores 40% of it as mana. 1.5 s cooldown. |
| Spirit Visage | +25% heal & shield power (life steal, omnivamp, potions). |
| Muramana | AD from 2.5% max mana. Skill hits add 3% max mana physical; attacks 1.5%. |
| Jak'Sho | Each second in combat (dealt damage in the last 3 s): +5% armor and MR, up to 30%. |
| Hextech Gunblade | Active (key 1–6): the enemy under the cursor, else the one nearest it within 700, takes 175 (+30% AP) magic and is slowed for 2 s. Aimed at an enemy farther away, Lucian walks into range first, even with another enemy in range; refused with no enemy in range or under the cursor. |
| Galeforce | Active: dash toward the cursor, as far as it but 200 at most (speed 1260), then 3 missiles at the lowest-health enemy within 750, 60 (+15% bonus AD) magic each. The missiles leave in a fan and curve onto it, faster and tighter as they fly. Lucian can move again as soon as the dash lands. The dash leaves a pale green wind trail. |
| Hextech Rocketbelt | Active: dash toward the cursor, as far as it but 275 at most (speed 800, slower than the bolts' 1500), an arc of 7 bolts forward that fly 900 from where Lucian started (each enemy hit once) for 100 (+10% AP) magic. Lucian can move again as soon as the dash lands. No move speed. The dash leaves a violet trail, like the bolts. |
| Banshee's Veil | *Annul:* blocks the next enemy skill hit whole (Thresh's hook with its pull, Flay, Akshan's skills). It comes back 40 s after it breaks. Basic attacks and the siege shell aren't skills. |
| Thornmail | *Thorns:* an enemy's basic attack on Lucian deals 20 (+10% bonus armor) magic damage back to it and applies Grievous Wounds for 3 s. |
| Immortal Shieldbow | *Lifeline:* a hit that would leave Lucian under 30% HP first gives a shield of 300 (level 1) to 650 (level 18) for 3 s. 90 s cooldown. *(V1.5.0: the shields already up count only if they would absorb the hit's type. Kaenic Rookern's Magebane and Chainlaced Crushers' Persistence take only magic, Armored Advance's Endurance only physical, so they no longer hold Lifeline back from the other type.)* |
| Death's Dance | *Ignore Pain:* 30% of each hit is taken over the next 3 s instead. *Defy:* a kill clears the damage still to come and heals 15% max HP over 2 s. Since V1.4.3 the damage still to come lands even after the item comes off; only Defy and Rebirth clear it. *(V1.5.0: the heal comes only from an elite, mini boss or boss kill, Slay's kinds. Any kill still clears the damage to come.)* |
| Guardian Angel | *Rebirth:* instead of dying, Lucian is held in gold stasis for 4 s (nothing can hurt him; enemies wait), then comes back with 50% base HP and 30% max mana. 300 s cooldown. Stasis ends his burns, slows and crowd control, and none land while it holds. *(V1.4.3: skill, summoner spell and item cooldowns and the attack timer keep counting down in stasis. Only buff timers stop: speed and stat buffs, shields (Barrier's time too), Ghost, potions and heals over time, and item buffs such as Spear of Shojin's Focused Will. Item waits that work like cooldowns keep running: Kaenic Rookern's Magebane wait, Malignance's Hatefog cooldown, Rapid Firecannon's ring wait and the combat timer behind Jak'Sho. HP and mana regen stay stopped, as before.)* |
| Kaenic Rookern | *Magebane:* after 15 s without magic damage, a shield against magic damage only, 15% max HP. Any magic damage restarts the wait. |
| Slightly Magical Boots | *Slightly Quicker:* +10 move speed, kept by every pair upgraded from them. A buff icon shows it. |
| Gluttonous Greaves, Immortal Path | *Slay:* each elite, mini boss or boss kill gives +0.6% omnivamp, up to 10 stacks. The stacks last for the stage and carry over to Immortal Path. Buff icon shows the count. |
| Immortal Path | *Now and Forever:* at 50% HP or more, Lucian deals 4% more damage. Below 50%, healing, shields and health regen are 12% stronger (on top of heal & shield power). |
| Swiftmarch | *Noxian Fervor:* adaptive force equal to 5% of move speed (his stat, not buffs or slows): 0.6 AD per point, or 1 AP when his bonus AP is higher than his bonus AD. |
| Crimson Lucidity | *Noxian Haste:* a skill hit (Q, W, R) or a summoner spell gives +8% move speed for 4 s, once every 4 s. |
| Chainlaced Crushers, Armored Advance | *Noxian Persistence / Endurance:* taking magic (Persistence) or physical (Endurance) damage gives a shield against that damage type of 100 (level 1) to 200 (level 18) +8% bonus HP for 5 s. 15 s cooldown. |
| Plated Steelcaps, Armored Advance | *Plating:* enemy basic attacks deal 10% less damage. Burn ticks don't count. |
| Boots of Swiftness, Swiftmarch | Slow resist weakens every slow on Lucian (the Slowed buff shows the weakened amount). |
| Ionian Boots, Crimson Lucidity | Summoner spell haste shortens Flash, Ghost, Barrier, Heal, Clarity and Smite (after Flash's and Ghost's tree upgrades). |
| Sorcerer's Shoes, Spellslinger's Shoes | Flat magic penetration on every hit Lucian deals. |

Actives share one cooldown per item (every copy), which keeps running after selling. The debug
"No cooldowns" cheat also refreshes item cooldowns that are already running.
"On hit" effects use basic attacks and Lightslinger shots; counters and "next attack"
effects (Kraken Slayer, Energized, Spellblade, Navori, Runaan's) use the main shot only.

**Shields** take a hit in this order: Kaenic Rookern's Magebane (magic only), Chainlaced
Crushers' Persistence (magic only), Armored Advance's Endurance (physical only), Shieldbow's
Lifeline, Barrier, Fimbulwinter's Everlasting, Bloodthirster's Ichorshield.

Void Staff has no passive.

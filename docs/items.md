# Items

> Placeholder numbers, LoL-based and about 70–80% similar. The live values are in
> `data/items/**/*.tres`; keep this list in sync when tuning.

Each legendary's stats follow its LoL item, adjusted so it usually carries the stat types
of the two fragments it is crafted from. Only items in **equip slots 1–6** give stats and
passives; the backpack is storage. Each item's passive counts **once**, however many copies
are equipped. Since Phase 3 most passives and all three actives work in combat; see
*What works in combat* at the end.

**Energized** attacks work like LoL: moving and attacking build stacks; at 100 the next attack is Energized.
In this game: +9 per basic attack, +1 per 24 units walked, and dashes count double (Flash doesn't
count). The charge only builds while an Energized item is equipped.

The merchant buys items back for **70%** of their cost (**Guardian Angel: 40%**).

## Fragments

| Code | Fragment | Stat | Cost |
|---|---|---|---|
| AD | B.F. Sword | +35 Attack Damage | 1300 |
| AS | Recurve Bow | +25% Attack Speed | 1000 |
| AP | Needlessly Large Rod | +60 Ability Power | 1200 |
| AR | Chain Vest | +40 Armor | 800 |
| CR | Cloak of Agility | +15% Critical Strike Chance | 600 |
| HP | Giant's Belt | +350 Health | 900 |
| MP | Tear of the Goddess | +300 Mana | 400 |
| MR | Negatron Cloak | +40 Magic Resist | 900 |

## Potions

| Potion | Effect | Cost | Stack |
|---|---|---|---|
| Health Potion | Restores 200 HP over 5 s | 50 | 9 per cell |
| Mana Potion | Restores 150 mana over 5 s | 50 | 9 per cell |

- Drink: right-click it in the backpack → **Use**, or put it in equip slot 1–6 and press its key.
- Several drinks run at the same time. Healing is raised by heal & shield power (Spirit Visage).
- Nothing is restored while the game is paused, so a potion drunk from the backpack starts on close.

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
- *Active — Lightning Bolt (60 s cooldown):* Blasts the target enemy for 175 (+30% AP) magic damage and slows it by 25% for 2 s.

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
- +10% Magic Penetration
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
- *Passive — Lifeline:* When damage would drop Lucian below 30% health, gain a shield of 300-650 (by level) for 3 s. 90 s cooldown.

### Death's Dance

**AR + HP** (Chain Vest + Giant's Belt) · 3200 gold

- +40 Attack Damage
- +40 Armor
- +250 Health
- *Passive — Ignore Pain:* 30% of damage taken is delayed and taken over 3 s instead.
- *Passive — Defy:* Killing an enemy clears the delayed damage and restores 15% max health over 2 s.

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
- *Passive — Rebirth:* When Lucian would die, he is held in stasis for 4 s and revives with 50% base health and 30% max mana. 300 s cooldown.

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
- *Active — Cloudburst (90 s cooldown):* Dash a short distance toward the cursor and fire three missiles that curve onto the enemy with the lowest health nearby, each dealing 60 (+15% bonus AD) magic damage.

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


## What works in combat (Phase 3)

Numbers not given above were picked during Phase 3 (`docs/implementation/phase3.md`) and tuned
in Phase 4 (`docs/implementation/phase4.md`).

| Item | Works as |
|---|---|
| Infinity Edge | Crit damage +40% (175% → 215%). |
| Kraken Slayer | Every 3rd basic attack (the main shot) adds 140 physical, up to +50% as the target's health drops. The count never resets. Buff icon shows the count and glows before the 3rd. |
| Mortal Reminder, Morellonomicon | Physical / magic damage applies Grievous Wounds (3 s) to the enemy: 40% less healing. |
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
| Fimbulwinter | Max HP from 8% max mana. *Everlasting* (shield) waits for enemies that hit back. |
| Rapid Firecannon | Energized: +60 magic, and the attack reaches 35% further. A light-blue ring shows that reach from full charge until the Energized shot lands. |
| Essence Reaver | After a skill, the next basic attack adds 100% base AD + 40% bonus AD physical and restores 40% of it as mana. 1.5 s cooldown. |
| Spirit Visage | +25% heal & shield power (life steal, omnivamp, potions). |
| Muramana | AD from 2.5% max mana. Skill hits add 3% max mana physical; attacks 1.5%. |
| Jak'Sho | Each second in combat (dealt damage in the last 3 s): +5% armor and MR, up to 30%. |
| Hextech Gunblade | Active (key 1–6): the enemy nearest the cursor within 700 takes 175 (+30% AP) magic and is slowed for 2 s. Refused with no enemy in range. |
| Galeforce | Active: 200-unit dash toward the cursor (speed 1260), then 3 missiles at the lowest-health enemy within 750, 60 (+15% bonus AD) magic each. The missiles leave in a fan and curve onto it, faster and tighter as they fly. Lucian can move again as soon as the dash lands. The dash leaves a pale green wind trail. |
| Hextech Rocketbelt | Active: 275-unit dash (speed 800, slower than the bolts' 1500), an arc of 7 bolts forward that fly 900 from where Lucian started (each enemy hit once) for 100 (+10% AP) magic. Lucian can move again as soon as the dash lands. No move speed. The dash leaves a violet trail, like the bolts. |

Actives share one cooldown per item (every copy), which keeps running after selling. The debug
"No cooldowns" cheat also refreshes item cooldowns that are already running.
"On hit" effects use basic attacks and Lightslinger shots; counters and "next attack"
effects (Kraken Slayer, Energized, Spellblade, Navori, Runaan's) use the main shot only.

**Still tooltip text** (they need enemies that hit Lucian): Banshee's Veil, Thornmail,
Immortal Shieldbow, Death's Dance, Fimbulwinter's Everlasting, Guardian Angel and
Kaenic Rookern. Void Staff has no passive.

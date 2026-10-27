# Phase 3 — Gold, potions, merchant & shop, settings, sound, item passives & actives

## Context

Phases 1–2 built Lucian (move, attack, P/Q/W/E/R, levels), the HUD, the F3+Q debug table, the ESC menu, the backpack with drag/craft, 41 items (stats only) and tooltips. The design docs (`lucian_game_design.md` §3/§6/§7/§9/§15, `ui_design.md` §1/§3/§4) already describe stage gold, the merchant, potions, the shop and settings, but none of it exists in code: no gold, no consumables, no audio, no settings persistence, no item passive runs in combat.

Phase 3 adds all of that on the training map. Output: a playable stage where Lucian earns gold (debug), right-clicks a merchant at the map center, buys/sells/refreshes, drinks potions, tunes settings, and every testable item passive and the 3 actives work with HUD buff icons.

### Decisions made with the user
| Topic | Decision |
|---|---|
| Item passives | **All on-hit / stacking / stat passives that can be tested on the dummy.** Defensive ones that need Lucian to take damage stay tooltip text (Banshee's Annul, Thornmail, Shieldbow Lifeline, Death's Dance, Fimbulwinter Everlasting, Guardian Angel, Kaenic Rookern). |
| Passive source | **Equipped slots 1–6 only**, like stats. Energized icon shows only when an energized item is equipped. Duplicates: each item's passive counts once. |
| Opening the shop | **Right-click the merchant**: Lucian walks over, the shop opens when in range (at once if already close). |
| Buying | **Hold-drag** a shop item into a backpack/equip cell, or **right-click** it to buy into the first fitting cell. |
| "buy hp/mp point" | The **Potions tab** (HP / MP potions, stack 9, restore over time). |
| Controls setting | **Key rebinding only**; skills stay quick cast. |
| Audio | Master / Music / SFX buses + **generated placeholder SFX**. No music track. |
| Item actives | **All 3** (Hextech Gunblade, Galeforce, Hextech Rocketbelt) on keys 1–6 with shared cooldowns on the HUD. |

### Defaults chosen during planning (placeholders, tune later)
- **Gold:** stage starts at 0. Only the debug table gives gold (nothing dies yet).
- **Potions:** HP potion 50 g, 200 HP over 5 s; MP potion 50 g, 150 mana over 5 s; stack 9 per cell. Each drink is its own restore-over-time (several run at once). Healing goes through `heal_shield_power`. Ticks only in `_physics_process`, so nothing heals while paused; a potion used from the paused backpack starts on close.
- **Use a potion:** right-click it in the backpack → small **Use** pop-up (per `ui_design.md`; the "left-click" line in the game design doc gets corrected), or put it in equip slot 1–6 and press the key. No stats from potions.
- **Merchant:** at the map center (2400, 1350); the training dummy moves to (2400, 950). Interaction range 250. A StaticBody on the WORLD layer, so Lucian walks around him. Hover shows a gold ring and "Merchant" label.
- **Merchant visit** = from the merchant appearing until he is removed. Debug "Add merchant" always creates a new visit with fresh stock.
- **Items tab:** 4 slots, **2 unlocked** (debug spin 2–4 until the Evolution Tree), chains on the rest. Each slot: random fragment, or a random legendary at **10%**. **Refresh 100 g** re-rolls only unbought slots; a bought slot shows SOLD for the rest of the visit.
- **Potions tab:** HP and MP potion, unlimited stock.
- **Buy rules:** not enough gold or no room → refused, price flashes red, error SFX. Dragging onto an occupied cell only works for a same-potion stack with room; otherwise the drag returns.
- **Sell:** drag onto the red 7th equip-row cell; pays `floor(cost × 0.7)` (Guardian Angel 0.4) per item, × count for a potion stack. While dragging over it, the cell shows "+N".
- **Shop screen:** the backpack screen in shop mode — backpack column moves left, recipe table hidden, shop panel on the right with its own gold readout, sell cell red. ESC or P closes it. Pauses the game.
- **Energized:** one shared charge 0–100, only while an energized item is equipped (else reset and hidden). +10 per basic attack (main shot), +1 per 24 units walked, dash distance counts ×2. At 100 the next basic attack is Energized and resets it to 0; every equipped energized item triggers on that hit.
- **Which hits are "attacks":** on-hit damage effects (Nashor's, Muramana 1.5%, carve, lifesteal) apply to `basic` and `lightslinger` hits. Counters and "next attack" effects (Kraken, Energized, Navori, Spellblade, Runaan's) use the `basic` main shot only.
- **Once per cast:** Spear of Shojin stacks and Archangel's Mana Charge trigger on the first skill hit of each cast (armed in `try_cast`), so R's 22 bullets give one stack.
- **Passive numbers not in `items.md`:** Kraken bonus scales linearly to +50% at 0% target HP, stacks never expire. LDR: +15% at ≥1500 more max HP than Lucian, linear. Jak'Sho: "in combat" = dealt damage in the last 3 s, +5% armor/MR per second up to 30%. Malignance Hatefog: one zone per 3 s, radius 150. Archangel's mana charge is kept for the stage even if unequipped. Runaan's bolts: 2 extra homing shots within 450 of the target, no on-hit. Statikk chain: target first, then nearest within 500, up to 5.
- **Actives:** aim at cursor. Gunblade targets the enemy nearest the cursor within 700 (refused if none); slow 25% 2 s is a status (dummy shows it). Galeforce: 200-unit dash, then 3 missiles at the lowest-HP enemy within 750. Rocketbelt: 275-unit dash, an arc of 7 bolts forward, +75% MS fading over 2 s. Not usable while casting/dashing or with the backpack/shop open. Shared cooldown per item id, kept after selling.
- **Settings file:** `user://settings.json` with `"version": 1`, saved on every change. Shared by all save slots.
- **Graphics options:** window mode (windowed / fullscreen / borderless), VSync, FPS cap (30/60/120/144/unlimited), quality preset (Low: no MSAA, no dash trail, fewer muzzle flashes; Medium: MSAA 2×; High: MSAA 4×, all effects), show FPS counter.
- **Gameplay options:** skill queue (moved out of the debug table).
- **Rebinding:** one binding per action, keyboard key or mouse button. Rebindable: move, attack, attack-move, Q/W/E/R, D/F, items 1–6, backpack, stats, camera. ESC and F3+Q stay fixed. Binding a key that another action uses swaps them. Reset to defaults. Ctrl + skill key still ranks up. HUD/backpack key labels read the live binding.
- **Canvas layers:** HUD 10, Backpack/Shop 30, Menu 40, Settings 45, Debug 50, tooltips 100.

## Architecture

### Pure core (`src/core/`, GUT-tested first)
- **`Wallet`** (RefCounted): `gold`, `signal changed(gold)`, `add(n)`, `spend(n) -> bool`, `can_afford(n)`. Owned by Stage, passed to HUD, shop, debug.
- **`ItemData`**: `Kind.POTION`; new exports `max_stack := 1`, `restore_hp`, `restore_mana`, `restore_time`; `sell_price()` (70% / GA 40%). `ItemCatalog.potions()`.
- **`Inventory`**: parallel `counts: Array[int]`; `add(item, n := 1)` stacks into same-potion cells first; `count_at`, `take_one(i)`, `space_for(item)`; `Drop.STACK` outcome (moves what fits, rest stays); `remove` returns item + count.
- **`MerchantStock`**: `SLOTS := 4`, `unlocked`, `items`, `sold`, `roll(rng)`, `refresh(rng)` (unsold only), `mark_sold(i)`, `LEGENDARY_CHANCE := 0.1`, `REFRESH_COST := 100`. Uses the catalog.
- **`Shop`** (RefCounted, the transaction rules): `buy(slot_or_potion, inventory, wallet, cell := -1) -> Result`, `sell(inventory, index, wallet)`, `refresh(wallet)`.
- **`RestoreOverTime`**: list of HoTs, `tick(delta) -> {hp, mana}`.
- **`EnergizeCharge`**: `value`, `add_attack()`, `add_distance(d, dash)`, `ready`, `consume()`.
- **`GameSettings`** (class_name, not an autoload so tests and `-s` runs work): lazy `instance()`, `load(path)`, `save()`, defaults, `set_value(key, v)` + `signal changed(key)`, binding (de)serialization, `rebind(action, event)` with swap, `apply()` (AudioServer buses, InputMap, DisplayServer, MSAA, FPS). Tests use their own path.
- **`DamageCalc`**: unchanged formulas; enemies pass effective armor/MR after shred.
- **`Cooldown`**: `reduce_fraction(f)` for Navori.

### Lucian (`src/lucian/`)
- `heal(amount)` / `restore_mana(amount)` use `heal_shield_power`; lifesteal/omnivamp route through them. `shield` value (Bloodthirster) drawn as a white segment on the HUD HP bar.
- **Speed buffs** become named entries `{flat, pct, left, fade}` instead of the single replaceable bonus: W mark, Fervor, Stormrazor, Rocketbelt. `current_move_speed = (base + Σflat) × (1 + Σpct)`.
- **`ItemPassives`** (child node, `src/lucian/items/item_passives.gd`): rebuilt on `inventory.changed` from the unique equipped ids. Hooks called by Lucian:
  - `adjust_stats(stats)` after `at_level`: Awe ×3 (Archangel AP, Fimbulwinter HP, Muramana AD), Archangel mana charge, Rabadon ×1.3 AP, Spirit Visage +25% HSP, Jak'Sho resist %, Malignance R haste.
  - `on_cast(slot)`: arm Shojin / Mana Charge / Spellblade.
  - `on_attack_fired(target)`: Kraken counter, energize consume, Navori, Runaan's bolts, RFC range.
  - `before_damage(target, info)` (new hook in `Enemy.take_damage`, before mitigation): IE (crit), LDR, Shadowflame, Shojin, Kraken low-HP scale.
  - `on_damage_dealt(target, info, final)`: on-hit procs as separate hits with their own `source` (Nashor's, Muramana, Kraken, Spellblade, Stormrazor, RFC, Statikk), carve, GW, Fervor, Jak'Sho combat timer, Bloodthirster overheal, Hatefog. Item-source hits never re-trigger on-hit effects.
  - `buffs() -> Array[BuffState]` for the HUD.
- **Item actives** (`src/lucian/items/item_actives.gd`): Gunblade, Galeforce, Rocketbelt; shared cooldowns keyed by item id; `use_slot(n, aim)` also handles potions. Controller reads `item_1..6`.
- **Energize** distance comes from the per-frame position delta in `_physics_process`.
- `queue_casts` follows `GameSettings`.

### Enemies
- `Enemy` gets a small status list: carve stacks (−5% armor each, 6 s, max 6), Grievous Wounds (3 s), slow (Gunblade), MR shred (Hatefog). Effective armor/MR feed `mitigate`. `EnemyHealthBar` draws tiny debuff icons (item icons + stack number).
- Debug **dummy count 1–5**: extra dummies in a ring around the main one, for Runaan's and Statikk.
- New combat visuals in `src/combat/`: `chain_lightning.gd`, `hatefog_zone.gd`, `item_bolt.gd` (reuse `linear_projectile` / `attack_projectile` where they fit).

### Stage, merchant, shop, settings UI
- **`Merchant`** (`src/stage/merchant.gd` + `assets/art/npc/merchant.svg`): StaticBody2D, hover ring, owns a `MerchantStock`. Controller: RMB on the merchant → `lucian.order_visit(merchant)`; Lucian emits `merchant_reached` → `ScreenSwitcher.set_shop_open(true, merchant)`. Stage `add_merchant()` / `remove_merchant()` (closes the shop if open).
- **`BackpackScreen` shop mode**: `open_shop(shop_panel)` / `close`. Drag source can be a shop slot; `_cell_index_at` tells the sell cell apart from "outside". Sell cell red and active. Right-click a potion → `UsePopup`.
- **`ShopPanel`** (`src/ui/shop/`): tabs Items / Potions, `ShopSlot` cells (ItemIcon + price + SOLD/chain), Refresh button bottom-right, gold readout, red flash on refusal, item tooltips via `HoverTip`.
- **`ScreenSwitcher`**: shop state in `_update_pause()`; ESC closes shop → backpack → settings (back to menu) → menu; P closes the shop; re-docks the debug table.
- **`SettingsScreen`** (`src/ui/settings/`, layer 45): tabs Audio / Controls / Graphics / Gameplay, Back button, applies and saves live. `GameMenu` Settings button emits `settings_requested`.
- **HUD**: top-right gold readout (coin icon + number); `BuffBar` above the bottom panel (anchored like `StatsPanel`, placed on `bottom_panel.resized`), 32 px `BuffIcon`s with stack number, timer sweep, "ready" glow, hover card; potion stack count and active cooldown sweep on `HudItemSlot`; key labels from bindings.
- **Debug table**: Gold (+100 / +1000 / +10000 / reset), Merchant (add / remove / shop slots 2–4), Items (+HP potion, +MP potion, Energize now), Dummies (count), and the skill-queue checkbox removed.

### Audio
- `default_bus_layout.tres`: Master → Music, SFX.
- `Sfx` (`src/audio/sfx.gd`): short `AudioStreamWAV`s generated in code and cached (shot, hit, coin, potion, refresh, error, craft, energized zap); a pooled player node in Stage (ALWAYS, for UI sounds). No-op when absent (tests).

### Art (hand-written SVG, same approach as Phase 2)
`items/hp_potion.svg`, `items/mp_potion.svg`, `npc/merchant.svg`, `ui/gold.svg`, `ui/buff_energized.svg`, `ui/buff_move_speed.svg`, `ui/buff_shield.svg`. Item buffs reuse their item icon.

## Build order (one verified commit per step, on `main`, never pushed)
0. Save this plan as `docs/implementation/phase3.md`.
1. **Gold:** `Wallet` (TDD), HUD gold readout + `gold.svg`, debug Gold section.
2. **Potions data:** `ItemData` potion fields, `Inventory` stacks (TDD), 2 `.tres` + icons, data tests adjusted (potions need restore > 0 instead of stats), potion tooltip card, debug potion buttons.
3. **Potion use:** `RestoreOverTime` (TDD), `heal`/`restore_mana`, Use pop-up, keys 1–6 for potions, stack count on HUD slots.
4. **Merchant:** `MerchantStock` (TDD), `Merchant` node + art, dummy moved, right-click walk-and-open, debug add/remove/slot count.
5. **Shop:** `Shop` rules (TDD), `ShopPanel`, backpack shop mode, buy by right-click and drag, sell cell, refresh, refusals; `test_shop_drag`.
6. **Settings core:** `GameSettings` (TDD: defaults, JSON round trip, version, rebind swap), bus layout, `apply()`.
7. **Settings screen:** 4 tabs, rebinding UI, HUD/backpack key labels, skill queue moved, graphics/quality applied, FPS counter; fix the `tooltip` screenshot scenario (Settings button now enabled → use "Leave this stage").
8. **SFX:** generated sounds and their hooks.
9. **Passive framework:** speed-buff refactor, enemy statuses + debuff icons, `before_damage` hook, `ItemPassives` skeleton, `EnergizeCharge` (TDD), `BuffBar` + `BuffIcon`, debug dummy count.
10. **Stat passives:** Awe ×3, Archangel mana charge, Rabadon, Spirit Visage, Jak'Sho, Malignance Scorn.
11. **On-hit passives:** IE, Kraken, Nashor's, Navori, Essence Reaver, Muramana Shock, Black Cleaver, GW (Mortal Reminder, Morellonomicon), LDR, Shadowflame, Shojin, Runaan's, Bloodthirster shield.
12. **Energized:** charge + icon, Statikk chain lightning, RFC, Stormrazor.
13. **Malignance Hatefog.**
14. **Actives:** Gunblade, Galeforce, Rocketbelt, HUD cooldowns.
15. **Polish:** full GUT run, new screenshots, docs (`items.md` implemented/deferred list, `ui_design.md` shop/settings/buffs, game design §2/§7 fixes), implementation notes in `phase3.md`, report in `docs/report/phase3.md`, then shut down the PC (`shutdown /s /t 120`, so it can be aborted with `shutdown /a`).

## Verification

**Unit / scene tests** (Godot at `%LOCALAPPDATA%\Programs\Godot`):
```
godot_console --headless --path . --import
godot_console --headless --path . -s res://addons/gut/gut_cmdln.gd
```
- `test_wallet`, `test_inventory` (stacking, STACK outcome, take_one, full backpack), `test_merchant_stock` (roll, refresh keeps sold empty, unlocked count), `test_shop` (buy/sell/refresh gold math, refusals, GA 40%), `test_restore`, `test_energize`, `test_game_settings` (round trip, version, swap on conflict, reset).
- `test_item_passives` (scene, Lucian + dummies): each implemented passive changes damage/stats as specified; duplicates count once; backpack-only items do nothing; Kraken 3rd hit; energized at 100 fires Statikk/RFC/Stormrazor procs; Shojin once per cast; carve lowers mitigation.
- `test_item_actives`: cooldowns shared and kept after selling; refused with no target (Gunblade).
- `test_shop_drag`: drag from shop to cell buys; drag to sell cell sells; drop outside returns.
- Existing suites stay green (`test_item_data_files` rules updated for potions, `test_cast_queue` reads the setting).

**Screenshots** (`godot --path . -s res://tests/tools/screenshot.gd -- <scenario> <dir>`): new `merchant`, `shop`, `shop_potions`, `settings`, `buffs`, `energized`, `potions`; existing ones rerun.

**Manual playtest checklist** (written into the report for the user): gold from debug shows top-right; right-click merchant → walk → shop pauses; buy by right-click and drag; sell for 70%; refresh re-rolls only unsold; potions stack to 9, Use pop-up, keys 1–6, heal only while unpaused; settings persist across restarts, rebinding updates HUD labels; volume sliders change SFX; buff icons show and tooltips explain them; energized fills faster while running/dashing.

## Implementation notes (Phase 3 done)

Everything in the build order is in place. Changes and details settled while building:

- **Commits:** steps 4 and 5 (merchant, shop) landed in one commit, so did 6–8 (settings core, screen, sounds: the Settings screen plays a test sound) and 9–14 (the passive framework, every passive, Energize, Hatefog and the actives share the same hooks).
- **Debug table in tabs** (Lucian / Items / Shop / Dummy), with the DPS meter and hit log always under them; it had grown past the screen height. New: gold +100 / +1000 / +10000 / reset, add / remove merchant, shop item slots (1–4), +HP / +MP potion, Energize now, dummy count (1–5, extras in a ring above and beside the first). The skill-queue checkbox moved to Settings → Gameplay.
- **`Inventory`** keeps a `counts` array next to `items`. `add(item, amount)` is all or nothing; `put(cell, item)` / `can_put` place one item in a chosen cell (the shop's drag-buy); `take_one` drinks; `Drop.STACK` merges same potions and leaves the rest. `ItemData.sell_ratio` (0.7, Guardian Angel 0.4) drives `sell_price()`.
- **Shop mode is the backpack screen**: `BackpackScreen.open_shop(Shop)` shows `ShopPanel` beside it and hides the recipe table, so dragging from the shop reuses the backpack's drag. `Shop` (pure, tested) owns the rules; nothing is paid when an item doesn't fit. The sell slot is a drop target (`BackpackScreen.SELL`) only while shopping.
- **Merchant** (`src/stage/merchant.gd`) is a `StaticBody2D` on the WORLD layer with its own `MerchantStock`. `Lucian.command_visit()` walks him into range and emits `merchant_reached`; the stage opens the shop. The dummy moved to (2400, 950) so the merchant can take the center.
- **`GameSettings`** is a `class_name` with a lazy `instance()`, not an autoload, so GUT and the screenshot tool (`-s` scripts) work without it. The screenshot tool uses `user://screenshot_settings.json`, so it never touches the player's settings. Default bindings come from `ProjectSettings` (`input/<action>`), so they don't depend on the live InputMap. Bindings drop modifiers, so Ctrl + skill still ranks up.
- **Sounds** (`src/audio/sfx.gd`) are synthesized into `AudioStreamWAV`s at first use: shot, hit, coin, error, potion, craft, refresh, zap. `Sfx.play()` is a no-op without the stage's Sfx node (tests). `default_bus_layout.tres` adds Music and SFX buses.
- **Passives** (`src/lucian/items/item_passives.gd`) read only the unique equipped ids. Hooks: `adjust_stats` after `at_level`; `on_cast`; `on_moved` (per-frame position change, dashes count double); `on_basic_attack` when the main shot leaves the gun (procs ride on `DamageInfo.procs`); `before_damage`, a new hook `Enemy.take_damage` calls on the attacker before mitigation; `on_damage_dealt`. Item damage uses the item id as its source and never triggers on-hit effects again, so there is no recursion.
- **Move speed buffs** are named (`Lucian.add_speed_buff(id, flat, pct, duration, fade)`): W, Fervor, Stormrazor and Rocketbelt stack; the same id replaces itself. Speed = (base + flat) × (1 + pct).
- **Enemy statuses** (`Enemy.add_status`): Carve lowers effective armor, Hatefog effective MR; Grievous Wounds cuts `Enemy.heal()` (nothing heals yet, so it shows as an icon). `EnemyHealthBar` draws them.
- **Item cooldowns** live on `Lucian.item_cooldowns` (id → Cooldown) and are shared by copies and kept after selling. Essence Reaver's 1.5 s Spellblade uses the same table. `cheat_no_cooldowns` also skips item cooldowns.
- **Quality Low** skips dash trails and muzzle flashes (and MSAA); the shot sound still plays.

### Running the checks

```
godot_console --headless --path . --import
godot_console --headless --path . -s res://addons/gut/gut_cmdln.gd
godot --path . -s res://tests/tools/screenshot.gd -- <scenario> <output_dir>
```

New scenarios: `gold`, `potions`, `shop`, `settings`, `buffs`, `actives`, `energized`. One test file can run alone with `-gconfig= -gtest=res://tests/unit/<file>.gd -gexit`.

# Translation

*(V2.0.1)* The game is written in English and can be shown in Vietnamese. This page is the contract for code and for translators.

## How it works

- **Choosing:** Settings → Gameplay → Language, or the two buttons at the title screen's top right (each language named in itself). The choice is the `language` setting (`en` or `vi`), saved with the other settings for every save slot. It starts as English.
- **Switching:** the title screen and the main screen are built again in the new language at once, with Settings open where it was. During a stage the choice is locked: a stage keeps the language it started in.
- **Looking up:** every text a player reads goes through `Lang.t(text)` at the place it is shown. `Lang.t` answers with the Vietnamese, or with the English when there is none.
- **The files:** `locale/vi/*.po` (gettext), one per part of the game, all listed in `project.godot`. English has no file: it is the text in the code.
  - `common.po`: names and words every part shares (stats, items, skills, enemies, buttons).
  - `items.po`: item texts, tooltips, the backpack and the merchant.
  - `stage.po`: the HUD, Lucian, enemies and bosses, tips, scenes, the end card.
  - `main.po`: the Journey, the Evolution Tree, the Skin Shop.
  - `shell.po`: the title, Settings, the menus and the pop-ups.
- **Not translated:** the game's name on the title, champions' names, key names (Space, LMB), the debug tables, and what is listed in `locale/untranslated.txt`.

## Rules for code

1. **Write the English, translate where it is shown.** `label.text = Lang.t("Skip")`. A text kept in a constant or a data resource is translated when it is used: `Lang.t(item.display_name)`, `Lang.t(TAB_NAMES[i])`.
2. **A text with values is translated as its format, then filled:** `Lang.t("Wave %d/%d") % [wave, waves]`. Never build a sentence from translated pieces of a sentence: give the whole sentence as one format.
3. **A translation keeps the values' order.** If Vietnamese needs another order, use named values: `Lang.t("{item} from {boss}").format({"item": ..., "boss": ...})`.
4. **Nothing translated is stored or compared.** Saves, ids, dictionary keys and tests of equality use the English or the id. A save loads in any language.
5. **Text drawn by hand** (`draw_string`) is translated in `_draw` the same way.
6. **A new text needs its Vietnamese** in the part's `.po` file, or a line in `locale/untranslated.txt`. The tests fail otherwise.

## Rules for the Vietnamese

- **Names** follow the Vietnamese League of Legends client where it has one (`common.po`). One English term has one Vietnamese term everywhere.
- **Voice:** short interface Vietnamese. Speak to the player as "bạn". Buttons are verbs ("Quay lại", "Bỏ qua").
- **Capitals:** proper names take a capital on each word ("Vô Cực Kiếm"); sentences take one at the start; a heading in capitals in English stays in capitals ("CHỌN ĐỘ KHÓ").
- **Keep** every value (`%d`, `%s`, `%.1f`, `{name}`), every BBCode tag, every line break and the spaces at a text's ends. `%%` is a percent sign.
- **Length:** the interface was laid out for English. Keep a translation near its English's length; where it cannot be, say so and the layout is widened.
- **A comment** (`#.`) above each entry says where the text shows and what each value is.

## Tests

- `tests/unit/test_lang.gd`: the setting, the picker, the rebuild.
- `tests/unit/test_translations.gd`: the files load; no translation is empty, breaks its values or tags, or differs between two files; every text in `src/` and `data/` has a Vietnamese or is listed as untranslated.
- `tests/unit/test_lang_<part>.gd`: each part's screens, built with `Lang.probe` on, show no text that skipped `Lang.t` (`LangProbe.plain_texts`).

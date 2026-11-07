# Game Text Editing Guide

Edit player-facing text in `game_text_merged.csv`, the active runtime table. `game_text.csv` preserves the working table from before the coworker rewrite merge as a backup; the game does not load it and Windows exports exclude it.

The merged table preserves the original 515 IDs and row order. Later rows cover additions including the opening door reminder, departure hint, and main menu panels.

Columns:

- `category`: Groups text by area, such as `dialogue`, `ui`, `prompt`, `item`, `shop`, `task`, `ending`, `map`, or `system`.
- `key`: Stable ID for future code-based lookup.
- `source_text`: The text currently used by scenes, resources, or scripts.
- `english`: What appears when the language is English.
- `tagalog`: What appears when the language is Tagalog.
- `notes`: Reminders for special formatting.

Rules:

- Keep `%s`, `%d`, and other `%` placeholders in both translations.
- Keep BBCode tags such as `[b]` and `[i]` when they appear in dialogue.
- Use `[color=#c7b8dd][i]...[/i][/color]` for action narration and `[color=#a9d8e8]...[/color]` for thoughts embedded in spoken dialogue. End the color before the next spoken sentence. The shared monologue UI already uses pale blue. Preserve spoken italic emphasis and the existing yellow `[b]` gameplay hints.
- To change current game text without touching scenes, edit `english` and `tagalog`.
- If a scene/resource changes its source text, add or update the matching `source_text` row.
- New code can use `LocalizationManager.translate_key(key, fallback_text)` for cleaner future text IDs.
- Repeated source phrases keep their first translation as the general default. Context-specific aliases must use `translate_key`: `lotto.close` and `ui.linda_trade_prompt` intentionally differ from their general source defaults. Never rely on CSV row order to overwrite another context's translation.

Dynamic text must retain its source and format values if it needs to update while visible. `QuestNPC.show_choice_prompt(source, accept, decline, values)` translates before substituting values; do not format the source before lookup. Automatic localization preserves later unknown dynamic assignments rather than restoring stale text.

Button language remains CSV-driven. Existing action labels such as Resume, Accept and Not now are intentionally English in both columns; there is no blanket Button exemption. Milestone 2 adds five quest-choice prompts, not complete intro/narrative translation coverage.

## Export requirement

Keep `game_text_merged.csv` imported as **Keep File (exported as is)**. `LocalizationManager` reads the raw file with `FileAccess`; Godot's CSV translation importer produces translation resources instead and leaves the raw table out of the package, even with an export include filter. Both Windows presets include this active CSV and exclude the backup. Check the export manifest for `res://game/localization/game_text_merged.csv`, not merely its `.import` metadata.

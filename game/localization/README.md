# Game Text Editing Guide

Edit player-facing text in `game_text.csv`.

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
- To change current game text without touching scenes, edit `english` and `tagalog`.
- If a scene/resource changes its source text, add or update the matching `source_text` row.
- New code can use `LocalizationManager.translate_key(key, fallback_text)` for cleaner future text IDs.

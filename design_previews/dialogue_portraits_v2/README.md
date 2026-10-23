# Approved dialogue portrait library v2

Status: **approved and integrated into Godot dialogues and NPCs.**

[preview.html](preview.html) documents all 18 characters, 68 portraits, model references and approved English/Tagalog line assignments. [cast.html](cast.html) is the compact overview; the six [expression sheets](sheets/) show portraits at the 150px base display size.

## Installed coverage

- 17 active NPCs, including all four shop speakers, plus Player.
- 63 NPC portraits and five Player states, all with black rectangular glasses.
- 64 active interaction lines (57 NPC, seven Player replies), plus two configured Linda fallback lines.
- Shared task/pickup/object monologues use Player thinking.
- Each character has a consistent location background across expressions. Player thinking retains its approved cooler background.

All 68 PNG masters were copied byte-for-byte to `game/assets/npc_portraits/stylized/`. Existing `DialogueLine.expression` bindings select each line's approved expression. No emotion manager or automatic text inference was added. Original images and 12 legacy/unreferenced dialogue lines remain preserved. Lola's `Resource_clmbx` now correctly identifies Lola rather than Nanay.

## Design and provenance

The approved roster and exact assignment contract are in [metadata/roster.json](metadata/roster.json) and [metadata/dialogue_assignments.json](metadata/dialogue_assignments.json). The contract's historical `proposed_*` names now describe installed choices. [metadata/prompts.json](metadata/prompts.json) records all 68 builtin-imagegen prompts, inputs and source files. Model identity evidence and independent design reviews remain in metadata. Nanay/Lola follow their current models; Linda, Hardware Girl and Grocery Girl share their blonde model identity with distinct backgrounds. The Player preserves the approved player style with glasses added.

## Integration and checks

[metadata/integration.json](metadata/integration.json) lists the 19 edited runtime resources and their hashes. Exact pre-integration files, including pre-existing uncommitted work, are retained under `metadata/integration_baseline/`. Dialogue source text/localization, quest branches, shops, timer logic and character models are preserved.

Run `python design_previews/dialogue_portraits_v2/build_review.py --verify` to check artwork provenance, gallery links, all 68 installed image/master pairs, and the 253-file runtime baseline with exactly the 19 approved resource edits. The original pre-integration design check remains documented in earlier review records.

The focused Godot fixture loads and decodes all 68 textures, discovers actual NPC scene sequences, and exercises all 66 lines through real DialogueUI in English and Tagalog. It checks portrait switching, missing-portrait visibility/recovery, localized text/speakers and the monologue binding. Final engine results and limits are in [metadata/integration_verification.md](metadata/integration_verification.md).

No commit or push was performed. Browser artwork previews and scripted Godot tests do not replace manual gameplay or packaged-build acceptance.

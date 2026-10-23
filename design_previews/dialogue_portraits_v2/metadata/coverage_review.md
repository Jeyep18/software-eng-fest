# Independent coverage review

Reviewed 2026-10-11 against the current working tree. This review changes only this evidence file; it does not integrate portraits or alter runtime behavior.

## Coverage

- The roster covers all 17 talking NPCs instantiated by the current SceneManager destinations: Nanay and Lola at home; Ate Linda, Mang Nestor, Kapitbahay and Tambay at Tindahan; Pharmacy Boy, Tindero and Ate Maribel at Pharmacy; Hardware Girl, Tatay Jun and Tauhan ni Kap at Hardware; Grocery Girl, Queue Man, Panic Buyer, Nanay sa Palengke and Stranger at Grocery.
- Barangay Hall, Mang Romy, Bodega, test room 1 and HouseAct1 contain no additional authored NPC speaker. The old Act1.tscn references legacy Nanay, but SceneManager's act1 destination points to HouseAct1.tscn rather than that old scene.
- The **64 authored NPC-interaction lines** count is valid: 57 NPC lines and 7 player replies. Independently counted speaker resources in every roster NPC scene; each count exactly agrees with dialogue_assignments.json and roster.json.
- Two separately configured Ate Linda fallback lines are correctly excluded from the 64: all current branch sequences are non-null, so the fallback is not selected. The 12 old or unreferenced lines are also separated correctly.
- No dynamically constructed NPC DialogueLine or DialogueSequence was found. Quest and shop scripts select their configured sequences; modal choice labels are separate from portrait dialogue.

## Line meaning and expressions

- All 64 assignment texts and their English/Tagalog translations agree with the first source-text row in game/localization/game_text_merged.csv, matching LocalizationManager.translate() behavior.
- Assigned expressions fit the current localized meaning: concern/urgency for family warnings, hopeful/grateful for Mang Nestor, frustration and anxiety in Grocery, and the stores' cheerful, weary/helpful or urgent/annoyed tones. Existing platform support already uses DialogueLine.expression per line; new expression assets can use that mechanism after approval.
- Lola's Resource_clmbx currently labels its speaker Nanay, but its localized line starts "Sabi ni Nanay..." and reports Nanay's words from Lola's food-hint sequence. The proposed Lola identity and concerned expression are appropriate. Keep this correction explicitly reviewable and apply only during approved integration.
- The 64 count excludes player task, item pickup and narrative monologues. Those all use the fixed playerInnerThoughts.png in the shared monologue_ui.tscn. Replacing that shared image with the approved glasses/thinking portrait will cover these callers; their line-specific expression selection is not represented by this NPC assignment manifest.

## Models

- All 17 recorded NPC model SHA-256 values match the current files. The direct scene references match the roster. Ate Linda, Hardware Girl and Grocery Girl correctly share game/assets/models/nanay_model.tscn, which wraps Animated Woman.glb.
- The eleven animated NPC entries also record matching polished external export paths. Six other entries have no matching external-export hash; their external previews remain visual references rather than proof that an external render was produced from the exact current file.
- Nanay and Lola's documented differences between approved initial portraits and active models should stay visible at design approval. Matching those current model identities is consistent with the user's new request to use model references where possible.
- Player is present in the roster with the explicit glasses requirement, but model_references.json currently has no Player entry. This is an evidence gap, not an NPC coverage gap. Glasses must be visually checked in every proposed player expression.

No Godot rendering, device/input checks, or portrait integration were performed. This audit proves source coverage and mapping consistency, not visual approval or runtime correctness.

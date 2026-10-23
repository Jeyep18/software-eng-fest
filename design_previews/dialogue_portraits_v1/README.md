# Dialogue portrait style preview v1

Preview date: 2026-10-11 (Asia/Manila).
Status: awaiting user visual approval. No runtime integration is authorized in this pass.

Open preview.html to inspect the five generated previews at large size and at 150 x 150 px.

## Proposed direction

Original faceted 2D portraits with deliberate contours, broad cel shading, muted storm backgrounds, restrained print texture, and a shared sea-green / charcoal / ivory frame. The three player states share identity and framing. Nanay preserves rectangular glasses, black hair, earrings, and purple clothing; Lola preserves silver hair, round glasses, pearls, and a flower brooch.

## Inputs and provenance

- User-supplied character references: C:/Users/john2/Downloads/playerTalking2.png, playerTalking.png, playerInnerThoughts.png, mamawoo.png, Gemini_Generated_Image_xzdgclxzdgclxzdg.png.
- Palette/world reference: design_previews/static_npc_integration/overview_front.jpg.
- Illustrated shape/texture reference: game/assets/scratch_lotto/scratch_ticket_face.png.
- Current design guidance: docs/ART_ASSET_GENERATION.md, docs/GAME_DESIGN.md, game/ui/GameUIStyle.gd.
- Generator: built-in imagegen, opaque PNG output.
- Exact final prompts: prompts.json. Later portraits use player_calm.png as their style master; the original identity image is the other input.
- Files are copied without altering generated output pixels. Original generated files remain under C:/Users/john2/.codex/generated_images/01a12911-1d6a-7383-aa81-84d435f4f9ef/.

## Verification performed

All five PNG headers were checked: each generated master is 1254 x 1254 pixels (the generator returned this size despite the requested 1024 x 1024). The five prompt records parse as JSON, and every local preview image/link resolves to a file. The browser loaded all ten image instances; the smaller copies render at exactly 150 x 150 CSS pixels. The page was visually inspected at that size, and its screenshot is saved as review.jpg. This does not establish Godot rendering behavior.

## Acceptance limits

The preview page is a browser comparison, not a Godot rendering test. UI scaling, actual dialogue placement, optional VHS/CRT effects, final texture import, emotion coverage for additional NPCs, and expression bindings need validation after the design is accepted. No runtime portrait, scene, resource, script, or localization entry has been edited.


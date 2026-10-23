# Approved portrait integration verification — 2026-10-11

## Result

Installed 68 approved PNGs for 17 active NPCs and Player. All 64 active interaction lines plus two Linda configured fallback lines select their approved character/expression. Shared inner-dialogue uses Player thinking with glasses. Lola Resource_clmbx is now correctly named Lola. Original dialogue text, localization tables, models, branches and shops are preserved.

## Godot evidence

Godot 4.6.1 official ran against a current-runtime disposable copy at `C:/Temp/bagyong-portraits-20261011/project`, with isolated APPDATA/LOCALAPPDATA and guarded BAGYONG_ISOLATED_SMOKE. No dependency install or project configuration change was needed.

- [Headless portrait regression](../validation/portrait.log): **686 checks, 0 failures**, all 68 imported images match source pixels, 66 real resource lines exercise actual DialogueUI in English and Tagalog, visibility recovery and shared monologue binding.
- [Forward Plus/Vulkan portrait regression](../validation/visual.log): **691 checks, 0 failures**, including five real 1920x1080 UI render captures on RTX 4050 with the default VHS/CRT overlay. [Final rendering diagnostics](../validation/visual-error.log) are empty.
- [Ate Linda trade/shop regression](../validation/linda.log): **17 checks, 0 failures**, including trade accept/decline, prices/stock and language switching.
- [Read-only working-project cache audit](../validation/workspace-cache.log): **68 portraits, 0 pixel mismatches**. The probe ran from the disposable project and read working-project imported textures without writing its cache.

The first disposable import yielded 12 bad decoded textures; the first GPU stress probe also exhausted memory. Rebuilding only disposable portrait cache entries fixed the decode mismatches. The fixture now releases rendering resources between scene loads and compares every imported pixel against the source PNG, catching failures that dimensions alone miss. Production portrait caches matched all masters. Source artwork and compression settings were not changed. Some headless test exits report existing ObjectDB/resource-in-use diagnostics separately from passing checks.

Saved UI captures: [Nanay](../validation/nanay.png), [Linda](../validation/ate_linda.png), [Grocery Girl](../validation/grocery_girl.png), [Player reply](../validation/player.png), [Player thinking](../validation/player_thinking.png). All five were visually inspected for portrait identity, color, frame and text presentation; the capture background is the fixture, not a rendered gameplay location.

## Independent scope review

A read-only independent reviewer compared all 19 edited resources to exact pre-integration files. Only approved expression fields, texture dependencies and Lola's approved speaker correction changed. All 66 mappings match the approved assignment contract. There are no duplicate/undefined ExtResource IDs. All 68 runtime image SHA-256 hashes match approved originals. Other scene/resource properties and pre-existing uncommitted work are preserved; no blocking defect was found.

`build_review.py --verify` additionally checks the complete artwork/generation roster, gallery links, master/runtime file pairs and the 253-file pre-generation baseline: exactly the 19 approved resource edits differ, with their installed hashes matching integration.json. Git diff whitespace checks pass, with existing CRLF normalization warnings on animated NPC scenes.

## Limits

Scripted resource/UI and Linda shop checks are not a manual playthrough of every NPC branch or standalone Windows export acceptance. No commit or push was performed. No 3D model was changed as part of portrait integration.

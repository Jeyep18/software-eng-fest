# Public release notices and attribution follow-up

**November 7, 2026, Asia/Manila**

The menu now has concise contributor credits, detailed third-party attributions, offline project terms and license texts, privacy information, and an AI assistance disclosure. Jeyep18 and 3 Netherite Ingots appear first. The team permits free personal and educational play of official builds while reserving reuse and redistribution rights in original project material. Third-party permissions remain intact. [Project permission](../../LICENSE.txt)

The owner confirmed original modeling, environments, house maps and art direction by Jeyep18 and the team, with AI-assisted map and NPC portrait artwork under their direction. Codex and ChatGPT assisted programming, debugging, testing and documentation. Those confirmations are recorded separately from the authorship and licenses of imported packs. [AI disclosure](../../game/legal/AI_DISCLOSURE.txt)

## Updated source findings

| Work | Source and terms | Local evidence and remaining mapping |
| --- | --- | --- |
| Low Poly Tool Pack | Lyndschoko, CC BY 4.0. The exact Sketchfab ID, creator and license were verified through its public model API. [Creator page](https://sketchfab.com/3d-models/low-poly-tool-pack-66fc15e383a9453984db4ededd41ed3c) | Owner-listed source family for the active wrench and Bodega tools. The Bodega and standalone wrench textures have the same SHA-256. The original source archive was not compared. The separate Hammer has identifiers beginning `10293_Hammer`, so its exact source remains unresolved. |
| Low-Poly Bed | The supplied floating-world URL redirects to psychopom. Custom terms allow commercial/noncommercial project use, appreciate credit, and restrict standalone redistribution and resale. [Creator page](https://floating-world.itch.io/low-poly-bed) | Standalone `bed.glb` and its image are unused by current runtime references and were in the earlier pack. The active house bed has different mesh counts, so the standalone source does not establish the visible bed's origin. |
| PS1/PSX Tree and Grass Pack | Domi, CC BY 4.0. Credit, source and license links are retained. [Creator page](https://domi236.itch.io/ps1-style-tree-and-grass-pack) | Owner confirmed this tree source along with Elegant Crow and halfhuman. The generic `Tree.glb` and embedded trees still lack a model-by-model mapping to those packs. |
| Retro Model Pack Interior | Kkryy, CC0. [Creator page](https://kkryy.itch.io/retro-interior-pack) | Owner-confirmed interior source family. Original archive entries were not compared with each exported object. |
| Retro furniture set with dithering | chikievna, CC0. Some source textures are from AmbientCG. [Creator page](https://chikievna.itch.io/retro-furniture-set-with-dithering) | Distinctive atlas names such as `freezer`, `door&shelf` and `sofa&sideboard` corroborate the supplied family. Inventory rows distinguish family attribution from an exact original-file match. |
| Retro PSX Nature Pack | Elegant Crow, CC0, with AmbientCG and Pixabay source imagery identified by the publisher. [Creator page](https://elegantcrow.itch.io/retro-psx-nature-pack) | This is the owner-supplied nature pack. It replaces the earlier guessed link to the separate Retro Tree Pack for this source family. |
| Objects Interior (Village) Alpha and Buildings | Elbolilloduro, publisher-declared CC0. Buildings also identifies external texture libraries. [Interiors](https://elbolilloduro.itch.io/objects-interiorvillage-alpha), [Buildings](https://elbolilloduro.itch.io/buildings) | Owner-confirmed upstream packs. Original project scene composition and modifications retain the team's separate credit. |
| VHS and CRT monitor effect | pend00, CC0. [Shader source](https://godotshaders.com/shader/vhs-and-crt-monitor-effect/) | Source functions, uniform names, noise, aperture-grille and warping formulas match the active shader's derivation. The game adapts it for Godot 4, recording time and visual settings. |
| PSX Character - Sackhead Killer | Aredius. Custom terms permit game-project use, require credit as Aredius, restrict raw redistribution even after modification, and request notification when used in a game. [Creator page](https://arediuspsx.itch.io/sackhead-killer) | Supplied source reference with no identified local receiving model. No `sack`, `bagman`, `killer`, `Jesse` or `Aredius` identifying node/material/image names were found. It remains an unmapped reference, with no claim of use in public contributor credits. |

## Inventory changes

The [inventory](2026-11-04-asset-inventory.csv) now has 1,099 rows, including the two shaders omitted from the earlier media-only extension list. It records 425 normal game dependencies, 143 recording dependencies, 16 test or legacy dependencies, 5 inactive references, and 510 files with other or unresolved runtime status. Thirty-four model/source rows now record owner-confirmed project work, and 79 active map/portrait images record owner-confirmed AI-assisted art direction.

A source family is an attribution to an owner-supplied pack corroborated by local names or content. It does not claim that every component was compared with the original download. Six identical local image copies inherit the matched file's attribution with the duplicate path recorded. The inventory still has 272 rows marked `Unknown original creator`, including 236 normal game dependencies, plus one separate unresolved mesh source. Many rows are texture variants and components within the same shared environments.

The existing `In audited Windows pack` column remains the historical November 4 demo result, now including its two shader rows. That baseline has 826 included inventory rows. A separate November 7 public-export decision column records the approved exclusions and retained export behavior. It does not substitute for inspecting a fresh package.

## Offline notices and distribution files

The repository's `game/legal` directory supplies the menu text and the companion `licenses` folder planned beside the executable. The project terms, privacy notice and AI disclosure also have Tagalog reading aids. English controls where those reading aids differ. Creator names, individual source links and original license texts remain unchanged between language views.

Full texts were retrieved unchanged from Creative Commons' official legal-tools repository. The Inter text matches the existing bundled font notice byte for byte. Godot's own license and compiled component notices are supplied through the engine's license APIs by the menu and distribution work.

| File | Official source or consistency check |
| --- | --- |
| `PROJECT_LICENSE.txt` | Same bytes as the root [LICENSE.txt](../../LICENSE.txt). |
| `THIRD_PARTY_NOTICES.txt` | Individual works, creators, known license links, adaptations and summaries of custom terms. |
| `PRIVACY.txt` | Local v2 leaderboard, temporary/backup score files, settings, archived old leaderboard and diagnostic logs. External links open in the player's browser. |
| `AI_DISCLOSURE.txt` | Owner-confirmed tools and assistance scope. |
| `CC_BY_3.0.txt` | [Official plain text](https://creativecommons.org/licenses/by/3.0/legalcode.txt). SHA-256 `e6bc9e9c474700b708f568bac9e5a8a9bcb2b1dad53442f5ba449fcb848b8e76`. |
| `CC_BY_4.0.txt` | [Official plain text](https://creativecommons.org/licenses/by/4.0/legalcode.txt). SHA-256 `9ba9550ad48438d0836ddab3da480b3b69ffa0aac7b7878b5a0039e7ab429411`. |
| `CC0_1.0.txt` | [Official plain text](https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt). SHA-256 `a2010f343487d3f7618affe54f789f5487602331c0a8d03f49e9a7c547cf0499`. |
| `INTER_OFL.txt` | Exact copy of the existing [font notice](../../game/assets/fonts/inter/OFL.txt), including copyright. |

The legal-code files came from the same published paths in Creative Commons' [official data repository](https://github.com/creativecommons/cc-legal-tools-data). The website download endpoint rejected the shell request. The full official texts were preserved without rewriting their clauses.

## Public export checklist

- [x] Preserve creator/work links and distinguish team originals, AI assistance and imported assets.
- [x] Add source/license credit for Domi, Lyndschoko and pend00, and retain the existing CC BY audio/font/model attributions.
- [x] Include full CC BY 3.0, CC BY 4.0, CC0 and Inter OFL notices for offline reading.
- [x] Apply the approved public-preset exclusions for Bates Shower, both Traveling Typewriter formats and the unused ErickBloem outside-birds recording. Source copies remain in Git.
- [x] Verify the fresh public package contains the legal menu files and excludes those font and audio payloads.
- [x] Verify the companion `licenses` directory, Godot notices and readme in the final Windows distribution.
- [x] Complete the rendered menu, keyboard and local-data-flow checks and record the exact results.
- [ ] Complete native interactive verification of the packaged executable.
- [ ] Resolve permission or an owner-approved replacement for the active DZRH recording before a public distribution decision.

A focused Godot 4.6.1 catalog check passed all 7 contributor sections, 7 detailed sections, 78 unique HTTPS source entries, 4 full license paths and 7 authored notice files. It also parsed the credit BBCode and checked team-first content and exclusion of unconfirmed Aredius usage. Static checks verified every inventory path, count, duplicate-free row, local document link, formal license hash and identical project/Inter notice copies. The headless engine exited 0 with existing ObjectDB/resource-retention diagnostics at shutdown. Rendered UI and package results are recorded by the root verification pass.

The final menu passed 37 headless and 44 Forward Plus checks. Local score persistence and prompt checks passed 75 headless and 79 Forward Plus checks. Existing score, ending and Dev Mode checks passed. The package contains 2,241 entries, with all 11 legal files and localization verified against source. The excluded font/ambience imports are absent. Its normal entry started under the installed engine with `--main-pack`. The native desktop launcher timed out and exhausted the computer-use budget, so interactive executable acceptance remains open. See [testing](../TESTING.md) for limits and evidence.

The evaluation folder is `releases/2026-11-07/BagyongBahay-Notices-Evaluation-Windows-x64` beside the source checkout. Its executable is 1,188,317,296 bytes with SHA-256 `34ab415ccecf097817f6e5b7a981055d37b5bedd3d4bcd0653a100d50f051f65`. This local evaluation artifact retains the active media whose permission work remains open.

## Remaining permission and provenance work

1. The active Tindahan recording is the owner-confirmed BokerTV upload of DZRH's *Kasaysayan sa mga liham ni Tiya Dely*. Permission to redistribute it in a game remains undocumented. Its attribution stays visible. [Confirmed source](https://www.youtube.com/watch?v=IrpTpQobwUc)
2. The original creators of archive IDs 44505 Train Announcement and 79709 Distant Thunder remain unresolved. Both have game references. The generic archive label is retained with the known source information.
3. The generic Hammer, unidentified extracted photographs/product images and unresolved texture components retain open inventory entries. Owner confirmation of original environment modeling does not identify every embedded external image.
4. Identify any local derivative of the Aredius character before claiming use. If used, retain the required creator credit and review its custom game-only and raw-redistribution terms.
5. Review access to raw source bundles and repository assets separately from the compiled game. The custom terms for JashiPSX and psychopom and Adobe's Mixamo terms restrict standalone asset redistribution. Added credits and the project's free-play permission preserve those third-party restrictions.

The earlier [November 4 audit](2026-11-04-asset-credits.md) remains a dated record. The current follow-up and inventory supersede its unresolved source guesses where new evidence is recorded.

# Bagyong Bahay release readiness audit

**November 4, 2026, Asia/Manila** · `dev` working snapshot based on `a584d34` · Godot 4.6.1, Forward Plus

Bagyong Bahay is a single-player Windows game. The player prepares a house for a typhoon by exploring, talking to family and neighbors, shopping, and spending limited time and money. Settings and leaderboard entries are local to the machine. This audit assumes one player and one game process.

**Verdict. The Windows build is ready for local evaluation. Hold public distribution.** The exact executable in the ZIP reached the first waking dialogue on Windows and returned to title. Public release still needs third-party asset clearance, a physical-keyboard playthrough of the packaged game, and a decision on the reproduced leaderboard failures below.

## Windows demo

| Artifact | Result |
| --- | --- |
| Target | Windows x64, existing `Windows Desktop` release preset, embedded game data |
| ZIP | `BagyongBahay-Demo-Windows-x64.zip`, 836,031,521 bytes (797.3 MiB) |
| Executable | `BagyongBahay.exe`, 1,194,888,376 bytes |
| ZIP SHA-256 | `bb9e305bdf4f46b148c52155af978cfebe3132adc08f6d72ca48b697527b6f7f` |
| EXE SHA-256 | `939d89c0f4ff87d990e47f77aa4f9124f06266452bfb1d8f2114ab35435b668b` |
| ZIP check | All entries passed CRC. The embedded executable's SHA-256 equals the tested executable's hash. |
| Embedded pack | 2,225 entries, all 2,225 payload checksums match. Active localization CSV matches source byte for byte. The backup CSV and design previews are absent. |

The archive and checksum file are in the project’s sibling `releases/2026-11-03/` folder. Extract the archive and launch the executable. Godot does not need to be installed. The build contains an evaluation README. The export uses the existing unsigned preset.

## Verification

All gameplay tests used isolated Windows application data. The rendered checks ran on an NVIDIA GeForce RTX 4050 Laptop GPU.

| Check | Result |
| --- | --- |
| Editor import and Windows release export | Both exited 0 with clean final logs. |
| Rendered production smoke | **156 checks passed.** Intro, waking dialogue, untimed house and bodega, Nanay handoff, map/backpack, travel, purchases, medicine task, restart, storm ending, score submission and a second run. The harness drives game inputs and calls and forces the storm. |
| Rendered cursor ownership | Exit 0. Menu, overlapping UI owners, freed UI and player exit. |
| Rendered presentation matrix | **49 checks passed.** Six house-scene cases spanning graphics presets, VHS on/off, UI scales 100% and 175%, and 1280×720, 1280×800 and 1920×1080. The short samples were approximately 62–134 FPS on this machine. |
| Rendered ending checks | **69 checks passed.** Town montage, English and Tagalog results, continue controls and score-panel sequencing. |
| Exact packaged executable | Normal Windows launch, intro skip, title, Standard difficulty, first waking line with clock and objectives hidden, pause/resume, return to title, and Quit. Exit 0. Automated E/Space taps did not advance the opening line. The tool could not hold the keys. The cause is unconfirmed, so physical-keyboard acceptance remains open. |
| Public developer controls | Source guard requires both a debug build and an editor/internal feature. The public preset adds no internal feature. The standalone pause menu showed no Dev tab. The release template rejects command-line scene overrides, so the direct-command regression was not run inside the shipped EXE. |
| Pre-push text secret scan | No matches for private-key headers, common token formats or literal secret assignments in the text scanned. Binary and oversized files were outside the pattern scan. |

The 16 headless suites recorded **15,952 passing checks**:

| Suite | Checks | Failures | Exit |
| --- | ---: | ---: | ---: |
| `ambient_animal_regression` | 229 | 0 | 0 |
| `ate_linda_trade_regression` | 17 | 0 | 0 |
| `audio_regression` | 132 | 0 | 0 |
| `cleanup_regression` | 95 | 0 | 0 |
| `dev_camera_regression` | 1,011 | 0 | 0 |
| `dev_mode_regression` | 47 | 0 | 0 |
| `dialogue_portrait_regression` | 686 | 0 | 0 |
| `ending_balance_regression` | 17 | 0 | 0 |
| `house_teaser_regression` | 11,558 | 0 | 0 |
| `map_ui_regression` | 20 | 0 | 0 |
| `milestone2_regression` | 103 | 0 | 0 |
| `pharmacy_movement_regression` | 32 | 0 | 0 |
| `pickup_guidance_regression` | 54 | 0 | 0 |
| `score_calculation_regression` | 272 | 0 | 0 |
| `scratch_lotto_regression` | 41 | 0 | 0 |
| `static_npc_regression` | 1,638 | 0 | 0 |

The first camera and house-teaser runs each failed one assertion because the shared test tried to enter recording mode before closing the waking dialogue after restart. The fixture now checks that recording is denied during dialogue and advances the normal monologue before continuing. Both suites passed on rerun. The production camera guard was preserved.

Some passing runs emitted existing ObjectDB/resource shutdown diagnostics. The full rendered flow also logged the existing leftover ending-camera warning. The normal packaged startup/quit log had no script or resource-load error. A complete human playthrough, listening review, other hardware, long-run performance, and all possible endings remain unverified.

## Findings before public distribution

1. **Confirm rights and attribution for bundled media.** The Tindahan scene loads a recording named `DZRH radio drama_ Kasaysayan sa mga liham ni Tiya Dely.mp3`. The pack contains 16,819,927 bytes for that imported recording. No permission or provenance record for it was found in the repository, and the pack has no named third-party license/attribution file. Verify redistribution permission or replace the recording. Record the source, license and required credits for third-party audio, fonts and art before public distribution. The asset filename alone establishes neither permission nor infringement. [Tindahan scene](../../game/scenes/locations/tindahan.tscn)
2. **Malformed local scores can throw during load.** A valid JSON entry with an object in `remaining_minutes` produced a Godot script error at the integer conversion in `_sanitize_entry()`. Validate the value type before conversion and safely recover the remaining valid records. This was reproduced using isolated data. [Leaderboard manager](../../game/autoload/LeaderboardManager.gd#L85)
3. **A failed leaderboard write can look successful.** With a directory in place of the expected save file, recording a run updated the in-memory list but wrote nothing. The ending submit flow still marks the score as saved and dismisses the name prompt. Return a save result, preserve retry on failure, and write through a temporary file before replacing the previous scores file. [Leaderboard write](../../game/autoload/LeaderboardManager.gd#L108) · [Ending submit](../../game/scenes/ending/EndingSequence.gd#L373)
4. **Complete packaged input and distribution acceptance.** Play the Windows ZIP on an intended player machine with a physical keyboard through the waking dialogue, travel, storm and score submission. Confirm audible balance on that machine. Source tests passed dialogue advancement, but desktop taps in the exact EXE left the first line onscreen. Windows allowed launch on this audit machine. Other machines may apply different policy to unsigned builds.

The proposed action-narration styling, monologue colors and compact cash HUD remain pending separate plan approval. They are outside the current build.

## File and storage audit

The source inventory covered 2,535 files at the start of the audit, approximately 1.93 GiB excluding `.git` and `.godot`. It includes 935.0 MiB under `game/`, 638.5 MiB under `_raw_assets/`, 391.65 MiB under `design_previews/` and 10.93 MiB under `marketing/`. The generated editor cache is about 1.86 GiB and Git storage about 2.56 GiB on this checkout. Neither contributes directly to the ZIP. Many paths in `_raw_assets/` are runtime dependencies.

| Candidate | Stored in the current pack | Suggested next step |
| --- | ---: | --- |
| Marketing assets | 8,569,481 bytes | Trial an export exclusion and recheck title/credits. |
| Outside-birds WAV import | 6,514,828 bytes | Only importer references found. Trial excluding the source asset from the export and verify the pack. The source WAV itself is about 46.14 MiB. |
| Tests and sandbox resources | 4,055,731 bytes | Keep them in Git. Verify the registered legacy `room_1` path and dependencies before excluding the test tree from a public build. |
| Legacy map artwork | 2,732,513 bytes | No active map reference was found. Verify the remaining legacy routes before excluding. |
| **Subtotal for a first exclusion trial** | **21,872,553 bytes (20.86 MiB)** | Stored payload bytes. ZIP savings require a rebuild and measurement. |
| House teaser recording assets | 245,300,159 bytes (233.94 MiB) | Larger packaging opportunity. Separate the recording controller’s dependencies from a public release before exclusion. |
| Unreferenced rain/wind FLAC | 0 bytes | About 105.44 MiB in source. An archive/removal decision would reduce checkout storage only. |
| Design previews | 0 bytes | Already ignored by Godot. These are source-control storage, useful for design review. |

The source hash scan found 235.15 MiB of duplicate bytes in exact-match groups of files at least 1 MiB. Many belong to separate model import paths and textures. The figure overlaps other categories and cannot be added to the subtotal. The largest single packaged entry is the **119,023,601-byte rain room tone**, referenced by both the storm controller and the grocery scene. A shorter, tested loop is a more useful compression candidate than deleting it.

The reference audit used the project main scene, autoloads, location paths, resource IDs, imports and known dynamic path patterns. Unreached items are candidates because this scan cannot prove that all runtime or authoring references were found. No asset deletion or export filter change was made.

## Scope and evidence

The checkpoint includes the existing opening and waking monologue, audio and ending changes, the recording-camera test fixture adjustment, and this report. The downloadable archive lives outside Git. Publishing a public release and changing source assets or export filters require separate decisions.

Logs, source inventories, candidate CSV, per-entry package inventory and checksums are under `C:/Temp/bagyong-release-audit-20261103/`. See `tests/summary.md`, `full-forward-plus/engine.log`, `native-demo/runtime.log`, `review/save_type_probe.log`, `review/save_write_probe.log`, `storage/package_summary.json`, `storage/package_inventory.csv` and `zip-verification.json`. The scope is the current Windows x64 demo and its source checkout.

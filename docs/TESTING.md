# Testing and verification

## Current strategy and evidence

The initial documentation audit found no automated tests. Focused no-framework checks now live in `game/tests/cleanup_regression.tscn` and `game/tests/milestone1_smoke.tscn`; no third-party test framework or CI test workflow is configured. `game/tests/test_world/test_world.tscn`, `test_world_2.tscn` and their scene resources are exploratory 3D content, not GUT/GdUnit/custom automated tests. Do not report them as a passing suite.

Verification should distinguish five kinds of evidence:

| Kind | What it establishes |
| --- | --- |
| Static inspection | Paths, node wiring, code branches and configuration as written |
| Import/script validation | Godot can import/parse the checked content; not proof of successful gameplay |
| Scene-level checks | A specific scene instantiates and its relevant nodes/controls operate |
| Gameplay smoke test | Normal startup, preparation, travel and ending paths work together |
| Targeted regression | The changed behavior and nearby failure cases remain correct |

The documentation audit on 2026-09-16–17 used static inspection. The installed engine version was verified as `4.6.1.stable.official.14d19694e` and Git LFS as 3.7.1. No editor import, headless project execution, export or gameplay test was run because the task prohibited writes to import/cache/generated files. Runtime quality and successful export remain **Unknown / Needs verification**.

## Script and scene validation for future development

### Focused cleanup regression scene

After importing a disposable project copy with its LFS assets, run:

```powershell
# Use a separate user-data directory; this assignment is for this shell session.
$env:APPDATA = Join-Path $env:TEMP 'bagyong-regression-userdata'
Godot_v4.6.1-stable_win64_console.exe --headless --path 'C:\path\to\disposable-project-copy' --scene res://game/tests/cleanup_regression.tscn
```

The runner returns nonzero on failed assertions and prints its check count. It covers inventory rejection without mutation/signals, both combination recipes in both orders, successful signal ordering, full inventory/stack/discard handling, real hotbar input handlers, task requirement quantities/tool consumption, window state and side-quest readiness. These are targeted automated checks, not a full dialogue/interaction playthrough.

The null-result combination test deliberately exercises the existing `push_error` diagnostic; rejected invalid requests also warn. Inspect the assertion summary and unexpected script errors, not just whether the log contains the word ERROR. Run as a scene so Godot initializes the configured autoloads before loading the test's dependent Resource classes.

### Milestone 1 scripted integration

Run in a disposable copy after importing its actual LFS assets. The runner changes session state and writes a test score, so it requires an explicit isolated user-data path:

```powershell
$testProject = 'C:\path\to\disposable-project-copy'
$env:APPDATA = Join-Path $env:TEMP 'bagyong-milestone1-userdata'
$env:LOCALAPPDATA = Join-Path $env:TEMP 'bagyong-milestone1-localdata'
$env:BAGYONG_ISOLATED_SMOKE = $env:APPDATA.Replace('\', '/') + '/Godot/app_userdata/Software Festival 2026'
Godot_v4.6.1-stable_win64_console.exe --headless --path $testProject --scene res://game/tests/milestone1_smoke.tscn
```

Omit `--headless` to run with rendering. The graphical run saves `milestone1_home.png`, `milestone1_tindahan.png`, `milestone1_shop.png` and `milestone1_ending.png` in the isolated user-data directory. The test uses normal engine timing, skips the intro through its input handler, dismisses the actual tutorial, advances dialogue, buys medicine from Ate Linda and an item from hardware, completes the medicine task, restarts, forces storm arrival, submits an isolated score and starts another run. It also reproduces detached-checklist and immediately-freed-label callbacks. Expect several minutes for the normal ending sequence.

Inspect logs as well as exit status and assertions: a Godot runtime error does not necessarily set a failing process exit code. No `SCRIPT ERROR`, failed assertion, deferred-localization error or detached-checklist error is acceptable. Known shutdown leak diagnostics are recorded separately. This test calls production interaction methods directly; it is not a manual movement/proximity/audio test, a natural full-day wait or coverage of every optional quest and ending.

### General import validation

During ordinary development, open the project in Godot 4.6.1, wait for imports, inspect parser/import errors and run affected scenes. For a command-line import pass, the following is a **suggested future command, not a test run by this audit**:

```powershell
godot --headless --editor --path "C:\path\to\disposable-project-copy" --import
```

Replace `godot` with the installed executable path if it is not on PATH. Prefer a disposable copy containing actual LFS assets when protecting the working checkout. This command may generate `.godot/` and import metadata; do not run it in a checkout during a documentation-only task that forbids those writes. Review all errors and exit status. Import success alone does not instantiate every gameplay path or exercise signal callbacks.

F5 follows the configured intro startup and is the baseline smoke test. F6 runs the selected scene and can bypass fresh-run setup; record that distinction. `SceneManager.SCENE_PATHS` includes older/debug entries, so verify the selected path exists before treating a failure as a new regression. Do not silently change project settings or caches merely to make a documentation check pass.

## Gameplay smoke test

Use a fresh run from the menu and note difficulty, language, quality, UI scale and existing user settings. Keep a copy of valuable local leaderboard/settings data before tests that intentionally alter it; use an isolated user-data environment if available in the chosen workflow.

- [ ] Start through the intro. Confirm studio/credit/warning/dedication cards precede the skippable narrative; accept/cancel/mouse can skip once enabled. Reach menu and open/close credits, tutorial, settings and leaderboards.
- [ ] Choose a difficulty, reach the home scene, complete the stand-up/tutorial handoff and regain movement. Test tutorial Continue and session-only Do not show again.
- [ ] Move with WASD and Shift sprint. Check facing/animation, small-step traversal, camera-volume transitions, nearby interaction selection and prompt visibility. PlayerV2 has no jump handler; do not infer jump/crouch/flashlight behavior from Input Map entries. Test Space as dialogue advancement.
- [ ] Talk to Nanay and Lola, advance/skip dialogue, discover preparation needs and inspect the objective HUD. Verify input returns after dialogue and task sequences.
- [ ] Open backpack with Tab and map with M. Each closes the other and releases the mouse. **The clock continues while these menus are open.** Escape pause closes gameplay menus, pauses the tree, and Resume restores input/time progression.
- [ ] Buy/pick up items, inspect quantities and cash, combine an eligible pair and complete at least one home task. Verify the completed need, remaining inventory and visible props agree.
- [ ] Travel among reachable map destinations and return home. Confirm displayed quoted cost is used, timer advances, appropriate spawn is selected and collected/completed scene state survives revisits.
- [ ] Observe storm danger/closure progression and a refused inaccessible destination. Check map presentation, rain/audio intensity and eventual storm arrival.
- [ ] Use End Day on one run and natural timeout on another. Confirm ending beats reflect need completion; save a named score and return to menu.
- [ ] Restart from pause and start another run after an ending. Check cash, needs, inventory, shop stock, storm restrictions, opening/tutorial behavior and selected difficulty against the relevant reset code.

## System regression checks

Choose checks relevant to the change. These are procedures to execute, not claims that they have passed.

| System | Cases to exercise |
| --- | --- |
| Player/camera/interaction | Walk/sprint, obstacles/steps, overlapping interactable areas, leaving range, locks during dialogue/tasks, Space dialogue advancement, camera volume enter/exit and return travel |
| Timer/difficulty | Each difficulty's pacing and departure cash; action/travel time deductions; thresholds crossed by a large time jump; pause vs unpaused map/backpack; storm arrival during another operation |
| Dialogue/quests | First/repeat conversations, partial progress, successful/failed requirements, one-time rewards, objective notices and return visits |
| Needs/tasks | Undiscovered/discovered/resolved states; missing ingredients; multi-step window progress; task completion once; visual cues restored on revisit; ending state matches needs |
| Inventory/combinations | Empty/full inventory, stack quantities, adding to existing stack, valid/invalid pair, result slot pressure, selection after consumption, discard/restore with full inventory and critical-item warning |
| Shops/trade/economy | Exact/insufficient cash, finite/unlimited/out-of-stock item, full inventory, repeat purchase, barter requirements, completion/revisit, stock/reset state after restart |
| Travel/world state | Current/closed/inaccessible destination, danger penalties, quoted cost, repeated travel input, room transitions/spawn IDs, unique pickups and task props after leaving/returning |
| UI/input ownership | Map/backpack mutual exclusion, pause while each is open, tutorial from menu/pause/gameplay, mouse recapture, focus release, repeated close/open and transitions while a modal is active |
| Localization | English↔Tagalog changes in menu and gameplay, dynamic dialogue/item/shop/objective text, `%` placeholders and BBCode, long text/clipping; do not assume automatic node traversal catches later text assignments |
| Visuals | High/Balanced/Performance, VHS on/off, UI scale extremes, different window/aspect sizes, scene change after settings adjustment, camera DOF and light/shadow changes |
| Audio | Music/ambience transitions, overlapping SFX, dialogue voice ending/skipping, storm progression and grocery layer, pause/resume, volume persistence and Reset |
| Ending/leaderboard | Six need-dependent shots; result tiers at 0–1, 2–3, 4–5 and 6 needs; empty/whitespace/name-limit input; early-finish time snapshot; difficulty multiplier; score ties; reload and two-step clear |
| Persistence/export | Quit/relaunch settings and leaderboard; absent/malformed files in isolated test data; exported build includes CSV/assets and can complete the normal application flow |

### Existing edge cases worth preserving in reports

- `InventoryManager.MAX_INVENTORY_SIZE` is **7**. Slot construction, selection and wheel wrap use this capacity. Key 8 explicitly aliases the last slot. Exercise both wrapping directions and the alias before changing controls.
- `TutorialModal` suppression is a static session flag; it is not written to settings. Verify it separately from disk persistence.
- `AudioSettingsPanel` Reset resets audio and visual settings, not language. UI scale is 100–175%, default 140%; quality defaults High and VHS defaults enabled.
- `AudioManager.play_sfx` creates temporary players, whereas `stop_sfx` and `stop_all` stop the fixed SFX player. Do not assume these helpers silence every active one-shot.
- Leaderboard recording trims to 25 entries; loading does not enforce that cap. `clear_entries` clears all modes even though its signature accepts an unused difficulty argument. Test local-data changes deliberately.
- Intro narrative assigns strings dynamically without explicit translation calls. Full localization coverage has not been established.

See [ARCHITECTURE.md](ARCHITECTURE.md) and [ROADMAP.md](ROADMAP.md) for broader implementation boundaries and follow-up candidates. Static concerns are not automatically reproduced runtime bugs or authorization for unrelated fixes.

## Bug-fix evidence

Record each fix using:

```text
Expected:
Actual:
Reproduction: scene/entry path, difficulty, state, inputs
Root cause: affected code/resource and why it fails
Fix: smallest relevant behavioral change
Verification: exact checks run, results, and checks not run
```

Reproduce the defect before editing when feasible, exercise the fixed path and nearby failure cases, and add a targeted regression test when an appropriate harness exists or is justified by the task. Never report a bug as verified fixed unless the relevant verification was actually performed.

## Final review

Inspect `git diff --check`, the changed-file list and the diff for unintended scene/resource/configuration edits. Report parser/import checks separately from manual tests. For a documentation-only task, validate referenced paths, symbols, configured autoloads and links without launching the project. A clean diff or executable version check is not a passing gameplay test.

### Documentation audit result — 2026-09-17

All eight requested guides were reviewed against implementation and each other. An independent review caught and corrected an erroneous PlayerV2 jump test and the AudioManager scene-folder description. Other corrected historical assumptions include Act1 startup/timer behavior, HUD registration, inventory capacity and plans presented as completed systems.

The local-link check examined 46 links with no missing targets; the controls anchors were also checked. A scan of 87 code-formatted repository paths found only the two explicitly documented missing scene paths (each mentioned in architecture and roadmap). `git diff --check` passed. The changed-file inventory contained nine Markdown files only: the eight requested guides plus a historical-status notice added to `PROJECT_HANDOFF.md`. No gameplay, scene, resource, asset, shader, addon or project-setting edits were made. No runtime verification is implied by these checks.

### Conservative cleanup validation — 2026-09-17

The documentation was checkpointed locally as `ab25f2a` on `dev` before implementation. No push was performed. Validation used Godot `4.6.1.stable.official.14d19694e` in a disposable copy with isolated runtime user data.

- A fresh-cache import exited 1 during resource import before any production edits. The log included initial UID/font-cache errors and ended during import without a clear final cause; clean-checkout import remains unresolved.
- Seeding the disposable copy with the existing `.godot` cache allowed the baseline editor/import pass to exit 0 without script/parse errors. This does not establish fresh-import success.
- Baseline headless samples loaded intro, menu, home, hardware, pharmacy, grocery and ending. Tindahan emitted missing-greybox and vanished-node recovery errors. Forced exits reported leaked objects/resources before changes.
- The focused regression scene passed **92 assertions with zero failures**. The deliberate null-result diagnostic and existing shutdown resource warnings are separate from assertion failures.
- Independent review found no actionable defects in the changed production scripts and focused tests. Existing gameplay scenes, resources, assets, project settings, Input Map and save formats were not edited.
- A disposable, script-driven integration smoke passed intro skip → menu → home, map/backpack clock continuity, hardware travel and return spawn, pause, restart into a second home instance with a fresh clock, and forced storm → ending. It used accelerated time and suppressed the startup tutorial through its existing session API; it does not verify normal timing or tutorial interaction.
- The same smoke passed at checkpoint `ab25f2a` and with the cleanup. Both emitted `PreparationChecklistHUD._schedule_checklist_resize` line 249's null `get_tree()` error during restart, plus shutdown resource warnings. These are pre-existing lifecycle findings, deliberately outside this pass.

No manual visual/audio playthrough, complete dialogue/task interaction sequence, Nestor reward turn-in or exported-build test was performed. The focused window and quest tests establish state-helper behavior only. Existing missing-resource and lifecycle issues are not claimed fixed by this cleanup.

Final recheck on 2026-09-23 synchronized all changed scripts and the regression scene into the disposable copy. Godot 4.6.1 editor/import exited 0 with no script/parse errors, but was not clean: editor cache/settings access, certificate-store, empty-mesh and a gravel normal-texture load error were logged. These asset/environment diagnostics were not repaired or conclusively classified by this script cleanup. The regression scene then exited 0 with **92 checks, 0 failures**, with expected invalid-input diagnostics and shutdown resource warnings. `git diff --check` passed. Implementation remains uncommitted; the rollback point is still `ab25f2a`.

### Milestone 1 implementation and verification — 2026-09-24

Before edits, the prior cleanup and all pending documentation/tests were committed locally on `dev` as `200990fdffa8075ab7073da37639cb21c960cda0`. Nothing was pushed. This supersedes the preceding paragraph's working-tree status; the new Milestone 1 changes remain uncommitted.

- Fixed the reported checklist `get_tree()` error by checking tree membership before access and after the frame wait. Also fixed the reproduced deferred-localization error when temporary controls are freed before their queued callback; a weak reference now resolves to null safely.
- Cleared the screenshot's script warnings through local renames, an explicit enum cast and narrow annotations for intentional integer division, inherited signals, retained public parameters and the required asynchronous completion hook. The Godot language server checked all 89 scripts under `game/` with zero diagnostics after fixes.
- Removed Tindahan's missing hidden prototype reference while preserving its visible GLB and imported collisions. Retired the old `test_room2` mapping and Act1 door following the user's explicit choice. Static checking of `game/` scene/resource dependency paths found zero missing files.
- Imported a newly copied project without seeding `.godot` from the workspace. Initial import completed asset processing but emitted bootstrap UID/font/autoload diagnostics and raw-asset importer diagnostics (empty meshes and the absent gravel normal JPG). A subsequent editor/import exited 0 with no errors or warnings, using only the cache generated in that fresh copy. This establishes a reproducible imported baseline, not an error-free first import or a repair of those raw source assets.
- Focused cleanup regression: **92 checks, 0 failures**, exit 0. Intentional invalid-input diagnostics remain expected.
- Normal-timing Milestone 1 smoke: **54 checks, 0 failures** in headless and Forward Plus graphical runs. Runtime logs are checked independently of assertions. The only remaining termination diagnostics are ObjectDB/resource-leak warnings already observed before this pass.
- Rendered captures were inspected for the home HUD/seven-slot bar, Tindahan environment, shop and ending name prompt. Desktop interaction could not be performed because the computer-use service rejected the game window's ownership identity; rendered captures and scripted calls are not claimed as manual playtesting.
- Independent Caveman-style review found no introduced production defects. Its requested freed-node regression is included in the smoke. Final whitespace/diff checks passed.

Remaining verification: full manual movement and camera/proximity coverage, audio quality, all household tasks/optional quests, natural storm timing during overlapping operations, other ending outcomes, quality/resolution matrix and exported builds. Asset re-authoring, broad lifecycle redesign, reset consolidation and gameplay changes remain outside this pass.

### Milestone 2 implementation and verification — 2026-09-25

Approved scope: deadline/transition ownership, pause cleanup, full-inventory quest turn-in, repeated interactions, stock resets/return visits and a bounded dynamic/long-text localization audit. Pending work was copied before editing to `C:\Users\john2\AppData\Local\Temp\bagyong-m2-backup-20260925-001110`, including a binary Git patch. No commit or push was made.

Run `game/tests/milestone2_regression.tscn` in an imported disposable copy with the same isolated `APPDATA` / `BAGYONG_ISOLATED_SMOKE` setup described above. This test changes language/UI settings and session state. Its optional Godot user argument `--unit-only` runs the focused inventory/shop/localization/pause checks; `--visual-only` runs the rendered UI scenarios. Example:

```powershell
$testProject = 'C:\path\to\disposable-project-copy'
$env:APPDATA = Join-Path $env:TEMP 'bagyong-m2-userdata'
$env:LOCALAPPDATA = Join-Path $env:TEMP 'bagyong-m2-localdata'
$env:BAGYONG_ISOLATED_SMOKE = $env:APPDATA.Replace('\', '/') + '/Godot/app_userdata/Software Festival 2026'
Godot_v4.6.1-stable_win64_console.exe --headless --path $testProject --scene res://game/tests/milestone2_regression.tscn
# Rendered audit; saves milestone2_*.png under isolated user://.
Godot_v4.6.1-stable_win64_console.exe --path $testProject --scene res://game/tests/milestone2_regression.tscn --resolution 1280x720 -- --visual-only
```

Evidence from Godot `4.6.1.stable.official.14d19694e`:

- Before production fixes, the initial regression reproduced **5 failed assertions** across stale dynamic localization, repeated shop opens and the full-backpack Nestor exchange.
- Final Milestone 2 run: **97 checks, 0 failures**, exit 0. Includes travel/danger charges crossing the deadline, storm during departure/arrival fades, reset during travel/storm, medicine/window completion at the deadline, canceled task supplies, smoke-break deadline, forced storm during NPC dialogue/shop/map/backpack/pause/tutorial, and successful stock/task return visits. Owner cleanup, duplicate rewards, formatted language changes and stale stock callbacks are also checked.
- Final cleanup regression: **92 checks, 0 failures**, exit 0; expected invalid-input warnings and intentional null-combination error remain.
- After the final timer-parameter rename to avoid shadowing `Node.owner`, the focused `--unit-only` recheck passed **26 checks, 0 failures**, exit 0. Its log is `bagyong-m2-unit-final.txt`; existing shutdown resource warnings remain.
- Final normal-timing Milestone 1 integration: **54 checks, 0 failures**, exit 0, including tutorial, dialogue, purchases, task completion, pause restart, ending, score submission and second run.
- Final Forward Plus visual run on the RTX 4050: **8 scene/layout checks, 0 failures**, exit 0. Generated 16 map/shop/quest/backpack captures across English/Tagalog and 100%/175% UI scale. Representative captures were inspected: quest prompts translate, action labels remain English as authored, and long backpack/hotbar names wrap. The 1280×720 window renders the configured 1920×1080 canvas; this is not a resolution matrix.
- CSV placeholder audit: **412 rows, 0 mismatches** between source, English and Tagalog format placeholders.
- Editor/import in the existing disposable copy completed without logged errors/warnings. This reused its imported asset cache; no fresh-import claim is made for this milestone.
- Final M2/M1/visual runtime logs contain no script errors, freed-capture errors or failed assertions. Existing ObjectDB shutdown-leak warnings remain; cleanup also reports retained resources at shutdown. Earlier intermediate runs exposed and corrected a freed objective-row callback and test/type issues; they are not counted as passing verification.
- Independent Caveman/Ponytail review identified the repeat-Interact-over-choice pause overlap, which was fixed and regression-tested. Its final review found no further concrete defects. Final diff/whitespace review passed.

Logs are retained under `%TEMP%`: `bagyong-m2-before.txt`, `bagyong-m2-final.txt`, `bagyong-m2-cleanup.txt`, `bagyong-m2-m1.txt`, `bagyong-m2-visual-final.txt`, and `bagyong-m2-import.txt`. Always inspect errors alongside counts: a GDScript error can abort one coroutine without making Godot exit nonzero.

Limits: tests call production APIs directly and force deadline fixtures; they do not establish manual movement/proximity/audio quality, every optional quest/ending, a full natural-day playthrough or export readiness. The localization audit fixes five choice prompts and dynamic assignment; intro narration remains incompletely translated. Existing authored button translations are preserved without adding a blanket Button exemption. No broad reset consolidation, engine upgrade or asset rewrite was performed.

### Milestone 3 distribution and presentation — 2026-09-26 (partial)

The validation pass uses Godot `4.6.1.stable.official.14d19694e` and matching `4.6.1.stable` Windows x86_64 release templates. Existing uncommitted work was retained. A disposable copy and pre-change binary patch are at `C:\Users\john2\AppData\Local\Temp\bagyong-m3-20260926`. Its import cache was copied from the earlier disposable project and refreshed; this is not a fresh-import test. User settings and scores were isolated through `APPDATA`/`LOCALAPPDATA`.

**Distribution findings and changes:**

- The original exported package omitted the raw `game/localization/game_text.csv`. A data-pack launch through the installed engine, from outside the source tree, reproduced `LocalizationManager: missing text table`. Running from the source directory masked the omission, so tests must run outside it.
- An exact export include filter alone did not fix the omission. The table's CSV translation importer still substituted generated resources. Godot-generated import configuration now selects `keep`, and the final export manifest explicitly contains the raw CSV. No production localization logic or translation contents changed in this milestone. No consumers of the generated translation resources were found. See the [Godot import documentation](https://docs.godotengine.org/en/4.6/tutorials/assets_pipeline/import_process.html) for Keep File behavior.
- Headless export returned 0 while emitting VoxelGI image serialization errors (`Expected Image data size ... got 0 bytes instead`). Export with rendering enabled returned 0 without logged errors/warnings. Use the graphical export command in [DEVELOPMENT.md](DEVELOPMENT.md).
- Candidate: `C:\Users\john2\AppData\Local\Temp\bagyong-m3-20260926\build\BagyongBahay.exe`, 797,825,592 bytes, embedded PCK. SHA-256: `58CA5D918D0AC495DC133AC3D8C89B884F8B33FBBF7EAE32C629008A60D96A1D`.
- Read-only binary inspection found the complete 65,491-byte source CSV payload inside the embedded PCK at offset 788,044,304. Its SHA-256 matches the source: `a178327e4b16711a67ff316fe8550c7930e45182f122883c458466f9bb80f9f8`. This verifies packaged bytes without executing the blocked application.
- **Standalone acceptance is blocked:** Windows rejected the initial EXE launch with `An Application Control policy has blocked this file.` Security policy was not changed or bypassed. The final candidate has not been launched. The earlier data-pack diagnostic is not standalone release-template execution or a completed packaged gameplay smoke.
- `git lfs fsck` passed; all 369 LFS entries were hydrated. This establishes local asset availability, not exhaustive exported asset rendering.

**Runtime evidence from the disposable source project:**

- Existing Milestone 1 normal-timing smoke: **54 checks, 0 failures**, exit 0. Covers intro/menu, tutorial, dialogue, travel, purchases, task completion, restart, ending, score submission and a second run.
- New `game/tests/milestone3_validation.tscn`: **49 checks, 0 failures**, exit 0. Covers raw CSV presence, exact Tagalog translation, a nonempty audio stream starting on the SFX bus, six presentation cases, actual light/environment/camera quality effects, VHS visibility, UI scale, actual render dimensions and screenshot output. Audio playback state is not a listening test.
- Six home-scene screenshots were inspected. HUD/clock/controls/seven-slot hotbar remain within the frame at the tested scales. At 100% scale and low resolution, VHS makes the small objective/control text harder to read. These are English home HUD captures, not full menu/shop/dialogue or accessibility acceptance.
- After changing the CSV import mode, Milestone 2 `--unit-only`: **26 checks, 0 failures**, exit 0, including English/Tagalog dynamic text. The new runner's isolation guard was exercised with a mismatched path: exit 1 as expected, with no report written.
- Final runtime logs have no script errors or failed assertions. Known ObjectDB/resource warnings remain at shutdown (8 retained resources in M1/unit; 10 in the graphical runner). Intermediate matrix runs failed an overly strict window-mode assertion; only the final verified run supplies results below.
- The runner requests windowed mode, but this machine reports mode 4 (exclusive fullscreen). Window and screenshot dimensions match each requested size. This is a render-resolution matrix, not verified windowed-mode behavior.

**Measured baseline:** Intel Core i7-13620H, NVIDIA GeForce RTX 4050 Laptop GPU, 16,870,064,128 bytes RAM, NVIDIA driver `32.0.16.1692`, Windows, Vulkan Forward Plus. VSync mode 1 remained enabled. Each fixed home view used a two-second warmup followed by approximately three seconds of monotonic wall-clock frame samples. The clock stayed paused and no other Godot test ran concurrently. FPS is sampled frame count divided by elapsed time; p95 is the 95th percentile of process-frame intervals, not GPU execution time.

| Quality | VHS | UI scale | Render size | Frames | Average FPS | p95 frame ms |
| --- | --- | --- | --- | --- | --- | --- |
| High | On | 100% | 1280×720 | 333 | 110.93 | 9.94 |
| High | Off | 175% | 1920×1080 | 231 | 77.00 | 13.65 |
| Balanced | On | 175% | 1280×800 | 374 | 124.46 | 8.66 |
| Balanced | Off | 100% | 1920×1080 | 259 | 86.22 | 12.27 |
| Performance | On | 100% | 1280×800 | 402 | 133.91 | 8.06 |
| Performance | Off | 175% | 1280×720 | 431 | 143.62 | 7.42 |

This is a short, single-machine source-runtime sample. Different cases vary multiple settings, so they do not isolate the cost of each setting. Power mode, thermals and background desktop load were not controlled. No minimum/recommended hardware claim, outdoor/storm benchmark, sustained-performance claim or release-build performance claim follows from these numbers.

Reproduce the graphical runner in an imported disposable copy:

```powershell
$testProject = 'C:\path\to\disposable-project-copy'
$env:APPDATA = Join-Path $env:TEMP 'bagyong-m3-userdata'
$env:LOCALAPPDATA = Join-Path $env:TEMP 'bagyong-m3-localdata'
$env:BAGYONG_ISOLATED_SMOKE = $env:APPDATA.Replace('\', '/') + '/Godot/app_userdata/Software Festival 2026'
Godot_v4.6.1-stable_win64_console.exe --path $testProject --scene res://game/tests/milestone3_validation.tscn --windowed
```

Evidence under the disposable root: `export-final.log`, `import-csv.log`, `m1-source.log`, `unit-final.log`, `guard.log`, and `m3-visual-verified.log`. Screenshots and `milestone3_report.json` are in `visual-userdata-verified/Godot/app_userdata/Software Festival 2026/`. The initial failed export log and intermediate matrix logs are retained for diagnosis.

Remaining Milestone 3 acceptance: run the final standalone candidate on an authorized Windows machine; verify packaged localization/audio/assets and the normal gameplay flow, listen to audio, cover broader UI/resolution combinations, and measure representative travel/storm scenes before publishing hardware requirements. Milestone 3 remains in progress.

### Standalone Windows retry — 2026-09-27 (blocked)

The final candidate above was retried from outside the source tree with isolated `APPDATA`/`LOCALAPPDATA`. Its SHA-256 still matches `58CA5D918D0AC495DC133AC3D8C89B884F8B33FBBF7EAE32C629008A60D96A1D`. Windows rejected process creation with `An Application Control policy has blocked this file.` No game runtime log was produced.

Windows Code Integrity events 3033 and 3077 identify this exact executable as failing signing-level/policy requirements; event 3118 records a Smart App Control block at 11:14:57 local time. Evidence is saved under `C:\Users\john2\AppData\Local\Temp\bagyong-m3-20260927` in `standalone-launch-error.txt` and `code-integrity-events.json`. Security policy and the executable were not modified.

Packaged gameplay, localization, audible audio, and packaged storm/travel performance remain **unverified**, not failed gameplay tests. Existing source-runtime measurements do not close this gate. Continue on a Windows machine whose security policy permits the candidate, or through an approved signing/distribution process. Reuse the isolated Milestone 1 gameplay smoke and Milestone 2 localization checks; separately inspect/listen to the normal packaged UI/audio and measure real travel transitions plus outdoor heavy-storm frame times. Report transition latency separately from steady-state FPS/p95, and retain the single-machine hardware-claim limit. Milestone 3 remains incomplete.

### Source-runtime storm/travel profiling — 2026-09-27

A profiling runner in the existing disposable project at `C:\Users\john2\AppData\Local\Temp\bagyong-m3-20260926\project\game\tests\storm_travel_performance.gd` measured high quality, VHS on, 1280×720, Forward Plus on the same i7-13620H/RTX 4050 Laptop GPU. It used a two-second warmup and three-second fixed-camera sample per scene, paused the game clock, and used production `SceneManager.travel_to()` for travel. Grocery was sampled at minute 315; storm home at 600; hardware at 615. Two passes exited 0 with seven recorded cases each and no script errors. Logs and JSON reports are under `C:\Users\john2\AppData\Local\Temp\bagyong-performance-20260927`.

| Fixed scene | Pass 1 FPS / p95 ms | Pass 2 FPS / p95 ms |
| --- | ---: | ---: |
| Home, minute 0 | 120.35 / 8.75 | 118.76 / 8.93 |
| Grocery, minute 315 | 125.37 / 9.00 | 119.17 / 9.41 |
| Home, minute 600 | 127.04 / 8.36 | 126.50 / 8.53 |
| Hardware, minute 615 | 133.91 / 7.97 | 121.46 / 9.04 |

Travel completed in 1.35–1.79 seconds. Worst frames were 165–665 ms across the two passes. The second pass recorded every frame over 100 ms at overlay alpha 1.0, during the black transition. `SceneManager._change_scene()` calls `change_scene_to_file()` during that fade, consistent with scene loading as the source of the stalls. The fixed views show no measured steady-frame problem on this GPU. Prioritize scene-loading work only if black-screen travel latency is unacceptable in manual testing; do not change lighting, rain, VoxelGI or player loops based on these samples.

This runner reused an imported disposable copy and did not execute the blocked standalone EXE. It did not move the camera/player, control thermals or background load, record GPU execution time, cover every location, or test weaker hardware. These results do not establish minimum requirements or complete Milestone 3.

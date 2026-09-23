# Testing and verification

## Current strategy and evidence

The initial documentation audit found no automated tests. A focused no-framework regression scene has since been added at `game/tests/cleanup_regression.tscn`; no third-party test framework or CI test workflow is configured. `game/tests/test_world/test_world.tscn`, `test_world_2.tscn` and their scene resources are exploratory 3D content, not GUT/GdUnit/custom automated tests. Do not report them as a passing suite.

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

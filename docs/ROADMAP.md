# Roadmap and unresolved work

Audited 2026-09-16–17. This file describes future work, not implemented architecture. No new feature work is authorized by this document. See [GAME_DESIGN.md](GAME_DESIGN.md) for historical task provenance and [ARCHITECTURE.md](ARCHITECTURE.md) for current behavior.

## Current stage and priority

Current apparent stage: playable festival/beta preparation loop. Milestones 1 and 2 are implemented with targeted Godot 4.6.1 validation; broader manual playtesting remains necessary. Milestone 3 distribution/presentation validation is in progress; Windows Application Control blocks standalone launch on the test machine. Release date remains **Unknown / Needs verification**.

The milestones below are **audit-proposed stabilization work**, not recovered commitments. Their ordering is a recommendation based on verified source risks; it does not establish a scheduled release plan.

## Milestone 1 — Establish a reproducible playable baseline (implemented 2026-09-24)

Goal: verify the current preparation loop from a fresh checkout and resolve confirmed blockers. The user authorized this implementation and explicitly chose to retire the old `test_room2` door/route.

### Required

- [x] Remove the broken hidden greybox reference in `tindahan.tscn`; retain the actual GLB/collisions and verify travel, spawn floor support and Ate Linda's shop from a freshly imported copy.
- [x] Retire `test_room2` and the old `Act1.tscn` door, as explicitly selected by the user.
- [x] Exercise startup, dialogue, shopping, task completion, travel, ending and second-run reset with the normal-timing scripted smoke; record results and manual verification limits in [TESTING.md](TESTING.md).
- [x] Retain Godot 4.6.1 / Forward Plus as the target for this baseline. No 4.7 migration was performed.

### Optional

- [ ] Add a narrowly scoped resource-reference check if it proves useful; distinguish missing paths from UID recovery and stale comments.

### Completion criteria

The normal route is demonstrated in the target engine, each failing path has a recorded resolution, and results distinguish static checks from runtime playtests. Scripted checks and rendered captures establish the baseline, not full manual acceptance: movement/camera edge cases, audio, every quest/ending and exports still need their own checks. Initial raw-asset import diagnostics and shutdown leak warnings are documented rather than claimed fixed.

## Milestone 2 — Resolve interaction and state edge cases (implemented 2026-09-25)

Goal: test and address concrete consistency risks without broad refactoring.

### Required

- [x] Align seven-slot hotbar selection with inventory capacity; preserve key 8 as the last-slot alias.
- [x] Exercise storm arrival during travel/task/dialogue/modal activity; enforce storm priority, cancel superseded transitions and release scene-owned timer pauses safely.
- [x] Exercise full-inventory quest turn-in, repeated interactions, stock resets and return visits. Correct Nestor's capacity check, duplicate choice/dialogue interaction and stale shop purchases.
- [x] Audit dynamic localization and long text in both languages, including intended button-language scope. Correct stale text restoration, five quest prompts and overflowing slot names; retain authored English action labels.

### Optional

- [x] Add a focused no-framework regression scene for inventory, hotbar, task requirements, window state and quest readiness.

### Completion criteria

Each reported bug has a reproduction and relevant verification, and intentional behavior such as an unpaused map/backpack is preserved or explicitly changed.

Milestone 2 evidence: 97 focused checks passed, including deadline travel/task/modal cases, reset cancellation, quest exchange and stock revisits. English/Tagalog captures at 100%/175% UI scale were inspected, with 8 scene/layout assertions passed. See [TESTING.md](TESTING.md) for exact evidence and limits. This is a bounded audit, not exhaustive localization, manual acceptance or export validation.

## Milestone 3 — Validate distribution and presentation (in progress 2026-09-26)

Goal: establish evidence for a downloadable Windows build and readable presentation.

### Required

- [ ] Export with matching templates and a deliberate output path; test the packaged CSV, LFS assets, audio and main flow.
- [ ] Test quality presets, VHS toggle, UI scale and representative resolutions.
- [ ] Measure hardware performance before publishing minimum/recommended requirements.

### Optional

- [ ] Revisit additional accessibility controls after agreeing on product scope.

### Completion criteria

An actual exported build has recorded smoke-test results and any hardware claims include measurements. A Windows candidate is exported and the missing raw localization CSV is explicitly included. Standalone execution remains blocked by Windows Application Control; source-run tests do not fulfill exported-build acceptance. See [TESTING.md](TESTING.md) for the bounded presentation matrix, measurements and remaining checks. No minimum/recommended hardware specification is established by a single-machine sample.

## Backlog by proposed priority

| Priority | Candidate work | Basis |
| --- | --- | --- |
| High | Complete manual playthrough and investigate remaining raw-asset import diagnostics | The two planned scene-reference defects are resolved; scripted checks/captures do not establish all player interactions |
| High | Broader manual playthrough after deadline/pause fixes | Targeted Milestone 2 cases pass; arbitrary overlapping inputs still need manual playtesting |
| Medium | Complete localization coverage and presentation matrix | Five choice prompts and dynamic assignment are fixed; intro narration and broader UI/accessibility remain outside the bounded audit |
| Medium | Remaining mutable inventory ownership and duplicate storm-state review | Add/combine validation is implemented; live arrays and duplicate storm state remain |
| Low / nice to have | Extend targeted checks as needed and establish a measured performance baseline | Focused regression scene exists; hardware benchmarks do not |

## Known defects and verification boundaries

**Static defects confirmed in source:**

- Resolved in Milestone 1: the missing hidden Tindahan greybox reference was removed; the visible model was retained.
- Retired in Milestone 1 by user decision: `test_room2` and its old Act1 door.
- Resolved in the conservative cleanup: wheel wrapping now uses seven slots and key 8 explicitly aliases the last slot.
- Corrected the touched hotbar, timer and HUD comments to describe current capacity, pause/startup behavior and scene ownership. Other legacy comments still require source verification.

**Runtime fixes in Milestone 1:** checklist resize now checks tree membership before `get_tree()` and after waiting a frame. Deferred localization now uses a weak reference to skip controls freed before the callback. Normal-timing smoke tests cover the lifecycle cases and logs are inspected separately from assertion results. See [TESTING.md](TESTING.md) for results and limits.

**Milestone 2 fixes:** deadline transitions now have priority/cancellation checks; the timer centrally releases Node-owned pauses on scene exit/reset; Nestor accepts a full-backpack exchange; duplicate shop opens and stale stock callbacks are guarded; dynamic localization no longer restores obsolete text. The travel regression also covers a freed animated objective-row callback. Multiple overlapping targets can still retain a stale nearest selection; that separate source risk was not reproduced or changed here.

The old danger-zone reset complaint is historical; current menu/restart code resets both scene and storm managers. Keep a second-run regression check rather than treating that old report as proof the bug is still present.

## Deferred ideas — not committed features

**Plan next game features** proposed richer storm events, route risks, authored NPC request data, morale and preparation feedback. No `StormEventManager`, `StormEventData`, `RouteRiskData` or `NpcRequestData` implementation was found. Existing custom quests only partially overlap that proposal. Do not install those abstractions merely because their names appear here.

Full gameplay save/load was suggested in the older handoff after state stabilizes. It is not implemented and no save schema is approved. Broader acts, rescue/corruption outcomes and other old GameState fields have **Unclear** future status. Existing scene/field presence is insufficient to turn them into commitments.

Historical bulk asset deletion was explicitly reversed by the user after visual problems. It is **Superseded**, not an approved cleanup backlog. Preserve assets until a future scoped request and stronger dependency evidence justify changes.

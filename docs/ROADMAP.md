# Roadmap and unresolved work

Audited 2026-09-16–17. This file describes future work, not implemented architecture. No new feature work is authorized by this document. See [GAME_DESIGN.md](GAME_DESIGN.md) for historical task provenance and [ARCHITECTURE.md](ARCHITECTURE.md) for current behavior.

## Current stage and priority

Current apparent stage: playable festival/beta preparation loop. The current approved priority is conservative GDScript cleanup that preserves gameplay. Release date and subsequent milestones remain **Unknown / Needs verification**.

The milestones below are **audit-proposed stabilization work**, not recovered commitments. Their ordering is a recommendation based on verified source risks; it does not establish a scheduled release plan.

## Milestone 1 — Establish a reproducible playable baseline (proposed)

Goal: verify the current preparation loop from a fresh checkout and resolve confirmed blockers in a separately authorized implementation task.

### Required

- [ ] Investigate the missing greybox path in `game/scenes/locations/tindahan.tscn`; choose the correct replacement by scene inspection and verify fresh-import travel to Ate Linda.
- [ ] Remove or redirect the missing `test_room2` route only after deciding whether that debug destination is still wanted.
- [ ] Run the [testing guide](TESTING.md) through startup, tasks, travel, ending and second-run reset; record results and actual failures.
- [ ] Confirm Godot 4.6.1 as the release target or approve a separate migration plan. The old 4.7 intention is not a completed upgrade.

### Optional

- [ ] Add a narrowly scoped resource-reference check if it proves useful; distinguish missing paths from UID recovery and stale comments.

### Completion criteria

The normal route is demonstrated in the target engine, each failing path has a recorded resolution, and results distinguish static checks from runtime playtests.

## Milestone 2 — Resolve interaction and state edge cases (proposed)

Goal: test and address concrete consistency risks without broad refactoring.

### Required

- [x] Align seven-slot hotbar selection with inventory capacity; preserve key 8 as the last-slot alias.
- [ ] Reproduce storm arrival during travel/task/dialogue/modal activity; decide and test transition and pause ownership behavior.
- [ ] Exercise full-inventory quest turn-in, repeated interactions, stock resets and return visits.
- [ ] Audit dynamic localization and long text in both languages, including intended button-language scope.

### Optional

- [x] Add a focused no-framework regression scene for inventory, hotbar, task requirements, window state and quest readiness.

### Completion criteria

Each reported bug has a reproduction and relevant verification, and intentional behavior such as an unpaused map/backpack is preserved or explicitly changed.

## Milestone 3 — Validate distribution and presentation (proposed)

Goal: establish evidence for a downloadable Windows build and readable presentation.

### Required

- [ ] Export with matching templates and a deliberate output path; test the packaged CSV, LFS assets, audio and main flow.
- [ ] Test quality presets, VHS toggle, UI scale and representative resolutions.
- [ ] Measure hardware performance before publishing minimum/recommended requirements.

### Optional

- [ ] Revisit additional accessibility controls after agreeing on product scope.

### Completion criteria

An actual exported build has recorded smoke-test results and any hardware claims include measurements. This documentation audit supplies neither.

## Backlog by proposed priority

| Priority | Candidate work | Basis |
| --- | --- | --- |
| High | Scene-reference repair and complete manual playthrough | Two missing paths remain; headless checks do not establish visual usability |
| High | Deadline/transition and pause lifecycle checks | Hotbar bounds are fixed; broader lifecycle risks remain |
| Medium | Localization scope/coverage, capacity-sensitive quest rewards, repeat-run reset coverage | Existing code paths and historical intent require testing |
| Medium | Remaining mutable inventory ownership and duplicate storm-state review | Add/combine validation is implemented; live arrays and duplicate storm state remain |
| Low / nice to have | Extend targeted checks as needed and establish a measured performance baseline | Focused regression scene exists; hardware benchmarks do not |

## Known defects and verification boundaries

**Static defects confirmed in source:**

- `game/scenes/locations/tindahan.tscn` references missing `res://game/maps/tindahan/tinadahan_greybox.tscn`. The cleanup baseline reproduced the missing-resource error and vanished-node recovery warning in Godot 4.6.1; the scene path was deliberately left unchanged.
- `SceneManager.SCENE_PATHS.test_room2` targets missing `res://game/maps/test_map1/tindahanmo.tscn`.
- Resolved in the conservative cleanup: wheel wrapping now uses seven slots and key 8 explicitly aliases the last slot.
- Corrected the touched hotbar, timer and HUD comments to describe current capacity, pause/startup behavior and scene ownership. Other legacy comments still require source verification.

**Runtime follow-up:** the accelerated integration smoke passed travel, restart, second-run clock and ending checks both before and after cleanup. Both versions emitted a null-tree error from `PreparationChecklistHUD._schedule_checklist_resize` during restart. Investigate its deferred resize lifecycle separately; this cleanup does not change it. See [TESTING.md](TESTING.md) for the smoke's limits.

**Source risks, not runtime-reproduced bugs in this audit:** deadline coroutines can overlap scene changes/fades; scene-owned dialogues have distributed pause/lock cleanup; multiple overlapping targets can retain a stale nearest selection; Nestor turn-in checks capacity before removing the outgoing chicken. See architecture for exact owners. Do not report these as verified fixed or as observed crashes.

The old danger-zone reset complaint is historical; current menu/restart code resets both scene and storm managers. Keep a second-run regression check rather than treating that old report as proof the bug is still present.

## Deferred ideas — not committed features

**Plan next game features** proposed richer storm events, route risks, authored NPC request data, morale and preparation feedback. No `StormEventManager`, `StormEventData`, `RouteRiskData` or `NpcRequestData` implementation was found. Existing custom quests only partially overlap that proposal. Do not install those abstractions merely because their names appear here.

Full gameplay save/load was suggested in the older handoff after state stabilizes. It is not implemented and no save schema is approved. Broader acts, rescue/corruption outcomes and other old GameState fields have **Unclear** future status. Existing scene/field presence is insufficient to turn them into commitments.

Historical bulk asset deletion was explicitly reversed by the user after visual problems. It is **Superseded**, not an approved cleanup backlog. Preserve assets until a future scoped request and stronger dependency evidence justify changes.

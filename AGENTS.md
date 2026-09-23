# Repository instructions for AI agents

## Purpose and project

Use these instructions for work in **Bagyong Bahay**, a GDScript disaster-preparation game with 3D environments and a 2.5D camera. Target Godot **4.6.1**, Forward Plus. The configured application name is `Software Festival 2026`. Current scope is a playable festival/beta preparation loop, not a completed four-act simulation.

## Source of truth

For implementation facts, use: current repository implementation → current task requirements → this file → [architecture](docs/ARCHITECTURE.md) → [game design](docs/GAME_DESIGN.md) → other current documentation → historical conversations. Task instructions control authorized actions. Never treat plans, unused fields, comments, or a past assistant's completion claim as proof of implementation. Use `Unknown / Needs verification` where evidence is insufficient.

## Before modifying code

Inspect the relevant implementation, scenes/resources, callers and dependencies. Read the linked guides and nearby conventions. Reuse existing patterns and make the smallest coherent change. Check Git status first and preserve unrelated user changes. Use independent sub-agents when useful for substantial investigation or review.

## Repository map and entry points

| Path | Responsibility |
| --- | --- |
| `project.godot` | Main scene, autoload order, Input Map, rendering |
| `game/scenes/intro/IntroSequence.tscn` | Application entry, narrative intro → menu |
| `game/scenes/main_menu/Main_Menu1.tscn` | Difficulty choice, settings, scores, start |
| `game/scenes/locations/house_inside.tscn` | Current new-run destination; family and tasks |
| `game/scenes/locations/` | Travel destinations; `bodega.tscn` is a home room |
| `game/scenes/ending/EndingSequence.tscn` | Six preparation outcomes and score submission |
| `game/entities/playerv2/playerv_2.tscn` | Active player, camera, backpack/hotbar/HUD/map/pause |
| `game/entities/npc/`, `game/entities/quest_npcs/` | Dialogue bases and optional choices |
| `game/objects/interactables/` | `Interactable` base, tasks, doors and cues |
| `game/autoload/` | Managers **and some ordinary scene/class scripts** |
| `game/resources/`, `game/scripts/` | Item/shop resources, dialogue-related data consumers, environments |
| `game/ui/`, `game/audio/`, `game/weather/`, `game/shaders/` | Presentation and reusable helpers |
| `game/localization/` | Custom runtime CSV; see its [editing guide](game/localization/README.md) |
| `game/assets/`, `_raw_assets/` | Runtime and source assets; scenes use both |
| `game/maps/`, `game/scenes/act1/`, `game/tests/` | Mixed supporting/older scenes; verify reachability |
| `.agents/skills/` | Agent guidance, not a Godot runtime addon |

## Globals and communication

The **17 configured autoloads**, in order, are `VisualSettings`, `LocalizationManager`, `TransitionOverlay`, `GlobalTimer`, `SceneManager`, `NeedsLog`, `GameState`, `TravelCalculator`, `InventoryManager`, `SideQuestLog`, `EconomyManager`, `ShopUi`, `StormEnroachment`, `AudioManager`, `StormAudioController`, `LeaderboardManager`, `VhsCrtOverlay`. Preserve spelling/case, including `ShopUi` and `StormEnroachment`. `AudioManager` is the scene `game/utils/AudioManager.tscn`.

`TaskObject.gd` is a base class; `HUDOverlay.gd` is attached to a player-owned scene. Neither is an autoload. Search for equivalents before adding managers, services or global state.

Use existing direct manager APIs for actions and signals for notifications: `inventory_changed`, `need_discovered`, `need_resolved`, `window_boarded`, `guide_tasks_changed`, `time_updated`, `storm_arrived`, `travel_completed`, `language_changed`. Inspect signatures in source. Preserve `player`, `interactables`, `camera volume` and runtime UI groups used for discovery.

## Current systems and invariants

- **Implemented:** PlayerV2 movement/sprint/step-up; camera volumes; proximity interaction; dialogue; six household needs; shopping, inventory and two combine recipes; side quests; timed travel/storm; endings; audio/settings/localization; local leaderboard.
- **Partial/legacy:** old first-person controller, act enums/outcome flags and unused barter API. They do not establish active combat, four playable acts, or a complete branching rescue story.
- **Not present:** full gameplay save/load, combat/enemy navigation, multiplayer, third-party automated test framework. Focused built-in regression checks now live in `game/tests/cleanup_regression.tscn`.
- `GameState`, `NeedsLog`, `InventoryManager` and `SideQuestLog` hold session truth. UI must not create competing inventory or objective state. Inventory has **seven slots**; only canned goods and nails stack.
- `GlobalTimer` has a 720-minute limit and reference-counted pause API. Pair every pause/resume and handle cleanup. Scene-tree pause is separate. The current map, backpack and fades do **not** pause the clock. New runs start the clock immediately in the house.
- Preserve stable item IDs, world-item IDs, window IDs and location IDs across resources/callers. `water_jugs.tres` uses item ID `water_jug`.

## Scenes, resources, input and physics

Locations instantiate their own player and its UI. Whole-scene replacement frees them; autoloads survive. Use `SceneManager.travel_to` for travel, its pending spawn IDs and `spawnpoint.gd` markers. The player must be discoverable in group `player` when a marker places it. Check transient dialog ownership, movement locks, mouse capture and timer pauses on exit.

Use existing `PackedScene.instantiate()` / `add_child()` / `queue_free()` patterns. Custom Resources include `ItemData`, `ShopItem`, `ShopData`, `DialogueLine`, `DialogueSequence`. `ShopUi` duplicates/caches shop data for per-run stock; do not mutate shared `.tres` data casually. Item type controls task consumption; tools are retained, but the current wrench defaults to a consumable type.

Reuse Input Map actions: movement, `sprint`, `interact`, `dialogue_advance`, `open_map`, `toggle_backpack`, `hotbar_slot_1`–`hotbar_slot_8`. Pause uses built-in `ui_cancel`. Mapped jump/crouch/flashlight do not imply PlayerV2 supports them. See [controls](README.md#controls).

PlayerV2 uses `CharacterBody3D`; interactions and camera volumes use `Area3D`. There is no named project collision-layer scheme. Most scenes omit masks/layers; a test-world override uses value 3. Check scene properties and step-up collision probes before changing physics. Do not infer a gameplay layer convention from that test scene.

## Coding and debugging conventions

Use tabs and existing local formatting. Classes are generally PascalCase; members/functions/signals snake_case; constants UPPER_SNAKE_CASE. Filenames mix PascalCase and snake_case: follow the neighborhood, do not normalize unrelated files. Typing commonly uses explicit parameters/returns, typed arrays and `:=`; flexible Dictionaries/Variants also exist.

Use Inspector exports, `@onready` paths/unique names, inherited interaction/NPC hooks and existing UI style helpers. Preserve `super._ready()` where needed. Comments mix `##` API notes, `#region`, and section dividers; some historical comments are stale. Update explanatory comments with changed behavior. Guard invalid resources/nodes, use existing `push_warning`/`push_error` and debug-gated logging; do not silently weaken validation.

Profile before optimizing. Player collision probes, camera follow, storm particles, postprocessing, lighting, and UI rebuilds deserve care. Preserve current dirty flags/cached slot nodes; avoid speculative per-frame scans or allocations.

## Assets, dependencies and safety

No runtime addon directory or enabled editor plugin is present. Do not modify third-party source unless required. Git LFS tracks major asset formats. Avoid asset/scene/node renames: paths, UIDs, animation tracks and Inspector bindings are coupled. Do not hand-edit `.godot/`, generated imports or generated translations. Keep `.uid` companions with their scripts.

Never hardcode or expose secrets. Keep diffs focused, avoid unrelated formatting/settings, and exclude caches/build artifacts. Do not commit or push without user authorization. Never discard unrelated changes or rewrite history.

## High-risk changes and verified debt

Review changes to global resets, timer/scene transitions, player input/physics, resource schemas, localization source keys and persisted settings/scores carefully. Never silently change persistence formats. Significant refactors need a stated problem, affected systems, alternatives, risks and preserved behavior; record the decision.

Known issues are recorded in [architecture](docs/ARCHITECTURE.md) and [roadmap](docs/ROADMAP.md): missing tindahan greybox path and debug `test_room2` target; overlapping transition/pause lifecycle risks; legacy state/comments. These notes do not authorize unrelated fixes.

## Completion and documentation maintenance

- Verify requested behavior and relevant callers/scenes; inspect the final diff.
- Follow [testing](docs/TESTING.md); report exactly which checks ran and which did not. Never claim unperformed tests passed.
- No unrelated rewrites, duplicate managers, casual resource moves, mass formatting or project-setting edits.
- Update architecture for system/lifecycle changes; game design for player-facing behavior; development for workflow; testing for validation; decisions for significant tradeoffs; roadmap for planned work; README/this file when entry points or operating instructions change.

Keep this file operational; put detailed explanations in the linked guides.

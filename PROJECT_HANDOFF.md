# Bagyong Bahay Project Handoff

Last updated: 2026-08-31  
Current branch: `dev`  
Latest backed-up commit before this handoff: `de80cf5 Backup before Godot 4.7 upgrade`  
Remote: `origin/dev` at `https://github.com/Jeyep18/software-eng-fest.git`

## Purpose

`Bagyong Bahay` is a Godot 4 disaster-preparedness game about a Filipino family preparing their home before a major storm arrives. The project mixes exploration, dialogue, inventory, shopping, task completion, time pressure, storm encroachment, localization, and ending outcome logic.

This handoff is written for another conversation, AI model, or teammate who needs to understand the current state quickly without rediscovering the whole project from scratch.

## Current Engine State

- Godot project name: `Software Festival 2026`
- Current project feature flag: `4.6`
- Render mode: `Forward Plus`
- Main scene: `res://game/scenes/intro/IntroSequence.tscn`
- Planned user action: update Godot from 4.6.1 to 4.7
- Export preset now exists for Windows Desktop at `export_presets.cfg`
- Git LFS is configured for large assets such as `.glb`, `.png`, `.wav`, `.ogg`, and `.flac`

Before the Godot update, all project changes were committed and pushed to `origin/dev` in commit `de80cf5`.

## High-Level Project Map

- `project.godot`: engine settings, input actions, autoload registration, main scene.
- `game/autoload`: global managers for state, time, inventory, scene changes, localization, economy, storm behavior, audio, leaderboard, visual settings, and overlays.
- `game/scenes`: main playable scenes, intro, ending, menu, locations, and act-specific scenes.
- `game/entities`: player, NPCs, quest NPCs, shop NPCs, dialogue resources, and character scenes.
- `game/objects/interactables`: interactable props, task sites, world objects, and task scripts such as roof, window, fridge, medicine, radio, and water tasks.
- `game/ui`: HUD, pause menu, map, backpack, hotbar, shop, dialogue, tutorial, settings, credits, leaderboard, and related UI scripts.
- `game/localization`: CSV text table used by `LocalizationManager`.
- `game/resources`: data resources, environments, items, voxels, and other Godot resources.
- `game/weather`: storm/rain layer and controller.
- `_raw_assets`: source art/model/audio/reference assets. Many files are large and tracked through Git LFS depending on extension.
- `game/tests`: current test/playground scenes.

## Core Systems

### Game State

`game/autoload/GameState.gd` is the central gameplay state singleton. It tracks:

- Player name and display identity.
- Selected difficulty: Story, Standard, Challenge.
- Difficulty timing, score multipliers, and starting departure cash.
- Current act and Act 1 state.
- Story progression flags such as Nanay intro, Lola intro, house task unlocks, grocery donation, Ate Linda discount, and smoke break.
- Ending outcome variables such as tarp, plywood, rope, medicine, first aid, Tatay call, child safety, and corruption evidence.
- Collected world items.

Any new gameplay feature should first check whether it belongs in `GameState` or a more specific manager.

### Time and Storm Pressure

`game/autoload/GlobalTimer.gd` controls the 12-hour pre-storm countdown:

- Total duration is 720 in-game minutes.
- Difficulty affects `seconds_per_game_minute`.
- Time begins paused and is resumed after the early game/Act 1 flow.
- UI systems should call `pause_timer()` and `resume_timer()` as a pair.
- Travel and tasks can add time instantly with `add_time()`.
- Storm encroachment thresholds fire at 4h, 6h, 9h, and 12h.
- At storm arrival, the timer emits `storm_arrived`, and `SceneManager` transitions to the ending.

### Scene Travel

`game/autoload/SceneManager.gd` maps location IDs to scene paths and handles travel fades, travel time cost, storm travel blocking, pending spawn IDs, and ending transition.

Important location IDs include:

- `intro`
- `main_menu`
- `act1`
- `home`
- `tindahan`
- `pharmacy`
- `barangay_hall`
- `grocery`
- `mang_romy`
- `ate_linda`
- `hardware`
- `bodega`
- `test_room1`
- `ending`

Potential issue: `test_room2` currently points to `res://game/maps/test_map1/tindahanmo.tscn`, but that file was deleted in the latest backup commit. Either remove that debug route or redirect it to an existing scene.

### Interactions and Tasks

`game/objects/interactables/interactable.gd` defines the base `Interactable` class:

- Extends `Area3D`.
- Emits player enter/exit signals.
- Exposes `prompt_label`.
- Exposes `prompt_visibility_changed`.
- Provides a default `interact()` warning.

`game/autoload/TaskObject.gd` extends this for task-based interactions. Specific task scripts live in `game/objects/interactables`, including:

- `RoofTask.gd`
- `WindowTask.gd`
- `FridgeTask.gd`
- `MedicineTask.gd`
- `radio_task.gd`
- `fill_water_task.gd`

The current player controller resolves nearby interactables, checks facing direction, displays the interaction prompt, and calls `interact()`.

### Player

The active newer player is in `game/entities/playerv2`:

- `playerv_2.gd`
- `playerv_2.tscn`
- `camera_2d5_controller.gd`
- `player_model.tscn`
- `simple_character_psx.tscn`

The player handles movement, animation, interaction targeting, prompt display, and UI-blocked interaction checks.

### Inventory

`game/autoload/InventoryManager.gd` is the source of truth for inventory:

- Max inventory size is 7.
- Hotbar size is also 7.
- Stackable items include `canned_goods` and `nails`.
- Critical items include hammer, tarp, medicine, water jug, plywood, nails, batteries, broken radio, and dead flashlight.
- Combine recipes currently include:
  - `batteries + dead_flashlight -> working_flashlight`
  - `batteries + broken_radio -> working_radio`

Backpack and hotbar UI should interact through `InventoryManager`, not keep separate inventory truth.

### Localization

`game/autoload/LocalizationManager.gd` loads `game/localization/game_text.csv` and translates by source text or key.

Current languages:

- English
- Tagalog

The manager localizes node properties such as `text`, `placeholder_text`, and `tooltip_text`. It also listens for newly added nodes and localizes them.

Use `LocalizationManager.translate(text)`, `translate_key(key)`, `trf(text, values)`, or `trfk(key, values, fallback_text)` for dynamic text.

## Latest Backed-Up Changes

The latest pushed backup commit is:

`de80cf5 Backup before Godot 4.7 upgrade`

Summary:

- Added Windows export preset.
- Updated player interaction prompt behavior.
- Updated localization entries.
- Shortened part of the intro sequence pacing.
- Moved VoxelGI data resources into `game/resources/voxels`.
- Moved TV scene into `game/objects/interactables`.
- Removed older duplicated map/object scene files under `game/maps` and `game/objects`.
- Updated several active scenes to reference the new resource locations.

Changed files in that commit:

- Added `export_presets.cfg`.
- Modified `game/entities/playerv2/playerv_2.gd`.
- Modified `game/localization/game_text.csv`.
- Modified `game/maps/test_map1/room_1.tscn`.
- Modified `game/scenes/act1/Act1.tscn`.
- Modified `game/scenes/intro/IntroSequence.gd`.
- Modified `game/scenes/locations/house_inside.tscn`.
- Modified `game/scenes/locations/room_1.tscn`.
- Modified `game/tests/test_world/test_world.tscn`.
- Renamed `game/objects/tv.tscn` to `game/objects/interactables/tv.tscn`.
- Renamed `game/maps/house/house_1.VoxelGI_data.res` to `game/resources/voxels/house_1.VoxelGI_data.res`.
- Renamed `game/maps/test_map1/room_1.VoxelGI_data.res` to `game/resources/voxels/room_1.VoxelGI_data.res`.
- Renamed `game/maps/tindahan/tindahan.VoxelGI_data.res` to `game/resources/voxels/tindahan.VoxelGI_data.res`.
- Deleted old map scenes:
  - `game/maps/ate_linda/ate_linda.tscn`
  - `game/maps/barangay_hall/barangay_hall.tscn`
  - `game/maps/grocery/grocery.tscn`
  - `game/maps/hardware/hardware.tscn`
  - `game/maps/house/house_1.tscn`
  - `game/maps/mang_romy/mang_romy.tscn`
  - `game/maps/pharmacy/pharmacy.tscn`
  - `game/maps/pharmacy/pharmacyGreybox.tscn`
  - `game/maps/test_map1/tindahanmo.tscn`
  - `game/maps/tindahan/tinadahan_greybox.tscn`
  - `game/maps/tindahan/tindahan.tscn`
- Deleted old object scenes:
  - `game/objects/bed.tscn`
  - `game/objects/tree.tscn`

## Current Known Risks

- `game/scenes/locations/tindahan.tscn` still references `res://game/maps/tindahan/tinadahan_greybox.tscn`, which was deleted. This scene should be opened in Godot and fixed or redirected before relying on the location.
- `SceneManager.gd` still has `test_room2` pointing to deleted `res://game/maps/test_map1/tindahanmo.tscn`.
- Several scenes still reference `res://game/maps/camera volumes/camera_volume.gd`. That file still exists, but the folder name contains a space and lives under `game/maps` even though most maps were moved toward `game/scenes/locations`. Consider moving this camera volume script later, after updating references safely in Godot.
- `README.md` is currently empty, so this handoff is the main written orientation document for now.
- There are many raw imported assets. Be careful with bulk cleanup because Godot `.import`, `.uid`, and scene references can break if moved outside the editor.
- The project is about to move from Godot 4.6.1 to 4.7. After opening in 4.7, expect Godot to rewrite metadata/import files. Commit those separately from gameplay changes so migration noise is easy to review.

## Suggested Godot 4.7 Update Workflow

1. Keep the current backup commit `de80cf5` as the known rollback point.
2. Open the project in Godot 4.7.
3. Let Godot import and upgrade resources.
4. Run the main intro flow from `IntroSequence.tscn`.
5. Test travel to core locations: home, tindahan, pharmacy, grocery, hardware, barangay hall.
6. Test core UI: pause menu, settings, backpack, hotbar, map, shop, dialogue, and tutorial modal.
7. Test critical tasks: roof, windows, medicine, food/fridge, water, radio/flashlight.
8. Check the output console for missing resources, broken UIDs, script parse warnings, and renamed engine APIs.
9. Commit the automatic Godot 4.7 migration separately before making new design/code changes.

## Improvements and Suggestions

- Fix stale references after the recent cleanup, especially `tindahan.tscn` and `SceneManager.test_room2`.
- Move reusable camera volume code out of `game/maps/camera volumes` into something like `game/utils/camera_volume` or `game/scenes/camera`, then update references through Godot.
- Fill in `README.md` with basic setup, Godot version, branch rules, Git LFS note, run instructions, and export instructions.
- Add a short `CHANGELOG.md` or `docs/` folder for migration notes and major feature milestones.
- Add a lightweight smoke-test checklist for the festival build so anyone can test the same route before submitting.
- Keep localization keys stable. Avoid using placeholder/test strings in UI because `LocalizationManager` can preserve them as source metadata.
- Consider centralizing location metadata in one resource or data file instead of spreading location IDs across map UI, travel, and scene manager code.
- Add validation tooling or an editor script that checks for missing `res://` references after file moves.
- Separate raw assets from production assets more clearly. `_raw_assets` is useful, but production scenes should ideally point to curated assets under `game/assets` or `game/resources`.
- Review inventory item IDs and task item requirements together so critical item names are consistent across shops, pickups, tasks, and endings.
- Consider adding save/load support only after core state is stable, because `GameState`, `InventoryManager`, `GlobalTimer`, and task completion state will all need serialization.
- For future AI conversations, start by reading this file, `project.godot`, `game/autoload/GameState.gd`, `game/autoload/SceneManager.gd`, `game/autoload/GlobalTimer.gd`, `game/autoload/InventoryManager.gd`, and `game/objects/interactables/interactable.gd`.

## Suggested Prompt for Future Conversations

Use this when handing the project to another AI model:

```text
We are working on Bagyong Bahay, a Godot 4 disaster-preparedness game. Start by reading PROJECT_HANDOFF.md, then inspect project.godot and the relevant scripts before making changes. The current branch is dev. The pre-Godot-4.7 backup commit is de80cf5. Be careful with Godot scene/resource references, UIDs, Git LFS assets, localization, and autoload state. Do not move or delete imported assets unless you also update all Godot references.
```

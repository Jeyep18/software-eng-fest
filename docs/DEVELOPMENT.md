# Development guide

This guide describes the repository inspected on 2026-09-16–17. Read [AGENTS.md](../AGENTS.md) before changing files, [ARCHITECTURE.md](ARCHITECTURE.md) for runtime ownership, and [TESTING.md](TESTING.md) for verification. Existing implementation takes precedence over comments and historical plans.

## Environment and setup

- Use **Godot 4.6.1**, the standard GDScript build. The locally installed executable reported `4.6.1.stable.official.14d19694e`; `project.godot` declares the 4.6 feature family and Forward Plus renderer.
- Use Git and Git LFS for the checkout. The inspected machine has Git LFS 3.7.1; that exact patch version is not established as a project requirement.
- No C# project, package-manager build pipeline, installed `addons/` directory, or enabled editor plugin is present. Blender import is disabled in `project.godot`; do not assume Blender is required to open the project.
- Fetch LFS content when cloning (`git lfs install`, then `git lfs pull` in the checkout). These are setup steps, not actions performed by the documentation audit. `.gitattributes` tracks `*.wav`, `*.ogg`, `*.flac`, `*.glb`, and `*.png`; do not replace asset content with LFS pointer text.

In Godot Project Manager, import the repository's `project.godot` and allow normal resource import. Opening the editor can update `.godot/` and import metadata. For a task that forbids generated-file writes, restrict work to static inspection or use a disposable copy if that task permits it.

Run the project with **F6 only for an intentionally isolated scene**, or **F5 for the full application**. The configured main UID resolves to `game/scenes/intro/IntroSequence.tscn`. Normal progression is intro → `Main_Menu1.tscn` → difficulty selection → `game/scenes/locations/house_inside.tscn`. Running a location directly bypasses startup/reset/difficulty selection and is not equivalent to a fresh game.

## Repository and naming conventions

| Area | Current use |
| --- | --- |
| `game/autoload/` | Registered global manager scripts; preserve `project.godot` registration order |
| `game/entities/` | Animals, grouped NPC roles/models and existing player implementations |
| `game/objects/` | Props, interactable implementations, task sites and visual cues |
| `game/scenes/` | Intro/menu/ending, active locations, and older act scenes |
| `game/ui/` | Player HUD, map, inventory, dialogue, pause, tutorial and settings |
| `game/resources/` | Item/catalogue and other Resource data; inspect existing subfolders before adding data |
| `game/resources/dialogue/`, `game/resources/shops/` | Resource classes beside their authored data; narrative behavior is in `objects/interactables/` |
| `game/assets/` | Runtime models, textures, fonts and sound |
| `game/weather/`, `game/shaders/`, `game/audio/` | Rain particles, VHS shader and shared SFX helpers |
| `game/camera/`, `game/scenes/components/`, `game/tests/` | Camera volumes, spawnpoint component, regression scenes and sandbox worlds |
| `_raw_assets/` | Retained model/texture bundles, including assets loaded by runtime scenes |

Names are mixed: managers/classes commonly use PascalCase (`InventoryManager.gd`, `ItemData.gd`); locations/controllers also use snake_case (`house_inside.tscn`, `playerv_2.gd`), and existing names include `Main_Menu1.tscn` and `dialogueLine.gd`. Follow the neighboring implementation, rather than renaming files to impose consistency. Class names are generally PascalCase; functions, variables and signals use snake_case; constants use UPPER_SNAKE_CASE. Underscore prefixes often indicate internal state/helpers.

Scene node names and `%UniqueName` references are contracts: `$World3D/WindowArea`, `%InteractText` and `%SpeakerDialogue` are examples. Moving or renaming a node requires checking scripts, exported NodePaths, inherited scene overrides and signal connections. Preserve `.uid` sidecars and asset import settings; do not manually edit generated `.godot/` content.

## Folder organization and relocation

Folder names describe ownership or purpose. NPCs are grouped by family/shop/quest/story roles; UI by feature; audio assets by category. Keep filenames, scene nodes, stable IDs and resource UIDs unchanged when moving files.

Move script `.uid` and asset `.import` companions with their owners. Preserve import settings and let Godot regenerate derived import paths in a disposable copy. Update full `res://` paths, partial test paths, manifests and documentation together. `_raw_assets/` bundles retain their original paths and relative model dependencies. Do not move item definitions out of `resources/items/`: inventory combinations load them by item ID.

## Code and communication patterns

GDScript is the implementation language. Typed parameters/returns, typed arrays, enums, `@export`, `@onready`, `class_name` and inferred `:=` variables are common, alongside untyped Dictionaries/Arrays and older untyped code. Preserve nearby typing practices and improve types only within the requested scope.

Composition is prominent: location scenes contain player/NPC/prop instances; the active player scene owns multiple UI scenes; managers retain session state across scene replacements. Inheritance supplies reusable `Interactable` and NPC/task behaviors. Do not replace this with new global managers without a demonstrated need.

Use direct manager calls for commands, such as `InventoryManager.combine_items`, `SceneManager.travel_to`, or `LocalizationManager.translate`. Signals communicate changes to observers: `inventory_changed`, `need_discovered`, `need_resolved`, `cash_changed`, `time_updated`, `travel_completed`, and settings-change signals. Groups locate scene-owned peers (`player`, `map_screen`, `backpack_ui`, `hotbar_ui`); group names must match callers exactly. Signals appear both in scene connections and `_ready()` code, so check both to avoid duplicate callbacks.

`preload(...).instantiate()` followed by `add_child()` is the normal reusable-scene pattern. UI construction also happens in code (`AudioSettingsPanel`, menu overlays, leaderboard name prompt). Deferred setup is used where nodes must be in the tree before camera/global-transform operations. Coroutines await fades, timers, dialogue and animation completion; changing a reset or transition path must account for outstanding callbacks and input locks.

Comments range from compact purpose notes to long scene-tree diagrams and implementation rationale. Some diagrams and counts are stale: inspect executable logic before copying them into new documentation. Error handling commonly uses guards, `get_node_or_null`, `ResourceLoader.exists`, `push_warning`, and `push_error`. Preserve failure checks and meaningful diagnostics.

## Scene and Resource workflows

Before adding gameplay behavior, locate its existing owner and inspect its callers. For example, task completion involves task scripts, `NeedsLog`, inventory and ending results; adding another path without those connections produces inconsistent state.

For a new scene:

1. Start from the nearest relevant scene and identify which nodes/resources are shared versus scene-local. Do not assume similarly named older scenes are the active implementation.
2. Preserve required player/UI ownership, interaction groups, Area3D collision masks and camera-volume wiring. Use the active `game/entities/players/playerv2/playerv_2.tscn` as the gameplay reference, not the older `player/` scene.
3. If it is a travel destination, update the relevant `SceneManager` route/alias, `TravelCalculator`, storm restrictions and `MapScreen` data together as required by scope. A file existing on disk does not make it reachable from the five-node map.
4. Wire spawn IDs/door destinations and verify travel away/back. Check that reconstructed scenes read retained state instead of restoring collected props or completed tasks.
5. Validate both the isolated scene and its normal entry/exit path; see [TESTING.md](TESTING.md).

Existing custom Resources include `ItemData`, `ShopItem`, `ShopData`, `DialogueLine`, and `DialogueSequence`. Edit instances in the Inspector or carefully scoped `.tres` changes. Item IDs are gameplay keys, not display labels; recipe lookup and `BackpackUI` result loading rely on IDs, including `game/resources/items/<item_id>.tres`. Search references before changing an ID or schema. Resource objects may be shared by Godot's loader; inspect `ShopUi` stock/reset handling before assuming reloading a scene resets catalogue state. `ShopItem.reset_stock()` itself is a placeholder.

A new Resource type should follow the existing `class_name ... extends Resource` and exported-field pattern when data warrants it. First check whether an existing type can represent the requested data without changing its contract. Audit consumers and existing `.tres` instances if fields change.

## Ambient animal asset workflow

The approved cat/dog GLBs, coat atlases and post-import script live in `game/assets/animals/`; their [asset README](../game/assets/animals/README.md) records the Blender copies, 24 fps import settings, source preservation and visual approval workflow. Use the two scenes under `game/entities/animals/`, with parent-space waypoints beneath a location's `AmbientAnimals` node. Preserve the supplied meshes/rigs and native import configuration when updating animations. Verify changes in an imported disposable project; do not edit generated `.godot/` files or add a global animal manager.

## Text, UI, audio and settings

Follow the existing [game text editing guide](../game/localization/README.md) and `game/localization/game_text_merged.csv`. Keep formatting placeholders and BBCode intact. Source-string lookup is exact; if a source changes, update its row. New dynamic text should call `LocalizationManager.translate`, `translate_key`, `trf` or `trfk` as appropriate. Automatic localization runs on node addition and language change; it does not continuously translate arbitrary later assignments.

Reuse `game/ui/theme/GameUIStyle.gd`, `GameTheme.tres` and `VisualSettings` sizing where the existing component supports it. Font/style names are historical: regular and semibold helpers currently load the same EAS VHS font. Check English and Tagalog at different UI scales rather than assuming every panel scales uniformly.

Use `game/audio/Sfx.gd` for existing semantic sounds and button wiring. `AudioManager` manages music/ambience/voice and transient SFX; `StormAudioController` separately owns evolving storm layers. Settings and leaderboard are local files, not a complete save-game system. Changing their format requires checking old data and load failure behavior. Persistent files and their scope are documented in [ARCHITECTURE.md](ARCHITECTURE.md).

## Debugging and export

Use Godot's Output/Debugger and Remote scene tree during ordinary development to inspect node ownership, signals, input locks and paused state. Existing `game/tests/sandbox/test_world/test_world.tscn` and `test_world_2.tscn` are exploratory scenes, not assertions or a test runner. Directly loading ending/location scenes is a useful narrow inspection but cannot prove the normal run flow works. Read current resource paths before using older debug entries.

The Windows Desktop preset in `export_presets.cfg` targets x86_64 with embedded PCK. Its output path is machine-relative (`../../../../Desktop/builds/windows/BagyongBahay.exe`); always supply an intentional absolute output destination when building. Use matching Godot 4.6.1 templates. The preset explicitly includes `game/localization/game_text_merged.csv`, whose import mode is **Keep File (exported as is)**: the runtime reads the raw CSV with `FileAccess`, so imported translation resources alone are insufficient. An include filter alone does not override the CSV translation importer. Preserve the Keep File setting when reimporting this custom table.

Export with a graphical renderer, for example `Godot_v4.6.1-stable_win64_console.exe --path 'C:\path\to\disposable-project-copy' --export-release 'Windows Desktop' 'C:\path\to\build\BagyongBahay.exe'`. In Milestone 3, headless export returned exit 0 while logging VoxelGI image serialization errors; graphical export avoided those errors. Inspect the log rather than relying on the exit code. Test from the build directory, outside the source tree, so loose source files cannot mask missing packaged resources. A successful editor run or export does not establish standalone playability. See [TESTING.md](TESTING.md) for the Application Control launch limitation and validation evidence.

For internal Dev Mode testing, use the separate `Windows Desktop Internal Dev` preset with `--export-debug`; it carries the `bagyong_dev_tools` feature tag. The existing `Windows Desktop` preset has no such tag. Dev Mode requires either `editor_runtime` or both the debug build and internal tag, so a release export denies access even if someone selects the internal preset by mistake. Distribute only `--export-release` builds to players and verify the packaged release denies the sequence, Settings toggle and direct dev actions. A typed sequence is a convenience trigger, not a secret credential or protection against modifying a local game package.

## Recording Camera workflow

For the approved normal/wrecked house, choose **Recording location → House teaser**, select the house state, and enter camera mode. **G** switches Normal/Wrecked while retaining position, rotation, FOV and cinematic movement. Normal includes the authored gameplay props, doors and family visuals controlled by **Hide NPCs**. Wrecked retains the approved empty-house composition. Default Stormy gives Wrecked its gloomy HDRI/fog and rain even at the start of a run; dry presets mute that rain. Escape restores the original location; Reset Camera returns to the approved living/dining shot. The set is recording-only and can be selected from any gameplay location. See [asset notes](../game/assets/house_teaser/README.md).

Unlock/enable Dev Mode, start a run, then open Pause → Dev Mode → Recording Camera. Configure the next take and press Enter camera mode. The panel contains the flight controls, hide options, environment dropdown, bounded tuning and recording-only VHS/DOF switches. P toggles world freezing; the deadline stays held even with the world playing. Escape restores the normal camera and paused Dev panel. To change gameplay location, use the existing Dev teleport after Escape, then enter again. Reset Camera restores the selected recording location's initial framing; Reset Preset affects the selected environment's adjustments only.

`DevMode` settings remain in process memory. Keep recording logic under the location-owned `DevCameraController` and `DevCameraEnvironment`; do not use normal VisualSettings setters for a temporary look, move the player, save scene resources, or add a second cursor/timer manager. Entry guards deliberately reject in-flight gameplay actions. Cleanup is callable after access is revoked and must release only the controller's clock ownership while respecting a transition's scene pause.

The user-supplied HDR panoramas live in `game/assets/sky_hdri/` with source/license notes. Sunrise/Sunset load them lazily for recording. Clear Sunny uses Godot's procedural sky; default weather uses the location's authored resources. Keep existing indoor lamps/GI and hidden directional lights. Recheck current quality after restoring temporary sunlight metadata, and test weather signals while a dry preset is active so rain cannot reappear behind the override.

Use `game/tests/dev_camera_regression.tscn` in an imported disposable copy with isolated user data for state checks; use `-- --visual-only` for Forward Plus preset, freeze and panel captures. Inspect rendered output and manually review movement/zoom/stabilization before accepting a take. Exported debug/release checks must preserve the existing Dev Mode access gate; a source editor run is not packaged-build evidence.

## Git workflow and definition of done

Check `git status --short` and the existing diff before editing. Keep user changes intact, keep the change focused, and inspect the final diff including resource/scene changes. `.gitattributes` normalizes text to LF; `.gitignore` excludes `.godot/` and `/android/`. Do not add cache files, mass-reformat unrelated scripts, or relocate assets without necessity. No repository-specific branch/release policy was established by the inspected configuration.

Completion means:

- Requested behavior is implemented using its existing owners and contracts.
- Relevant parse/import checks and manual regressions were actually performed, or their absence is explicitly reported.
- Scene changes, reset/travel paths, inventory/task state and input/pause behavior were checked where affected.
- No unrelated edits, temporary debug code, secrets or generated artifacts were introduced.
- Documentation reflects changed paths, interfaces and behavior without promoting future plans to implementation.

The 2026-09-16–17 documentation task performed static inspection and executable-version verification only; it did not launch/import the project, export a build, or playtest it.

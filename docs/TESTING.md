# Testing and verification

## House teaser props and weather follow-up

Normal now uses the authored gameplay house visuals and lighting, including its doors, TV, sofa, furniture, family and eleven surrounding trees. Wrecked retains approved damage/flood meshes, the damaged sofa, native additional props and surroundings; its TV follows the displaced cabinet and its door leaves/family are absent. Hide NPCs affects Normal. The existing environment helper starts from the selected state's authored resource and applies each preset once. Wrecked Default Stormy uses the existing overcast HDRI, fog and full-intensity rain; dry presets suppress rain, and world freeze pauses it.

Godot **4.6.1.stable.official.14d19694e**, synchronized disposable project `C:/Temp/bagyong-static-npcs-20261010/project`, isolated APPDATA/LOCALAPPDATA and exact BAGYONG_ISOLATED_SMOKE paths:

| Check | Result |
| --- | --- |
| House regression | **11,516 checks, 0 failures**. Native mesh resources and global placements match the playable house; visual copies have no gameplay scripts/groups/collision participation. Includes exclusive states, cabinet-relative TV placement, no duplicate sofa, NPC visibility, state environment rebuilds, all four preset exposures, weather refresh/dry/freeze behavior, current-location switching with player input disabled, restart/title/teleport/storm cleanup and restoration. |
| Forward Plus | **11,530 checks, 0 failures**, no logged warnings/errors. Actual 1920Ã—1080 matched living/dining, reverse and bedroom views, both states under all four presets, NPC visibility and EN/TL panels. A separate wider props/NPC capture passed **11 checks**, also without logged errors. **32 full-resolution PNGs** and four comparison sheets are in [the revised gallery](../design_previews/house_teaser/README.md). |
| Existing camera regression | **979 checks, 0 failures** after the controller ownership change. |
| Packaged internal debug runtime | Native resource pack export succeeded. The installed Windows debug template loaded the pack from an isolated directory and passed **11,516 checks, 0 failures**, including native house dependencies, imported textures/HDRIs and lifecycle restoration. This was a disposable test entry, not a distribution build. |
| Review and preservation | Independent source review found no actionable issue. Final diffs checked against exact pre-adjustment files; original gameplay scene and model assets were not edited. Both GLB hashes still match the previous integrity report. No Blender file was edited by this revision. |

Logs remain under `C:/Temp/bagyong-house-teaser-adjustments-20261013`. The diagnostic package remains in its `package/` folder (about 1.1 GB) because automatic approval review blocked deletion with "blocked by policy". Headless runs retain the existing ObjectDB/ten-resources-at-exit diagnostics; the package also reports a test-script UID fallback to its valid text path. These are separate from passing assertions and clean graphical logs. Manual recording feel, sustained capture performance and a natural full-day playthrough remain unverified. Public release denial was verified in the preceding integration stage; this follow-up did not rerun that package. No access-gate or export-preset changes were made.

## Approved normal/wrecked house recording location - 2026-10-12

`house_teaser_regression.tscn` exercises the production PauseMenu and recording controller with the approved imported house. Godot **4.6.1.stable.official.14d19694e** in the synchronized disposable project `C:/Temp/bagyong-static-npcs-20261010/project` passed **5,611 headless checks, 0 failures** and **5,613 Forward Plus checks, 0 failures**. The original camera suite passed **979 checks, 0 failures**. Each run uses isolated APPDATA/LOCALAPPDATA and an exact BAGYONG_ISOLATED_SMOKE path; production user data and project/export settings are unchanged.

Coverage includes validated location/state choices, retained framing, exclusive states, original world/light/GI visibility and processing, unchanged player/destination/deadline/preferences, current-location switching, reentry/reset, developer disable/run end and real Restart/Return to Title/teleport/storm cleanup. Six native **1920Ã—1080** renders and English/Tagalog 175% panel captures were inspected. The internal debug test package passed the same **5,611 checks** outside the source directory, proving the imported models/textures are packaged and loadable. See [Godot comparisons](../design_previews/house_teaser/README.md) and [asset notes](../game/assets/house_teaser/README.md).

Asset checks validate all 68 Normal / 71 Wrecked embedded images, wet color factors, water and transparent wall-mark textures. CSV verification preserves every previous row except the updated recording instructions and adds six UI labels. Both original/approved Blender files retain their pre-export hashes. Independent source review found no actionable issue. A public release test package passed **3 access-denial checks, 0 failures**, including direct new location/state settings. Export initially exhausted disk space; removing only task-created diagnostic packages resolved it. Test packages were removed after verification, while logs and `glb_integrity.json` remain in `C:/Temp/bagyong-house-teaser-20261012`.

Some headless runs retain existing ObjectDB/resource-in-use shutdown diagnostics. Floating poses are static; no fluid animation, audio, automated glitch edit or gameplay damage system was added. Manual recording feel, sustained performance and a natural full-day playthrough remain open.

## Dev Mode Recording Camera - 2026-10-12

`game/tests/dev_camera_regression.tscn` exercises the production camera, pause panel, environment helper and all six destinations. Verification used Godot **4.6.1.stable.official.14d19694e**, a synchronized imported disposable project at `C:/Temp/bagyong-static-npcs-20261010/project`, and separate APPDATA/LOCALAPPDATA plus an exact `BAGYONG_ISOLATED_SMOKE` path for each run. Production user data, project/export settings and `.godot/` caches were untouched.

| Check | Result |
| --- | --- |
| Recording camera state regression | **979 checks, 0 failures**. Access guards, bounded settings/FOV/pitch, blocked gameplay input, held deadline in both time modes, frame-rate-independent cinematic movement, retained/reset framing, each hide option, previously hidden objects, completed preparations, all four presets across all six destinations, resource/lighting restoration, inherited and explicit graphics effects, unchanged saved graphics bytes, weather-controller refreshes and preservation of another timer pause owner. |
| Lifecycle | The same suite covers Esc, repeated entry/exit, developer disable, run end/reset, scene removal, Dev teleport, forced storm, and actual PauseMenu Restart/Return to Title replacements. It checks that old camera/timer/cursor owners disappear and that the title menu retains its own valid cursor request. |
| Forward Plus rendering | **203 checks, 0 failures**, on an NVIDIA RTX 4050. **36 PNGs** cover the 24 destination/preset combinations, live/frozen grocery rain and VHS, and eight recording-panel sections in English/Tagalog at 175% UI scale. Rendered frozen-frame mean difference is approximately **0.000045**, below the 0.01 tolerance for temporal rendering; live frames change. |
| Windows exports | Both debug presets and the public release export succeed. The tagged internal debug EXE passes the full **979 checks, 0 failures** outside the source directory, including lazy HDR loading. Untagged debug and public release each pass **7 access-denial checks, 0 failures**, including direct camera/settings/effect calls. |
| Existing regressions | Dev Mode **47/47**, animals **229/229**, pickup guidance **38/38**, Milestone 2 unit subset **29/29**, animated NPCs **1,638/1,638**, cleanup **92/92**. The rendered cursor regression exits 0 without failed assertions. |
| Independent review | Source review of authorization, input ownership, cached visibility, temporary rendering, quality refresh and lifecycle cleanup found no remaining actionable issue after the inherited graphics-effect refresh fix. |

All preset captures were inspected for distinct outdoor lighting, dry weather, clear recording views and retained interior lighting/hidden sunlight. Large Tagalog recording toggles wrap at 175% instead of being clipped. Headless state and internal-package runs still emit the existing ObjectDB/resource-in-use shutdown diagnostics (10 retained resources in the final camera run); these are separate from passing assertions. The cleanup suite intentionally logs invalid-input warnings and its null-combination error. Final camera/render runs have no parser/script errors. No new dependency or autoload was added.

To repeat after synchronizing/importing a disposable project:

```powershell
$camera_engine = 'C:/Godot/Godot_v4.6.1-stable_win64.exe/Godot_v4.6.1-stable_win64_console.exe'
$camera_project = 'C:/Temp/bagyong-static-npcs-20261010/project'
$env:APPDATA = 'C:/Temp/bagyong-dev-camera-20261012/repeat/Roaming'
$env:LOCALAPPDATA = 'C:/Temp/bagyong-dev-camera-20261012/repeat/Local'
$env:BAGYONG_ISOLATED_SMOKE = 'C:/Temp/bagyong-dev-camera-20261012/repeat/Roaming/Godot/app_userdata/Software Festival 2026'
& $camera_engine --headless --path $camera_project res://game/tests/dev_camera_regression.tscn
& $camera_engine --path $camera_project res://game/tests/dev_camera_regression.tscn --windowed --resolution 1280x720 -- --visual-only
```

The test creates its own isolated preference fixture. Repeat package checks by changing **only the disposable copy's** main scene to this test, exporting `Windows Desktop Internal Dev` with `--export-debug`, and running its EXE with isolated user data outside the source project. Untagged `Windows Desktop` debug and release EXEs take the denied-access branch. Restore the disposable project/export configuration afterward; never distribute these test-entry packages.

Evidence is under `C:/Temp/bagyong-dev-camera-20261012`: `camera-final.log`, `visual-wrap.log`, the named existing-suite logs, `export-final-*.log`, and `package-final-*/stdout.log` / `stderr.log`. Final images are in `visual-wrap/Roaming/Godot/app_userdata/Software Festival 2026/recording_camera_*.png`.

**Manual recording acceptance remains open:** physical keyboard/mouse feel, cinematic smoothness, chosen trailer framing, audible ambience, recording performance and a natural gameplay playthrough. Scripted input and rendered captures do not replace this review. Fly-through recording can expose unfinished geometry or leave fixed rain volumes; the supplied 1K skies can soften at strong zoom.

## Walking animal start positions - 2026-10-12

The three walking animals now start at the positions saved by the user in the location scenes: Palengke cat **(-12.792954, 0.6178, -11.068410)**, Palengke dog **(6.687792, 0.6178, -8.193398)**, Tindahan dog **(8.115475, 0.500448, -7.689245)**. `AmbientAnimal` duplicates each parent-space route and translates it to the saved node position on entry, preventing the old first waypoint from resetting the editor placement. Initial rotations are retained. The stationary cats' user-edited transforms are preserved.

The Tindahan leg is shortened from 1.7 m to **1 m**, ending at X=9.115475, to clear Mang Nestor. The other two leg lengths/directions are retained. A new saved-placement regression reproduced the original reset for all three animals (**229 checks, 3 failures**) and the corrected controller passes **229 checks, 0 failures**, including relative route shape, player proximity, pause, travel and storm checks. Ground raycasts and five-phase skinned-body bounds along all three relocated routes pass **2,031 checks, 0 failures** against visible solids and NPC collision bodies. Hidden CSG player boundary walls are excluded from visual clearance because these decorative animals have no collision bodies; player boundaries are unchanged.

Checks use the same imported disposable project and isolated user data under `C:/Temp/bagyong-animal-starts-20261012`. [Updated previews and logs](../design_previews/ambient_animals/start_positions_20261012/README.md) record the new starts. Actual PlayerV2 cameras pass **12 captures, 0 visibility failures** for the three walkers across High/Performance and VHS off/on. The original 2026-10-11 captures below remain evidence of the initial integration. Manual keyboard play and standalone Windows execution were not rerun. Existing headless shutdown retention warnings persist.

## Ambient cats and dogs - 2026-10-11

The approved Blender exports are integrated as **five decorative animals**: three in Palengke (`grocery.tscn`) and two in Tindahan. Their fixed anchors/species match the approved plan. Coats and rest/movement timing vary through an instance-local RNG. The asset [workflow](../game/assets/animals/README.md) records the shared models, six coat atlases, 24 fps native imports and animation names.

Verification used Godot **4.6.1.stable.official.14d19694e** in the imported disposable project `C:/Temp/bagyong-static-npcs-20261010/project`, with separate APPDATA/LOCALAPPDATA and an exact `BAGYONG_ISOLATED_SMOKE` path for each run. Production user data, project settings and generated `.godot/` files were untouched.

| Check | Result |
| --- | --- |
| Focused `ambient_animal_regression.tscn` | **223 checks, 0 failures**. Full clip ranges/loop flags, finite animated bones/skins, loop and rest-transition seams, three independent/stable coats, unchanged gameplay RNG, exact populations, bounded authored routes, smooth turns, nearby-player pauses, actual SceneTree pause/resume, actual travel/storm cleanup and no ending animals. |
| Imported skin ground sampling | **16 clips, 634 poses** at 24 fps. No ground penetration; idle/sit/lie/sniff paws remain approximately 1 mm above the ground. Walking/running retain their authored raised-paw phases. This checks native CPU skinning, not just bone configuration. |
| Location ground and body clearance | **2,305 checks, 0 failures**. Ground raycasts every 0.5 m or less along routes; conservative skinned-body bounds at five phases per action and both route directions clear the actual solid geometry. The lowest 35 mm are omitted from body-box overlap tests to permit ground contact; separate full-mesh ground sampling covers that band. |
| Gait calibration | Imported low-paw backward velocities measure approximately **0.43 m/s cat walk, 0.60 m/s dog walk, 2.20 m/s dog run**. Runtime speeds are 0.43/0.59/2.20 m/s. Cat speed was corrected from its initial estimate; an endpoint tolerance that could exceed the speed cap was removed and the focused test rerun. |
| Actual gameplay cameras | **20 captures, 0 visibility failures** across all five animals, High/Performance and VHS off/on, using PlayerV2's actual camera volumes, normal lighting and HUD. VHS-off temporary silhouette masks verify visible rendered pixels. Animals are held at their starting anchors for repeatable comparisons while clips continue. Scene occlusion remains dependent on player position. |
| Native animation/motion review | **736 rendered frames**: three 20-second controlled route simulations plus every cat/dog action at its midpoint. Reviewed native sheets retain the approved deformation and grounding. Camera/HUD/lighting are native; controller/animation time is manually advanced and the player is locked for repeatable capture. |
| Existing regressions | Normal-flow Milestone 1 smoke **56/56**; animated NPC regression **1,638/1,638**; Ate Linda trade/shop **17/17**. |
| Independent review | No material controller/import/test issue found. The only location edits are the two model scene references, `AmbientAnimals` roots and their five children. |

For the focused check, import a disposable copy and use its path in `$animal_project`:

```powershell
$env:APPDATA = 'C:/Temp/bagyong-ambient-integration-20261011/regression-data/Roaming'
$env:LOCALAPPDATA = 'C:/Temp/bagyong-ambient-integration-20261011/regression-data/Local'
$env:BAGYONG_ISOLATED_SMOKE = 'C:/Temp/bagyong-ambient-integration-20261011/regression-data/Roaming/Godot/app_userdata/Software Festival 2026'
$animal_engine = 'C:/Godot/Godot_v4.6.1-stable_win64.exe/Godot_v4.6.1-stable_win64_console.exe'
$animal_project = 'C:/Temp/bagyong-static-npcs-20261010/project'
& $animal_engine --headless --path $animal_project res://game/tests/ambient_animal_regression.tscn
```

[Placement previews and evidence](../design_previews/ambient_animals/README.md) include native camera captures, logs, geometry results and disposable probes. Final runs have no parser/script errors or failed assertions. Existing ObjectDB/resource-in-use diagnostics remain in some headless shutdown logs and are separate from passing assertions. No new dependencies, autoloads, physics bodies or gameplay interactions were added. Manual keyboard play through every route and a standalone Windows build remain unchecked.

## Approved dialogue portrait integration â€” 2026-10-11

The approved v2 library installs 68 portraits for 17 NPCs and Player, binds all 64 active interaction lines plus two configured Linda fallback lines, and updates the shared player monologue portrait. `game/tests/dialogue_portrait_regression.tscn` loads the actual NPC scene sequences and exercises real DialogueUI in English and Tagalog, including expression switching, null-portrait hiding/recovery, localized speakers/text and player thinking. The manifest records the approved character expression roster and scene paths.

In the imported disposable project `C:/Temp/bagyong-portraits-20261011/project`, Godot 4.6.1 headless passed **686 checks, 0 failures**. The Forward Plus/Vulkan run on the RTX 4050 passed **691 checks, 0 failures**, including five saved real UI render captures with the default VHS/CRT overlay. All 68 imported textures were compared pixel-for-pixel against their PNG masters. The existing Ate Linda trade/shop regression passed **17 checks, 0 failures**. A separate read-only audit of the working project's 68 portrait cache textures also matched the masters. Tests used isolated APPDATA/LOCALAPPDATA and BAGYONG_ISOLATED_SMOKE; no gameplay user data or project settings were changed.

The first disposable import produced corrupted colors in 12 textures, and the initial simultaneous model-loading probe exhausted memory. Rebuilding only the disposable portrait cache and allowing model rendering resources to retire between scene loads resolved those probe failures. No source PNG edits or compression-setting changes were needed. Final render logs have no parser/script errors or failed assertions. Some headless runs retain the existing ObjectDB/resource-in-use shutdown diagnostics separately from passing assertions.

Independent comparison against exact pre-integration files verified all 66 approved bindings and preservation of every other scene/resource property, except the approved Lola speaker correction. All 68 runtime PNGs match approved master hashes. Gallery verification permits exactly the 19 approved resource changes against the 253-file pre-generation runtime baseline. Logs, captures and scope review are under `design_previews/dialogue_portraits_v2/metadata/integration_verification.md` and its linked files. Manual gameplay through every branch and a standalone Windows build remain unchecked.

## Separate merged localization CSV â€” 2026-10-11

The active table is `game/localization/game_text_merged.csv`; `game_text.csv` is the exact pre-rewrite working table retained as a backup. The merged CSV retains all 515 ordered IDs and metadata: 127 accepted rewrite rows and 388 rows with their pre-merge translations. Source lookup keeps the first translation for a repeated source, while context-specific UI uses its stable key. This prevents Lotto's `Close` alias and Linda's trade prompt alias from overwriting general source defaults. Both Windows presets include the active raw CSV, imported as Keep File, and exclude the backup.

Godot 4.6.1 checks used isolated user data and the existing imported disposable project. The all-row source/key/Label/BBCode probe passed **2,569 checks, 0 failures** in English and Tagalog. The Milestone 2 unit subset passed **29/29**, including the general Close, Lotto Close, and Linda trade aliases. The actual Ate Linda trade regression passed **17/17**, including language switching while the offer is open; Scratch Lotto passed **41/41**. CSV checks verify unique IDs, preserved source/order/metadata, and exact unchanged-row values against the restored backup. An independent read-only review found no material issue.

A minimal localization data PCK exported with the current Windows Desktop include/exclude settings was loaded from a separate project outside the source directory. Its packaged lookup check passed **2,061/2,061**: the active raw CSV exists with the source hash, the backup is absent, and all English/Tagalog key and general source lookups match. This verifies localization packing; it is not a full-game Windows EXE or presentation test. Full-game visual layout, manual gameplay, and standalone Windows acceptance remain separate. The full-project headless regressions retain the known ObjectDB/resource-in-use shutdown diagnostics, with no script/parser errors or failed assertions.

## NPC fidget frequency and dialogue head tracking â€” 2026-10-11

The approved follow-up shortens the 11 new NPCs' idle fidget wait from 8â€“14 to **4â€“7 seconds** and adds dialogue-only head tracking. A native `LookAtModifier3D` under each opted-in skeleton rotates only `Head`, toward PlayerV2's animated `spine.005` position plus a 0.1-unit face offset. Limits are **55 degrees left/right and 20 degrees up/down**, measured from Head's local rest orientation under its current neck pose. Symmetric native settings specify the total range, so they are configured as 110/40 degrees. Influence eases in/out over approximately 0.25 seconds; rear or very close targets restore authored motion. The six default NPCs, assets, location scenes, gameplay scripts, scales, and placements are unchanged.

Godot `4.6.1.stable.official.14d19694e` ran in the existing disposable project with fresh isolated user data under `C:\Temp\bagyong-npc-look-20261011`. The focused `static_npc_regression.tscn` passed **1,638 checks, 0 failures**, retaining the original clip, physics, dialogue, quest, donation, smoking, and pharmacy checks. New checks sample the actual final modified bone poses through `modification_processed`, rather than only asserting configured limits. They verify visible turns in all four directions, angular bounds, unchanged non-head bones, front/rear handling, eased return, rapid reopening, pause, storm cancellation, and choice/shop restoration for all 11 NPCs. Native imports remain unchanged.

A Forward Plus preview used the actual PlayerV2 head joint as a target in the four locations: **77 captured views** cover authored idle, both yaw limits, both pitch limits, a rear target, and restored idle for every NPC. All 11 sheets were reviewed; no new visible neck deformation, backward twist, or body rotation appeared. Two seven-second H.264 previews (MangNestor and MoneyBeggar) decode successfully. [Head tracking gallery](../design_previews/animated_npcs/head_tracking/README.md) includes the sheets, videos, and validation log. Inspection fill lighting, hidden player/HUD/CRT, displaced player targets, and disabled detection in the capture fixture do not change production files.

The independent controller review found no material issue. Baseline hashes preserve existing NPC scenes, model assets, default NPCs, shared scripts, and locations. Manual keyboard gameplay and packaged-build acceptance remain separate. Existing headless shutdown ObjectDB/retained-resource diagnostics persist despite passing checks; the graphical preview log has no script errors. The previous integration evidence below describes the earlier 8â€“14-second, authored-head-only checkpoint.

## Animated PSX NPC integration â€” 2026-10-11

Only the 11 new PSX NPC scenes opt into animated visuals and the scene-owned `PSXNPCAnimation` controller. The six original modeled NPCs and shared NPC scripts are unchanged. The [animated asset workflow and manual checklist](../_raw_assets/npc_assets/psx_animated/README.md) describe import settings, preserved height calibration, playback behavior, and the four locations to test. The static integration and height sections below remain historical checkpoint evidence.

Godot `4.6.1.stable.official.14d19694e` reused the imported disposable project at `C:\Temp\bagyong-static-npcs-20261010\project`. Current game files were synced before the checks. New GLBs were imported normally; their parameters were configured using Godot's `ConfigFile` API and the native scene importer regenerated its outputs. Import FPS is 24, suffix processing is off, animation optimization/compression are disabled, and the asset-specific import script preserves nearest interpolation, nearest textures, clip loop flags, and idle autoplay. No production `.godot/` files were edited.

Each run used its own isolated `APPDATA`, `LOCALAPPDATA`, and exact forward-slash `BAGYONG_ISOLATED_SMOKE` path under `C:\Temp\bagyong-animated-npcs-20261011`. To repeat the focused checks after importing a disposable copy:

```powershell
$env:APPDATA = 'C:\Temp\bagyong-animated-npcs-20261011\regression-data\Roaming'
$env:LOCALAPPDATA = 'C:\Temp\bagyong-animated-npcs-20261011\regression-data\Local'
$env:BAGYONG_ISOLATED_SMOKE = 'C:/Temp/bagyong-animated-npcs-20261011/regression-data/Roaming/Godot/app_userdata/Software Festival 2026'
$engine = 'C:\Godot\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe'
$project = 'C:\Temp\bagyong-static-npcs-20261010\project'
& $engine --headless --path $project res://game/tests/static_npc_regression.tscn

$env:STATIC_NPC_CAPTURE_DIR = 'C:/Temp/bagyong-animated-npcs-20261011/all_clip_captures'
& $engine --path $project --windowed --resolution 1280x720 res://game/tests/static_npc_regression.tscn -- --visual-only
```

The existing `static_npc_regression.tscn` name is retained for command compatibility; its checks now validate animated models.

| Check | Result |
| --- | --- |
| Configured native import | Exit 0, with no logged script/parser/import errors. All 11 production GLBs match their corrected source exports byte-for-byte. |
| Focused animation/gameplay regression | **1,267 checks, 0 failures**. All 11 rigs, skins, nearest materials, required clips, loop flags, and stepped tracks load. Each authored clip is sampled at 24 fps for fixed roots/feet/ground props and valid skin data. |
| Responsiveness and lifecycle | Actual `npc.interact()` calls trigger entry, loop, and exit. Typing skip and next-line signals do not restart playback. Reopening during exit and talking during fidgets/reactions interrupt promptly. Choices/shop suppress fidgets. Donation decline, insufficient cash, success, queued/interrupted gratitude, relieved idle, and reentry are covered. Actual SceneTree pause, storm suspension, and removal during playback are checked. |
| Preserved gameplay | A CharacterBody3D fixture enters/leaves each real Area3D through physics. Existing dialogue, Nestor quest cash/chicken/tarp/sukli guards, donation, smoker's one-time time cost, and pharmacy shopping checks pass. |
| Independent source/import geometry audit | **10,803 checks, 0 failures** across **69 clips and 4,674 authored poses/STEP holds**. Mesh vertices/counts, named weights, bind matrices, and skin deformation match the corrected exports. Held props retain authored hand weighting; roots, feet, and ground props stay fixed. Approved scaled idle heights and grounding differ by less than 0.000001 scene units. |
| Responsive action previews | All 11 labeled H.264 MP4s decode successfully. Real dialogue calls and the controller's fidget scheduler drive each idle/fidget/conversation/exit/idle sequence in the four actual locations. Reviewed sheets show no new visible deformation or prop-contact issue. |
| Every clip in three views | **207 captures, 0 failures**: all 69 clips at their midpoint from front, side, and elevated views in the four actual locations. All 11 labeled sheets were independently reviewed; no new visible deformation, prop separation, ground-prop drift, or wall/counter intersection was found. |
| Existing regressions | Milestone 2 unit subset: **26 checks, 0 failures**. Headless normal-flow Milestone 1 smoke: **56 checks, 0 failures**. |
| Independent preservation review | Reversing only the approved visual/controller edits and Beggar offset reproduces all 11 scene baseline hashes. Other protected baseline files, excluded NPCs/assets, shared scripts, static GLBs, locations, corrected source exports, and polished Blender file remain unchanged. Existing unrelated dirty work is retained. |

Durable action videos and sheets are in [the animated review folder](../design_previews/animated_npcs/). The [all-clip gallery](../design_previews/animated_npcs/all_clips/README.md) contains 11 labeled sheets; copied geometry reports and final regression/capture logs are in `design_previews/animated_npcs/validation/`. Full-resolution captures, baseline hashes, and disposable probes remain under `C:\Temp\bagyong-animated-npcs-20261011`. Responsive videos use controlled animation time at 12 fps and a shortened fidget wait; labeled inspection lighting and hidden dialogue/shop overlays improve model visibility only in the preview fixture. Production lighting and UI are unchanged.

The checks establish scripted physics/dialogue responsiveness and import fidelity. They do not establish manual keyboard/mouse gameplay, actual PlayerV2 HUD acceptance, audible quality, or a packaged build. Geometry equivalence preserves authored prop contact but is not an exhaustive surface-intersection proof. PanicBuyer's existing foreground box partly obscures a shoe. Some probes still report known ObjectDB/retained-resource diagnostics at shutdown despite exit 0 and passing checks; these are separate from script/parser failures.

## Static PSX NPC integration â€” 2026-10-10

The 11 new NPCs use static meshes baked from the corrected `idle_loop`, frame 1. The asset [workflow](../_raw_assets/npc_assets/psx_static/README.md) records the source, export constraints, model mapping, and PharmaDude's visual grounding correction. No gameplay scripts or location scenes changed in this integration.

Godot `4.6.1.stable.official.14d19694e` imported a disposable copy at `C:\Temp\bagyong-static-npcs-20261010\project`; `.git` and `.godot` were excluded from the copy. Test runs used isolated `APPDATA` and `LOCALAPPDATA`. The initial fresh import reported dependency/cache errors before assets were available; a second complete import exited 0 with no parser/import errors or warnings. No production `.godot/` files were edited.

To repeat the focused check after importing a disposable copy:

```powershell
$env:APPDATA = 'C:\Temp\bagyong-static-npcs-20261010\userdata\Roaming'
$env:LOCALAPPDATA = 'C:\Temp\bagyong-static-npcs-20261010\userdata\Local'
# Match OS.get_user_data_dir() exactly, including forward slashes.
$env:BAGYONG_ISOLATED_SMOKE = 'C:/Temp/bagyong-static-npcs-20261010/userdata/Roaming/Godot/app_userdata/Software Festival 2026'
$engine = 'C:\Godot\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe'
$project = 'C:\Temp\bagyong-static-npcs-20261010\project'
& $engine --headless --path $project res://game/tests/static_npc_regression.tscn

$env:STATIC_NPC_CAPTURE_DIR = 'C:/Temp/bagyong-static-npcs-20261010/captures'
& $engine --path $project --windowed --resolution 1280x720 res://game/tests/static_npc_regression.tscn -- --visual-only
```

| Check | Result |
| --- | --- |
| Independent GLB audit | 11/11: expected source body/prop components, embedded textures, nearest samplers, grounded Y=0 bounds, and no animations, skins, joints, cameras, lights, or collision nodes. Standing heights are 1.597â€“1.800 m; MoneyBeggar remains seated at 0.9276 m. |
| `static_npc_regression.tscn` | Final run: 339 checks, 0 failures. All 11 scenes instantiate with unskinned static meshes and nearest imported materials. A CharacterBody3D fixture enters and leaves each actual Area3D through physics, exercising detection callbacks and prompt strings. |
| Interaction coverage | Story dialogue completes; Nestor gives quest cash, exchanges chicken for tarp with a full backpack, gives sukli, and guards duplicate rewards. Beggar donation and SmokeBreakNPC's 20-minute choice apply once. PharmaDude opens/closes the pharmacy shop. Visual transforms remain static through every interaction. |
| Four real location scenes | Final Forward Plus run: 33 captures, 0 save failures. Front, side, and elevated views of every target were inspected for scale, facing, feet, hands, props, and nearby geometry. Close cameras avoid entering foreground shop roofs/walls. |
| PharmaDude grounding | Visual child offset `(0, -0.3448443, 0)` places feet on the visible platform at world Y=0.9617674. Four model-bound corner probes agree on the platform height. Body clears the back wall by 0.486 m and the side wall by 1.391 m; held props remain clear. Root, Area3D, and disabled collider are preserved. |
| Existing Milestone 2 unit subset | 26 checks, 0 failures. |
| Existing normal-flow Milestone 1 smoke | 56 checks, 0 failures. |
| Preservation review | Ten scenes have only model resource path substitutions relative to the dirty baseline. PharmaDude has only visual additions. Excluded NPCs/assets, shared Mixamo, production scripts, four locations, source Blender file, and 11 animated exports retain baseline hashes. Existing unrelated work is preserved. |

Logs, baseline snapshots, GLB audit, and independent review are in `C:\Temp\bagyong-static-npcs-20261010`. Labeled sheets are in `design_previews/static_npc_integration/`; all 33 full-resolution location captures are also saved in the Blender package at `animated/static_pose_review/game_locations/`. The project still renders its 1920Ã—1080 logical canvas in a 1280Ã—720 window.

The final import and runtime logs contain no script/parser errors or failed checks. Known ObjectDB/resource-in-use diagnostics remain at shutdown in the headless regressions. These checks establish scripted scene/physics interaction and rendered appearance; they do not establish physical keyboard/mouse acceptance, audible quality, a natural full-day playthrough, or a packaged Windows build. The player fixture checks callback/prompt state rather than the actual PlayerV2 HUD. Existing small root-to-floor margins remain for the ten replacement scenes because their transforms were preserved. No animation playback was integrated.

### NPC height follow-up â€” 2026-10-10

The 11 model children now use uniform scales calibrated against PlayerV2's visible idle height of **2.04209747 scene units**. The measurement evaluates actual skinned player vertices at `Idle/mixamo_com`, frame 0; NPC body bounds exclude props. Male models measure 98â€“100% of player height and female models 92â€“94%. MoneyBeggar remains seated and uses his source standing body height as the scale reference. Exact scales and measured heights are in the [asset workflow](../_raw_assets/npc_assets/psx_static/README.md#height-calibration).

Godot 4.6.1 reused the imported disposable project above with the revised scenes and the current pharmacy placement. Isolated `APPDATA`, `LOCALAPPDATA`, and matching `BAGYONG_ISOLATED_SMOKE` were under `C:\Temp\bagyong-npc-height-20261010\regression-data`. The focused `static_npc_regression.tscn` passed **339 checks, 0 failures**, including physics entry/exit, dialogue, quests, donation, smoke choice, pharmacy shopping, and static pose persistence. All 11 measured height ratios match the intended values within 0.00001; model grounding offsets remain unchanged.

Forward Plus rendered **22 before/after captures** across the four actual locations. A frozen PlayerV2 idle model stands beside each NPC on the same foot plane with matching framing per pair. Review found the intended height differences, retained seated proportions and held-prop contact, and no new visible wall intersections. PharmaDude's feet remain at Y=0.961767; a platform support ray measured Y=0.961951 (approximately 0.18 mm difference). PanicBuyer's existing foreground box partly hides one shoe and bag. The comparison fixture demonstrates relative model height; it does not simulate normal player movement around furniture.

Labeled sheets and individual captures are in [the height review folder](../design_previews/static_npc_height/). Measurement, regression, and visual logs remain in `C:\Temp\bagyong-npc-height-20261010`. An independent review and baseline hashes confirm that only the 11 model-child scales changed in NPC scenes: roots, visual wrappers, Area3Ds, colliders, scripts, dialogue, locations, PlayerV2, excluded NPCs, and protected GLBs remain unchanged. `git diff --check` passed. Existing unrelated edits were retained.

No animations, gameplay changes, asset re-exports, physical keyboard/mouse playthrough, actual HUD acceptance, or packaged-build checks were performed for this follow-up.

## Current strategy and evidence

The initial documentation audit found no automated tests. Focused no-framework checks now live in `game/tests/cleanup_regression.tscn` and `game/tests/milestone1_smoke.tscn`; no third-party test framework or CI test workflow is configured. `game/tests/sandbox/test_world/test_world.tscn`, `test_world_2.tscn` and their scene resources are exploratory 3D content, not GUT/GdUnit/custom automated tests. Do not report them as a passing suite.

Verification should distinguish five kinds of evidence:

| Kind | What it establishes |
| --- | --- |
| Static inspection | Paths, node wiring, code branches and configuration as written |
| Import/script validation | Godot can import/parse the checked content; not proof of successful gameplay |
| Scene-level checks | A specific scene instantiates and its relevant nodes/controls operate |
| Gameplay smoke test | Normal startup, preparation, travel and ending paths work together |
| Targeted regression | The changed behavior and nearby failure cases remain correct |

The documentation audit on 2026-09-16â€“17 used static inspection. The installed engine version was verified as `4.6.1.stable.official.14d19694e` and Git LFS as 3.7.1. No editor import, headless project execution, export or gameplay test was run because the task prohibited writes to import/cache/generated files. Runtime quality and successful export remain **Unknown / Needs verification**.

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

Omit `--headless` to run with rendering. The graphical run saves `milestone1_home.png`, `milestone1_tindahan.png`, `milestone1_shop.png` and `milestone1_ending.png` in the isolated user-data directory. The test uses normal engine timing, skips the intro through its input handler, dismisses the actual tutorial, advances dialogue, buys medicine from Ate Linda and an item from hardware, completes the medicine task, restarts, forces storm arrival, verifies that the score waits for a continue press, submits an isolated score and starts another run. It also reproduces detached-checklist and immediately-freed-label callbacks. Expect several minutes for the normal ending sequence.

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
- [ ] Use End Day on one run and natural timeout on another. Confirm ending beats reflect need completion; read the score and typhoon message before pressing continue, then save a named score and return to menu.
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
| Localization | Englishâ†”Tagalog changes in menu and gameplay, dynamic dialogue/item/shop/objective text, `%` placeholders and BBCode, long text/clipping; do not assume automatic node traversal catches later text assignments |
| Visuals | High/Balanced/Performance, VHS on/off, UI scale extremes, different window/aspect sizes, scene change after settings adjustment, camera DOF and light/shadow changes |
| Audio | Music/ambience transitions, overlapping SFX, dialogue voice ending/skipping, storm progression and grocery layer, pause/resume, volume persistence and Reset |
| Ending/leaderboard | Six need-dependent shots; result tiers at 0â€“1, 2â€“3, 4â€“5 and 6 needs; empty/whitespace/name-limit input; early-finish time snapshot; difficulty multiplier; score ties; reload and two-step clear |
| Persistence/export | Quit/relaunch settings and leaderboard; absent/malformed files in isolated test data; exported build includes CSV/assets and can complete the normal application flow |

### Existing edge cases worth preserving in reports

- `InventoryManager.MAX_INVENTORY_SIZE` is **7**. Slot construction, selection and wheel wrap use this capacity. Key 8 explicitly aliases the last slot. Exercise both wrapping directions and the alias before changing controls.
- `TutorialModal` suppression is a static session flag; it is not written to settings. Verify it separately from disk persistence.
- `AudioSettingsPanel` Reset resets audio and visual settings, not language. UI scale is 100â€“175%, default 140%; quality defaults High and VHS defaults enabled.
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

### Documentation audit result â€” 2026-09-17

All eight requested guides were reviewed against implementation and each other. An independent review caught and corrected an erroneous PlayerV2 jump test and the AudioManager scene-folder description. Other corrected historical assumptions include Act1 startup/timer behavior, HUD registration, inventory capacity and plans presented as completed systems.

The local-link check examined 46 links with no missing targets; the controls anchors were also checked. A scan of 87 code-formatted repository paths found only the two explicitly documented missing scene paths (each mentioned in architecture and roadmap). `git diff --check` passed. The changed-file inventory contained nine Markdown files only: the eight requested guides plus a historical-status notice added to `PROJECT_HANDOFF.md`. No gameplay, scene, resource, asset, shader, addon or project-setting edits were made. No runtime verification is implied by these checks.

### Conservative cleanup validation â€” 2026-09-17

The documentation was checkpointed locally as `ab25f2a` on `dev` before implementation. No push was performed. Validation used Godot `4.6.1.stable.official.14d19694e` in a disposable copy with isolated runtime user data.

- A fresh-cache import exited 1 during resource import before any production edits. The log included initial UID/font-cache errors and ended during import without a clear final cause; clean-checkout import remains unresolved.
- Seeding the disposable copy with the existing `.godot` cache allowed the baseline editor/import pass to exit 0 without script/parse errors. This does not establish fresh-import success.
- Baseline headless samples loaded intro, menu, home, hardware, pharmacy, grocery and ending. Tindahan emitted missing-greybox and vanished-node recovery errors. Forced exits reported leaked objects/resources before changes.
- The focused regression scene passed **92 assertions with zero failures**. The deliberate null-result diagnostic and existing shutdown resource warnings are separate from assertion failures.
- Independent review found no actionable defects in the changed production scripts and focused tests. Existing gameplay scenes, resources, assets, project settings, Input Map and save formats were not edited.
- A disposable, script-driven integration smoke passed intro skip â†’ menu â†’ home, map/backpack clock continuity, hardware travel and return spawn, pause, restart into a second home instance with a fresh clock, and forced storm â†’ ending. It used accelerated time and suppressed the startup tutorial through its existing session API; it does not verify normal timing or tutorial interaction.
- The same smoke passed at checkpoint `ab25f2a` and with the cleanup. Both emitted `PreparationChecklistHUD._schedule_checklist_resize` line 249's null `get_tree()` error during restart, plus shutdown resource warnings. These are pre-existing lifecycle findings, deliberately outside this pass.

No manual visual/audio playthrough, complete dialogue/task interaction sequence, Nestor reward turn-in or exported-build test was performed. The focused window and quest tests establish state-helper behavior only. Existing missing-resource and lifecycle issues are not claimed fixed by this cleanup.

Final recheck on 2026-09-23 synchronized all changed scripts and the regression scene into the disposable copy. Godot 4.6.1 editor/import exited 0 with no script/parse errors, but was not clean: editor cache/settings access, certificate-store, empty-mesh and a gravel normal-texture load error were logged. These asset/environment diagnostics were not repaired or conclusively classified by this script cleanup. The regression scene then exited 0 with **92 checks, 0 failures**, with expected invalid-input diagnostics and shutdown resource warnings. `git diff --check` passed. Implementation remains uncommitted; the rollback point is still `ab25f2a`.

### Milestone 1 implementation and verification â€” 2026-09-24

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

### Milestone 2 implementation and verification â€” 2026-09-25

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
- Final Forward Plus visual run on the RTX 4050: **8 scene/layout checks, 0 failures**, exit 0. Generated 16 map/shop/quest/backpack captures across English/Tagalog and 100%/175% UI scale. Representative captures were inspected: quest prompts translate, action labels remain English as authored, and long backpack/hotbar names wrap. The 1280Ã—720 window renders the configured 1920Ã—1080 canvas; this is not a resolution matrix.
- CSV placeholder audit: **412 rows, 0 mismatches** between source, English and Tagalog format placeholders.
- Editor/import in the existing disposable copy completed without logged errors/warnings. This reused its imported asset cache; no fresh-import claim is made for this milestone.
- Final M2/M1/visual runtime logs contain no script errors, freed-capture errors or failed assertions. Existing ObjectDB shutdown-leak warnings remain; cleanup also reports retained resources at shutdown. Earlier intermediate runs exposed and corrected a freed objective-row callback and test/type issues; they are not counted as passing verification.
- Independent Caveman/Ponytail review identified the repeat-Interact-over-choice pause overlap, which was fixed and regression-tested. Its final review found no further concrete defects. Final diff/whitespace review passed.

Logs are retained under `%TEMP%`: `bagyong-m2-before.txt`, `bagyong-m2-final.txt`, `bagyong-m2-cleanup.txt`, `bagyong-m2-m1.txt`, `bagyong-m2-visual-final.txt`, and `bagyong-m2-import.txt`. Always inspect errors alongside counts: a GDScript error can abort one coroutine without making Godot exit nonzero.

Limits: tests call production APIs directly and force deadline fixtures; they do not establish manual movement/proximity/audio quality, every optional quest/ending, a full natural-day playthrough or export readiness. The localization audit fixes five choice prompts and dynamic assignment; intro narration remains incompletely translated. Existing authored button translations are preserved without adding a blanket Button exemption. No broad reset consolidation, engine upgrade or asset rewrite was performed.

### Milestone 3 distribution and presentation â€” 2026-09-26 (partial)

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
| High | On | 100% | 1280Ã—720 | 333 | 110.93 | 9.94 |
| High | Off | 175% | 1920Ã—1080 | 231 | 77.00 | 13.65 |
| Balanced | On | 175% | 1280Ã—800 | 374 | 124.46 | 8.66 |
| Balanced | Off | 100% | 1920Ã—1080 | 259 | 86.22 | 12.27 |
| Performance | On | 100% | 1280Ã—800 | 402 | 133.91 | 8.06 |
| Performance | Off | 175% | 1280Ã—720 | 431 | 143.62 | 7.42 |

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

### Standalone Windows retry â€” 2026-09-27 (blocked)

The final candidate above was retried from outside the source tree with isolated `APPDATA`/`LOCALAPPDATA`. Its SHA-256 still matches `58CA5D918D0AC495DC133AC3D8C89B884F8B33FBBF7EAE32C629008A60D96A1D`. Windows rejected process creation with `An Application Control policy has blocked this file.` No game runtime log was produced.

Windows Code Integrity events 3033 and 3077 identify this exact executable as failing signing-level/policy requirements; event 3118 records a Smart App Control block at 11:14:57 local time. Evidence is saved under `C:\Users\john2\AppData\Local\Temp\bagyong-m3-20260927` in `standalone-launch-error.txt` and `code-integrity-events.json`. Security policy and the executable were not modified.

Packaged gameplay, localization, audible audio, and packaged storm/travel performance remain **unverified**, not failed gameplay tests. Existing source-runtime measurements do not close this gate. Continue on a Windows machine whose security policy permits the candidate, or through an approved signing/distribution process. Reuse the isolated Milestone 1 gameplay smoke and Milestone 2 localization checks; separately inspect/listen to the normal packaged UI/audio and measure real travel transitions plus outdoor heavy-storm frame times. Report transition latency separately from steady-state FPS/p95, and retain the single-machine hardware-claim limit. Milestone 3 remains incomplete.

### Source-runtime storm/travel profiling â€” 2026-09-27

A profiling runner in the existing disposable project at `C:\Users\john2\AppData\Local\Temp\bagyong-m3-20260926\project\game\tests\storm_travel_performance.gd` measured high quality, VHS on, 1280Ã—720, Forward Plus on the same i7-13620H/RTX 4050 Laptop GPU. It used a two-second warmup and three-second fixed-camera sample per scene, paused the game clock, and used production `SceneManager.travel_to()` for travel. Grocery was sampled at minute 315; storm home at 600; hardware at 615. Two passes exited 0 with seven recorded cases each and no script errors. Logs and JSON reports are under `C:\Users\john2\AppData\Local\Temp\bagyong-performance-20260927`.

| Fixed scene | Pass 1 FPS / p95 ms | Pass 2 FPS / p95 ms |
| --- | ---: | ---: |
| Home, minute 0 | 120.35 / 8.75 | 118.76 / 8.93 |
| Grocery, minute 315 | 125.37 / 9.00 | 119.17 / 9.41 |
| Home, minute 600 | 127.04 / 8.36 | 126.50 / 8.53 |
| Hardware, minute 615 | 133.91 / 7.97 | 121.46 / 9.04 |

Travel completed in 1.35â€“1.79 seconds. Worst frames were 165â€“665 ms across the two passes. The second pass recorded every frame over 100 ms at overlay alpha 1.0, during the black transition. `SceneManager._change_scene()` calls `change_scene_to_file()` during that fade, consistent with scene loading as the source of the stalls. The fixed views show no measured steady-frame problem on this GPU. Prioritize scene-loading work only if black-screen travel latency is unacceptable in manual testing; do not change lighting, rain, VoxelGI or player loops based on these samples.

This runner reused an imported disposable copy and did not execute the blocked standalone EXE. It did not move the camera/player, control thermals or background load, record GPU execution time, cover every location, or test weaker hardware. These results do not establish minimum requirements or complete Milestone 3.

### Cursor, UI and branding pass â€” 2026-10-02

The pre-change checkpoint is local commit `6880587`. The UI implementation was checked while uncommitted with Godot `4.6.1.stable.official.14d19694e` in a disposable project copy (`%LOCALAPPDATA%\Temp\bagyong-ui-check-22a13371c34642c8a4240afa61424ded`). Test scores/settings used isolated `APPDATA` and `LOCALAPPDATA` under `C:\Temp\bbui`. Source files were synced into the copy before the final import and runs; visual probes that are not listed below as repository scenes exist only in that copy. Logs are under `C:\Temp\bbui\final-*.txt`.

| Check | Result |
| --- | --- |
| Editor import | Exit 0; no logged parser/import errors or warnings. It reused the disposable copy's prior import cache. |
| `cursor_state_regression.tscn` | Graphical run exit 0; owner/idempotence assertions passed. Headless mode cannot retain captured mouse mode, so this scene must be run graphically. |
| Disposable cursor integration | 20 checks, 0 failures: map/backpack swaps, pause over map/shop/quest/pickup UI, nested tutorial Escape and scene exit. |
| `score_calculation_regression.tscn` | 4 checks, 0 failures; displayed calculation matches the persisted score. |
| `cleanup_regression.tscn` | 92 checks, 0 failures; its null-combination error is intentional. |
| `milestone2_regression.tscn` | 97 checks, 0 failures. |
| `milestone1_smoke.tscn` | 54 checks, 0 failures. |
| Disposable rendered map/shop/quest/backpack matrix | 24 checks, 0 failures at each of 1280Ã—720, 1920Ã—1080 and 2560Ã—1080, across English/Tagalog and 100%, 140%, 175% UI scale. The 1280 window scales the 1920Ã—1080 logical canvas; the wide window expands the viewport to 2560Ã—1080. |
| Additional rendered probes | Reopened leaderboard Close button remained enabled; localized task-complete notice passed 12 checks/0 failures; six pickup cue attachments and active/hidden states passed 9 checks/0 failures. Menu, settings, tutorial, dialogue, ending, leaderboard, splash and cue captures were inspected. Splash image alpha reached 1 and returned to 0. |
| Quality/VHS comparison | Balanced with VHS on and Performance with VHS off each passed 8 rendered map/shop/quest/backpack checks at 140% scale. High with VHS on was included in the main matrix. |

The final runtime logs contained no script/parser errors or failed assertions. Existing shutdown ObjectDB/resource-retention diagnostics remain. These scripted and rendered checks do not establish manual movement/proximity, audible hover/focus quality, every ending, physical-screen readability on other displays, or a packaged build. The earlier standalone Windows acceptance block remains separate.

### Screenshot-driven UI follow-up â€” 2026-10-02

The supplied studio PNG's final pixel column is white; the splash now excludes that column at render time and has no separate "developed by" label. A rendered fade probe confirmed the artwork reaches full opacity and fades out without the white edge. Menu captures at 1920Ã—1080 show the larger title centered above its buttons with a shorter gap.

In the same disposable Godot 4.6.1 copy, a focused rendered probe passed at 1920Ã—1080 and a 1280Ã—720 window (1920Ã—1080 logical canvas). At 100%/140%/175% UI scale, empty inventory help had 22/33/45 logical pixels between its instruction and discard prompt, and the pickup description measured 18/25/32px. Changing scale while the pickup prompt was visible rebuilt it without losing cursor ownership. At 140% global scale, dialogue renders at 125%; dialogue and monologue captures at 140% and 175% stayed clear of the scaled bottom-left controls. The long Tagalog monologue fitted without scrolling after enabling content sizing. The disposable copy's graphical Milestone 2 UI probe passed 24 checks with no failures after these edits. Final editor import exited 0 with no parser/import warnings or errors. Logs are `C:\Temp\bbui\tweak-*.txt`; the focused probe and its screenshots exist only in the disposable project/user-data copy. Existing shutdown resource-retention warnings remain. Manual play and an exported build were not tested in this follow-up.

### Pharmacy Lottohan â€” 2026-10-04

Run `game/tests/scratch_lotto_regression.tscn` in an imported disposable copy with isolated `APPDATA`, `LOCALAPPDATA` and `BAGYONG_ISOLATED_SMOKE` pointing to Godot's isolated user-data directory. Use `--headless` for the rules and cash/lifecycle checks. Use `--windowed --resolution 1280x720 -- --visual-only` for the Forward Plus visual probe; it resizes the window to 1280Ã—720 and 1920Ã—1080, captures English and Tagalog at 100% and 175% UI scale with VHS enabled, and checks counter overlap, movement lock, cursor, map/backpack conflicts and Escape behavior. The project uses a 1920Ã—1080 logical canvas at both window sizes; the probe saves copies scaled to the physical window size for review.

The focused checks cover all eight fruit prizes in both rows, two winning rows, weighted seeded draws and calculated odds, insufficient cash, repeated buys/reveals, Buy Again, clock progression, storm purchase guard, one-time payout on close/storm and scene exit. Rendered captures were also inspected for legibility. These source-runtime checks do not replace a manual walk-up or packaged Windows acceptance.

Godot 4.6.1 imported the three supplied PNGs and loaded the pharmacy scene in the disposable copy. Final focused run: **41 checks, 0 failures**. Final Forward Plus visual run: **23 checks, 0 failures**; eight language/scale/resolution captures plus the revealed result were inspected, including the shortened Tagalog footer. Existing ObjectDB/resource-retention warnings appeared at shutdown. This pass did not run a manual walk-up or an exported executable.

### Dev Mode verification â€” 2026-10-04

Use isolated `APPDATA` and `LOCALAPPDATA` for any source or packaged test that reaches the leaderboard. Run `game/tests/dev_mode_regression.tscn` in Godot 4.6.1 for authorization, cash, timer ownership/rewind, storm thresholds, teleport, and unranked score guards. Check the log for script errors as well as the test summary.

Manually type `HELLOWORLD` at the idle main menu; partial/wrong sequences, delays over five seconds, active overlays and focused text fields must not unlock. The unlocked Settings toggle should appear in editor or tagged internal debug builds only. Enabling it should reveal the right-side Dev Mode panel in Pause, and toggling it off should release a developer clock pause while leaving the current run unranked. Check Escape/cursor behavior, English and Tagalog, 100% and 175% UI scale, and 1280Ã—720 and 1920Ã—1080 windows. Restart and return to title should keep session access; a new process should start locked.

Export the tagged `Windows Desktop Internal Dev` preset with `--export-debug`, the ordinary `Windows Desktop` preset with `--export-debug`, and the public preset with `--export-release`. Test outside the source tree with isolated user data. The internal build must allow the sequence and commands; the other two must not. In a disposable release test package, invoke the DevMode command API directly and confirm cash, time and location stay unchanged. Also try forged Dev Mode values in saved settings; they must not grant access. If Windows Application Control blocks the EXE, report packaged-runtime acceptance as unverified and retry only through an authorized machine or approved signing/distribution path.

Implementation check on 2026-10-04 used Godot `4.6.1.stable.official.14d19694e`, a disposable project copy at `C:\Temp\bagyong-devmode-check-20261004-01`, and isolated `APPDATA`/`LOCALAPPDATA`. The final import and all three normal exports exited successfully with no script/parser errors. Each export manifest includes the raw `game_text.csv`. Logs are under `C:\Temp\bagyong-devmode-*.log`.

| Check | Result |
| --- | --- |
| `dev_mode_regression.tscn` in the editor runtime | 47 checks, 0 failures, including focused input, overlay clearing, clock rewind and pause ownership, closed-location teleport, and score rejection after disabling Dev Mode. |
| Existing regressions | Cleanup 92, Milestone 1 54, Milestone 2 97, score calculation 4, and scratch lotto 41 checks, all with 0 failures. The graphical cursor ownership regression exited 0. Cleanup's null-combination error is intentional. |
| Rendered UI probe in the disposable copy | 15 checks, 0 failures. Menu Settings and pause Dev panel were captured and visually inspected in English and Tagalog at 100%/175% scale and 1280Ã—720/1920Ã—1080. The probe exercised the Settings toggle, pause ownership, and the Escape handler. This was scripted input and screenshot review, not a manual playthrough. |
| Disposable run-lifecycle probe | 9 checks, 0 failures. Return to title kept unlock/toggle and cleared per-run state; a new run and Restart kept the toggle and started unranked. |
| Normal packaged builds | Internal debug and ordinary debug started headlessly and exited 0. The public release started outside the source tree with isolated user data; its engine log contained no script/parser errors. |
| Final ordinary debug verification package | 10 checks, 0 failures: no Dev Mode UI or command access. |
| Final public release verification package | 10 checks, 0 failures: direct unlock, cash, timer, clock-reset, teleport, and guarded travel calls leave state unchanged. |
| Internal debug verification package | Before the final availability hardening and expanded tests, it passed 43 checks with no failures. A second process started locked with forged `dev_mode` keys in saved settings. The rebuilt final verification EXE was blocked before startup by Windows Code Integrity (`CreateProcess failed, error 4551`, event 3077), so its final packaged command flow remains unverified. Its normal final internal debug build did start. |

Existing ObjectDB/resource-retention diagnostics still appear at process shutdown. Packaged UI navigation by physical mouse/keyboard, and the final internal debug command flow, still need acceptance on an authorized machine or through an approved signing path. No Windows policy was changed for this check.

### Pause layout and Lottohan balance â€” 2026-10-04

In a disposable Godot 4.6.1 copy with isolated user data, the scratch lotto regression passed **41 checks** and its Forward Plus visual probe passed **23 checks** at 1280Ã—720 and 1920Ã—1080, English/Tagalog and 100%/175% UI scale. The updated weights give an 8.6079296% chance of at least one matching row and â‚±22.13084 expected payout per â‚±50 ticket. The Dev Mode regression still passed **47 checks**.

A disposable pause-layout probe passed at 1280Ã—720 with **0 failures**. It checked that the idle navigation, Settings card and Dev Mode card are centered; tabs overlap each open card by 12 logical pixels; and Resume closes the menu and unpauses. Captures were visually inspected in both languages at 100% and 175% scale. This was scripted scene interaction and image review, not a physical mouse/keyboard playthrough or packaged build.

### Illustrated map UI â€” 2026-10-05

Run `game/tests/map_ui_regression.tscn` with Godot 4.6.1 in an imported disposable project copy. Set isolated `APPDATA` and `LOCALAPPDATA`, and set `BAGYONG_ISOLATED_SMOKE` to that copy's Godot `user://` directory. The headless run checks the live destinations, End the Day, M action, quoted travel cost, hover, current/danger/closed states, and early-end score snapshot. A Forward Plus run with `-- --visual-only` also saves English/Tagalog captures under isolated `user://`. Add `--wide` to render the map in a 2560 Ã— 1080 offscreen viewport; this works even when the physical display is narrower. Inspect logs for script errors and shutdown diagnostics independently of assertion counts.

The final focused headless run passed **17 checks, 0 failures**. The Forward Plus visual run passed **22 checks, 0 failures**; logical-viewport map captures from runs requesting 1280 Ã— 720 and 1920 Ã— 1080 windows were inspected. The existing Milestone 2 unit subset passed **26 checks, 0 failures**; its Forward Plus integration visual subset passed **16 checks, 0 failures** across English/Tagalog and 100%/175% UI scale. Godot imported the new map assets successfully. The focused run still printed ObjectDB/resource-in-use shutdown warnings despite exit 0; the Milestone 2 visual subset did not print those warnings.

An initial attempt to resize the native window was capped at the machine's 1920 Ã— 1080 display and failed the width assertion. The corrected offscreen 2560 Ã— 1080 Forward Plus run passed **24 checks, 0 failures**; its initial and confirmation captures were inspected and show the paper centered with readable side margins and controls. This verifies rendered ultrawide layout, not physical ultrawide monitor behavior. The focused offscreen run still printed ObjectDB and resource-in-use shutdown diagnostics. Manual mouse/keyboard travel, natural clock progression through a full run, audible feedback, VHS-off comparison, and a packaged executable were not tested in this pass.

Map refinement on 2026-10-05 aligned the icon art to measured paper-circle centers, enlarged it, reduced blank space under both action panels, and placed a transparent static cloud-and-rain cutout behind the moving storm. The storm text gained a light ink outline for contrast. These checks ran in the working checkout with isolated user data: Godot 4.6.1 import exited 0; the updated headless map regression passed **20 checks**, the rendered map run **25 checks**, and the 2560 Ã— 1080 offscreen run **27 checks**, all with 0 failures. The action-panel bottom gaps measured 18 and 21 logical pixels. The Milestone 2 unit subset passed **26 checks**, and its Forward Plus UI subset passed **16 checks** across English/Tagalog at 100%/175% UI scale, all with 0 failures. Captures with the game HUD and the ultrawide map were inspected. The focused and unit runs still logged ObjectDB/resource-in-use shutdown warnings; no manual gameplay or packaged build was performed for this refinement.

### Weighted preparation and ending revision â€” 2026-10-06

Use Godot 4.6.1 with isolated `APPDATA`, `LOCALAPPDATA`, and matching `BAGYONG_ISOLATED_SMOKE` for any regression that writes leaderboard data. The count-only leaderboard file remains an archive; new tests must use `leaderboard_scores_v2.json` in isolated user data.

The pre-change score regression passed **4 checks, 0 failures**. After the scoring stage, `score_calculation_regression.tscn` passed **272 checks, 0 failures**, covering all 64 household need masks across four Nestor states, R8 versus R10, input normalization, saved score consistency, live need state, home and canonicalized shop visits, canceled travel, and visit deduplication. The first post-change run had one assertion failure because the test expected input ordering rather than canonical saved need-ID ordering; the corrected assertion passed on rerun. `milestone2_regression.tscn -- --unit-only` passed **26 checks, 0 failures** and `map_ui_regression.tscn` passed **20 checks, 0 failures**. Each headless run exited 0 after the corrected score test. Existing ObjectDB/resource-in-use shutdown diagnostics appeared in some runs despite passing assertions.

Final Godot 4.6.1 CLI checks in isolated user data: `score_calculation_regression.tscn` **272/272**, `ending_balance_regression.tscn` **12/12**, `pickup_guidance_regression.tscn` **37/37**, `dev_mode_regression.tscn` **47/47**, `map_ui_regression.tscn` **20/20**, `scratch_lotto_regression.tscn` **41/41**, and `milestone2_regression.tscn -- --unit-only` **26/26**. The rendered Milestone 1 smoke passed **54/54**, exercising a normal scene flow through ending and score submission. Direct bodega and hardware scene loads emitted no script/parser errors. Logs for these runs contained only the known ObjectDB/resource-in-use shutdown diagnostics.

Forward Plus probes used `ending_balance_regression.tscn -- --visual-only` at 1920Ã—1080 with VHS enabled (**27/27**) and at a 1280Ã—720 window with VHS disabled (**27/27**). They saved and inspected start/end frames of all four finished town locations, Nestor present/absent, English/Tagalog captions, the partial-window prop, and English/Tagalog result panels. The 1280Ã—720 window still rendered the project's 1920Ã—1080 logical canvas. The initial rendered pass exposed nearly black town shots; local montage lights corrected them. The final `pickup_guidance_regression.tscn -- --visual-only` Forward Plus pass saved bodega/hardware trail captures and passed **45/45** after a modest ribbon and wisp visibility adjustment; the matching headless run passed **37/37**. Guidance tests cover all six target routes, collision and destination checks, collection/full-bag cancellation, outside-mesh rejection, and modal/pause suppression. The captures show a visible ground-level ribbon without obvious wall phasing, but these scripted frames do not replace manual walking and visual tuning on a physical display, audio review, a natural full-day playthrough, or a packaged build.

After the final NPC hint edits, the Godot CLI editor import exited 0 without script/parser errors. The focused score (**272/272**), ending (**12/12**), and Milestone 2 unit (**26/26**) regressions passed in isolated user data. A CSV/source check confirmed all six edited highlighted NPC lines have one matching localization row with balanced BBCode in English and Tagalog. The headless regression runs still emitted the known ObjectDB/resource-in-use shutdown diagnostics.

### Pickup wind, Ate Linda shopping, and ending camera â€” 2026-10-07

Godot 4.6.1 CLI checks used separate isolated `APPDATA`/`LOCALAPPDATA` directories and matching `BAGYONG_ISOLATED_SMOKE` paths. The focused `ate_linda_trade_regression.tscn` passed **15/15** (decline opens normal-price shopping, repeat offer, acceptance changes price without restoring sold stock). `pickup_guidance_regression.tscn` passed **38/38** headless and **50/50** Forward Plus (particle trails, route movement, pickup and modal cancellation). `ending_balance_regression.tscn` passed **12/12** headless and **49/49** Forward Plus both with VHS on at 1920Ã—1080 and off at a 1280Ã—720 window (orbit focus/distance, town environment and VoxelGI selection, editable town anchors, Nestor and result captures). The final rendered hardware frames were inspected at both orbit endpoints with VHS on and off; its rear sign and ceiling are now visible. These probes render the projectâ€™s 1920Ã—1080 logical canvas even in the smaller window.

After the focused changes, the score regression passed **272/272**, the Milestone 2 unit subset **26/26**, and the normal-flow Milestone 1 smoke **54/54** in isolated user data. Logs had no script/parser errors or failed assertions. Some headless runs still emitted the known ObjectDB/resource-in-use shutdown diagnostics. The captures and scripted interactions do not establish manual walking, audible quality, natural full-day play, physical-display tuning, or packaged Windows behavior.

### Final pickup trail and result-screen reading gate â€” 2026-10-07

Godot 4.6.1 CLI runs used isolated user data. After lowering the wind trail, reducing it to 30 particles, and adding mild material emission, `pickup_guidance_regression.tscn` passed **38/38** headless and **50/50** rendered. After restoring the original two-paragraph typhoon/accountability message and adding a continue press before leaderboard name entry, `ending_balance_regression.tscn` passed **17/17** headless and **58/58** rendered; the normal-flow `milestone1_smoke.tscn` passed **56/56**. Rendered bodega/hardware trail and English/Tagalog result captures were inspected for visibility and clipping. No failed assertions or script/parser errors appeared; the known ObjectDB/resource-in-use shutdown diagnostics remain. Scripted checks and captures do not replace manual movement, physical-display visual tuning, a natural full-day run, or a packaged-build check.

## File organization verification - 2026-10-14

The existing runtime work was checkpointed separately as `e04a588` before the structure-only relocation. The organization changes move 315 files, preserve filenames and resource identities, and update references without changing gameplay logic, node names, scene properties or asset payloads. `_raw_assets` model/texture bundles retain their existing paths.

Verification used Godot **4.6.1.stable.official.14d19694e**, separate baseline/reorganized project copies and isolated APPDATA/LOCALAPPDATA with exact BAGYONG_ISOLATED_SMOKE paths:

- Path-normalized comparison: **2,070 files**, zero unexpected content changes, missing files, missing executable resource paths or stale active paths. All 75 relocated asset import files preserve their UIDs/settings and contain the correct source path; Godot regenerated their derived cache paths.
- **17 matching suites, 15,804 checks per version, zero failures**: ambient animals, Ate Linda, cleanup, cursor, recording camera, Dev Mode, portraits, ending balance, house teaser, map, Milestone 1 smoke, Milestone 2, Milestone 3, pickup guidance, score calculation, lotto and animated NPCs. Cursor and Milestone 3 use Forward Plus because headless mouse capture/presentation cannot satisfy their checks.
- Both imported projects have a clean subsequent editor/import pass. A fresh cache bootstrap can emit the previously observed UID/font/import diagnostics; those are not presented as a clean first import.
- A temporary rendered probe captured intro, menu, home, dialogue, inventory, map, shop and ending screens (**13 checks, zero failures**). The existing ending visual regression also passed 58 checks, zero failures, with English/Tagalog result captures. These captures exercise production resources through scripted calls and are not manual gameplay acceptance.
- A graphical Windows Desktop PCK export completed without logged errors/warnings. Outside the source directory, the diagnostic package loaded **191 relocated resources** and passed **420 checks, zero failures**, including stable UIDs, nonempty audio, the active raw localization CSV and excluded backup CSV.
- Independent review checked the move map, dynamic NPC path tables, UID companions, content-preservation evidence and navigation documentation. Its pending import-metadata finding was resolved by copying Godot-regenerated sidecars from the tested project.

Evidence is under `C:/Temp/bagyong-structure-20261014`: `regression-comparison.json`, `preservation-report.json`, source/rendered suite logs, `visual-final`, `export-results` and `package-results`. The helper scripts and diagnostic probes remain outside the repository. Existing ObjectDB/resource retention warnings and intentional cleanup invalid-input diagnostics are recorded separately from assertions. Full manual play, audible audio quality and standalone Windows EXE acceptance were not verified by this relocation task.

## Freed pickup guidance regression - 2026-10-14

The radio pickup in bodega exposed cached `WorldItem` references surviving their nodes' deletion. Godot rejects a freed argument at the typed `_is_eligible()` call before its internal guard runs. `PickupGuidance3D` now checks instance validity before each eligibility call for its active target, previous target and cached candidates; item eligibility and route rules are unchanged.

The extended `pickup_guidance_regression.tscn` reproduced the original script error before the fix. It invokes actual pickup completion in bodega and hardware, verifies inventory/collected state and node deletion, checks queued and freed targets, remaining-item selection, no surplus plywood hints after two boards, all pickups removed, and scene reload with collected items absent. Godot **4.6.1.stable.official.14d19694e** passed **54 headless checks** and **64 Forward Plus checks**, both with **0 failures** and no script/parser errors, warnings or shutdown diagnostics. The rendered run additionally exercises active-hint cancellation after target deletion. Tests reused the imported disposable project at `C:/Temp/bagyong-structure-20261014/after` with synchronized game files and isolated APPDATA/LOCALAPPDATA plus exact BAGYONG_ISOLATED_SMOKE paths. Logs and result files are under `C:/Temp/bagyong-radio-20261014/final-headless` and `final-rendered`. `git diff --check` passed. Manual keyboard pickup/confirmation and packaged builds were not rerun; unrelated editor warnings shown in the original screenshot were outside this fix.

## Deferred visual quality regression - 2026-10-14

`VisualSettings` previously deferred a typed `Node` argument directly when lights or environments entered the tree. Nodes freed before dispatch caused `Cannot convert argument 1 from Object to Object` before the function's validity guard could run. It now uses the existing localization weak-reference pattern, resolving the node immediately before the unchanged typed quality function. Live-node quality behavior and persisted settings are unchanged.

The extended cleanup suite frees a light and environment before their deferred callbacks and retains another pair to verify quality application. Before the fix, assertions passed but the engine logged two deferred conversion errors; therefore the assertion count alone is insufficient. After the fix, Godot **4.6.1.stable.official.14d19694e** passed **95 checks, 0 failures** in both headless and Forward Plus, with no unexpected engine/script errors or shutdown diagnostics. The suite's intentional invalid-inventory diagnostics remain expected. The previous pickup suite also passed **54 checks, 0 failures** after this change. Tests reused the imported disposable project with isolated APPDATA/LOCALAPPDATA and exact BAGYONG_ISOLATED_SMOKE paths. Evidence is under `C:/Temp/bagyong-pharmacy-20261014/visual-before`, `visual-after`, `visual-rendered` and `pickup-recheck`. Independent review found no actionable issue in the two-file fix. Manual keyboard play and packaged builds were not verified; the pharmacy movement report is a separate collision investigation.

## Pharmacy chicken-store curb regression - 2026-10-14

A diagonal walking approach into the pharmacy's front/right boundary reproduced persistent forward movement blockage at the chicken-store curb. At initial contact, step-up classified the remaining movement as sufficient; repeated imported sidewalk contacts then lost floor recognition and prevented further step-up attempts. The road/sidewalk rise is approximately 0.172 units, below the controller's 0.32-unit limit. A small scene-owned collision ramp now provides continuous ground support at this corner, without changing the visible imported mesh, map walls or shared controller.

`game/tests/pharmacy_movement_regression.tscn` exercises actual PlayerV2 input/physics across four approach positions, walking and sprinting, sustained diagonal pressure, W/A escapes, boundary containment, and reaching the sidewalk top. Godot **4.6.1.stable.official.14d19694e** passed **32 checks, 0 failures** in both headless and Forward Plus using the imported disposable project and isolated APPDATA/LOCALAPPDATA plus exact BAGYONG_ISOLATED_SMOKE paths. The pre-fix approach probe failed the curb escape; the candidate and final scene passed. Logs/results are under `C:/Temp/bagyong-pharmacy-20261014/approach`, `ramp-candidate`, `final-headless` and `final-rendered`. No script/parser errors occurred. The headless movement run retained known ObjectDB/resource-in-use shutdown diagnostics; the rendered run did not. Independent review found no actionable issue in the scene/test fix. Temporary diagnosis and shop-cycle probes remain outside the repository.

This verifies the reproduced curb blockage, not the user's reported complete all-direction immobilization: leftward escape worked in the failing probe. Manual keyboard acceptance of the original stuck session and packaged builds remain unverified. Recheck diagonal corner entry and W/A escape after restarting the game; D/S should still respect the authored road/right boundaries.

# Animated PSX NPC models

These 11 corrected GLBs replace the static visual checkpoint in the new NPC scenes. The six original modeled NPCs are excluded. Static GLBs remain under `../psx_static/`; the editable Blender source and its exports are preserved.

## Source and import

Copy only the 11 GLBs from `C:\Users\john2\Documents\Blender\Bagyong_Bahay_NPCs_PSX\animated\exports_arm_polish`. They were exported from `Bagyong_Bahay_NPCs_PSX_Arms_Polished.blend` and contain 69 clips, 20-bone rigs, embedded textures, skinned held props, and stationary ground props. No animation reauthoring or asset re-export is needed for this integration.

Use Godot 4.6.1's native scene importer. For these assets only, set:

- Animation FPS: 24; trimming and removal of immutable tracks: off.
- Node name/type suffix processing: off, preserving `idle_loop` and `talk_loop` names.
- Advanced settings for `AnimationPlayer`: optimizer and compression disabled.
- Embedded images: Embed as Uncompressed.
- Import script: `PSXAnimatedImport.gd` in this folder.

The import script preserves nearest interpolation and nearest texture sampling, marks only `idle_loop`, `talk_loop`, and `relieved_loop` as looping, and sets the editor preview's autoplay to `idle_loop`. Other clips play once. Godot generates the import metadata and cached resources; do not hand-edit `.godot/`. The initial implementation configured the normal import parameters with Godot's `ConfigFile` API in the disposable project and then let the native importer regenerate its outputs.

## Scenes and controller

Each target retains its existing `visuals/mixamo_base` model child, or `visuals/PharmaDudeModel` for PharmaDude. Preserve the [calibrated scales](../psx_static/README.md#height-calibration), facing, and gameplay root. The imported model includes all its ground-prop siblings; do not copy only its rig.

MoneyBeggar's animated model child is positioned at local Y=0.058364598, compensating for the source's seated minimum of -0.049578786 before its 1.17720910 scale. PharmaDude retains local Y=-0.3448443. These offsets match the approved static grounding. Other model offsets remain unchanged.

`NPCAnimation` is an opt-in scene-owned node using `game/entities/npcs/base/PSXNPCAnimation.gd`. Its Inspector paths identify the existing NPC Area3D and the complete visual model. Only MoneyBeggar enables `donation_reaction`.

The controller observes the existing dialogue signal and `NPC.is_showing`. It runs idle, schedules an authored fidget after 4–7 idle seconds, and immediately switches to conversation entry/loop/exit when dialogue starts or ends. Repeated line signals do not restart a clip. Choice prompts and shopping suppress fidgets. Donation success triggers one grateful reaction followed by relieved idle; failed/declined donations do not. Returning after donation starts relieved idle without replaying thanks. SceneTree pause stops playback; storm transition and scene exit cancel pending work.

During dialogue only, a native `LookAtModifier3D` turns the Head bone toward PlayerV2's animated head joint. Tracking eases in and out over approximately 0.25 seconds. Head rotation is limited to 55 degrees left/right and 20 degrees up/down relative to the head's rest orientation under its current neck pose. Godot's symmetric settings use the total range, so the configured values are 110 and 40 degrees. Targets behind the character or too close to the head disable tracking and restore authored motion. Dialogue ending, choices, and shopping also restore authored motion; pause freezes tracking and storm transitions cancel it.

The authored head animation remains unchanged in the assets and plays normally outside dialogue tracking. No root motion, body rotation toward the player, clip crossfades, or walking is used. Shared NPC scripts, interaction areas, quests, shops, and the six excluded NPCs are unchanged.

## Manual test

Start a normal run in Godot 4.6.1 and visit:

| Location | New animated NPCs |
| --- | --- |
| Tindahan | MangNestor, TapeNeighbor, SmokeBreakNPC |
| Hardware | TatayJun, KapsWorker |
| Grocery | PalengkeQueueMan, PanicBuyer, WetParent, MoneyBeggar |
| Pharmacy | PharmaDude, AteMaribel |

1. Watch each NPC idle for at least 7 seconds to see a character fidget. Begin talking during a fidget.
2. Press **E** to talk. Use the existing dialogue advance control (**Space**, or E where supported) to skip typing and advance lines. Conversation should enter, loop without restarting per line, then exit to idle.
3. Quickly talk again during the exit. Check detection prompts, normal dialogue, foot placement, and held-prop contact.
4. Accept/decline the Nestor and smoker choices; open and close the pharmacy shop. Choice/shop screens should leave the model resting.
5. Try Beggar's donation with insufficient cash, decline, then donate successfully. Observe the grateful nod and lowered-hand relieved idle. Leave and revisit Grocery; the nod must not repeat.
6. Pause/unpause during an action. Confirm animation resumes and movement/dialogue behavior stays normal.
7. Initiate dialogue from either side and check the head turns toward your character without moving the body. Check the seated Beggar's upward gaze. Leaving dialogue should restore authored motion. The head must never twist backward or make a full rotation.

Automated evidence and limitations are recorded in [Testing](../../../docs/TESTING.md). Location action previews are in `design_previews/animated_npcs/`. Manual gameplay acceptance and packaged-build testing are separate from scripted checks.

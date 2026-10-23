# Ambient animals integration review

The user moved the animals on 2026-10-12. See the [current walking starts and route checks](start_positions_20261012/README.md); the captures below show the original placement.

Five approved animals are installed in Palengke and Tindahan. These captures use the real PlayerV2 cameras, normal location lighting and HUD in Godot 4.6.1 Forward Plus on the RTX 4050. There is no inspection fill light or runtime placement change. Coats are chosen by the production controller, so another visit can look different.

![Five placements](placement_sheet.png)

## Verification evidence

The focused [controller regression](validation/regression.log) passes 223 checks; the [normal-flow smoke](validation/smoke.log) passes 56, [NPC regression](validation/npc.log) 1,638 and [Linda shop regression](validation/linda.log) 17. [Imported skin geometry](validation/geometry.json) samples all 16 clips at 24 fps. [Clearance](validation/clearance.log) passes 2,305 ground/body checks, and [gait sampling](validation/gait.log) supports the runtime speeds. [Camera results](validation/camera_measurements.json) cover 20 High/Performance and VHS off/on views.

The full-resolution PNGs here show each animal at its starting anchor. The camera comparison probe holds translation for repeatability, while animation continues. Temporary unshaded magenta materials used only for visibility measurements are restored before the normal captures. Geometry clearance uses conservative skinned bounds above 35 mm, plus separate full-mesh ground sampling. These checks establish local scene visibility and nonblocking behavior; world scenery can obscure animals from other player positions.

The validation folder includes external probe scripts for an imported disposable project. They are not shipped game scripts. `docs/TESTING.md` records the isolated-userdata setup. Full temporary captures remain at `C:/Temp/bagyong-ambient-integration-20261011`.

Manual keyboard gameplay through every route, audible acceptance and a standalone Windows build were not performed. Existing headless shutdown retention warnings are retained in the logs.

## Motion and native clip previews

[Palengke cat](grocery_WalkingCat.gif), [Palengke dog](grocery_WanderingDog.gif), and [Tindahan dog](tindahan_WalkingDog.gif) each show 20 seconds of controlled simulation using the production movement/rest controller and native imported animation at 12 fps. The GIFs retain every second frame at 6 fps. The camera/HUD/lighting remain native; the fixture locks the player and manually advances controller/animation time for repeatable capture. For the Palengke dog, the locked player follows its X coordinate from 2.8 m behind the route, letting the real camera follow through the frontage. The captured cat sits after its first walking leg; Palengke's dog runs, walks, wags and sniffs, while Tindahan's dog only walks and rests/sniffs. Crops improve visibility without altering animal pixels or lighting.

All **five cat clips** and **eleven dog clips** were also rendered at their midpoint and reviewed in the actual Palengke lighting: [cat sheet](cat_clip_sheet.jpg), [dog sheet](dog_clip_sheet.jpg). No new visible deformation or ground intersection appeared. Ground/contact and loop/transition seam checks cover the full clips separately. [Motion capture log](validation/motion.log) records 736 native render frames.

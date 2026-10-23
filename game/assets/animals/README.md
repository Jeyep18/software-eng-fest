# Ambient cats and dogs

Approved models for the five decorative animals in `grocery.tscn` (Palengke) and `tindahan.tscn`. Both species use shared GLB geometry/rigs. Their reusable scenes duplicate one coat material per instance; colors remain stable until the location is left.

| Species | Coat atlases | Actions | Standing head height |
| --- | --- | --- | --- |
| Cat | Ginger, gray, cream | Idle, walk, sit enter/loop/exit | 0.35 m |
| Dog | Charcoal, brown, tan | Idle, wag, walk, run, sniff, sit enter/loop/exit, lie enter/loop/exit | 0.60 m |

These exports match the visually approved Blender copies. Original vertex geometry, rig rest data and authoring weights are retained. Six skin influences survive GLB export and Godot import. The cat's missing texture was replaced with a pixel atlas; dog recolors retain facial and paw detail. Eight slightly excessive cat weights are normalized only during export. Dog constraints were baked on its working copy. The unused source bark clip is excluded.

## Editing and reimport

Prepared source files and reproduction scripts are in `C:/Users/john2/Documents/Blender/Bagyong_Bahay_Ambient_Animals`. The original downloads are `cat.blend` and `Dog1.1/Dog/Dogs1.blend`; work on copies. Review changes in Blender before replacing approved GLBs or atlases.

In Godot 4.6.1's Import dock, retain the committed native `.glb.import` settings: 24 fps baking, no trimming, disabled name suffix processing, embedded textures, no animation optimizer/compression, and `AmbientAnimalImport.gd`. That asset-specific post-import script sets explicit `_loop` modes, disables autoplay, preserves nearest texture filtering, and enables dynamic GI. It uses the [native scene import workflow](https://docs.godotengine.org/en/4.6/tutorials/assets_pipeline/importing_3d_scenes/import_configuration.html). Never edit `.godot/` cache files.

`game/entities/animals/AmbientAnimal.gd` owns the local state, RNG, coat choice and animation player. Waypoints use the `AmbientAnimals` parent's coordinates as a route template. On entry, the controller duplicates that route and translates every point so the first point matches the animal's saved scene position. Move the animal node in the editor to move its start and entire route together; its leg lengths and directions remain unchanged. Keep these animals out of `player`/`interactables` groups and give them no physics bodies. Running is enabled only for Palengke's dog. Cats walk at 0.43 m/s; dogs walk at 0.59 m/s and run at 2.2 m/s. Speeds follow the imported low-paw surface velocities (approximately 0.43/0.60/2.20 m/s). Each model child has 1 mm clearance for interpolation tolerance. A location exit frees all state; game pause suspends both gait and movement, while storm arrival freezes them immediately.

Use `game/tests/ambient_animal_regression.tscn` in an imported disposable project with the isolated-userdata setup in `docs/TESTING.md`. Gameplay camera captures and validation evidence are in `design_previews/ambient_animals/`.

# Verified portrait model references

All 17 current NPC roles have existing external preview images in `C:/Users/john2/Documents/Blender/Bagyong_Bahay_NPCs_PSX/animated/previews/{NPCID}.png`. See `model_references.json` for exact scene/model/image paths and observed identities. Paths were checked on disk.

## Identity traps

- Use the animated previews for SmokeBreakNPC and MoneyBeggar. The earlier base library exchanged their later clothing/appearance: current smoker is fuller, has glasses and a gray polo; current beggar is seated in a torn sleeveless gray shirt and olive shorts.
- Ate Linda, Hardware Girl and Grocery Girl all use the same active `nanay_model.tscn` wrapper, which loads `Animated Woman.glb`. Their gold/blond bob, gray/white shirt and orange trousers are the same. Distinguish portraits with location backgrounds and relevant expressions.
- Active household Nanay is copper-haired with a dark T-shirt; the approved portrait is black-haired with glasses and purple clothes. Active Lola is gray-haired in a pale blue blazer without glasses; the approved portrait has round glasses and a cardigan. This divergence must remain visible in review notes. Parent will explicitly explain this divergence and use current model identities in the approved rendering style.
- Chooks seller shares Mang Nestor's balding donor head but uses a blue shirt and plaid shorts, whereas Mang Nestor wears teal and dark shorts.
- Panic Buyer and Wet Parent share a face/hair donor but use olive-yellow and dusty plum shirts respectively. Tatay Jun and Queue Man also share a face/hair donor but use brown and slate-blue shirts.

## Player glasses

The current PlayerV2 embeds the `head` ArrayMesh from Simple Character PSX. It has a second surface named `glass`, using StandardMaterial3D_y10w4. The face texture includes thick black rectangular rims; source GLB glasses lenses use a translucent glass material (alpha 0.2). The source head has 167 textured vertices and 16 lens vertices. There is no separately named glasses node. Retain the approved black-haired boy identity and add black rectangular glasses consistently across all expressions.

## Missing player render and safe rendering route

A standalone player head/shoulder render is now available at `references/player_model.png` (768 x 768). Blender exists at `C:/Program Files/Blender Foundation/Blender 5.2/blender.exe`; Godot 4.6.1 console exists at `C:/Godot/Godot_v4.6.1-stable_win64.exe/Godot_v4.6.1-stable_win64_console.exe`. A background factory-startup Blender process can import the source Simple Character PSX GLB and render a head/shoulder reference into preview-only output. This is independent of the live Blender scene and does not require a Godot project import. An isolated Blender 5.2.2 LTS process rendered the requested front view from the source GLB and exited successfully; the result was visually inspected.

## Verification boundary

Current scene external-resource paths, source GLB JSON node/mesh/material records, player atlas, and existing rendered cast were inspected. All 17 NPC scene/model/image paths exist. All 11 active animated NPC GLBs byte-match their external export versions. Nanay, Lola and Chooks current GLB albedo pixels exactly match the corresponding external animated package textures. Active game rendering was not run. No model, game scene, runtime script, runtime portrait, or connected Blender state was changed.

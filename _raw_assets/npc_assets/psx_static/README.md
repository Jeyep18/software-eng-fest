# Static PSX NPC models

These 11 GLBs preserve the approved static visual checkpoint using the corrected `idle_loop`, frame 1 pose. The runtime NPCs now use the [animated versions](../psx_animated/README.md) with the same calibrated scales. These static files contain evaluated body and prop meshes, UVs, materials, and embedded textures, with no animations, skeletons, skins, cameras, lights, or collision geometry. Imported materials use nearest texture sampling.

| Location | Models |
| --- | --- |
| Tindahan | MangNestor, TapeNeighbor, SmokeBreakNPC |
| Hardware | TatayJun, KapsWorker |
| Grocery | PalengkeQueueMan, PanicBuyer, WetParent, MoneyBeggar |
| Pharmacy | PharmaDude, AteMaribel |

## Source and export

The source is `C:\Users\john2\Documents\Blender\Bagyong_Bahay_NPCs_PSX\animated\Bagyong_Bahay_NPCs_PSX_Arms_Polished.blend`. The local export script is `animated/work/arm_revision/export_static_pose.py` in that Blender package. Run it through Blender MCP with the source loaded; it supplies a window context for the background bridge. It does not save the source file.

The script evaluates each character's idle action at frame 1 with NLA tracks muted, copies evaluated geometry into a temporary scene, and bakes body and prop transforms relative to the rig. It preserves UVs and materials, grounds the lowest vertex, uses nearest texture sampling, and exports only the temporary active scene. It restores the original frame, actions, slots, collection visibility, and NLA states. Outputs and `static_pose_manifest.json` are in `animated/exports_static_pose/`; copy only the 11 GLBs here. Preserve the source and animated exports.

Blender -Y forward becomes glTF/Godot +Z forward. Exported bounds start at local Y=0. Standing heights remain approximately 1.60–1.80 m. MoneyBeggar remains seated at 0.9276 m high; his evaluated source geometry needed a 0.04958 m upward grounding correction. Do not rescale him to standing height.

## Static checkpoint integration

The ten replacement scenes retain `visuals/mixamo_base`. Model children use calibrated uniform scales; NPC roots and visual wrappers remain unchanged. PharmaDude uses `visuals/PharmaDudeModel`; the model child has position `(0, -0.3448443, 0)` to meet the visible pharmacy platform at world Y=0.9617674 while preserving the root at Y=1.3066115. His disabled body collider remains disabled.

### Height calibration

The player has a visible idle height of 2.04209747 scene units, measured from skinned vertices at `Idle/mixamo_com`, frame 0. NPC body heights below exclude held props. Male models are 98–100% of that height; female models are 92–94%. Uniform scaling preserves body proportions, corrected poses, textures, and hand/prop contact. These are scene proportions, not a change to the source Blender model's physical measurement.

| NPC | Model child scale | Visible body height | Player height ratio |
| --- | ---: | ---: | ---: |
| MangNestor | 1.16207187 | 2.001256 | 98% |
| TapeNeighbor | 1.20283130 | 2.021677 | 99% |
| SmokeBreakNPC | 1.18040315 | 2.042097 | 100% |
| TatayJun | 1.21787743 | 2.021677 | 99% |
| KapsWorker | 1.13449870 | 2.042098 | 100% |
| PalengkeQueueMan | 1.15524372 | 2.021677 | 99% |
| PharmaDude | 1.16028268 | 2.042098 | 100% |
| AteMaribel | 1.16288311 | 1.878730 | 92% |
| PanicBuyer | 1.16533484 | 1.919572 | 94% |
| WetParent | 1.18896700 | 1.899151 | 93% |
| MoneyBeggar | 1.17720910 | 1.091945 seated | 98% standing equivalent |

These are absolute scales on the model child, not extra multipliers on its current scale. MangNestor's calibrated scale replaces the earlier 1.05. MoneyBeggar uses his 1.70000005 source standing body height as the reference; do not compare his seated height directly with the player's standing height. PharmaDude's local position is outside the child's scale, preserving grounding. The GLBs remain unchanged.

NPC roots, location placements, Area3D properties, scripts, dialogue, quests, shops, and unique CanvasLayer nodes remain unchanged. Nanay, Lola, AteLinda, HardwareGirl, GroceryGirl, ChooksSeller, and the shared Mixamo asset are outside this integration.

Open the project in Godot 4.6.1 and let Godot import the GLBs normally. Default embedded-image handling may create extracted PNGs and their import metadata beside the GLBs. Do not hand-edit `.godot/`, enable imported animation playback, or attach gameplay collision to these visuals.

## Verification

See [Testing](../../../docs/TESTING.md#static-psx-npc-integration--2026-10-10) for the disposable-project commands, results, and limits. The focused scene is `game/tests/static_npc_regression.tscn`; its graphical mode captures front, side, and elevated views in the four real locations. Original integration sheets are in `design_previews/static_npc_integration/`; player-relative height comparisons are in `design_previews/static_npc_height/`.

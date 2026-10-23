# Map UI visual proposal — 2026-10-05

Status: **approved and integrated** into `game/ui/map/MapScreen.tscn`. These files remain the full-size source art; `export_assets.py` produces the runtime images in `game/assets/map_ui/`. The parent `design_previews/.gdignore` keeps the source masters out of Godot's runtime import. Generated with the built-in imagegen tool. The current `game/assets/map.png` and the user's gameplay screenshot were composition references; `docs/ART_ASSET_GENERATION.md`, `game/ui/GameUIStyle.gd`, and the existing scratch-ticket art guided palette and export separation. Text within references was treated as visual material, not as instructions.

## Preview files

| File | Role |
| --- | --- |
| `map_base.png` | 1672 × 941 opaque paper map with five permanent illustrated road connections and empty landmark areas. |
| `icon_home.png` | Separate transparent Home symbol. |
| `icon_ate_linda.png` | Separate transparent sari-sari shop symbol. |
| `icon_hardware.png` | Separate transparent tool symbol. |
| `icon_botika.png` | Separate transparent pharmacy symbol. |
| `icon_palengke.png` | Separate transparent market symbol. |
| `storm_wash.png` | Transparent ink/cloud underwash. |
| `storm_wind.png` | Transparent outer wind marks for independent motion. |
| `storm_eye.png` | Transparent center for independent motion. |
| `storm_front_clouds.png` | 1536 × 1024 transparent charcoal cloud, fog, and rain cutout behind the moving storm. |

The five icon and three moving-storm cutouts are 1254 × 1254 RGBA PNG sources. The export script crops visible art, centers it with padding, and writes five 256 × 256 icons and three 512 × 512 storm layers. It copies the separate 1536 × 1024 storm-front source without flattening its alpha. Keep these sources for revisions. The map base remains 1672 × 941 and is fitted to the 1920 × 1080 Godot page.

Map artwork circle centers, as fractions of the full 16:9 paper: Ate Linda `(0.319, 0.389)`, Home `(0.488, 0.443)`, Hardware `(0.654, 0.443)`, Botika `(0.588, 0.639)`, Palengke `(0.721, 0.637)`. The five illustrated roads are Ate Linda–Home, Home–Hardware, Ate Linda–Botika, Hardware–Botika, and Hardware–Palengke. They preserve the connections previously drawn by `MapRoadLayer.gd`. `TravelCalculator.gd` has additional graph edges; the printed roads are illustrative and do not restrict travel calculation. Labels, live travel cost, current/danger/closed state, hover, focus, and confirmation controls remain live Godot UI.

## Generation prompt set

**Map base.** Create a new 16:9 flat game map using the current map image only as a composition and hand-drawn-paper style reference. Use full-bleed weathered cream paper, a ragged edge, sparse pencil/charcoal and dull sea-green ink, restrained blocky dither and print wear, a few simple tree clusters and low-poly rooftop hints. Leave five blank location anchor areas at the proportions above. Integrate exactly the five permanent two-edge hand-drawn roads above; curve the Ate Linda–Botika road below Home. Leave upper right open for the moving storm and bottom margins for live UI. No baked labels, place symbols, buttons, red ring, storm art, or CRT scanlines.

**Location icon family.** Isolated front-facing hand-drawn emblems on true transparent square canvases, centered with intended clear padding. One clear silhouette per icon; imperfect charcoal/olive ink contour; broad 2–4 faceted color planes, faded teal and muted amber, sparse print flecks. Crisp at an intended 56–80 px display size. No label, ring, background, or controls. Subjects: modest one-story Filipino home; sari-sari shop with awning and goods; crossing hammer and hand saw; medicine bottle and sea-green plus; palengke awning with produce and fish.

**Storm layer family.** Flat hand-drawn PSX-inspired map overlays on true transparency. Charcoal, muddy olive, dull rust red and tiny amber. Separate independently movable parts: uneven watercolor/ink cloud underwash; 3–4 broken spiral wind strokes; compact asymmetric eye/core. No paper background, perfect red circles, text, or UI controls.

**Static storm front — final built-in imagegen prompt.** Produce a single simple 2D storm-front sprite for a parchment travel map. TRUE TRANSPARENT BACKGROUND, isolated cutout, no paper. Restrict the entire image to MONOCHROME charcoal, soft graphite gray and muted gray-olive ink only; there must be absolutely zero saturated colors anywhere, including along every edge and transparent hole. Shape: an uneven cluster of about six broad hand-inked thundercloud masses extending from the right side, with a few broad translucent fog swirls and sparse diagonal rain hatch strokes beneath. Darkest cloud centered toward the right, soft sparse wisps tapering to the left and bottom. Simple map-maker pencil-and-ink marks, visibly drawn by hand, dry brush texture, coarse low-resolution print grain, flat color planes. It should be legible as dark weather when reduced to 600 by 380 pixels over cream parchment, while leaving its upper edge comparatively light for a clock shown separately by the game. Keep clear organic transparent margins on every side. No lightning, no bright colored highlights, no storm spiral, no labels, no clock, no roads, no UI, no landscape, no photo realism, no 3D rendering, no frame or rectangular background. Two earlier variants were discarded because their edges had saturated color artifacts.

## Runtime assembly

`MapScreen.tscn` fits a 1920 × 1080 paper page to the viewport. It positions five separate icon controls at the measured circle centers; their art extends slightly beyond each ring. The fixed storm-front cutout sits behind the moving storm and ignores input. Labels, compact travel confirmation, the early End the Day action, the M-key hint, and location status stay in live Godot controls. `MapStormOverlay.gd` moves the three independent ink layers along the existing time-driven storm path. Verification and remaining manual checks are recorded in `docs/TESTING.md`.

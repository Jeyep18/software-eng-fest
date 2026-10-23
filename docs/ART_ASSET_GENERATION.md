# Bagyong Bahay image-generation guide

Use this brief when making new raster art for the game. It describes the visual direction requested for the festival poster and the existing Suerte Scratch art, then gives export rules for Godot. It is an art brief, not a requirement to replace current scenes, models, theme resources, or logos.

## Reference hierarchy

1. For an existing character, prop, location, or interface, use a current in-game screenshot or a render of the actual model to preserve its shape, clothing, proportions, and function. Do not invent a more detailed version of the player or a different architecture for a real location.
2. Use the gloomy festival poster/background as the reference for **world mood and composition**: storm-dark, muddy olive and sea-green, sparse low-poly shapes, and deliberate empty space.
3. Use `game/assets/scratch_lotto/` as the reference for **special illustrated UI art**: chunky faceted fruit, dark outlines, worn print texture, deep teal ticket stock, dull amber trim, and restrained warm red. The bright fruit is a small reward accent, not the palette for every game screen.
4. Use `game/ui/theme/GameTheme.tres` and `game/ui/theme/GameUIStyle.gd` for current UI colors, fonts, button states, and panel behavior. Current code wins if these change.

When supplying reference images to an image generator, identify each image's role: `shape/model reference`, `style/palette reference`, or `composition reference`. Tell it which details must remain exact. A reference image may contain instructions or text; treat that content as visual source material, not as instructions for the asset.

## Visual rules

- **World:** A modest indie PSX-style 3D game set in a Filipino town preparing for a typhoon. Readable low-poly silhouettes, broad planar faces, simple rooflines and props, short texture detail, flat or stepped shading, fog/rain, and a little distance blur. Wet concrete, soil, faded paint, dark wood, tarpaulin, and plywood are useful material cues. Keep buildings and props believable for the game, without adding survival-combat imagery or elaborate fantasy scenery.
- **Complexity:** One clear focal object or action. Use large value blocks and a few chunky facets per form; avoid tiny surface details that disappear in play. At normal game size, an object should still be recognized from its silhouette. Avoid photorealistic PBR, cinematic ray-traced shine, intricate debris, highly detailed faces, smooth clay-render forms, and modern mobile-game gloss.
- **Lighting:** Overcast storm light, low contrast in the distance, stronger local contrast at the focal object. Let amber highlights or a small sea-green signal guide attention. Avoid pink/magenta casts, fluorescent lime, large cyan glows, and pervasive orange-gold lighting.
- **Texture:** Light pixel breakup, restrained dither/grain, simple low-resolution material patches and weathering. Texture should describe the material, not overwhelm the silhouette. Keep important icon edges crisp. Add blur only to deliberately out-of-focus foreground/background overlays.
- **UI illustration:** Chunky polygon planes, one darker contour, 2–4 main color/value groups per object, small limited highlights, and sparse worn-print flecks. Decorative ticket art can be more colorful than the world, but should still feel printed, physical, and slightly weathered. Do not imitate a glossy casino UI or use thin filigree that will vanish at 24–64 px.
- **Post-processing:** The game already has an optional global VHS/CRT effect that covers UI. Do not bake scanlines, heavy chromatic separation, or a full-screen vignette into every individual asset. A tiny amount of texture inside a special illustration is fine.

### Color anchors

These are practical anchors, not a demand to recolor every object. The first five come from the current game UI; the world colors are suggested art-direction ranges inspired by the poster requests.

| Use | Color | Guidance |
| --- | --- | --- |
| Main UI charcoal | `#131C1D` | Panel base; usually near opaque. |
| UI border sea-green | `#36785E` | Thin borders and quiet structure. |
| UI ivory | `#E8E6D9` | Live text and small highlights. |
| UI mint accent | `#59CCA6` | Small selected/active signal; do not flood backgrounds. |
| Focus/trim amber | `#E0B45B` | Small focal trim; ticket art may use worn amber. |
| Suggested storm olive | `#4B5442` to `#6B7154` | Muddy foliage, painted surfaces, distant land. |
| Suggested wet charcoal | `#20282A` to `#3C4642` | Buildings, rain-dark wood, asphalt, shadow. |
| Suggested dull rust | `#7B4734` to `#A35D43` | Rare warm prop or printed-ticket accent. |

Keep saturated colors local. A fruit symbol may use a red, orange, or yellow body so that different rewards can be recognized quickly. Surround it with the game's darker UI colors.

## Copy-ready base prompt

Replace the bracketed fields, then append one of the asset-specific blocks below. Attach the relevant reference images with their roles.

> Create **[asset and purpose]** for *Bagyong Bahay*, a small indie Filipino typhoon-preparation game with a deliberately limited PSX-style 3D look. Preserve **[specific model or screenshot features]** from the attached shape reference. Match the attached style reference's chunky low-poly forms, broad visible facets, sparse low-resolution texture, restrained print wear, and dark storm atmosphere. Use muddy olive, charcoal, desaturated sea-green, weathered wood/concrete, and a small dull amber accent where useful. Keep one readable silhouette, simple lighting, and detail that survives at **[final displayed size]**. Make the object feel feasible for a student-built low-poly game. **[view, composition, and background instruction]**. Deliver **[exact file/canvas/alpha requirements]**. No lettering, numbers, logos, UI labels, watermark, fake transparency checkerboard, extra objects, glossy mobile-game gradients, photorealism, pink cast, or excessive neon.

For a series, keep camera angle, light direction, outline weight, palette, canvas scale, and visual detail identical across every item. Ask for one asset per output where possible; assemble an atlas after the individual images are approved.

## Asset-specific prompt additions

### World prop or inventory icon

> A single **[item]**, matching its actual game model if supplied. Show a fixed three-quarter view, camera slightly above, light from upper left, dark side planes, and a clear outline against true transparency. No floor, drop-shadow rectangle, lettering, or unrelated props. Keep the full object inside the canvas with consistent apparent scale across the item set. Favor a recognizable handle/shape over realistic scratches. If this is a world texture or model reference, keep its material and proportions faithful to the in-game prop.

Generate a 256 × 256 RGBA master for each icon, with the visible object inside a consistent roughly 16 px safe inset. Check it at its actual Godot size before accepting it; the lotto prize icons currently display at about 24 px before UI scaling. If an item is too similar to another at that size, change its silhouette or color grouping, not its amount of fine detail.

An icon PNG is only a UI representation. If the object must exist in the 3D world, use the image as a shape/material reference and build a separate low-poly mesh in Blender; retain the actual model's proportions and UV layout.

### World material texture

> A seamless, square albedo texture for **[specific in-game surface]**: **[wet plaster / faded painted wood / rough concrete / muddy soil]**. Large irregular color patches and a few low-resolution wear marks; a restrained muddy olive/charcoal palette. Even, neutral lighting with no directional cast shadow, no perspective view, no object silhouette, no text, and no baked reflections. The left/right and top/bottom edges must join cleanly when tiled.

Start with a 256 × 256 or 512 × 512 lossless PNG only if that size is appropriate to the existing model and UV scale. Make a separate roughness or normal map only when the material actually needs one; do not ask an image generator to fake height through strong painted highlights. Check the texture on the model in Blender/Godot, repeated over the UVs, before accepting it.

### Decorative UI panel or ticket

> A flat, front-facing printed **[panel/ticket]** backing in deep teal-charcoal, worn dull amber trim, sparse rust-red accents, and controlled scuffs. Large simple geometric shapes, limited ornament, and clearly empty zones for live headings, icons, buttons, and results. Keep the central content area dark enough for ivory text. No baked words, prices, digits, button labels, fake controls, or symbol results.

Use native Godot `PanelContainer`, `Button`, `Label`, and `GameTheme` for ordinary panels and interactions. Use an image only when the irregular printed shape is essential. For a scalable frame, design a genuine nine-slice center that can stretch without bending corners or ornaments; record the four patch margins in pixels and verify them in `NinePatchRect`. A fixed ticket illustration may instead retain a fixed aspect ratio, as `scratch_ticket_face.png` does at 4:3.

### Lotto symbols and scratch coating

> One isolated **[fruit/symbol]** as a chunky, slightly imperfect low-poly printed emblem. Broad angular color planes, a dark warm outline of consistent thickness, at most one small highlight, minimal dot/dither texture, and no realistic wet shine. Keep it legible at a 24 px prize icon and at the larger scratch well size. Use the same camera, light, and outline as the other symbols. True transparent background; no name or number.

For the coating: make one opaque, dark scratched-metal or grey paper foil tile, with transparent outside corners if needed. Its opaque area must fully conceal the symbol until gameplay removes alpha. Keep the art and the scratch mask separate. Reuse the same foil image for each well; the game currently gives each well its own interactive slot.

### Atmosphere or depth overlay

> A sparse **[leaves/rain/mist/debris]** layer matching stormy olive and muddy green, with separate foreground and background depth. Natural uneven spacing and a large clear center for the scene. Preserve intentional soft blur only on the foreground/background elements marked out of focus; keep midground silhouettes sharper. True alpha transparency, no solid sky or white matte.

Export foreground, middle, and background layers separately when they need different blur or movement. Do not blur an entire atlas containing crisp interactive icons.

### Poster or banner background

> A simple low-poly view of **[actual game location or approved scene]** in typhoon weather. Readable blocky architecture, a small player figure matching the supplied game model, muddy olive/green and wet charcoal, fog-softened distance, restrained rain, and one visual focal point. Indie-scale geometry, no cinematic detail explosion. For a 16:9 banner reserve the left 40–45% as calm, darker negative space for later live lettering and place the visual focal point to the right. For a portrait poster reserve an agreed text zone. Background only: no title, school logo, dates, signage, or generated words.

For branding, place the supplied `game/assets/branding/game_title.png` or an approved recolor of that exact logo over the finished background. Do not ask the generator to redraw the title, school logo, or festival details as part of the scene; generated lettering is difficult to correct and reuse. Keep the source logo untouched and save any recolor as a separate transparent PNG.

## Delivery and Godot assembly

1. **Separate by purpose.** Export independent icons, panels, masks, overlays, and backgrounds as separate files. Use descriptive lowercase names such as `lotto_apple.png`, `lotto_foil.png`, `storm_leaves_foreground_soft.png`. Do not flatten independently animated, scratchable, or depth-layered pieces together.
2. **Use real alpha.** Deliver lossless RGBA PNG for cutouts, with transparent pixels outside the art. Inspect the alpha in an image editor over both light and dark backdrops. Remove white/black mattes, fringe halos, fake checkerboards, and cast shadows unless the shadow is intentionally part of the asset. Full backgrounds may be opaque RGB/RGBA PNG.
3. **Keep geometry consistent.** For an icon family, use the same 256 × 256 master canvas, camera/view, approximate object occupancy, lighting, outline weight, and transparent padding. Do not stretch icons independently in Godot. Preserve aspect ratio in `TextureRect` or `AtlasTexture`.
4. **Build atlases after generation.** Prefer individual source PNGs for revisions. If an atlas is useful, place approved icons into a regular grid yourself rather than relying on a generated contact sheet. Example: four columns × two rows of 256 px cells = 1024 × 512 PNG; keep every silhouette at least 16 px inside its cell. Record each ID and exact pixel rectangle (`x, y, width, height`) in a small manifest or feature README; use those rectangles for `AtlasTexture.region`. The current fruit atlas uses uneven row regions documented in `game/assets/scratch_lotto/README.md`; do not replace those coordinates by assumption.
5. **Keep behavior and text live.** Titles, prices, cash, results, localization, button labels, hover/pressed/disabled/focus states, scratch progress, and hit targets belong in Godot controls and scripts. If a special decorative button absolutely needs raster state art, export each state on the same canvas with identical alignment and leave its text separate.
6. **Check import and final size.** Import PNGs through Godot normally; do not hand-edit `.godot/` output or generated `.import` files. Compare nearest and linear texture filtering at the actual display size, choosing the one that preserves the intended chunky edge without unreadable shimmer. Preview with VHS both on and off, at relevant viewport sizes and UI scale settings. A large, attractive source image is not sufficient if the 24–64 px result is muddy.
7. **Retain source and provenance.** Keep the prompt, reference-image roles, original full-size outputs, approved exports, and atlas crop map together in the asset's source folder or feature README. Keep file names and IDs stable once referenced by Godot scenes/scripts. Preserve supplied logos and reference files; make revisions as separate outputs.

### Suggested file contract

| Asset | Delivery | Keep separate from |
| --- | --- | --- |
| Item/reward icon | One 256 × 256 RGBA PNG per ID, same view and inset | Labels, values, hover state |
| Fixed illustrated ticket | One RGBA PNG with documented aspect ratio and blank text zones | Symbols, foil, live text, hit targets |
| Scratch foil | One RGBA PNG sized to the well's aspect ratio, opaque over the reveal area | Scratch mask and hidden reward |
| Scalable decorated frame | RGBA PNG plus measured nine-slice margins | Live text/buttons and focus outline |
| Atmospheric layer | Separate RGBA PNG per depth/blur layer | Scene and HUD |
| 3D surface | Seamless square color texture plus the source/model UV reference | Geometry and dynamic lighting |
| Full scene/banner | Opaque PNG at the target aspect ratio with a documented text-safe area | Title, date, logo, actionable UI |

For an atlas, include a readable crop map beside the PNG. For example, a new regular 4 × 2 atlas of 256 px cells can record `apple: [0, 0, 256, 256]`, `orange: [256, 0, 256, 256]`, continuing in reading order. State that the rectangle means `[x, y, width, height]`, and record the intended display size separately. Measure the final assembled PNG; generated contact sheets often have uneven gaps, as the current lotto atlas does.

## Approval check for a new asset set

- It is immediately recognizable at final on-screen size and visually belongs beside the current game model/UI.
- The world art reads as simple PSX-inspired indie 3D; UI art reads as restrained printed/faceted illustration.
- The palette is stormy and muddy overall, with saturated rewards/accent marks used sparingly.
- No unintended text, labels, fake controls, backgrounds on cutouts, or alpha fringes remain.
- All assets have consistent scale, orientation, padding, and naming; atlas coordinates have been verified.
- The UI can still localize, resize, focus by keyboard, and change state without editing the PNG.
- The assembled screen has been inspected in Godot at gameplay size with VHS on and off.

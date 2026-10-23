# Map cloud asset preview and implementation plan

Status: assets and standalone preview only; runtime integration awaits approval.

## Generated assets
Built-in Imagegen generated four independent RGBA files with real alpha:
- cloud_drift_a.png: 2172 x 724, light elongated ink-wash cloud.
- cloud_drift_b.png: 1774 x 887, light curling cloud.
- cloud_bank_left.png and cloud_bank_right.png: 1024 x 1536, dark side banks.
Original generated files remain under the Codex generated_images folder. map_reference.png is the user's screenshot, not generated artwork.
Open preview.html to inspect slow motion and coverage using the slider. It demonstrates composition only; screenshot storm position and clock do not change. No game scripts, scenes, or runtime assets were changed.

## Proposed implementation
1. Reuse MapScreen's artwork/control separation. Add cloud drawing above paper but below destination nodes, status labels, HUD, confirmation, and End the Day. Cloud controls ignore mouse input; cursor remains on top.
2. Use these separate textures with restrained alpha, linear filtering, continuous delta-based sine drift (roughly 40-60 second cycles, 8-24 logical pixel excursions). No random frame offsets, snapping loops, or gameplay particles.
3. Derive target coverage from the existing normalized storm clock and storm approach toward home. Use a monotonic eased envelope so sides darken and advance steadily, strongest in the final quarter. Smooth displayed progress to avoid jumps at minute ticks. Opening the map initializes to current progress rather than replaying an invasion.
4. Keep node icons AND their label/status areas clear with feathered safe regions. Protect HUD/control bounds across UI scaling. Confine dense clouds to sides; retain central route readability. The screenshot preview approximates those safe areas; runtime must use actual bounds.
5. Keep animation inactive while map is hidden. Preserve clock, closures, travel costs, and existing storm authority.
6. Verify with Godot 4.6.1 CLI: existing map regression, cloud progress monotonicity, input pass-through, reopen at late storm, and captures at early/middle/late progress with VHS on/off, English/Tagalog, 100/175% UI, 16:9 and ultrawide. Inspect motion for smoothness separately from static captures.

## Tradeoff
Use texture motion rather than fluid simulation: predictable, low cost, and consistent with printed map art. Feathered protected areas avoid unreadable labels when clouds advance behind them.

## Delegation status
The astra-flash-orchestrator doctor failed because the selected deepseek/deepseek-v4.1-flash route is missing or duplicated in the local catalog; routing.json is absent. No worker provider was substituted. Resolve this route or explicitly choose a different implementation workflow before delegation.

## Generation prompts
### Asset 1
Use case: stylized-concept. Asset type: separate transparent atmospheric sprite for a parchment illustrated game map. Generate ONE elongated wispy cloud cluster, soft warm gray and desaturated olive charcoal, light and airy with generous gaps. Antique hand-drawn graphite contour and diluted ink-wash illustration, restrained stippling and paper-print imperfections INSIDE cloud only. Broad organic billowing shapes, tapered wisps, delicate translucent edges. Flat illustration, no 3D, no photorealism, no glossy gradients. Landscape canvas, full silhouette within transparent margin. It should blend beside hand-inked trees and buildings on aged ivory parchment. No parchment/background, no sky, no text, no map, no rain, no lightning, no symbols, no fake checkerboard. True transparent RGBA background. This is a reusable light cloud for very slow gentle map drift.

### Asset 2
Use case: stylized-concept. Asset type: separate transparent atmospheric sprite for a parchment illustrated game map. Generate ONE low stretched curling mist-cloud cluster with two uneven lobes and thin trailing wisps, distinct from a round puff. Pale warm gray with muted olive charcoal linework, light airy watercolor and graphite ink wash, restrained stippled printed texture inside cloud only, broad organic forms and delicate semitransparent boundaries. Flat antique illustrated-map style, no 3D or photorealism. Landscape canvas with generous transparent padding around entire silhouette. No parchment, no solid background, no text, no objects, no rain, no lightning, no checkerboard. True transparent RGBA background. Intended for subtle slow drift over empty regions of aged ivory illustrated game map.

### Asset 3
Use case: stylized-concept. Asset type: transparent LEFT EDGE storm-cloud bank for illustrated parchment game map. ONE tall irregular mass of dark billowing storm clouds concentrated on LEFT edge, dense wet charcoal and muddy olive-gray at far left, tapering in ragged organic soft tendrils toward RIGHT into true transparency. Antique graphite and ink-wash illustration with restrained print stipple, broad sculpted organic cloud lobes, warm charcoal shadows, muted gray highlights, no hard rectangular silhouette. Portrait composition, full top and bottom ends softly taper with transparent margins; left mass may meet left boundary for edge overlay. Rightmost half predominantly transparent, no center-filling fog. No map, no parchment, no background, no text, no lightning, no objects, no checkerboard. Flat painted 2D, not photographic. True transparent RGBA. Designed to subtly engulf map edges as typhoon approaches while center stays clear.

### Asset 4
Use case: stylized-concept. Asset type: transparent RIGHT EDGE storm-cloud bank for illustrated parchment game map. ONE tall asymmetric rolling storm bank concentrated on RIGHT edge with a heavier upper lobe and lower curling tendrils, distinct irregular silhouette. Dense wet charcoal and desaturated olive-gray at far right, tapering toward LEFT into delicate transparent wisps. Antique graphite and ink-wash map illustration, restrained print stipple inside clouds, broad soft organic cloud contours, warm charcoal shadows, muted gray highlights. Portrait composition, top and bottom ends taper into transparent margins; cloud mass may touch right border. Leftmost half predominantly transparent. No map, no paper, no solid sky/background, no text, no lightning, no objects, no fake checkerboard. Not photographic or 3D. True transparent RGBA. Edge-overlay asset for approaching typhoon.


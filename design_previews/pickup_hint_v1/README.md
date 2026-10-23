# Pickup hint wisp — visual review

- `pickup_hint_reference.png`: concept over the current bodega screenshot. The separate pale motes follow the existing route toward the pickup. This is an image reference, not an in-game capture.
- `pickup_hint_wisp.png`: one reusable RGBA particle sprite with transparent surroundings. It is intentionally separate from the route and can be tinted, scaled, faded, and moved by Godot.

The visual direction is about 7–10 small motes at a time, gently drifting around the existing path. Remove the solid green ribbon when this is implemented; keep routing and pickup eligibility as they are. No scene or script has been changed for this preview.

## Generation provenance

The game screenshot was the composition reference for the mockup. The supplied white-particle image was a mood reference only; its checkerboard and watermark were excluded. The standalone sprite was generated without a source image.

Reference prompt: “Preserve the dim PSX-style room, player, props, and HUD from the game screenshot. Remove the flat green ribbon and yellow glow. Show roughly 7–10 separate small ivory-white wisps at ankle-to-knee height along the same route toward the left-hand pickup. Give a few motes very short, curved windy tails. No joined line, ribbon, dense particle cloud, checkerboard, watermark, or copied snowflake shapes.”

Sprite prompt: “Create exactly one isolated, small off-white wisp mote for a Godot particle sprite on a genuinely transparent RGBA square canvas. Give it an irregular light head, a short curved tapered tail, and one or two nearby pinpoints. Keep broad transparent padding and restrained brightness. No line, particle field, text, checkerboard, or watermark.”

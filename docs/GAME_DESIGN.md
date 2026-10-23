# Game design: current scope and historical intent

## Recording-only house teaser

The developer Recording Camera offers the visually approved **House teaser** location with **Normal** and **Wrecked** states. Normal uses the gameplay house's furniture, TV, sofa, doors and surrounding trees. Normal includes Nanay/Lola visuals controlled by **Hide NPCs**; Wrecked retains the approved empty-house composition. Wrecked omits door leaves and includes recognizable typhoon damage, muddy flood water, floating household items and wall waterlines. Default Stormy adds the existing gloomy storm sky/fog and rain; ordinary dry presets replace that look consistently. **G** switches the aligned states from the same camera shot. This is a trailer capture tool and does not create a playable post-storm location or change preparation outcomes.

Audited 2026-09-16–17. Implementation statements come from the repository; history is supplementary. **Implemented** means source and scene wiring exist, not that this audit playtested them. Technical details belong in [ARCHITECTURE.md](ARCHITECTURE.md); uncommitted future work belongs in [ROADMAP.md](ROADMAP.md).

## Overview and high concept

**Bagyong Bahay** is a household disaster-preparation game set around a Filipino family and neighborhood. The configured application title is `Software Festival 2026`. The player explores 3D locations through a 2.5D follow camera, collects supplies, makes purchases and optional social choices, and prepares the house before the storm deadline. A Windows Desktop x86_64 export preset exists. Other release platforms and release readiness: **Unknown / Needs verification**.

The apparent stage is playable festival/beta scope, based on the preparation loop and explicit beta-scope comments in `MapScreen.gd` and `StormEnroachment.gd`. It is not evidence of a finished four-act game.

## Intended experience and design pillars

These are synthesized from the current loop and the selected histories below, not a recovered formal original design document:

- **Preparation under constraint:** time, cash and inventory capacity force prioritization. Difficulty changes pacing, Nanay's cash and leaderboard multipliers. Historical dialogue direction explicitly emphasized that the player cannot save everything.
- **Family and neighborhood responsibility:** Nanay/Lola objectives and optional neighbor requests give supplies a social context. The Ate Linda history explicitly sought a reason to visit an otherwise unattractive expensive shop.
- **Meaningful voluntary choices:** accept/decline prompts allow trades, entrusted-money errands, donation and smoke-break choices. These are specific authored interactions, not a general reputation/morale simulation.
- **Storm pressure made visible and audible:** the clock, map restrictions, rain, thunder and ending shots communicate approaching danger.
- **Readable bilingual play:** English/Tagalog and adjustable UI presentation support accessibility. Complete translation and accessibility coverage remain unverified.
- **Milestone 2 deadline behavior:** storm arrival takes priority over travel; tasks completed at the deadline count toward the ending, while interrupted uncommitted tasks retain their supplies. A full backpack can exchange Nestor's chicken for the tarp. Quest prompts switch languages, while existing English action labels remain authored choices.

## Current gameplay loop

### Ambient neighborhood animals

Five decorative animals add quiet movement to the shopping locations: Palengke has one resting cat, one walking cat and one wandering dog; Tindahan has a resting cat beside the counter and a walking dog on the left sidewalk. Species and areas remain fixed. Each visit chooses among three coats per species and varies animation timing, pauses and rests. Cats sit and occasionally stand; dogs sniff, wag, sit or lie down between short walking legs. Only Palengke's dog occasionally runs. Moving animals pause near the player and have no collision bodies, so shops, NPCs and walkways remain usable. They stop during game pause/storm transitions and leave with their location. No animal interactions, quests, sounds or ending-scene animals are included.

```text
Intro → menu/difficulty → home, opening animation/tutorial, running clock
  → speak to family and discover household needs
  → choose routes, supplies and optional neighbor interactions
  → return home and spend supplies/time on preparation
  → repeat while time remains
  → End Day or storm deadline → six preparation outcomes → local score → menu
```

This is a description of the intended route through implemented interactions, not a claim that every step is forcibly gated. The main menu enters home directly; older Act1 state names do not drive this entire sequence.

## Current player mechanics

| Mechanic | Current implementation | Planned distinction |
| --- | --- | --- |
| Movement/camera | WASD, Shift sprint, step-up collision handling, animated PlayerV2 and camera volumes | No confirmed new movement feature. Jump/crouch/flashlight bindings do not make those features active in PlayerV2. |
| Interaction | Nearby Area3D targets, E interaction, Space dialogue advance, typewriter/portrait presentation | No general branching dialogue editor or systemic relationship simulation established. |
| Preparation | Six needs in `NeedsLog`: roof, medicine, food, windows, water, flashlight | Old rope/first-aid/rescue/corruption fields are not completed mechanics. |
| Inventory | Seven slots, canned-goods/nails stacking, two battery recipes, one recoverable discard stack | No general crafting tree or equipment system established. |
| Economy | Cash, catalogue prices/stock, named quest trades and optional pharmacy Lottohan | The older generic barter API is not evidence of all proposed NPC trading routes. |
| Travel | Five map destinations; graph costs plus variation and danger penalty; whole-scene travel | Richer route-risk events were proposed, not implemented. |
| Time pressure | 720 in-game minutes; passive time plus action/travel costs; map/backpack keep time running | A generalized storm-event system remains a proposal. |

Preparation details are defined by task scripts, resource types and scene overrides. The roof uses tarp/nails/hammer; food requires four canned goods; two individually tracked windows require plywood/nails/hammer; medicine, water and combined radio/flashlight complete the remaining needs. Hammer is retained as a tool; the current wrench is consumed because its resource retains the default item type. See the architecture task table for costs and source owners.

### Pharmacy Lottohan

The lotto counter offers Suerte Scratch as an optional cash risk during the preparation clock. Each ticket costs ₱50 and has six independently drawn fruit, arranged in two horizontal rows. Three identical fruit in one row wins that fruit's prize; both rows can pay. Players may scratch each foil well or use Scratch All. A paid ticket resolves before the player leaves or the storm ends the visit. The clock continues while the screen is open, and buying adds no separate time cost. Rewards change cash only; the leaderboard formula is unchanged.

| Fruit | Draw weight per well | Prize per matching row |
| --- | ---: | ---: |
| Apple | 28% | ₱180 |
| Banana | 24% | ₱240 |
| Orange | 18% | ₱350 |
| Watermelon | 12% | ₱600 |
| Grapes | 8% | ₱900 |
| Cherries | 5% | ₱1,200 |
| Peach | 3% | ₱2,500 |
| Raspberry | 2% | ₱5,000 |

Draws are independent and do not change with difficulty, current cash or previous tickets. The chance of at least one winning row is about 8.61%; average payout is ₱22.13 per ₱50 ticket. Repeated play usually consumes money needed for house preparation, while a rare win can fund several supplies.

### Internal Dev Mode

Dev Mode is a testing overlay on the existing Story, Standard and Challenge difficulties. An idle main-menu `HELLOWORLD` sequence unlocks a session-only Settings toggle in editor runs and tagged internal debug exports. When enabled, the pause menu can add/remove cash, hold or reset the preparation clock, and teleport among the five map destinations and bodega without travel cost or storm closure checks. Clock reset preserves current run progress and reopens storm-closed locations; it cannot reverse storm arrival. Any run enabled with Dev Mode is unranked, including after the toggle is turned off. The public release build has no usable Dev Mode controls.

### Recording teaser footage with Dev Mode

Pause → Dev Mode includes a Recording Camera section. Enter Camera Mode hides gameplay HUD/menus and flies through scenery independently of the player. WASD flies relative to the view; mouse looks around; E/Q moves up/down; Shift speeds up; mouse wheel zooms between 20–100 degrees; Alt+C toggles stabilized movement at one quarter speed; P toggles live/frozen world time. Escape restores the normal view and paused Dev tab. The preparation clock/deadline is held in both world modes. The player stays in place with gameplay processing disabled. Instructions and speed/sensitivity settings stay in the Dev panel.

Separate hide settings cover player, NPCs, animals, pickable items and world indicators, including task glows and pickup guidance. Completed physical preparations stay visible. Defaults hide player and indicators, keep other entities visible, use Play Time with cinematic movement off, and retain current graphics effects. Settings and per-environment adjustments last only for the app session. The last camera position/direction/zoom is remembered while that location remains loaded; Reset Camera returns to normal gameplay framing. Changing location uses Escape → Dev teleport → enter camera again and starts a new shot.

Default Stormy preserves the location's authored weather. Sunrise Morning uses the supplied Citrus Orchard sky and warm low sunlight; Clear Sunny uses a procedural blue sky; Sunset uses the supplied Belfast panorama. Brightness, sun strength, fog amount and sky rotation are bounded recording adjustments; Reset Preset resets only the selected look. Sun strength is unavailable in interiors with intentionally inactive sunlight. Dry looks mute rain/wind/thunder while retaining unrelated ambient sound. VHS/CRT and depth of field can be temporarily toggled for the take. Preparing settings in Pause does not apply them to gameplay; exit restores authored rendering and current saved graphics quality.

The tool records no video itself and supplies no camera paths. Free flight can reveal unfinished scenery and leave fixed rain volumes. The supplied 1K panoramas can appear soft at strong zoom. Keyboard/mouse feel, framing and cinematic smoothness require manual acceptance on the recording machine.

## Progression and outcomes

Nanay's initial completed conversation grants difficulty cash and unlocks household task cues; Lola introduces medicine. Discovering all needs completes an exploration guide objective. There is no implemented experience/level progression.

The ending evaluates the six resolved needs with different preparation weights: food 3; water and Lola's medicine 2 each; roof, both windows, and radio/flashlight 1 each. A complete household has 10 weight points. Each point contributes 2,000 score before difficulty scaling; delivering Mang Nestor's chicken contributes another 1,000, followed by the existing remaining-time bonus. Thus helping Nestor rewards a promise kept, while household needs remain the score's first priority. Lotto remains an optional, high-variance detour rather than a dependable supply strategy.

The household result describes preparation, with need-specific shortages instead of guaranteed injury or death inferred from task counts. Nestor appears in the ending only after accepting his errand: delivery shows that he went home with food, while an unfinished errand shows him still waiting. An unfinished state cannot establish whether the player kept the advance deliberately. Visited finished town locations add short cinematic context with gentle camera orbits around editable focus points and their corresponding shop lighting/environment; Barangay Hall and Mang Romy are omitted until their environments are complete. The final score restores the original message about annual typhoons, failed flood-control promises, and public accountability. It remains on screen until the player presses a key or button before the leaderboard name prompt. This does not establish playable corruption investigation, rescue missions, or the older named `EndingResolver` mentioned in comments.

Nanay and town NPCs emphasize actionable words in dialogue. In the bodega and hardware store, a subtle stream of lightly glowing wind-like motes with short trails periodically travels close to the ground along a safe route from the player toward vital free pickups while the player can move. It stops after collection or when the item no longer helps, and remains hidden when no safe route exists. The backpack and clock rules are unchanged.

## World and NPC design

Current map destinations are Home, Ate Linda's, Hardware Store, Botika/pharmacy and Palengke/grocery. Bodega is a home interior. Barangay Hall and Mang Romy scenes/registry entries exist but are cut from the current five-node map, per source comments. The earlier missing Tindahan scene reference was removed in Milestone 1; travel still needs gameplay verification beyond scene presence.
The map uses a sparse printed-paper illustration with five fixed roads, separate hand-drawn destination icons centered over the printed location circles, and a moving layered ink storm. A fixed cloud-and-rain wash makes the storm's upper-right starting area visible at the beginning of a run. Destinations retain live travel confirmation, current-location and danger/closure indicators; players can press M to open or close the map or choose End the Day to finish early. The illustration does not define all travel routes: the travel graph still determines costs and availability.

Current optional content includes:

- Ate Linda: trade away a hammer to unlock lower prices through another shop catalogue. Declining the offer still opens her regular-price shop; the offer returns at the next interaction. Accepting changes prices without replenishing stock already bought there.
- Mang Nestor: accept money to buy half chicken, return it for a tarp and additional cash. The history explicitly chose a surprise tarp reward to make the risk worthwhile.
- MoneyBeggar: optional donation of 20 cash.
- SmokeBreakNPC: optional one-time 20-minute delay.
- Story NPCs: authored dialogue providing activity and context in the shops.

No enemy AI, navigation/perception, combat, or procedural world generation was found. These are not implied future requirements.

## Tension, art, audio and UX

Tension comes from shrinking preparation time, risky/closed destinations, limited supplies/cash and storm presentation. No evidence establishes a separate horror enemy, stealth or safe-room system.

Current presentation uses low-poly/PSX-style character content, an optional global VHS/CRT shader, lighting/fog, weather particles and vignette overlays. The shared theme uses Inter for body text and EAS VHS for headings, with charcoal, sea-green, ivory and amber controls. Larger dialogue and inventory text, a centered leaderboard, brief panel fades and restrained focus sounds support legibility without changing gameplay actions. The studio splash and menu title use the supplied 3 Netherite Ingots and Bagyong Bahay artwork; menu camera motion and lightning animate the environment while title/buttons remain fixed. Brighter amber task markers also identify the bodega tools and hardware plywood; completing a need briefly reports success beside the checklist. The ending includes completed needs, difficulty, remaining time and score alongside its narrative. These are current implementation observations, not a comprehensive art bible.

Audio combines music, ambient storm layers, UI/task SFX and dialogue chatter. Weather intensity responds to elapsed time/location state. Volume controls, quality presets, VHS toggle, language and UI scale are present. Tutorial suppression lasts for the process session, not across launches. Custom key remapping, comprehensive controller support and reduced-motion coverage: **Unknown / Needs verification**.

The approved dialogue portrait library covers all 17 active NPCs, including shop speakers, with model-based identities, location backgrounds and authored expressions that change with each line. All Player portrait states include the model's black rectangular glasses; shared inner thoughts use the cooler thinking portrait. The 68-image library is stored in `game/assets/npc_portraits/stylized/`, with the approved cast and expression assignments documented in `design_previews/dialogue_portraits_v2/`.

## History and implementation status

Seven selected accessible Codex tasks were reviewed, including their available turns. This is not an exhaustive archive of every ChatGPT Project conversation. Task IDs identify provenance for future retrieval; old assistant reports are not proof of runtime success.

| Historical task | ID | Current classification |
| --- | --- | --- |
| Plan next game features | `019e62bf-8084-7422-a873-877fdcd14a1c` | **Planned / Partially Implemented:** authored NPC tradeoffs exist, but proposed `StormEventManager`, `StormEventData`, `RouteRiskData`, `NpcRequestData` and household morale do not. These were suggestions, not a committed milestone. |
| Plan Ate Linda side quest | `019e77af-e20a-7722-aa5d-b724219c4ed1` | **Implemented in source:** hammer discount, Nestor chicken/tarp errand, optional choices and additional NPCs. |
| Update difficulty and UI prompts | `019e4394-1779-7763-a47e-e0072c7259ab` | **Implemented core behavior:** 0.8 Challenge pacing, nail stacking, weighted combined leaderboard, Tab backpack and clock continuing in map/backpack. The declared stack value 99 is not enforced. |
| Add menu parallax and intro | `019e6366-47dd-7401-aadf-0e63ad1bb87a` | **Partially Implemented / Superseded:** intro and environment motion remain; original moving UI and general-font plans changed later. |
| Match main menu effect | `019e64db-0d4d-7cb3-a05b-3be8c731838a` | **Implemented refinement:** stationary menu text with camera motion. Historical two-column ending checklist/text details differ from current source; later rationale is **Unclear**. |
| Add language selection | `019e655f-c893-72c0-b07d-170ece05c87e` | **Implemented infrastructure / Partial coverage:** English/Tagalog, settings and CSV. Historical English-only button intent is not a universal code exclusion; current automatic translation has no Button exemption. |
| Analyze project structure | `01a00af1-e0e1-7ed3-b9ad-df4ad320dfdc` | **Superseded cleanup:** user explicitly ordered reversal of asset deletion/menu patches after visual problems. Do not revive those deletions as approved work. Root cause of those historical visual problems is **Unclear**. |

## Scope and open questions

**Implemented:** the preparation loop and authored systems above. **In development:** current beta/festival scope is evident, but a developer-owned active task list is **Unknown / Needs verification**. **Planned:** uncommitted historical proposals are listed in the roadmap. **Explicitly out of current beta scope:** Mang Romy and Barangay Hall as map nodes; that does not mean permanent exclusion.

Unresolved decisions include the next approved milestone, whether broader act/outcome fields should ever become gameplay, engine migration timing, supported minimum hardware, complete localization scope, and whether pause/transition edge cases need behavior changes. The source does not settle these product questions.

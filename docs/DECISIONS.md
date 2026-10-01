# Architecture and design decisions

Recorded 2026-09-17 from current source and selected project tasks. Original decision dates are **Unknown / Needs verification**; the recording date must not be mistaken for when a choice was made. Accepted below means an explicit historical user choice supported by current code, not a new approval. Unrecorded technical rationale remains unknown.

## ADR-001 — Preserve time pressure in map and backpack

Date: Unknown / Needs verification (recorded 2026-09-17).

Status: Accepted.

### Context

The user requested map/backpack behavior that allows movement and keeps the clock running in **Update difficulty and UI prompts**, task `019e4394-1779-7763-a47e-e0072c7259ab`. Older timer comments still describe pausing these interfaces.

### Options considered

#### Option A — Pause the clock while browsing

Advantages: removes browsing time pressure. Disadvantages: conflicts with the later explicit request. This is the older described behavior, not a formally recovered evaluation.

#### Option B — Leave the clock running

Advantages: preserves the requested time pressure. Disadvantages: time can expire during UI use. These consequences follow from the implementation; no additional historical rationale is asserted.

### Decision and reasoning

Keep the current unpaused map/backpack behavior unless a new task changes it. The explicit correction is stronger evidence than stale header comments. Scene-tree pause and dialogue/shop timer pauses remain separate behaviors.

### Consequences

Positive: documentation and future tests can preserve intentional behavior. Tradeoff: input, overlays and ending transitions must handle an active clock.

### Relevant files

- `game/ui/map/MapScreen.gd`
- `game/ui/BackpackUI/BackpackUI.gd`
- `game/autoload/GlobalTimer.gd`

### Supersedes

Earlier map/backpack pause descriptions; no prior numbered ADR.

## ADR-002 — Give Ate Linda a tradeoff and make optional requests explicit

Date: Unknown / Needs verification (recorded 2026-09-17).

Status: Accepted.

### Context

In **Plan Ate Linda side quest**, task `019e77af-e20a-7722-aa5d-b724219c4ed1`, the user described the expensive shop as lacking a reason to visit. The user proposed a hammer trade for lower prices and an entrusted-money errand, later choosing a surprise tarp reward and asking for explicit accept/decline prompts.

### Options considered

#### Option A — Retain the higher-price shop without added incentive

Advantages: no additional quest content. Disadvantages: the user identified little reason to visit. This was the existing situation, not a formally documented design alternative.

#### Option B — Add the hammer discount and optional errand

Advantages: gives the shop a purpose and a supply tradeoff. Disadvantages: consumes a useful tool and adds authored state/reward handling. A battery reward was discussed and rejected as underwhelming; tarp was selected instead.

### Decision and reasoning

Use the authored hammer-for-discount interaction and Nestor chicken/tarp errand, with player choice. The explicit purpose was to make visiting worthwhile and reward the risk. Separate story NPCs were requested rather than replacing seller hint dialogue.

### Consequences

Positive: optional neighborhood interactions connect money, supplies and priorities. Tradeoffs: persistent flags, inventory capacity and rewards need regression checks; alternate catalogue paths currently retain separate stock. The latter is observed behavior, not recovered design intent.

### Relevant files

- `game/entities/ate_linda_npc/AteLindaQuestShop.gd`
- `game/entities/quest_npcs/MangNestor.gd`
- `game/entities/npc/QuestNPC.gd`
- `game/autoload/SideQuestLog.gd`
- `game/resources/items/shops/ate_linda_shop_discounted.tres`

### Supersedes

Initial automatic-acceptance behavior and proposed battery reward; no prior numbered ADR.

## ADR-003 — Keep menu text stationary while the environment moves

Date: Unknown / Needs verification (recorded 2026-09-17).

Status: Accepted.

### Context

**Add menu parallax and intro**, task `019e6366-47dd-7401-aadf-0e63ad1bb87a`, initially discussed layered title/button motion. **Match main menu effect**, task `019e64db-0d4d-7cb3-a05b-3be8c731838a`, explicitly corrected the effect using stationary title/buttons and moving environment camera.

### Options considered

#### Option A — Move title/buttons with layered parallax

Advantages: stronger layered motion. Disadvantages: did not match the user's later reference and preference.

#### Option B — Rotate the environment camera and keep UI stationary

Advantages: matches the requested reference behavior. Disadvantages: less UI motion; no other historical cost analysis was recorded.

### Decision and reasoning

The current `_apply_parallax()` changes camera rotation and restores camera position. Preserve stationary title/buttons; the explicit visual correction superseded the original plan.

### Consequences

Positive: clear separation of menu input layout and environmental motion. Tradeoff: test camera movement and button interactions together when changing presentation.

### Relevant files

- `game/scenes/main_menu/main_menu_1.gd`
- `game/scenes/main_menu/Main_Menu1.tscn`

### Supersedes

Original layered UI parallax proposal; no prior numbered ADR.

## Milestone 1 — Retire the obsolete shop route

Milestone 1 route decision, accepted 2026-09-24: the user explicitly selected retirement of the old door and `test_room2` route. The alternative was redirecting the old door to the current Tindahan, which would require deciding obsolete spawn/location semantics. Removed only that door subtree and mapping; current home/map routes remain. The missing hidden Tindahan greybox reference was separately removed because the current scene already has its GLB and collision imports; no deleted prototype geometry was restored. Godot 4.6.1 remains the target for this baseline.

## Milestone 2 — Deadline priority and pause ownership

Accepted 2026-09-25 through the approved Milestone 2 plan. Storm arrival supersedes travel and other pending fades. Completed task state is committed before its time charge; work interrupted before that commit retains its supplies. Reset invalidates pending transitions. Map/backpack time pressure remains unchanged.

Use a generation in the existing SceneManager and replaceable tweens in TransitionOverlay. A transition queue/new coordinator was unnecessary for the current single-scene loop; keeping the old fixed delay would not prevent stale continuations. Canceled fades must settle their callers, since killed Godot tweens do not emit `finished`.

The existing GlobalTimer accepts an optional Node owner. Owned pauses are idempotent, release on scene exit and are disconnected on reset. This avoids duplicated teardown logic across NPC/task/item classes and protects new runs from old-node cleanup. Anonymous pause/resume calls retain compatibility. Quest choices block reopening dialogue over the same owner. No resource IDs, persistence formats, dependencies or autoload registrations change.

## Choices whose rationale is not established

The repository demonstrates autoload-based session state, duplicated shop resources, a directed travel graph, seven inventory slots, and local JSON scores. It does not establish all original alternatives or reasons behind those choices. Do not fabricate Accepted ADRs for them. A 4.7 engine upgrade was mentioned in the old handoff, but acceptance/completion remains **Unknown / Needs verification**.

For a future significant decision, record its real date/status, problem, actual alternatives with pros/cons, selected approach and reasoning, consequences, relevant files and superseded ADR. Update [ARCHITECTURE.md](ARCHITECTURE.md) and [GAME_DESIGN.md](GAME_DESIGN.md) as applicable.

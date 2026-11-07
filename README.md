# Bagyong Bahay

A Filipino household prepares for an approaching storm. Explore the house, talk to family and neighbors, buy supplies, and choose how to spend limited money and time before the ending evaluates six preparation needs.

## Status

Playable festival/beta scope, inferred from the current loop and source scope comments. This repository includes older scenes and unfinished APIs alongside the current game. Documentation was audited on **2026-09-16–17**, against baseline commit `d280ee0`; gameplay was not playtested during that documentation audit.

## Engine and requirements

- **Godot 4.6.1**, standard GDScript build. `project.godot` declares 4.6 / Forward Plus; the local executable reports `4.6.1.stable.official.14d19694e`.
- Git and Git LFS for cloning the large assets.
- A graphics environment that supports this project's Forward Plus renderer. Measured minimum hardware requirements: **Unknown / Needs verification**.
- Windows Desktop x86_64 export preset exists; matching export templates are needed to export. No C#/.NET or runtime addon dependency was found.

The application/window title is `Bagyong Bahay`. Its custom user-data directory retains the former `Software Festival 2026` path so existing scores and settings remain available. The older handoff discusses a possible 4.7 upgrade; that is not evidence of a completed migration.

## Getting started

1. Clone the repository with Git LFS available and retrieve its LFS objects (`git lfs pull`).
2. In Godot 4.6.1, import the root `project.godot` and let assets import.
3. Run the project with **F6 only for a selected scene**, or **F5 for the complete game flow**. Prefer F5 when checking progression and resets.

## Running the game

The configured main scene is [IntroSequence.tscn](game/scenes/intro/IntroSequence.tscn). It leads to [Main_Menu1.tscn](game/scenes/main_menu/Main_Menu1.tscn). Choosing Start and a difficulty loads [house_inside.tscn](game/scenes/locations/house_inside.tscn) and plays the waking animation, followed by a short player monologue about waking with a sore back from sleeping on the floor, a strange dream, and hearing the TV from the kitchen. Press E to finish the monologue. The player can explore the house and bodega without a clock. Completing Nanay's first conversation starts preparation, reveals the clock/objectives and opens the optional tutorial. Until then, the map and outdoor travel are locked; approaching the front door explains why. The current menu does not enter the older Act1 scenes.

## Controls

| Input | Current behavior |
| --- | --- |
| W / A / S / D | Move |
| Shift | Sprint |
| E | Interact with the selected nearby object/NPC |
| Space | Advance/finish active dialogue through `dialogue_advance` |
| M | Open/close map |
| Tab | Open/close backpack |
| Escape | Pause/resume via `ui_cancel`; player also has an `escape` mouse-capture handler |
| Mouse | UI choices, shop purchases, inventory selection and drag-to-discard |

The bottom inventory bar is a passive seven-slot preview centered at the bottom, without an instruction badge. Wheel and number keys do not select or use items. The Input Map retains legacy jump, crouch, flashlight and hotbar bindings; PlayerV2 does not implement these actions. Map and backpack leave time running.

## Project structure

```text
game/
  autoload/                  # Registered global managers and session state
  assets/                    # Audio, item icons, portraits, fonts and visual assets
    audio/                   # Music, weather, broadcasts, dialogue, UI, gameplay, ambience
    item_icons/
    npc_portraits/           # Stylized, original and placeholder images
    reference_images/        # Retained reference screenshots
  audio/                     # AudioManager scene, bus layout and SFX helper
  camera/                    # Shared camera volumes
  entities/
    animals/
    npcs/                    # Base, models, family, shops, quests and story
    players/                 # Existing player and playerv2 implementations
  localization/              # English/Tagalog CSV and editing guide
  objects/                   # Interactables, props, models and world items
  resources/                 # Dialogue, items, shops, environments, navigation and voxels
  scenes/                    # Intro, menu, ending, locations, act1, recording and components
  shaders/
  tests/                     # Regression entry points and sandbox environments
  ui/                        # HUD, inventory, dialogue, theme, settings and feature panels
  weather/
```

Related scripts and scenes stay together; registered managers stay in `autoload/`.
`_raw_assets/` retains its existing model/texture bundles and remains a runtime dependency.
Older scenes and alternate characters are retained; folder grouping does not retire gameplay routes.
See the [development guide](docs/DEVELOPMENT.md) for reference and import preservation rules.

## Major systems

The current game includes a 2.5D player/camera, proximity interactions, resource-driven dialogue/items/shops, seven-slot inventory and combinations, household and optional NPC objectives, a 720-minute storm clock, five-node travel map, storm restrictions, preparation-based ending, local scores, audio/visual settings, and English/Tagalog localization. See [architecture](docs/ARCHITECTURE.md) for ownership and data flows.

## Development and testing

Read [development](docs/DEVELOPMENT.md) for conventions and workflows, [testing](docs/TESTING.md) for validation and smoke checks, and [AGENTS.md](AGENTS.md) before an AI-assisted change.

## Documentation

- [Current notices and public-export checklist](docs/audits/2026-11-07-public-release-notices.md), [asset inventory](docs/audits/2026-11-04-asset-inventory.csv), and the dated [November 4 credits audit](docs/audits/2026-11-04-asset-credits.md).
- [Project permission for free personal and educational play](LICENSE.txt), [privacy and local data](game/legal/PRIVACY.txt), and [AI assistance disclosure](game/legal/AI_DISCLOSURE.txt). Third-party licenses apply to their respective works.
- [Architecture](docs/ARCHITECTURE.md): current implementation.
- [Game design](docs/GAME_DESIGN.md): player experience and implementation/history distinctions.
- [Development](docs/DEVELOPMENT.md): working in the repository.
- [Testing](docs/TESTING.md): real validation procedures and limits.
- [Decisions](docs/DECISIONS.md): evidence-backed choices.
- [Roadmap](docs/ROADMAP.md): future work and uncommitted proposals.
- [Historical handoff](PROJECT_HANDOFF.md): dated 2026-08-31; not the current operating guide.

## Known limitations

- Milestone 1 removed Tindahan's broken hidden greybox reference and retired the unused `test_room2` route/old Act1 door. Normal-timing scripted validation is available in `game/tests/milestone1_smoke.tscn`; full manual coverage remains separate.
- Gameplay sessions cannot be saved/resumed. Disk persistence covers settings and local leaderboard entries.
- Localization is implemented, but complete dynamic-text coverage is not established.
- No third-party automated test framework or CI test workflow is configured; a focused headless regression scene is available. See the [roadmap](docs/ROADMAP.md) for verified issues and explicitly proposed follow-up work.

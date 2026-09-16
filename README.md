# Bagyong Bahay

A Filipino household prepares for an approaching storm. Explore the house, talk to family and neighbors, buy supplies, and choose how to spend limited money and time before the ending evaluates six preparation needs.

## Status

Playable festival/beta scope, inferred from the current loop and source scope comments. This repository includes older scenes and unfinished APIs alongside the current game. Documentation was audited on **2026-09-16–17**, against baseline commit `d280ee0`; gameplay was not playtested during that documentation audit.

## Engine and requirements

- **Godot 4.6.1**, standard GDScript build. `project.godot` declares 4.6 / Forward Plus; the local executable reports `4.6.1.stable.official.14d19694e`.
- Git and Git LFS for cloning the large assets.
- A graphics environment that supports this project's Forward Plus renderer. Measured minimum hardware requirements: **Unknown / Needs verification**.
- Windows Desktop x86_64 export preset exists; matching export templates are needed to export. No C#/.NET or runtime addon dependency was found.

The application setting still names the project `Software Festival 2026`. The older handoff discusses a possible 4.7 upgrade; that is not evidence of a completed migration.

## Getting started

1. Clone the repository with Git LFS available and retrieve its LFS objects (`git lfs pull`).
2. In Godot 4.6.1, import the root `project.godot` and let assets import.
3. Run the project with **F6 only for a selected scene**, or **F5 for the complete game flow**. Prefer F5 when checking progression and resets.

## Running the game

The configured main scene is [IntroSequence.tscn](game/scenes/intro/IntroSequence.tscn). It leads to [Main_Menu1.tscn](game/scenes/main_menu/Main_Menu1.tscn). Choosing Start and a difficulty loads [house_inside.tscn](game/scenes/locations/house_inside.tscn), starts the clock, and plays the player's opening animation/tutorial flow. The current menu does not enter the older Act1 scenes.

## Controls

| Input | Current behavior |
| --- | --- |
| W / A / S / D | Move |
| Shift | Sprint |
| E | Interact with the selected nearby object/NPC |
| Space | Advance/finish active dialogue through `dialogue_advance` |
| M | Open/close map |
| Tab | Open/close backpack |
| 1–7 | Select hotbar slot |
| Mouse wheel | Hotbar selection; see limitation below |
| Escape | Pause/resume via `ui_cancel`; player also has an `escape` mouse-capture handler |
| Mouse | UI choices, shop purchases, inventory selection and drag-to-discard |

The Input Map also defines jump, crouch, flashlight, and hotbar key 8. The active PlayerV2 does not implement jump/crouch/flashlight actions. Key 8 clamps to the seventh slot; wheel cycling retains eight-slot arithmetic. Map and backpack currently leave time running.

## Project structure

- `game/autoload/`: global services and state, plus ordinary `TaskObject` and HUD scripts.
- `game/scenes/`: intro/menu/ending, location and older act scenes.
- `game/entities/`: current/legacy players, family, shop and quest NPCs, dialogue resources.
- `game/objects/interactables/`: doors, household tasks and interaction base.
- `game/resources/`: items, shops, environments, baked voxel data.
- `game/ui/`, `game/audio/`, `game/weather/`, `game/shaders/`: presentation.
- `game/localization/`: English/Tagalog CSV and [text editing guide](game/localization/README.md).
- `game/assets/`, `_raw_assets/`: assets; both are referenced by runtime scenes.
- `game/maps/`, `game/tests/`: supporting and exploratory scenes, not an automated test suite.

## Major systems

The current game includes a 2.5D player/camera, proximity interactions, resource-driven dialogue/items/shops, seven-slot inventory and combinations, household and optional NPC objectives, a 720-minute storm clock, five-node travel map, storm restrictions, preparation-based ending, local scores, audio/visual settings, and English/Tagalog localization. See [architecture](docs/ARCHITECTURE.md) for ownership and data flows.

## Development and testing

Read [development](docs/DEVELOPMENT.md) for conventions and workflows, [testing](docs/TESTING.md) for validation and smoke checks, and [AGENTS.md](AGENTS.md) before an AI-assisted change.

## Documentation

- [Architecture](docs/ARCHITECTURE.md): current implementation.
- [Game design](docs/GAME_DESIGN.md): player experience and implementation/history distinctions.
- [Development](docs/DEVELOPMENT.md): working in the repository.
- [Testing](docs/TESTING.md): real validation procedures and limits.
- [Decisions](docs/DECISIONS.md): evidence-backed choices.
- [Roadmap](docs/ROADMAP.md): future work and uncommitted proposals.
- [Historical handoff](PROJECT_HANDOFF.md): dated 2026-08-31; not the current operating guide.

## Known limitations

- `tindahan.tscn` contains a reference to a missing greybox scene; the `test_room2` route also targets a missing file. Runtime loading/recovery has not been verified in this audit.
- Gameplay sessions cannot be saved/resumed. Disk persistence covers settings and local leaderboard entries.
- Seven-slot inventory and eight-slot input arithmetic disagree.
- Localization is implemented, but complete dynamic-text coverage is not established.
- No automated test framework or CI test workflow was found. See the [roadmap](docs/ROADMAP.md) for verified issues and explicitly proposed follow-up work.

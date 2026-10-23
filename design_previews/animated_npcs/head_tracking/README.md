# Dialogue head tracking review

The 11 new NPCs now fidget after 4–7 idle seconds and turn their heads toward the player during dialogue. Head limits are 55 degrees left/right and 20 degrees up/down. Rear targets and dialogue closure restore authored motion.

Each sheet shows authored idle, left/right limits, up/down limits, a rear target, and restored idle. These are actual Godot renders in the four locations, using PlayerV2's head joint. Review fill lighting and hidden player/HUD/CRT are fixture settings only.

- [MangNestor sheet](MangNestor.jpg) and [action preview](MangNestor_head_tracking.mp4)
- [MoneyBeggar sheet](MoneyBeggar.jpg) and [action preview](MoneyBeggar_head_tracking.mp4)
- [SmokeBreakNPC](SmokeBreakNPC.jpg)
- [TapeNeighbor](TapeNeighbor.jpg)
- [TatayJun](TatayJun.jpg)
- [KapsWorker](KapsWorker.jpg)
- [AteMaribel](AteMaribel.jpg)
- [PalengkeQueueMan](PalengkeQueueMan.jpg)
- [PanicBuyer](PanicBuyer.jpg)
- [WetParent](WetParent.jpg)
- [PharmaDude](PharmaDude.jpg)

Godot 4.6.1 focused regression: 1,638 checks, 0 failures. The final bone poses, other bones, detection, dialogue, quests, donations, smoking, shopping, pause, and storm behavior are covered. See [runtime log](head_regression.log), [capture log](preview.log), [Testing](../../../docs/TESTING.md), and the [manual checklist](../../../_raw_assets/npc_assets/psx_animated/README.md#manual-test).

Manual gameplay acceptance and packaged builds are unchecked. Headless shutdown retains the existing resource diagnostics.

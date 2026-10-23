# Bagyong Bahay: controlled balance routes

**Date:** 5 October 2026

**Build assessed:** a disposable copy of the working checkout on that date, including its in-progress map and UI changes.

**Purpose:** compare Story, Standard, and Challenge, then examine limited-knowledge play, scratch tickets, and Mang Nestor's errand.

## Method and limits

The desktop game launched, but the available Windows control service failed to bind to its window. These are **controlled Godot runs, not hands-on player playthroughs**. A temporary runner outside the repository selected the difficulty through the main menu, dismissed the tutorial, completed Nanay and Lola's dialogue, used real scene travel, shop purchases, inventory rules, task completion, lotto UI rolls, quest state, and the End Day button. It chose each destination and item directly, picked up world items without walking to them or confirming their prompts, advanced dialogue immediately, invoked Nestor's accept/turn-in handlers rather than his choice buttons, and used Scratch All. No Dev Mode, free cash, forced lottery result, or altered game rule was used. The route scripts, test logs, and user data stayed in isolated temporary directories.

The knowledge labels describe deliberately restricted **decision policies**, not observations of human players learning. The remaining time is optimistic because walking, searching, reading, and manual scratching were skipped. Travel variance and passive time during scene changes cause small differences between otherwise identical routes. The ending tier below follows the current six-need thresholds; the End Day transition was exercised, but the entire cinematic was not watched in these route runs. Proximity, audio, and packaged Windows behavior remain unverified here.

Static screenshots of the home HUD, map, and pharmacy Lottohan were inspected at 1920×1080. The lotto screen shows the ₱50 ticket price and prize amounts, but no win odds. These captures do not establish whether players notice the controls or can read them comfortably across display settings.

The baseline integration smoke passed **54 checks, 0 failures**. The scratch-lotto regression passed **41 checks, 0 failures**. Ten selected route runs below completed with no runner failures. An exploratory lucky route initially hit the seven-slot inventory limit while carrying medicine; its runner reported failures, so it is not counted as a successful route. Completing medicine before the grocery trip resolved that planning mistake in the later winning run.

## Runs and player reasoning

| ID | Mode and knowledge | Decision policy / likely reasoning | Needs | Cash left | Game minutes left* | Ending tier |
| --- | --- | --- | ---: | ---: | ---: | --- |
| R1 | Story, limited information | Go to nearby Ate Linda first; buy four expensive cans, medicine, and water; miss the free hammer and plywood; later buy tools. | 3/6 | ₱16 | 612 | Hard night |
| R2 | Standard, one-run learning | Find the bodega hammer and free hardware plywood; shop at the cheaper grocery; miss the battery combinations. | 5/6 | ₱189 | 501 | Injured but alive |
| R3 | Story, fully informed | Use free pickups, cheap shops, both battery recipes, and an inventory-aware route; no quest or lotto. | 6/6 | ₱219 | 498 | Everyone survives |
| R4 | Standard, same informed route | Repeat R3's choices on Standard. | 6/6 | ₱119 | 490 | Everyone survives |
| R5 | Challenge, same informed route | Repeat R3's choices on Challenge. | 6/6 | ₱19 | 476 | Everyone survives |
| R6 | Challenge, keep Nestor's advance | Accept ₱150, never buy his chicken, and otherwise follow R5. His quest remains active. | 6/6 | ₱169 | 480 | Everyone survives |
| R7 | Challenge, complete Nestor's errand | Buy half chicken for ₱145, return it, receive the tarp and ₱5 change; then finish the informed route. | 6/6 | ₱139 | 436 | Everyone survives |
| R8 | Standard, gamble then protect essentials | Buy five ₱50 tickets; all lose. Prioritize food, medicine, water, and windows. | 4/6 | ₱61 | 501 | Injured but alive |
| R9 | Standard, lucky lotto | Buy five tickets; one pays ₱350. Complete medicine early to free bag space, then complete all needs. | 6/6 | ₱219 | 473 | Everyone survives |
| R10 | Standard, score-aware replay after losses | Buy five losing tickets, then maximize completed needs by omitting the costly food task. | 5/6 | ₱49 | 485 | Injured but alive |

\*Clock snapshots immediately before End Day. They are **not** human completion-time measurements. R8's losing five-ticket route was repeated twice with the same 4/6 result; only one representative appears in the table.

R1 is a plausible hurried first-run choice only if the player leaves before inspecting the fridge and bodega. The current fridge dialogue explicitly says the market is cheaper, and the tutorial explains combining. This study does **not** establish that those clues are invisible or ineffective; it shows the cost of missing or not acting on them. R1 spent money on a hammer and plywood available as free pickups, boarded only one window, and finished food, medicine, and water.

R2 shows how one discovery changes the outcome: Standard still has enough cash for the five needs this route understood. The uncompleted electronics need requires finding both dead devices and combining each with a battery. R3–R5 show mechanical feasibility of a full clear across all three modes with the same known route. The common required basket cost **₱581** with a free hammer and two free plywood pickups: three nails ₱36, tarp ₱110, wrench ₱75, four cans ₱180, water ₱55, two grocery batteries ₱70, medicine ₱55. Challenge's ₱600 start therefore leaves only **₱19** without another cash source.

R6 and R7 expose an uneven quest incentive. Completing Nestor's errand improves the full-clear cash balance by ₱120 relative to R5: ₱150 advance − ₱145 chicken + ₱5 change + ₱110 tarp saved. Keeping his advance improves it by ₱150 and avoids the chicken detour. The active, unfinished quest did not lower the six-needs result or score in the run. R6's slightly higher remaining time than R5 reflects random travel variation and should not be treated as a measured speed advantage; R7 did require extra travel.

R8–R10 show how the same five-ticket gamble can change decisions. Each ticket costs ₱50; five losing tickets reduce Standard's ₱700 to ₱450 before supplies, **₱131 short** of the ₱581 full basket. R8's family-first choices completed four needs. R10 spent ₱401 on the other five needs and skipped four cans costing ₱180. Because the score gives every need the same 1,000-point contribution, R10 scored more despite leaving the household without stored food. R9's single ₱350 prize more than covered the ₱250 stake and funded all six; it is a lucky outcome, not a reliable route.

## What the current rules imply

- **Difficulty:** Story, Standard, and Challenge give ₱800/₱700/₱600 and tick one game minute every 2.0/1.5/0.8 real seconds. The 720-minute clock would last 24/18/9.6 real minutes without action costs or pauses. Dialogue, shop, and task interactions pause it; map and backpack use do not. The optimized controlled route reached the grocery before its 360-minute closure in all modes, but this cannot establish how much time real players spend searching or reading.
- **Lotto:** The eight fruit weights and prizes produce a **4.4008%** chance of a winning row, an **8.6079%** chance of any win per ticket, and an average payout of **₱22.13** per ₱50 ticket (about **₱27.87 expected loss**). Five independent tickets have a **63.76%** chance of no win. These are exact consequences of the configured independent draws, not an estimate from the small sample. The screen's “Try again?” prompt can invite repeated purchases while the game clock continues.
- **Inventory:** Seven slots make purchase and task order part of the challenge. Cans and nails stack; most other items do not. In the excluded exploratory lucky run, carrying medicine, tools, both dead devices, and grocery supplies filled the bag before batteries. The store rejected the purchases without charging the player. Completing medicine before that trip freed a slot and enabled R9's full clear.
- **Endings and score:** Six resolved needs get the all-survive result; four or five get the injured-but-alive result; two or three get the hard-night result. Score is `(1,000 × resolved needs + remaining game minutes) × difficulty multiplier`. It does not examine Nestor's unfinished advance or distinguish food from the other needs.

## Balance opinions and recommended decisions

1. **High confidence — Nestor's unfinished advance is the strongest unintended-looking strategy.** R6 is richer and avoids the honest errand without an observable ending or score cost. Decide whether keeping entrusted money is an intentional moral choice. If it is, give that choice a visible narrative consequence. If it is not, remove the cash advantage until the errand is completed. Preserve an honest route that remains worthwhile.
2. **High confidence — lotto is a high-variance detour, not a dependable preparation strategy.** The expected loss and 63.76% five-ticket no-win chance are large relative to Standard's ₱119 full-clear cash margin. If its purpose is an optional gamble, the current economics serve that purpose; make its risk clear enough for players to consent knowingly. If it is meant to be a viable alternate route, adjust odds/prizes or add a separate safety mechanism only after choosing that design goal.
3. **High confidence — equal need scoring rewards counterintuitive omissions.** R10 could improve the task count after gambling by leaving food unresolved. If the leaderboard should reflect preparedness rather than checkbox count, consider weighting needs or adding an explicit consequence for missing critical supplies. Keep the narrative ending and score rules aligned.
4. **Medium confidence — Story may still punish missed knowledge sharply.** R1 finished 3/6 despite the largest cash budget. Existing tutorial and task hints already explain some solutions, so do not raise starting cash blindly. First check whether new players notice the bodega, free plywood cues, cheaper market clue, and two battery recipes. A small, timely hint or Story-specific cushion may be enough.
5. **Medium confidence — bag order is meaningful but can obscure a successful plan.** R9 needed an extra home task before shopping to free a slot. Test whether a player understands why the battery purchase was rejected and can recover without discarding a critical item. Improve feedback if that recovery is unclear; the seven-slot rule itself need not change yet.
6. **Insufficient human evidence — hold off on clock retuning.** Challenge's shorter real-time clock matters most while walking, reading, opening the map/backpack, and choosing purchases. These controlled routes skip much of that time. Test actual first-time and returning-player completion time before changing the three rates.

## Verification and remaining work

- Godot 4.6.1 source runtime: Milestone 1 smoke **54/54** and scratch-lotto regression **41/41**. All ten selected route runs reached the End Day transition with zero runner failures. The exploratory full-bag lotto route is excluded from that count.
- Most rapid scripted multi-scene runs logged a deferred `VisualSettings._apply_quality_to_node` argument-conversion error. Its queued node can be freed by a scene change before the deferred call; that explanation is a source-based inference, not a verified root-cause fix. The focused smoke did not log this error. Godot also logged shutdown ObjectDB/resource diagnostics. These are technical follow-ups, separate from balance conclusions.
- A hands-on follow-up should use anonymized first-time and returning players in each mode. Record route, discovered needs, missed pickups, purchases, tickets, Nestor choice, inventory-full feedback, unpaused real duration, game minutes, cash, and ending. Keep developer test runs separate from human playtests and from packaged Windows acceptance.
- No gameplay, balance, quest, resource, or leaderboard files were changed for this assessment.

**Current source anchors:** [difficulty and cash](../game/autoload/GameState.gd), [clock](../game/autoload/GlobalTimer.gd), [travel](../game/autoload/TravelCalculator.gd), [lotto rules](../game/ui/lotto/ScratchLottoRules.gd), [Nestor](../game/entities/npcs/quests/MangNestor.gd), [inventory](../game/autoload/InventoryManager.gd), [score](../game/autoload/LeaderboardManager.gd), [ending](../game/scenes/ending/EndingSequence.gd), and [tutorial](../game/ui/tutorial/TutorialModal.gd).

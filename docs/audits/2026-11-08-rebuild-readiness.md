# Source review before the next Windows rebuild

November 8, 2026, Asia/Manila. Baseline `3fd7ed1`; this report accompanies the
approved presentation, guidance and audio polish commit.

The source checks below pass. The game is ready for an approved Windows rebuild.
No Windows executable or ZIP was exported or replaced during this work. A new
package must still pass extracted-native launch and persistence checks before
replacing the existing downloadable archive in place.

## Changes reviewed

- Credits/licenses uses a dark outlined reader, larger section headings, one
  continuous licenses document and an edge-aligned scrollbar. Duplicate dropdowns
  and source-picker controls are removed. Offline notice wording, selectable text,
  direct source links, keyboard scrolling and contained focus remain available.
- Four cans remain the advertised food requirement. One whole chicken or two
  halves still work, with a separate ready line when chicken is selected. Existing
  consumption priority, supply rechecks, five-minute cost and Nestor quest remain.
- The five-page tutorial emphasizes the 6 PM deadline, travel/task costs, route
  planning and budget. Map/bag time continues; existing dialogue/shop/Pause rules
  and gameplay costs are unchanged.
- Dismissals have an explicit shared secondary style; exits that discard progress
  use a warning border. Difficulty Cancel is narrower and separated. Lotto's
  Reveal Result remains primary and changes to secondary Close after settlement.
- Ending music/storm use -12/-10 dB track gains and no duplicate gameplay weather.
  Both fade out over 1.5 seconds as results begin, remaining stopped during name
  entry, retries and skipping. New playback cancels an older pending stop fade.
  Saved bus settings and the authored looping recordings remain unchanged.

## Accepted checks

Godot `4.6.1.stable.official.14d19694e`, imported working checkout, isolated
APPDATA/LOCALAPPDATA and matching `BAGYONG_ISOLATED_SMOKE`. Native rendering used
the NVIDIA RTX 4050 laptop. Inputs were injected by the harness.

| Check | Result |
| --- | --- |
| Credits/menu | 393 headless and 401 Forward Plus checks, zero failures. Four views, all offline license wording, direct source-link focus, wheel/Page Up/Down/Home/End, fresh opens, resize without changing tabs, bounded reading focus, difficulty Cancel hierarchy and confirmed native quit. Layout matrix covers EN/TL, 100/140/175%, 1920x1080 and 1280x720 logical canvases. |
| Food | 166 headless and 166 Forward Plus checks, zero failures. Four-can guidance, conditional chicken line, all complete options, rejection of partial mixtures, cans priority, supply changes/cancellation, Nestor readiness and deadline snapshots. |
| Tutorial | 1,238 headless and 1,238 Forward Plus checks, zero failures. Actual main/Pause entry points, all five pages, translated time/budget/deadline copy, images, all scales/canvases and pause/focus/cursor restoration. |
| Audio | 161 headless and 161 Forward Plus checks, zero failures. Real current ending scene at maximum storm progress, suppression of existing gameplay weather, recording loop boundaries, complete closing statement, concurrent result fades, quiet name/save-retry/skip states, replacement/same-track fade cancellation and preserved bus gains. |
| Full scripted flow | 163 headless and 163 Forward Plus checks, zero failures. Intro/menu, waking, untimed exploration, Nanay, tutorial, travel/purchases/task, restart, forced storm, complete ending/results, nickname save, menu and a clean second run. Results and name entry explicitly assert stopped ending loops. |
| Related regressions | Cleanup 92; scratch lotto 44; Milestone 2 lifecycle 169; leaderboard persistence 75; dialogue 110; map 20; Ate Linda 17; pickup guidance 54; score 272; Dev Mode 47; branding 15; inventory bar 48. All zero failures. Native ending balance passed 19 checks; native cursor ownership exited 0. |
| Graphics | 49 Forward Plus and 49 forced Compatibility checks, zero failures. Six quality/VHS/scale/resolution cases per renderer, with native captures and short frame-time samples. This is a local smoke check, not a minimum hardware guarantee. |
| Source/assets | Editor import had no script/parser errors. Git LFS fsck passed. CSV has 616 unique keys, preserves all 615 previous IDs/order, updates five rows and adds the chicken acknowledgement. No new dependency, persistence format or export-preset change. |

A separate native output-meter probe sampled five seconds per case at the default
isolated bus settings. Home music had a -16.27 dB peak; ending music plus its storm
bed had a -21.74 dB peak. After the result fade, both players were stopped and the
decaying meter stayed below -92 dB. This supports headroom and fade checks; it is
not integrated loudness measurement or human listening acceptance.

Independent review found a credits heading-resize issue and two test-fixture
defects; these were corrected before the accepted runs. Native review also moved
reading focus to a bounded panel. Earlier failed attempts remain in the evidence
folder and are not acceptance results. Accepted logs have no script/parser errors
or failed assertions. Known ObjectDB/resource-at-exit diagnostics, an ending-camera
demotion warning and unsupported-effect warnings in Compatibility remain separate.

Evidence: `C:/Temp/bagyong-polish-20261108`, especially `accepted-reader-headless`,
`accepted-reader-native`, `targeted`, `corrected`, `ui-final-headless`,
`final-native`, `integration`, `full-flow-headless`, `acceptance-forward`,
`acceptance-compatibility` and `mix`. Use the final passing result for each suite;
the early menu/audio runs in `targeted` are superseded.

## Remaining gates

1. Obtain the user's separate approval before exporting the Windows EXE/ZIP.
2. Verify native icon/resource rewriting under the existing Windows policy. This
   laptop previously rejected a resource-rewritten executable with WinError 4551;
   the current icon-enabled preset has not been exported in this task. Do not
   change Windows security policy to bypass a launch failure.
3. Check the rebuilt package's resources/notices, extracted startup, release
   Dev Mode denial, nickname/settings persistence across processes and ZIP
   integrity/checksums. Replace the existing downloadable ZIP, without creating
   another dated archive.
4. Record physical-input playthrough and listening balance, then second-PC
   acceptance without Godot or administrator rights. The scripted forced-storm
   run does not prove natural full-day progression or other hardware support.

Unrelated preexisting documentation and icon-preview work is preserved separately
from the polish commit.

## Follow-up: recovered title and shop discovery markers

After baseline `586a2ef`, the owner confirmed restoring the recovered Bates Shower
menu version and including its font in Windows exports. The title/tagline use the
original 100/45 font settings and white/shadow treatment. One responsive column
preserves the title/menu/Replay Intro separation. The prior pixel-font substitute
was not committed. Credits and offline notices now identify Imagex and preserve
the font's embedded "Free for personal use only" notice. See the
[font record](../../game/assets/fonts/bates_shower/README.md); no separate broader
distribution permission document is present in the repository.

Only Ate Linda, grocery, hardware and pharmacy receive the existing gold task-cue
visual. First valid dialogue records discovery for that run; leaving/revisiting
does not restore it, while a new run does. The small TaskCue3D subclass reuses
existing dialogue signals, without changing shop bases, costs or persistence.
Its billboard symbol stays readable beneath shop roofs; glow/particles remain
normal 3D content.

| Follow-up check | Final result |
| --- | --- |
| Restored title | 77 headless and 77 Forward Plus, zero failures. Font/export settings, 18 layout combinations, all actions and Replay Intro bounds/non-overlap. |
| Shop lifecycle | 57 headless and 57 Forward Plus, zero failures. Four identities, first valid dialogue, rejection guards, head clearance, independent flags, revisit/reset and normal shop opening. |
| Production shop cameras | 24 native checks, zero failures; 16 final captures across the four actual locations and return visits. Ate Linda's initially obscured symbol was corrected before final review. |
| Related checks | Menu modal 396 headless/404 Forward Plus; lifecycle 169; recording camera 1,025; pickup 54; Ate Linda trade 17; full scripted flow 163. All final runs passed. |

The initial concurrent lifecycle run missed a transient fade condition; the same
unmodified suite passed its rerun. No assertion was weakened. Independent source
review found no actionable remaining issue. Evidence is under
`C:/Temp/bagyong-title-shops-20261108`. Runtime/geometry tests use scripted input and
scene staging, not a human playthrough. Native package/font inclusion and broader
font-distribution permission remain unverified. Windows rebuild approval is still
required, and the existing ZIP has not been replaced or duplicated.

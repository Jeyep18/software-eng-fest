# Tutorial screenshots

The five-page tutorial uses `overview`, `task`, `map`, `combine` and `finish`
captures in both `english` and `tagalog`. These are native Godot 4.6.1 gameplay
renders from November 7, 2026, with the current dialogue and inventory UI.
The overview, task and finish images were refreshed after removing the hotbar
instruction badge. The two older `*_example.png` images are retained but no longer
shown.

Captures use the normal house scene, player camera and lighting at 100% UI scale.
VHS is disabled during capture because the runtime overlay also covers the
tutorial. The combination image captures the actual backpack panel region;
other images capture the viewport. Pixels are not painted or generated.

The capture fixture stages unlocked tasks, known supplies and a paused clock
with isolated application data. It selects the broken radio and batteries to
show the actual combination preview. The finish image follows real food-task
completion, including four-can consumption, objective feedback and the five-minute
time charge. These images illustrate controls; they are not a human playthrough.

When refreshing them, capture both languages after changing the language before
loading the scene, so notices and controls match. Keep each filename and let
Godot regenerate imports. Check all pages using
`res://game/tests/tutorial_paging_regression.tscn`, including 175% UI scale.

# Suerte Scratch art kit

These are the supplied visual assets used by the pharmacy Lottohan in `game/scenes/locations/pharmacy.tscn`. Purchase, odds and prize rules live in `game/ui/lotto/ScratchLottoRules.gd`; the screen and scratching behavior live beside it. The supplied gameplay screenshot remains the layout reference.

## Files

| File | Size | Use |
| --- | --- | --- |
| `scratch_ticket_face.png` | 1448 × 1086 | Transparent-outside, 4:3 ticket backing with six empty wells. |
| `scratch_fruit_atlas.png` | 1043 × 1508 | Eight fruit symbols on transparent alpha. |
| `scratch_foil_cover.png` | 1298 × 1212 | One opaque scratch coating with transparent corners; reuse it over each well. |

Keep labels, prices, cash, card count, and win/loss text as Godot controls. Do not bake them into the PNGs. The ticket's empty header and footer bands are for live title and result text.

## Fruit atlas regions

The atlas has two columns and four rows. Use these exact pixel regions with `AtlasTexture.region` (`x, y, width, height`). The row heights vary because the clear gaps between generated icons are uneven; these crop lines lie within transparent gaps.

| Symbol ID | Region |
| --- | --- |
| `apple` | `0, 0, 522, 403` |
| `orange` | `522, 0, 521, 403` |
| `watermelon` | `0, 403, 522, 362` |
| `grapes` | `522, 403, 521, 362` |
| `cherries` | `0, 765, 522, 351` |
| `banana` | `522, 765, 521, 351` |
| `raspberry` | `0, 1116, 522, 392` |
| `peach` | `522, 1116, 521, 392` |

Use stable symbol IDs in game logic and map them to these regions. Keep the whole symbol visible with aspect-preserving scaling; do not stretch a fruit to fill a well.

## Assembly in Godot

1. Keep the existing dark modal treatment and use `GameUIStyle` / `GameTheme` for the panel, buttons, fonts, focus state, and live text. The ticket art supplies the reward emphasis without the glossy neon look of the reference UI.
2. Center a `TextureRect` using `scratch_ticket_face.png` and preserve its 4:3 aspect ratio. A displayed size around 600 × 450 px is a useful starting point at 1920 × 1080; scale responsively with the viewport and UI scale.
3. Overlay six separate slot `Control`s inside the ticket wells. Their approximate centers, as fractions of the full ticket image, are `x = 0.274, 0.500, 0.726` and `y = 0.374, 0.634`. Use each combination once, left to right and top to bottom. Start with a content area around `0.17 × ticket width` by `0.19 × ticket height` per slot, then visually align within the gold borders. Do not use one full-card input target for six independent scratch areas.
4. Inside each slot, stack the fruit `TextureRect` below a separate copy of `scratch_foil_cover.png`. Fit the foil just inside the gold well border. Scratch interaction should erase/reveal that slot's foil alpha while the fruit stays fixed underneath. The “scratch all” action reveals all six through the same game state path.
5. Place the title in the ticket's empty top band and the dynamic result in its bottom band. Show cash and card count outside the ticket, above it. Put purchase, scratch-all, and close buttons below the ticket using native `Button`s. Read price labels and result messages from feature data/localization rather than from this art.

```text
cash / card count
┌────────── ticket face ──────────┐
│        live title text          │
│   [1]     [2]     [3]          │
│   [4]     [5]     [6]          │
│       live result text          │
└─────────────────────────────────┘
buy buttons · scratch all · close
```

Preview the assembled UI at the game's target resolutions with its VHS/CRT effect enabled. Check that the symbols remain distinguishable at slot size, all six foil covers line up, text remains legible, and mouse/keyboard focus still works. These assets do not establish the feature's rules or balance.

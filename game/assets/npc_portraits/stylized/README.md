# Approved dialogue portrait library

68 PNG masters cover 17 active NPCs and five Player expressions. The Player wears glasses in every state. Portrait identities follow current NPC models and the approved player art style.

Each `DialogueLine.expression` selects a texture for its authored line; the existing `DialogueUI.show_line()` switches it when the line advances. The shared monologue scene uses `player/thinking.png`. Neutral and additional expressions remain available for future authored lines; expressions are not inferred automatically from text.

The approved roster, artwork provenance, exact line assignments and integration record are in `design_previews/dialogue_portraits_v2/metadata/`. Existing source portraits and unreferenced legacy dialogue resources are preserved. The two configured Linda fallback lines also use this library.

When adding dialogue, choose an existing expression matching the line's intent and assign it in the Inspector. Keep dialogue text/localization keys unchanged when changing only art. Run `game/tests/dialogue_portrait_regression.tscn` in an imported disposable project with isolated userdata; its manifest lists the approved expression roster and NPC scenes.

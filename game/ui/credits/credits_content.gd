extends RefCounted

# Concise contributor credits and detailed notices share the menu's section format.
const CREDIT_SECTIONS := [
	["ui.credits.development", "Game design and programming", """[b]3 Netherite Ingots[/b]
Original modeling, environments, house maps and art direction
[b]Jeyep18[/b]

Map and portrait art
[b]Jeyep18 and 3 Netherite Ingots[/b]
Created with AI assistance under team direction."""],
	["ui.credits.visual", "Models and environments", """Characters · [b]Elbolilloduro, JashiPSX and Comp-3 Interactive[/b]
Animals · [b]MCSTEEG and Prildarill[/b]
Props and buildings · [b]Elbolilloduro, Kkryy, chikievna, styloo, psychopom[/b]
Tools and supplies · [b]Lyndschoko, MasterYogurt, Jvdm78, Сверкающая Звезда[/b]
Cars and plants · [b]GGBotNet and valsekamerplant[/b]
Nature · [b]Elegant Crow, halfhuman and Domi[/b]
Textures and skies · [b]Rob Tuytel, Charlotte Baglioni, Dimitrios Savva, Jarod Guest, Sergej Majboroda and Greg Zaal[/b]"""],
	["ui.credits.music", "Music", """Extreme Sad Cinema · [b]Samuel F. Johanns[/b]
Phase Shift · [b]Scott Buckley[/b]
Lottery Casino Pause Intro Background Music · [b]MFCC[/b]"""],
	["ui.credits.sfx", "Sound effects", """Ambience · [b]jacksonacademyashmore, klankbeeld, forfie, giddster, SduggySounds, Catacombronson, Marlene_Coetzer and JoelMcDaniel[/b]
Animals · [b]dadshb1489, cabled_mess, DRAGON-STUDIO, solarmusic and soundofsong[/b]
Actions · [b]sbaneat, husky70, Henaway, pagancow, lulyc, j1987 and mlestn1[/b]
Interface · [b]LittleRobotSoundFactory, Fission9, freesound_CrunchpixStudio, Universfield, Nomagician, Musicholder, ksjsbwuil, floraphonic and Cartoon Music[/b]
Weather · [b]JCI-21, DRAGON-STUDIO, SoundReality, u_7hpxkdroz2 and u_vrs223ln83[/b]
Additional archive effects · [b]Freesound Community via Pixabay[/b]"""],
	["ui.credits.broadcast", "Broadcast audio", """Kasaysayan sa mga Liham ni Tiya Dely · [b]DZRH, from BokerTV's upload[/b]
Sounds from a TV · [b]IESP[/b]
Train Announcement · [b]Freesound Community via Pixabay[/b]
Bundled shortwave recording · [b]uair01[/b]"""],
	["ui.credits.fonts", "Typefaces", """Inter · [b]Rasmus Andersson and the Inter Project Authors[/b]
EAS VHS · [b]Lastnames, listed as Rurr[/b]"""],
	["ui.credits.technology", "Technology and artwork", """Godot Engine · [b]Godot contributors[/b]
Player animations · [b]Adobe Mixamo[/b]
VHS and CRT monitor effect · [b]pend00[/b]
Godot application icon · [b]Andrea Calabró[/b]
Map and portrait art · [b]Jeyep18 and 3 Netherite Ingots, with AI assistance[/b]"""],
]

# Detailed attributions retain source and license links for each identified work.
const SECTIONS := [
	["ui.credits.development", "Game design and programming", "3 Netherite Ingots\nOriginal art direction and models · Jeyep18\n[url=https://godotengine.org/license/]Godot Engine[/url] · MIT License"],
	["ui.credits.visual", "3D models and textures", """Original models, environments and house maps · Jeyep18 and 3 Netherite Ingots
Upstream character assets · [url=https://elbolilloduro.itch.io/characters-psx]Characters PSX[/url] by Elbolilloduro
Player base · [url=https://jashi-psx.itch.io/simple-character-psx-asset]Simple Character PSX Asset[/url] by JashiPSX
Player animations · [url=https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html]Adobe Mixamo[/url]
Human base mesh · [url=https://comp3interactive.itch.io/low-poly-human-mesh]Low Poly Human Mesh[/url] by Comp-3 Interactive
Dog · [url=https://mcsteeg.itch.io/psx-dog]PSX Dog[/url] by MCSTEEG, adapted for the game
Cat · [url=https://prildarill.itch.io/meow]Low-poly cat[/url] by Prildarill, adapted for the game
Cars · [url=https://ggbot.itch.io/psx-style-cars]PSX Style Cars[/url] by GGBotNet
Plants · [url=https://valsekamerplant.itch.io/psx-style-house-plants-and-pots]valsekamerplant[/url]
Trees · [url=https://elegantcrow.itch.io/retro-psx-nature-pack]Retro PSX Nature Pack[/url] by Elegant Crow (CC0), [url=https://halfhuman.itch.io/ps1psx-game-asset-pack]halfhuman[/url], and [url=https://domi236.itch.io/ps1-style-tree-and-grass-pack]PS1/PSX Tree and Grass Pack[/url] by Domi · [url=https://creativecommons.org/licenses/by/4.0/]CC BY 4.0[/url]
Domi pack assets were imported into Godot and integrated into team scenes.
Interiors · [url=https://elbolilloduro.itch.io/objects-interiorvillage-alpha]Objects Interior (Village) Alpha[/url] by Elbolilloduro, [url=https://kkryy.itch.io/retro-interior-pack]Retro Model Pack Interior[/url] by Kkryy, and [url=https://chikievna.itch.io/retro-furniture-set-with-dithering]Retro furniture set with dithering[/url] by chikievna · CC0
Original scene composition and models · Jeyep18 and 3 Netherite Ingots
Buildings · [url=https://elbolilloduro.itch.io/buildings]Buildings[/url] by Elbolilloduro · CC0, with original locations by Jeyep18
Tools · [url=https://sketchfab.com/3d-models/low-poly-tool-pack-66fc15e383a9453984db4ededd41ed3c]Low Poly Tool Pack[/url] by Lyndschoko · [url=https://creativecommons.org/licenses/by/4.0/]CC BY 4.0[/url]
Lyndschoko pack assets were imported into Godot and integrated into team scenes.
Bed source retained in the project · [url=https://psychopom.itch.io/low-poly-bed]Low-Poly Bed[/url] by psychopom (formerly floating world) · custom terms
Door textures · [url=https://styloo.itch.io/classroom-asset-pack]School Classrooms Asset Pack[/url] by styloo
[url=https://sketchfab.com/3d-models/simple-aa-battery-5dcd884e27b642c8a7932a227d7c1b7a]Simple AA Battery[/url] by MasterYogurt · [url=https://creativecommons.org/licenses/by/4.0/]CC BY 4.0[/url]
[url=https://sketchfab.com/3d-models/nail-58f0c51993c1461da0a76d735d118281]Nail[/url] by Jvdm78 · [url=https://creativecommons.org/licenses/by/4.0/]CC BY 4.0[/url]
[url=https://sketchfab.com/3d-models/treska-865b2169516042f3a2965ca7b672fe74]Treska[/url] by Сверкающая Звезда · [url=https://creativecommons.org/licenses/by/4.0/]CC BY 4.0[/url]
[url=https://sketchfab.com/3d-models/psx-style-fridge-1b5727b1952043339b4501a72df1bd6c]Psx Style Fridge[/url] by pixapexel (bundled model) · [url=https://creativecommons.org/licenses/by/4.0/]CC BY 4.0[/url]
[url=https://polyhaven.com/a/asphalt_02]Asphalt 02[/url] by Rob Tuytel and [url=https://polyhaven.com/a/gravel_concrete_03]Gravel Concrete 03[/url] by Charlotte Baglioni · Poly Haven · CC0
[url=https://polyhaven.com/a/overcast_soil_puresky]Overcast Soil (Pure Sky)[/url] by Jarod Guest and Sergej Majboroda · Poly Haven · CC0
[url=https://polyhaven.com/a/citrus_orchard_puresky]Citrus Orchard (Pure Sky)[/url] by Dimitrios Savva and Jarod Guest · Poly Haven · CC0
[url=https://polyhaven.com/a/belfast_sunset_puresky]Belfast Sunset (Pure Sky)[/url] by Dimitrios Savva, Greg Zaal and Jarod Guest · Poly Haven · CC0
[url=https://godotengine.org/press/]Godot default application icon[/url] by Andrea Calabró · [url=https://creativecommons.org/licenses/by/4.0/]CC BY 4.0[/url]"""],
	["ui.credits.music", "Music", """Extreme Sad Cinema · Samuel F. Johanns (Pixabay)
[url=https://www.scottbuckley.com.au/library/phase-shift/]Phase Shift[/url] by Scott Buckley · [url=https://creativecommons.org/licenses/by/4.0/]CC BY 4.0[/url] · [url=https://www.scottbuckley.com.au/]www.scottbuckley.com.au[/url]
[url=https://pixabay.com/music/funk-lottery-casino-pause-intro-background-music-120443/]Lottery Casino Pause Intro Background Music[/url] · MFCC (Pixabay)"""],
	["ui.credits.sfx", "Sound effects", """[url=https://freesound.org/people/jacksonacademyashmore/sounds/434523/]Scary Ambience[/url] · jacksonacademyashmore (Freesound via Pixabay) · CC0
[url=https://freesound.org/people/klankbeeld/sounds/217464/]MarketCalm 140205_0059.wav[/url] and [url=https://freesound.org/people/klankbeeld/sounds/523722/]Room-tone wind rain LONG 200216_0114.ogg[/url] by klankbeeld (Freesound) · [url=https://creativecommons.org/licenses/by/4.0/]CC BY 4.0[/url]
[url=https://freesound.org/people/forfie/sounds/319336/]City Sounds[/url] · forfie (Freesound)
[url=https://freesound.org/people/giddster/sounds/437343/]Fan (heating)[/url] · giddster (Freesound)
[url=https://freesound.org/people/SduggySounds/sounds/721615/]Foodcourt ambience[/url] · SduggySounds (Freesound)
[url=https://freesound.org/people/Catacombronson/sounds/626727/]Fridge tone[/url] · Catacombronson (Freesound)
[url=https://freesound.org/people/Marlene_Coetzer/sounds/594553/]Quiet house ambience[/url] by Marlene_Coetzer (Freesound) · [url=https://creativecommons.org/licenses/by/3.0/]CC BY 3.0[/url]
[url=https://freesound.org/people/JoelMcDaniel/sounds/830440/]Fluorescent light buzzing[/url] · JoelMcDaniel (Freesound)
[url=https://freesound.org/people/dadshb1489/sounds/390563/]Morning-Birds[/url] · dadshb1489 (Freesound via Pixabay) · CC0
[url=https://pixabay.com/sound-effects/nature-rooster-crowing-27112016-processed-101724/]Rooster Crowing[/url] · cabled_mess (Freesound via Pixabay)
[url=https://pixabay.com/sound-effects/nature-free-dog-bark-419014/]Free Dog Bark[/url] and [url=https://pixabay.com/sound-effects/nature-meowing-cat-401728/]Meowing Cat[/url] · DRAGON-STUDIO (Pixabay)
[url=https://pixabay.com/sound-effects/nature-big-dog-bark-distant-113701/]Big Dog Bark Distant[/url] · solarmusic (Pixabay)
[url=https://freesound.org/people/soundofsong/sounds/650575/]cat purring loop.wav[/url] · soundofsong (Freesound)
[url=https://pixabay.com/sound-effects/people-fumar-6420/]Fumar[/url] · sbaneat (Freesound via Pixabay)
[url=https://pixabay.com/sound-effects/people-having-a-smoke-89760/]Having A Smoke[/url] · husky70 (Freesound via Pixabay)
[url=https://freesound.org/people/Henaway/sounds/127979/]Scratching Paper.mp3[/url] · Henaway (Freesound)
[url=https://freesound.org/people/pagancow/sounds/15419/]dorm door opening.wav[/url] · pagancow (Freesound)
[url=https://freesound.org/people/lulyc/sounds/346118/]Bllrr-text-loop[/url] · lulyc (Freesound via Pixabay) · CC0
[url=https://pixabay.com/sound-effects/film-special-effects-put-item-83043/]put_item[/url] · j1987 (Freesound via Pixabay)
[url=https://freesound.org/people/mlestn1/sounds/83242/]HammeringRoof[/url] · mlestn1 (Freesound via Pixabay)
[url=https://freesound.org/people/LittleRobotSoundFactory/sounds/270393/]Inventory_Open_00.wav[/url] by LittleRobotSoundFactory (Freesound) · [url=https://creativecommons.org/licenses/by/4.0/]CC BY 4.0[/url]
[url=https://freesound.org/people/Fission9/sounds/568991/]Inventory close[/url] · Fission9 (Freesound)
[url=https://pixabay.com/sound-effects/open-map-384948/]Open Map[/url] · freesound_CrunchpixStudio (Pixabay)
[url=https://pixabay.com/sound-effects/water-191999/]Pouring Water[/url], [url=https://pixabay.com/sound-effects/interface-124464/]Interface[/url], [url=https://pixabay.com/sound-effects/button-124476/]Interface Click[/url], [url=https://pixabay.com/sound-effects/error-010-206498/]Error Notification 010[/url] and Cinematic Impact Boom 05 · Universfield (Pixabay)
[url=https://pixabay.com/sound-effects/ui-button-sound-cancel-back-exit-continue-467877/]UI Button Sound[/url] · Nomagician (Pixabay)
[url=https://pixabay.com/sound-effects/hover-button-287656/]Hover Button[/url] · Musicholder (Pixabay)
Cash Register 1 · ksjsbwuil (Pixabay)
[url=https://pixabay.com/sound-effects/coin-and-money-bag-3-185264/]Coin and Money Bag 3[/url] · floraphonic (Pixabay)
Cash Register Scanner Single Beep · Cartoon Music (Pixabay)
[url=https://pixabay.com/sound-effects/wind-blowing-sfx-12809/]Wind blowing sfx[/url] · JCI-21 (Pixabay)
Gust of Wind · DRAGON-STUDIO (Pixabay)
Rain Thunder SFX · SoundReality (Pixabay)
Storm · u_7hpxkdroz2 (Pixabay)
Loud Thunder · u_vrs223ln83 (Pixabay)
[url=https://pixabay.com/sound-effects/027958-distant-thunderwav-79709/]027958_Distant Thunder.wav[/url] · Freesound Community (Pixabay)"""],
	["ui.credits.broadcast", "Broadcast audio", """Kasaysayan sa mga Liham ni Tiya Dely · DZRH radio drama, sourced from [url=https://www.youtube.com/watch?v=IrpTpQobwUc]BokerTV's upload[/url]
Redistribution permission for this recording remains undocumented.
[url=https://freesound.org/people/IESP/sounds/340020/]Sounds from a TV[/url] by IESP (Freesound) · [url=https://creativecommons.org/licenses/by/3.0/]CC BY 3.0[/url]
057519 Train Announcement · Freesound Community (Pixabay)
[url=https://freesound.org/people/uair01/sounds/86613/]shortwave criminal history.wav[/url] by uair01 (bundled Freesound recording) · [url=https://creativecommons.org/licenses/by/3.0/]CC BY 3.0[/url]"""],
	["ui.credits.fonts", "Typefaces", """[url=https://rsms.me/inter/]Inter[/url] · The Inter Project Authors and Rasmus Andersson · [url=https://github.com/rsms/inter/blob/v3.19/LICENSE.txt]SIL Open Font License 1.1[/url]
[url=https://fontstruct.com/fontstructions/show/2878521/eas-vhs]EAS VHS[/url] · Lastnames (listed as [url=https://www.dafont.com/easvhs.font]Rurr[/url]) · [url=https://creativecommons.org/licenses/by/3.0/]CC BY 3.0[/url]"""],
	["ui.credits.technology", "Shader and artwork notes", """[url=https://godotshaders.com/shader/vhs-and-crt-monitor-effect/]VHS and CRT monitor effect[/url] by pend00 · CC0, adapted for Godot 4 and the game
Map and NPC portrait artwork · Jeyep18 and 3 Netherite Ingots, with AI-assisted image generation under team direction
Animal models, scene assemblies and selected upstream assets were adapted for the game. Full notices and project terms are available offline in this menu."""],
]

# The menu opens the selected HTTPS source only after the player activates it.
const SOURCE_LINKS := [
	["Godot Engine", "https://godotengine.org/license/"],
	["Characters PSX", "https://elbolilloduro.itch.io/characters-psx"],
	["Simple Character PSX Asset", "https://jashi-psx.itch.io/simple-character-psx-asset"],
	["Adobe Mixamo", "https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html"],
	["Low Poly Human Mesh", "https://comp3interactive.itch.io/low-poly-human-mesh"],
	["PSX Dog", "https://mcsteeg.itch.io/psx-dog"],
	["Low-poly cat", "https://prildarill.itch.io/meow"],
	["PSX Style Cars", "https://ggbot.itch.io/psx-style-cars"],
	["valsekamerplant", "https://valsekamerplant.itch.io/psx-style-house-plants-and-pots"],
	["Retro PSX Nature Pack", "https://elegantcrow.itch.io/retro-psx-nature-pack"],
	["halfhuman", "https://halfhuman.itch.io/ps1psx-game-asset-pack"],
	["PS1/PSX Tree and Grass Pack", "https://domi236.itch.io/ps1-style-tree-and-grass-pack"],
	["CC BY 4.0", "https://creativecommons.org/licenses/by/4.0/"],
	["Objects Interior (Village) Alpha", "https://elbolilloduro.itch.io/objects-interiorvillage-alpha"],
	["Retro Model Pack Interior", "https://kkryy.itch.io/retro-interior-pack"],
	["Retro furniture set with dithering", "https://chikievna.itch.io/retro-furniture-set-with-dithering"],
	["Buildings", "https://elbolilloduro.itch.io/buildings"],
	["Low Poly Tool Pack", "https://sketchfab.com/3d-models/low-poly-tool-pack-66fc15e383a9453984db4ededd41ed3c"],
	["Low-Poly Bed", "https://psychopom.itch.io/low-poly-bed"],
	["School Classrooms Asset Pack", "https://styloo.itch.io/classroom-asset-pack"],
	["Simple AA Battery", "https://sketchfab.com/3d-models/simple-aa-battery-5dcd884e27b642c8a7932a227d7c1b7a"],
	["Nail", "https://sketchfab.com/3d-models/nail-58f0c51993c1461da0a76d735d118281"],
	["Treska", "https://sketchfab.com/3d-models/treska-865b2169516042f3a2965ca7b672fe74"],
	["Psx Style Fridge", "https://sketchfab.com/3d-models/psx-style-fridge-1b5727b1952043339b4501a72df1bd6c"],
	["Asphalt 02", "https://polyhaven.com/a/asphalt_02"],
	["Gravel Concrete 03", "https://polyhaven.com/a/gravel_concrete_03"],
	["Overcast Soil (Pure Sky)", "https://polyhaven.com/a/overcast_soil_puresky"],
	["Citrus Orchard (Pure Sky)", "https://polyhaven.com/a/citrus_orchard_puresky"],
	["Belfast Sunset (Pure Sky)", "https://polyhaven.com/a/belfast_sunset_puresky"],
	["Godot default application icon", "https://godotengine.org/press/"],
	["Phase Shift", "https://www.scottbuckley.com.au/library/phase-shift/"],
	["www.scottbuckley.com.au", "https://www.scottbuckley.com.au/"],
	["Lottery Casino Pause Intro Background Music", "https://pixabay.com/music/funk-lottery-casino-pause-intro-background-music-120443/"],
	["Scary Ambience", "https://freesound.org/people/jacksonacademyashmore/sounds/434523/"],
	["MarketCalm 140205_0059.wav", "https://freesound.org/people/klankbeeld/sounds/217464/"],
	["Room-tone wind rain LONG 200216_0114.ogg", "https://freesound.org/people/klankbeeld/sounds/523722/"],
	["City Sounds", "https://freesound.org/people/forfie/sounds/319336/"],
	["Fan (heating)", "https://freesound.org/people/giddster/sounds/437343/"],
	["Foodcourt ambience", "https://freesound.org/people/SduggySounds/sounds/721615/"],
	["Fridge tone", "https://freesound.org/people/Catacombronson/sounds/626727/"],
	["Quiet house ambience", "https://freesound.org/people/Marlene_Coetzer/sounds/594553/"],
	["CC BY 3.0", "https://creativecommons.org/licenses/by/3.0/"],
	["Fluorescent light buzzing", "https://freesound.org/people/JoelMcDaniel/sounds/830440/"],
	["Morning-Birds", "https://freesound.org/people/dadshb1489/sounds/390563/"],
	["Rooster Crowing", "https://pixabay.com/sound-effects/nature-rooster-crowing-27112016-processed-101724/"],
	["Free Dog Bark", "https://pixabay.com/sound-effects/nature-free-dog-bark-419014/"],
	["Meowing Cat", "https://pixabay.com/sound-effects/nature-meowing-cat-401728/"],
	["Big Dog Bark Distant", "https://pixabay.com/sound-effects/nature-big-dog-bark-distant-113701/"],
	["cat purring loop.wav", "https://freesound.org/people/soundofsong/sounds/650575/"],
	["Fumar", "https://pixabay.com/sound-effects/people-fumar-6420/"],
	["Having A Smoke", "https://pixabay.com/sound-effects/people-having-a-smoke-89760/"],
	["Scratching Paper.mp3", "https://freesound.org/people/Henaway/sounds/127979/"],
	["dorm door opening.wav", "https://freesound.org/people/pagancow/sounds/15419/"],
	["Bllrr-text-loop", "https://freesound.org/people/lulyc/sounds/346118/"],
	["put_item", "https://pixabay.com/sound-effects/film-special-effects-put-item-83043/"],
	["HammeringRoof", "https://freesound.org/people/mlestn1/sounds/83242/"],
	["Inventory_Open_00.wav", "https://freesound.org/people/LittleRobotSoundFactory/sounds/270393/"],
	["Inventory close", "https://freesound.org/people/Fission9/sounds/568991/"],
	["Open Map", "https://pixabay.com/sound-effects/open-map-384948/"],
	["Pouring Water", "https://pixabay.com/sound-effects/water-191999/"],
	["Interface", "https://pixabay.com/sound-effects/interface-124464/"],
	["Interface Click", "https://pixabay.com/sound-effects/button-124476/"],
	["Error Notification 010", "https://pixabay.com/sound-effects/error-010-206498/"],
	["UI Button Sound", "https://pixabay.com/sound-effects/ui-button-sound-cancel-back-exit-continue-467877/"],
	["Hover Button", "https://pixabay.com/sound-effects/hover-button-287656/"],
	["Coin and Money Bag 3", "https://pixabay.com/sound-effects/coin-and-money-bag-3-185264/"],
	["Wind blowing sfx", "https://pixabay.com/sound-effects/wind-blowing-sfx-12809/"],
	["027958_Distant Thunder.wav", "https://pixabay.com/sound-effects/027958-distant-thunderwav-79709/"],
	["BokerTV's upload", "https://www.youtube.com/watch?v=IrpTpQobwUc"],
	["Sounds from a TV", "https://freesound.org/people/IESP/sounds/340020/"],
	["shortwave criminal history.wav", "https://freesound.org/people/uair01/sounds/86613/"],
	["Inter", "https://rsms.me/inter/"],
	["SIL Open Font License 1.1", "https://github.com/rsms/inter/blob/v3.19/LICENSE.txt"],
	["EAS VHS", "https://fontstruct.com/fontstructions/show/2878521/eas-vhs"],
	["Rurr", "https://www.dafont.com/easvhs.font"],
	["VHS and CRT monitor effect", "https://godotshaders.com/shader/vhs-and-crt-monitor-effect/"],
	["Public release notice report", "https://github.com/Jeyep18/software-eng-fest/blob/dev/docs/audits/2026-11-07-public-release-notices.md"],
	["Pixabay Content License", "https://pixabay.com/service/license-summary/"],
]

const LICENSE_FILES := [
	["Creative Commons Attribution 3.0", "res://game/legal/CC_BY_3.0.txt"],
	["Creative Commons Attribution 4.0", "res://game/legal/CC_BY_4.0.txt"],
	["Creative Commons CC0 1.0", "res://game/legal/CC0_1.0.txt"],
	["Inter SIL Open Font License 1.1", "res://game/legal/INTER_OFL.txt"],
]

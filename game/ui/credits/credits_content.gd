extends RefCounted

# Keep source and license links with the individual work when known.
const SECTIONS := [
	["ui.credits.development", "Game design and programming", "3 Netherite Ingots\n[url=https://godotengine.org/license/]Godot Engine[/url] · MIT License"],
	["ui.credits.visual", "3D models and textures", """Characters · [url=https://elbolilloduro.itch.io/characters-psx]Elbolilloduro[/url], JashiPSX and Jeyep18
Player base · [url=https://jashi-psx.itch.io/simple-character-psx-asset]Simple Character PSX Asset[/url] by JashiPSX
Player animations · [url=https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html]Adobe Mixamo[/url]
Human base mesh · [url=https://comp3interactive.itch.io/low-poly-human-mesh]Low Poly Human Mesh[/url] by Comp-3 Interactive
Dog · [url=https://mcsteeg.itch.io/psx-dog]PSX Dog[/url] by MCSTEEG, adapted for the game
Cat · [url=https://prildarill.itch.io/meow]Low-poly cat[/url] by Prildarill, adapted for the game
Cars · [url=https://ggbot.itch.io/psx-style-cars]PSX Style Cars[/url] by GGBotNet
Plants · [url=https://valsekamerplant.itch.io/psx-style-house-plants-and-pots]valsekamerplant[/url]
Trees · [url=https://elegantcrow.itch.io/psx-retro-style-tree-pack]Elegant Crow[/url], [url=https://halfhuman.itch.io/ps1psx-game-asset-pack]halfhuman[/url], Domi
Interiors · Elbolilloduro, Kkryy, Chikievna, Jeyep18
Buildings · Elbolilloduro and Jeyep18
Tools · Lyndschoko
Door textures · [url=https://styloo.itch.io/classroom-asset-pack]School Classrooms Asset Pack[/url] by styloo
[url=https://sketchfab.com/3d-models/simple-aa-battery-5dcd884e27b642c8a7932a227d7c1b7a]Simple AA Battery[/url] by MasterYogurt · [url=https://creativecommons.org/licenses/by/4.0/]CC BY 4.0[/url]
[url=https://sketchfab.com/3d-models/nail-58f0c51993c1461da0a76d735d118281]Nail[/url] by Jvdm78 · [url=https://creativecommons.org/licenses/by/4.0/]CC BY 4.0[/url]
[url=https://sketchfab.com/3d-models/treska-865b2169516042f3a2965ca7b672fe74]Treska[/url] by Сверкающая Звезда · [url=https://creativecommons.org/licenses/by/4.0/]CC BY 4.0[/url]
[url=https://sketchfab.com/3d-models/psx-style-fridge-1b5727b1952043339b4501a72df1bd6c]Psx Style Fridge[/url] by pixapexel (bundled model) · [url=https://creativecommons.org/licenses/by/4.0/]CC BY 4.0[/url]
[url=https://polyhaven.com/a/asphalt_02]Asphalt 02[/url] by Rob Tuytel and [url=https://polyhaven.com/a/gravel_concrete_03]Gravel Concrete 03[/url] by Charlotte Baglioni · Poly Haven
[url=https://polyhaven.com/a/overcast_soil_puresky]Overcast Soil (Pure Sky)[/url] by Jarod Guest and Sergej Majboroda · Poly Haven
[url=https://polyhaven.com/a/citrus_orchard_puresky]Citrus Orchard (Pure Sky)[/url] by Dimitrios Savva and Jarod Guest · Poly Haven
[url=https://godotengine.org/press/]Godot default application icon[/url] by Andrea Calabró · [url=https://creativecommons.org/licenses/by/4.0/]CC BY 4.0[/url]"""],
	["ui.credits.music", "Music", """Extreme Sad Cinema · Samuel F. Johanns (Pixabay)
[url=https://www.scottbuckley.com.au/library/phase-shift/]Phase Shift[/url] by Scott Buckley · [url=https://creativecommons.org/licenses/by/4.0/]CC BY 4.0[/url] · [url=https://www.scottbuckley.com.au/]www.scottbuckley.com.au[/url]
[url=https://pixabay.com/music/funk-lottery-casino-pause-intro-background-music-120443/]Lottery Casino Pause Intro Background Music[/url] · MFCC (Pixabay)"""],
	["ui.credits.sfx", "Sound effects", """[url=https://pixabay.com/sound-effects/film-special-effects-scary-ambience-59002/]Scary Ambience[/url] · jacksonacademyashmore (Freesound via Pixabay)
[url=https://freesound.org/people/klankbeeld/sounds/217464/]MarketCalm 140205_0059.wav[/url] and [url=https://freesound.org/people/klankbeeld/sounds/523722/]Room-tone wind rain LONG 200216_0114.ogg[/url] by klankbeeld (Freesound) · [url=https://creativecommons.org/licenses/by/4.0/]CC BY 4.0[/url]
[url=https://freesound.org/people/forfie/sounds/319336/]City Sounds[/url] · forfie (Freesound)
[url=https://freesound.org/people/giddster/sounds/437343/]Fan (heating)[/url] · giddster (Freesound)
[url=https://freesound.org/people/SduggySounds/sounds/721615/]Foodcourt ambience[/url] · SduggySounds (Freesound)
[url=https://freesound.org/people/Catacombronson/sounds/626727/]Fridge tone[/url] · Catacombronson (Freesound)
[url=https://freesound.org/people/Marlene_Coetzer/sounds/594553/]Quiet house ambience[/url] by Marlene_Coetzer (Freesound) · [url=https://creativecommons.org/licenses/by/3.0/]CC BY 3.0[/url]
[url=https://freesound.org/people/JoelMcDaniel/sounds/830440/]Fluorescent light buzzing[/url] · JoelMcDaniel (Freesound)
[url=https://freesound.org/people/ErickBloem_200250/sounds/542912/]Outside ambience with birds[/url] by ErickBloem_200250 (bundled Freesound recording) · [url=https://creativecommons.org/licenses/by-nc/3.0/]CC BY-NC 3.0[/url]
[url=https://pixabay.com/sound-effects/nature-morning-birds-30911/]Morning-Birds[/url] · dadshb1489 (Freesound via Pixabay)
[url=https://pixabay.com/sound-effects/nature-rooster-crowing-27112016-processed-101724/]Rooster Crowing[/url] · cabled_mess (Freesound via Pixabay)
[url=https://pixabay.com/sound-effects/nature-free-dog-bark-419014/]Free Dog Bark[/url] and [url=https://pixabay.com/sound-effects/nature-meowing-cat-401728/]Meowing Cat[/url] · DRAGON-STUDIO (Pixabay)
[url=https://pixabay.com/sound-effects/nature-big-dog-bark-distant-113701/]Big Dog Bark Distant[/url] · solarmusic (Pixabay)
[url=https://freesound.org/people/soundofsong/sounds/650575/]cat purring loop.wav[/url] · soundofsong (Freesound)
[url=https://pixabay.com/sound-effects/people-fumar-6420/]Fumar[/url] · sbaneat (Freesound via Pixabay)
[url=https://pixabay.com/sound-effects/people-having-a-smoke-89760/]Having A Smoke[/url] · husky70 (Freesound via Pixabay)
[url=https://freesound.org/people/Henaway/sounds/127979/]Scratching Paper.mp3[/url] · Henaway (Freesound)
[url=https://freesound.org/people/pagancow/sounds/15419/]dorm door opening.wav[/url] · pagancow (Freesound)
[url=https://pixabay.com/sound-effects/film-special-effects-bllrr-text-loop-82399/]Bllrr-text-loop[/url] · lulyc (Freesound via Pixabay)
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
	["ui.credits.broadcast", "Broadcast audio", """Kasaysayan sa mga Liham ni Tiya Dely · DZRH radio drama, sourced from [url=https://www.youtube.com/watch?v=IrpTpQobwUc]BokerTV’s upload[/url]
[url=https://freesound.org/people/IESP/sounds/340020/]Sounds from a TV[/url] by IESP (Freesound) · [url=https://creativecommons.org/licenses/by/3.0/]CC BY 3.0[/url]
057519 Train Announcement · Freesound Community (Pixabay)
[url=https://freesound.org/people/uair01/sounds/86613/]shortwave criminal history.wav[/url] by uair01 (bundled Freesound recording) · [url=https://creativecommons.org/licenses/by/3.0/]CC BY 3.0[/url]"""],
	["ui.credits.fonts", "Typefaces", """[url=https://rsms.me/inter/]Inter[/url] · The Inter Project Authors and Rasmus Andersson · [url=https://github.com/rsms/inter/blob/v3.19/LICENSE.txt]SIL Open Font License 1.1[/url]
[url=https://fontstruct.com/fontstructions/show/2878521/eas-vhs]EAS VHS[/url] · Lastnames (listed as [url=https://www.dafont.com/easvhs.font]Rurr[/url]) · [url=https://creativecommons.org/licenses/by/3.0/]CC BY 3.0[/url]"""],
]

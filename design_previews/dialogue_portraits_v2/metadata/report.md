# Dialogue portrait inventory and proposed expression assignments

Review-only artwork metadata. No runtime script, resource, scene, localization row, or existing portrait has been changed.

Static source coverage: 17 active NPC identities plus Player; 64 authored active DialogueLines (57 NPC lines, 7 player replies). Every line has a current English and Tagalog translation in game_text_merged.csv. The per-line JSON preserves the untranslated source string used for lookup, current translations, scene/resource location, sequence binding, and proposed expression.

The active destination scenes instantiate these speakers. Mang Romy and Barangay Hall have no authored NPC speaker entities. This inventory does not imply a manual gameplay playthrough.

| Character | Destination | DialogueLines in its scene | Proposed portrait states |
| --- | --- | ---: | --- |
| Nanay | home | 14 | neutral, speaking, concerned, urgent |
| Lola | home | 11 | neutral, speaking, concerned, relieved |
| Ate Linda | tindahan | 5 | neutral, speaking, apologetic, grateful |
| Mang Nestor | tindahan | 7 | neutral, speaking, hopeful, grateful, concerned |
| Kapitbahay | tindahan | 1 | neutral, speaking, uncertain |
| Tambay | tindahan | 2 | neutral, speaking, coaxing, concerned |
| Pharmacy Boy | pharmacy | 1 | neutral, speaking |
| Tindero | pharmacy | 3 | neutral, speaking, cheerful |
| Ate Maribel | pharmacy | 2 | neutral, speaking, amused |
| Hardware Girl | hardware | 3 | neutral, speaking, weary, helpful |
| Tatay Jun | hardware | 2 | neutral, speaking, amused, concerned |
| Tauhan ni Kap | hardware | 2 | neutral, speaking, defensive |
| Grocery Girl | grocery | 3 | neutral, speaking, urgent, annoyed |
| Palengke Queue Man | grocery | 2 | neutral, speaking, frustrated, stern |
| Panic Buyer | grocery | 2 | neutral, speaking, anxious, overwhelmed |
| Nanay sa Palengke | grocery | 2 | neutral, speaking, exhausted, compassionate |
| Stranger | grocery | 2 | neutral, speaking, pleading, grateful |
| Player | all destinations | 7 | neutral, speaking, thinking, surprised, determined |

## Scope and integration notes

- DialogueUI already switches the portrait on every DialogueLine.expression, so per-line bindings can implement NPC expression changes without another manager or emotion inference system.
- 29 of the 64 active lines currently have no portrait binding; these are Linda branch dialogue, new story NPCs and quest NPCs. Seven active store-speaker lines use the Linda placeholder, Pharmacy screenshot, or Chooks image.
- All states should preserve identity, frame, clothing and character-specific background; change the face and subtle pose so emotion remains legible at the actual 150 px base dialogue display.
- Neutral is a library/fallback pose. Speaking means an attentive conversational expression. Named emotion states are still speaking poses where appropriate; this plan does not introduce mouth animation.
- Lola Resource_clmbx is labeled Nanay in source but reports "Sabi ni Nanay..." and already uses Lola artwork. Assign Lola concerned and review the speaker correction at the integration gate.
- Lola sequence_hint_all_done is reached after the hints are discovered, not after every task is resolved. Its relieved portrait must be gentle and cautiously calm, not a celebratory victory image.
- Ate Linda has two configured external fallback lines, but current no_hammer/trade/discounted branches all have non-null sequences, so these fallback lines are recorded separately. trade_complete_sequence is declared but unassigned and unused.
- Player surprise is warranted by three shop lines: "Ikaw ulit?!!", the mistaken Ate Linda identity, and "VIC SOTTO?!?!". Player determined fits "Ako na po bahala nay."; thought portrait fits the actual medicine reminder. Every player state needs the model glasses.
- MonologueUI uses a shared texture in game/ui/inner_dialogue/monologue_ui.tscn, not DialogueLine.expression; replacing that shared inner-thought texture later covers pickups, task and object monologues. Per-object emotion inference would be extra runtime scope and is not required for NPC expressions.
- Twelve other authored DialogueLines are legacy/unreferenced: the old Nanay resource chain, unused old Linda line resources, and the generic NPC sample (Chris/Wews/Chris na malungkot). Their content is recorded without presenting them as new active characters.
- Quest choice modals show text/buttons only and do not have portrait controls; offer/done dialogue lines already supply contextual NPC expressions. The portrait work need not redesign those modals.

## Every active authored line

| Speaker | Proposed state | Source resource and sequence | Authored source text |
| --- | --- | --- | --- |
| Nanay | speaking | game/entities/nanay/nanay.tscn:12 / Resource_dclit / Resource_jfkbs[0] | Anak kamusta, Narinig mo na ba yung balita? |
| Nanay | concerned | game/entities/nanay/nanay.tscn:19 / Resource_x1yr6 / Resource_jfkbs[1] | May paparating na bagyo ulit... kailangan nating maghanda. |
| Nanay | concerned | game/entities/nanay/nanay.tscn:26 / Resource_tmuxm / Resource_jfkbs[2] | Mas malakas daw ito kaysa dati, kaya kailangan nating maging maingat. |
| Nanay | speaking | game/entities/nanay/nanay.tscn:33 / Resource_8t3t3 / Resource_jfkbs[3] | May kailangan tayong bilhin bago lumakas ang bagyo. Ito ang pera, anak. |
| Nanay | speaking | game/entities/nanay/nanay.tscn:40 / Resource_gkn0j / Resource_jfkbs[4] | Nasa [b]bodega[/b] ang [b]martilyo[/b], [b]radyo[/b], at [b]flashlight[/b]. Kailangan ng [b]isang baterya bawat isa[/b] ng radyo at flashlight bago ilagay sa [b]istante katabi ni Lola[/b]. |
| Nanay | concerned | game/entities/nanay/nanay.tscn:47 / Resource_2bejg / Resource_jfkbs[5] | [i]Inabot ni Nanay ang pera para sa mga kailangang bilhin.[/i] Hindi natin maililigtas lahat, anak. Unahin mo ang pinaka-kailangan. |
| Nanay | concerned | game/entities/nanay/nanay.tscn:54 / Resource_6khh6 / Resource_jfkbs[6] | Kasya dapat yan kung maingat ka sa pagbili. Mag-ingat ka ha. |
| Player | speaking | game/entities/nanay/nanay.tscn:61 / Resource_ucdwx / Resource_jfkbs[7] | Opo Nay. Hahanapin ko kung ano ang kailangan ihanda. |
| Nanay | concerned | game/entities/nanay/nanay.tscn:68 / Resource_d6eln / Resource_jfkbs[8] | Pasensya na anak, hindi ko kayang umalis ng bahay dahil wala mag aalaga sa bunso. |
| Nanay | concerned | game/entities/nanay/nanay.tscn:75 / Resource_dt7x6 / Resource_jfkbs[9] | Ikaw lang maaasahan ko anak. Mag-ingat ka ha, bumalik ka agad. |
| Player | determined | game/entities/nanay/nanay.tscn:82 / Resource_67bnw / Resource_jfkbs[10] | Ako na po bahala nay. |
| Nanay | speaking | game/entities/nanay/nanay.tscn:94 / Resource_wdexl / Resource_6ed0c[0] | Kamusta anak, nabili mo na ba ang mga kailangan? |
| Nanay | concerned | game/entities/nanay/nanay.tscn:106 / Resource_wklle / Resource_2gl7e[0] | Lumalakas na ang hangin anak, mag-ingat ka. |
| Nanay | urgent | game/entities/nanay/nanay.tscn:118 / Resource_ysi4t / Resource_2080c[0] | Huwag ka nang lumabas ulit anak. Malapit na ang bagyo, dito ka nalang at para ligtas. |
| Lola | speaking | game/entities/lola/lola.tscn:12 / Resource_adolq / Resource_qv5jj[0] | Oy apo, halika. Umupo ka muna sandali.  |
| Lola | concerned | game/entities/lola/lola.tscn:19 / Resource_f6xjy / Resource_qv5jj[1] | Apo yung bagyong paparating mag-ingat ka ha. |
| Player | speaking | game/entities/lola/lola.tscn:26 / Resource_q26se / Resource_qv5jj[2] | Opo Lola. |
| Lola | speaking | game/entities/lola/lola.tscn:33 / Resource_8ka6y / Resource_qv5jj[3] | Mabuti naman. Pero yung [b]gamot[/b] ko huwag mo kalimutan yung sa [b]botika[/b] ha.  |
| Lola | concerned | game/entities/lola/lola.tscn:40 / Resource_ak15h / Resource_qv5jj[4] | Pag walang gamot, mahihirapan ako. Pasensya na apo.  |
| Player | thinking | game/entities/lola/lola.tscn:47 / Resource_5d8dr / Resource_qv5jj[5] | Kailangan ni Lola ang [b]gamot[/b]. Kailangan ko pumunta ng [b]botika[/b]. |
| Lola | speaking | game/entities/lola/lola.tscn:54 / Resource_ebi62 / Resource_qv5jj[6] | Sige na apo, pakilagay na lang sa [b]drawer sa higaan[/b] yung aking [b]gamot[/b].  |
| Lola | concerned | game/entities/lola/lola.tscn:66 / Resource_dyppw / Resource_t0cy6[0] | Yung [b]gamot[/b], huwag mong kalimutan apo. [i]Mahalaga yun sa akin.[/i] |
| Lola | concerned | game/entities/lola/lola.tscn:78 / Resource_tkmwj / Resource_d6pkr[0] | Pag umulan nang malakas at walang [b]panakip sa kisame[/b]... [i]basa lahat tayo dito.[/i]  |
| Lola | concerned | game/entities/lola/lola.tscn:90 / Resource_clmbx / Resource_d5nod[0] | Sabi ni Nanay, wala tayong [b]pagkain[/b] para bukas. Kailangan kahit [b]de lata[/b]. |
| Lola | relieved | game/entities/lola/lola.tscn:102 / Resource_uqh7n / Resource_twvbh[0] | Mabuti na. Nandito na tayo. Dasal lang tayo ngayon. |
| Ate Linda | speaking | game/entities/ate_linda_npc/ate_linda.tscn:17 / Line_trade_1 / Seq_trade[0] | Iho, kung may [b]martilyo[/b] ka sana, maayos ko itong istante. Kapag natulungan mo ako, [b]bababaan ko presyo[/b] ko sa'yo. |
| Ate Linda | grateful | game/entities/ate_linda_npc/ate_linda.tscn:23 / Line_trade_2 / Seq_trade[1] | Ipapahiram mo? Sige, utang na loob ko 'to. Ibababa ko presyo, pero kailangan mo ng [b]pamalit[/b] kung aayusin mo pa bahay n'yo. |
| Ate Linda | grateful | game/entities/ate_linda_npc/ate_linda.tscn:34 / Line_discounted / Seq_discounted[0] | Salamat, iho. Para sa'yo, mas mababa na presyo. |
| Ate Linda | speaking | game/entities/ate_linda_npc/ate_linda.tscn:45 / Line_no_hammer_1 / Seq_no_hammer[0] | Oh, iho, ano ang iyong mga kailangan? |
| Ate Linda | apologetic | game/entities/ate_linda_npc/ate_linda.tscn:51 / Line_no_hammer_2 / Seq_no_hammer[1] | Pasensya na at mataas presyo. Kung may [b]martilyo[/b] ka sana para dito sa istante, [b]bababaan ko presyo[/b] ko sa'yo. |
| Mang Nestor | hopeful | game/entities/quest_npcs/mang_nestor.tscn:19 / OfferLine1 / OfferSequence[0] | Anak, pwede bang makisuyo? Hindi ako makaalis, hinihintay ko pa asawa ko. |
| Mang Nestor | speaking | game/entities/quest_npcs/mang_nestor.tscn:25 / OfferLine2 / OfferSequence[1] | Bilhan mo sana ako ng [b]Half Chicken[/b] sa [b]Go To Chooks[/b], katabi lang ng [b]Botika[/b]. |
| Mang Nestor | hopeful | game/entities/quest_npcs/mang_nestor.tscn:31 / OfferLine3 / OfferSequence[2] | Eto ang [b]PHP 150[/b] para sa manok. Ikaw na bahala sa sukli. Nagtitiwala akong makakauwi kami na may [b]hapunan[/b]. |
| Mang Nestor | hopeful | game/entities/quest_npcs/mang_nestor.tscn:42 / WaitingLine / WaitingSequence[0] | Wala pa? Nagtitiwala pa rin ako sa'yo. Ang [b]Half Chicken[/b] ay sa [b]Go To Chooks[/b], katabi ng [b]Botika[/b]. |
| Mang Nestor | grateful | game/entities/quest_npcs/mang_nestor.tscn:53 / CompleteLine / CompleteSequence[0] | Ay, salamat. May extra [b]tarp[/b] ako sa tricycle. Kunin mo. Mas kailangan n'yo 'to sa bahay. |
| Mang Nestor | concerned | game/entities/quest_npcs/mang_nestor.tscn:64 / FullInventoryLine / FullInventorySequence[0] | Naku, puno ang dala mo. Magbawas ka muna para maabot ko sa'yo itong tarp. |
| Mang Nestor | grateful | game/entities/quest_npcs/mang_nestor.tscn:75 / DoneLine / DoneSequence[0] | Salamat ulit, anak. Umuwi ka na rin bago tuluyang lumakas ang hangin. |
| Kapitbahay | uncertain | game/entities/story_npcs/tape_neighbor.tscn:18 / Line1 / Sequence[0] | Nag-tape na ako ng bintana. Hindi ko alam kung science o dasal ang gumagana. |
| Tambay | coaxing | game/entities/quest_npcs/smoke_break_npc.tscn:18 / OfferLine / OfferSequence[0] | Stress ka na rin ba sa bagyo? Yosi muna tayo sa gilid. Sandali lang. |
| Tambay | concerned | game/entities/quest_npcs/smoke_break_npc.tscn:29 / DoneLine / DoneSequence[0] | Ayos na. Pero lumakas na ulan, ah. Sana sulit yung pahinga. |
| Pharmacy Boy | speaking | game/entities/pharmacist/pharma_dude.tscn:16 / Resource_6k71h / Resource_iev7r[0] | Ano po ang inyong kailangan? Mabuti at naabutan niyo pa ang [b]botika[/b] na bukas. |
| Tindero | cheerful | game/entities/chooks_to_go_seller.tscn:11 / Resource_leh6v / Resource_eclqx[0] | Ano pa hinihintay mo iho, bili na ng aming malinamnam na manok! |
| Tindero | cheerful | game/entities/chooks_to_go_seller.tscn:18 / Resource_uelfc / Resource_eclqx[1] | Siguradong mabubusog ka dito, promise! |
| Player | surprised | game/entities/chooks_to_go_seller.tscn:25 / Resource_htrks / Resource_eclqx[2] | VIC SOTTO?!?! |
| Ate Maribel | speaking | game/entities/story_npcs/ate_maribel.tscn:18 / Line1 / Sequence[0] | Kung [b]manok[/b] hanap mo, nasa tabi lang ng [b]Botika[/b] ang [b]Go To Chooks[/b]. |
| Ate Maribel | amused | game/entities/story_npcs/ate_maribel.tscn:24 / Line2 / Sequence[1] | Naamoy mo na bago mo makita. Effective signage din pala ang gutom. |
| Hardware Girl | weary | game/entities/hardware_girl/hardware_girl.tscn:15 / Resource_lk3gm / Resource_jdpt7[0] | Bili na kayo, at magsasara na ako. Halos naubos na lahat ni Kapitan ang mga [b]supplies[/b]. |
| Player | surprised | game/entities/hardware_girl/hardware_girl.tscn:22 / Resource_8a7sq / Resource_jdpt7[1] | Ikaw ulit?!! |
| Hardware Girl | helpful | game/entities/hardware_girl/hardware_girl.tscn:29 / Resource_hqigv / Resource_jdpt7[2] | Pero i-check mo sa una unahan baka ay mayroon pa tira-tirang [b]plywood[/b] doon. |
| Tatay Jun | amused | game/entities/story_npcs/tatay_jun.tscn:18 / Line1 / Sequence[0] | Lahat naghahanap ng [b]pako[/b] ngayon. Parang exam, pero [b]bubong[/b] ang reviewer. |
| Tatay Jun | concerned | game/entities/story_npcs/tatay_jun.tscn:24 / Line2 / Sequence[1] | Kung may [b]martilyo[/b] ka, ingatan mo. Kapag nawala 'yan, gastos na naman. |
| Tauhan ni Kap | speaking | game/entities/story_npcs/kaps_worker.tscn:18 / Line1 / Sequence[0] | Utos lang ni Kapitan. Sabi niya bilhin ko lahat ng [b]pako[/b], [b]tarp[/b], [b]plywood[/b]... lahat daw kailangan sa barangay. |
| Tauhan ni Kap | defensive | game/entities/story_npcs/kaps_worker.tscn:24 / Line2 / Sequence[1] | Hindi ko na tinanong kung bakit sa bodega niya muna dadalhin. Trabaho lang, iho. |
| Grocery Girl | urgent | game/entities/grocery_girl/grocery_girl.tscn:15 / Resource_lix8p / Resource_hwteu[0] | Oh, ano mga kailangan mo? Bilis, may bagyo na paparating at magsasara na ang [b]grocery[/b]. |
| Player | surprised | game/entities/grocery_girl/grocery_girl.tscn:22 / Resource_l50sn / Resource_hwteu[1] | Ate Linda?? Nagtatrabaho karin pala sa hardware? Paano ka po nakarating dito?! |
| Grocery Girl | annoyed | game/entities/grocery_girl/grocery_girl.tscn:29 / Resource_sfjle / Resource_hwteu[2] | Sinong Ate Linda?! kita mo nag tatrabaho ako dito! |
| Palengke Queue Man | frustrated | game/entities/story_npcs/palengke_queue_man.tscn:18 / Line1 / Sequence[0] | Kanina pa ako nakapila. Yung iba, doble-doble ang binibili. |
| Palengke Queue Man | stern | game/entities/story_npcs/palengke_queue_man.tscn:24 / Line2 / Sequence[1] | Kung kukuha ka ng [b]de lata[/b], kumuha ka lang ng [b]kaya mong dalhin[/b]. May kasunod ka pa. |
| Panic Buyer | anxious | game/entities/story_npcs/panic_buyer.tscn:18 / Line1 / Sequence[0] | Kailangan ko pa ng lima... hindi, sampu! Paano kung isang linggo walang kuryente? |
| Panic Buyer | overwhelmed | game/entities/story_npcs/panic_buyer.tscn:24 / Line2 / Sequence[1] | Wait, may budget pa ba ako? Ayoko tingnan. |
| Nanay sa Palengke | exhausted | game/entities/story_npcs/wet_parent.tscn:18 / Line1 / Sequence[0] | Basa na sapatos ko, pero kailangan pa rin pumila. May bata akong naghihintay sa bahay. |
| Nanay sa Palengke | compassionate | game/entities/story_npcs/wet_parent.tscn:24 / Line2 / Sequence[1] | Kapag may nakuha kang extra, isipin mo rin kung sino pa ang wala. |
| Stranger | pleading | game/entities/quest_npcs/money_beggar.tscn:18 / AskLine / AskSequence[0] | Pasensya na. Kulang pamasahe ko pauwi. May maiaabot ka bang konti? |
| Stranger | grateful | game/entities/quest_npcs/money_beggar.tscn:29 / ThanksLine / ThanksSequence[0] | Salamat. Hindi ko makakalimutan 'to. |

"""Read-only source inventory; writes only sibling review metadata."""
from pathlib import Path
import csv
import json
import re

ROOT = Path(__file__).resolve().parents[3]
OUT = Path(__file__).resolve().parent
ROSTER = [
    ('nanay', 'Nanay', 'home', 'game/entities/nanay/nanay.tscn', ['neutral','speaking','concerned','urgent']),
    ('lola', 'Lola', 'home', 'game/entities/lola/lola.tscn', ['neutral','speaking','concerned','relieved']),
    ('ate_linda', 'Ate Linda', 'tindahan', 'game/entities/ate_linda_npc/ate_linda.tscn', ['neutral','speaking','apologetic','grateful']),
    ('mang_nestor', 'Mang Nestor', 'tindahan', 'game/entities/quest_npcs/mang_nestor.tscn', ['neutral','speaking','hopeful','grateful','concerned']),
    ('tape_neighbor', 'Kapitbahay', 'tindahan', 'game/entities/story_npcs/tape_neighbor.tscn', ['neutral','speaking','uncertain']),
    ('smoke_break', 'Tambay', 'tindahan', 'game/entities/quest_npcs/smoke_break_npc.tscn', ['neutral','speaking','coaxing','concerned']),
    ('pharmacist', 'Pharmacy Boy', 'pharmacy', 'game/entities/pharmacist/pharma_dude.tscn', ['neutral','speaking']),
    ('chooks_seller', 'Tindero', 'pharmacy', 'game/entities/chooks_to_go_seller.tscn', ['neutral','speaking','cheerful']),
    ('ate_maribel', 'Ate Maribel', 'pharmacy', 'game/entities/story_npcs/ate_maribel.tscn', ['neutral','speaking','amused']),
    ('hardware_girl', 'Hardware Girl', 'hardware', 'game/entities/hardware_girl/hardware_girl.tscn', ['neutral','speaking','weary','helpful']),
    ('tatay_jun', 'Tatay Jun', 'hardware', 'game/entities/story_npcs/tatay_jun.tscn', ['neutral','speaking','amused','concerned']),
    ('kaps_worker', 'Tauhan ni Kap', 'hardware', 'game/entities/story_npcs/kaps_worker.tscn', ['neutral','speaking','defensive']),
    ('grocery_girl', 'Grocery Girl', 'grocery', 'game/entities/grocery_girl/grocery_girl.tscn', ['neutral','speaking','urgent','annoyed']),
    ('queue_man', 'Palengke Queue Man', 'grocery', 'game/entities/story_npcs/palengke_queue_man.tscn', ['neutral','speaking','frustrated','stern']),
    ('panic_buyer', 'Panic Buyer', 'grocery', 'game/entities/story_npcs/panic_buyer.tscn', ['neutral','speaking','anxious','overwhelmed']),
    ('wet_parent', 'Nanay sa Palengke', 'grocery', 'game/entities/story_npcs/wet_parent.tscn', ['neutral','speaking','exhausted','compassionate']),
    ('stranger', 'Stranger', 'grocery', 'game/entities/quest_npcs/money_beggar.tscn', ['neutral','speaking','pleading','grateful']),
]

STATE_MAP = {
 'nanay': dict(zip(['Resource_dclit','Resource_x1yr6','Resource_tmuxm','Resource_8t3t3','Resource_gkn0j','Resource_2bejg','Resource_6khh6','Resource_ucdwx','Resource_d6eln','Resource_dt7x6','Resource_67bnw','Resource_wdexl','Resource_wklle','Resource_ysi4t'], ['speaking','concerned','concerned','speaking','speaking','concerned','concerned','speaking','concerned','concerned','determined','speaking','concerned','urgent'])),
 'lola': dict(zip(['Resource_adolq','Resource_f6xjy','Resource_q26se','Resource_8ka6y','Resource_ak15h','Resource_5d8dr','Resource_ebi62','Resource_dyppw','Resource_tkmwj','Resource_clmbx','Resource_uqh7n'], ['speaking','concerned','speaking','speaking','concerned','thinking','speaking','concerned','concerned','concerned','relieved'])),
 'ate_linda': {'Line_trade_1':'speaking','Line_trade_2':'grateful','Line_discounted':'grateful','Line_no_hammer_1':'speaking','Line_no_hammer_2':'apologetic','Resource_xc5m4':'speaking','Resource_ylcxj':'apologetic'},
 'mang_nestor': {'OfferLine1':'hopeful','OfferLine2':'speaking','OfferLine3':'hopeful','WaitingLine':'hopeful','CompleteLine':'grateful','FullInventoryLine':'concerned','DoneLine':'grateful'},
 'tape_neighbor': ['uncertain'], 'smoke_break': ['coaxing','concerned'],
 'pharmacist': ['speaking'], 'chooks_seller': ['cheerful','cheerful','surprised'],
 'ate_maribel': ['speaking','amused'], 'hardware_girl': ['weary','surprised','helpful'],
 'tatay_jun': ['amused','concerned'], 'kaps_worker': ['speaking','defensive'],
 'grocery_girl': ['urgent','surprised','annoyed'], 'queue_man': ['frustrated','stern'],
 'panic_buyer': ['anxious','overwhelmed'], 'wet_parent': ['exhausted','compassionate'],
 'stranger': ['pleading','grateful'],
}

def string_value(body, name):
    match = re.search(r'^' + re.escape(name) + r' = ("(?:[^"\\]|\\.)*")', body, re.M | re.S)
    return json.loads(match[1]) if match else None

def parse(path):
    raw = (ROOT/path).read_text(encoding='utf-8')
    sections = list(re.finditer(r'^\[([^\n]+)\]\s*$', raw, re.M))
    ext, lines, sequences, bindings, models, scripts = {}, [], {}, [], [], []
    for i, sec in enumerate(sections):
        header = sec[1]
        body = raw[sec.end():sections[i+1].start() if i+1 < len(sections) else len(raw)]
        line_no = raw[:sec.start()].count('\n')+1
        ident = re.search(r'\bid="([^"]+)"', header)
        if header.startswith('ext_resource'):
            ref_path = re.search(r'\bpath="([^"]+)"', header)
            if ref_path:
                ext[ident[1]] = ref_path[1]
                if 'type="Script"' in header: scripts.append(ref_path[1])
                if 'type="PackedScene"' in header and any(x in ref_path[1] for x in ['npc_assets','models/']): models.append(ref_path[1])
        if header.startswith('sub_resource') or header == 'resource':
            rid = ident[1] if ident else 'resource'
            speaker = string_value(body, 'speaker_name')
            if speaker is not None:
                expression = re.search(r'^expression = ExtResource\("([^"]+)"\)', body, re.M)
                lines.append({'source_path':path, 'source_line':line_no, 'resource_id':rid, 'speaker_name':speaker, 'source_text':string_value(body,'text'), 'current_expression':ext.get(expression[1]) if expression else None})
            if re.search(r'^lines = ', body, re.M):
                sequences[rid] = [(x[0],x[1]) for x in re.findall(r'(SubResource|ExtResource)\("([^"]+)"\)', re.search(r'^lines = (.*)',body,re.M)[1].split('](',1)[-1])]
        if header.startswith('node'):
            for name, kind, ref in re.findall(r'^(\w*sequence\w*) = (SubResource|ExtResource)\("([^"]+)"\)',body,re.M):
                bindings.append({'property':name,'kind':kind,'resource_id':ref})
    return {'lines':lines,'sequences':sequences,'bindings':bindings,'ext':ext,'models':models,'scripts':scripts}

assignments, roster, external_fallback = [], [], []
for key, label, location, path, expressions in ROSTER:
    data = parse(path)
    entries = data['lines']
    for binding in data['bindings']:
        if binding['kind'] == 'ExtResource':
            external = data['ext'][binding['resource_id']].removeprefix('res://')
            more = parse(external)
            for entry in more['lines']:
                external_fallback.append({**entry,'npc_id':key,'proposed_speaker_id':key,'proposed_expression':STATE_MAP[key].get(entry['resource_id'],'speaking'),'status':'configured_fallback_not_selected_with_current_non_null_branches','sequence_bindings':[binding]})
    for index, entry in enumerate(entries):
        state = STATE_MAP[key]
        expression = state.get(entry['resource_id'],'speaking') if isinstance(state,dict) else state[index]
        sequence_refs = []
        for seqid,refs in data['sequences'].items():
            for line_index,(kind,ref) in enumerate(refs):
                if kind == 'SubResource' and ref == entry['resource_id']:
                    sequence_refs.append({'sequence_resource_id':seqid,'line_index_zero_based':line_index,'export_properties':[b['property'] for b in data['bindings'] if b['kind']=='SubResource' and b['resource_id']==seqid]})
        proposed_id = 'player' if entry['speaker_name']=='Player' else key
        note = None
        if key=='lola' and entry['resource_id']=='Resource_clmbx':
            note='Source speaker is Nanay but this is a Lola line reporting what Nanay said; proposed speaker correction to Lola requires later integration approval.'
        assignments.append({**entry,'npc_id':key,'proposed_speaker_id':proposed_id,'proposed_expression':expression,'sequence_bindings':sequence_refs,'status':'active_authored','review_note':note})
    roster.append({'id':key,'speaker_name':label,'location':location,'scene_path':path,'model_paths':data['models'],'script_paths':data['scripts'],'expressions':expressions,'active_authored_line_count':len(entries),'reachability':'Instanced by SceneManager destination '+location})

player = {'id':'player','speaker_name':'Player','scene_path':'game/entities/playerv2/playerv_2.tscn','expressions':['neutral','speaking','thinking','surprised','determined'],'active_authored_line_count':sum(e['proposed_speaker_id']=='player' for e in assignments),'note':'Add glasses to every state. Shared inner-dialogue scene currently binds playerInnerThoughts.png, covering item/task/narrative monologues.'}
roster.append(player)

active_paths = {e['source_path'] for e in assignments+external_fallback}
legacy=[]
for path in sorted((ROOT/'game').rglob('*')):
    if path.suffix not in {'.tscn','.tres'}: continue
    relative = path.relative_to(ROOT).as_posix()
    if relative in active_paths: continue
    if 'speaker_name = ' not in path.read_text(encoding='utf-8'): continue
    legacy.extend({**e,'status':'legacy_or_unreferenced','integration':'Do not change without confirming reachability'} for e in parse(relative)['lines'])

assert len(roster)==18 and len(ROSTER)==17
assert all(e['sequence_bindings'] for e in assignments), 'Every active line must belong to a bound sequence'
assert all(e['source_text'] for e in assignments)
for e in assignments:
    expressions = next(r['expressions'] for r in roster if r['id']==e['proposed_speaker_id'])
    assert e['proposed_expression'] in expressions, e

payload = {'status':'review_only_not_integrated','npc_count':17,'portrait_character_count':18,'active_authored_line_count':len(assignments),'active_npc_spoken_line_count':sum(e['proposed_speaker_id']!='player' for e in assignments),'active_player_reply_count':sum(e['proposed_speaker_id']=='player' for e in assignments),'configured_fallback_lines':external_fallback,'active_assignments':assignments,'legacy_or_unreferenced_lines':legacy}
localized = {}
with (ROOT/'game/localization/game_text_merged.csv').open(encoding='utf-8-sig',newline='') as file:
    for row in csv.DictReader(file):
        localized.setdefault(row['source_text'],row)
for entry in assignments+external_fallback:
    row = localized.get(entry['source_text'])
    entry['localization'] = {k:row[k] for k in ['key','english','tagalog']} if row else None
payload['localized_active_line_count'] = sum(e['localization'] is not None for e in assignments)
(OUT/'roster.json').write_text(json.dumps(roster,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(OUT/'dialogue_assignments.json').write_text(json.dumps(payload,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
report = [
    '# Dialogue portrait inventory and proposed expression assignments',
    '',
    'Review-only artwork metadata. No runtime script, resource, scene, localization row, or existing portrait has been changed.',
    '',
    'Static source coverage: 17 active NPC identities plus Player; 64 authored active DialogueLines (57 NPC lines, 7 player replies). Every line has a current English and Tagalog translation in game_text_merged.csv. The per-line JSON preserves the untranslated source string used for lookup, current translations, scene/resource location, sequence binding, and proposed expression.',
    '',
    'The active destination scenes instantiate these speakers. Mang Romy and Barangay Hall have no authored NPC speaker entities. This inventory does not imply a manual gameplay playthrough.',
    '',
    '| Character | Destination | DialogueLines in its scene | Proposed portrait states |',
    '| --- | --- | ---: | --- |',
]
for row in roster:
    report.append(f"| {row['speaker_name']} | {row.get('location','all destinations')} | {row['active_authored_line_count']} | {', '.join(row['expressions'])} |")
report.extend([
    '',
    '## Scope and integration notes',
    '',
    '- DialogueUI already switches the portrait on every DialogueLine.expression, so per-line bindings can implement NPC expression changes without another manager or emotion inference system.',
    '- 29 of the 64 active lines currently have no portrait binding; these are Linda branch dialogue, new story NPCs and quest NPCs. Seven active store-speaker lines use the Linda placeholder, Pharmacy screenshot, or Chooks image.',
    '- All states should preserve identity, frame, clothing and character-specific background; change the face and subtle pose so emotion remains legible at the actual 150 px base dialogue display.',
    '- Neutral is a library/fallback pose. Speaking means an attentive conversational expression. Named emotion states are still speaking poses where appropriate; this plan does not introduce mouth animation.',
    '- Lola Resource_clmbx is labeled Nanay in source but reports "Sabi ni Nanay..." and already uses Lola artwork. Assign Lola concerned and review the speaker correction at the integration gate.',
    '- Lola sequence_hint_all_done is reached after the hints are discovered, not after every task is resolved. Its relieved portrait must be gentle and cautiously calm, not a celebratory victory image.',
    '- Ate Linda has two configured external fallback lines, but current no_hammer/trade/discounted branches all have non-null sequences, so these fallback lines are recorded separately. trade_complete_sequence is declared but unassigned and unused.',
    '- Player surprise is warranted by three shop lines: "Ikaw ulit?!!", the mistaken Ate Linda identity, and "VIC SOTTO?!?!". Player determined fits "Ako na po bahala nay."; thought portrait fits the actual medicine reminder. Every player state needs the model glasses.',
    '- MonologueUI uses a shared texture in game/ui/inner_dialogue/monologue_ui.tscn, not DialogueLine.expression; replacing that shared inner-thought texture later covers pickups, task and object monologues. Per-object emotion inference would be extra runtime scope and is not required for NPC expressions.',
    '- Twelve other authored DialogueLines are legacy/unreferenced: the old Nanay resource chain, unused old Linda line resources, and the generic NPC sample (Chris/Wews/Chris na malungkot). Their content is recorded without presenting them as new active characters.',
    '- Quest choice modals show text/buttons only and do not have portrait controls; offer/done dialogue lines already supply contextual NPC expressions. The portrait work need not redesign those modals.',
    '',
    '## Every active authored line',
    '',
    '| Speaker | Proposed state | Source resource and sequence | Authored source text |',
    '| --- | --- | --- | --- |',
])
for entry in assignments:
    sequences = ', '.join(f"{x['sequence_resource_id']}[{x['line_index_zero_based']}]" for x in entry['sequence_bindings'])
    source = entry['source_text'].replace('|','\\|').replace('\n','<br>')
    name = next(r['speaker_name'] for r in roster if r['id']==entry['proposed_speaker_id'])
    report.append(f"| {name} | {entry['proposed_expression']} | {entry['source_path']}:{entry['source_line']} / {entry['resource_id']} / {sequences} | {source} |")
(OUT/'report.md').write_text('\n'.join(report)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in payload.items() if isinstance(v,int)},indent=2))
print('Missing portrait bindings:',sum(e['current_expression'] is None for e in assignments))
print('Fallback:',len(external_fallback),'Legacy:',len(legacy))

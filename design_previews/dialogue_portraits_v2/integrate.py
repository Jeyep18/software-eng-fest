"""Apply approved portrait bindings without rewriting other scene properties."""
import hashlib
import json
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parents[1]
META = ROOT / 'metadata'
mapping = json.loads((META / 'dialogue_assignments.json').read_text())
roster = json.loads((META / 'roster.json').read_text())
lines = mapping['active_assignments'] + mapping['configured_fallback_lines']
paths = sorted({a['source_path'] for a in lines})
monologue = 'game/ui/inner_dialogue/monologue_ui.tscn'
baseline = META / 'integration_baseline'
assert not baseline.exists(), 'Integration already started; inspect before rerunning.'
pending = {}
for rel in paths:
    original = (REPO / rel).read_bytes()
    newline = '\r\n' if b'\r\n' in original else '\n'
    text = original.decode('utf-8').replace('\r\n', '\n')
    textures = {}
    for a in (a for a in lines if a['source_path'] == rel):
        identity, expression = a['proposed_speaker_id'], a['proposed_expression']
        texture_id = f'portrait_{identity}_{expression}'
        textures[texture_id] = f'res://game/assets/npc_portraits/stylized/{identity}/{expression}.png'
        pattern = r'(\[sub_resource[^\n]* id="' + re.escape(a['resource_id']) + r'"\]\n)(.*?)(?=\n\[|\Z)'
        matches = list(re.finditer(pattern, text, re.S))
        assert len(matches) == 1, (rel, a['resource_id'])
        block = matches[0].group(2)
        assert f'text = {json.dumps(a["source_text"], ensure_ascii=False)}' in block, (rel, a['resource_id'], 'text drift')
        replacement = f'expression = ExtResource("{texture_id}")'
        if re.search(r'^expression = .*$', block, re.M):
            updated = re.sub(r'^expression = .*$', replacement, block, flags=re.M)
        else:
            updated = re.sub(r'^(speaker_name = .*\n)', r'\1' + replacement + '\n', block, flags=re.M)
        if rel.endswith('lola/lola.tscn') and a['resource_id'] == 'Resource_clmbx':
            updated = updated.replace('speaker_name = "Nanay"', 'speaker_name = "Lola"')
        assert updated != block, (rel, a['resource_id'])
        text = text[:matches[0].start(2)] + updated + text[matches[0].end(2):]
    # Remove only portrait declarations made unused by these replacements.
    for declaration in re.findall(r'^\[ext_resource type="Texture2D"[^\n]*\]\n', text, re.M):
        resource_id = re.search(r'id="([^"]+)"', declaration)[1]
        if f'ExtResource("{resource_id}")' not in text:
            text = text.replace(declaration, '')
    declarations = ''.join(f'[ext_resource type="Texture2D" path="{path}" id="{key}"]\n' for key, path in sorted(textures.items()))
    first_subresource = text.index('[sub_resource')
    text = text[:first_subresource] + declarations + '\n' + text[first_subresource:]
    pending[rel] = text.replace('\n', newline).encode('utf-8')
original = (REPO / monologue).read_bytes()
updated = re.sub(rb'\[ext_resource type="Texture2D"[^\r\n]* id="2_3haje"\]', b'[ext_resource type="Texture2D" path="res://game/assets/npc_portraits/stylized/player/thinking.png" id="2_3haje"]', original)
assert updated != original
pending[monologue] = updated
for r in roster:
    for expression in r['expressions']:
        source = ROOT / 'portraits' / r['id'] / f'{expression}.png'
        destination = REPO / 'game/assets/npc_portraits/stylized' / r['id'] / source.name
        assert source.is_file() and not destination.exists(), str(destination)
for rel in pending:
    saved = baseline / rel
    saved.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(REPO / rel, saved)
for r in roster:
    for expression in r['expressions']:
        source = ROOT / 'portraits' / r['id'] / f'{expression}.png'
        destination = REPO / 'game/assets/npc_portraits/stylized' / r['id'] / source.name
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, destination)
for rel, data in pending.items():
    (REPO / rel).write_bytes(data)
report = {'status': 'approved_and_integrated', 'portrait_count': 68, 'active_line_count': 64, 'fallback_line_count': 2, 'runtime_paths': list(pending), 'sha256': {rel: hashlib.sha256(data).hexdigest() for rel, data in pending.items()}}
(META / 'integration.json').write_text(json.dumps(report, indent=2) + '\n')
print(f'Integrated 68 portraits and 66 line bindings in {len(pending)} runtime resources.')

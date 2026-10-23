"""Build the review-only gallery from the audited roster and line assignments."""
import hashlib
import html
import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent.parent
read = lambda name: json.loads((ROOT / "metadata" / name).read_text(encoding="utf-8"))
roster = read("roster.json")
next(r for r in roster if r["id"] == "player")["location"] = "player"
assignments = read("dialogue_assignments.json")
names = {r["id"]: r["speaker_name"] for r in roster}
h = html.escape
locations = {"home": "Family", "tindahan": "Tindahan & neighborhood", "pharmacy": "Pharmacy & chicken stall", "hardware": "Hardware", "grocery": "Palengke", "player": "Player"}

CSS = """
:root{color-scheme:dark;background:#172126;color:#ebe6d9;font:16px/1.5 system-ui,sans-serif}*{box-sizing:border-box}
body{margin:0 auto;padding:26px;max-width:1220px}h1,h2,h3,p{margin:0 0 14px}h1{font-size:30px;line-height:1.2}h2{font-size:23px}a{color:#d6e4c0}
.tag{font-size:12px;text-transform:uppercase;letter-spacing:1px;color:#c9d9bf}.muted,small{color:#bac5c7}nav{display:flex;gap:16px;flex-wrap:wrap;margin:18px 0}
.cast{display:grid;grid-template-columns:repeat(6,minmax(0,1fr));gap:15px}.card{padding:10px;background:#243138;border:1px solid #43565a;border-radius:8px;text-align:center}
.card a{display:block;text-decoration:none}.card img{width:100%;max-width:150px;height:auto;aspect-ratio:1}.card b{display:block;font-size:14px}
section,details.character{padding:18px;margin:20px 0;background:#202c32;border:1px solid #43565a;border-radius:10px;scroll-margin-top:16px}
summary{cursor:pointer;font-weight:650;font-size:18px}summary small{font-weight:400;font-size:14px}details[open]>summary{margin-bottom:16px}
.row{display:flex;flex-wrap:wrap;gap:14px}.portrait{width:150px;margin:0;text-align:center}.portrait img{width:150px;height:150px;object-fit:cover;display:block;border:1px solid #516368}
.portrait figcaption{font-size:13px;margin-top:6px}.model img{object-fit:contain;background:#334047}.reference{border-right:1px solid #586469;padding-right:14px;margin-right:4px;width:165px}
table{border-collapse:collapse;width:100%;font-size:14px;margin:16px 0}td,th{text-align:left;vertical-align:top;padding:10px;border-bottom:1px solid #47565c}
th{color:#c9d9bf}td:nth-child(1){width:110px}td img{width:84px;height:84px}code{overflow-wrap:anywhere;font-size:12px;color:#bfd4db}
.notice{background:#293a3c;border-left:3px solid #b6c699;padding:14px;margin:18px 0}.table-scroll{overflow:auto}.table-scroll table{min-width:670px}
footer{margin-top:30px;color:#bac5c7;font-size:14px}.sheet section{padding:14px}.sheet h2{margin-bottom:10px}.sheet .tag{margin-bottom:6px}
@media(max-width:850px){.cast{grid-template-columns:repeat(3,minmax(0,1fr))}body{padding:16px}}
@media(max-width:460px){.cast{grid-template-columns:repeat(2,minmax(0,1fr))}.portrait{width:135px}.portrait img{width:135px;height:135px}}
"""

def picture(r, expression, prefix=""):
    src = f'{prefix}portraits/{r["id"]}/{expression}.png'
    return f'<figure class="portrait"><a href="{src}" target="_blank" rel="noopener"><img src="{src}" alt="{h(r["speaker_name"])} — {expression}" width="150" height="150"></a><figcaption>{expression.replace("_"," ").title()}</figcaption></figure>'

def expression_row(r, prefix=""):
    model = f'{prefix}references/{r["id"]}_model.png'
    return '<div class="row"><figure class="portrait model reference"><a href="' + model + '" target="_blank" rel="noopener"><img src="' + model + '" alt="' + h(r["speaker_name"]) + ' 3D model reference" width="150" height="150"></a><figcaption>3D model reference</figcaption></figure>' + "".join(picture(r, e, prefix) for e in r["expressions"]) + "</div>"

def page(title, body, sheet=False):
    return '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>' + h(title) + '</title><style>' + CSS + '</style><body' + (' class="sheet"' if sheet else '') + '>' + body + '</body></html>'

cards = '<div class="cast">' + "".join(
    f'<div class="card"><a href="preview.html#{r["id"]}"><img src="portraits/{r["id"]}/neutral.png" alt="{h(r["speaker_name"])} neutral portrait" width="150" height="150"><b>{h(r["speaker_name"])}</b><small>{len(r["expressions"])} expressions</small></a></div>'
    for r in roster
) + '</div>'
count = sum(len(r["expressions"]) for r in roster)
intro = f'<p class="tag">Bagyong Bahay · approved portrait library v2</p><h1>The complete dialogue cast</h1><p>{len(roster)-1} NPCs + Player · {count} portraits · 64 active interaction lines mapped</p>'
nav = '<nav><a href="cast.html">Cast overview</a>' + "".join(f'<a href="sheets/{key}.html">{title}</a>' for key,title in locations.items()) + '<a href="metadata/report.md">Dialogue inventory</a></nav>'
notice = '<div class="notice">Approved artwork is installed in the game. Click a portrait for its full-resolution PNG. Expression rows show the 150px base game display size. This gallery documents the artwork and approved line assignments.</div>'
notes = '<p class="muted">Model details take priority: Nanay has auburn hair and a dark tee; Lola wears a pale blue jacket. The three shop women share a source model, with their own locations and expression sets. Every player expression includes the model’s black glasses.</p>'
sections = []
for r in sorted(roster, key=lambda r: r["id"] != "player"):
    lines = [a for a in assignments["active_assignments"] if a["proposed_speaker_id"] == r["id"]]
    fallback = [a for a in assignments["configured_fallback_lines"] if a["proposed_speaker_id"] == r["id"]]
    body = expression_row(r)
    if r["id"] == "player":
        body += '<p class="muted" style="margin-top:14px">Glasses are included in all five states. Thinking is installed in the shared task/pickup monologue portrait.</p>'
    if r["id"] in ("ate_linda","hardware_girl","grocery_girl"):
        body += '<p class="muted" style="margin-top:14px">This shop uses the same 3D woman model as the other two vendors. The background and expression library identify her location.</p>'
    def line_table(items):
        rows = []
        for a in items:
            e = a["proposed_expression"]
            loc = a.get("localization") or {}
            note = a.get("review_note")
            source = f'{a["source_path"]}:{a["source_line"]} · {a["resource_id"]}'
            rows.append(f'<tr><td><img src="portraits/{r["id"]}/{e}.png" alt="{h(r["speaker_name"])} {e}"><br>{e}</td><td>{h(loc.get("tagalog") or a["source_text"])}<br><small>{h(loc.get("english") or "")}</small><p><code>{h(source)}</code></p>' + (f'<p class="muted">{h(note)}</p>' if note else '') + '</td></tr>')
        return '<div class="table-scroll"><table><thead><tr><th>Expression</th><th>Tagalog · English · source</th></tr></thead><tbody>' + ''.join(rows) + '</tbody></table></div>'
    body += '<details style="margin-top:18px"><summary>Approved dialogue expressions <small>· ' + str(len(lines)) + ' active lines</small></summary>' + line_table(lines) + '</details>'
    if fallback:
        body += '<details><summary>Configured fallback lines <small>· not selected by current branches</small></summary>' + line_table(fallback) + '</details>'
    sections.append(f'<details class="character" id="{r["id"]}"' + (' open' if r["id"]=="player" else '') + f'><summary>{h(r["speaker_name"])} <small>· {locations[r["location"]]} · {len(r["expressions"])} portraits</small></summary>{body}</details>')
tail = '<footer>Approved portraits and per-line expressions are integrated. Lola’s mislabeled line now identifies Lola. This gallery does not simulate game postprocessing.</footer>'
(ROOT/"preview.html").write_text(page("Bagyong Bahay — portrait design review", intro+nav+notice+cards+notes+''.join(sections)+tail), encoding="utf-8")
compact_style = '<style>.overview .cast{gap:8px}.overview .card{padding:6px}.overview .card small{display:none}.overview .card img{max-width:100px}.overview .card b{font-size:12px;line-height:18px}.overview h1{font-size:24px}.overview>p{font-size:13px;margin-bottom:8px}.overview>nav{margin:12px 0}@media(max-width:850px){.overview .card img{width:70px}.overview{padding:12px}}</style>'
(ROOT/"cast.html").write_text(page("Bagyong Bahay — complete cast",compact_style+'<div class="overview">'+intro+cards+'<nav><a href="preview.html">Open expression and dialogue review</a></nav></div>'),encoding="utf-8")
(ROOT/"sheets").mkdir(exist_ok=True)
for key,title in locations.items():
    body=f'<p class="tag">Bagyong Bahay · design review only</p><h1>{title}</h1><p class="muted">3D reference, then expression library at 150px. Click any image to enlarge.</p>'
    for r in roster:
        if r["location"]==key:
            body+=f'<section><h2>{h(r["speaker_name"])}</h2>'+expression_row(r,"../")+'</section>'
    body+='<nav><a href="../preview.html">Back to complete review</a></nav>'
    (ROOT/"sheets"/f"{key}.html").write_text(page(title+" — expression sheet",body,True),encoding="utf-8")
print(f"Built review gallery: {len(roster)} characters, {count} planned portraits, {len(assignments['active_assignments'])} dialogue bindings.")

def verify():
    from html.parser import HTMLParser
    expected = {f'portraits/{r["id"]}/{e}.png' for r in roster for e in r["expressions"]}
    actual = {p.relative_to(ROOT).as_posix() for p in (ROOT/"portraits").rglob("*.png")}
    assert actual == expected, {"missing":sorted(expected-actual),"extra":sorted(actual-expected)}
    sizes = {}
    hashes = {}
    for rel in sorted(expected):
        data=(ROOT/rel).read_bytes()
        assert data[:8] == b"\x89PNG\r\n\x1a\n", rel
        width,height=struct.unpack(">II",data[16:24])
        assert width==height and width>=1024,(rel,width,height)
        sizes[rel]=[width,height]
        digest=hashlib.sha256(data).hexdigest()
        assert digest not in hashes, (rel,"duplicate",hashes.get(digest))
        hashes[digest]=rel
    for a in assignments["active_assignments"]+assignments["configured_fallback_lines"]:
        assert f'portraits/{a["proposed_speaker_id"]}/{a["proposed_expression"]}.png' in expected,a
        assert a.get("localization",{}).get("english") and a.get("localization",{}).get("tagalog"),a
    assert len(assignments["active_assignments"])==64
    assert len(roster)==18 and count==68
    assert all((ROOT/"references"/f'{r["id"]}_model.png').is_file() for r in roster)
    base_records=read("base_generation_records.json")
    variants=[json.loads(p.read_text(encoding="utf-8")) for p in (ROOT/"metadata"/"generation_records").glob("*.json")]
    assert len(base_records)==18 and len(variants)==50,(len(base_records),len(variants))
    prompt_records=[]
    for record in base_records+variants:
        expression=record.get("expression","neutral")
        rel=f'portraits/{record["id"]}/{expression}.png'
        assert rel in expected,record
        assert record["prompt"] and record["refs"],record
        assert all(Path(ref).is_file() for ref in record["refs"]),record
        prompt_records.append({"id":record["id"],"expression":expression,"portrait_path":rel,"prompt":record["prompt"],"reference_paths":record["refs"],"generated_source":record["source"],"sha256":hashlib.sha256((ROOT/rel).read_bytes()).hexdigest()})
    assert len({r["portrait_path"] for r in prompt_records})==68
    (ROOT/"metadata"/"prompts.json").write_text(json.dumps(prompt_records,indent=2)+"\n",encoding="utf-8")
    class Links(HTMLParser):
        def __init__(self): super().__init__(); self.targets=[]
        def handle_starttag(self,tag,attrs):
            self.targets.extend(v for k,v in attrs if k in ("src","href") and v and not v.startswith(("http:", "https:", "#")))
    for doc in [ROOT/"preview.html",ROOT/"cast.html",*list((ROOT/"sheets").glob("*.html"))]:
        parser=Links();parser.feed(doc.read_text(encoding="utf-8"))
        for target in parser.targets: assert (doc.parent/target.split("#")[0]).is_file(), (str(doc),target)
    baseline=read("runtime_baseline.json")
    changed=[rel for rel,digest in baseline.items() if not (REPO/rel).is_file() or hashlib.sha256((REPO/rel).read_bytes()).hexdigest()!=digest]
    report={"status":"artwork_ready_for_design_approval_not_integrated","npc_count":17,"character_count":18,"portrait_count":68,"active_interaction_line_count":64,"configured_fallback_line_count":2,"model_reference_count":18,"base_generation_record_count":18,"expression_generation_record_count":50,"png_dimensions":sizes,"runtime_baseline_file_count":len(baseline),"runtime_baseline_changed_files":changed,"limits":["Static coverage and browser review; no Godot integration or in-game postprocessing acceptance."]}
    (ROOT/"metadata"/"validation.json").write_text(json.dumps(report,indent=2)+"\n",encoding="utf-8")
    integration = read("integration.json")
    assert set(changed) == set(integration["runtime_paths"]), {"unexpected_runtime_changes": changed}
    for rel, digest in integration["sha256"].items():
        assert hashlib.sha256((REPO/rel).read_bytes()).hexdigest() == digest, rel
    for rel in expected:
        installed = REPO/"game/assets/npc_portraits/stylized"/Path(rel).relative_to("portraits")
        assert installed.read_bytes() == (ROOT/rel).read_bytes(), str(installed)
    report["status"] = "approved_and_integrated"
    report["limits"] = ["Artwork and binding preservation checks; see integration verification for Godot runtime results."]
    (ROOT/"metadata"/"validation.json").write_text(json.dumps(report,indent=2)+"\n",encoding="utf-8")
    print(f"PASS: 68 installed PNGs match approved masters, 64 active and 2 fallback bindings, all gallery links. Only the 19 approved resources differ from the {len(baseline)}-file runtime baseline.")

if __name__ == "__main__":
    import sys
    if "--verify" in sys.argv: verify()


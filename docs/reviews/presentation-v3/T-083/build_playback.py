"""Build a local, network-free playback page from native timestamped captures."""
import json
from pathlib import Path

root = Path(__file__).resolve().parent
trials = []
for kind in ('inner', 'wedges', 'core'):
    record = json.loads((root / 'blind-native' / f'{kind}.json').read_text())
    trials.append([{'file': '../blind-native/' + f['file'], 't': f['wall_seconds']}
                   for f in record['frames']])
page = '''<!doctype html><meta charset="utf-8"><title>Ring Zero motion review</title>
<style>body{background:#060c11;color:#dbe5e7;font:16px system-ui;margin:24px}button{font:inherit;padding:10px;margin:8px;background:#21313b;color:inherit;border:1px solid #78909c}img{width:min(100%,1600px);display:block}p{max-width:900px}</style>
<h1>Motion review</h1><p>Watch each silent trial once at normal speed. Record what changed, where it happened, and how much of the structure was lost. Do not inspect the source files until answers are recorded. No results are submitted automatically.</p>
<button id="play">Play trial 1</button><button id="next">Next trial</button><span id="status"></span><img id="frame" alt="Native game frame">
<script>const trials=DATA;let trial=0,started=0,running=false,last=-1;
const frame=document.getElementById('frame'),status=document.getElementById('status');
function reset(){running=false;last=-1;frame.src=trials[trial][0].file;document.getElementById('play').textContent='Play trial '+(trial+1);status.textContent='';}
document.getElementById('play').onclick=()=>{started=performance.now();running=true;last=-1;requestAnimationFrame(tick)};
document.getElementById('next').onclick=()=>{trial=(trial+1)%trials.length;reset()};
function tick(now){if(!running)return;let elapsed=(now-started)/1000,fs=trials[trial],i=0;while(i+1<fs.length&&fs[i+1].t<=elapsed)i++;if(i!==last){frame.src=fs[i].file;last=i;}status.textContent=elapsed.toFixed(1)+' s';if(elapsed>=fs[fs.length-1].t){running=false;status.textContent+=' — record your answer';return;}requestAnimationFrame(tick)}reset();</script>'''
(root / 'public').mkdir(exist_ok=True)
(root / 'public' / 'index.html').write_text(page.replace('DATA', json.dumps(trials)), encoding='utf-8')

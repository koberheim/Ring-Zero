"""Prepare T-092 monochrome human trial from retained Blender renders.

python scripts/art/t092_silhouette_review.py
Requires Pillow. Does not invoke Blender or Godot or modify shipping assets.
Trial key is deliberately written outside the public trial directory.
"""
import hashlib
import json
import random
import subprocess
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'assets/art/source/presentation-v3-elites'
OUT = ROOT / 'docs/reviews/presentation-v3/T-092'
NAMES = ('tunneler', 'transfer', 'foundry', 'sapper', 'breacher', 'assembler')
DESCRIPTIONS = ('Long drill / cutting axis', 'Open paired launch form', 'Broad anchored processing body', 'Radial reaching probes', 'Solid asymmetric ram wedge', 'Accreted broken-ring hull')
SEED = 920135


def font(size):
    return ImageFont.truetype('C:/Windows/Fonts/arial.ttf', size)


def normalized(path):
    alpha = Image.open(path).convert('RGBA').getchannel('A')
    bounds = alpha.getbbox()
    a = alpha.crop(bounds)
    scale = 16 / max(a.size)
    dims = tuple(max(1, round(v * scale)) for v in a.size)
    a = a.resize(dims, Image.Resampling.LANCZOS).point(lambda v: 255 if v >= 128 else 0)
    canvas = Image.new('L', (16,16), 255)
    origin = ((16-dims[0])//2, (16-dims[1])//2)
    canvas.paste(0, origin, a)
    return canvas, {'source_alpha_bounds':bounds,'resized_content':dims,'offset_in_16px_canvas':origin,'threshold':128}


def write_json(path, value):
    path.write_text(json.dumps(value,indent=2)+'\n',encoding='utf-8')


def main():
    for directory in (OUT,OUT/'public',OUT/'public/reference',OUT/'public/trials',OUT/'reviewer-private',OUT/'before'):
        directory.mkdir(parents=True,exist_ok=True)
    (OUT/'.gdignore').touch()
    (SOURCE/'.gdignore').touch()
    tiles={}
    before_tiles={}
    normalization={}
    for name in NAMES:
        tiles[name],normalization[name]=normalized(SOURCE/(name+'_silhouette.png'))
        tiles[name].save(OUT/'public/reference'/(name+'.png'))
        previous=ROOT/'assets/art/machines'/('assembler.png' if name=='assembler' else 'elite_'+name+'.png')
        tile,_=normalized(previous)
        before_tiles[name]=tile
        tile.save(OUT/'before'/(name+'_16.png'))
    demo=Image.new('RGB',(1200,620),'white')
    d=ImageDraw.Draw(demo)
    d.text((32,20),'T-092 / learn the six silhouette candidates',fill='black',font=font(25))
    d.text((32,58),'Large shapes are 8x nearest-neighbor demonstrations. Small shapes are native 16 px.',fill='black',font=font(17))
    clay=Image.new('RGB',(1200,650),'#edf0f2')
    cd=ImageDraw.Draw(clay)
    cd.text((30,18),'T-092 / Blender depth blockouts - provisional, not detailed art',fill='black',font=font(24))
    for i,name in enumerate(NAMES):
        x=32+(i%3)*395
        y=112+(i//3)*248
        d.text((x,y),name.title(),fill='black',font=font(24))
        demo.paste(tiles[name].resize((128,128),Image.Resampling.NEAREST),(x,y+42))
        demo.paste(tiles[name],(x+188,y+96))
        d.text((x,y+191),DESCRIPTIONS[i],fill='black',font=font(16))
        ci=Image.open(SOURCE/(name+'_clay.png')).convert('RGBA')
        cx=45+(i%3)*395
        cy=56+(i//3)*288
        clay.paste(ci,(cx,cy),ci)
        cd.text((cx,cy+249),name.title(),fill='black',font=font(21))
    demo.save(OUT/'public/reference-demonstration.png')
    clay.save(OUT/'clay-depth-blockouts.png')
    order=[(name,angle) for name in NAMES for angle in (0,180)]
    random.Random(SEED).shuffle(order)
    key=[]
    sheet=Image.new('RGB',(960,620),'white')
    sd=ImageDraw.Draw(sheet)
    sd.text((30,22),'T-092 / twelve monochrome trials',fill='black',font=font(26))
    sd.text((30,62),'16 px at native image size. Use the HTML page for display-scale calibration.',fill='black',font=font(18))
    before_sheet=Image.new('RGB',(960,620),'white')
    bd=ImageDraw.Draw(before_sheet)
    bd.text((30,22),'T-092 / BEFORE - retained shipping asset alpha',fill='black',font=font(26))
    bd.text((30,62),'Matched 16 px normalization / same shuffled order. Diagnostic only.',fill='black',font=font(18))
    for i,(name,angle) in enumerate(order,1):
        tile=tiles[name].rotate(angle)
        tile.save(OUT/'public/trials'/('%02d.png'%i))
        key.append({'trial':i,'class':name,'sprite_rotation_degrees':angle})
        x=42+((i-1)%3)*300
        y=124+((i-1)//3)*117
        sd.text((x,y),'%02d'%i,fill='black',font=font(20))
        sheet.paste(tile,(x+116,y+6))
        bd.text((x,y),'%02d'%i,fill='black',font=font(20))
        before_sheet.paste(before_tiles[name].rotate(angle),(x+116,y+6))
    sheet.save(OUT/'public/trials-unlabeled-16px.png')
    before_sheet.save(OUT/'before/trials-unlabeled-16px.png')
    write_json(OUT/'reviewer-private/answer-key.json',{'seed':SEED,'answers':key,'gate':'At least 11/12 correct, no recurrent Tunneler/Transfer/Breacher confusion; human result required.'})
    trial_markup='\n'.join('<label class="trial"><b>%02d</b><img class="native" src="trials/%02d.png" alt="Trial %02d silhouette"><input data-trial="%02d" aria-label="Answer %02d" placeholder="Class name" autocomplete="off"></label>'%(i,i,i,i,i) for i in range(1,13))
    reference_markup='\n'.join('<figure><figcaption>%s</figcaption><img class="demo" src="reference/%s.png" alt="%s enlarged reference"><img class="native" src="reference/%s.png" alt="%s native reference"><p>%s</p></figure>'%(name.title(),name,name,name,name,desc) for name,desc in zip(NAMES,DESCRIPTIONS))
    html='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>T-092 silhouette trial</title>
<style>body{margin:32px;font:18px Arial,sans-serif;background:white;color:black;max-width:1100px}h1{font-size:28px}button,input{font:inherit;padding:10px}button{cursor:pointer}small{display:block;margin:14px 0}#reference{display:grid;grid-template-columns:repeat(3,1fr)}figure{margin:20px 8px;min-height:190px}figcaption{font-size:23px;margin-bottom:18px}.demo{width:96px;height:96px;image-rendering:pixelated;vertical-align:middle;margin-right:45px}.native{image-rendering:pixelated;object-fit:contain;flex:none}.trial{display:flex;align-items:center;gap:35px;padding:24px 0}.trial b{width:30px}.trial input{width:190px}#trials{display:grid;grid-template-columns:repeat(2,1fr)}#trial-section[hidden],#reference[hidden]{display:none}textarea{width:100%;height:220px;font:16px monospace}.note{line-height:1.5}p{line-height:1.4}</style>
<h1>T-092: six silhouette candidates</h1><p class="note">First learn the six classes below. Large reference images are enlarged demonstrations; their small neighbors are 16 physical pixels. When ready, hide the reference and identify all twelve numbered shapes. Enter one class name for each. Do not zoom, magnify, open the reference again, or view the private answer key during the trial.</p><p id="scale"></p><div id="reference">REF</div><button id="begin">Hide reference and begin twelve trials</button><section id="trial-section" hidden><p>Available names: Tunneler, Transfer, Foundry, Sapper, Breacher, Assembler.</p><div id="trials">TRIALS</div><p><label>Reviewer name <input id="reviewer" autocomplete="name"></label></p><p><label><input type="checkbox" id="confirmed"> I viewed each trial at the calibrated 16 physical pixels, without magnification or the reference/key.</label></p><button id="export">Prepare my answers</button><p>Copy the result below back to Astra/Kevin. This page contains no answer key and does not score itself.</p><textarea id="result" readonly></textarea></section><small>Provisional Blender blockouts. Human silhouette gate only; this is not gameplay/crowd/performance evidence.</small>
<script>let startScale=null,scaleChanged=false;function calibrate(){const r=devicePixelRatio||1;document.querySelectorAll('.native').forEach(i=>{i.style.width=(16/r)+'px';i.style.height=(16/r)+'px'});document.getElementById('scale').textContent='Display calibration: '+r+' device pixels per CSS pixel. Each small shape spans 16 physical pixels.';if(startScale!==null&&r!==startScale)scaleChanged=true}calibrate();addEventListener('resize',calibrate);document.getElementById('begin').onclick=()=>{startScale=devicePixelRatio||1;document.getElementById('reference').hidden=true;document.getElementById('begin').hidden=true;document.getElementById('trial-section').hidden=false};document.getElementById('export').onclick=()=>{let a=[...document.querySelectorAll('[data-trial]')].map(i=>({trial:Number(i.dataset.trial),answer:i.value.trim()}));if(a.some(i=>!i.answer)){alert('Please answer all twelve trials before preparing the result.');return}let result={task:'T-092',candidate:'v1',reviewer:document.getElementById('reviewer').value.trim(),timestamp:new Date().toISOString(),devicePixelRatio:devicePixelRatio||1,screen:[screen.width,screen.height],viewport:[innerWidth,innerHeight],scaleChanged,confirmed16px:document.getElementById('confirmed').checked,answers:a};document.getElementById('result').value=JSON.stringify(result,null,2)};</script></html>'''
    (OUT/'public/index.html').write_text(html.replace('REF',reference_markup).replace('TRIALS',trial_markup),encoding='utf-8')
    commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
    metadata={'task':'T-092','candidate':'v1','status':'HUMAN GATE PENDING - no detailed production authorized by this package','source_commit':commit,'recovery_base':'a42b7a8fb7cf85cae7f6385b1f0f0a24d310c037 plus recovered T-086 changes (disjoint)','renderer':'Blender 5.2.1 LTS / Workbench','camera':{'orthographic':True,'tilt_from_vertical_degrees':20,'position':[0,-3.420201433,9.396926208],'orthographic_scale':4.1,'object_forward':'+Y','pivot_xyz':[0,0,0]},'source_resolution':[256,256],'trial_canvas_physical_pixels':[16,16],'palette':'strict binary black and white from rendered alpha, 128 threshold after Lanczos reduction','ui_scale':'HTML compensates devicePixelRatio; reviewer must attest no magnification','zoom':'isolated diagnostic; no game camera','simulation_tick':None,'active_actor_count':0,'seed_location':'reviewer-private/answer-key.json','normalization':normalization,'orientation_scope':'two exact 2D sprite rotations per class (0 and 180 degrees); twelve-bearing live acceptance remains pending','original_blender_scene':{'name':'Scene','file':'Untitled','objects':['Cube','Light','Camera'],'preserved':True,'lease_released':True},'shipping_outputs':None,'normal_emission_animation':'not generated; waits for human gate','physical_floors_provisional':{'elites':16,'assembler':28,'human_trial_all_classes':16},'limitations':['No human answers yet','No runtime, crowd, star palette, live bearing, normal or motion acceptance claimed','Clay sheet is blockout geometry only','Normalized review tiles are not shipping atlas/pivot metadata']}
    write_json(OUT/'fixture-metadata.json',metadata)
    metadata['gpu']=None
    metadata['driver']=None
    metadata['hardware_inspection']='Get-CimInstance Win32_VideoController denied by local access policy; no escalation needed for an isolated silhouette diagnostic. Hardware comparison/performance is not claimed.'
    write_json(OUT/'fixture-metadata.json',metadata)
    checks=[]
    for i in range(1,13):
        im=Image.open(OUT/'public/trials'/('%02d.png'%i))
        assert im.size==(16,16)
        assert set(im.tobytes())=={0,255}
        checks.append({'trial':i,'dimensions':[16,16],'binary_black_white':True})
    assert sorted(a['class'] for a in key)==sorted(list(NAMES)*2)
    write_json(OUT/'artifact-checks.json',{'result':'PASS artifact integrity only; human identification untested','twelve_trials':checks,'class_count':6,'occurrences_each':2,'source_files_present':all((SOURCE/(n+'_silhouette.png')).exists() for n in NAMES)})
    manifest={}
    for p in sorted([*OUT.rglob('*'),*SOURCE.rglob('*'),ROOT/'scripts/art/t092_silhouettes_blender.py',ROOT/'scripts/art/t092_silhouette_review.py',ROOT/'docs/art-prompts/presentation-v3-elites.md']):
        if p.is_file() and p.name!='manifest-sha256.json':
            manifest[p.relative_to(ROOT).as_posix()]=hashlib.sha256(p.read_bytes()).hexdigest()
    write_json(OUT/'manifest-sha256.json',manifest)
    print('T-092 review package ready; twelve binary 16px tiles verified. HUMAN GATE PENDING.')


if __name__=='__main__':
    main()

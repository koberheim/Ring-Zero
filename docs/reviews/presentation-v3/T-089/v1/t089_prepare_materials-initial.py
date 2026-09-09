"""Package original modeled T089 maps and explicit periodic geometric surfaces.
No original art is read/painted over. Analytic normals derive from authored
height surfaces, never image luminance. Source and native gates are separate.
"""
import hashlib
import json
import math
import runpy
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'assets/art/source/presentation-v3-fortress/v1'
DEST=ROOT/'assets/art/materials/presentation_v3'
REVIEW=ROOT/'docs/reviews/presentation-v3/T-089/v1'
KINDS=('flak','emp_node','lance_emitter','point_defense','relay','repair_node','armor_plating','wall','debris_field','tractor_lane','occlusion_screen')
SHARED=runpy.run_path(str(ROOT/'scripts/art/t092_production_review.py'))
SHARED['prepare'].__globals__['SOURCE']=SOURCE


def write_json(path,value):path.write_text(json.dumps(value,indent=2)+'\n',encoding='utf-8')
def rgba(rgb,a):return Image.fromarray(np.dstack((np.rint(np.clip(rgb,0,1)*255).astype('uint8'),np.rint(np.clip(a,0,1)*255).astype('uint8'))))


def bands():
    w,h=512,128
    y,x=np.mgrid[0:h,0:w].astype(float);u=x/(w-1);v=y/(h-1)
    # Periodic welded deck panels, raised edge rails and geometric seam recesses.
    seam=np.exp(-((np.sin(u*math.tau*4))/.095)**2)
    edge=np.exp(-((v-.07)/.028)**2)+np.exp(-((v-.93)/.028)**2)
    z=.035*edge-.018*seam+.006*np.cos(u*math.tau*16)*np.exp(-((v-.5)/.25)**2)
    dy,dx=np.gradient(z,1/(h-1),1/(w-1))
    # Repeated tangent is eight times radial span; keep normals world-proportional.
    n=np.dstack((-dx/8,-dy,np.ones_like(x)));n/=np.linalg.norm(n,axis=2,keepdims=True)
    scratches=np.maximum(0,np.sin(u*math.tau*19+v*17))**45*.018
    result={}
    for tier,base in {'hot':(.25,.175,.095),'working':(.30,.31,.29),'cold':(.36,.42,.43)}.items():
        rgb=np.ones((h,w,3))*base
        rgb*=((1-.30*seam+.14*edge-scratches)[:,:,None])
        # Narrow paint/weld edge lines come from the same surface geometry.
        rgb+=edge[:,:,None]*np.array((.035,.026,.01))
        a=np.ones_like(x)
        maps={'albedo':rgba(rgb,a),'normal':rgba((n+1)/2,a),'emission':rgba(np.zeros_like(rgb),a)}
        for channel,im in maps.items():
            arr=np.asarray(im).copy();arr[:,-1]=arr[:,0]
            im=Image.fromarray(arr);im.save(DEST/f'band_{tier}_{channel}.png')
        result[tier]={'albedo':f'res://assets/art/materials/presentation_v3/band_{tier}_albedo.png','normal':f'res://assets/art/materials/presentation_v3/band_{tier}_normal.png','emission':f'res://assets/art/materials/presentation_v3/band_{tier}_emission.png','size':[w,h],'repeat_x':True,'edge_rgba_max_error':0,'normal_source':'explicit analytic deck height; periodic recesses and raised edge rails'}
    return result


def damage():
    # Six substrate-free surface marks. Coverage is the mark, never a plate.
    size=128;y,x=np.mgrid[-1:1:complex(size),-1:1:complex(size)];r=np.sqrt(x*x+y*y)
    motifs={
        'scorch':np.exp(-(r/.51)**3)*.64,
        'pits':sum(np.exp(-(((x-cx)**2+(y-cy)**2)/.009)) for cx,cy in ((-.35,-.2),(.2,-.1),(-.08,.3))),
        'crack':np.exp(-((x-.20*np.sin(y*9))/.024)**2)*np.exp(-(y/.67)**6),
        'weld':np.exp(-(y/.045)**2)*np.exp(-(x/.64)**8)*(.50+.50*np.cos(x*49)**2),
        'scrape':np.exp(-((y-.3*x)/.05)**2)*np.exp(-(x/.65)**6),
        'edge_spall':np.exp(-(((r-.36)/.04)**2))*np.clip(.2+.7*np.sin(np.arctan2(y,x)*5),0,1)}
    atlas={k:Image.new('RGBA',(size*3,size*2)) for k in ('albedo','normal','emission')}
    entries=[]
    for i,(name,coverage) in enumerate(motifs.items()):
        coverage=np.clip(coverage,0,1);coverage[coverage<.012]=0
        height=-coverage*.008 if name in ('pits','crack','edge_spall') else coverage*.003
        dy,dx=np.gradient(height,2/(size-1),2/(size-1));n=np.dstack((-dx,-dy,np.ones_like(x)));n/=np.linalg.norm(n,axis=2,keepdims=True)
        color=(.055,.065,.07) if name!='weld' else (.39,.36,.27)
        rgb=np.ones((size,size,3))*color
        maps={'albedo':rgba(rgb,coverage),'normal':rgba((n+1)/2,coverage),'emission':rgba(np.zeros_like(rgb),coverage)}
        for channel,im in maps.items():atlas[channel].paste(im,((i%3)*size,(i//3)*size))
        entries.append({'name':name,'rect':[(i%3)*size,(i//3)*size,size,size]})
    for channel,im in atlas.items():im.save(DEST/f'damage_{channel}.png')
    return {'frames':entries,'albedo':'res://assets/art/materials/presentation_v3/damage_albedo.png','normal':'res://assets/art/materials/presentation_v3/damage_normal.png','emission':'res://assets/art/materials/presentation_v3/damage_emission.png','substrate':'none; transparent marks only','normal_source':'explicit analytic pit/crack/weld relief'}


def main():
    for path in (DEST,REVIEW):path.mkdir(parents=True,exist_ok=True)
    (REVIEW/'.gdignore').touch()
    metadata={'schema':'ring-zero-fortress-art/1','status':'PROVISIONAL SOURCE ART; native all-bearing/state/palette and human gates pending','source_blend':'res://assets/art/source/presentation-v3-fortress/v1/t089_fortress_v1.blend','camera':{'tilt_from_vertical':20,'pivot':[0,0,0],'forward':'+Y model = outward at north','bearing_frames':12,'bearing_formula':'round(clockwise_turns*12)%12','important':'Each frame rotates actual 3D geometry under fixed camera. Select frame and draw screen-aligned; do not rotate baked height again. Cancel parent ground Y squash for already-projected artwork.'},'channels':{'albedo':'unlit material color, sRGB straight RGBA','normal':'modeled or explicit analytic geometry, camera-right/image-down/viewer RGB; linear data. T081 static material-cache convention; NO additional green inversion','emission':'linear data; source lamp colors only; runtime must gate by actual power/health','alpha':'all map channels share coverage; no baked lights in albedo'},'classes':{}}
    report={'status':'source integrity only','classes':{}}
    font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',19)
    sheet=Image.new('RGB',(1280,880),'#101820');draw=ImageDraw.Draw(sheet)
    draw.text((20,15),'T089 modeled structural repairs / Blender beauty source, not native game evidence',font=font,fill='white')
    for index,k in enumerate(KINDS):
        size=128;atlases={c:Image.new('RGBA' if c!='alpha' else 'L',(size*4,size*3)) for c in ('albedo','normal','emission','alpha')}
        bounds=[];unique=set();max_error=0
        contact=Image.new('RGB',(1024,820),'#101820');cd=ImageDraw.Draw(contact)
        cd.text((16,14),f'{k} / actual geometry bearings, fixed20 degree camera / SOURCE ONLY',font=font,fill='white')
        for frame in range(12):
            prepared=SHARED['prepare'](k,frame,size)
            for channel,im in prepared.items():atlases[channel].paste(im,((frame%4)*size,(frame//4)*size))
            a=np.asarray(prepared['alpha']);bound=prepared['alpha'].getbbox();assert bound and min(bound[:2])>=2 and max(bound[2:])<=126,(k,frame,'clipped')
            bounds.append(list(bound));unique.add(hashlib.sha256(prepared['albedo'].tobytes()).hexdigest())
            n=np.asarray(prepared['normal'])[:,:,:3]/127.5-1
            max_error=max(max_error,float(np.max(np.abs(np.linalg.norm(n[a>128],axis=1)-1))))
            beauty=Image.open(SOURCE/'renders'/k/f'beauty_{frame:02d}.png').convert('RGBA')
            contact.paste(beauty,((frame%4)*256,40+(frame//4)*256),beauty)
            cd.text(((frame%4)*256+10,45+(frame//4)*256),str(frame*30)+'deg',font=font,fill='#acbbc5')
        assert max_error<.009,(k,'normal length',max_error)
        for channel,im in atlases.items():im.save(DEST/f'{k}_{channel}.png')
        contact.save(REVIEW/f'{k}-bearings.png')
        beauty=Image.open(SOURCE/'renders'/k/'beauty_00.png').convert('RGBA')
        pos=((index%4)*320,80+(index//4)*256);sheet.paste(beauty,(pos[0]+32,pos[1]),beauty);draw.text((pos[0]+16,pos[1]-8),k,font=font,fill='#ded6bd')
        metadata['classes'][k]={c:f'res://assets/art/materials/presentation_v3/{k}_{c}.png' for c in ('albedo','normal','emission','alpha')}
        metadata['classes'][k].update(frame_size=[128,128],atlas_size=[512,384],frame_count=12,layout=[4,3],pivot_pixels=[64,64],frame_rects=[[(f%4)*128,(f//4)*128,128,128] for f in range(12)],alpha_bounds=bounds,world_canvas_size=62 if k not in ('relay','wall','debris_field','tractor_lane','occlusion_screen') else (44 if k=='relay' else (48 if k=='wall' else 58)),mount='existing shared mount' if k in ('flak','emp_node','lance_emitter','point_defense','repair_node') else 'ground pivot / no raised shared mount')
        report['classes'][k]={'frames':12,'unique_decoded_albedo_frames':len(unique),'normal_max_length_error':max_error,'aligned_coverage':True,'border_clear':True}
    metadata['bands']=bands();metadata['damage']=damage()
    sheet.save(REVIEW/'source-lineup.png')
    write_json(DEST/'metadata.json',metadata);write_json(REVIEW/'integrity.json',report)
    manifest={}
    for path in sorted([*SOURCE.rglob('*'),*DEST.rglob('*'),*REVIEW.rglob('*'),ROOT/'scripts/art/t089_fortress_blender.py',Path(__file__)]):
        if path.is_file() and path.name!='manifest-sha256.json':manifest[path.relative_to(ROOT).as_posix()]=hashlib.sha256(path.read_bytes()).hexdigest()
    write_json(REVIEW/'manifest-sha256.json',manifest)
    print(json.dumps({'result':'source integrity pass; native gates pending','classes':len(KINDS),'artifacts':len(manifest)}))


if __name__=='__main__':main()

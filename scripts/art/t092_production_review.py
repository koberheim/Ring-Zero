"""Build aligned v2 animation/map atlases and diagnostic review without Godot/GPU.

python scripts/art/t092_production_review.py
Dependencies: Pillow, NumPy. Retains v1 untouched. Human gates remain untested.
"""
import hashlib
import json
import math
import random
import subprocess
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'assets/art/source/presentation-v3-elites/v2'
ASSETS=ROOT/'assets/art/machines/presentation_v3_v2'
REVIEW=ROOT/'docs/reviews/presentation-v3/T-092/v2'
KINDS=('tunneler','transfer','foundry','sapper','breacher','assembler')
PERIODS={'tunneler':.8,'transfer':1.0,'foundry':1.2,'sapper':1.6,'breacher':.8,'assembler':2.0}
EXTENTS={'tunneler':3.65,'transfer':3.65,'foundry':3.75,'sapper':3.85,'breacher':3.65,'assembler':4.65}
MOTIONS={'tunneler':'drill rotation','transfer':'launch rail compression','foundry':'processing jaw','sapper':'radial probe reach','breacher':'ram recoil','assembler':'accretion feeding clamps'}


def write_json(path,obj):path.write_text(json.dumps(obj,indent=2)+'\n',encoding='utf-8')
def font(n):return ImageFont.truetype('C:/Windows/Fonts/arial.ttf',n)
def srgb_decode(x):return np.where(x<=.04045,x/12.92,((x+.055)/1.055)**2.4)
def srgb_encode(x):return np.where(x<=.0031308,12.92*x,1.055*np.maximum(x,0)**(1/2.4)-.055)


def resize_float(a,size):
    # Exact2x BOX reduction avoids negative-lobe RGB/coverage ringing at alpha edges.
    return np.array(Image.fromarray(a.astype('float32')).resize((size,size),Image.Resampling.BOX))


def edge_dilate(rgb,alpha,steps=4):
    """Propagate existing edge colors into transparent texels, alpha unchanged."""
    rgb=rgb.copy();known=alpha>0
    for _ in range(steps):
        old=known.copy();before=rgb.copy()
        for dy,dx in ((-1,0),(1,0),(0,-1),(0,1),(-1,-1),(-1,1),(1,-1),(1,1)):
            valid=np.roll(old,(dy,dx),(0,1))
            if dy<0:valid[dy:,:]=False
            if dy>0:valid[:dy,:]=False
            if dx<0:valid[:,dx:]=False
            if dx>0:valid[:,:dx]=False
            take=valid&~known
            shifted=np.roll(before,(dy,dx),(0,1))
            rgb[take]=shifted[take];known[take]=True
    return rgb


def normalized16(alpha):
    a=Image.fromarray(alpha)
    crop=a.crop(a.getbbox())
    scale=16/max(crop.size)
    dims=tuple(max(1,round(v*scale)) for v in crop.size)
    small=crop.resize(dims,Image.Resampling.LANCZOS).point(lambda p:255 if p>=128 else 0)
    tile=Image.new('L',(16,16),255);tile.paste(0,((16-dims[0])//2,(16-dims[1])//2),small)
    return tile


def prepare(kind,frame,size):
    raw={channel:np.asarray(Image.open(SOURCE/'renders'/kind/('%s_%02d.png'%(channel,frame))).convert('RGBA')).astype('float32')/255 for channel in ('albedo','normal','emission')}
    a=raw['albedo'][:,:,3]
    assert all(np.array_equal(raw[k][:,:,3],a) for k in ('normal','emission')),'Source map alpha mismatch'
    alpha=np.clip(resize_float(a,size),0,1)
    frames={}
    for channel,data in raw.items():
        rgb=data[:,:,:3]
        if channel=='albedo':rgb=srgb_decode(rgb)
        elif channel=='normal':rgb=rgb*2-1
        premul=rgb*a[:,:,None]
        reduced=np.stack([resize_float(premul[:,:,i],size) for i in range(3)],axis=-1)
        reduced=np.divide(reduced,alpha[:,:,None],out=np.zeros_like(reduced),where=alpha[:,:,None]>.00001)
        if channel=='normal':
            norm=np.linalg.norm(reduced,axis=-1,keepdims=True)
            reduced=np.divide(reduced,norm,out=np.zeros_like(reduced),where=norm>.00001)
            reduced=(reduced+1)/2
            reduced[alpha==0]=(.5,.5,1)
        elif channel=='albedo':reduced=srgb_encode(np.clip(reduced,0,1))
        rgb8=np.rint(np.clip(reduced,0,1)*255).astype('uint8')
        alpha8=np.rint(alpha*255).astype('uint8')
        rgb8=edge_dilate(rgb8,alpha8)
        frames[channel]=Image.fromarray(np.dstack((rgb8,alpha8)))
    frames['alpha']=Image.fromarray(alpha8)
    return frames


def diagnostic_lit(albedo,normal,emission,light):
    """Offline Lambert check of map orientation; never gameplay evidence."""
    a=np.asarray(albedo).astype('float32')/255;n=np.asarray(normal).astype('float32')[:,:,:3]/127.5-1;e=np.asarray(emission).astype('float32')[:,:,:3]/255
    direction=np.array((-.40,.48,.78));direction/=np.linalg.norm(direction)
    lambert=np.maximum(np.sum(n*direction,axis=-1),0)
    rgb=srgb_decode(a[:,:,:3])*(.28+lambert[:,:,None]*np.array(light)*.95)+e*.65
    rgb=np.rint(np.clip(srgb_encode(rgb),0,1)*255).astype('uint8')
    return Image.fromarray(np.dstack((rgb,np.asarray(albedo)[:,:,3])))


def main():
    for p in (ASSETS,REVIEW,REVIEW/'public',REVIEW/'public/reference',REVIEW/'public/trials',REVIEW/'reviewer-private',REVIEW/'motion'):p.mkdir(parents=True,exist_ok=True)
    (REVIEW/'.gdignore').touch()
    metadata={'schema':'ring-zero-elite-art/2','status':'PROVISIONAL - human recognition and native acceptance pending','source_commit':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'production_base':'ff1de6d','source_blend':'res://assets/art/source/presentation-v3-elites/v2/t092_industrial_elites_v2r1.blend','renderer':'Blender 5.2.1 LTS / Cycles CPU; maps 8 samples, beauty16 samples + denoising','map_conventions':{'albedo':'sRGB straight RGBA, unlit material colors, no baked lights or glow','normal':'linear-data RGBA; RGB = (camera-right X, camera-up Y, viewer-positive Z)*0.5+0.5; neutral (128,128,255); model Geometry Normal transformed WORLD->CAMERA with explicit Z inversion','emission':'linear RGB cold color/mask, same straight alpha, no baked glow; intensity supplied by runtime','alpha':'8-bit grayscale coverage; RGBA map alpha matches this mask','filtering':'albedo reduced in linear light with alpha weighting; normals alpha-weighted then renormalized; emission linear; RGB extended4px beyond coverage without changing alpha','import':'lossless, mipmaps on, repeat disabled; normal is data/no sRGB; no green inversion in export; use NORMAL_MAP conversion or adapter green flip exactly once if required by Godot 2D path'},'camera':{'tilt_degrees_from_vertical':20,'side':'camera on negative Y','ground_plane':'XY','height_axis':'+Z','forward':'+Y projects up in frame','pivot_source_xyz':[0,0,0],'pivot_uv':[.5,.5],'note':'already20deg projected; preserve source pivot and validate any parent squash in live all-bearing seating'},'runtime_usage':{'frame_formula':'frame = floor(presentation_phase_seconds / period_seconds * 8) % 8; event-gate mechanisms using existing state/events; reduced motion freezes frame0','mechanism_scope':'Local mechanical presentation only; compression/reach/recoil do not move simulation actors or invent attacks/hops/growth. Assembler hull growth remains driven by real state outside this loop.','bearing':'Frame points up. Current release uses point.angle()-PI/2 to make up-pointing sprite face inward; E must preserve authoritative heading. Rotate normal XY consistently with sprite.','floor_formula':'canvas_world_size = max(world_canvas_size, physical_floor_px / (world_to_physical_pixel_scale * min_occupied_extent_fraction)); physical scale includes viewport/window scale. Physical_floor refers to occupied silhouette extent, not full transparent canvas.','acceptance':'Human, native all-bearing/palette/crowd/performance gates are still pending.'},'classes':{}}
    checks={'status':'artifact integrity only; not human or native gate','classes':{},'normal_calibration':{'probe':'tunneler raw normal frame0 pixel(128,128), known horizontal roof','expected_rgb_approx':[128,171,247],'actual_rgba':list(Image.open(SOURCE/'renders/tunneler/normal_00.png').getpixel((128,128)))}}
    tiles={};all_prepared={}
    contact=Image.new('RGB',(1020,700),'#101820');cd=ImageDraw.Draw(contact)
    cd.text((22,16),'T-092 v2 / provisional industrial models',font=font(28),fill='white')
    cd.text((22,55),'Blender beauty reference only. Actual maps remain unlit; human gate pending.',font=font(17),fill='#acbbc5')
    material_sheet=Image.new('RGB',(1100,1480),'#101820');md=ImageDraw.Draw(material_sheet)
    md.text((22,16),'Aligned maps / albedo - true normal - emission - alpha',font=font(26),fill='white')
    palette_sheet=Image.new('RGB',(1200,660),'#101820');pd=ImageDraw.Draw(palette_sheet)
    pd.text((22,16),'Offline material diagnostic / yellow - white - red key light',font=font(24),fill='white')
    pd.text((22,50),'Map orientation/color check. Not star-palette gameplay acceptance.',font=font(17),fill='#acbbc5')
    bearing_sheet=Image.new('RGB',(1280,730),'#101820');bd=ImageDraw.Draw(bearing_sheet)
    bd.text((20,15),'Twelve sprite bearings / offline diagnostic, not live seating acceptance',font=font(24),fill='white')
    for ci,kind in enumerate(KINDS):
        size=256 if kind=='assembler' else 128
        maps={c:Image.new('RGBA' if c!='alpha' else 'L',(size*4,size*2)) for c in ('albedo','normal','emission','alpha')}
        content=[];min_fraction=1.;normal_lengths=[];blue_min=1.;animated=[];unique=set();edge_checks=[];all_prepared[kind]=[]
        strip=Image.new('RGB',(256*8,300),'#101820');sd=ImageDraw.Draw(strip)
        for f in range(8):
            prepared=prepare(kind,f,size);all_prepared[kind].append(prepared)
            for channel,im in prepared.items():maps[channel].paste(im,((f%4)*size,(f//4)*size))
            alpha=np.asarray(prepared['alpha']);bounds=prepared['alpha'].getbbox();content.append(list(bounds))
            assert bounds[0]>=2 and bounds[1]>=2 and bounds[2]<=size-2 and bounds[3]<=size-2,'Frame touches border'
            normals=np.asarray(prepared['normal'])[:,:,:3]/127.5-1
            coverage=alpha>0
            outside=~coverage&(np.roll(coverage,1,0)|np.roll(coverage,-1,0)|np.roll(coverage,1,1)|np.roll(coverage,-1,1))
            edge_checks.append(bool(np.all(np.asarray(prepared['albedo'])[:,:,:3][outside].sum(axis=-1)>0)))
            assert edge_checks[-1],'Black RGB immediately outside albedo coverage'
            opaque=alpha>=250
            normal_lengths.extend(np.linalg.norm(normals[opaque],axis=-1).tolist());blue_min=min(blue_min,float(normals[:,:,2][opaque].min()))
            for bearing in range(12):
                mask=prepared['alpha'].rotate(bearing*30,resample=Image.Resampling.BILINEAR)
                b=mask.point(lambda p:255 if p>=128 else 0).getbbox()
                min_fraction=min(min_fraction,max(b[2]-b[0],b[3]-b[1])/size)
            b=Image.open(SOURCE/'renders'/kind/('beauty_%02d.png'%f)).convert('RGBA')
            rgb=Image.new('RGB',(256,256),'#101820');rgb.paste(b,(0,0),b)
            animated.append(rgb);unique.add(hashlib.sha256(b.tobytes()).hexdigest())
            strip.paste(rgb,(f*256,25));sd.text((f*256+8,277),'%d / %.3fs'%(f,f*PERIODS[kind]/8),font=font(15),fill='white')
        for channel,im in maps.items():im.save(ASSETS/('%s_%s.png'%(kind,channel)))
        # Native source frame sequence retained; GIF is convenient playback evidence.
        animated[0].save(REVIEW/'motion'/(kind+'.gif'),save_all=True,append_images=animated[1:],duration=round(PERIODS[kind]*1000/8),loop=0,disposal=2)
        strip.save(REVIEW/'motion'/(kind+'-frames.png'))
        x=20+(ci%3)*337;y=110+(ci//3)*292
        contact.paste(animated[0],(x,y));cd.text((x,y+258),kind.title()+' / '+MOTIONS[kind],font=font(16),fill='white')
        first=all_prepared[kind][0]
        tiles[kind]=normalized16(np.asarray(first['alpha']));tiles[kind].save(REVIEW/'public/reference'/(kind+'.png'))
        for column,channel in enumerate(('albedo','normal','emission','alpha')):
            preview=first[channel].convert('RGBA').resize((192,192),Image.Resampling.NEAREST)
            xx=25+column*270;yy=75+ci*230
            if channel=='alpha':material_sheet.paste(preview,(xx,yy))
            else:material_sheet.paste(preview,(xx,yy),preview)
            md.text((xx,yy+198),kind+' / '+channel,font=font(17),fill='white')
        for pi,color in enumerate(((1,.73,.39),(1,1,1),(1,.28,.12))):
            relit=diagnostic_lit(first['albedo'],first['normal'],first['emission'],color).resize((128,128),Image.Resampling.LANCZOS)
            px=20+pi*395+(ci%3)*127;py=105+(ci//3)*225
            palette_sheet.paste(relit,(px,py),relit);pd.text((px,py+136),kind,font=font(16),fill='white')
        for bearing in range(12):
            thumb=animated[0].convert('RGBA').resize((88,88),Image.Resampling.LANCZOS).rotate(-bearing*30)
            bx=20+bearing*104;by=80+ci*102
            bearing_sheet.paste(thumb,(bx,by));bd.text((bx,by+85),str(bearing+1),font=font(13),fill='#acbbc5')
        desc={'albedo':'res://assets/art/machines/presentation_v3_v2/'+kind+'_albedo.png','normal':'res://assets/art/machines/presentation_v3_v2/'+kind+'_normal.png','emission':'res://assets/art/machines/presentation_v3_v2/'+kind+'_emission.png','alpha':'res://assets/art/machines/presentation_v3_v2/'+kind+'_alpha.png','frame_size':[size,size],'atlas_size':[size*4,size*2],'layout':[4,2],'frame_count':8,'pivot_pixels':[size/2,size/2],'frame_rects':[[f%4*size,f//4*size,size,size] for f in range(8)],'content_bounds_by_frame':content,'world_canvas_size':34 if kind=='assembler' else (21 if kind=='foundry' else 15),'physical_floor_px':28 if kind=='assembler' else 16,'min_occupied_extent_fraction':min_fraction,'source_orthographic_extent_units':EXTENTS[kind],'period_seconds':PERIODS[kind],'frame_timestamps_seconds':[round(f*PERIODS[kind]/8,5) for f in range(8)],'motion':MOTIONS[kind]}
        metadata['classes'][kind]=desc
        desc['projected_visible_extent_world_units_by_frame']=[[round((b[2]-b[0])*desc['world_canvas_size']/size,5),round((b[3]-b[1])*desc['world_canvas_size']/size,5)] for b in content]
        desc['footprint_note']='Projected artwork extent, not a collision/rule footprint. Ground pivot is center; do not use this metadata to change simulation geometry.'
        checks['classes'][kind]={'frames':8,'unique_beauty_frames':len(unique),'map_alpha_identical':True,'frame_border_clear':True,'no_black_albedo_rgb_at_transparent_edge':all(edge_checks),'normal_unit_length_max_error':max(abs(v-1) for v in normal_lengths),'min_viewer_normal_z_opaque':blue_min,'min_occupied_extent_fraction':min_fraction,'pivot_fixed_pixels':desc['pivot_pixels']}
        assert len(unique)>=3,'Mechanism did not animate'
        assert checks['classes'][kind]['normal_unit_length_max_error']<.014,'Normal encoding not unit length'
        assert blue_min>=-.08,'Opaque front-facing normals point away from viewer'
    contact.save(REVIEW/'industrial-models.png');material_sheet.save(REVIEW/'material-channels.png');palette_sheet.save(REVIEW/'palette-material-diagnostic.png');bearing_sheet.save(REVIEW/'twelve-bearings-diagnostic.png')
    write_json(ASSETS/'metadata.json',metadata);write_json(REVIEW/'artifact-checks.json',checks)
    demo=Image.new('RGB',(1200,600),'white');d=ImageDraw.Draw(demo)
    d.text((25,18),'T-092 v2 / learn six detailed-model silhouettes',font=font(26),fill='black')
    d.text((25,55),'Enlarged 8x reference beside native 16px sample. Human identification untested.',font=font(18),fill='black')
    for i,k in enumerate(KINDS):
        x=25+i%3*395;y=110+i//3*235
        d.text((x,y),k.title(),font=font(23),fill='black');demo.paste(tiles[k].resize((128,128),Image.Resampling.NEAREST),(x,y+38));demo.paste(tiles[k],(x+190,y+98))
    demo.save(REVIEW/'public/reference-demonstration.png')
    order=[(k,a) for k in KINDS for a in (0,180)];random.Random(920136).shuffle(order)
    key=[];trial=Image.new('RGB',(960,620),'white');td=ImageDraw.Draw(trial)
    td.text((25,20),'T-092 v2 / twelve unlabeled 16px trials',font=font(26),fill='black')
    td.text((25,60),'Use index.html for physical-pixel calibration; no magnification.',font=font(18),fill='black')
    for i,(k,a) in enumerate(order,1):
        im=tiles[k].rotate(a);im.save(REVIEW/'public/trials'/('%02d.png'%i));key.append({'trial':i,'class':k,'sprite_rotation_degrees':a})
        x=42+(i-1)%3*300;y=124+(i-1)//3*117;td.text((x,y),'%02d'%i,font=font(20),fill='black');trial.paste(im,(x+116,y+6))
    trial.save(REVIEW/'public/trials-unlabeled-16px.png')
    html=(ROOT/'docs/reviews/presentation-v3/T-092/public/index.html').read_text(encoding='utf-8')
    html=html.replace("candidate:'v1'","candidate:'v2'").replace('T-092: six silhouette candidates','T-092 v2: six detailed-model silhouettes').replace('Provisional Blender blockouts','Provisional detailed Blender models')
    (REVIEW/'public/index.html').write_text(html,encoding='utf-8')
    write_json(REVIEW/'reviewer-private/answer-key.json',{'candidate':'v2','seed':920136,'answers':key,'status':'Human result pending; do not show key before answers.'})
    motion_html='<!doctype html><html lang="en"><meta charset="utf-8"><title>T-092 mechanism review</title><style>body{background:#101820;color:white;font:18px Arial;margin:30px}main{display:grid;grid-template-columns:repeat(3,300px);gap:25px}img{width:256px;height:256px}p{max-width:1000px;line-height:1.5}</style><h1>T-092 / mechanical motion</h1><p>Native256px Blender frames. Local moving parts preserve the ground pivot. Playback periods are provisional and need live reduced-motion/event integration. This is model animation evidence, not gameplay acceptance.</p><main>'
    for k in KINDS:motion_html+='<article><h2>'+k.title()+'</h2><img src="motion/'+k+'.gif" alt="'+MOTIONS[k]+'"><p>'+MOTIONS[k]+' / '+str(PERIODS[k])+'s cycle</p></article>'
    (REVIEW/'motion-review.html').write_text(motion_html+'</main></html>',encoding='utf-8')
    manifest={}
    for p in sorted([*SOURCE.rglob('*'),*ASSETS.rglob('*'),*REVIEW.rglob('*'),ROOT/'scripts/art/t092_production_blender.py',ROOT/'scripts/art/t092_production_review.py']):
        if p.is_file() and p.name!='manifest-sha256.json':manifest[p.relative_to(ROOT).as_posix()]=hashlib.sha256(p.read_bytes()).hexdigest()
    write_json(REVIEW/'manifest-sha256.json',manifest)
    print(json.dumps({'result':'PASS artifact integrity; human/native gates PENDING','classes':6,'frames_per_class':8,'maps_per_class':4,'manifest_files':len(manifest),'metadata':str(ASSETS/'metadata.json')}))


if __name__=='__main__':main()

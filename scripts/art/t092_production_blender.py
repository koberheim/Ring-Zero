"""T-092 provisional v2 industrial models and model-derived map/frame renders.

Only creates T092V2-owned data in an isolated scene. Never saves the active file.
Load definitions per MCP call; build() once; render_frames(kind,start,end); save_source().
Human silhouette recognition remains PENDING; provisional production was explicitly authorized.
"""
import bpy
import json
import math
from pathlib import Path
from mathutils import Vector

ROOT = Path(r'E:\AI Projects\Games\Ring Zero')
OUT = ROOT/'assets/art/source/presentation-v3-elites/v2'
SCENE = 'T092_Production_v2'
KINDS = ('tunneler','transfer','foundry','sapper','breacher','assembler')
PFX = 'T092V2_'
FRAME_COUNT = 8
COLORS = {'tunneler':(.03,.70,.90),'transfer':(.08,.27,1.0),'foundry':(.04,.70,.42),'sapper':(.47,.16,1.0),'breacher':(.60,.88,1.0),'assembler':(.65,.90,1.0)}
EXTENTS = {'tunneler':3.65,'transfer':3.65,'foundry':3.75,'sapper':3.85,'breacher':3.65,'assembler':4.65}
PERIODS = {'tunneler':.8,'transfer':1.0,'foundry':1.2,'sapper':1.6,'breacher':.8,'assembler':2.0}


def material(name, color, metallic=.65, roughness=.42, glow=False):
    m=bpy.data.materials.new(PFX+name)
    m.diffuse_color=(*color,1)
    m['base_rgb']=list(color)
    m['is_emitter']=glow
    m['metallic']=metallic
    m['roughness']=roughness
    m.use_nodes=True
    # New private materials only; no user's materials or node graphs are edited.
    n=m.node_tree.nodes
    n.clear()
    out=n.new('ShaderNodeOutputMaterial');out.name='Output'
    p=n.new('ShaderNodeBsdfPrincipled');p.name='Surface'
    p.inputs['Base Color'].default_value=(*color,1)
    p.inputs['Metallic'].default_value=metallic
    p.inputs['Roughness'].default_value=roughness
    if glow:
        p.inputs['Emission Color'].default_value=(*color,1)
        p.inputs['Emission Strength'].default_value=2.5
    e=n.new('ShaderNodeEmission');e.name='FlatMap'
    e.inputs['Color'].default_value=(*color,1)
    e.inputs['Strength'].default_value=1
    geo=n.new('ShaderNodeNewGeometry');geo.name='TrueGeometryNormal'
    transform=n.new('ShaderNodeVectorTransform');transform.name='WorldToCameraNormal'
    transform.vector_type='NORMAL';transform.convert_from='WORLD';transform.convert_to='CAMERA'
    facing=n.new('ShaderNodeVectorMath');facing.name='CameraZTowardViewer';facing.operation='MULTIPLY'
    facing.inputs[1].default_value=(1,1,-1)
    encode=n.new('ShaderNodeVectorMath');encode.name='EncodeSignedNormal';encode.operation='MULTIPLY_ADD'
    encode.inputs[1].default_value=(.5,.5,.5);encode.inputs[2].default_value=(.5,.5,.5)
    m.node_tree.links.new(geo.outputs['Normal'],transform.inputs[0])
    m.node_tree.links.new(transform.outputs[0],facing.inputs[0])
    m.node_tree.links.new(facing.outputs[0],encode.inputs[0])
    m.node_tree.links.new(p.outputs[0],out.inputs['Surface'])
    return m


def mesh_object(c,name,vertices,faces,mat,bevel=.025,smooth=False,parent=None):
    mesh=bpy.data.meshes.new(PFX+name)
    mesh.from_pydata(vertices,[],faces);mesh.update()
    o=bpy.data.objects.new(PFX+name,mesh);c.objects.link(o)
    if parent:o.parent=parent
    mesh.materials.append(mat)
    if smooth:
        for poly in mesh.polygons:poly.use_smooth=len(poly.vertices)==4
    if bevel:
        b=o.modifiers.new('Machined edge radii','BEVEL');b.width=bevel;b.segments=2
        b.affect='EDGES'
    return o


def prism(c,name,points,h,z,mat,bevel=.025,parent=None):
    n=len(points)
    vertices=[(x,y,z) for x,y in points]+[(x,y,z+h) for x,y in points]
    faces=[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    return mesh_object(c,name,vertices,faces,mat,bevel,parent=parent)


def box(c,name,loc,size,mat,bevel=.025,angle=0,parent=None):
    w,d,h=size;co,si=math.cos(angle),math.sin(angle)
    x,y,z=loc
    points=[(x+a*co-b*si,y+a*si+b*co) for a,b in ((-w/2,-d/2),(w/2,-d/2),(w/2,d/2),(-w/2,d/2))]
    return prism(c,name,points,h,z,mat,bevel,parent)


def cylinder(c,name,loc,radius,length,mat,axis=(0,0,1),radius_top=None,segments=24,parent=None,bevel=.008):
    rt=radius if radius_top is None else radius_top
    verts=[(math.cos(i*math.tau/segments)*r,math.sin(i*math.tau/segments)*r,z) for z,r in ((-length/2,radius),(length/2,rt)) for i in range(segments)]
    faces=[tuple(reversed(range(segments))),tuple(range(segments,2*segments))]+[(i,(i+1)%segments,(i+1)%segments+segments,i+segments) for i in range(segments)]
    o=mesh_object(c,name,verts,faces,mat,bevel,smooth=True,parent=parent)
    o.location=loc;o.rotation_euler=Vector(axis).to_track_quat('Z','Y').to_euler()
    return o


def torus(c,name,loc,major,minor,mat,axis=(0,0,1),parent=None):
    seg,tube=32,6
    verts=[((major+minor*math.cos(j*math.tau/tube))*math.cos(i*math.tau/seg),(major+minor*math.cos(j*math.tau/tube))*math.sin(i*math.tau/seg),minor*math.sin(j*math.tau/tube)) for i in range(seg) for j in range(tube)]
    faces=[(i*tube+j,((i+1)%seg)*tube+j,((i+1)%seg)*tube+(j+1)%tube,i*tube+(j+1)%tube) for i in range(seg) for j in range(tube)]
    o=mesh_object(c,name,verts,faces,mat,0,smooth=True,parent=parent)
    o.location=loc;o.rotation_euler=Vector(axis).to_track_quat('Z','Y').to_euler()
    return o


def rig(c,name,kind,base=(0,0,0)):
    o=bpy.data.objects.new(PFX+name,None);c.objects.link(o);o.location=base
    o['motion_kind']=kind;o['base_location']=list(base)
    return o


def panel(c,name,loc,size,mat,trim,parent=None,angle=0):
    box(c,name,loc,size,mat,.018,angle,parent)
    # Real relief-fasteners retain surface information in exported normals.
    x,y,z=loc;w,d,h=size;co,si=math.cos(angle),math.sin(angle)
    if min(w,d)>.19:
        for j,(a,b) in enumerate(((-w*.34,-d*.34),(w*.34,-d*.34),(-w*.34,d*.34),(w*.34,d*.34))):
            cylinder(c,name+'_rivet%d'%j,(x+a*co-b*si,y+a*si+b*co,z+h+.010),.022,.022,trim,segments=6,parent=parent,bevel=0)


def vents(c,name,loc,count,w,step,mat,parent=None):
    x,y,z=loc
    for i in range(count):box(c,name+str(i),(x,y+i*step,z),(w,step*.43,.025),mat,.004,parent=parent)


def build_class(kind,c,m):
    hull,dark,steel,plate,light=[m[k] for k in ('hull','dark','steel','plate',kind)]
    if kind=='tunneler':
        for i,y in enumerate((-1.13,-.68,-.23)):
            box(c,'tunnel_segment%d'%i,(0,y,.08),(.69,.48,.27),hull,.05)
            panel(c,'tunnel_carapace%d'%i,(0,y,.36),(.57,.37,.075),plate,steel)
            for x in (-.36,.36):
                for j in range(3):box(c,'tunnel_tread_%d_%s_%d'%(i,x,j),(x,y-.14+j*.13,.075),(.12,.10,.12),steel,.01)
        box(c,'tunnel_lit_spine',(0,-.63,.449),(.07,.76,.016),light,.008)
        cylinder(c,'tunnel_drive',(0,.04,.25),.30,.28,dark,axis=(0,1,0))
        rotor=rig(c,'tunnel_rotor','drill',(0,.22,.27))
        cylinder(c,'tunnel_cutting_cone',(0,.48,0),.43,.96,steel,axis=(0,1,0),radius_top=.02,parent=rotor)
        for i in range(5):
            y=.09+i*.18;r=.40-i*.069
            torus(c,'tunnel_cutter_ring%d'%i,(0,y,0),r,.026,dark,axis=(0,1,0),parent=rotor)
            for j in range(5):
                a=j*math.tau/5+i*.48
                box(c,'tunnel_cut_tooth%d_%d'%(i,j),(math.cos(a)*r,y,math.sin(a)*r-.025),(.082,.13,.065),plate,.007,angle=a,parent=rotor)
        torus(c,'tunnel_drive_lamp',(0,.005,.27),.31,.025,light,axis=(0,1,0))
    elif kind=='transfer':
        box(c,'transfer_rear_yoke',(0,-.93,.12),(2.42,.55,.30),hull,.06)
        for x in (-.94,.94):
            r=rig(c,'transfer_rail_%s'%x,'compression',(x,0,0))
            box(c,'transfer_railbed_%s'%x,(0,.10,.20),(.55,2.32,.31),hull,.055,parent=r)
            for i,y in enumerate((-.56,.14,.84)):
                panel(c,'transfer_plating_%s_%d'%(x,i),(0,y,.51),(.44,.60,.075),plate,steel,parent=r)
            box(c,'transfer_inner_track_%s'%x,(-math.copysign(.20,x),.20,.60),(.045,1.75,.03),light,.01,parent=r)
            cylinder(c,'transfer_piston_%s'%x,(0,-.82,.64),.09,.72,steel,axis=(0,1,0),parent=r)
            cylinder(c,'transfer_bell_%s'%x,(0,-1.22,.23),.29,.34,steel,axis=(0,-1,0),radius_top=.34,parent=r)
            cylinder(c,'transfer_throat_%s'%x,(0,-1.397,.23),.245,.01,dark,axis=(0,1,0),parent=r)
            torus(c,'transfer_nozzle_glow_%s'%x,(0,-1.413,.23),.15,.025,light,axis=(0,1,0),parent=r)
        panel(c,'transfer_yoke_plating',(0,-.94,.45),(.93,.39,.055),plate,steel)
        vents(c,'transfer_radiator',(-.15,-1.07,.52),4,.30,.077,dark)
    elif kind=='foundry':
        box(c,'foundry_lower_casting',(0,0,.11),(2.44,1.71,.39),hull,.07)
        box(c,'foundry_press_chamber',(0,-.03,.50),(1.61,1.27,.40),dark,.045)
        panel(c,'foundry_roof',(0,-.20,.90),(1.45,.90,.10),plate,steel)
        vents(c,'foundry_roof_vents',(0,-.51,1.005),7,.70,.105,dark)
        for x in (-1.17,1.17):
            for y in (-.81,.81):
                box(c,'foundry_anchor_%s_%s'%(x,y),(x,y,.02),(.65,.57,.25),steel,.035)
                panel(c,'foundry_foot_%s_%s'%(x,y),(x,y,.27),(.50,.45,.095),plate,dark)
            cylinder(c,'foundry_hydraulic_%s'%x,(x,0,.62),.14,1.36,steel,axis=(0,1,0))
            box(c,'foundry_side_lamp_%s'%x,(x,-.2,.77),(.09,.64,.035),light,.01)
        jaw=rig(c,'foundry_jaw','press')
        box(c,'foundry_moving_jaw',(0,.92,.26),(1.46,.49,.37),steel,.03,parent=jaw)
        for i in range(7):box(c,'foundry_tooth%d'%i,(-.6+i*.20,1.20,.24),(.13,.20,.23),plate,.008,parent=jaw)
        box(c,'foundry_throat_lamp',(0,.68,.70),(1.17,.09,.055),light,.01)
    elif kind=='sapper':
        cylinder(c,'sapper_central_body',(0,0,.20),.56,.35,hull,segments=12)
        cylinder(c,'sapper_upper_crown',(0,0,.49),.43,.24,plate,segments=12)
        torus(c,'sapper_sensor_ring',(0,0,.64),.29,.038,light)
        cylinder(c,'sapper_aperture',(0,0,.65),.17,.035,dark,segments=12)
        for i in range(6):
            a=i*math.tau/6;dx,dy=math.sin(a),math.cos(a)
            p=rig(c,'sapper_probe_rig%d'%i,'probe',(dx*.50,dy*.50,0));p['radial']=[dx,dy]
            box(c,'sapper_probe_arm%d'%i,(dx*.38,dy*.38,.22),(.30,1.08,.17),hull,.024,angle=-a,parent=p)
            cylinder(c,'sapper_probe_hinge%d'%i,(0,0,.28),.19,.18,steel,parent=p)
            panel(c,'sapper_probe_tip%d'%i,(dx*.85,dy*.85,.28),(.31,.31,.065),plate,steel,parent=p,angle=-a)
            box(c,'sapper_lit_probe%d'%i,(dx*.43,dy*.43,.405),(.065,.56,.024),light,.008,angle=-a,parent=p)
            cylinder(c,'sapper_tip_sensor%d'%i,(dx*.89,dy*.89,.37),.074,.035,light,parent=p,segments=12)
    elif kind=='breacher':
        outline=[(-1.17,-1.14),(.80,-1.14),(1.17,.02),(.42,1.42),(-1.17,.41)]
        prism(c,'breacher_cast_body',outline,.45,.08,hull,.045)
        ram=rig(c,'breacher_ram','recoil')
        prism(c,'breacher_armored_prow',[(-1.10,.13),(.39,1.39),(1.13,.015),(.62,-.40)],.19,.54,steel,.025,parent=ram)
        prism(c,'breacher_top_plate',[(-.99,.13),(.39,1.18),(.94,.035),(.55,-.27)],.06,.735,plate,.014,parent=ram)
        panel(c,'breacher_offset_shoulder',(-.88,-.59,.53),(.50,.95,.26),plate,steel)
        panel(c,'breacher_engine_cover',(.16,-.84,.56),(1.06,.43,.10),plate,steel)
        vents(c,'breacher_rear_vents',(.17,-.99,.672),4,.58,.09,dark)
        box(c,'breacher_shoulder_lamp',(-.88,-.57,.802),(.07,.61,.027),light,.01)
        box(c,'breacher_prow_lamp',(.40,.90,.812),(.055,.33,.025),light,.01,angle=-.42,parent=ram)
        for x in (-.62,.56):cylinder(c,'breacher_recoil_piston%s'%x,(x,-.10,.51),.105,.62,steel,axis=(0,1,0))
    elif kind=='assembler':
        for i,degrees in enumerate((25,53,81,109,137,165,193,221,249,277)):
            a=math.radians(degrees);x,y=math.cos(a)*1.18,math.sin(a)*1.18
            w=.71+(i%3)*.10;d=.75;h=.34+(i%3)*.11
            box(c,'assembler_hull_chunk%02d'%i,(x,y,.12),(w,d,h),hull,.045,angle=a)
            panel(c,'assembler_accreted_plate%02d'%i,(x,y,h+.14),(w*.85,d*.85,.07),plate,steel,angle=a)
            if i%2==0:
                box(c,'assembler_lamp%02d'%i,(x,y,h+.22),(.11,.38,.035),light,.01,angle=a)
            if i%3==1:
                cylinder(c,'assembler_reclaimed_hub%02d'%i,(x,y,h+.28),.17,.11,dark,segments=12)
                torus(c,'assembler_hub_ring%02d'%i,(x,y,h+.35),.13,.023,steel)
        panel(c,'assembler_old_side_hull',(-1.54,.10,.36),(.76,.95,.21),steel,dark,angle=.11)
        panel(c,'assembler_old_upper_hull',(-.60,1.21,.72),(.71,.62,.14),plate,steel,angle=.40)
        # Two feeding clamps reach into the open side; the broken-ring void stays visible.
        for i,(x,y,a) in enumerate(((1.30,.17,-.6),(.54,-1.31,.2))):
            r=rig(c,'assembler_feed_rig%d'%i,'assembly',(x,y,0));r['radial']=[-.65 if i==0 else .10,.20 if i==0 else .65]
            box(c,'assembler_feed_arm%d'%i,(0,0,.28),(.27,.61,.21),steel,.02,angle=a,parent=r)
            box(c,'assembler_feed_plate%d'%i,(.11,-.05,.51),(.39,.43,.09),plate,.013,angle=a,parent=r)
            box(c,'assembler_feed_lamp%d'%i,(.11,-.05,.61),(.06,.27,.025),light,.008,angle=a,parent=r)


def set_pose(frame):
    t=(frame%FRAME_COUNT)/FRAME_COUNT
    q=.5-.5*math.cos(t*math.tau)
    for o in bpy.data.scenes[SCENE].objects:
        kind=o.get('motion_kind')
        if not kind:continue
        o.location=o['base_location'];o.rotation_euler=(0,0,0)
        if kind=='drill':o.rotation_euler.y=t*math.tau
        elif kind=='compression':o.location.y=-.15*q
        elif kind=='press':o.location.y=.11*q;o.location.z=.13*q
        elif kind=='probe':
            dx,dy=o['radial'];o.location.x+=dx*.15*q;o.location.y+=dy*.15*q
        elif kind=='recoil':o.location.y=-.13*q
        elif kind=='assembly':
            dx,dy=o['radial'];o.location.x+=dx*.19*q;o.location.y+=dy*.19*q;o.location.z=.08*q


def build():
    if bpy.data.scenes.get(SCENE):raise RuntimeError('v2 scene exists: inspect it rather than overwrite.')
    OUT.mkdir(parents=True,exist_ok=True)
    s=bpy.data.scenes.new(SCENE)
    root=bpy.data.collections.new(PFX+'Industrial_Elites');s.collection.children.link(root)
    mats={
        'hull':material('gunmetal',(.065,.088,.107)),
        'dark':material('recess',(.010,.017,.023),.30,.61),
        'steel':material('machined_edges',(.23,.29,.32),.82,.32),
        'plate':material('carapace',(.13,.175,.205),.73,.43),
    }
    for k in KINDS:mats[k]=material(k+'_cold_lamps',COLORS[k],.25,.28,True)
    for kind in KINDS:
        c=bpy.data.collections.new(PFX+kind);root.children.link(c);build_class(kind,c,mats)
    cd=bpy.data.cameras.new(PFX+'Camera20deg');cam=bpy.data.objects.new(PFX+'Camera20deg',cd);root.objects.link(cam)
    cam.location=(0,-math.sin(math.radians(20))*10,math.cos(math.radians(20))*10)
    cam.rotation_euler=(Vector((0,0,0))-cam.location).to_track_quat('-Z','Y').to_euler()
    cd.type='ORTHO';cd.ortho_scale=3.85;s.camera=cam
    for name,loc,energy,color,size in (('Key',(-3,4,6),700,(1,.82,.64),5),('Fill',(3,-3,5),450,(.59,.78,1),4),('Rim',(-4,-1,3),350,(.60,.78,1),3)):
        data=bpy.data.lights.new(PFX+name,'AREA');data.energy=energy;data.color=color;data.shape='DISK';data.size=size
        o=bpy.data.objects.new(PFX+name,data);root.objects.link(o);o.location=loc;o.rotation_euler=(Vector((0,0,.3))-o.location).to_track_quat('-Z','Y').to_euler()
    world=bpy.data.worlds.new(PFX+'World');world.color=(.07,.07,.07);s.world=world
    s.render.engine='CYCLES';s.cycles.samples=12;s.cycles.use_denoising=True
    s.cycles.device='CPU'
    s.render.resolution_x=s.render.resolution_y=256;s.render.resolution_percentage=100
    s.render.image_settings.file_format='PNG';s.render.image_settings.color_mode='RGBA';s.render.image_settings.color_depth='8'
    s.render.film_transparent=True
    s.render.fps=10;s.frame_start=1;s.frame_end=8
    s.view_settings.view_transform='Standard'
    s['task']='T092 provisional detailed production; human gate PENDING'
    s['normal_convention']='camera right +R, camera up +G, viewer +B; RGB=normal*.5+.5; Raw PNG, not sRGB'
    s['pivot_xyz']=[0.,0.,0.];s['forward_axis']='+Y';s['camera_tilt_degrees']=20.
    # Keyframes retained for reproducible visible mechanisms in source file.
    for f in range(9):
        set_pose(f)
        for o in s.objects:
            if o.get('motion_kind'):
                if o.get('motion_kind')=='drill' and f==8:o.rotation_euler.y=math.tau
                o.keyframe_insert(data_path='location',frame=f+1);o.keyframe_insert(data_path='rotation_euler',frame=f+1)
    s.frame_set(1);set_pose(0)
    print(json.dumps({'scene':s.name,'object_count':len(s.objects),'material_count':len(mats),'original_active_scene':bpy.context.scene.name,'original_file':bpy.data.filepath}))


def set_map(channel):
    s=bpy.data.scenes[SCENE]
    s.view_settings.view_transform='Raw' if channel in ('normal','emission') else 'Standard'
    s.cycles.samples=16 if channel=='beauty' else 8
    s.cycles.use_denoising=channel=='beauty'
    for m in bpy.data.materials:
        if not m.name.startswith(PFX):continue
        nodes=m.node_tree.nodes;links=m.node_tree.links
        out=nodes['Output'];flat=nodes['FlatMap']
        for link in list(flat.inputs['Color'].links):links.remove(link)
        if channel=='beauty':links.new(nodes['Surface'].outputs[0],out.inputs['Surface'])
        else:
            if channel=='normal':links.new(nodes['EncodeSignedNormal'].outputs[0],flat.inputs['Color'])
            elif channel=='emission':flat.inputs['Color'].default_value=(*m['base_rgb'],1) if m['is_emitter'] else (0,0,0,1)
            else:flat.inputs['Color'].default_value=(*m['base_rgb'],1)
            links.new(flat.outputs[0],out.inputs['Surface'])


def render_frames(kind,start=0,end=8,channels=('albedo','normal','emission','beauty'),force=False):
    assert kind in KINDS
    s=bpy.data.scenes[SCENE]
    for k in KINDS:bpy.data.collections[PFX+k].hide_render=k!=kind
    s.camera.data.ortho_scale=EXTENTS[kind]
    dest=OUT/'renders'/kind;dest.mkdir(parents=True,exist_ok=True)
    for frame in range(start,end):
        with bpy.context.temp_override(scene=s,view_layer=s.view_layers[0]):
            s.frame_set(frame+1);set_pose(frame)
            s.view_layers[0].update()
            for channel in channels:
                path=dest/('%s_%02d.png'%(channel,frame))
                if path.exists() and not force:continue
                set_map(channel);s.render.filepath=str(path)
                s.view_layers[0].update()
                bpy.ops.render.render(write_still=True,scene=SCENE)
                print('T092V2_RENDER '+str(path))


def save_source(filename='t092_industrial_elites_v2.blend'):
    s=bpy.data.scenes[SCENE];s.frame_set(1);set_pose(0);set_map('beauty')
    s.view_layers[0].update()
    for k in KINDS:bpy.data.collections[PFX+k].hide_render=k!='tunneler'
    s.camera.data.ortho_scale=EXTENTS['tunneler']
    path=OUT/filename
    if path.exists():raise RuntimeError('Existing versioned source is preserved; choose a new source version.')
    bpy.data.libraries.write(str(path),{s},fake_user=True,compress=True)
    print(json.dumps({'source':str(path),'active_scene_preserved':bpy.context.scene.name,'active_file_preserved':bpy.data.filepath}))

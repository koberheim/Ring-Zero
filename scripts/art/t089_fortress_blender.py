"""Original modeled T-089 structural repairs, isolated source library v1.

Executed through Blender MCP after instance inspection/claim. Never changes the
user's Scene/file or F's scenes. Reuses project-owned mesh/map constructors.
All-bearing source captures are provisional until native live integration.
"""
import bpy
import json
import math
from pathlib import Path
from mathutils import Vector

ROOT = Path(r'E:\AI Projects\Games\Ring Zero')
OUT = ROOT/'assets/art/source/presentation-v3-fortress/v2'
SCENE = 'T089_Fortress_v2'
PFX = 'T089V2_'
KINDS = ('flak','emp_node','lance_emitter','point_defense','relay','repair_node','armor_plating','wall','debris_field','tractor_lane','occlusion_screen')
F = {}
exec(compile((ROOT/'scripts/art/t092_production_blender.py').read_text(encoding='utf-8'),'t092_shared_mesh_constructors','exec'), F)
F.update(PFX=PFX, SCENE=SCENE, OUT=OUT)
box, cylinder, torus, prism, panel = (F[k] for k in ('box','cylinder','torus','prism','panel'))


def beam(c, name, a, b, radius, mat):
    a,b=Vector(a),Vector(b)
    return cylinder(c,name,(a+b)/2,radius,(b-a).length,mat,axis=(b-a),segments=12)


def bolt(c,name,x,y,z,mat):
    return cylinder(c,name,(x,y,z),.042,.035,mat,segments=6,bevel=0)


def build_kind(k,c,m):
    steel,light,dark,warm,ceramic = (m[n] for n in ('steel','light','dark','warm','ceramic'))
    if k in ('flak','emp_node','lance_emitter','point_defense','repair_node'):
        cylinder(c,k+'_seat',(0,0,.08),.47 if k!='point_defense' else .33,.16,dark)
        cylinder(c,k+'_bearing',(0,0,.18),.39 if k!='point_defense' else .26,.10,steel)
    if k=='flak':
        panel(c,'breech',(0,-.32,.20),(1.12,.74,.33),steel,light)
        for side in (-1,1):
            box(c,'side_cheek',(side*.59,-.31,.20),(.16,.52,.43),dark)
            for j in range(3):
                x=side*(.20+j*.18)
                cylinder(c,'short_barrel',(x,.39,.39),.069,.85,light,axis=(0,1,0),segments=12)
                cylinder(c,'muzzle',(x,.84,.39),.093,.14,dark,axis=(0,1,0),segments=12)
                cylinder(c,'muzzle_rim',(x,.916,.39),.071,.03,steel,axis=(0,1,0),segments=12)
        box(c,'burst_chamber',(0,-.64,.43),(.25,.20,.11),warm)
    elif k=='emp_node':
        for z,r in ((.29,.56),(.43,.48),(.58,.39)):
            torus(c,'pulse_coil',(0,0,z),r,.075,warm)
        cylinder(c,'pulse_core',(0,0,.47),.19,.65,ceramic)
        for j in range(4):
            a=j*math.tau/4
            cylinder(c,'insulator',(math.cos(a)*.57,math.sin(a)*.57,.29),.065,.29,light,segments=10)
        cylinder(c,'lens',(0,0,.815),.13,.035,m['lamp'])
    elif k=='lance_emitter':
        panel(c,'single_spine',(0,.25,.23),(.26,1.72,.28),steel,light)
        for y in (-.53,-.29,-.05,.19,.43):
            box(c,'cooling_vane',(0,y,.31),(.70,.075,.16),dark)
        for side in (-1,1):
            beam(c,'focus_brace',(side*.34,-.41,.38),(side*.18,1.13,.48),.038,light)
        torus(c,'focusing_ring',(0,1.04,.42),.23,.050,warm,axis=(0,1,0))
        cylinder(c,'optic',(0,1.08,.42),.15,.065,m['lamp'],axis=(0,1,0))
        box(c,'rear_power',(0,-.68,.26),(.48,.34,.20),steel)
    elif k=='point_defense':
        # Open lightweight yoke: no armored slab around the twin mechanism.
        for side in (-1,1):
            beam(c,'tracking_fork',(side*.29,-.15,.16),(side*.29,.17,.45),.043,steel)
            cylinder(c,'micro_barrel',(side*.15,.34,.41),.044,.63,light,axis=(0,1,0),segments=10)
            cylinder(c,'micro_breech',(side*.15,-.08,.41),.085,.25,dark,axis=(0,1,0),segments=10)
        beam(c,'cross_pin',(-.34,.08,.36),(.34,.08,.36),.052,warm)
        cylinder(c,'tracking_eye',(0,-.19,.34),.080,.07,m['lamp'])
    elif k=='relay':
        for j in range(3):
            a=j*math.tau/3
            x,y=math.cos(a)*.43,math.sin(a)*.43
            panel(c,'ground_foot',(x,y,.015),(.24,.26,.07),steel,light)
            beam(c,'mast_brace',(x,y,.09),(0,0,.82),.039,light)
        cylinder(c,'relay_mast',(0,0,.70),.075,1.3,steel)
        # Actual raised shallow dish; camera stays fixed for every bearing.
        cylinder(c,'dish_back',(0,.02,1.23),.37,.09,dark,axis=(0,1,.32),segments=32)
        cylinder(c,'dish_face',(0,.075,1.25),.32,.04,light,axis=(0,1,.32),segments=32)
        torus(c,'dish_rim',(0,.095,1.26),.345,.028,warm,axis=(0,1,.32))
        beam(c,'feed_arm',(0,0,1.04),(0,.36,1.31),.025,steel)
        cylinder(c,'relay_feed',(0,.35,1.31),.045,.07,m['lamp'],axis=(0,1,0))
    elif k=='repair_node':
        beam(c,'lower_arm',(0,-.25,.30),(0,.09,.85),.095,steel)
        beam(c,'upper_arm',(0,.09,.85),(0,.75,.51),.075,light)
        beam(c,'hydraulic',(0,-.11,.29),(0,.47,.60),.038,warm)
        for name,y,z in (('base_joint',-.25,.30),('elbow_joint',.09,.85),('tool_joint',.75,.51)):
            cylinder(c,name,(0,y,z),.13,.29,dark,axis=(1,0,0),segments=16)
        for side in (-1,1):
            beam(c,'tool_fork',(side*.10,.73,.49),(side*.19,1.02,.25),.042,light)
        box(c,'tool_light',(0,.78,.51),(.09,.10,.06),m['lamp'])
    elif k=='armor_plating':
        for x in (-.32,.32):
            for y in (-.32,.32):
                panel(c,'flush_slab',(x,y,.01),(.58,.58,.075),steel,light)
        for x in (-.60,.60): box(c,'edge_stripe',(x,0,.088),(.045,1.22,.006),warm,0)
    elif k=='wall':
        box(c,'barrier_face',(0,0,.18),(2.40,.16,.72),steel)
        box(c,'barrier_crest',(0,0,.88),(2.50,.25,.10),light)
        box(c,'barrier_lower_beam',(0,0,.14),(2.55,.26,.14),dark)
        for x in (-1.13,-.57,0,.57,1.13):
            box(c,'barrier_stiffener',(x,-.12,.21),(.10,.10,.62),dark)
            for y in (-.20,.20):
                panel(c,'attachment_foot',(x,y,.015),(.24,.31,.065),steel,light)
        for x in (-.84,.28): box(c,'barrier_hazard',(x,-.086,.68),(.25,.012,.085),warm,0)
    elif k=='debris_field':
        for i in range(11):
            a=i*2.39996;r=.25+.11*(i%5)
            x,y=math.cos(a)*r,math.sin(a)*r
            box(c,'dead_scrap',(x,y,.012),(.16+.045*(i%3),.09+.025*(i%4),.04+.025*(i%3)),steel if i%3 else dark,.006,angle=a)
        beam(c,'snapped_pipe',(-.50,-.44,.06),(-.11,-.35,.06),.040,dark)
    elif k=='tractor_lane':
        # +X is clockwise/tangential when model +Y faces north/outward.
        for x in (-.52,0,.52):
            points=[(x-.19,-.36),(x-.07,-.36),(x+.19,0),(x-.07,.36),(x-.19,.36),(x+.07,0)]
            prism(c,'flush_arrow',points,.006,.004,warm,0)
        for y in (-.48,.48):
            for x in (-.56,-.19,.19,.56):box(c,'flush_dash',(x,y,.004),(.21,.035,.005),light,0)
    elif k=='occlusion_screen':
        for x in (-.83,.83):
            panel(c,'screen_foot',(x,0,.015),(.28,.57,.07),steel,light)
            box(c,'screen_leg',(x,0,.07),(.095,.12,1.24),light)
        box(c,'screen_top',(0,0,1.28),(1.79,.14,.08),steel)
        box(c,'screen_bottom',(0,0,.31),(1.79,.14,.08),steel)
        for x in range(10):box(c,'standing_louver',(-.73+x*.162,0,.38),(.11,.075,.82),dark,.01)
        for z in (.58,.86,1.13):box(c,'screen_crossbar',(0,-.04,z),(1.61,.06,.025),steel,.006)
    rig=bpy.data.objects.new(PFX+k+'_ORIENTATION_ROOT',None);c.objects.link(rig)
    for o in list(c.objects):
        if o!=rig:o.parent=rig


def build():
    if SCENE in bpy.data.scenes:raise RuntimeError('Preserve existing version; use new source version')
    OUT.mkdir(parents=True,exist_ok=True)
    s=bpy.data.scenes.new(SCENE)
    root=bpy.data.collections.new(PFX+'Root');s.collection.children.link(root)
    mats={k:F['material'](k,v,.65,.48,k=='lamp') for k,v in {
        'steel':(.24,.27,.28),'light':(.47,.48,.43),'dark':(.055,.075,.087),'warm':(.55,.27,.065),'ceramic':(.40,.40,.32),'lamp':(.86,.43,.12)}.items()}
    # Static T081 material cache takes image-down green. This is explicit
    # camera-normal conversion, never luminance-derived pseudo depth.
    for m in mats.values():m.node_tree.nodes['CameraZTowardViewer'].inputs[1].default_value=(1,-1,-1)
    for k in KINDS:
        c=bpy.data.collections.new(PFX+k);root.children.link(c);build_kind(k,c,mats)
    cd=bpy.data.cameras.new(PFX+'Camera');cam=bpy.data.objects.new(PFX+'Camera',cd);root.objects.link(cam)
    cam.location=(0,-math.sin(math.radians(20))*10,math.cos(math.radians(20))*10)
    cam.rotation_euler=(-cam.location).to_track_quat('-Z','Y').to_euler();cd.type='ORTHO';cd.ortho_scale=3.4;s.camera=cam
    for name,loc,energy,color in [('Key',(-3,4,6),700,(1,.82,.64)),('Fill',(3,-3,5),400,(.59,.78,1))]:
        data=bpy.data.lights.new(PFX+name,'AREA');data.energy=energy;data.color=color;data.shape='DISK';data.size=5
        o=bpy.data.objects.new(PFX+name,data);root.objects.link(o);o.location=loc;o.rotation_euler=(Vector((0,0,.3))-o.location).to_track_quat('-Z','Y').to_euler()
    world=bpy.data.worlds.new(PFX+'World');world.color=(.07,.07,.07);s.world=world
    s.render.engine='CYCLES';s.cycles.device='CPU';s.cycles.samples=8;s.cycles.use_denoising=False
    s.render.resolution_x=s.render.resolution_y=256;s.render.resolution_percentage=100
    s.render.image_settings.file_format='PNG';s.render.image_settings.color_mode='RGBA';s.render.image_settings.color_depth='8';s.render.film_transparent=True
    s.view_settings.view_transform='Standard';s['task']='T089 mapped structural repairs, native acceptance pending'
    s['normal_convention']='camera right, image down, toward viewer; linear data RGB=n*.5+.5'
    s['pivot_xyz']=[0.,0.,0.];s['forward_axis']='+Y outward at north';s['bearing_frames']=12
    print(json.dumps({'scene':s.name,'objects':len(s.objects),'original_scene':bpy.context.scene.name,'original_file':bpy.data.filepath}))


def render(k,start=0,end=12,channels=('albedo','normal','emission','beauty')):
    assert k in KINDS
    s=bpy.data.scenes[SCENE]
    for kind in KINDS:bpy.data.collections[PFX+kind].hide_render=kind!=k
    dest=OUT/'renders'/k;dest.mkdir(parents=True,exist_ok=True)
    rig=bpy.data.objects[PFX+k+'_ORIENTATION_ROOT']
    assert rig.type=='EMPTY' and len(rig.children)>0,'Orientation root must own the complete model'
    for frame in range(start,end):
        with bpy.context.temp_override(scene=s,view_layer=s.view_layers[0]):
            rig.rotation_euler.z=-frame*math.tau/12;s.view_layers[0].update()
            for channel in channels:
                path=dest/('%s_%02d.png'%(channel,frame))
                if path.exists():continue
                F['set_map'](channel);s.render.filepath=str(path);s.view_layers[0].update()
                bpy.ops.render.render(write_still=True,scene=SCENE)
                print('T089_RENDER '+str(path))


def save_source():
    s=bpy.data.scenes[SCENE];F['set_map']('beauty')
    for k in KINDS:bpy.data.objects[PFX+k+'_ORIENTATION_ROOT'].rotation_euler.z=0
    for k in KINDS:bpy.data.collections[PFX+k].hide_render=k!='flak'
    s.view_layers[0].update()
    path=OUT/'t089_fortress_v2.blend'
    if path.exists():raise RuntimeError('Versioned source already exists')
    bpy.data.libraries.write(str(path),{s},fake_user=True,compress=True)
    print(json.dumps({'source':str(path),'active_scene_preserved':bpy.context.scene.name,'active_file_preserved':bpy.data.filepath}))

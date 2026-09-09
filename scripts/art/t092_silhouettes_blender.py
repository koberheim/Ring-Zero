"""T-092 v1: isolated Blender depth blockouts; not shipping art.

Execute via Blender MCP: exec(compile(open(PATH).read(), PATH, 'exec')).
Then call build(); render_class('tunneler'); ...; save_source().
No existing scene/data is edited. The active .blend is never saved/replaced.
"""
import bpy
import json
import math
from pathlib import Path
from mathutils import Vector

ROOT = Path(r'E:\AI Projects\Games\Ring Zero')
OUT = ROOT / 'assets/art/source/presentation-v3-elites'
SCENE = 'T092_Silhouette_v1'
CLASSES = ('tunneler', 'transfer', 'foundry', 'sapper', 'breacher', 'assembler')


def prism(collection, name, points, height, z=0):
    n = len(points)
    vertices = [(x, y, z) for x, y in points] + [(x, y, z + height) for x, y in points]
    faces = [tuple(reversed(range(n))), tuple(range(n, 2*n))]
    faces += [(i, (i+1) % n, (i+1) % n+n, i+n) for i in range(n)]
    mesh = bpy.data.meshes.new('T092_' + name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new('T092_' + name, mesh)
    collection.objects.link(obj)
    return obj


def box(c, name, x, y, w, d, h, angle=0, z=0):
    co, si = math.cos(angle), math.sin(angle)
    points = [(x+a*co-b*si, y+a*si+b*co) for a,b in [(-w/2,-d/2),(w/2,-d/2),(w/2,d/2),(-w/2,d/2)]]
    return prism(c, name, points, h, z)


def build():
    if bpy.data.scenes.get(SCENE):
        raise RuntimeError('T-092 scene already exists; inspect it, do not silently replace it.')
    OUT.mkdir(parents=True, exist_ok=True)
    s = bpy.data.scenes.new(SCENE)
    root = bpy.data.collections.new('T092_Silhouette_Blockouts_v1')
    s.collection.children.link(root)
    collections = {}
    for name in CLASSES:
        c = bpy.data.collections.new('T092_' + name)
        root.children.link(c)
        collections[name] = c
    c = collections['tunneler']
    # Long, low cutting axis; stepped worm body and a single tapered drill.
    for i, (width, y) in enumerate(((.60,-1.15),(.72,-.64),(.64,-.10))):
        box(c, 'tunneler_segment_%d' % i, 0, y, width, .59, .23)
    prism(c, 'tunneler_drill', [(-.48,.12),(.48,.12),(0,1.48)], .31)
    c = collections['transfer']
    # Open horseshoe: substantial gap survives minification.
    prism(c, 'transfer_horseshoe', [(-1.22,1.22),(-.64,1.22),(-.64,-.64),(.64,-.64),(.64,1.22),(1.22,1.22),(1.22,-1.12),(-1.22,-1.12)], .42)
    box(c, 'transfer_left_thruster', -.93, -1.18, .68, .54, .62)
    box(c, 'transfer_right_thruster', .93, -1.18, .68, .54, .62)
    c = collections['foundry']
    # Wide processing press with four anchored feet and a broad front jaw.
    box(c, 'foundry_body', 0, 0, 2.40, 1.60, .78)
    box(c, 'foundry_processing_jaw', 0, .91, 1.38, .48, .49)
    for x in (-1.20, 1.20):
        for y in (-.82,.82):
            box(c, 'foundry_anchor_%s_%s' % (x,y), x,y,.56,.56,.25)
    c = collections['sapper']
    prism(c, 'sapper_hub', [(math.cos(i*math.tau/6)*.58,math.sin(i*math.tau/6)*.58) for i in range(6)], .39)
    for i in range(6):
        a=i*math.tau/6
        box(c, 'sapper_probe_%d' % i, math.sin(a)*.87, math.cos(a)*.87,.36,1.18,.19,angle=-a)
    c = collections['breacher']
    # Solid offset ram: no drill neck, fork or hole.
    prism(c, 'breacher_wedge', [(-1.17,-1.14),(.82,-1.14),(1.18,.05),(.46,1.47),(-1.17,.42)], .54)
    box(c, 'breacher_offset_shoulder', -.97,-.60,.55,.98,.77)
    c = collections['assembler']
    # A damaged accretion ring; rectangular hull fragments, permanent opening.
    for i, degrees in enumerate((35,65,95,125,155,185,215,245,275)):
        a=math.radians(degrees)
        box(c, 'assembler_hull_%02d' % i, math.cos(a)*1.03, math.sin(a)*1.03,.72+(i%3)*.12,.70,.34+(i%3)*.18,angle=a)
    box(c, 'assembler_accretion', -1.31,.08,.75,.75,.82,angle=.15)
    cam_data=bpy.data.cameras.new('T092_Camera_20deg')
    cam=bpy.data.objects.new('T092_Camera_20deg',cam_data)
    root.objects.link(cam)
    cam.location=(0,-math.sin(math.radians(20))*10,math.cos(math.radians(20))*10)
    cam.rotation_euler=(Vector((0,0,0))-cam.location).to_track_quat('-Z','Y').to_euler()
    cam_data.type='ORTHO'
    cam_data.ortho_scale=4.1
    s.camera=cam
    s.render.engine='BLENDER_WORKBENCH'
    s.render.resolution_x=s.render.resolution_y=256
    s.render.resolution_percentage=100
    s.render.image_settings.file_format='PNG'
    s.render.image_settings.color_mode='RGBA'
    s.render.film_transparent=True
    sh=s.display.shading
    sh.light='FLAT'
    sh.color_type='SINGLE'
    sh.single_color=(0,0,0)
    sh.show_shadows=False
    sh.show_cavity=False
    sh.show_specular_highlight=False
    s.view_settings.view_transform='Standard'
    s['task']='T-092 early silhouette gate only'
    s['forward_axis']='+Y'
    s['ground_pivot']=[0.0,0.0,0.0]
    s['camera_tilt_from_vertical_degrees']=20.0
    s['shipping_status']='NOT ACCEPTED / human trial pending'
    print(json.dumps({'created_scene':s.name,'objects':len(s.objects),'original_active_scene':bpy.context.scene.name,'original_file':bpy.data.filepath}))


def render_class(name, clay=False):
    assert name in CLASSES
    s=bpy.data.scenes[SCENE]
    for kind in CLASSES:
        bpy.data.collections['T092_'+kind].hide_render=kind != name
    sh=s.display.shading
    sh.light='STUDIO' if clay else 'FLAT'
    sh.single_color=(.46,.49,.53) if clay else (0,0,0)
    s.render.filepath=str(OUT / (name + ('_clay' if clay else '_silhouette') + '.png'))
    bpy.ops.render.render(write_still=True,scene=SCENE)
    print('T092_RENDER '+s.render.filepath)


def save_source():
    s=bpy.data.scenes[SCENE]
    for kind in CLASSES:
        bpy.data.collections['T092_'+kind].hide_render=kind != 'tunneler'
    s.display.shading.light='STUDIO'
    s.display.shading.single_color=(.46,.49,.53)
    path=OUT / 't092_silhouette_blockouts_v1.blend'
    if path.exists():
        raise RuntimeError('Source already exists; use a versioned new filename.')
    bpy.data.libraries.write(str(path),{s},fake_user=True,compress=True)
    print(json.dumps({'source_library':str(path),'active_scene_preserved':bpy.context.scene.name,'active_file_preserved':bpy.data.filepath}))

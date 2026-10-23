import bpy, pathlib, json
from mathutils import Vector
ROOT=pathlib.Path(r'C:\Users\john2\Documents\Game Development\Bagyong Bahay\software-eng-fest')
OUT=ROOT/'design_previews/dialogue_portraits_v2/references'
SOURCE=ROOT/'_raw_assets/Simple_Character_PSX/model/glb/simple-character-psx.glb'
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(SOURCE))
for ob in bpy.data.objects:
 if ob.animation_data: ob.animation_data_clear()
 if ob.type=='ARMATURE':ob.data.pose_position='REST'
for mat in bpy.data.materials:
 if mat.use_nodes:
  for node in mat.node_tree.nodes:
   if node.type=='TEX_IMAGE':node.interpolation='Closest'
head=next(o for o in bpy.data.objects if o.type=='MESH' and o.name=='head')
bpy.context.view_layer.update()
points=[head.matrix_world @ Vector(v) for v in head.bound_box]
mins=Vector([min(p[i] for p in points) for i in range(3)]);maxs=Vector([max(p[i] for p in points) for i in range(3)]);center=(mins+maxs)/2
print('PLAYER_HEAD_BOUNDS',list(mins),list(maxs),flush=True)
target=Vector((center.x,center.y,center.z-(maxs.z-mins.z)*0.30))
cam_data=bpy.data.cameras.new('ReviewCamera');cam=bpy.data.objects.new('ReviewCamera',cam_data);bpy.context.collection.objects.link(cam)
cam.location=target+Vector((0,-4,0));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam_data.type='ORTHO';cam_data.ortho_scale=(maxs.z-mins.z)*2.25
scene=bpy.context.scene;scene.camera=cam;scene.render.engine='BLENDER_EEVEE';scene.render.resolution_x=768;scene.render.resolution_y=768;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.render.film_transparent=False;scene.world.use_nodes=True
scene.world.node_tree.nodes.get('Background').inputs[0].default_value=(0.075,0.095,0.11,1);scene.world.node_tree.nodes.get('Background').inputs[1].default_value=0.6;scene.view_settings.view_transform='Standard'
for name,loc,power,size in [('Key',(-2,-3,3),450,4),('Fill',(2,-2,1),200,3),('Back',(0,2,2.7),150,3)]:
 data=bpy.data.lights.new(name,'AREA');ob=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(ob);ob.location=target+Vector(loc);ob.rotation_euler=(target-ob.location).to_track_quat('-Z','Y').to_euler();data.energy=power;data.shape='DISK';data.size=size
scene.render.filepath=str(OUT/'player_model.png');bpy.ops.render.render(write_still=True)
print('PLAYER_REFERENCE_RENDER',scene.render.filepath,flush=True)

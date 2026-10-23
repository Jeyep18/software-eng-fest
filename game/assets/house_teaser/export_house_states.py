"""Run through Blender MCP against the approved review file; never saves it."""
import bpy
import json
import tempfile
from pathlib import Path
from io_scene_gltf2.blender.exp.material import encode_image

OUT = Path(__file__).parent
EXPORT_OUT = Path(r'C:\Temp\bagyong-house-teaser-20261012\exports')
EXPORT_OUT.mkdir(parents=True, exist_ok=True)
source_scene = bpy.context.scene
window = bpy.context.window_manager.windows[0]
source_layer = window.view_layer
exports = []
temporary_materials = []
original_encoder = encode_image._encode_temp_image

def encode_with_extension(image, file_format, settings):
    # Packed images require an explicit copy path in Blender 5.2.
    with tempfile.TemporaryDirectory() as folder:
        path = Path(folder) / ('img.' + {'JPEG':'jpg', 'WEBP':'webp'}.get(file_format, 'png'))
        image.filepath_raw = str(path)
        image.file_format = file_format
        if file_format in {'JPEG', 'WEBP'}:
            image.save(filepath=str(path), save_copy=True, quality=settings['gltf_image_quality'])
        else:
            image.save(filepath=str(path), save_copy=True)
        return path.read_bytes()

encode_image._encode_temp_image = encode_with_extension

def portable_material(material):
    copy = material.copy()
    temporary_materials.append(copy)
    nodes = copy.node_tree.nodes if copy.use_nodes else None
    if nodes:
        diffuse = next((n for n in nodes if n.type == 'BSDF_DIFFUSE'), None)
        if diffuse:
            shader = nodes.new('ShaderNodeBsdfPrincipled')
            shader.inputs['Roughness'].default_value = 0.8
            color = diffuse.inputs['Color']
            if color.is_linked:
                copy.node_tree.links.new(color.links[0].from_socket, shader.inputs['Base Color'])
            else:
                shader.inputs['Base Color'].default_value = color.default_value
            for link in list(diffuse.outputs[0].links):
                copy.node_tree.links.new(shader.outputs[0], link.to_socket)
            nodes.remove(diffuse)
    return copy

try:
    for state in ['Normal', 'Wrecked']:
        window.view_layer = source_scene.view_layers[state + '_Atmosphere']
        window.view_layer.update()
        depsgraph = bpy.context.evaluated_depsgraph_get()
        scene = bpy.data.scenes.new('Teaser_Export_' + state)
        scene.render.resolution_x = 1920
        scene.render.resolution_y = 1080
        material_map = {}
        objects = list(bpy.data.collections['House_' + state].all_objects)
        objects += list(bpy.data.collections['Surrounding_Environment'].all_objects)
        if state == 'Normal':
            objects += list(bpy.data.collections['Review_Cameras'].all_objects)
        for original in objects:
            if original.type in {'MESH', 'CURVE'}:
                mesh = bpy.data.meshes.new_from_object(original.evaluated_get(depsgraph), depsgraph=depsgraph)
                obj = bpy.data.objects.new(original.name, mesh)
                for i, material in enumerate(mesh.materials):
                    if material:
                        if material not in material_map:
                            material_map[material] = portable_material(material)
                        mesh.materials[i] = material_map[material]
            elif original.type == 'CAMERA':
                obj = bpy.data.objects.new(original.name, original.data.copy())
            else:
                continue
            scene.collection.objects.link(obj)
            obj.matrix_world = original.matrix_world.copy()
            obj.name = original.name.replace('.', '_')
        window.scene = scene
        path = EXPORT_OUT / ('house_' + state.lower() + '.glb')
        bpy.ops.export_scene.gltf(filepath=str(path), export_format='GLB', use_active_scene=True,
            export_cameras=True, export_lights=False, export_animations=False,
            export_yup=True, export_extras=True, export_materials='EXPORT', export_image_format='AUTO')
        exports.append({'state':state, 'objects':len(scene.objects), 'bytes':path.stat().st_size})
        window.scene = source_scene
        for obj in list(scene.objects):
            data = obj.data
            bpy.data.objects.remove(obj, do_unlink=True)
            if data and data.users == 0:
                (bpy.data.cameras if isinstance(data,bpy.types.Camera) else bpy.data.meshes).remove(data)
        bpy.data.scenes.remove(scene)
    (OUT / 'export_manifest.json').write_text(json.dumps({'source':bpy.data.filepath,'exports':exports},indent=2))
finally:
    encode_image._encode_temp_image = original_encoder
    window.scene = source_scene
    window.view_layer = source_layer
    for material in temporary_materials:
        if material.users == 0:
            bpy.data.materials.remove(material)
result = {'exports':exports, 'source_saved':False}

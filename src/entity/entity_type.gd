class_name EntityType
extends Content

class MeshData extends Resource:
    @export var mesh: Mesh
    @export var transform: Transform3D

@export var meshes: Array[MeshData] = []

@export_group("Import from scene", "scene_")
@export var scene_meshes: NodePath

## Array[NodePath -> MeshInstance3D]
@export var scene_mesh_nodes: Array[NodePath]

func _data() -> void:
    super._data()
    content_type = ContentType.ENTITY

func _init_from_scene(node: ContentScene) -> void:
    super._init_from_scene(node)
    if scene_meshes:
        var n = node.get_node(scene_meshes)
        var shapes = n.find_children("*", "MeshInstance3D")
        for shape in shapes:
            scene_mesh_nodes.append(node.get_path_to(shape))
    for node_path in scene_mesh_nodes:
        var n = node.get_node(node_path)
        import_mesh(n)

func import_mesh(mesh: MeshInstance3D) -> void:
    var mesh_data = MeshData.new()
    mesh_data.mesh = mesh.mesh
    mesh_data.transform = get_relative_transform(mesh)
    meshes.append(mesh_data)

func _apply_mesh(entity: Entity) -> void:
    for mesh in meshes:
        entity.add_mesh(mesh.mesh.get_rid(), mesh.transform)

func apply_mesh(entity: Entity) -> void:
    _apply_mesh(entity)


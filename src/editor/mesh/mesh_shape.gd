@tool
class_name MeshShape
extends MultiMeshInstance3D

const MESH = preload("res://assets/editor/mesh_shape_cube_cube.res")

@export var size: Vector3i = Vector3i(1, 1, 1):
    set = set_size

var content_scene: ContentScene
var mesh_origin: MeshOrigin

func _ready() -> void:
    multimesh = MultiMesh.new()
    multimesh.transform_format = MultiMesh.TRANSFORM_3D
    multimesh.mesh = MESH
    update_content_scene()
    set_size(size)

func update_content_scene() -> void:
    var current = self
    while current:
        if current is ContentScene:
            content_scene = current
            break
        current = current.get_parent()
    if content_scene:
        content_scene.child_entered_tree.connect(update_mesh_origin)
        content_scene.child_exiting_tree.connect(update_mesh_origin)
        update_mesh_origin()

func update_mesh_origin(node: Node = content_scene) -> bool:
    if node == null: return false
    if node is MeshOrigin:
        mesh_origin = node
        return true
    for child in node.get_children():
        if update_mesh_origin(child):
            return true
    return false

func _process(_delta: float) -> void:
    transform.basis = Basis.IDENTITY
    if mesh_origin:
        var offset = position - mesh_origin.position
        offset = offset.round()
        position = mesh_origin.position + offset

func set_size(v: Vector3i) -> void:
    size = v
    multimesh.instance_count = size.x * size.y * size.z
    for i in multimesh.instance_count:
        @warning_ignore("integer_division")
        var pos = Vector3(i % size.x, (i / size.x) % size.y, i / size.x / size.y)
        multimesh.set_instance_transform(i, Transform3D.IDENTITY.translated(pos))

func get_min_position() -> Vector3i:
    return Vector3i(position - mesh_origin.position)

func get_max_position() -> Vector3i:
    return Vector3i(position - mesh_origin.position) + size


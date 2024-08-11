class_name PhysicsEntityType
extends EntityType

class ShapeData extends RefCounted:
    var shape: Shape3D
    var transform: Transform3D
    var mass: float = 1

var collision_shapes: Array[ShapeData]

@export_group("Import from scene", "scene_")
@export_node_path("Node3D") var scene_collision_shapes: NodePath

## Array[NodePath -> CollisionShape3D]
@export var scene_collision_shape_nodes: Array[NodePath]

func _init_from_scene(node: ContentScene) -> void:
    super._init_from_scene(node)
    if scene_collision_shapes:
        var n = node.get_node(scene_collision_shapes)
        var shapes = n.find_children("*", "CollisionShape3D")
        for shape in shapes:
            import_shape(shape, n)
    for node_path in scene_collision_shape_nodes:
        var n = node.get_node(node_path)
        import_shape(n)

func import_shape(shape: EntityCollisionShape3D, relative: Node3D = null) -> void:
    var shape_data = ShapeData.new()
    shape_data.shape = shape.shape
    shape_data.transform = relative.transform.affine_inverse() * shape.transform \
            if relative else shape.transform
    shape_data.mass = shape.mass
    collision_shapes.append(shape_data)

func _apply_shape(entity: PhysicsEntity) -> void:
    for shape_data in collision_shapes:
        entity.add_shape(shape_data.shape.get_rid(), shape_data.transform, shape_data.mass)

func apply_shape(entity: PhysicsEntity) -> void:
    _apply_shape(entity)


class_name PhysicsEntityType
extends EntityType

class ShapeData extends RefCounted:
    @export var shape: Shape3D
    @export var transform: Transform3D
    @export var mass: float = 1

var collision_shapes: Array[ShapeData]

@export_group("Import from scene", "scene_")
@export var scene_collision_shapes: NodePath

## Array[NodePath -> CollisionShape3D]
@export var scene_collision_shape_nodes: Array[NodePath]

func _init_from_scene(node: ContentScene) -> void:
    super._init_from_scene(node)
    if scene_collision_shapes:
        var n = node.get_node(scene_collision_shapes)
        var shapes = n.find_children("*", "EntityCollisionShape3D")
        for shape in shapes:
            scene_collision_shape_nodes.append(shape)
    for node_path in scene_collision_shape_nodes:
        var n = node.get_node(node_path)
        import_shape(n)

func import_shape(shape: EntityCollisionShape3D) -> void:
    var shape_data = ShapeData.new()
    shape_data.shape = shape.shape
    shape_data.transform = get_relative_transform(shape)
    shape_data.mass = shape.mass
    collision_shapes.append(shape_data)

func _apply_shape(entity: PhysicsEntity) -> void:
    for shape_data in collision_shapes:
        entity.add_shape(shape_data.shape.get_rid(), shape_data.transform, shape_data.mass)

func apply_shape(entity: PhysicsEntity) -> void:
    _apply_shape(entity)


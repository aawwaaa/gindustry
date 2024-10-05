class_name MeshBlockType
extends PhysicsEntityType

const MESH_BLOCK_SIZE = MeshEntity.MESH_BLOCK_SIZE

@export var rotatable: MeshBlockEntity.Rotatable

## The offset from `position * MESH_BLOCK_SIZE` to the origin of the entity
@export var origin_offset: Vector3

## The offset from `position` to the left(X-) near(Z+) bottom(Y-) corner of the bitmap
@export var mesh_shape_offset: Vector3i

## Every element is a layer in `height`(Y+ in relative), which is a plane in `width`(x+) as x and `depth`(Z-) as y
@export var mesh_shape: Array[BitMap]

@export_group("Import from scene", "scene_")

@export_node_path("MeshOrigin") var scene_origin_offset: NodePath
@export var scene_mesh_shapes: NodePath

func _init_from_scene(node: ContentScene) -> void:
    super._init_from_scene(node)
    var origin = node.get_node(scene_origin_offset) as MeshOrigin
    if origin:
        origin_offset = origin.get_origin_offset()
    if scene_mesh_shapes:
        var n = node.get_node(scene_mesh_shapes)
        var shapes = n.find_children("*", "MeshShape")
        var min_pos = Vector3i.ONE * INF;
        var max_pos = Vector3i.ONE * -INF;
        for shape in shapes:
            shape.update_content_scene();
            var pos = shape.get_min_position();
            min_pos = Vector3i(mini(pos.x, min_pos.x), mini(pos.y, min_pos.y), mini(pos.z, min_pos.z))
            pos = shape.get_max_position();
            max_pos = Vector3i(maxi(pos.x, max_pos.x), maxi(pos.y, max_pos.y), maxi(pos.z, max_pos.z))
        var size = max_pos - min_pos
        # its based origin and origin is Vector3i.ZERO
        var offset = Vector3i.ZERO - min_pos
        mesh_shape_offset = offset
        mesh_shape = []
        for y in size.y + 1:
            var bitmap = BitMap.new()
            bitmap.create(Vector2i(size.x + 1, size.z + 1))
            mesh_shape.append(bitmap)
        for shape in shapes:
            for y in range(shape.get_min_position().y, shape.get_max_position().y + 1):
                var bitmap = mesh_shape[y + offset.y]
                for x in range(shape.get_min_position().x, shape.get_max_position().x + 1):
                    for z in range(shape.get_min_position().z, shape.get_max_position().z + 1):
                        bitmap.set_bit(x + offset.x, z + offset.z, true)


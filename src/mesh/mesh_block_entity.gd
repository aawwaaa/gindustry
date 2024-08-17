class_name MeshBlockEntity
extends PartialPhysicsEntity

const MESH_BLOCK_SIZE = MeshEntity.MESH_BLOCK_SIZE

static func get_type() -> ObjectType:
    return (MeshBlockEntity as Object).get_meta(OBJECT_TYPE_META)

enum Rotatable {
    NONE = 0, FACING = 1, ALL = 3
}

var mesh_block_type: MeshBlockType:
    get: return object_type as MeshBlockType
var position: Vector3i:
    set = set_position
var rotation: Rotation = Rotation.FORWARD_UP:
    set = set_rotation
var mesh_entity: MeshEntity

func _entity_init() -> void:
    super._entity_init()
    var current = self
    while current:
        if current is MeshEntity:
            mesh_entity = current
            break
        current = current.parent_entity
    assign_blocks()

func _entity_deinit() -> void:
    unassign_blocks()
    mesh_entity = null
    super._entity_deinit()

func set_position(pos: Vector3i) -> void:
    if entity_active: unassign_blocks()
    position = pos
    update_transform()
    if entity_active: assign_blocks()

func set_rotation(rot: Rotation) -> void:
    if entity_active: unassign_blocks()
    rotation = rot
    update_transform()
    if entity_active: assign_blocks()

func update_transform() -> void:
    var base_origin = position * MESH_BLOCK_SIZE
    var origin = base_origin + mesh_block_type.origin_offset

    transform = Transform3D(rotation.basis, origin)

func assign_blocks() -> void:
    var offset = mesh_block_type.mesh_shape_offset
    for y in mesh_block_type.mesh_shape.size():
        var bitmap = mesh_block_type.mesh_shape[y]
        var size = bitmap.get_size()
        for x in size.x:
            for z in size.y:
                if not bitmap.get_bit(x, z): continue
                var pos = Vector3i(x, y, size.y - z - 1) + offset
                pos = Vector3i((rotation.basis * Vector3(pos)).round())
                pos += position
                mesh_entity.assign_mesh_block(pos, self)

func unassign_blocks() -> void:
    var offset = mesh_block_type.mesh_shape_offset
    for y in mesh_block_type.mesh_shape.size():
        var bitmap = mesh_block_type.mesh_shape[y]
        var size = bitmap.get_size()
        for x in size.x:
            for z in size.y:
                if not bitmap.get_bit(x, z): continue
                var pos = Vector3i(x, y, size.y - z - 1) + offset
                pos = Vector3i((rotation.basis * Vector3(pos)).round())
                pos += position
                mesh_entity.unassign_mesh_block(pos)


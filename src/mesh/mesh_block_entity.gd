class_name MeshBlockEntity
extends PartialPhysicsEntity

const MESH_BLOCK_SIZE = MeshEntity.MESH_BLOCK_SIZE

static func get_type() -> ObjectType:
    return (MeshBlockEntity as Object).get_meta(OBJECT_TYPE_META)

var mesh_block_type: MeshBlockType:
    get: return object_type as MeshBlockType
var position: Vector3i



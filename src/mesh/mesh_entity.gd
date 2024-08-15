class_name MeshEntity
extends StandalonePhysicsEntity

const MESH_BLOCK_SIZE = 0.5

static func get_type() -> ObjectType:
    return (MeshEntity as Object).get_meta(OBJECT_TYPE_META)



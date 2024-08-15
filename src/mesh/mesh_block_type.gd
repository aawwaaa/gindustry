class_name MeshBlockType
extends PhysicsEntityType

const MESH_BLOCK_SIZE = MeshEntity.MESH_BLOCK_SIZE

## The offset from `position * MESH_BLOCK_SIZE` to the origin of the entity
@export var entity_center_offset: Vector3

## The offset from `position` to the left bottom corner of the bitmap
@export var mesh_shape_offset: Vector3i

## Every element is a layer in `height`(Y+ in relative), which is a plane in `width` and `depth`
@export var mesh_shape: Array[BitMap]


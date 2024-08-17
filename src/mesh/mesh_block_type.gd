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

# TODO import from scene, mesh_shape nodes

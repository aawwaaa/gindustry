class_name Chunk
extends Node

const CHUNK_SIZE = 32
const CHUNK_SIZE_VECTOR = Vector3.ONE * CHUNK_SIZE

var world: World
var chunk_pos: Vector3i
var tile_offset: Vector3i

var tiles_block_type_index: PackedInt32Array

var tiles_building_static_data: PackedInt64Array
var tiles_building_ref: PackedInt64Array

class_name MeshChunk
extends RefCounted

const CHUNK_SIZE_BITS = 5
const CHUNK_SIZE = 1 << CHUNK_SIZE_BITS
const MESH_BLOCKS_SIZE = CHUNK_SIZE ** 3

signal chunk_empty()

static func get_chunk_position(position: Vector3i) -> Vector3i:
    return Vector3i(position.x >> CHUNK_SIZE_BITS, \
            position.y >> CHUNK_SIZE_BITS, \
            position.z >> CHUNK_SIZE_BITS)
static func get_local_position(position: Vector3i) -> Vector3i:
    return Vector3i(position.x & (CHUNK_SIZE - 1), \
            position.y & (CHUNK_SIZE - 1), \
            position.z & (CHUNK_SIZE - 1))

var assigned_mesh_blocks: int = 0

var mesh_entity: MeshEntity

var mesh_blocks: PackedInt64Array
var chunk_position: Vector3i
var chunk_base_position: Vector3i:
    get: return chunk_position * CHUNK_SIZE

func _init(pos: Vector3i) -> void:
    chunk_position = pos

    mesh_blocks.resize(MESH_BLOCKS_SIZE)

func get_index(local_position: Vector3i) -> int:
    return local_position.y * CHUNK_SIZE * CHUNK_SIZE + local_position.z * CHUNK_SIZE + local_position.x

func assign_block(local_position: Vector3i, mesh_block: MeshBlockEntity) -> void:
    mesh_blocks[get_index(local_position)] = mesh_block.object_id
    assigned_mesh_blocks += 1

func unassign_block(local_position: Vector3i) -> void:
    mesh_blocks[get_index(local_position)] = 0
    assigned_mesh_blocks -= 1
    if assigned_mesh_blocks == 0:
        chunk_empty.emit()

func check_block(local_position: Vector3i) -> bool:
    return mesh_blocks[get_index(local_position)] != 0

func get_block(local_position: Vector3i) -> MeshBlockEntity:
    var object_id = mesh_blocks[get_index(local_position)]
    var object = Vars.objects.get_object_or_null(object_id)
    if object == null: return null
    if not (object is MeshBlockEntity):
        push_warning("Object {id} is not a MeshBlockEntity".format({id = object_id}))
        return null
    return object

func load_data(stream: Stream) -> Error:
    return _load_data(stream)

func save_data(stream: Stream) -> void:
    _save_data(stream)

func _load_data(stream: Stream) -> Error:
    return Utils.load_data_with_version(stream, [func():
        mesh_blocks = stream.get_var()
        if stream.get_error(): return stream.get_error()
        return OK
    ])

func _save_data(stream: Stream) -> void:
    Utils.save_data_with_version(stream, [func():
        stream.store_var(mesh_blocks, true)
    ])


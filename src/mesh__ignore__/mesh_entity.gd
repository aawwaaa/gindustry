class_name MeshEntity
extends StandalonePhysicsEntity

const MESH_BLOCK_SIZE = 1.0

static func get_type() -> ObjectType:
    return (MeshEntity as Object).get_meta(OBJECT_TYPE_META)

# Vector3i -> MeshChunk
var chunks: Dictionary

func get_chunk(position: Vector3i) -> MeshChunk:
    position = MeshChunk.get_chunk_position(position)
    if not chunks.has(position):
        chunks[position] = MeshChunk.new(position)
        chunks[position].chunk_empty.connect(\
                _on_chunk_empty.bind(chunks[position]))
    return chunks[position]

func assign_mesh_block(position: Vector3i, mesh_block: MeshBlockEntity) -> void:
    get_chunk(position).assign_block(MeshChunk.get_local_position(position), mesh_block)

func unassign_mesh_block(position: Vector3i) -> void:
    get_chunk(position).unassign_block(MeshChunk.get_local_position(position))

func check_block(position: Vector3i) -> bool:
    return get_chunk(position).check_block(MeshChunk.get_local_position(position))

func get_block(position: Vector3i) -> MeshBlockEntity:
    return get_chunk(position).get_block(MeshChunk.get_local_position(position))

func _on_chunk_empty(chunk: MeshChunk) -> void:
    chunks.erase(chunk.chunk_position)

func _load_data(stream: Stream) -> Error:
    var err = super._load_data(stream)
    if err: return err
    return Utils.load_data_with_version(stream, [func():
        chunks.clear()
        var size = stream.get_64()
        if stream.get_error(): return stream.get_error()
        for _1 in range(size):
            var position = stream.get_var()
            if stream.get_error(): return stream.get_error()
            if not (position is Vector3i): return ERR_INVALID_DATA
            var chunk = get_chunk(position)
            err = chunk.load_data(stream)
            if err: return err
        return OK
    ])

func _save_data(stream: Stream) -> void:
    super._save_data(stream)
    return Utils.save_data_with_version(stream, [func():
        var size = chunks.size()
        stream.store_64(size)
        for chunk in chunks.values():
            stream.store_var(chunk.chunk_position, true)
            chunk.save_data(stream)
        return OK
    ])


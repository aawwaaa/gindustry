class_name MeshEntity
extends StandalonePhysicsEntity

const MESH_BLOCK_SIZE = 0.5

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

func assign_block(position: Vector3i, mesh_block: MeshBlockEntity) -> void:
    get_chunk(position).assign_block(MeshChunk.get_local_position(position), mesh_block)

func unassign_block(position: Vector3i) -> void:
    get_chunk(position).unassign_block(MeshChunk.get_local_position(position))

func check_block(position: Vector3i) -> bool:
    return get_chunk(position).check_block(MeshChunk.get_local_position(position))

func get_block(position: Vector3i) -> MeshBlockEntity:
    return get_chunk(position).get_block(MeshChunk.get_local_position(position))

func _on_chunk_empty(chunk: MeshChunk) -> void:
    chunks.erase(chunk.chunk_position)


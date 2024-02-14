extends ChunkLoadSource

func _load_chunk(chunk_pos: Vector2) -> Chunk:
    var chunk = world.init_chunk_for(chunk_pos);
    for x in range(Global.CHUNK_SIZE):
        for y in range(Global.CHUNK_SIZE):
            chunk.get_tile(Vector2i(x, y)).set_floor(Gindustry.floors.grass)
            if randf() > 0.95:
                chunk.get_tile(Vector2i(x, y)).set_overlay(Gindustry.overlays.ore_copper)
            if randf() > 0.95:
                chunk.get_tile(Vector2i(x, y)).set_overlay(Gindustry.overlays.ore_lead)
    return chunk;

extends ItemUse

func _process(delta: float) -> void:
	pass
	
func _set_position(pos: Vector2) -> void:
	position = Tile.floor_to_tile_grid(pos) + Tile.HALF_TILE

func _use() -> void:
	var tile_pos = (position / Global.TILE_SIZE).floor()
	var tile = world.get_tile_or_null(tile_pos)
	if not tile: return queue_free()
	var removed = remove_items(1);
	removed.queue_free()
	tile.set_floor(item.item_type.floor_type)
	queue_free()

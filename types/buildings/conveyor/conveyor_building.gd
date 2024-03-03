extends Building

func _get_adapter_at(pos: Vector2i, rot: int, type: String) -> EntityAdapter:
    if pos != Vector2i.ZERO: return null
    return adapters["item"]

func get_component_at(pos: Vector2i, rot: int, type: String) -> BuildingComponent:
    if pos != tile_pos: return null
    return main_node

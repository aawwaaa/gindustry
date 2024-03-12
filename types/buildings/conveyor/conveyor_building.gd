extends Building

func _get_adapter_at(pos: Vector2i, type: String) -> EntityAdapter:
    if pos != Vector2i.ZERO or type != "item": return null
    return adapters["item"]

func get_component_at(pos: Vector2i, rot: int, type: String) -> BuildingComponent:
    if pos != tile_pos: return null
    return main_node

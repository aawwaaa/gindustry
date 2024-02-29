class_name Consumer
extends Resource

func _save_data(data: Variant, stream: Stream) -> void:
    pass

func save_data(data: Variant, stream: Stream) -> void:
    return _save_data(data, stream)

func _load_data(stream: Stream) -> Variant:
    return null

func load_data(stream: Stream) -> Variant:
    return _load_data(stream)

func _init_data() -> Variant:
    return null

func init_data() -> Variant:
    return _init_data()

func _get_type() -> ConsumerType:
    return null

func get_type() -> ConsumerType:
    return _get_type()

func _should_begin(building: Building, data: Variant) -> bool:
    return true

func should_begin(building: Building, data: Variant) -> bool:
    return _should_begin(building, data)

func _process_begin(building: Building, data: Variant) -> Variant:
    return null

func process_begin(building: Building, data: Variant) -> Variant:
    return _process_begin(building, data)

func _get_effectity(building: Building, data: Variant, delta: float) -> float:
    return 1

func get_effectity(building: Building, data: Variant, delta: float) -> float:
    return _get_effectity(building, data, delta)

func _process_update(building: Building, data: Variant, delta: float, effectity: float) -> void:
    pass

func process_update(building: Building, data: Variant, delta: float, effectity: float) -> void:
    return _process_update(building, data, delta, effectity)

func _process_break(building: Building, data: Variant) -> Variant:
    return null

func process_break(building: Building, data: Variant) -> Variant:
    return _process_begin(building, data)

func _process_finish(building: Building, data: Variant) -> Variant:
    return null

func process_finish(building: Building, data: Variant) -> Variant:
    return _process_finish(building, data)

func _display_ui(building: Building, data: Variant, node: Control) -> Variant:
    return null

func display_ui(building: Building, data: Variant, node: Control) -> Variant:
    return _display_ui(building, data, node)

func _check_recipe(building: Building, data: Variant) -> bool:
    return true

func check_recipe(building: Building, data: Variant) -> bool:
    return _check_recipe(building, data)


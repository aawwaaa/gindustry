class_name Provider
extends Resource

func _get_type() -> ProviderType:
    return null

func get_type() -> ProviderType:
    return _get_type()

func _should_begin(building: Building) -> bool:
    return true

func should_begin(building: Building) -> bool:
    return _should_begin(building)

func _process_begin(building: Building) -> Variant:
    return null

func process_begin(building: Building) -> Variant:
    return _process_begin(building)

func _get_effectity(building: Building, delta: float) -> float:
    return 1

func get_effectity(building: Building, delta: float) -> float:
    return _get_effectity(building, delta)

func _process_update(building: Building, delta: float, effectity: float) -> void:
    pass

func process_update(building: Building, delta: float, effectity: float) -> void:
    return _process_update(building, delta, effectity)

func _process_break(building: Building) -> Variant:
    return null

func process_break(building: Building) -> Variant:
    return _process_begin(building)

func _process_finish(building: Building) -> Variant:
    return null

func process_finish(building: Building) -> Variant:
    return _process_finish(building)

func _display_ui(building: Building, node: Control) -> Variant:
    return null

func display_ui(building: Building, node: Control) -> Variant:
    return _display_ui(building, node)

func _check_recipe(building: Building) -> bool:
    return true

func check_recipe(building: Building) -> bool:
    return _check_recipe(building)

func _pre_check_recipe(building_type: BuildingType) -> bool:
    return true

func pre_check_recipe(building_type: BuildingType) -> bool:
    return _pre_check_recipe(building_type)

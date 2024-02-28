class_name AdapterUnitType
extends Resource

var adapter_unit_scene: PackedScene:
    get = _get_adapter_unit_scene

func _get_adapter_unit_scene() -> PackedScene:
    return null

func create_adapter_unit(adapter: EntityAdapter) -> AdapterUnit:
    var inst = adapter_unit_scene.instantiate()
    inst.adapter_unit_type = self
    inst.adapter = adapter
    return inst

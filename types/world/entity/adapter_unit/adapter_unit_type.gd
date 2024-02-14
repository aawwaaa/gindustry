class_name AdapterUnitType
extends Resource

@export var adapter_unit_scene: PackedScene

func create_adapter_unit(adapter: EntityAdapter) -> AdapterUnit:
    var inst = adapter_unit_scene.instantiate()
    inst.adapter_unit_type = self
    inst.adapter = adapter
    return inst

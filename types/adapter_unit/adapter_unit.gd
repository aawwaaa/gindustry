class_name AdapterUnit
extends Node2D

var entity: Entity:
    get: return adapter.entity_node
var world: World:
    get: return entity.world
var adapter: EntityAdapter;
var adapter_unit_type: AdapterUnitType;

func _init_unit() -> void:
    pass

func _load_data(stream: Stream) -> void:
    pass

func _save_data(stream: Stream) -> void:
    pass

func init_unit() -> void:
    _init_unit()

func load_data(stream: Stream) -> void:
    _load_data(stream)

func save_data(stream: Stream) -> void:
    _save_data(stream)

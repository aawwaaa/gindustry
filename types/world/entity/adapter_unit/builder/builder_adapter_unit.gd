class_name BuilderAdapterUnit
extends AdapterUnit

var type: BuilderAdapterUnitType:
    get: return adapter_unit_type

func _ready() -> void:
    entity.layer_changed.connect(_on_layer_changed)
    _on_layer_changed(entity.layer, 0)
    %CollisionShape2D.shape = type.build_range

func _on_layer_changed(layer: int, from: int) -> void:
    var mask = entity.get_collision_mask(type.build_range_layer_begin, type.build_range_layer_end)
    $Area2D.collision_mask = mask
    $Area2D.collision_layer = mask

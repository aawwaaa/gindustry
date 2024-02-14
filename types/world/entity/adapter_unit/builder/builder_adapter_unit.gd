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

func check_access_range(world: World, target: Vector2) -> bool:
    if world != self.world: return false
    var distance = entity.position.distance_to(target)
    var shape = %CollisionShape2D.shape
    if not (shape is CircleShape2D): return false
    return distance < shape.radius

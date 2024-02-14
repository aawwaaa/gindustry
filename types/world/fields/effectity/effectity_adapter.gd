class_name EffectityAdapter
extends EntityAdapter

func get_effectity() -> float:
    var fields = $Area2D.get_overlapping_areas()
    var max = 1.0
    for field in fields:
        var parent_node = field.get_parent()
        max = max(parent_node.get_field_effectity(), max)
    return max

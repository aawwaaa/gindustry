class_name BuilderAdapter
extends EntityAdapter

@export var builder_unit_positions: Array[Marker2D] = [];
@export var builder_type: BuilderAdapterUnitType;

var units: Array[BuilderAdapterUnit] = []

func _enter_tree() -> void:
    for marker in builder_unit_positions:
        if marker.get_child_count() != 0: continue
        var unit = builder_type.create_adapter_unit(self)
        unit._init_unit()
        units.append(unit)
        marker.add_child(unit)

func _should_save_data() -> bool:
    return true

func _load_data(stream: Stream) -> void:
    Utils.load_data_with_version(stream, [func():
        for index in range(stream.get_16()):
            var mark = builder_unit_positions[index]
            if mark.get_child_count() == 0:
                var unit = builder_type.create_adapter_unit(self)
                units.append(unit)
                mark.add_child(unit)
            var unit = units[index]
            unit._load_data(stream),
    ])

func _save_data(stream: Stream) -> void:
    Utils.save_data_with_version(stream, [func():
        stream.store_16(units.size())
        for unit in units:
            unit._save_data(stream),
    ])

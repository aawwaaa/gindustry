class_name Building
extends Entity

signal placed()
signal destroyed()

@export var shadow_container: Node2D
@export_group("callbacks", "callback_")
@export var callback_get_adapter_at: StringName = "";
@export var callback_get_component_at: StringName = "";
@export var callback_handle_break: StringName = ""

@export var callback_get_config: StringName = "";
@export var callback_set_config: StringName = "";

var building_type: BuildingType:
    get: return entity_type if entity_type is BuildingType else null
var building_config: Variant:
    get: return main_node.call(callback_get_config) if callback_get_config != "" else building_config
    set(v): 
        if callback_set_config != "": 
            main_node.call(callback_set_config, v)
        else:
            building_config = v
var shadow: BuildingShadow
var shadow_inited: bool = false;

var pos: Vector2i;
var rot: int;

var should_place: bool = false
var should_destroy: bool = false

func _ready() -> void:
    super._ready()

    layer_changed.connect(_on_layer_changed)
    main_node.position = Tile.to_world_pos(pos)
    main_node.rotation = Tile.to_entity_rot(rot)
    shadow = building_type.create_shadow()
    shadow.world = world
    shadow.pos = pos
    shadow.building_config = building_config
    shadow.layer = layer
    await get_tree().process_frame
    shadow_container.add_child(shadow)
    shadow.rot = rot
    shadow.finish_build(self)
    shadow_inited = true
    shadow.input_mouse_entered.connect(_on_collision_object_2d_mouse_entered)
    shadow.input_mouse_exited.connect(_on_collision_object_2d_mouse_exited)

    if should_place: place()
    if should_destroy: destroy()

func _on_layer_changed(layer: int, from: int) -> void:
    if not shadow: return
    shadow.layer = layer
    main_node.z_as_relative = false
    main_node.z_index = get_z_index(0)

func place() -> void:
    if not shadow_inited:
        should_place = true
        return
    should_place = false
    shadow.place(false, entity_id)
    placed.emit()

func destroy() -> void:
    if not shadow_inited:
        should_destroy = true
        return
    should_destroy = false
    shadow.destroy(false, entity_id)
    destroyed.emit()

func _handle_break(unit: BuilderAdapterUnit) -> bool:
    if not accept_access(unit.adapter.entity_node.main_node): return false
    if callback_handle_break != "" and not main_node.call(callback_handle_break, unit): return false
    for adapter in adapters:
        if not get_adapter(adapter)._handle_break(unit): return false
    return true

func handle_break(unit: BuilderAdapterUnit) -> bool:
    return _handle_break(unit)

func _handle_destroy() -> void:
    pass

func handle_destroy() -> void:
    _handle_destroy()

func _can_be_replaced_by(building_type: BuildingType) -> bool:
    return self.building_type._can_be_replaced_by(self, building_type)

func can_be_replaced_by(building_type: BuildingType) -> bool:
    return _can_be_replaced_by(building_type)

func _get_attribute(type: BuildingAttributeType) -> BuildingAttribute:
    return building_type.get_attribute(type)

func get_attribute(type: BuildingAttributeType) -> BuildingAttribute:
    return _get_attribute(type)

func _get_consumers() -> Array[Consumer]:
    return [] as Array[Consumer]

func get_consumers() -> Array[Consumer]:
    return _get_consumers()

func _get_providers() -> Array[Provider]:
    return [] as Array[Provider]

func get_providers() -> Array[Provider]:
    return _get_providers()

func get_local_pos(tile_pos: Vector2i) -> Vector2i:
    var delta = tile_pos - self.tile_pos
    return delta.rotated(-Tile.to_entity_rot(shadow.rot))

func get_adapter_at(pos: Vector2i, type: String) -> EntityAdapter:
    if callback_get_adapter_at == "": return null
    return main_node.call(callback_get_adapter_at, get_local_pos(pos), type)

func get_component_at(pos: Vector2i, rot: int, type: String, ignore_side = false) -> BuildingComponent:
    if callback_get_component_at != "": return main_node.call(callback_get_component_at, pos, rot, type, ignore_side)
    if not shadow.pos_to_component.has(pos): return null
    if not shadow.pos_to_component[pos].has(type): return null
    var component: BuildingComponent = shadow.pos_to_component[pos][type]
    var side = BuildingComponent.ROT_TO_SIDE[rot]
    if not ignore_side and not component.has_side(side): return null
    return component

func _load_data(stream: Stream) -> void:
    Utils.load_data_with_version(stream, [func():
        building_type = Contents.get_content_by_index(stream.get_64()) as BuildingType
        pos = stream.get_var()
        rot = stream.get_8()
        building_config = building_type._load_config(stream)
    ])

func _save_data(stream: Stream) -> void:
    Utils.save_data_with_version(stream, [func():
        stream.store_64(building_type.index)
        stream.store_var(pos, true)
        stream.store_8(rot)
        building_type._save_config(building_config, stream)
    ])

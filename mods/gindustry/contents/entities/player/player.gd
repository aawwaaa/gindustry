extends CharacterBody2D

@export var entity: Entity

const max_speed = 500;

func _process(_delta: float) -> void:
    %ControllerAdapter.update_control("build", %BuilderAdapter.update_building.bind())

func _physics_process(_delta: float) -> void:
    %ControllerAdapter.update_control("move", %ControllerAdapter.update_velocity.bind(max_speed))
    move_and_slide()

func _on_controller_adapter_controller_added(_controller: Controller) -> void:
    %PlayerName.visible = %ControllerAdapter.update_control("name", update_name)

func update_name(controller: Controller, _adapter: ControllerAdapter) -> void:
    %PlayerName.text = controller._get_name()

func get_entity() -> Entity:
    return entity;

func _on_entity_layer_changed(_layer: int, _from: int) -> void:
    z_index = get_entity().get_z_index(0)
    %PlayerName.z_index = get_entity().get_z_index(1)
    var mask = get_entity().get_collision_mask(0, 0);
    collision_layer = mask;
    collision_mask = mask;
    var floor_mask = get_entity().get_collision_mask(-Global.MAX_LAYERS, -1);
    platform_floor_layers = floor_mask
    var access_range_mask = get_entity().get_collision_mask(-1, 1);
    get_entity().access_range.collision_layer = access_range_mask
    get_entity().access_range.collision_mask = access_range_mask

func get_attribute(key: String) -> Variant:
    match key:
        "position":
            return global_position
        "rotation":
            return global_rotation
    return null

func _on_controller_adapter_operation_received(operation: String, args: Array) -> void:
    pass

func _on_entity_on_load_data(stream: Stream) -> void:
    Utils.load_data_with_version(stream, [])

func _on_entity_on_save_data(stream: Stream) -> void:
    Utils.save_data_with_version(stream, [])

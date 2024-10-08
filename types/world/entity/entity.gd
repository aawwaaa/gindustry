class_name Entity
extends Node

signal layer_changed(layer: int, from: int)
signal on_save_data(stream: Stream);
signal on_load_data(stream: Stream);

signal access_target_changed(target: Node2D, from: Node2D)
signal access_from(source: Node2D, removed: bool)

static var entity_ref_targets: Dictionary = {}

var entity_type: EntityType;

@export var main_node: Node2D;
"""
可用:
    - controller(ControllerAdapter)
    - item(ItemAdapter-物品)
    - inventory(Inventory-物品栏)
    - item_source(ItemAdapter-物品来源)
    - item_target(ItemAdapter-物品目标)
"""
@export var adapters: Dictionary = {}

@export var child_entities_main_node: Array[Node2D];

var parent_entity: Entity;
var access_target: Node2D:
    set(v):
        var old = access_target
        access_target = v
        access_target_changed.emit(v, old)

@export var access_range: Area2D;
var world: World:
    get = get_world,
    set = set_world;

var has_entity_id: bool = false
var entity_id: int:
    set(v):
        if not has_entity_id:
            has_entity_id = true
            for node in child_entities_main_node:
                node.get_entity().init_entity()
        entity_id = v;
        main_node.name = "Entity#" + str(v);


@export var layer_follow_world: bool = false
@export var layer: int:
    get = get_layer,
    set = set_layer;

var tile_pos: Vector2:
    get: return (main_node.position / Global.TILE_SIZE).floor()

static func _on_game_signal_reset_game() -> void:
    entity_ref_targets = {};

static func get_entity_by_ref(target_id: int, callback: Callable) -> void:
    if target_id == 0:
        callback.call(null)
        return
    if entity_ref_targets.has(target_id) and entity_ref_targets[target_id] is Entity:
        callback.call(entity_ref_targets[target_id])
        return
    if not entity_ref_targets.has(target_id):
        entity_ref_targets[target_id] = []
    entity_ref_targets[target_id].append(callback)

static func get_entity_by_ref_or_null(target_id: int) -> Entity:
    if target_id == 0:
        return null
    if entity_ref_targets.has(target_id) and entity_ref_targets[target_id] is Entity:
        return entity_ref_targets[target_id]
    return null

func _exit_tree() -> void:
    entity_ref_targets.erase(entity_id)

func get_world() -> World:
    if parent_entity:
        return parent_entity.world
    return world

func get_layer() -> int:
    if layer_follow_world:
        if not world: return layer
        return layer + world.layer
    return layer

func set_layer(v: int) -> void:
    var old = layer;
    layer = clampi(0, v, Global.MAX_LAYERS);
    for node in child_entities_main_node:
        node.get_entity().set_layer(layer)
    if is_inside_tree():
        layer_changed.emit(layer, old);

func set_world(v: World) -> void:
    if parent_entity:
        return parent_entity.set_world(world)
    if world:
        world.get_entities_node().remove_child(main_node);
        world.layer_changed.disconnect(_on_world_layer_changed)
    world = v;
    world.layer_changed.connect(_on_world_layer_changed);
    world.get_entities_node().add_child(main_node);

func has_adapter(adapter: String) -> bool:
    return adapters.has(adapter)

func get_adapter(adapter: String) -> Node:
    return get_node(adapters[adapter]) if has_adapter(adapter) else null

func get_collision_mask(begin: int, end: int) -> int:
    return get_collision_mask_static(layer, begin, end)

static func get_collision_mask_static(layer: int, begin: int, end: int) -> int:
    begin = clampi(begin + layer, 0, Global.MAX_LAYERS);
    end = clampi(end + layer, 0, Global.MAX_LAYERS);
    var delta = end - begin + 1;
    var mask = (1 << delta) - 1;
    return mask << begin

func _on_world_layer_changed(new_layer: int, from: int) -> void:
    if not layer_follow_world:
        return;
    set_layer(layer - world.layer)

func init_entity() -> void:
    entity_id = Game.entity_inc_id;
    Game.entity_inc_id += 1;

func get_z_index(offset: int) -> int:
    return 32 * (world.layer + layer + offset)

func _ready() -> void:
    for node in child_entities_main_node:
        node.get_entity().parent_entity = self
    layer_changed.emit(layer, 0);
    if entity_ref_targets.has(entity_id):
        for callback in entity_ref_targets[entity_id]:
            callback.call(self)
    entity_ref_targets[entity_id] = self

func _on_access_range_body_exited(body: Node2D) -> void:
    if body == access_target:
        access_target = null

func accept_access(_from: Node2D) -> bool:
    return true

func request_access_target(body: Node2D) -> bool:
    if access_target == body:
        return true
    if access_range and not access_range.get_overlapping_bodies().has(body):
        return false
    if not body.get_entity().accept_access(main_node):
        return false
    access_target = body
    body.get_entity().access_from.emit(main_node, false)
    return true

func clear_access_target() -> void:
    if access_target:
        access_target.get_entity().access_to.emit(main_node, true)
    access_target = null

func check_access_range(target_world: World, target_position: Vector2) -> bool:
    if not access_range:
        return true
    if world != target_world:
        return false
    var shape = access_range.get_node("CollisionShape2D").shape
    if not(shape is CircleShape2D):
        return true
    var radius = shape.radius
    var distance = main_node.position.distance_to(target_position)
    return distance < radius
    # var body = target_world.create_temp_physics_body(target_position)
    # body.force_update_transform()
    # await get_tree().physics_frame
    # await get_tree().physics_frame
    # var bodies = access_range.get_overlapping_bodies()
    # var result = bodies.has(body)
    # body.queue_free()
    # return result

func remove() -> void:
    world.remove_entity(self)
    main_node.queue_free()

static func load_from(stream: Stream) -> Entity:
    var data_entity_type = Contents.get_content_by_index(stream.get_32()) as EntityType;
    var entity = data_entity_type.create_entity(false);
    entity.load_data(stream);
    return entity;

func save_to(stream: Stream) -> void:
    stream.store_32(entity_type.index);
    save_data(stream);

func _load_data(stream: Stream) -> void:
    pass

func _save_data(stream: Stream) -> void:
    pass

const current_data_version = 3;

func load_data(stream: Stream) -> void:
    Utils.load_data_with_version(stream, [func():
        has_entity_id = true
        entity_id = stream.get_64();
        main_node.position = stream.get_var();
        main_node.rotation = stream.get_float();
        layer = stream.get_8();
        layer_follow_world = stream.get_8() == 1;

        for node in child_entities_main_node:
            var entity = node.get_entity()
            entity.parent_entity = self
            entity.load_data(stream)

        Entity.get_entity_by_ref(stream.get_64(), func(entity): access_target = entity),
    ])
    _load_data(stream)
    on_load_data.emit(stream)

func save_data(stream: Stream) -> void:
    Utils.save_data_with_version(stream, [func():
        stream.store_64(entity_id);
        stream.store_var(main_node.position, true);
        stream.store_float(main_node.rotation);
        stream.store_8(layer);
        stream.store_8(1 if layer_follow_world else 0);

        for node in child_entities_main_node:
            var entity = node.get_entity()
            entity.save_data(stream)

        stream.store_64(0 if access_target == null else access_target.entity_id);
    ])
    _save_data(stream)
    on_save_data.emit(stream)

class_name Entity
extends RefObject

signal transform_changed(source: Entity)
signal child_entity_added(entity: Entity)
signal child_entity_removed(entity: Entity)

const TARGET_SELF = &"self"

const SNAPSHOT_SYNC_INTERVAL = 15.0
const SNAPSHOT_CHANGED_SYNC_INTERVAL = 0.5

static var logger: Log.Logger

var parent_entity: Entity:
    set = set_parent_entity
var child_entities: Array[Entity] = []
var __world: World
var world: World:
    get: return self if self is World else parent_entity.world if parent_entity else __world
    set(v): __world = v; for child in child_entities: child.world = v
var root_world: World:
    get: return self if self is World and self.is_root_world \
            else __world if __world and __world.is_root_world \
            else parent_entity.root_world
var transform: Transform3D:
    set = set_transform
var entity_type: EntityType:
    get: return object_type as EntityType

var entity_active = false

var components: Dictionary = {}
var components_id: Dictionary = {}
var access_source: AccessOperation.EntityAccessSource = \
        AccessOperation.EntityAccessSource.new(self)

var last_snapshot_sync: float = 0.0
var last_snapshot_data: PackedByteArray

static func get_type() -> ObjectType:
    return (Entity as Object).get_meta(OBJECT_TYPE_META)

static func __script__init() -> void:
    logger = Log.register_logger("Entity_LogSource")

func _init() -> void:
    _components_init()

func set_parent_entity(new_parent: Entity) -> void:
    if object_ready: entity_deinit()
    if parent_entity: parent_entity.handle_remove_child_entity(self)
    parent_entity = new_parent
    if parent_entity: parent_entity.handle_add_child_entity(self)
    if object_ready: entity_init()
    transform_changed.emit()

func get_component(comp_name: StringName) -> EntityComponent:
    return components[comp_name]

func has_component(comp_name: StringName) -> bool:
    return components.has(comp_name)

func get_component_by_id(id: int) -> EntityComponent:
    return components_id[id]

func has_component_id(id: int) -> bool:
    return components_id.has(id)

func _components_init() -> void:
    pass

func entity_init() -> void:
    for child in child_entities:
        child.entity_init()
    _entity_init()
    entity_active = true

func entity_deinit() -> void:
    entity_active = false
    for child in child_entities:
        child.entity_deinit()
    _entity_deinit()

func _entity_init() -> void:
    for component in components.values():
        component._component_init()
    _on_transform_changed(self)

func _entity_deinit() -> void:
    for component in components.values():
        component._component_deinit()

func add_child_entity(entity: Entity) -> void:
    entity.parent_entity = self

func remove_child_entity(entity: Entity) -> void:
    if entity.parent_entity != self: return
    entity.parent_entity = null

func handle_add_child_entity(entity: Entity) -> void:
    child_entities.append(entity)
    child_entity_added.emit(entity)

func handle_remove_child_entity(entity: Entity) -> void:
    child_entities.erase(entity)
    child_entity_removed.emit(entity)

func get_global_transform() -> Transform3D:
    if parent_entity == null: return transform
    return parent_entity.get_global_transform() * transform

func get_relative_transform(entity: Entity) -> Transform3D:
    if parent_entity == null: return transform
    if entity == self: return Transform3D.IDENTITY
    return parent_entity.get_relative_transform(entity) * transform

func set_transform(new_transform: Transform3D) -> void:
    transform = new_transform
    transform_changed.emit(self)

func _on_transform_changed(source: Entity) -> void:
    for child in child_entities:
        child.transform_changed.emit(source)

func add_component(comp: EntityComponent, \
        parent_comp: EntityComponent = null, \
        comp_name: StringName = comp._get_default_component_name()) -> void:
    comp.init(self, comp_name, parent_comp)
    components[comp_name] = comp
    components_id[comp.component_id] = comp

func _object_create() -> void:
    super._object_create()

func _object_init() -> void:
    super._object_init()
    transform_changed.connect(_on_transform_changed)

func _object_ready() -> void:
    if object_ready: return
    super._object_ready()
    if parent_entity: entity_init()

func object_free() -> void:
    entity_deinit()
    super.object_free()

func _object_free() -> void:
    for component in components.values():
        component.queue_free()
    super._object_free()

func _physics_process(_delta: float) -> void:
    if not entity_active: return
    snapshot_update()

func snapshot_sync_rpc(data: PackedByteArray) -> void:
    if Vars.server.server_active(): return
    Vars.temp.bas.load(data)
    var err = _snapshot_load(Vars.temp.bas)
    if err != OK:
        logger.warn(tr("Entity_SnapshotLoadError {id} {error} {str}").format({
            "id" = object_id,
            "error" = error_string(err),
            "str" = str(self)
        }))
    Vars.temp.bas.clear()

func snapshot_update() -> void:
    if not Vars.server.server_active(): return
    Vars.temp.bas.load(last_snapshot_data)
    var check_result = _snapshot_check(Vars.temp.bas)
    Vars.temp.bas.clear()
    var interval = SNAPSHOT_CHANGED_SYNC_INTERVAL if check_result \
            else SNAPSHOT_SYNC_INTERVAL
    if last_snapshot_sync + interval >= Vars.server.time: return
    last_snapshot_sync = Vars.server.time
    _snapshot_save(Vars.temp.bas)
    last_snapshot_data = Vars.temp.bas.submit()
    Vars.temp.bas.clear()
    sync("snapshot_sync_rpc", [last_snapshot_data])

## return true if something is changed
func _snapshot_check(stream: Stream) -> bool:
    if not transform.is_equal_approx(stream.get_var()): return true
    return false

func _snapshot_save(stream: Stream) -> void:
    stream.store_var(transform, true)

func _snapshot_load(stream: Stream) -> Error:
    transform = stream.get_var()
    if stream.get_error(): return stream.get_error()
    return OK

func _check_access_source(_source: AccessOperation.AccessSource) -> bool:
    return true

func _check_access(_source: AccessOperation.AccessSource, \
        _method: StringName, _args: Array[Variant]) -> bool:
    return _check_access_source(_source)

func _check_access_component(_source: AccessOperation.AccessSource, \
        _comp: EntityComponent, _method: StringName, _args: Array[Variant]) -> bool:
    return _check_access_source(_source)

func _handle_access(_source: AccessOperation.AccessSource, \
        _method: StringName, _args: Array[Variant]) -> void:
    pass

func access_to(target: Variant, method: StringName, args: Array[Variant]) -> void:
    AccessOperation.handle_access(access_source, target, method, args)

func access_to_self(method: StringName, args: Array[Variant]) -> void:
    access_to(self, method, args)

func _controller_feedback(control_handle: ControlHandleComponent) -> void:
    var movement = control_handle.get_module(Controller.MovementModule.TYPE)
    if movement:
        movement.entity_basis = transform.basis

func _load_data(stream: Stream) -> Error:
    var err = super._load_data(stream)
    if err: return err
    return Utils.load_data_with_version(stream, [func():
        var tran = stream.get_var()
        if stream.get_error(): return stream.get_error()
        if not (tran is Transform3D): return ERR_INVALID_DATA
        transform = tran

        var size = stream.get_64()
        if stream.get_error(): return stream.get_error()
        for _1 in range(size):
            var component_id = stream.get_32()
            if stream.get_error(): return stream.get_error()
            if not components_id.has(component_id): return ERR_INVALID_DATA
            var comp = components_id[component_id]
            err = comp.load_data(stream)
            if err: return err

        size = stream.get_64()
        if stream.get_error(): return stream.get_error()
        for _1 in range(size):
            var object = Vars.objects.load_object(stream)
            if Vars.objects.err: return Vars.objects.err
            if not (object is Entity): return ERR_INVALID_DATA
            add_child_entity(object)
        return OK
    ])

func _save_data(stream: Stream) -> void:
    super._save_data(stream)
    Utils.save_data_with_version(stream, [func():
        stream.store_var(transform, true)

        stream.store_64(components.size())
        for comp in components.values():
            stream.store_32(comp.component_id)
            comp.save_data(stream)
        
        stream.store_64(child_entities.size())
        for child in child_entities:
            Vars.objects.save_object(stream, child)
    ])

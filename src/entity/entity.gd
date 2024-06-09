class_name Entity
extends RefObject

signal transform_changed()
signal child_entity_added(entity: Entity)
signal child_entity_removed(entity: Entity)

const TARGET_SELF = &"self"

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

var components: Dictionary = {}
var components_id: Dictionary = {}
var access_source: AccessOperation.EntityAccessSource = \
        AccessOperation.EntityAccessSource.new(self)

static func get_type() -> ObjectType:
    return (Entity as Object).get_meta(OBJECT_TYPE_META)

func _init() -> void:
    _components_init()

func set_parent_entity(new_parent: Entity) -> void:
    if object_ready: _entity_deinit()
    if parent_entity: parent_entity.handle_remove_child_entity(self)
    parent_entity = new_parent
    if parent_entity: parent_entity.handle_add_child_entity(self)
    if object_ready: _entity_init()
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

func _entity_init() -> void:
    for component in components.values():
        component._component_init()

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

func set_transform(new_transform: Transform3D) -> void:
    transform = new_transform
    transform_changed.emit()

func _on_transform_changed() -> void:
    for child in child_entities:
        child.transform_changed.emit()

func add_component(comp: EntityComponent, \
        comp_name: StringName = comp._get_default_component_name(), \
        parent_comp: EntityComponent = null) -> void:
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
    _entity_init()

func _object_free() -> void:
    _entity_deinit()
    for component in components.values():
        component.queue_free()
    super._object_free()

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

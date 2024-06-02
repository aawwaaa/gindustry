class_name Entity
extends RefObject

signal transform_changed()
signal child_entity_added(entity: Entity)
signal child_entity_removed(entity: Entity)

static var entity_object_type: GDScriptObjectType

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

static func _static_init() -> void:
    entity_object_type = GDScriptObjectType.add("entity", Entity)

static func get_type() -> ObjectType:
    return entity_object_type

func set_parent_entity(new_parent: Entity) -> void:
    if object_ready: _entity_deinit()
    if parent_entity: parent_entity.handle_remove_child_entity(self)
    parent_entity = new_parent
    if parent_entity: parent_entity.handle_add_child_entity(self)
    if object_ready: _entity_init()
    transform_changed.emit()

func _entity_init() -> void:
    pass

func _entity_deinit() -> void:
    pass

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
    super._object_free()

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
        stream.store_64(child_entities.size())
        for child in child_entities:
            Vars.objects.save_object(stream, child)
    ])

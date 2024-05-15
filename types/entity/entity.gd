class_name Entity
extends Vars_Objects.RefObject

signal transform_changed()
signal child_entity_added(entity: Entity)
signal child_entity_removed(entity: Entity)

static var entity_object_type: Vars_Objects.GDScriptObjectType

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
    entity_object_type = Vars_Objects.GDScriptObjectType.new()
    entity_object_type.uuid = "gindustry-builtin-entity"
    entity_object_type.type_script = Entity
    Vars_Objects.add_object_type(entity_object_type)

static func get_type() -> Vars_Objects.ObjectType:
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

func _load_data(stream: Stream) -> void:
    super._load_data(stream)

func _save_data(stream: Stream) -> void:
    super._save_data(stream)

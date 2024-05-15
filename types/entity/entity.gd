class_name Entity
extends Vars_Objects.RefObject

signal transform_changed()
signal child_entity_added(entity: Entity)
signal child_entity_removed(entity: Entity)

static var entity_object_type: Vars_Objects.GDScriptObjectType

var parent_entity: Entity:
    set = set_parent_entity
var child_entities: Array[Entity] = []
var world: World:
    get: return self if self is World else parent_entity.world if parent_entity else world
    set(v): world = v; for child in child_entities: child.world = v
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
    if parent_entity: parent_entity.remove_child_entity(self)
    parent_entity = new_parent
    if parent_entity: parent_entity.add_child_entity(self)

func add_child_entity(entity: Entity) -> void:
    child_entities.append(entity)
    entity.parent_entity = self
    child_entity_added.emit(entity)

func remove_child_entity(entity: Entity) -> void:
    child_entities.erase(entity)
    entity.parent_entity = null
    child_entity_removed.emit(entity)

func get_global_transform() -> Transform3D:
    return (parent_entity.get_global_transform() if parent_entity else 1) * transform

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

func _object_free() -> void:
    super._object_free()

func _load_data(stream: Stream) -> void:
    super._load_data(stream)

func _save_data(stream: Stream) -> void:
    super._save_data(stream)

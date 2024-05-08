class_name Entity
extends Vars_Objects.RefObject

signal data_changed(data_type: StringName)

static var entity_object_type: Vars_Objects.GDScriptObjectType

var parent_entity: Entity:
    set = set_parent_entity
var child_entities: Array[Entity] = []
var world: World:
    get: return parent_entity.world if parent_entity else world
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
    if parent_entity:
        parent_entity.child_entities.erase(self)
    parent_entity = new_parent
    if parent_entity:
        parent_entity.child_entities.append(self)

func get_global_transform() -> Transform3D:
    return (parent_entity.get_global_transform() if parent_entity else 1) * transform

func set_transform(new_transform: Transform3D) -> void:
    transform = new_transform
    emit_data_changed(&"transform")

func emit_data_changed(data_type: StringName, includes_child: bool = true) -> void:
    data_changed.emit(data_type)
    if includes_child:
        for child in child_entities:
            child.emit_data_changed(data_type, true)

func attach_entity_module(type: Vars_Objects.ObjectType) -> EntityModule:
    var module: EntityModule = type.create()
    module.entity = self
    add_child(module)
    return module

func get_main_module(type: Vars_Objects.ObjectType) -> EntityModule:
    return null

func _object_create() -> void:
    super._object_create()

func _object_init() -> void:
    super._object_init()

func _object_free() -> void:
    super._object_free()

func _load_data(stream: Stream) -> void:
    super._load_data(stream)

func _save_data(stream: Stream) -> void:
    super._save_data(stream)

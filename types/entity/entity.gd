class_name Entity
extends Vars_Objects.RefObject

signal data_changed(data_type: StringName)

static var entity_object_type: Vars_Objects.GDScriptObjectType

var modules: Dictionary = {}

var parent: Entity:
    set = set_parent
var childs: Array[Entity] = []
var world: World:
    get: return parent.world if parent else world
    set(v): world = v; for child in childs: child.world = v
var transform: Transform3D:
    set = set_transform

static func _static_init() -> void:
    entity_object_type = Vars.objects.GDScriptObjectType.new()
    entity_object_type.uuid = "gindustry-builtin-entity"
    entity_object_type.type_script = Entity

static func get_type() -> Vars_Objects.ObjectType:
    return entity_object_type

func set_parent(new_parent: Entity) -> void:
    if parent:
        parent.childs.erase(self)
    parent = new_parent
    if parent:
        parent.childs.append(self)

func get_global_transform() -> Transform3D:
    return (parent.get_global_transform() if parent else 1) * transform

func set_transform(new_transform: Transform3D) -> void:
    transform = new_transform
    emit_data_changed(&"transform")

func emit_data_changed(data_type: StringName, includes_child: bool = true) -> void:
    data_changed.emit(data_type)
    if includes_child:
        for child in childs:
            child.emit_data_changed(data_type, true)

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

class_name EntityModule
extends Vars_Objects.RefObject

static var entity_module_object_type: Vars_Objects.GDScriptObjectType

static func _static_init() -> void:
    entity_module_object_type = Vars_Objects.GDScriptObjectType.new()
    entity_module_object_type.uuid = "gindustry-builtin-entity-module"
    entity_module_object_type.type_script = EntityModule
    Vars_Objects.add_object_type(entity_module_object_type)

static func get_type() -> Vars_Objects.ObjectType:
    return entity_module_object_type

var entity: Entity

func _object_create() -> void:
    super._object_create()

func _object_init() -> void:
    super._object_init()

func _object_free() -> void:
    super._object_free()

func _load_data(stream: Stream) -> void:
    super._load_data(stream)
    Utils.load_data_with_version(stream, [func():
        Vars.objects.get_object_callback(stream.get_64(), func(v): entity = v)
    ])

func _save_data(stream: Stream) -> void:
    super._save_data(stream)
    Utils.save_data_with_version(stream, [func():
        stream.store_64(Vars.objects.get_object_id(entity))
    ])

class_name EntityModuleRendering
extends EntityModule

static var entity_module_rendering_object_type: Vars_Objects.GDScriptObjectType

static func _static_init() -> void:
    entity_module_rendering_object_type = Vars_Objects.GDScriptObjectType.new()
    entity_module_rendering_object_type.uuid = "gindustry-builtin-entity-module-rendering"
    entity_module_rendering_object_type.type_script = EntityModuleRendering
    Vars_Objects.add_object_type(entity_module_rendering_object_type)

static func get_type() -> Vars_Objects.ObjectType:
    return entity_module_rendering_object_type

func _object_create() -> void:
    super._object_create()

func _object_init() -> void:
    super._object_init()

func _object_free() -> void:
    super._object_free()

func _load_data(stream: Stream) -> void:
    super._load_data(stream)
    Utils.load_data_with_version(stream, [func():
        pass
    ])

func _save_data(stream: Stream) -> void:
    super._save_data(stream)
    Utils.save_data_with_version(stream, [func():
        pass
    ])

class_name EntityModule
extends Object

static var TYPE:
    get = get_type

static func get_type() -> StringName:
    return &"entity_module"

var entity: Entity

func init() -> void:
    pass

func free() -> void:
    super.free()

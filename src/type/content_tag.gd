class_name ContentTag
extends ResourceType

static var TYPE: ResourceTypeType

var contents: Array[Content] = []

static func g(tag: String) -> ContentTag:
    var inst = Vars.types.get_type(TYPE, "#" + tag)
    if inst: return inst
    inst = ContentTag.new()
    inst.id = tag
    return Vars.types.register_type(inst)

func init_full_id() -> void:
    full_id = "#" + id

func _get_type() -> ResourceTypeType:
    return TYPE


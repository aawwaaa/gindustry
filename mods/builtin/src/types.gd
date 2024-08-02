extends Object

static var mod: Builtin_Mod

static func init(m: Builtin_Mod) -> void:
    mod = m
    init_resource_types()
    await mod.load_resources("mod://resource_types", "Load_LoadTypes", mod.logger.source)

static func init_resource_types() -> void:
    ContentCategory.TYPE = rtype("content_category")
    ContentTag.TYPE = rtype("content_tag")
    ContentType.TYPE = rtype("content_type")
    Preset.TYPE = rtype("preset")

static func rtype(id: String) -> ResourceTypeType:
    var t = ResourceTypeType.new()
    t.id = id
    Vars.types.register_type(t)
    return t

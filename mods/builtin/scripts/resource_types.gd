extends Object

static var mod: Builtin_Mod

static func init(m: Builtin_Mod) -> void:
    mod = m
    init_types()
    await load_types("/types")

static func init_types() -> void:
    ContentCategory.TYPE = type("content_category")
    ContentTag.TYPE = type("content_tag")
    ContentType.TYPE = type("content_type")
    Preset.TYPE = type("preset")

static func type(id: String) -> ResourceTypeType:
    var t = ResourceTypeType.new()
    t.id = id
    Vars.types.register_type(t)
    return t

static func load_types(path: String) -> void:
    var types_path = m.get_files(path)
    for index in types_path.size():
        types_path[index] = m.to_absolute(types_path[index])
    var types = await Utils.load_contents_async("", types_path, "Load_LoadTypes", m.logger.source)
    for type in types:
        var inst = type.new()
        Vars.types.register_type(inst)


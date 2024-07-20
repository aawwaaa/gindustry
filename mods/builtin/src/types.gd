extends Object

static var mod: Builtin_Mod

static func init(m: Builtin_Mod) -> void:
    mod = m
    init_resource_types()
    await mod.load_resources("/resource_types", "Load_LoadTypes", mod.logger.source)
    init_object_types()

    # await load_scripts(mod.root + "/src")
    # await load_scripts("res://src")

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

static func init_object_types() -> void:
    otype(RefObject, "ref_object")

    otype(Entity, "entity")
    otype(World, "world")

    otype(TestEntity, "test_entity")

static func otype(type: GDScript, id: String) -> ObjectType:
    var t = GDScriptObjectType.new()
    t.type_script = type
    t.id = id
    Vars_Objects.add_object_type(t)
    return t

static func load_scripts(path: String) -> void:
    var types_path = mod.get_files(path)
    var removes = []
    for p in types_path:
        if p.contains("__ignore__"):
            removes.append(p)
    for p in removes:
        types_path.erase(p)
    var types = await Utils.load_contents_async("", types_path, "Load_LoadScripts", mod.logger.source)
    for type in types:
        if type.has_method(&"__script__init"):
            type.__script__init()


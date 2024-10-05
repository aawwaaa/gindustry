extends Object

class ContentTypeTemplate extends ContentType:
    pass

static func __resource__static_init(_mod: Mod) -> void:
    ContentType.CONTENT = type("content")
    ContentType.ENTITY = type("entity")
    ContentType.BLOCK = type("block")
    ContentType.ITEM = type("item")
    ContentType.FLUID = type("fluid")
    ContentType.ENERGY = type("energy")
    ContentType.MESH_BLOCK = type("mesh_block")

static func type(id: String) -> ContentType:
    var t = ContentTypeTemplate.new()
    t.id = id
    Vars.types.register_type(t)
    return t

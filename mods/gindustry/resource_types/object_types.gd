extends Object

static func __resource__static_init(_mod: Mod) -> void:
    type(Gindustry_Entity_Test, "entity_test")

static func type(script: GDScript, id: String) -> void:
    var t = GDScriptObjectType.new()
    t.type_script = script
    t.id = id
    Vars_Objects.add_object_type(t)

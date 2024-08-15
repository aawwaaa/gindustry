extends Object

static func __resource__static_init(_mod: Mod) -> void:
    type(RefObject, "ref_object")

    type(Entity, "entity")
    type(PhysicsEntity, "physics_entity")
    type(PartialPhysicsEntity, "partial_physics_entity")
    type(StandalonePhysicsEntity, "standalone_physics_entity")

    type(MeshEntity, "mesh_entity")
    type(MeshBlockEntity, "mesh_block_entity")

    type(World, "world")

static func type(script: GDScript, id: String) -> void:
    var t = GDScriptObjectType.new()
    t.type_script = script
    t.id = id
    Vars_Objects.add_object_type(t)

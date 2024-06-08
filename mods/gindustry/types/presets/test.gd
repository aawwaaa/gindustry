extends Preset

var directional_light: RID
var instance: RID
var instance2: RID

var mesh = BoxMesh.new()

func _get_type() -> ResourceType:
    return TYPE

func _show_description(node: ScrollContainer) -> void:
    var label = Label.new()
    label.text = tr("Gindustry_Presets_Test_Description")
    node.add_child(label)

func _pre_config_preset() -> bool:
    return true

func _init_preset() -> void:
    var world = Vars.worlds.create_world()
    var entity = TestEntity.TYPE.create(false)

    world.add_child_entity(entity)
    entity.object_create()

func _after_ready() -> void:
    directional_light = RenderingServer.directional_light_create()
    RenderingServer.light_set_color(directional_light, Color.WHITE)
    RenderingServer.light_set_param(directional_light, RenderingServer.LIGHT_PARAM_ENERGY, 1)
    RenderingServer.light_set_param(directional_light, RenderingServer.LIGHT_PARAM_INDIRECT_ENERGY, 1)
    RenderingServer.light_set_param(directional_light, RenderingServer.LIGHT_PARAM_RANGE, 100)

    instance = RenderingServer.instance_create()
    RenderingServer.instance_set_base(instance, directional_light)
    RenderingServer.instance_set_transform(instance, Transform3D.IDENTITY.rotated(Vector3.RIGHT, PI / 4))
    RenderingServer.instance_set_scenario(instance, Vars.worlds.worlds[1].world_3d.scenario)

    mesh.size = Vector3(100, 2, 100)

    Vars.worlds.worlds[1].toggle_to.call_deferred()

    # instance2 = RenderingServer.instance_create()
    # RenderingServer.instance_set_base(instance2, mesh.get_rid())
    # RenderingServer.instance_set_transform(instance, Transform3D.IDENTITY \
    #         .translated(Vector3.DOWN * 0.2))
    # RenderingServer.instance_set_scenario(instance2, Vars.worlds.worlds[1].world_3d.scenario)

func _apply_preset() -> void:
    pass

func _enable_preset() -> void:
    pass

func _disable_preset() -> void:
    RenderingServer.free_rid(directional_light)
    RenderingServer.free_rid(instance)
    RenderingServer.free_rid(instance2)

func _load_preset_data(_stream: Stream) -> Error:
    return OK

func _save_preset_data(_stream: Stream) -> void:
    pass

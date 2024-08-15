extends Preset

var directional_light: RID
var instance: RID
var instance2: RID

var body: RID
var shape: RID

var player: Entity

var mesh = BoxMesh.new()

func _data() -> void:
    super._data()
    id = "test"

func _assign() -> void:
    Vars.presets.register_preset_group("Gindustry").add(self)

func _show_description(node: ScrollContainer) -> void:
    var label = Label.new()
    label.text = tr("Gindustry_Presets_Test_Description")
    node.add_child(label)

func _pre_config_preset() -> bool:
    return true

func _init_preset() -> void:
    var world = Vars.worlds.create_world()

    var entity = Vars.contents.get_content_by_full_id("gindustry:entity:player").create(false)
    player = entity
    entity.transform = Transform3D(Basis.IDENTITY, Vector3(0, 10, 0))

    world.add_child_entity(entity)
    entity.object_create()

func _after_ready() -> void:
    directional_light = RenderingServer.directional_light_create()
    RenderingServer.light_set_color(directional_light, Color.WHITE)
    RenderingServer.light_set_param(directional_light, RenderingServer.LIGHT_PARAM_ENERGY, 5)
    RenderingServer.light_set_param(directional_light, RenderingServer.LIGHT_PARAM_INDIRECT_ENERGY, 2)
    RenderingServer.light_set_param(directional_light, RenderingServer.LIGHT_PARAM_RANGE, 100)

    instance = RenderingServer.instance_create()
    RenderingServer.instance_set_base(instance, directional_light)
    RenderingServer.instance_set_transform(instance, Transform3D.IDENTITY.rotated(Vector3.RIGHT, -PI / 6).rotated(Vector3.UP, PI / 6))
    RenderingServer.instance_set_scenario(instance, Vars.worlds.worlds[1].scenario)

    mesh.size = Vector3(5, 1, 5)
    mesh.material = StandardMaterial3D.new()
    mesh.material.albedo_color = Color(1, 0.8, 0.2)

    PhysicsServer3D.area_set_param(Vars.worlds.worlds[1].space, PhysicsServer3D.AREA_PARAM_GRAVITY, 9.8)
    PhysicsServer3D.area_set_param(Vars.worlds.worlds[1].space, PhysicsServer3D.AREA_PARAM_GRAVITY_VECTOR, Vector3.DOWN)

    shape = PhysicsServer3D.box_shape_create()
    PhysicsServer3D.shape_set_data(shape, Vector3(1000, 1, 1000) / 2)

    body = PhysicsServer3D.body_create()
    PhysicsServer3D.body_add_shape(body, shape, Transform3D.IDENTITY)
    PhysicsServer3D.body_set_mode(body, PhysicsServer3D.BODY_MODE_STATIC)
    PhysicsServer3D.body_set_state(body, PhysicsServer3D.BODY_STATE_TRANSFORM, Transform3D.IDENTITY.translated(Vector3(0, -5, 0)))
    PhysicsServer3D.body_set_collision_mask(body, 1)
    PhysicsServer3D.body_set_collision_layer(body, 1)
    PhysicsServer3D.body_set_space(body, Vars.worlds.worlds[1].space)

    Vars.worlds.worlds[1].toggle_to.call_deferred()

    instance2 = RenderingServer.instance_create()
    RenderingServer.instance_set_base(instance2, mesh.get_rid())
    RenderingServer.instance_set_transform(instance2, Transform3D.IDENTITY.translated(Vector3(0, -5, 0)))
    RenderingServer.instance_set_scenario(instance2, Vars.worlds.worlds[1].scenario)

func _apply_preset() -> void:
    pass

func _enable_preset() -> void:
    pass

func _disable_preset() -> void:
    RenderingServer.free_rid(directional_light)
    RenderingServer.free_rid(instance)
    RenderingServer.free_rid(instance2)

func _init_after_local_player_join() -> void:
    Vars.game.player.controller.control_to(player.get_component(ControlHandleComponent.NAME))

func _load_preset_data(_stream: Stream) -> Error:
    return OK

func _save_preset_data(_stream: Stream) -> void:
    pass

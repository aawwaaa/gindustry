class_name Gindustry_Entity_Player
extends StandalonePhysicsEntity

static func get_type() -> ObjectType:
    push_error("Create with a entity content, DO NOT use TYPE.create()")
    return null

static func __content_scene__type() -> GDScript:
    return PlayerType

class PlayerType extends PhysicsEntityType:
    @export var mesh: Mesh

    @export var camera_transform: Transform3D

    ## x+, x-, y+, y-, z+, z-
    @export var max_force: Array[float] = [1000.0, 1000.0, 2000.0, 1000.0, 1000.0, 1000.0]
    @export var max_torque: float = 200.0

    @export_group("Import from scene", "scene_")
    @export_node_path("MeshInstance3D") var scene_mesh: NodePath
    @export_node_path("Camera3D") var scene_camera: NodePath

    func _create() -> RefObject:
        return Gindustry_Entity_Player.new()

    func _init_from_scene(node: ContentScene) -> void:
        super._init_from_scene(node)
        if scene_mesh:
            mesh = node.get_node(scene_mesh).mesh
        if scene_camera:
            var camera: Camera3D = node.get_node(scene_camera)
            camera_transform = camera.transform

var player_type: PlayerType:
    get: return object_type as PlayerType

var mesh_instance: RID
var control_handle_component: ControlHandleComponent

func _components_init() -> void:
    super._components_init()
    control_handle_component = ControlHandleComponent.new()
    add_component(control_handle_component)

func process_move(velocity: Vector3) -> void:
    velocity = velocity.clamp(-Vector3.ONE, Vector3.ONE)
    var x = velocity.x * player_type.max_force[0 + floori((1-signf(velocity.x)) / 2)]
    var y = velocity.y * player_type.max_force[2 + floori((1-signf(velocity.y)) / 2)]
    var z = velocity.z * player_type.max_force[4 + floori((1-signf(velocity.z)) / 2)]
    var force = transform.basis * Vector3(x, y, z)
    direct_state.apply_central_force(force)

func process_roll(velocity: Vector3) -> void:
    velocity = transform.basis * velocity * player_type.max_torque
    velocity = velocity.clamp(Vector3.ONE * -player_type.max_torque, Vector3.ONE * player_type.max_torque)
    direct_state.apply_torque(velocity)

func _physics_process(delta: float) -> void:
    super._physics_process(delta)
    if not entity_active: return
    _controller_feedback(control_handle_component)
    process_move(Controller.MovementModule.get_move_velocity_for(control_handle_component))
    process_roll(Controller.MovementModule.get_roll_velocity_for(control_handle_component))

func _object_init() -> void:
    super._object_init()

    mesh_instance = RenderingServer.instance_create()
    RenderingServer.instance_set_base(mesh_instance, player_type.mesh.get_rid())

func _object_free() -> void:
    RenderingServer.free_rid(mesh_instance)

    super._object_free()

func _entity_init() -> void:
    super._entity_init()

    RenderingServer.instance_set_scenario(mesh_instance, world.scenario)

func _entity_deinit() -> void:
    RenderingServer.instance_set_scenario(mesh_instance, RID())

    super._entity_deinit()

func _on_transform_changed(source: Entity) -> void:
    super._on_transform_changed(source)
    RenderingServer.instance_set_transform(mesh_instance, transform)

func _controller_feedback(control_handle: ControlHandleComponent) -> void:
    super._controller_feedback(control_handle)
    var movement = control_handle.get_module(Controller.MovementModule.TYPE)
    if movement:
        movement.entity_max_force = player_type.max_force
        movement.entity_max_torque = player_type.max_torque
    var camera_output = control_handle.get_module(Controller.CameraOutputModule.TYPE)
    if camera_output:
        camera_output.camera_transform = get_global_transform() * player_type.camera_transform

extends Node

var tracking: RID

func _ready() -> void:
    var space = PhysicsServer3D.space_create()
    PhysicsServer3D.area_set_param(space, PhysicsServer3D.AREA_PARAM_GRAVITY, 9.8)
    PhysicsServer3D.area_set_param(space, PhysicsServer3D.AREA_PARAM_GRAVITY_VECTOR, Vector3.DOWN)

    var shape1 = PhysicsServer3D.box_shape_create()
    PhysicsServer3D.shape_set_data(shape1, Vector3(1, 1, 1) / 2)
    
    var shape2 = PhysicsServer3D.box_shape_create()
    PhysicsServer3D.shape_set_data(shape2, Vector3(5, 1, 5) / 2)

    var body = PhysicsServer3D.body_create()
    PhysicsServer3D.body_add_shape(body, shape1, Transform3D.IDENTITY)
    PhysicsServer3D.body_set_mode(body, PhysicsServer3D.BODY_MODE_RIGID)
    PhysicsServer3D.body_set_state(body, PhysicsServer3D.BODY_STATE_TRANSFORM, Transform3D.IDENTITY.translated(Vector3(0, 1, 0)))
    PhysicsServer3D.body_set_collision_mask(body, 1)
    PhysicsServer3D.body_set_collision_layer(body, 1)
    PhysicsServer3D.body_set_space(body, space)

    var ground = PhysicsServer3D.body_create()
    PhysicsServer3D.body_add_shape(ground, shape2, Transform3D.IDENTITY)
    PhysicsServer3D.body_set_mode(ground, PhysicsServer3D.BODY_MODE_STATIC)
    PhysicsServer3D.body_set_state(ground, PhysicsServer3D.BODY_STATE_TRANSFORM, Transform3D.IDENTITY.translated(Vector3(0, -6, 0)))
    PhysicsServer3D.body_set_collision_mask(ground, 1)
    PhysicsServer3D.body_set_collision_layer(ground, 1)
    PhysicsServer3D.body_set_space(ground, space)

    PhysicsServer3D.space_set_active(space, true)
    
    tracking = body

func _process(_delta: float) -> void:
    print(PhysicsServer3D.body_get_state(tracking, PhysicsServer3D.BODY_STATE_TRANSFORM))


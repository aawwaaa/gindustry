extends Node

func _ready() -> void:
    var body = PhysicsServer3D.body_create()
    PhysicsServer3D.body_set_space(body, get_viewport().get_world_3d().space)
    var shape = PhysicsServer3D.box_shape_create()
    PhysicsServer3D.shape_set_data(shape, Vector3(1, 1, 1))

    PhysicsServer3D.body_add_shape(body, shape, Transform3D.IDENTITY)
    print(PhysicsServer3D.body_get_shape_count(body))

    PhysicsServer3D.body_add_shape(body, shape, Transform3D.IDENTITY.translated(Vector3(1, 0, 0)))
    print(PhysicsServer3D.body_get_shape_count(body))

    PhysicsServer3D.body_remove_shape(body, 0)
    print(PhysicsServer3D.body_get_shape_count(body))

    for i in range(PhysicsServer3D.body_get_shape_count(body)):
        printt(i, PhysicsServer3D.body_get_shape_transform(body, i))

    await get_tree().process_frame

    PhysicsServer3D.body_set_space(body, RID())

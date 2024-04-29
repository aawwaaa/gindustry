extends Node3D

@export var mesh: Mesh

func _ready() -> void:
    var instance = RenderingServer.instance_create()
    
    RenderingServer.instance_set_base(instance, mesh)
    RenderingServer.instance_set_scenario(instance, get_viewport().get_world_3d().scenario)

    var light = RenderingServer.directional_light_create()
    print(light)
    instance = RenderingServer.instance_create()

    RenderingServer.light_set_param(light, RenderingServer.LIGHT_PARAM_ENERGY, 1.0)
    RenderingServer.light_set_color(light, Color(1.0, 1.0, 1.0))
    RenderingServer.instance_set_base(instance, light)
    RenderingServer.instance_set_transform(instance, Transform3D( \
            Basis.IDENTITY.rotated(Vector3.RIGHT, PI * 1.5), Vector3.ZERO))
    RenderingServer.instance_set_scenario(instance, get_viewport().get_world_3d().scenario)

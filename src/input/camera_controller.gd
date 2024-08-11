class_name CameraController
extends Node

var active: bool = true:
    set(v): active = v; if v: update_transform()
var world: World:
    set = set_world
var camera_rid: RID
var transform: Transform3D:
    set(v): transform = v; update_transform()

func _ready() -> void:
    Vars.worlds.toggled_world_changed.connect(_on_toggled_world_changed)

func _on_toggled_world_changed(new_world: World) -> void:
    if not active: return
    set_world(new_world)

func set_world(v: World) -> void:
    world = v
    if v == null:
        camera_rid = RID()
        return
    camera_rid = v.camera

    RenderingServer.camera_set_perspective(camera_rid, 75, 0.1, 1000)

    update_transform()

func update_transform() -> void:
    if not camera_rid.is_valid(): return
    if not is_instance_valid(world): return
    if not active: return
    if Vars.worlds.current_toggled_world != world:
        world.toggle_to()
    RenderingServer.camera_set_transform(camera_rid, transform)

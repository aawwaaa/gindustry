class_name CameraController
extends Node

# TODO current world follow actived camera

var active: bool = true:
    set(v): active = v; if v: update_transform()
var camera_rid: RID
var transform: Transform3D:
    set(v): transform = v; update_transform()

func _ready() -> void:
    Vars.worlds.toggled_world_changed.connect(_on_toggled_world_changed)

func _on_toggled_world_changed(world: World) -> void:
    if not active: return
    set_world(world)

func set_world(v: World) -> void:
    if v == null:
        camera_rid = RID()
        return
    camera_rid = v.camera

    RenderingServer.camera_set_perspective(camera_rid, 90, 0.1, 100)

    update_transform()

func update_transform() -> void:
    if not camera_rid.is_valid(): return
    if not active: return
    RenderingServer.camera_set_transform(camera_rid, transform)

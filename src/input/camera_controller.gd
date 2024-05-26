class_name CameraController
extends Node

var active: bool = true
var camera_rid: RID
var transform: Transform3D:
    set(v): transform = v; update_transform()

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

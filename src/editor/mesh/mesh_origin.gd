@tool
class_name MeshOrigin
extends MeshInstance3D

const MESH = preload("res://assets/editor/mesh_origin_cube_cube.res")

func _ready() -> void:
    mesh = MESH

func _property_can_revert(property: StringName) -> bool:
    return property == "mesh"

func _property_get_revert(property: StringName) -> Variant:
    if property == "mesh":
        return MESH
    return null

func _process(_delta: float) -> void:
    transform.basis = Basis.IDENTITY

func get_origin_offset() -> Vector3:
    return -position


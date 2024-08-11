class_name SpaceAxisPanel
extends SubViewportContainer

static var scene: PackedScene = load("res://ui/panels/space_axis_panel/space_axis_panel.tscn")

@onready var mesh_instance: MeshInstance3D = %MeshInstance3D

@export var basis: Basis:
    set(v): basis = v; mesh_instance.transform.basis = basis

func _ready() -> void:
    mesh_instance.transform.basis = basis

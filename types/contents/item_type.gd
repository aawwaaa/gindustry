class_name ItemType
extends Content

@export var item_scene: PackedScene

@export var texture: Texture
@export var max_stack: int = 100

@export var useable: bool = false
@export var use_scene: PackedScene
@export var allow_use_out_of_access_range: bool = false

func create_item() -> Item:
    var inst = item_scene.instantiate()
    inst.item_type = self
    return inst

func get_tr_name() -> String:
    return Content.to_full_id(mod.mod_info.id, id, "Item")

func _get_content_type() -> String:
    return "item"

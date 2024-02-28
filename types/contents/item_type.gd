class_name ItemType
extends Content

const ITEM_SCENE = preload("res://types/item/item.tscn")

var item_scene: PackedScene:
    get = _get_item_scene

var texture: Texture2D:
    get = get_texture
var max_stack: int:
    get = get_max_stack
var cost: int:
    get = get_cost

var useable: bool:
    get: return use_scene != null
var use_scene: PackedScene:
    get = _get_use_scene

func create_item() -> Item:
    var inst = item_scene.instantiate()
    inst.item_type = self
    return inst

func get_tr_name() -> String:
    return Content.to_full_id(mod.mod_info.id, id, "Item")

func _get_content_type() -> String:
    return "item"

func _get_item_scene() -> PackedScene:
    return ITEM_SCENE

func _get_use_scene() -> PackedScene:
    return null

func _get_texture() -> Texture2D:
    return null

func _get_max_stack() -> int:
    return 100

func _get_cost() -> int:
    return 1

func get_texture() -> Texture2D:
    return _get_texture()

func get_max_stack() -> int:
    return _get_max_stack()

func get_cost() -> int:
    return _get_cost()

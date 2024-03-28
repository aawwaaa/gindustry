class_name ItemType
extends Content

const ITEM_TYPE = preload("res://contents/content_types/item.tres")
const ITEM_DISPLAY = preload("res://types/item/item_display.tscn")

var max_stack: int:
    get = get_max_stack

var useable: bool:
    get: return use_scene != null
var use_scene: PackedScene:
    get = _get_use_scene

func create_item() -> Item:
    var inst = _get_item_script().new()
    inst.item_type = self
    return inst

func get_tr_name() -> String:
    return Content.to_full_id(mod.mod_info.id, id, "Item")

func _get_content_type() -> ContentType:
    return ITEM_TYPE

func _get_item_script() -> GDScript:
    return Item

func _get_use_scene() -> PackedScene:
    return null

func _get_texture() -> Texture2D:
    return icon

func _get_display() -> PackedScene:
    return ITEM_DISPLAY

func _get_max_stack() -> int:
    return 100

func _get_cost() -> float:
    return 1

func get_texture() -> Texture2D:
    return _get_texture()

func get_display() -> PackedScene:
    return _get_display()

func get_max_stack() -> int:
    return _get_max_stack()

func get_cost() -> float:
    return _get_cost()

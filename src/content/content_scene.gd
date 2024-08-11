@tool
class_name ContentScene
extends Node

@export var content_type: GDScript:
    set(v): content_type = v; defaults.clear(); init()

var instance: Object = null
var property_list: Array[Dictionary]

var defaults: Dictionary = {}
var storaged: Dictionary = {}

func _ready() -> void:
    init()

func init() -> void:
    if storaged == null:
        storaged = {}
    if instance:
        instance = null
    if content_type == null:
        property_list = []
        notify_property_list_changed()
        return
    if content_type.has_method(&"__content_scene__type"):
        instance = content_type.__content_scene__type().new()
    else:
        instance = content_type.new()
    property_list = []
    var ignoring: bool = false
    var ignored_category: StringName
    for prop in instance.get_property_list():
        if prop.name == &"Resource" and prop.usage & PROPERTY_USAGE_CATEGORY:
            ignoring = true
            ignored_category = prop.name
            continue
        if prop.name != ignored_category and prop.usage & PROPERTY_USAGE_CATEGORY:
            ignoring = false
        if ignoring: continue
        if prop.usage & PROPERTY_USAGE_CATEGORY:
            prop.name = "Content / " + prop.name
        if prop.usage & PROPERTY_USAGE_STORAGE:
            defaults[prop.name] = instance.get(prop.name)
            if not storaged.has(prop.name):
                storaged[prop.name] = instance.get(prop.name)
        prop.usage = prop.usage & ~PROPERTY_USAGE_STORAGE
        property_list.append(prop)
    property_list.append({
        "name": "storaged",
        "type": TYPE_DICTIONARY,
        "usage": PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_INTERNAL,
    })
    notify_property_list_changed.call_deferred()

func _notification(what: int) -> void:
    if what == NOTIFICATION_PREDELETE:
        if instance:
            instance = null

func _get_property_list() -> Array[Dictionary]:
    return property_list

func _get(n: StringName) -> Variant:
    if n == "content_type":
        return content_type
    if n == "storaged":
        return storaged
    return storaged[n] if storaged.has(n) else null

func _set(n: StringName, v: Variant) -> bool:
    if n == "content_type":
        content_type = v
        return true
    if n == "storaged":
        storaged = v
        return true
    storaged[n] = v
    return false

func _property_get_revert(property: StringName) -> Variant:
    if not instance: return null
    return defaults.get(property) if defaults.has(property) else null

func _property_can_revert(property: StringName) -> bool:
    if not instance: return false
    return defaults.has(property)

func __packed_scene__init(_mod: Mod) -> bool:
    init()
    for key in storaged:
        instance.set(key, storaged[key])
    instance._init_from_scene(self)
    return true

func __packed_scene__get_resource() -> Resource:
    return instance

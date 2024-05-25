class_name RefObject
extends Node

static var TYPE: ObjectType:
    get = get_type

static func get_type() -> ObjectType:
    return null

var object_id: int;
var object_type: ObjectType
var object_ready: bool

func _object_create() -> void:
    pass

func handle_create() -> void:
    _object_create()
    _object_init()

func _object_init() -> void:
    Vars.objects.add_object(self) 
    add_to_group(&"objects")
    name = object_type.id + "#" + str(object_id)

func _object_free() -> void:
    pass

func free() -> void:
    _object_free()
    Vars.objects.object_freed(object_id)
    super.free()

func _object_ready() -> void:
    if object_ready: return
    object_ready = true
    if not is_inside_tree():
        Vars.objects.add_child(self)

func _load_data(_stream: Stream) -> void:
    pass

func load_data(stream: Stream) -> void:
    Utils.load_data_with_version(stream, [func():
        object_id = stream.get_64()
        _load_data(stream)
    ])
    _object_init()

func _save_data(_stream: Stream) -> void:
    pass

func save_data(stream: Stream) -> void:
    Utils.save_data_with_version(stream, [func():
        stream.store_64(object_id)
        _save_data(stream)
    ])

func sync(method: StringName, args: Array[Variant]) -> void:
    Vars.server.sync(self, method, args)

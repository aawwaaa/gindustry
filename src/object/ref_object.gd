class_name RefObject
extends Node

static var TYPE: ObjectType:
    get = get_type
const OBJECT_TYPE_META = &"object_type"

static func get_type() -> ObjectType:
    return null

var object_id: int = 0;
var object_type: ObjectType
var object_ready: bool

func _object_create() -> void:
    pass

func object_create() -> void:
    _object_create()
    _object_init()
    if Vars.objects.auto_ready:
        _object_ready()

func _object_init() -> void:
    Vars.objects.add_object(self, object_id)
    add_to_group(&"objects")
    name = object_type.id + "#" + str(object_id)

func _object_free() -> void:
    pass

func free() -> void:
    print("free")
    _object_free()
    Vars.objects.object_freed(object_id)
    super.free()

func packed() -> RefObjectPacked:
    var obj = RefObjectPacked.new()
    obj.object = self
    return obj

func _object_ready() -> void:
    if object_ready: return
    object_ready = true
    if not is_inside_tree():
        Vars.objects.add_child(self)

func _load_data(_stream: Stream) -> Error:
    return OK

func load_data(stream: Stream) -> Error:
    var err = Utils.load_data_with_version(stream, [func():
        object_id = stream.get_64()
        return _load_data(stream)
    ])
    if err: return err
    _object_init()
    return OK

func _save_data(_stream: Stream) -> void:
    pass

func save_data(stream: Stream) -> void:
    Utils.save_data_with_version(stream, [func():
        stream.store_64(object_id)
        _save_data(stream)
    ])

func sync(method: StringName, args: Array[Variant]) -> void:
    Vars.server.sync_node(self, method, args)

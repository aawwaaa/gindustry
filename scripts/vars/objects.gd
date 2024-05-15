class_name Vars_Objects
extends Vars.Vars_Object

signal object_registed(object: RefObject)

class RefObject extends Node:
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
        name = object_type.uuid + "#" + str(object_id)

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

    func _load_data(stream: Stream) -> void:
        pass

    func load_data(stream: Stream) -> void:
        Utils.load_data_with_version(stream, [func():
            object_id = stream.get_64()
            _load_data(stream)
        ])
        _object_init()

    func _save_data(stream: Stream) -> void:
        pass
    
    func save_data(stream: Stream) -> void:
        Utils.save_data_with_version(stream, [func():
            stream.store_64(object_id)
            _save_data(stream)
        ])

class ObjectType extends Resource:
    @export var uuid: String
    var index: int

    func _create() -> RefObject:
        return null
    func create(no_create: bool = false) -> RefObject:
        var obj = _create()
        if obj: obj.object_type = self
        if obj and not no_create: obj.handle_create()
        return obj

class GDScriptObjectType extends ObjectType:
    @export var type_script: GDScript

    func _create() -> RefObject:
        return type_script.new()

class PlaceholderObjectType extends ObjectType:
    pass

var logger: Log.Logger = Log.register_logger("Objects_LogSource")

static var object_types_list: Array[ObjectType]
static var object_type_inc_id: int = 1
static var object_types: Dictionary = {}
static var object_types_indexed: Dictionary = {}
static var object_types_sorted: Array[ObjectType]

var object_inc_id: int = 1
var objects: Dictionary = {}
var object_auto_ready: bool = false

func create_id() -> int:
    var id = object_inc_id
    object_inc_id += 1
    return id

func add_object(object: RefObject, id: int = 0) -> void:
    if id == 0:
        id = create_id()
        object.object_id = id
    objects[id] = object
    object_registed.emit(object, id)
    if object_auto_ready:
        object._object_ready()

func object_freed(id: int) -> void:
    objects.erase(id)

func has_object(id: int) -> bool:
    return objects.has(id)

func get_object_or_null(id: int) -> RefObject:
    if objects.has(id):
        return objects[id]
    return null

func get_object(id: int) -> RefObject:
    if id == 0: return null
    if objects.has(id):
        return objects[id]
    var last_object: RefObject
    while not last_object or last_object.object_id != id:
        last_object = await object_registed
        if last_object == null: return null
    return last_object

func get_object_callback(id: int, callback: Callable) -> void:
    if id == 0:
        callback.call(null)
        return
    if objects.has(id):
        callback.call(objects[id])
        return
    var last_object: RefObject
    while not last_object or last_object.object_id != id:
        last_object = await object_registed
        if last_object == null:
            callback.call(null)
            return
    callback.call(last_object)

func get_object_id(object: RefObject) -> int:
    return object.object_id if object else 0

func object_ready() -> void:
    Vars.tree.call_group(&"objects", &"_object_ready")
    object_auto_ready = true

func cleanup() -> void:
    for object in objects.values():
        if is_instance_valid(object):
            object.free()
    object_registed.emit(null)
    object_inc_id = 1
    object_auto_ready = false
    cleanup_object_types()

func cleanup_object_types() -> void:
    for type in object_types_sorted:
        if type is PlaceholderObjectType:
            type.free()
    object_type_inc_id = 1
    object_types = {}
    object_types_sorted = []

func load_object(stream: Stream) -> RefObject:
    var type_id = stream.get_64()
    if type_id == 0: return null
    if not object_types.has(type_id):
        logger.error(tr("Objects_UnknownObjectID {id}").format({id = type_id}))
        return null
    var type = object_types[type_id]
    if type is PlaceholderObjectType:
        logger.error(tr("Objects_UnknownObjectType {uuid}").format({uuid = type.uuid}))
        return null
    var object: RefObject = type.create()
    object.load_data(stream)
    return object

func save_object(stream: Stream, object: RefObject) -> void:
    if object == null:
        stream.store_64(0)
        return
    stream.store_64(object.object_type.index)
    object.save_data(stream)

func load_data(stream: Stream) -> void:
    Utils.load_data_with_version(stream, [func():
        load_object_types_mapping(stream)
        object_inc_id = stream.get_64()
    ])

func save_data(stream: Stream) -> void:
    Utils.save_data_with_version(stream, [func():
        save_object_types_mapping(stream)
        stream.store_64(object_inc_id)
    ])

static func add_object_type(type: ObjectType) -> void:
    object_types_list.append(type)
    object_types_indexed[type.uuid] = type

func init_object_types_mapping() -> void:
    cleanup_object_types()
    for type in object_types_list:
        type.index = object_type_inc_id
        object_types[type.index] = type
        object_types_sorted.append(type)  
        object_type_inc_id += 1

func load_object_types_mapping(stream: Stream) -> void:
    cleanup_object_types()
    for type in object_types_list:
        type.index = -1
    object_type_inc_id = 1
    for _1 in range(stream.get_32()):
        var uuid = stream.get_string()
        var type: ObjectType
        if object_types_indexed.has(uuid):
            type = object_types_indexed[uuid]
        else:
            type = PlaceholderObjectType.new()
            type.uuid = uuid
            logger.warn(tr("Objects_UnknownObjectType {uuid}").format({uuid = uuid}))
        type.index = object_type_inc_id
        object_types[type.index] = type
        object_types_sorted.append(type)
        object_type_inc_id += 1
    for type in object_types_list:
        if type.index == -1:
            type.index = object_type_inc_id
            object_types[type.index] = type
            object_types_sorted.append(type)
            object_type_inc_id += 1

func save_object_types_mapping(stream: Stream) -> void:
    stream.store_32(object_types_sorted.size())
    for type in object_types_sorted:
        stream.store_string(type.uuid)

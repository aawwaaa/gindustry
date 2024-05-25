class_name Vars_Objects
extends Vars.Vars_Object

signal object_registed(object: RefObject)

class PlaceholderObjectType extends ObjectType:
    pass

class __ObjectsReg extends Object:
    var object_types_list: Array[ObjectType] = []
    var object_type_inc_id: int = 1
    var object_types: Dictionary = {}
    var object_types_indexed: Dictionary = {}
    var object_types_sorted: Array[ObjectType] = []

static var __objects_reg: __ObjectsReg;
var objects_reg_v: __ObjectsReg:
    get: return __objects_reg

var logger: Log.Logger = Log.register_logger("Objects_LogSource")

var object_inc_id: int = 1
var objects: Dictionary = {}

static func _static_init() -> void:
    if __objects_reg == null:
        __objects_reg = __ObjectsReg.new()

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

func make_ready(object: RefObject) -> void:
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

func reset() -> void:
    for object in objects.values():
        if is_instance_valid(object):
            object.free()
    object_registed.emit(null)
    object_inc_id = 1
    cleanup_object_types()

func cleanup_object_types() -> void:
    for type in __objects_reg.object_types_sorted:
        if type is PlaceholderObjectType:
            type.free()
    __objects_reg.object_type_inc_id = 1
    __objects_reg.object_types = {}
    __objects_reg.object_types_sorted = []

func load_object(stream: Stream) -> RefObject:
    var type_id = stream.get_64()
    if type_id == 0: return null
    if not __objects_reg.object_types.has(type_id):
        logger.error(tr("Objects_UnknownObjectID {id}").format({id = type_id}))
        return null
    var type = __objects_reg.object_types[type_id]
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
    if __objects_reg == null:
        __objects_reg = __ObjectsReg.new()
    __objects_reg.object_types_list.append(type)
    __objects_reg.object_types_indexed[type.full_id] = type

func init_object_types_mapping() -> void:
    cleanup_object_types()
    for type in __objects_reg.object_types_list:
        type.index = __objects_reg.object_type_inc_id
        __objects_reg.object_types[type.index] = type
        __objects_reg.object_types_sorted.append(type)  
        __objects_reg.object_type_inc_id += 1

func load_object_types_mapping(stream: Stream) -> void:
    cleanup_object_types()
    for type in __objects_reg.object_types_list:
        type.index = -1
    __objects_reg.object_type_inc_id = 1
    for _1 in range(stream.get_32()):
        var uuid = stream.get_string()
        var type: ObjectType
        if __objects_reg.object_types_indexed.has(uuid):
            type = __objects_reg.object_types_indexed[uuid]
        else:
            type = PlaceholderObjectType.new()
            type.uuid = uuid
            logger.warn(tr("Objects_UnknownObjectType {uuid}").format({uuid = uuid}))
        type.index = __objects_reg.object_type_inc_id
        __objects_reg.object_types[type.index] = type
        __objects_reg.object_types_sorted.append(type)
        __objects_reg.object_type_inc_id += 1
    for type in __objects_reg.object_types_list:
        if type.index == -1:
            type.index = __objects_reg.object_type_inc_id
            __objects_reg.object_types[type.index] = type
            __objects_reg.object_types_sorted.append(type)
            __objects_reg.object_type_inc_id += 1

func save_object_types_mapping(stream: Stream) -> void:
    stream.store_32(__objects_reg.object_types_sorted.size())
    for type in __objects_reg.object_types_sorted:
        stream.store_string(type.uuid)

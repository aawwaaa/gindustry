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
static var objects_reg: __ObjectsReg:
    get:
        if not __objects_reg: __objects_reg = __ObjectsReg.new()
        return __objects_reg
var objects_reg_v: __ObjectsReg:
    get: return objects_reg

var logger: Log.Logger = Log.register_logger("Objects_LogSource")

var object_inc_id: int = 1
var objects: Dictionary = {}

var err: Error = OK

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
    for object in objects.values():
        make_ready(object)

func reset() -> void:
    for object in objects.values():
        if is_instance_valid(object):
            object.free()
    object_registed.emit(null)
    object_inc_id = 1
    cleanup_object_types()

func cleanup_object_types() -> void:
    for type in objects_reg.object_types_sorted:
        if type is PlaceholderObjectType:
            type.free()
    objects_reg.object_type_inc_id = 1
    objects_reg.object_types = {}
    objects_reg.object_types_sorted = []

func load_object(stream: Stream) -> RefObject:
    err = OK
    var type_id = stream.get_64()
    if stream.get_error():
        err = stream.get_error()
        return null
    if type_id == 0: return null
    if not objects_reg.object_types.has(type_id):
        logger.error(tr("Objects_UnknownObjectID {id}").format({id = type_id}))
        return null
    var type = objects_reg.object_types[type_id]
    if type is PlaceholderObjectType:
        logger.error(tr("Objects_UnknownObjectType {uuid}").format({uuid = type.uuid}))
        return null
    var object: RefObject = type.create()
    err = object.load_data(stream)
    if err:
        object.free()
        return null
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
    objects_reg.object_types_list.append(type)
    objects_reg.object_types_indexed[type.full_id] = type

func init_object_types_mapping() -> void:
    cleanup_object_types()
    for type in objects_reg.object_types_list:
        type.index = objects_reg.object_type_inc_id
        objects_reg.object_types[type.index] = type
        objects_reg.object_types_sorted.append(type)  
        objects_reg.object_type_inc_id += 1

func load_object_types_mapping(stream: Stream) -> Error:
    cleanup_object_types()
    for type in objects_reg.object_types_list:
        type.index = -1
    objects_reg.object_type_inc_id = 1
    var size = stream.get_32()
    if stream.get_error(): return stream.get_error()
    for _1 in range(size):
        var uuid = stream.get_string()
        if stream.get_error(): return stream.get_error()
        var type: ObjectType
        if objects_reg.object_types_indexed.has(uuid):
            type = objects_reg.object_types_indexed[uuid]
        else:
            type = PlaceholderObjectType.new()
            type.full_id = uuid
            logger.warn(tr("Objects_UnknownObjectType {uuid}").format({uuid = uuid}))
        type.index = objects_reg.object_type_inc_id
        objects_reg.object_types[type.index] = type
        objects_reg.object_types_sorted.append(type)
        objects_reg.object_type_inc_id += 1
    for type in objects_reg.object_types_list:
        if type.index == -1:
            type.index = objects_reg.object_type_inc_id
            objects_reg.object_types[type.index] = type
            objects_reg.object_types_sorted.append(type)
            objects_reg.object_type_inc_id += 1
    return OK

func save_object_types_mapping(stream: Stream) -> void:
    stream.store_32(objects_reg.object_types_sorted.size())
    for type in objects_reg.object_types_sorted:
        stream.store_string(type.full_id)

class_name Utils_Serialize
extends Object

class Serializer extends Object:
    var err: Error = OK

    func _get_name() -> String: return "builtin_variant"
    func get_name() -> String: return _get_name()

    func _matched(_object: Variant) -> bool: return true
    func matched(object: Variant) -> bool: return _matched(object)

    func _serialize(stream: Stream, object: Variant) -> void: stream.store_var(object, true)
    func serialize(stream: Stream, object: Variant) -> void: _serialize(stream, object)
    
    func _unserialize(stream: Stream) -> Variant: 
        var value = stream.get_var()
        if stream.get_error():
            err = stream.get_error()
            return null
        return value
    func unserialize(stream: Stream) -> Variant: return _unserialize(stream)

class ArraySerializer extends Serializer:
    func _get_name() -> String: return "builtin_array"
    func _matched(object: Variant) -> bool: return object is Array
    func _serialize(stream: Stream, object: Variant) -> void:
        stream.store_32(object.size())
        for item in object:
            Utils.serialize.serialize(stream, item)
    func _unserialize(stream: Stream) -> Variant:
        var size: int = stream.get_32()
        if stream.get_error():
            err = stream.get_error()
            return null
        var array: Array = []
        for _1 in range(size):
            array.append(Utils.serialize.unserialize(stream))
            if Utils.serialize.err:
                err = Utils.serialize.err
                return null
        err = OK
        return array

class DictionarySerializer extends Serializer:
    func _get_name() -> String: return "builtin_dictionary"
    func _matched(object: Variant) -> bool: return object is Dictionary
    func _serialize(stream: Stream, object: Variant) -> void:
        stream.store_32(object.size())
        for key in object:
            Utils.serialize.serialize(stream, key)
            Utils.serialize.serialize(stream, object[key])
    func _unserialize(stream: Stream) -> Variant:
        var size: int = stream.get_32()
        if stream.get_error():
            err = stream.get_error()
            return null
        var dict: Dictionary = {}
        for _1 in range(size):
            var key = Utils.serialize.unserialize(stream)
            if Utils.serialize.err:
                err = Utils.serialize.err
                return null
            var value = Utils.serialize.unserialize(stream)
            if Utils.serialize.err:
                err = Utils.serialize.err
                return null
            dict[key] = value
        return dict

class NodeSerializer extends Serializer:
    func _get_name() -> String: return "builtin_node"
    func _matched(object: Variant) -> bool: return object is Node
    func _serialize(stream: Stream, object: Variant) -> void: stream.store_string(object.get_path())
    func _unserialize(stream: Stream) -> Variant:
        var path = stream.get_string()
        if stream.get_error():
            err = stream.get_error()
            return null
        return Vars.tree.root.get_node_or_null(path)

class ContentSerializer extends Serializer:
    func _get_name() -> String: return "builtin_content"
    func _matched(object: Variant) -> bool: return object is Content
    func _serialize(stream: Stream, object: Variant) -> void:
        stream.store_64(object.index)
    func _unserialize(stream: Stream) -> Variant:
        var cid = stream.get_64()
        if stream.get_error():
            err = stream.get_error()
            return null
        return Vars.contents.get_content_by_index(cid)

class ResourceTypeSerializer extends Serializer:
    func _get_name() -> String: return "builtin_resource_type"
    func _matched(object: Variant) -> bool: return object is ResourceType
    func _serialize(stream: Stream, object: Variant) -> void: 
        stream.store_string(object.get_type().full_id)
        stream.store_string(object.full_id)
    func _unserialize(stream: Stream) -> Variant:
        var type = stream.get_string()
        if stream.get_error():
            err = stream.get_error()
            return null
        var id = stream.get_string()
        if stream.get_error():
            err = stream.get_error()
            return null
        var type_obj = Vars.types.get_type_type(type)
        if not type_obj: return null
        return Vars.types.get_type(type_obj, id)

class ObjectTypeSerializer extends Serializer:
    func _get_name() -> String: return "builtin_object_type"
    func _matched(object: Variant) -> bool: return object is ObjectType
    func _serialize(stream: Stream, object: Variant) -> void: 
        stream.store_64(object.index)
    func _unserialize(stream: Stream) -> Variant:
        var index = stream.get_64()
        if stream.get_error():
            err = stream.get_error()
            return null
        return Vars_Objects.objects_reg.object_types_indexed[index] \
                if Vars_Objects.objects_reg.object_types_indexed.has(index) \
                else null

class RefObjectSerializer extends Serializer:
    func _get_name() -> String: return "builtin_ref_object"
    func _matched(object: Variant) -> bool: return object is RefObject
    func _serialize(stream: Stream, object: Variant) -> void: 
        stream.store_64(object.object_id)
    func _unserialize(stream: Stream) -> Variant:
        var object_id = stream.get_64()
        if stream.get_error():
            err = stream.get_error()
            return null
        return Vars.objects.get_object_or_null(object_id)

class RefObjectRefSerializer extends Serializer:
    func _get_name() -> String: return "builtin_ref_object_ref"
    func _matched(object: Variant) -> bool: return object is RefObjectRef
    func _serialize(stream: Stream, object: Variant) -> void: 
        stream.store_64(object.id)
    func _unserialize(stream: Stream) -> Variant:
        var ref = RefObjectRef.new()
        ref.id = stream.get_64()
        if stream.get_error():
            err = stream.get_error()
            return null
        return ref

class RefObjectPackedSerializer extends Serializer:
    func _get_name() -> String: return "builtin_ref_object_packed"
    func _matched(object: Variant) -> bool: return object is RefObjectPacked
    func _serialize(stream: Stream, object: Variant) -> void: 
        Vars.objects.save_object(stream, object)
    func _unserialize(stream: Stream) -> Variant:
        var obj = Vars.objects.load_object(stream)
        if Vars.objects.err:
            err = Vars.objects.err
            return null
        return obj

class PlayerSerializer extends Serializer:
    func _get_name() -> String: return "builtin_player"
    func _matched(object: Variant) -> bool: return object is Player
    func _serialize(stream: Stream, object: Variant) -> void: 
        stream.store_64(object.player_id)
    func _unserialize(stream: Stream) -> Variant:
        var player_id = stream.get_64()
        if stream.get_error():
            err = stream.get_error()
            return null
        return Vars.players.get_player_or_null(player_id)

var serializers: Array[Serializer] = []
var map: Dictionary = {}

var err: Error = OK

func add_serializer(serializer: Serializer) -> void:
    serializers.push_front(serializer)
    map[serializer.get_name()] = serializer

func serialize(stream: Stream, object: Variant) -> void:
    for serializer in serializers:
        if not serializer.matched(object): continue
        var n = serializer.get_name()
        stream.store_8(n.length())
        stream.store_buffer(n.to_ascii_buffer())
        serializer.serialize(stream, object)
        return

func unserialize(stream: Stream) -> Variant:
    var nl = stream.get_8()
    if stream.get_error():
        err = stream.get_error()
        return null
    var buf = stream.get_buffer(nl)
    if stream.get_error():
        err = stream.get_error()
        return null
    var name = buf.get_string_from_ascii()
    if not map.has(name):
        err = ERR_INVALID_DATA
        return null
    var serializer = map[name]
    var value = serializer.unserialize(stream)
    err = serializer.err
    return value

func serialize_as_buffer(object: Variant) -> PackedByteArray:
    Vars.temp.bas.clear()
    serialize(Vars.temp.bas, object)
    return Vars.temp.bas.submit()

func unserialize_from_buffer(buffer: PackedByteArray) -> Variant:
    Vars.temp.bas.load(buffer)
    return unserialize(Vars.temp.bas)

func add_defaults() -> void:
    add_serializer(Serializer.new())
    add_serializer(ArraySerializer.new())
    add_serializer(DictionarySerializer.new())
    add_serializer(NodeSerializer.new())
    
    add_serializer(ContentSerializer.new())
    add_serializer(ResourceTypeSerializer.new())
    add_serializer(ObjectTypeSerializer.new())
    add_serializer(RefObjectSerializer.new())
    add_serializer(RefObjectRefSerializer.new())
    add_serializer(RefObjectPackedSerializer.new())

    add_serializer(PlayerSerializer.new())
#     add_serializer(EntitySerializer.new())

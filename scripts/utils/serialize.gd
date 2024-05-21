class_name Utils_Serialize
extends Object

class Serializer extends Object:
    
    func _get_name() -> String: return "."
    func get_name() -> String: return _get_name()

    func _matched(object: Variant) -> bool: return true
    func matched(object: Variant) -> bool: return _matched(object)

    func _serialize(object: Variant) -> Variant: return object
    func serialize(object: Variant) -> Variant: return _serialize(object)
    
    func _unserialize(object: Variant) -> Variant: return object
    func unserialize(object: Variant) -> Variant: return _unserialize(object)

class NodeSerializer extends Serializer:
    func _get_name() -> String: return "n"
    func _matched(object: Variant) -> bool: return object is Node
    func _serialize(object: Variant) -> Variant: return Vars.tree.root.get_path_to(object)
    func _unserialize(object: Variant) -> Variant: return Vars.tree.root.get_node(object)

class ContentSerializer extends Serializer:
    func _get_name() -> String: return "c"
    func _matched(object: Variant) -> bool: return object is Content
    func _serialize(object: Variant) -> Variant: return object.index
    func _unserialize(object: Variant) -> Variant: return Vars.contents.get_content_by_index(object)

class RefObjectSerializer extends Serializer:
    func _get_name() -> String: return "r"
    func _matched(object: Variant) -> bool: return object is Vars_Objects.RefObject
    func _serialize(object: Variant) -> Variant: return object.object_id
    func _unserialize(object: Variant) -> Variant: return Vars.objects.get_object_or_null(object)

# class EntitySerializer extends Serializer:
#     func _get_name() -> String: return "e"
#     func _matched(object: Variant) -> bool: return object is Entity
#     func _serialize(object: Variant) -> Variant: return object.entity_id
#     func _unserialize(object: Variant) -> Variant: return Entity.get_entity_by_ref_or_null(object)

var serializers: Array[Serializer] = []
var map: Dictionary = {}

func add_serializer(serializer: Serializer) -> void:
    serializers.push_front(serializer)
    map[serializer.get_name()] = serializer

func serialize_object(object: Variant) -> Dictionary:
    for serializer in serializers:
        if not serializer.matched(object): continue
        return {
            "object": serializer.serialize(object),
            "type": serializer.get_name()
        }
    return {
        "object": object,
        "type": "."
    }

func serialize_args(args: Array) -> Dictionary:
    var outs = []
    var types = []
    for arg in args:
        var serialized = serialize_object(arg)
        outs.append(serialized.object)
        types.append(serialized.type)
    return {"args": outs, "types": types}

func unserialize_object(object: Variant, type: String) -> Variant:
    if not map.has(type): return object
    var serializer: Serializer = map[type]
    return serializer.unserialize(object)

func unserialize_args(args: Array, types: Array) -> Array:
    var outs = []
    for index in args.size():
        outs.append(unserialize_object(args[index], types[index]))
    return outs

func add_defaults() -> void:
    add_serializer(Serializer.new())
    add_serializer(NodeSerializer.new())
    add_serializer(ContentSerializer.new())
#     add_serializer(EntitySerializer.new())

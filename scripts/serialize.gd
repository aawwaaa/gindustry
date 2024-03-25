extends Node

class Serializer extends Object:
    
    func _get_name() -> String: return "."
    func get_name() -> String: return _get_name()

    func _matched(object: Variant) -> bool: return true
    func matched(object: Variant) -> bool: return _matched(object)

    func _serialize(object: Variant) -> Variant: return object
    func serialize(object: Variant) -> Variant: return _serialize(object)
    
    func _unserialize(object: Variant) -> Variant: return object
    func unserialize(object: Variant) -> Variant: return _unserialize(object)

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
            "type": serializer.type()
        }
    return {
        "object": object,
        "type": "."
    }

func serialize_args(args: Variant) -> Dictionary:
    var outs = []
    var types = []
    for arg in args:
        var serialized = serialize_object(arg)
        outs.push(serialized.object)
        types.push(serialized.type)
    return {"args": outs, "types": types}

func unserialize_object(object: Variant, type: String) -> Variant:
    # todo


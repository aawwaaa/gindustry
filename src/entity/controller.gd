class_name Controller
extends Node

var modules: Dictionary = {}
var entity_ref: RefObjectRef = RefObjectRef.new()
var entity: Entity:
    get: return entity_ref.v
    set(v): entity_ref.v = v



class ControllerModule extends Node:
    static var TYPE:
        get = get_type
    static func get_type() -> StringName:
        return &"Controller"
    
    func _get_type() -> StringName:
        return &"Controller"


class_name RefObjectPacked
extends RefCounted

var object: RefObject

static func pack(obj: RefObject) -> RefObjectPacked:
    var inst = RefObjectPacked.new()
    inst.object = obj
    return inst
    

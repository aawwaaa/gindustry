class_name __GDScriptAdapter__
extends Resource

var _instance: Object

func _init() -> void:
    _instance = GDScriptAdapterImplement.Create(&"__GDScriptAdapter__")
    _instance._SetAdapter(self)

# __GODOT_SIGNALS_INSERT__
# signal name(...args)
# func _signal_name(...args):
#     name.emit(...args)

# __GODOT_FIELDS_INSERT__
# var name: type:
#     get: return _instance.name
#     set: _instance.name = value

# __GODOT_VIRTUAL_METHODS_INSERT__
# func name(...args) -> type:
#     return default

# __GODOT_OVERRIDE_METHODS_INSERT__
# func name(...args) -> type:
#     return _DefaultImplement_name(...args)

# __GODOT_METHODS_INSERT__
# func name(...args) -> type:
#     return _instance.name(...args) as type



class_name __GDScriptAdapter__
extends Object

var _instance: __S_GDScriptAdapter__

func _init() -> void:
    _instance = GA.Create(&"__GDScriptAdapter__")
    GA.SetAdapter(_instance, self)

func get_instance() -> __S_GDScriptAdapter__:
    return _instance as __S_GDScriptAdapter__

# __GDSCRIPT_SIGNALS_INSERT__
# signal name(...args)
# func _signal_name(...args):
#     name.emit(...args)

# __GDSCRIPT_FIELDS_INSERT__
# var name: type:
#     get: return _instance.name
#     set: _instance.name = value

# __GDSCRIPT_VIRTUAL_METHODS_INSERT__
# func name(...args) -> type:
#     GA.HaventOverriden(_instance)
#     return default

# __GDSCRIPT_OVERRIDE_METHODS_INSERT__
# func name(...args) -> type:
#     GA.HaventOverriden(_instance)
#     return default

# __GDSCRIPT_METHODS_INSERT__
# func name(...args) -> type:
#     return _instance.name(...args) as type



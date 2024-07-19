class_name Builtin_Mod
extends Mod

static var inst: Builtin_Mod
var logger = Log.register_logger("Builtin_LogSource");

func _mod_init() -> void:
    inst = self
    await load_relative("/scripts/resource_types.gd").init(self)

func _init_contents() -> void:
    pass

func _load_contents() -> void:
    pass

func _post() -> void:
    pass


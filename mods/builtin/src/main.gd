class_name Builtin_Mod
extends Mod

static var inst: Builtin_Mod
var logger = Log.register_logger("Builtin_LogSource");

func _mod_init() -> void:
    inst = self
    await load_relative("mod://src/types.gd").init(self)

    await load_scripts("res://src")
    await load_scripts("mod://src")

func _init_contents() -> void:
    pass

func _load_contents() -> void:
    pass

func _post() -> void:
    DesktopInputHandler.load_handler()


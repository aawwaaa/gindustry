class_name ControlHandleComponent
extends EntityComponent

signal controller_added(controller: Controller)
signal controller_removed(controller: Controller)

static func _get_default_component_name_static() -> StringName:
    return &"ControlHandleComponent"
func _get_default_component_name() -> StringName:
    return &"ControlHandleComponent"

var controllers: Array[Controller] = []

var modules: Dictionary = {} # StringName => Array[ControllerModule](sorted by priority)

var check_control_callback: Callable # (source: Controller) -> bool

func add_controller(controller: Controller) -> void:
    controllers.append(controller)
    var comp_modules = controller.get_modules()
    for type in comp_modules:
        if not modules.has(type): modules[type] = []
        modules[type].append(comp_modules[type])
        modules[type].sort_custom(func(a, b):
            return a._get_priority() > b._get_priority()
        )
    controller_added.emit(controller)

func remove_controller(controller: Controller) -> void:
    controllers.erase(controller)
    var comp_modules = controller.get_modules()
    for type in comp_modules:
        modules[type].erase(comp_modules[type])
        if modules[type].size() == 0: modules.erase(type)
    controller_removed.emit(controller)

func check_control(source: Controller) -> bool:
    return check_control_callback.call(source) \
            if check_control_callback \
            else true

func get_module(type: StringName) -> Controller.ControllerModule:
    if not modules.has(type): return null
    if modules[type].size() == 0: return null
    return modules[type][0]

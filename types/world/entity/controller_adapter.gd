class_name ControllerAdapter
extends Node

signal controller_added(controller: Controller)
signal controller_removed(controller: Controller)

signal operation_received(operation: String, args: Array[Variant])
signal remote_operation_received(from: ControllerAdapter, operation: String, args: Array[Variant])

@export var main_node: Node2D;
@export var entity_node: Entity;

"""
默认控制器, 由0~length优先级依次递减
新控制器加入后将重新排序
"""
@export var controllers: Array[Controller] = [];

"""
可用的属性, main_node.get_attribute(attribute: String) -> Variant
"""
@export var available_attributes: Array[String] = [];
"""
可用的操作, 会发出信号operation_received
"""
@export var available_operations: Array[String] = [];
@export var available_remote_operations: Array[String] = [];

func _ready() -> void:
    load_adapter()

func _check_access(controller: Controller) -> bool:
    return true

func get_attribute(key: String) -> Variant:
    if not available_attributes.has(key):
        return null
    return main_node.get_attribute(key)

func get_adapter_id() -> int:
    return entity_node.entity_id

func load_adapter() -> void:
    if Controller.adapter_targets.has(self.get_adapter_id()):
        for controller in Controller.adapter_targets[self.get_adapter_id()]:
            add_controller(controller)
    Controller.adapter_targets[self.get_adapter_id()] = self

func add_controller(controller: Controller) -> void:
    if not _check_access(controller):
        return
    controllers.append(controller);
    controllers.sort_custom(func(a: Controller, b: Controller):
        return b._get_priority() - a._get_priority())
    controller.accept_adapter(self);
    controller_added.emit(controller)

func remove_controller(controller: Controller) -> void:
    controllers.remove_at(controllers.find(controller))
    controller_removed.emit(controller)

func operate(controller: Controller, operation: String, args: Array[Variant] = []) -> void:
    if controller not in controllers:
        return
    if operation not in available_operations:
        return
    operation_received.emit(operation, args)

func operate_remote(controller: Controller, operation: String, args: Array[Variant] = []) -> bool:
    if controller not in controllers:
        return false
    if operation not in available_remote_operations:
        return false
    var access_target = entity_node.access_target
    if not access_target:
        return false
    if not access_target.get_entity().get_adapter("controller"):
        return false
    access_target.get_entity().get_adapter("controller").remote_operation_received.emit(self, operation, args)
    return true

func update_control(type: String, updater: Callable, append_args: Array[String] = []) -> bool:
    for controller in controllers:
        if not controller._get_attributes().has(type):
            continue
        var call_args = [controller, self]
        call_args.append_array(append_args)
        updater.callv(call_args)
        return true
    return false

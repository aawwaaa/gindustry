class_name InventoryPanel
extends ScrollContainer

@export var interfaces: Array[AdapterInterface] = []

var entity: Entity:
    set = set_entity;
var main_node: Node2D

signal request_operation(operation: String, args: Array[Variant])
signal request_remote_operation(operation: String, args: Array[Variant])

func set_entity(v: Entity) -> void:
    entity = v
    for interface in interfaces:
        interface.entity = v
        interface.remote_entity = Game.current_player.get_controller().target.entity_node != v
        if not interface.request_operation.is_connected(_on_interface_request_operation):
            interface.request_operation.connect(_on_interface_request_operation)
        if not interface.request_remote_operation.is_connected(_on_interface_request_remote_operation):
            interface.request_remote_operation.connect(_on_interface_request_remote_operation)
        interface.load_interface()

func _on_interface_request_operation(operation: String, args: Array[Variant]) -> void:
    request_operation.emit(operation, args)

func _on_interface_request_remote_operation(operation: String, args: Array[Variant]) -> void:
    request_remote_operation.emit(operation, args)

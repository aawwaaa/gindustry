extends Node2D

@export var entity: Building
@onready var content_select: ContentSelectAdapter = $ContentSelectAdapter
@onready var item_select: ItemSelectAdapter = $ItemSelectAdapter

func get_entity() -> Entity:
    return entity

func _on_building_input_operation(operation: String, args: Array) -> void:
    if operation == "open_panel":
        Global.input_handler.call_input_processor((ItemAdapter.DEFAULT_NAME), "access_target_ui", [self])

func _ready() -> void:
    item_select.content_display_group = entity.shadow.get_sub_node("group")

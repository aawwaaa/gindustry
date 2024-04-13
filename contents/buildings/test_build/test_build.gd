extends Node2D

@export var entity: Building
@onready var content_select: ContentSelectAdapter = $ContentSelectAdapter
@onready var item_select: ItemSelectAdapter = $ItemSelectAdapter

func get_entity() -> Entity:
    return entity

func _on_building_input_operation(operation: String, args: Array) -> void:
    if operation == InputInteracts.INTERACT_I_DIRECT_INTERACT:
        Global.input_handler.interact_access_target_ui(self)

func _ready() -> void:
    item_select.content_display_group = entity.shadow.get_sub_node("group")

func get_config() -> Variant:
    return item_select.get_config()

func set_config(config: Variant) -> void:
    item_select.set_config(config)

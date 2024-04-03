class_name EntityInfoContainer
extends VBoxContainer

@onready var container: VBoxContainer = self

func _on_input_handler_changed(handler: InputHandler, old: InputHandler) -> void:
    Utils.signal_dynamic_connect(handler, old, "focused_entity_changed", \
            _on_input_handler_focused_entity_changed)
    _on_input_handler_focused_entity_changed( \
            handler.entity if handler else null, \
            old.entity if old else null)

func _on_input_handler_focused_entity_changed(entity: Entity, old: Entity) -> void:
    for info in container.get_children(): info.queue_free()
    if not entity: return
    var panel = UIPanelAdapter.create_entity_info_panel_for(entity)
    if not panel: return
    container.add_child(panel)

func _ready() -> void:
    Global.input_handler_changed.connect(_on_input_handler_changed)

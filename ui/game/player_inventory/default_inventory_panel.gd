class_name PlayerInventoryPanel
extends InventoryPanel

func _on_child_request_operation(operate: String, args: Array) -> void:
    request_operation.emit(operate, args)

func _on_child_request_remote_operation(operate: String, args: Array) -> void:
    request_remote_operation.emit(operate, args)

func _on_game_ui_ui_hidden() -> void:
    for child in %TabContainer.get_children():
        if "_on_game_ui_ui_hidden" in child:
            child._on_game_ui_ui_hidden()

func add_tab(tab: Control) -> void:
    %TabContainer.add_child(tab)
    tab.request_operation.connect(_on_child_request_operation)
    tab.request_remote_operation.connect(_on_child_request_remote_operation)


extends CenterContainer

func add_button(button_text: String, handler: Callable) -> void:
    var button = Button.new();
    button.text = button_text;
    button.size_flags_vertical = Control.SIZE_FILL;
    button.pressed.connect(handler);
    button.auto_translate = true;
    %Buttons.add_child(button);

func _ready() -> void:
    for node in get_children():
        if node == $PanelContainer:
            continue;
        remove_child(node);
        node.size_flags_vertical = Control.SIZE_FILL;
        %Buttons.add_child(node);

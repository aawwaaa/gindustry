class_name ContentSelectorWindow
extends Window

signal submit(content: Content, amount: float)

class SelectContentReturnValue extends RefCounted:
    var content: Content
    var amount: float

    func _init(content: Content, amount: float) -> void:
        self.content = content
        self.amount = amount

var content_type_to_panel: Dictionary = {}
var content_type_to_button: Dictionary = {}
var current_selected_button: Button = null
var current_type: ContentType = null

var current_content: Content = null
var current_amount: float = 1:
    set = set_current_amount
var current_allow_float: bool = false

func _on_game_ui_contents_loaded() -> void:
    for content_type in Types.get_types(ContentType.TYPE).values() as Array[ContentType]:
        if not content_type.selector_panel: return
        var instance = content_type.selector_panel.instantiate()
        %Panelcontainer.add_child(instance)
        instance.selected_changed.connect(_on_instance_selected_changed)
        instance.load_contents()
        instance.hide_panel()

        # TODO generate button, signal

        content_type_to_panel[content_type] = instance

func show_content_type(content_type: ContentType) -> void:
    if current_type:
        content_type_to_panel[current_type].hide_panel()
        # TODO unselect button
    content_type_to_panel[content_type].show_panel()
    current_type = content_type
    # TODO select button

func select_content(content: Content, amount: float, allow_float: bool = false) -> SelectContentReturnValue:
    current_content = content
    current_amount = amount
    current_allow_float = allow_float
    await submit
    return SelectContentReturnValue.new(current_content, current_amount)

func set_current_content(value: Content) -> void:
    if value:
        show_content_type(value.get_type())
        var texture = content_type_to_panel[current_type].get_texture_for(value)
        %CurrentSelected.texture = texture
    else:
        %CurrentSelected.texture = null
    current_content = value

func set_current_amount(value: float) -> void:
    current_amount = value
    %AmountSlider.set_value_no_signal(value)
    %Amount.text = value

func set_current_allow_float(value: bool) -> void:
    current_allow_float = value
    %AmountSlider.step = 0.1 if value else 1

func _on_amount_text_changed(new_text: String) -> void:
    var number = float(new_text)
    if number == NAN:
        current_amount = current_amount
        return
    if not current_allow_float and floorf(number) != number:
        current_amount = current_amount
        return
    current_amount = number

func _on_amount_slider_value_changed(value: float) -> void:
    if not current_allow_float and floorf(value) != value:
        current_amount = current_amount
        return
    current_amount = value

func _on_confirm_pressed() -> void:
    pass # Replace with function body.

func _on_cancel_pressed() -> void:
    pass # Replace with function body.

func _on_clear_pressed() -> void:
    pass # Replace with function body.
func _on_instance_selected_changed(selected: Content) -> void:
    pass

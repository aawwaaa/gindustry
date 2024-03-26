class_name ContentSelectorLayer
extends CanvasLayer

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
var current_filter: Callable; # (type: ContentType) -> bool
var old_content: Content = null
var old_amount: float = 1;
var current_allow_float: bool = false

func _on_game_ui_contents_loaded() -> void:
    var types = Types.get_types(ContentType.TYPE).values().duplicate() as Array[ContentType]
    types.sort_custom(func(a, b): return a.order < b.order)
    var first: ContentType = null
    for content_type in types:
        if not content_type.selector_panel: continue

        if not first: first = content_type

        var button = Button.new()
        button.toggle_mode = true
        button.icon = content_type.icon
        button.focus_mode = Control.FOCUS_NONE
        %ContentTypes.add_child(button)
        button.pressed.connect(func(): show_content_type(content_type))

        content_type_to_button[content_type] = button

        var instance = content_type.selector_panel.instantiate()
        instance.content_type = content_type
        instance.size_flags_vertical = Control.SIZE_EXPAND_FILL
        %SelectorPanels.add_child(instance)
        instance.selected_changed.connect(_on_instance_selected_changed)
        instance.load_contents()
        instance.hide_panel()

        content_type_to_panel[content_type] = instance
    show_content_type(first)

func show_content_type(content_type: ContentType) -> void:
    if current_type:
        content_type_to_panel[current_type].hide_panel()
        content_type_to_button[current_type].button_pressed = false
    if not content_type:
        current_type = null
        return
    content_type_to_panel[content_type].show_panel()
    content_type_to_button[content_type].button_pressed = true
    current_type = content_type

func select_content(content: Content, amount: float, allow_float: bool = false, filter: Callable = func(v): return true) -> SelectContentReturnValue:
    old_content = content
    old_amount = amount
    current_content = content
    current_amount = amount
    current_allow_float = allow_float
    current_filter = filter
    update_filter()
    visible = true
    await submit
    return SelectContentReturnValue.new(current_content, current_amount)

func update_filter() -> void:
    var first: ContentType = null
    var types = Types.get_types(ContentType.TYPE).values() as Array[ContentType]
    for content_type in types:
        var visible = current_filter.call(content_type) 
        content_type_to_button[content_type].visible = visible
        if not visible: continue
        first = content_type
    if current_type:
        var visible = current_filter.call(current_type)
        if visible: return
    show_content_type(first)

func set_current_content(value: Content) -> void:
    current_content = value
    if value:
        show_content_type(value.get_content_type())
        var texture = content_type_to_panel[current_type].get_texture_for(value)
        %CurrentSelected.texture = texture
    else:
        %CurrentSelected.texture = null

func set_current_amount(value: float) -> void:
    current_amount = value
    %AmountSlider.set_value_no_signal(value)
    if not %Amount.has_focus():
        %Amount.text = str(value)

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
    submit.emit(current_content, current_amount)
    visible = false

func _on_cancel_pressed() -> void:
    current_content = old_content
    current_amount = old_amount
    submit.emit(old_content, old_amount)
    visible = false

func _on_clear_pressed() -> void:
    submit.emit(null, 0)
    visible = false

func _on_instance_selected_changed(selected: Content) -> void:
    set_current_content(selected)

func _on_drag_button_gui_input(event: InputEvent) -> void:
    var velocity = Vector2.ZERO
    if event is InputEventMouseMotion:
        if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
            velocity = event.relative
    if event is InputEventScreenDrag:
        velocity = event.relative
    if velocity != Vector2.ZERO:
        %Panel.position += velocity

func _on_amount_text_submitted(new_text: String) -> void:
    %Amount.release_focus()

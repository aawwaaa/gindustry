class_name CategorySelectorPanel
extends ContentSelectorPanel

@export var category_type: ResourceTypeType
@export_group("property_names", "property_name_")
@export var property_name_category_icon: StringName
@export var property_name_category_order: StringName
@export var property_name_category_contents: StringName

func get_icon_for_category(category: ResourceType) -> Texture2D:
    return category.get(property_name_category_icon)

func get_order_for_category(category: ResourceType) -> int:
    return category.get(property_name_category_order)

func get_contents_for_category(category: ResourceType) -> Array:
    var contents = category.get(property_name_category_contents)
    return contents.filter(func(v): return v.get_content_type() == content_type)

@onready var category_button_container: HBoxContainer = %Categories
@onready var containers_container: VBoxContainer = %Containers

var category_group: ButtonGroup
var button_to_category: Dictionary = {}
var category_to_button: Dictionary = {}
var category_to_container: Dictionary = {}
var current_category: ResourceType = null

var content_group: ButtonGroup
var button_to_content: Dictionary = {}
var content_to_button: Dictionary = {}
var content_to_category: Dictionary = {}

func _load_contents() -> void:
    category_group = ButtonGroup.new()
    content_group = ButtonGroup.new()
    content_group.allow_unpress = true

    var categories = G.types.get_types(category_type).values().duplicate()
    categories.sort_custom(func(a, b): return get_order_for_category(a) < get_order_for_category(b))
    for category in categories:
        var category_button = Button.new()
        category_button.toggle_mode = true
        category_button.icon = get_icon_for_category(category)
        category_button.button_group = category_group
        category_button.focus_mode = FOCUS_NONE
        category_button.toggled.connect(_on_category_button_toggled)
        category_button_container.add_child(category_button)
        button_to_category[category_button] = category
        category_to_button[category] = category_button

        var container = HFlowContainer.new()
        container.size_flags_vertical = Control.SIZE_EXPAND_FILL
        container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var sorted = Content.sort_content_list(get_contents_for_category(category))
        for content in sorted:
            var content_button = Button.new()
            content_button.icon = get_texture_for(content)
            content_button.toggle_mode = true
            content_button.button_group = content_group
            content_button.focus_mode = Control.FOCUS_NONE
            content_button.tooltip_text = "{localized} ( {full_id} )".format({
                localized = content.get_localized_name(),
                full_id = content.full_id
            })
            content_button.toggled.connect(_on_content_button_toggled)
            container.add_child(content_button)
            button_to_content[content_button] = content
            content_to_button[content] = content_button
            content_to_category[content] = category
        
        container.visible = false
        containers_container.add_child(container)
        category_to_container[category] = container

    show_category(categories.front())

func show_category(category: ResourceType) -> void:
    if current_category:
        category_to_container[current_category].visible = false
        category_to_button[current_category].set_pressed_no_signal(false)
    category_to_container[category].visible = true
    category_to_button[category].set_pressed_no_signal(true)
    current_category = category

func _on_category_button_toggled(pressed: bool) -> void: 
    var button = category_group.get_pressed_button()
    if not button: return
    show_category(button_to_category[button])

func _on_content_button_toggled(pressed: bool) -> void:
    var button = content_group.get_pressed_button()
    if not button:
        selected_changed.emit(null)
        return
    selected_changed.emit(button_to_content[button])

func _set_selected(selected: Content) -> void:
    if not selected:
        var button = content_group.get_pressed_button()
        if not button: return
        button.button_pressed = false
        return
    show_category(content_to_category[selected])
    content_to_button[selected].button_pressed = true


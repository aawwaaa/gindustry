class_name BuildUI
extends Control

signal rotation_changed(rotation: int);
signal confirm_build();
signal open_schematics();
signal build_paused_changed(paused: bool);
signal selected_building_type_changed(building_type: BuildingType);
signal build_plan_operate(operation: String);

const pause_icon = preload("res://assets/ui/icons/pause.tres")
const resume_icon = preload("res://assets/ui/icons/resume.tres")

var building_button_group: ButtonGroup;
var building_category_button_group: ButtonGroup;

var current_rotation: int = 0;
var current_rotation_rad: float:
    get: return current_rotation * 0.5 * PI
var build_mode: String = "place";
var build_paused: bool = false;

var selected_building_type: BuildingType:
    set(v):
        selected_building_type = v
        selected_building_type_changed.emit(v)
        update_child_visible()
        building_type_panel.apply_data(v)
var has_build_plan: bool = false:
    set(v):
        has_build_plan = v
        update_child_visible()
var has_schematic: bool = false:
    set(v):
        has_schematic = v
        update_child_visible()

@onready var building_type_panel: BuildingTypePanel = %BuildingTypePanel

func _ready() -> void:
    building_button_group = ButtonGroup.new();
    building_button_group.allow_unpress = true
    building_category_button_group = ButtonGroup.new();

func show_category(category: BuildingCategory) -> void:
    for child in %BuildingTypes.get_children():
        child.queue_free();

    var sorted = Content.sort_content_list(category.building_types)

    for building_type in sorted:
#         var node = Control.new()
#         node.custom_minimum_size = Vector2(48, 48)
        var button = Button.new();
        button.icon = building_type.icon;
        button.button_group = building_button_group;
#         button.scale = node.custom_minimum_size / button.icon.get_size();
        button.focus_mode = Control.FOCUS_NONE
        button.toggle_mode = true
        if selected_building_type == building_type: button.button_pressed = true
        button.toggled.connect(set_selected_building_type.bind(building_type))
#         node.add_child(button)
        %BuildingTypes.add_child(button);

func set_selected_building_type(toggled: bool, building_type: BuildingType) -> void:
    if not toggled:
        selected_building_type = null
        return
    selected_building_type = building_type

func load_categories() -> void:
    for child in %BuildingCategories.get_children():
        child.queue_free();

    var ordered: Array = Types.get_types(BuildingCategory.TYPE).values().duplicate()

    ordered.sort_custom(func(a, b): return a.order < b.order)

    var first: BuildingCategory

    for category in ordered:
        var button = Button.new();
        button.icon = category.icon;
        button.button_group = building_category_button_group;
        button.focus_mode = Control.FOCUS_NONE
        button.toggle_mode = true
        if not first:
            first = category
            button.button_pressed = true
        button.pressed.connect(show_category.bind(category))
        %BuildingCategories.add_child(button);

    show_category(first)

func _on_rotation_pressed() -> void:
    current_rotation += 1;
    current_rotation %= 4;
    %Rotation.icon.region.position.x = current_rotation * 32;
    rotation_changed.emit(current_rotation);

func _on_break_toggled(toggled_on: bool) -> void:
    if toggled_on == true: build_mode = "break";
    if not toggled_on:
        if %Copy.button_pressed: build_mode = "copy";
        else: build_mode = "place";

func _on_copy_toggled(toggled_on: bool) -> void:
    if toggled_on == true: build_mode = "copy";
    if not toggled_on:
        if %Break.button_pressed: build_mode = "break";
        else: build_mode = "place";

func toggle_build_mode_buttons(disable: bool) -> void:
    %Break.visible = not visible
    %Copy.visible = not visible

func _on_confirm_pressed() -> void:
    confirm_build.emit();

func _on_schematic_pressed() -> void:
    open_schematics.emit();

func _on_pause_pressed() -> void:
    build_paused = not build_paused;
    %Pause.icon = resume_icon if build_paused else pause_icon
    build_paused_changed.emit(build_paused);

func update_child_visible() -> void:
    %SchematicTools.visible = has_schematic
    %Cancel.visible = has_schematic or has_build_plan or selected_building_type != null

func _on_cancel_pressed() -> void:
    if has_schematic:
        build_plan_operate.emit("clear");
        has_schematic = false
        return
    if selected_building_type:
        selected_building_type = null
        building_button_group.get_pressed_button().button_pressed = false
        return
    if has_build_plan:
        build_plan_operate.emit("cancel");
        has_build_plan = false
        return

func _on_vertical_flip_pressed() -> void:
    build_plan_operate.emit("vertical-flip");

func _on_horizonal_flip_pressed() -> void:
    build_plan_operate.emit("horizonal-flip");

func _on_rotate_left_pressed() -> void:
    build_plan_operate.emit("rotate-left");

func _on_rotate_right_pressed() -> void:
    build_plan_operate.emit("rotate-right");

func _on_save_pressed() -> void:
    build_plan_operate.emit("save");

func _on_game_ui_contents_loaded() -> void:
    load_categories()

func _on_game_ui_ui_hidden() -> void:
    selected_building_type = null
    has_build_plan = false
    has_schematic = false

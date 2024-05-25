class_name DebugMenu_Basic_RootWorlds
extends PanelContainer

var button_group: ButtonGroup = ButtonGroup.new()
var button_to_world: Dictionary = {}

func _ready() -> void:
    await get_tree().process_frame
    Vars.worlds.worlds_changed.connect(_on_worlds_changed)
    button_group = ButtonGroup.new()

func _on_worlds_changed() -> void:
    for button in button_to_world:
        button.queue_free();
    button_to_world.clear();

    for world in Vars.worlds.worlds.values():
        if not world.is_root_world: return
        var button = Button.new()
        button.text = world.name
        button.button_group = button_group
        button.toggle_mode = true;
        button_to_world[button] = world
        %VBoxContainer.add_child(button)

func get_current_selected() -> World:
    if button_group.get_pressed_button() == null: return null
    return button_to_world[button_group.get_pressed_button()]

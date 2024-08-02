class_name Settings
extends LayerWindow

static var instance: Settings
static var groups: Dictionary = {}

static var general: SettingsUIGroup
static var about: SettingsUIGroup

static var desktop = SettingsUIGroup

static func create(group_name: String) -> SettingsUIGroup:
    var node = VBoxContainer.new()
    node.name = group_name
    instance.get_node("%TabContainer").add_child(node)
    var group = SettingsUIGroup.new()
    group.node = node
    groups[group_name] = group
    group.configs = Vars.configs.configs
    return group

func _ready() -> void:
    super._ready()
    instance = self

func load_tabs() -> void:
    general = load("res://ui/menus/settings/general.gd").new().load()
    about = load("res://ui/menus/settings/about.gd").new().load()

    if OS.has_feature("pc"):
        desktop = load("res://ui/menus/settings/desktop.gd").new().load()

func _on_close_requested() -> void:
    for group in groups.values():
        group.save_setting()
    Vars.configs.save_configs()
    hide()

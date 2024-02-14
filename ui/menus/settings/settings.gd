class_name Settings
extends Window

static var instance: Settings
static var groups: Dictionary = {}

static var general: SettingsUIGroup
static var about: SettingsUIGroup

class SettingsUIGroup extends RefCounted:
    var configs: ConfigsGroup = null;
    var parent: SettingsUIGroup

    var node: VBoxContainer
    var childs_load: Array[Callable] = []
    var childs_save: Array[Callable] = []

    func _init(node: VBoxContainer) -> void:
        self.node = node

    func _get_configs() -> ConfigsGroup:
        if parent: return parent._get_configs()
        if configs == null: return Game.save_configs
        return configs

    func load() -> void:
        for load in childs_load:
            load.call()

    func save() -> void:
        for save in childs_save:
            save.call()

    func child_group(name: String) -> SettingsUIGroup:
        var label_panel = PanelContainer.new()
        label_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var margin_panel = MarginContainer.new()
        margin_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        margin_panel.add_theme_constant_override("margin_left", 16)
        var label = Label.new()
        label.text = name
        margin_panel.add_child(label)
        label_panel.add_child(margin_panel)
        node.add_child(label_panel)
        var body_margin = MarginContainer.new()
        body_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        body_margin.add_theme_constant_override("margin_left", 32)
        var body = VBoxContainer.new()
        body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        node.add_child(body)
        var group = SettingsUIGroup.new(body)
        group.parent = self
        childs_load.append(group.load.bind())
        childs_save.append(group.save.bind())
        return group

    func label(text: String) -> Label:
        var label = Label.new()
        label.text = text
        node.add_child(label)
        return label

    func add_child(node: Control) -> void:
        self.node.add_child(node)

    func add_child_with_label(label: String, child: Control) -> void:
        var line = HBoxContainer.new()
        line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var label_node = Label.new()
        label_node.text = label
        label_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        label_node.size_flags_stretch_ratio = 1
        line.add_child(label_node)
        line.add_child(child)
        node.add_child(line)

    func input(settings_key: String, default_value: String = "", tr_name: String = settings_key) -> LineEdit:
        var line = HBoxContainer.new()
        line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var label = Label.new()
        label.text = tr(tr_name)
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        label.size_flags_stretch_ratio = 1
        line.add_child(label)
        var input = LineEdit.new()
        input.text = _get_configs().g(settings_key, default_value)
        input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        input.size_flags_stretch_ratio = 3
        childs_load.append(func(): input.text = _get_configs().g(settings_key, default_value))
        childs_save.append(func(): _get_configs().p(settings_key, input.text))
        line.add_child(input)
        node.add_child(line)
        return input

    func checkbox(settings_key: String, default_value: bool = false, tr_name: String = settings_key) -> CheckBox:
        var line = HBoxContainer.new()
        line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var label = Label.new()
        label.text = tr(tr_name)
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        label.size_flags_stretch_ratio = 1
        line.add_child(label)
        var checkbox = CheckBox.new()
        checkbox.button_pressed = _get_configs().g(settings_key, default_value)
        checkbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        checkbox.size_flags_stretch_ratio = 3
        childs_load.append(func(): checkbox.button_pressed = _get_configs().g(settings_key, default_value))
        childs_save.append(func(): _get_configs().p(settings_key, checkbox.button_pressed))
        line.add_child(checkbox)
        node.add_child(line)
        return checkbox

    func menu_button(settings_key: String, values: Dictionary, default_value: String = "", tr_name: String = settings_key) -> MenuButton:
        var line = HBoxContainer.new()
        line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var label = Label.new()
        label.text = tr(tr_name)
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        label.size_flags_stretch_ratio = 1
        line.add_child(label)
        var config_id: String = _get_configs().g(settings_key, default_value)
        var menu_button = MenuButton.new()
        menu_button.text = values[config_id]
        menu_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        menu_button.size_flags_stretch_ratio = 3
        menu_button.flat = false
        var values_values = values.values()
        var values_keys = values.keys()
        for id in range(values.size()):
            if values_keys[id] == "": continue
            menu_button.get_popup().add_item(values_values[id], id)
        menu_button.get_popup().id_pressed.connect(func(id):
            config_id = values.keys()[id]
            menu_button.text = values.values()[id]
        )
        childs_load.append(func():
            config_id = _get_configs().g(settings_key, default_value)
            menu_button.text = values[config_id]
        )
        childs_save.append(func(): _get_configs().p(settings_key, config_id))
        line.add_child(menu_button)
        node.add_child(line)
        return menu_button

static func create(name: String) -> SettingsUIGroup:
    var node = VBoxContainer.new()
    node.name = name
    instance.get_node("TabContainer").add_child(node)
    var group = SettingsUIGroup.new(node)
    groups[name] = group
    group.configs = Global.configs
    return group

func _ready() -> void:
    instance = self

func load_tabs() -> void:
    general = load("res://ui/menus/settings/general.gd").new().load()
    about = load("res://ui/menus/settings/about.gd").new().load()

func _on_close_requested() -> void:
    for group in groups.values():
        group.save()
    Global.save_configs()
    hide()

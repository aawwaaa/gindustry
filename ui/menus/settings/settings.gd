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

    func _init(n: VBoxContainer) -> void:
        self.node = n

    func _get_configs() -> ConfigsGroup:
        if parent: return parent._get_configs()
        if configs == null: return Vars.game.save_configs
        return configs

    func load() -> void:
        for load_config in childs_load:
            load_config.call()

    func save() -> void:
        for save_config in childs_save:
            save_config.call()

    func child_group(name: String) -> SettingsUIGroup:
        var label_panel = PanelContainer.new()
        label_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var margin_panel = MarginContainer.new()
        margin_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        margin_panel.add_theme_constant_override("margin_left", 16)
        var label_node = Label.new()
        label_node.text = name
        margin_panel.add_child(label_node)
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
        childs_load.append(func(): group.load())
        childs_save.append(func(): group.save())
        return group

    func label(text: String) -> Label:
        var label_node = Label.new()
        label_node.text = text
        node.add_child(label_node)
        return label_node

    func add_child(n: Control) -> void:
        self.node.add_child(n)

    func add_child_with_label(label_text: String, child: Control) -> void:
        var line = HBoxContainer.new()
        line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var label_node = Label.new()
        label_node.text = label_text
        label_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        label_node.size_flags_stretch_ratio = 1
        line.add_child(label_node)
        line.add_child(child)
        node.add_child(line)

    func input(settings_key: String, default_value: String = "", tr_name: String = settings_key) -> LineEdit:
        var line = HBoxContainer.new()
        line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var label_node = Label.new()
        label_node.text = tr(tr_name)
        label_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        label_node.size_flags_stretch_ratio = 1
        line.add_child(label_node)
        var input_node = LineEdit.new()
        input_node.text = _get_configs().g(settings_key, default_value)
        input_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        input_node.size_flags_stretch_ratio = 3
        childs_load.append(func(): input_node.text = _get_configs().g(settings_key, default_value))
        childs_save.append(func(): _get_configs().p(settings_key, input_node.text))
        line.add_child(input_node)
        node.add_child(line)
        return input_node

    func checkbox(settings_key: String, default_value: bool = false, tr_name: String = settings_key) -> CheckBox:
        var line = HBoxContainer.new()
        line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var label_node = Label.new()
        label_node.text = tr(tr_name)
        label_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        label_node.size_flags_stretch_ratio = 1
        line.add_child(label_node)
        var checkbox_node = CheckBox.new()
        checkbox_node.button_pressed = _get_configs().g(settings_key, default_value)
        checkbox_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        checkbox_node.size_flags_stretch_ratio = 3
        childs_load.append(func(): checkbox_node.button_pressed = _get_configs().g(settings_key, default_value))
        childs_save.append(func(): _get_configs().p(settings_key, checkbox_node.button_pressed))
        line.add_child(checkbox_node)
        node.add_child(line)
        return checkbox_node

    func menu_button(settings_key: String, values: Dictionary, default_value: String = "", tr_name: String = settings_key) -> MenuButton:
        var line = HBoxContainer.new()
        line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var label_node = Label.new()
        label_node.text = tr(tr_name)
        label_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        label_node.size_flags_stretch_ratio = 1
        line.add_child(label_node)
        var config_id: String = _get_configs().g(settings_key, default_value)
        var menu_button_node = MenuButton.new()
        menu_button_node.text = values[config_id]
        menu_button_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        menu_button_node.size_flags_stretch_ratio = 3
        menu_button_node.flat = false
        var values_values = values.values()
        var values_keys = values.keys()
        for id in range(values.size()):
            if values_keys[id] == "": continue
            menu_button_node.get_popup().add_item(values_values[id], id)
        menu_button_node.get_popup().id_pressed.connect(func(id):
            config_id = values.keys()[id]
            menu_button_node.text = values.values()[id]
        )
        childs_load.append(func():
            config_id = _get_configs().g(settings_key, default_value)
            menu_button_node.text = values[config_id]
        )
        childs_save.append(func(): _get_configs().p(settings_key, config_id))
        line.add_child(menu_button_node)
        node.add_child(line)
        return menu_button_node

static func create(group_name: String) -> SettingsUIGroup:
    var node = VBoxContainer.new()
    node.name = group_name
    instance.get_node("TabContainer").add_child(node)
    var group = SettingsUIGroup.new(node)
    groups[group_name] = group
    group.configs = Vars.configs.configs
    return group

func _ready() -> void:
    instance = self

func load_tabs() -> void:
    general = load("res://ui/menus/settings/general.gd").new().load()
    about = load("res://ui/menus/settings/about.gd").new().load()

func _on_close_requested() -> void:
    for group in groups.values():
        group.save()
    Vars.configs.save_configs()
    hide()

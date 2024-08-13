class_name SettingsUIGroup
extends Setting

var configs: ConfigsGroup:
    get: return parent_group.configs if not configs else configs
    set(v): configs = v
var node: VBoxContainer

var childs: Array[Setting] = []
var parent_group: SettingsUIGroup

func load_setting() -> void:
    for setting in childs:
        setting.load_setting()

func save_setting() -> void:
    for setting in childs:
        setting.save_setting()

func add(setting: Setting) -> void:
    setting.group = self
    childs.append(setting)
    setting.add_to_group()
    setting.load_setting()

func add_to_group() -> void:
    node = VBoxContainer.new()
    node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    
    var panel = PanelContainer.new()
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    node.add_child(panel)

    var label_node = Label.new()
    label_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    label_node.text = name
    panel.add_child(label_node)

    group.node.add_child(node)

func child_group(child_name: String) -> SettingsUIGroup:
    var child = SettingsUIGroup.new()
    child.name = child_name
    child.parent_group = self
    add(child)
    return child

func label(text: String) -> Label:
    var label_node = Label.new()
    label_node.text = text
    node.add_child(label_node)
    return label_node

func input(setting_name: String, key: ConfigsGroup.ConfigKey) -> InputSetting:
    var setting = InputSetting.new()
    setting.name = setting_name
    setting.config_key = key
    add(setting)
    return setting

func multiline(setting_name: String, key: ConfigsGroup.ConfigKey) -> MultilineInputSetting:
    var setting = MultilineInputSetting.new()
    setting.name = setting_name
    setting.config_key = key
    add(setting)
    return setting

func number(setting_name: String, key: ConfigsGroup.ConfigKey) -> NumberSetting:
    var setting = NumberSetting.new()
    setting.name = setting_name
    setting.config_key = key
    add(setting)
    return setting

func checkbox(setting_name: String, key: ConfigsGroup.ConfigKey) -> CheckboxSetting:
    var setting = CheckboxSetting.new()
    setting.name = setting_name
    setting.config_key = key
    add(setting)
    return setting

func select(setting_name: String, key: ConfigsGroup.ConfigKey, selections: Dictionary) -> SelectSetting:
    var setting = SelectSetting.new()
    setting.name = setting_name
    setting.config_key = key
    setting.selections = selections
    add(setting)
    return setting

class Setting extends RefCounted:
    signal setting_changed(new_value: Variant)

    var group: SettingsUIGroup
    var name: String
    var config_key: ConfigsGroup.ConfigKey

    func add_to_group() -> void: pass
    func default_add_line() -> HBoxContainer:
        var line = HBoxContainer.new()
        line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        group.node.add_child(line)

        var label_node = Label.new()
        label_node.text = name
        label_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        label_node.size_flags_stretch_ratio = 3
        line.add_child(label_node)

        var container = HBoxContainer.new()
        container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        container.size_flags_stretch_ratio = 5
        line.add_child(container)
        return container

    func get_config() -> Variant: return group.configs.k(config_key)
    func set_config(v: Variant) -> void:
        group.configs.pk(config_key, v)
        setting_changed.emit(v)

    func load_setting() -> void: pass
    func save_setting() -> void: pass

class InputSetting extends Setting:
    var validator: Callable = func(_v: String): return true
    var line_edit: LineEdit

    func add_to_group() -> void:
        var container = default_add_line()

        line_edit = LineEdit.new()
        line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        line_edit.text_submitted.connect(_on_line_edit_submitted)
        container.add_child(line_edit)

    func _on_line_edit_submitted(new_text: String) -> void:
        if not validator.call(new_text):
            load_setting()
            return
        save_setting()

    func load_setting() -> void:
        line_edit.text = str(get_config())
    func save_setting() -> void:
        set_config(line_edit.text)

class MultilineInputSetting extends Setting:
    var validator: Callable = func(_v: String): return true
    var text_edit: TextEdit

    func add_to_group() -> void:
        var container = default_add_line()

        text_edit = TextEdit.new()
        text_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        text_edit.text_submitted.connect(_on_text_edit_submitted)
        container.add_child(text_edit)

    func _on_text_edit_submitted(new_text: String) -> void:
        if not validator.call(new_text):
            load_setting()
            return
        save_setting()

    func load_setting() -> void:
        text_edit.text = str(get_config())
    func save_setting() -> void:
        set_config(text_edit.text)

class NumberSetting extends Setting:
    var spin_box: SpinBox
    var validator: Callable = func(_v: float): return true

    func add_to_group() -> void:
        var container = default_add_line()

        spin_box = SpinBox.new()
        spin_box.step = 0.00001
        spin_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        spin_box.value_changed.connect(_on_spin_box_value_changed)
        container.add_child(spin_box)

    func _on_spin_box_value_changed(new_value: float) -> void:
        if not validator.call(new_value):
            load_setting()
            return
        save_setting()

    func load_setting() -> void:
        spin_box.value = get_config()
    func save_setting() -> void:
        set_config(spin_box.value)

class CheckboxSetting extends Setting:
    var checkbox: CheckBox

    func add_to_group() -> void:
        var container = default_add_line()

        checkbox = CheckBox.new()
        checkbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        checkbox.toggled.connect(_on_checkbox_toggled)
        container.add_child(checkbox)

    func _on_checkbox_toggled(button_pressed: bool) -> void:
        set_config(button_pressed)

    func load_setting() -> void:
        checkbox.button_pressed = get_config()
    func save_setting() -> void:
        set_config(checkbox.button_pressed)

class SelectSetting extends Setting:
    var selections: Dictionary # stored-key => display-tr-text(do tr first)
    var selections_mapping: Dictionary # item-id => stored-key
    var selections_mapping_reversed: Dictionary # stored-key => item-id
    var inc_id: int = 0
    var select: OptionButton

    func add_to_group() -> void:
        var container = default_add_line()

        select = OptionButton.new()
        select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        select.item_selected.connect(_on_option_button_item_selected)
        container.add_child(select)

        for k in selections:
            add_selection(k, selections[k])

    func add_selection(k: String, v: String) -> void:
        selections[k] = v
        select.add_item(v, inc_id)
        selections_mapping[inc_id] = k
        selections_mapping_reversed[k] = inc_id
        inc_id += 1

    func _on_option_button_item_selected(_index: int) -> void:
        save_setting()

    func display_changed() -> void:
        select.disabled = selections.size() == 0
        var id = select.get_selected_id()
        if id == -1:
            select.text = "Settings_None"
            return
        var key = selections_mapping[id]
        select.text = tr(selections[key])

    func load_setting() -> void:
        var config = get_config()
        var index = selections_mapping_reversed[config] \
                if config in selections_mapping_reversed \
                else -1
        select.select(index)
        display_changed()

    func save_setting() -> void:
        if select.get_selected_id() == -1:
            set_config(null)
            display_changed()
            return
        set_config(selections_mapping[select.get_selected_id()])
        display_changed()

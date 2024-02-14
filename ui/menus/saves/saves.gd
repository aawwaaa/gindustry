extends Window

var save_ui = false:
    set = set_save_ui

var current: SaveMeta = null
var confirm_callable: Callable;
var cancel_callable: Callable;

func load_saves() -> void:
    for button in %SavesList.get_children():
        button.queue_free()
    for name in Saves.saves.keys():
        var button = Button.new()
        button.auto_translate = false
        button.text = name
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.pressed.connect(load_save_info.bind(name))
        %SavesList.add_child(button)
    if not Saves.saves_changed.is_connected(load_saves):
        Saves.saves_changed.connect(load_saves)

func load_save_info(name: String) -> void:
    var save = Saves.saves[name] if name in Saves.saves else null
    if save == null:
        return
    current = save
    %SaveName.text = save.save_name
    %TargetName.text = save.save_name
    %ConfirmButtons.visible = false
    %OptionButtons.visible = true
    for label in %Mods.get_children():
        label.queue_free()
    for mod in save.mods:
        var info = Mods.mod_info_list[mod] if mod in Mods.mod_info_list else null
        var mod_name = info.name if info else mod
        var container = HBoxContainer.new()
        var label = Label.new()
        label.text = mod_name
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        container.add_child(label)
        label = Label.new()
        label.text = save.mods[mod]
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        container.add_child(label)
        %Mods.add_child(container)


func _on_search_text_changed(new_text: String) -> void:
    if new_text == "":
        for child in %SavesList.get_children():
            child.visible = true
        return
    for child in %SavesList.get_children():
        var name = child.text
        child.visible = name.find(new_text) != -1

func wait_for_confirm(callback: Callable, cancel: Callable = func(): pass) -> void:
    cancel_callable = cancel
    confirm_callable = callback
    %ConfirmButtons.visible = true
    %OptionButtons.visible = false

func _on_delete_pressed() -> void:
    if not current: return
    wait_for_confirm(func():
        Saves.delete_save(current.save_name)
        current = null
        %SaveName.text = ""
        for label in %Mods.get_children():
            label.queue_free()
    )

func _on_rename_pressed() -> void:
    if not current: return
    %SaveName.editable = true
    wait_for_confirm(func():
        Saves.rename_save(current.save_name, %SaveName.text)
        current = Saves.saves[%SaveName.text]
        %SaveName.editable = false,
    func():
        %SaveName.editable = false)

func _on_copy_pressed() -> void:
    if not current: return
    %SaveName.editable = true
    wait_for_confirm(func():
        Saves.copy_save(current.save_name, %SaveName.text)
        current = Saves.saves[%SaveName.text]
        %SaveName.editable = false,
    func():
        %SaveName.editable = false)

func _on_cancel_pressed() -> void:
    if cancel_callable:
        cancel_callable.call()
    %ConfirmButtons.visible = false
    %OptionButtons.visible = current != null

func _on_confirm_pressed() -> void:
    if confirm_callable:
        confirm_callable.call()
    %ConfirmButtons.visible = false
    %OptionButtons.visible = current != null

func set_save_ui(v: bool) -> void:
    save_ui = v
    if not v:
        %ForceLoad.visible = true
        %Button.text = tr("Saves_Load")
        return
    %ForceLoad.visible = false
    %Button.text = tr("Saves_Save")
    %TargetName.text = ""

func _on_button_pressed() -> void:
    if save_ui:
        Saves.create_save(%TargetName.text)
        set_save_ui(false)
        hide()
        return
    if not Saves.saves.has(%TargetName.text):
        %AcceptDialog.dialog_text = tr("Saves_SaveNotExist {name}").format({name = %TargetName.text})
        %AcceptDialog.show()
        return
    var result = check_mods()
    if not result:
        %ConfirmationDialog.dialog_text = tr("Saves_NeedRestartForApplyMods")
        %ConfirmationDialog.show()
        return
    Saves.load_save(%TargetName.text)

func _on_force_load_pressed() -> void:
    if not Saves.saves.has(%TargetName.text):
        %AcceptDialog.dialog_text = tr("Saves_SaveNotExist {name}").format({name = %TargetName.text})
        %AcceptDialog.show()
        return
    Saves.load_save(%TargetName.text)

func check_mods() -> bool:
    for mod in Mods.mod_info_list.values():
        if mod.enabled and not current.mods.has(mod.id):
            return false
    for mod in current.mods:
        if not Mods.mod_info_list.has(mod) or not Mods.mod_info_list[mod].enabled:
            return false
    return true

func _on_confirmation_dialog_confirmed() -> void:
    var modifies = {}
    var missings = []
    for mod in Mods.mod_info_list.values():
        if mod.enabled and not current.mods.has(mod.id):
            modifies[mod.id] = mod.enabled
            mod.enabled = false
    for mod in current.mods:
        if not Mods.mod_info_list.has(mod):
            missings.append(mod)
        if not Mods.mod_info_list[mod].enabled:
            modifies[mod] = Mods.mod_info_list[mod].enabled
            Mods.mod_info_list[mod].enabled = true
    if missings.size() != 0:
        for mod in modifies:
            Mods.mod_info_list[mod].enabled = modifies[mod]
        var str = "\n".join(PackedStringArray(missings))
        %AcceptDialog.dialog_text = tr("Saves_FailedToApplyMods_MissingMods") + "\n" + str
        %AcceptDialog.show()
        return
    Mods.save_enable_configs()
    %AcceptDialog.dialog_text = tr("Mods_NeedRestart")
    %AcceptDialog.confirmed.connect(func():
        Headless.restart(["--load-save", %TargetName.text])
    , CONNECT_ONE_SHOT)
    %AcceptDialog.show()

extends Window

var save_ui = false:
    set = set_save_ui

var current: SaveMeta = null
var confirm_callable: Callable;
var cancel_callable: Callable;

func load_saves() -> void:
    for button in %SavesList.get_children():
        button.queue_free()
    for name in Vars.saves.saves.keys():
        var button = Button.new()
        button.auto_translate = false
        button.text = name
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.pressed.connect(load_save_info.bind(name))
        %SavesList.add_child(button)
    if not Vars.saves.saves_changed.is_connected(load_saves):
        Vars.saves.saves_changed.connect(load_saves)

func load_save_info(name: String) -> void:
    var save = Vars.saves.saves[name] if name in Vars.saves.saves else null
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
        var info = Vars.mods.mod_info_list[mod] if mod in Vars.mods.mod_info_list else null
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
        Vars.saves.delete_save(current.save_name)
        current = null
        %SaveName.text = ""
        for label in %Mods.get_children():
            label.queue_free()
    )

func _on_rename_pressed() -> void:
    if not current: return
    %SaveName.editable = true
    wait_for_confirm(func():
        Vars.saves.rename_save(current.save_name, %SaveName.text)
        current = Vars.saves.saves[%SaveName.text]
        %SaveName.editable = false,
    func():
        %SaveName.editable = false)

func _on_copy_pressed() -> void:
    if not current: return
    %SaveName.editable = true
    wait_for_confirm(func():
        Vars.saves.copy_save(current.save_name, %SaveName.text)
        current = Vars.saves.saves[%SaveName.text]
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
        %Button.text = tr("Vars.saves_Load")
        return
    %ForceLoad.visible = false
    %Button.text = tr("Vars.saves_Save")
    %TargetName.text = ""

func _on_button_pressed() -> void:
    if save_ui:
        Vars.saves.create_save(%TargetName.text)
        set_save_ui(false)
        hide()
        return
    if not Vars.saves.saves.has(%TargetName.text):
        %AcceptDialog.dialog_text = tr("Vars.saves_SaveNotExist {name}").format({name = %TargetName.text})
        %AcceptDialog.show()
        return
    var result = check_mods()
    if not result:
        %ConfirmationDialog.dialog_text = tr("Vars.saves_NeedRestartForApplyG.mods")
        %ConfirmationDialog.show()
        return
    Vars.saves.load_save(%TargetName.text)

func _on_force_load_pressed() -> void:
    if not Vars.saves.saves.has(%TargetName.text):
        %AcceptDialog.dialog_text = tr("Vars.saves_SaveNotExist {name}").format({name = %TargetName.text})
        %AcceptDialog.show()
        return
    Vars.saves.load_save(%TargetName.text)

func check_mods() -> bool:
    for mod in Vars.mods.mod_info_list.values():
        if mod.enabled and not current.mods.has(mod.id):
            return false
    for mod in current.mods:
        if not Vars.mods.mod_info_list.has(mod) or not Vars.mods.mod_info_list[mod].enabled:
            return false
    return true

func _on_confirmation_dialog_confirmed() -> void:
    var modifies = {}
    var missings = []
    for mod in Vars.mods.mod_info_list.values():
        if mod.enabled and not current.mods.has(mod.id):
            modifies[mod.id] = mod.enabled
            mod.enabled = false
    for mod in current.mods:
        if not Vars.mods.mod_info_list.has(mod):
            missings.append(mod)
        if not Vars.mods.mod_info_list[mod].enabled:
            modifies[mod] = Vars.mods.mod_info_list[mod].enabled
            Vars.mods.mod_info_list[mod].enabled = true
    if missings.size() != 0:
        for mod in modifies:
            Vars.mods.mod_info_list[mod].enabled = modifies[mod]
        var str = "\n".join(PackedStringArray(missings))
        %AcceptDialog.dialog_text = tr("Vars.saves_FailedToApplyG.mods_MissingG.mods") + "\n" + str
        %AcceptDialog.show()
        return
    Vars.mods.save_enable_configs()
    %AcceptDialog.dialog_text = tr("Vars.mods_NeedRestart")
    %AcceptDialog.confirmed.connect(func():
        Vars.headless.restart(["--load-save", %TargetName.text])
    , CONNECT_ONE_SHOT)
    %AcceptDialog.show()

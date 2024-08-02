extends LayerWindow

var ModLine = preload("res://ui/menus/mods/mod_line.tscn")
var state_changed = false;

func call_alert(message: String, callback: Callable) -> void:
    $Alert.dialog_text = tr(message);
    $Alert.confirmed.connect(callback, CONNECT_ONE_SHOT);
    $Alert.show();

func _on_close_requested() -> void:
    var errors = Vars.mods.check_errors();
    if errors.size() != 0:
        var s = ""
        for error in errors:
            s += error + "\n"
        call_alert(s, func(): 
            pass
        )
        return
    if not state_changed:
        hide();
        return;
    call_alert("Vars.mods_NeedRestart", func():
        hide();
        Vars.mods.save_enable_configs();
        Vars.headless.restart()
    );

func load_mod_list() -> void:
    for line in %ModLines.get_children():
        line.queue_free();
    for mod in Vars.mods.display_order:
        var info = Vars.mods.mod_info_list[mod];
        var line = ModLine.instantiate();
        line.mod_info = info;
        line.toggled.connect(_on_line_toggled);
        line.pressed.connect(_on_line_pressed);
        %ModLines.add_child(line);

func _on_line_toggled(info: ModInfo, enabled: bool) -> void:
    state_changed = true;
    info.enabled = enabled;

func _on_line_pressed(info: ModInfo) -> void:
    %ModDetail.visible = true
    %ModDetail.load_info(info);

func _on_line_edit_text_changed(new_text: String) -> void:
    if new_text == "":
        for line in %ModLines.get_children():
            line.visible = true;
        return;
    for line in %ModLines.get_children():
        line.visible = line.get_node("ModName").text \
            .findn(new_text) != -1


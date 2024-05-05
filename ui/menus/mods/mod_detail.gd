extends VBoxContainer

var mod_line = preload("res://ui/menus/mods/mod_line.tscn")

var mod_info: ModInfo;

func _on_config_button_pressed() -> void:
    var node = await G.mods.mod_inst_list[mod_info.id]._open_configs();
    node.always_on_top = true;
    node.initial_position = Window. \
        WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN;
    node.show();
    get_tree().root.add_child(node);

func _on_follow_repo_link_pressed() -> void:
    OS.shell_show_in_file_manager(mod_info.repo, false)

func load_info(info: ModInfo) -> void:
    self.mod_info = info;
    %ModName.text = mod_info.name;
    %ModDisplayVersion.text = mod_info.display_version;
    %ModID.text = mod_info.id;
    %ModVersion.text = mod_info.version;
    %ConfigButton.disabled = not G.mods.mod_inst_list.has(mod_info.id)
    %ModAuthor.text = mod_info.author;
    %ModIcon.texture = mod_info.icon;
    
    if mod_info.repo != "no_repo":
        %RepoPanel.visible = true;
        %ModRepo.text = mod_info.repo;
    else:
        %RepoPanel.visible = false;
    
    if mod_info.description != "no_description":
        %DescPanel.visible = true;
        %ModDescription.text = mod_info.description;
    else:
        %DescPanel.visible = false;
    
    for child in %ModDepends.get_children():
        child.queue_free();
    for depend in mod_info.depends.keys():
        var line = mod_line.instantiate();
        var versions = mod_info.depends[depend];
        if G.mods.mod_info_list.has(depend):
            line.get_node("ModName").text = G.mods.mod_info_list[depend].name
        else:
            line.get_node("ModName").text =  depend+" "+tr("G.mods_Unsloved")
        line.get_node("ModVersion").text = versions[0] + " ~ " + versions[1] \
            if versions.size() > 1 else versions[0] + " +"
        line.get_node("Button").disabled = not G.mods.mod_info_list.has(depend);
        line.pressed.connect(load_info);
        %ModDepends.add_child(line);
        if G.mods.mod_info_list.has(depend):
            line.mod_info = G.mods.mod_info_list[depend]
        line.get_node("Enabled").queue_free();
        
    for child in %ModExcepts.get_children():
        child.queue_free();
    for except in mod_info.excepts:
        var line = mod_line.instantiate();
        line.get_node("ModName").text = G.mods.mod_info_list[except] \
            if G.mods.mod_info_list.has(except) \
            else except+" "+tr("G.mods_Unsloved")
        line.get_node("ModVersion").text = "*"
        line.get_node("Button").disabled = not G.mods.mod_info_list.has(except);
        line.pressed.connect(load_info);
        %ModExcepts.add_child(line);
        line.get_node("Enabled").queue_free();

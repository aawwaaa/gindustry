class_name Mod
extends Node

signal signal_configs_changed(mod: Mod);

var mod_info: ModInfo;
var mod_configs: ConfigsGroup;

func _init(info: ModInfo) -> void:
    self.mod_info = info;

# _init -> init/load configs -> init -> load_contents -> end

func _mod_init() -> void:
    pass

func _load_contents() -> void:
    pass

func load_configs(stream: Stream) -> Error:
    mod_configs = ConfigsGroup.new()
    return mod_configs.load_from(stream);

func init_configs() -> void:
    mod_configs = ConfigsGroup.new()

func save_configs(stream: Stream) -> void:
    mod_configs.save_configs(stream)

func configs_changed() -> void:
    signal_configs_changed.emit(self);

func _open_configs() -> Window:
    var window = AcceptDialog.new();
    window.title = "";
    window.dialog_text = "Mods_NoConfigs"
    return window;

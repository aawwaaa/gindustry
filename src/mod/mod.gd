class_name Mod
extends Node

signal signal_configs_changed(mod: Mod);

var mod_info: ModInfo;
var mod_configs: ConfigsGroup;

var root: String:
    get: return mod_info.root

var contents: Array[Content] = [];
var types: Array[ResourceType] = [];

func _init(info: ModInfo) -> void:
    self.mod_info = info;

## When mod is instanced, this function will be called first
## Before config loading
## In stage of init
func _mod_init() -> void:
    pass

## After _mod_init and config loading
## In stage of init
func _init_contents() -> void:
    pass

## After _init_contents, in stage of load contents
func _load_contents() -> void:
    pass

func _load_assets() -> void:
    pass
func _load_headless() -> void:
    pass

## After _load_contents, in stage of post
func _post() -> void:
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

func get_files(path: String) -> Array[String]:
    path = to_absolute(path)
    var arr: Array[String] = []
    var access = DirAccess.open(path)
    if not access:
        return arr
    access.list_dir_begin()
    var file_name = access.get_next()
    while file_name != "":
        var file = to_relative(path + "/" + file_name)
        if access.current_is_dir():
            arr += get_files(file)
        else:
            arr.append(file)
        file_name = access.get_next()
    access.list_dir_end()
    return arr

func to_absolute(path: String) -> String:
    return root + path

func to_relative(path: String) -> String:
    if path.begins_with(root):
        return path.substr(root.length())
    return path

func load_relative(path: String) -> Resource:
    return load(to_absolute(path))

func _open_configs() -> Window:
    var window = AcceptDialog.new();
    window.title = "";
    window.dialog_text = "Mods_NoConfigs"
    return window;

class_name ModInfo
extends Resource

@export var id: String;
@export var name: String = "unnamed";
@export var description: String = "no_description";
@export var author: String = "unknown";
@export var repo: String = "no_repo";
@export var version: String = "1.0.0";
@export var display_version: String = "unmarked";

# {"id": [min, max?]}
@export var depends: Dictionary = {};
@export var excepts: Array = [];

@export var icon: Texture2D = preload("res://assets/asset-not-found.png");
@export var main: String = "scripts/main.gd";

var enabled: bool = false;
var file_path: String = "";

static func load_from_file(path: String) -> ModInfo:
    var reader = ZIPReader.new();
    if reader.open(path) != OK:
        reader.close();
        return null;
    if not reader.file_exists("info.json"):
        reader.close();
        return null;
    var info_data = reader.read_file("info.json");
    var info_dict: Dictionary = JSON.parse_string(info_data);
    var info = parse_info_dict(info_dict);
    if info and info_dict.has("icon") and info_dict.has("iconType"):
        var icon_data = reader.read_file(info_dict["icon"]);
        info.icon = Utils.parse_image_data(icon_data, info_dict["iconType"]);
    reader.close();
    info.file_path = path;
    return info;
    
static func load_from_folder(path: String) -> ModInfo:
    if not FileAccess.file_exists(path+"/info.json"):
        return null;
    var info_access = FileAccess.open(path+"/info.json", FileAccess.READ);
    var info_data = info_access.get_as_text();
    info_access.close();
    var info_dict: Dictionary = JSON.parse_string(info_data);
    var info = parse_info_dict(info_dict);
    if info and info_dict.has("icon") and info_dict.has("iconType"):
        var full = path + "/" + info_dict["icon"];
        var texture = load(full) if path.begins_with("res://") \
            else ImageTexture.create_from_image(Image.load_from_file(full));
        info.icon = texture;
    return info;

static func parse_info_dict(dict: Dictionary) -> ModInfo:
    if not dict.has("id"):
        return null;
    var info = ModInfo.new();
    info.id = dict["id"];
    if dict.has("name"):
        info.name = dict["name"];
    else:
        info.name = info.id;
    if dict.has("description"):
        info.description = dict["description"];
    if dict.has("author"):
        info.author = dict["author"];
    if dict.has("repo"):
        info.repo = dict["repo"];
    if dict.has("version"):
        info.version = dict["version"];
    if dict.has("displayVersion"):
        info.display_version = dict["displayVersion"];
    if dict.has("depends"):
        info.depends = dict["depends"];
    if dict.has("excepts"):
        info.excepts = dict["excepts"];
    if dict.has("main"):
        info.main = dict["main"];
    return info;

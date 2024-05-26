class_name ConfigsGroup
extends Resource

class ConfigKey extends Object:
    var name: String
    var default_value: Variant

    func _init(n: String, dv: Variant):
        name = n
        default_value = dv

var dict: Dictionary
var defaults: Dictionary = {}

static func load_from(stream: Stream):
    var group = ConfigsGroup.new();
    group.init_configs();
    group.load_configs(stream);
    return group;

func load_configs(stream: Stream):
    var size = stream.get_32();
    for _1 in range(size):
        var key = stream.get_string();
        dict[key] = stream.get_var();

func save_configs(stream: Stream):
    stream.store_32(dict.size())
    for key in dict.keys():
        stream.store_string(key);
        stream.store_var(dict[key], true);

func init_configs():
    dict = {}

func copy():
    var new_inst = ConfigsGroup.new();
    new_inst.dict = dict.duplicate(false);
    return new_inst;

func g(key: String, default_value: Variant = defaults[key] if defaults.has(key) else null) -> Variant:
    if not dict.has(key):
        dict[key] = default_value;
    return dict[key];

func k(key: ConfigKey) -> Variant:
    return g(key.name, key.default_value)

func p(key: String, value: Variant) -> void:
    dict[key] = value;

func set_defaults(defs: Dictionary) -> void:
    self.defaults.merge(defs)

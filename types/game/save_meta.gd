class_name SaveMeta
extends RefCounted

var file_path: String;

var save_meta_version: int = current_save_meta_version;
var save_name: String = "unnamed";
var mods: Dictionary = {};

static var current_save_meta_version: int = 1;

static func load_from(stream: Stream) -> SaveMeta:
    var meta = SaveMeta.new();
    meta.save_meta_version = stream.get_16();
    # version 0
    if meta.save_meta_version < 0: return meta;
    var name_buffer = stream.get_buffer(128)
    var name = name_buffer.decode_var(0, false)
    meta.save_name = name
    # version 1
    if meta.save_meta_version < 1: return meta;
    meta.mods = stream.get_var();
    return meta;

static func change_name(stream: Stream, new_name: String) -> void:
    stream.get_16();
    var name_buffer = PackedByteArray()
    name_buffer.resize(128)
    name_buffer.encode_var(0, new_name, false)
    stream.store_buffer(name_buffer)

func save_to(stream: Stream) -> void:
    stream.store_16(current_save_meta_version);
    # version 0
    var name_buffer = PackedByteArray()
    name_buffer.resize(128)
    name_buffer.encode_var(0, save_name, false)
    stream.store_buffer(name_buffer)
    # version 1
    mods = {}
    for mod in Vars.mods.mod_inst_list.values():
        mods[mod.mod_info.id] = mod.mod_info.version
    stream.store_var(mods, true)

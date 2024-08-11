class_name SaveMeta
extends RefCounted

var file_path: String;

var save_meta_version: int = current_save_meta_version;
var save_name: String = "unnamed";
var mods: Dictionary = {};

static var current_save_meta_version: int = 1;

func apply_current_mods() -> void:
    for mod in Vars.mods.mod_inst_list.values():
        mods[mod.mod_info.id] = mod.mod_info.version

func load_from(stream: Stream) -> Error:
    save_meta_version = stream.get_16();
    if stream.get_error(): return stream.get_error();
    # version 0
    if save_meta_version < 0: return OK;
    var name_length = stream.get_16()
    if stream.get_error(): return stream.get_error();
    var name_buffer = stream.get_buffer(128)
    if stream.get_error(): return stream.get_error();
    var name = name_buffer.slice(0, name_length).get_string_from_utf8()
    save_name = name
    # version 1
    if save_meta_version < 1: return OK;
    var size = stream.get_32();
    if stream.get_error(): return stream.get_error();
    for _1 in size:
        var mod_id = stream.get_string();
        if stream.get_error(): return stream.get_error();
        var mod_version = stream.get_string();
        if stream.get_error(): return stream.get_error();
        mods[mod_id] = mod_version
    return OK

static func change_name(stream: Stream, new_name: String) -> Error:
    stream.get_16();
    if stream.get_error(): return stream.get_error();
    stream.store_16(new_name.length())
    if stream.get_error(): return stream.get_error();
    var name_buffer = new_name.to_utf8_buffer()
    name_buffer.resize(128)
    stream.store_buffer(name_buffer)
    if stream.get_error(): return stream.get_error();
    return OK

func save_to(stream: Stream) -> void:
    stream.store_16(current_save_meta_version);
    # version 0
    stream.store_16(save_name.length())
    var name_buffer = save_name.to_utf8_buffer()
    name_buffer.resize(128)
    stream.store_buffer(name_buffer)
    # version 1
    var values = Vars.mods.mod_inst_list.values()
    stream.store_32(values.size())
    for mod in values:
        stream.store_string(mod.mod_info.id)
        stream.store_string(mod.mod_info.version)

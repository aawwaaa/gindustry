extends Node

signal saves_changed()

var log_source: Log.Logger

var saves: Dictionary = {}

var save_head = "GSAV".to_ascii_buffer()

func _ready() -> void:
    log_source = Log.register_log_source("Saves_LogSource");

func search_save_folder(path: String, dict: Dictionary = saves) -> void:
    var dir_access = DirAccess.open(path);
    if not dir_access:
        log_source.warn(tr("Saves_SearchFailed {directory}") \
                .format({directory = path}))
        return;
    var count = 0;
    var progress = Log.register_progress_source(5)
    dir_access.list_dir_begin()
    var dir_name = dir_access.get_next()
    while dir_name != "":
        var file = path + dir_name
        if dir_access.current_is_dir():
            # dict[dir_name] = {}
            # search_save_folder(file + "/", dict)
            continue
        var access = FileAccess.open(file, FileAccess.READ)
        var stream = FileStream.new(access)
        var buffer = stream.get_buffer(save_head.size())
        if buffer != save_head:
            log_source.error(tr("Saves_InvalidSaveFile {name}").format({name = name}))
            access.close()
            dir_name = dir_access.get_next()
            continue 
        var info = SaveMeta.load_from(stream)
        info.file_path = file
        dict[info.save_name] = info
        access.close()
        count += 1
        dir_name = dir_access.get_next()
    progress.call(5)
    log_source.info(tr_n("Saves_FoundSaves {dictionary} {amount}", "Saves_FoundSaves_plural {dictionary} {amount}", count) \
            .format({dictionary = path, amount = count}))
    saves_changed.emit()

func load_saves() -> void:
    search_save_folder("user://saves/")

func create_save(name: String) -> void:
    log_source.info(tr("Saves_CreateSave {name}").format({name = name}))
    var path = "user://saves/"+name+".gsav"
    var access = FileAccess.open(path, FileAccess.WRITE)
    var stream = FileStream.new(access)
    var buffer = PackedByteArray()
    buffer.resize(save_head.size())
    stream.store_buffer(buffer)
    Game.save_meta.save_name = name
    Game.save_meta.file_path = path
    Game.save_game(stream)
    access.seek(0)
    stream.store_buffer(save_head)
    access.close()
    saves[name] = Game.save_meta
    saves_changed.emit()

func load_save(name: String) -> void:
    log_source.info(tr("Saves_LoadSave {name}").format({name = name}))
    var meta = saves[name]
    var access = FileAccess.open(meta.file_path, FileAccess.READ)
    var stream = FileStream.new(access)
    var buffer = stream.get_buffer(save_head.size())
    if buffer != save_head:
        log_source.error(tr("Saves_InvalidSaveFile {name}").format({name = name}))
        access.close()
        return
    Game.load_game(stream)
    access.close()
    var player = Multiplayer.join_local()

func delete_save(name: String) -> void:
    log_source.info(tr("Saves_DeleteSave {name}").format({name = name}))
    var info = saves[name]
    DirAccess.remove_absolute(info.file_path)
    saves.erase(name)
    saves_changed.emit()

func rename_save(name: String, new_name: String) -> void:
    log_source.info(tr("Saves_RenameSave {name} {new_name}").format({name = name, new_name = new_name}))
    var info = saves[name]
    var new_path = "user://saves/"+new_name+".gsav"
    DirAccess.rename_absolute(info.file_path, new_path)
    var access = FileAccess.open(new_path, FileAccess.READ_WRITE)
    var stream = FileStream.new(access)
    stream.seek(save_head.size())
    SaveMeta.change_name(stream, new_name)
    access.seek(0)
    stream.seek(save_head.size())
    saves[new_name] = SaveMeta.load_from(stream)
    saves[new_name].file_path = new_path
    saves.erase(name)
    access.close()
    saves_changed.emit()

func copy_save(name: String, new_name: String) -> void:
    log_source.info(tr("Saves_CopySave {name} {new_name}").format({name = name, new_name = new_name}))
    var info = saves[name]
    var new_path = "user://saves/"+new_name+".gsav"
    DirAccess.copy_absolute(info.file_path, new_path)
    var new_access = FileAccess.open(new_path, FileAccess.READ_WRITE)
    var stream = FileStream.new(new_access)
    stream.seek(save_head.size())
    SaveMeta.change_name(stream, new_name)
    new_access.seek(0)
    stream.seek(save_head.size())
    saves[new_name] = SaveMeta.load_from(stream)
    saves[new_name].file_path = new_path
    new_access.close()
    saves_changed.emit()

class_name Vars_Saves
extends Vars.Vars_Object

signal saves_changed()

var logger: Log.Logger = Log.register_logger("Saves_LogSource");

var saves: Dictionary = {}

var save_head = "GSAV".to_ascii_buffer()

func search_save_folder(path: String, dict: Dictionary = saves) -> void:
    var dir_access = DirAccess.open(path);
    if not dir_access:
        logger.warn(tr("Saves_SearchFailed {directory}") \
                .format({directory = path}))
        return;
    var count = 0;
    var progress = Log.register_progress_tracker(5, \
            tr("Saves_SearchSaves {directory}").format({directory = path}), \
            logger.source)
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
            logger.error(tr("Saves_InvalidSaveFile {name}").format({name = file}))
            access.close()
            dir_name = dir_access.get_next()
            continue 
        var info = SaveMeta.new()
        var err = info.load_from(stream)
        if err:
            logger.error(tr("Saves_InvalidSaveFile {name}").format({name = file}))
            access.close()
            dir_name = dir_access.get_next()
            continue
        info.file_path = file
        dict[info.save_name] = info
        access.close()
        count += 1
        dir_name = dir_access.get_next()
    logger.info(tr_n("Saves_FoundSaves {dictionary} {amount}", "Saves_FoundSaves_plural {dictionary} {amount}", count) \
            .format({dictionary = path, amount = count}))
    progress.finish()
    saves_changed.emit()

func load_saves() -> void:
    search_save_folder("user://saves/")

func create_save(save_name: String) -> Error:
    logger.info(tr("Saves_CreateSave {name}").format({name = save_name}))
    var path = "user://saves/"+save_name+".gsav"
    var access = FileAccess.open(path, FileAccess.WRITE)
    var stream = FileStream.new(access)
    var buffer = PackedByteArray()
    buffer.resize(save_head.size())
    stream.store_buffer(buffer)
    if stream.get_error():
        access.close()
        return stream.get_error()
    Vars.game.save_meta.save_name = save_name
    Vars.game.save_meta.file_path = path
    Vars.game.save_game(stream) # TODO error
    access.seek(0)
    stream.store_buffer(save_head)
    access.close()
    saves[save_name] = Vars.game.save_meta
    saves_changed.emit()
    return OK

func load_save(save_name: String) -> Error:
    logger.info(tr("Saves_LoadSave {name}").format({name = save_name}))
    if not saves.has(save_name): return ERR_FILE_NOT_FOUND
    var meta = saves[save_name]
    var access = FileAccess.open(meta.file_path, FileAccess.READ)
    var stream = FileStream.new(access)
    var buffer = stream.get_buffer(save_head.size())
    if buffer != save_head:
        logger.error(tr("Saves_InvalidSaveFile {name}").format({name = save_name}))
        access.close()
        return ERR_FILE_CORRUPT
    var err = Vars.game.load_game(stream)
    if err:
        logger.error(tr("Saves_InvalidSaveFile {name}").format({name = save_name}))
        access.close()
        return err
    access.close()
    Vars.game.make_ready_game()
    var _player = Vars.client.join_local()
    Vars.game.enter_game()
    Vars.game.save_preset._after_ready()
    return OK

func delete_save(save_name: String) -> Error:
    logger.info(tr("Saves_DeleteSave {name}").format({name = save_name}))
    if not saves.has(save_name): return ERR_FILE_NOT_FOUND
    var info = saves[save_name]
    var err = DirAccess.remove_absolute(info.file_path)
    if err: return err
    saves.erase(save_name)
    saves_changed.emit()
    return OK

func rename_save(save_name: String, new_name: String) -> Error:
    logger.info(tr("Saves_RenameSave {name} {new_name}").format({name = save_name, new_name = new_name}))
    if not saves.has(save_name): return ERR_FILE_NOT_FOUND
    var info = saves[save_name]
    var new_path = "user://saves/"+new_name+".gsav"
    var err = DirAccess.rename_absolute(info.file_path, new_path)
    if err: return err
    var access = FileAccess.open(new_path, FileAccess.READ_WRITE)
    var stream = FileStream.new(access)
    stream.seek(save_head.size())
    if stream.get_error():
        err = stream.get_error()
        access.close()
        return err
    err = SaveMeta.change_name(stream, new_name)
    if err:
        access.close()
        return err
    access.seek(0)
    stream.seek(save_head.size())
    if stream.get_error():
        err = stream.get_error()
        access.close()
        return err
    saves[new_name] = SaveMeta.new()
    err = saves[new_name].load_from(stream)
    if err:
        access.seek(0)
        stream.seek(save_head.size())
        SaveMeta.change_name(stream, save_name)
        access.close()
        saves.erase(new_name)
        return err
    saves[new_name].file_path = new_path
    saves.erase(save_name)
    access.close()
    saves_changed.emit()
    return OK

func copy_save(save_name: String, new_name: String) -> Error:
    logger.info(tr("Saves_CopySave {name} {new_name}").format({name = name, new_name = new_name}))
    if not saves.has(save_name): return ERR_FILE_NOT_FOUND
    var info = saves[save_name]
    var new_path = "user://saves/"+new_name+".gsav"
    var err = DirAccess.copy_absolute(info.file_path, new_path)
    if err: return err
    var new_access = FileAccess.open(new_path, FileAccess.READ_WRITE)
    var stream = FileStream.new(new_access)
    stream.seek(save_head.size())
    SaveMeta.change_name(stream, new_name)
    new_access.seek(0)
    stream.seek(save_head.size())
    saves[new_name] = SaveMeta.new()
    err = saves[new_name].load_from(stream)
    if err:
        new_access.close()
        saves.erase(new_name)
        DirAccess.remove_absolute(new_path)
        return err
    saves[new_name].file_path = new_path
    new_access.close()
    saves_changed.emit()
    return OK

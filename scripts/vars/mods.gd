class_name Vars_Mods
extends Vars.Vars_Object

var logger = Log.register_logger("Mods_LogSource");

var mod_info_list: Dictionary = {}
var mod_inst_list: Dictionary = {}

func search_mod_folder(path: String, ignore_folder: bool = true) -> void:
    var dir_access = DirAccess.open(path);
    if not dir_access:
        logger.error(tr("Mods_SearchFailed {directory}") \
            .format({directory = path}))
        return;    
    var progress = Log.register_progress_tracker(5, \
            tr("Mods_SearchMods {directory}").format({directory = path}), \
            logger.source);
    var count = 0;
    dir_access.list_dir_begin();
    var dir_name = dir_access.get_next();
    while dir_name != "":
        dir_name = path + dir_name;
        if dir_access.current_is_dir():
            if ignore_folder:
                logger.warn(tr("Mods_FolderNotSupported {path}") \
                        .format({path = dir_name}))
            else:
                var info = ModInfo.load_from_folder(dir_name)
                count += found_mod(info, dir_name);
        else:
            var info = ModInfo.load_from_file(dir_name);
            count += found_mod(info, dir_name);
        dir_name = dir_access.get_next();
    dir_access.list_dir_end();
    logger.info(tr_n("Mods_SearchSuccess {directory} {amount}", \
            "Mods_SearchSuccess_plural {directory} {amount}", count) \
            .format({directory = path, amount = count}))
    progress.finish()

func found_mod(info: ModInfo, path: String) -> int:
    if not info:
        logger.warn(tr("Mods_NotAMod {path}") \
                .format({path = path}))
        return 0;
    mod_info_list[info.id] = info;
    return 1;

func init_configs() -> void:
    if not DirAccess.dir_exists_absolute("user://mod-configs/"):
        DirAccess.make_dir_absolute("user://mod-configs/");

func load_enable_configs() -> void:
    if not FileAccess.file_exists("user://mod-enable-config.bin"):
        for info in mod_info_list.values():
            info.enabled = true;
        logger.warn(tr("Mods_EnableConfigsNotFound"))
        save_enable_configs()
        return
    logger.info(tr("Mods_LoadEnableConfigs"))
    var progress = Log.register_progress_tracker(5, "Mods_LoadEnableConfigs", logger.source);
    var access = FileAccess.open("user://mod-enable-config.bin", \
            FileAccess.READ);
    var founded = [];
    while not access.eof_reached():
        var mod_name = access.get_pascal_string();
        var enabled = true if access.get_8() else false;
        if mod_info_list.has(mod_name):
            mod_info_list[mod_name].enabled = enabled;
        founded.append(mod_name);
    var has_foreign = false;
    for info in mod_info_list.values():
        if founded.find(info.id) != -1:
            continue;
        info.enabled = true;
        logger.info(tr("Mods_FoundNewModEnabled {id} {name}") \
                .format({id = info.id, name = info.name}))
        has_foreign = true;
    access.close();
    if has_foreign:
        save_enable_configs()
    progress.finish()

func save_enable_configs() -> void:
    logger.info(tr("Mods_SaveEnableConfigs"))
    var access = FileAccess.open("user://mod-enable-config.bin", \
            FileAccess.WRITE);
    for info in mod_info_list.values():
        access.store_pascal_string(info.id);
        access.store_8(1 if info.enabled else 0);
    access.close();

func load_mod_configs(mod: Mod) -> void:
    var path = "user://mod-configs/" + mod.mod_info.id + ".bin"
    if not FileAccess.file_exists(path):
        logger.warn(tr("Mods_ModConfigsNotFound {id} {name}") \
                .format({id = mod.mod_info.id, name = mod.mod_info.name}));
        mod.init_configs();
        return;
    logger.info(("Mods_LoadModConfigs {id} {name}") \
            .format({id = mod.mod_info.id, name = mod.mod_info.name}));
    var access = FileAccess.open(path, FileAccess.READ);
    var stream = FileStream.new(access)
    @warning_ignore("redundant_await")
    await mod.load_configs(stream);
    access.close()

func save_mod_configs(mod: Mod) -> void:
    logger.info(("Mods_SaveModConfigs {id} {name}") \
            .format({id = mod.mod_info.id, name = mod.mod_info.name}));
    var path = "user://mod-configs/" + mod.mod_info.id + ".bin"
    var access = FileAccess.open(path, FileAccess.WRITE)
    var stream = FileStream.new(access)
    @warning_ignore("redundant_await")
    await mod.save_configs(stream)
    access.close()

func check_errors() -> Array:
    var errors = [];
    for info in mod_info_list.values():
        if not info.enabled:
            continue;
        for depend in info.depends.keys():
            var versions = info.depends[depend];
            if not mod_info_list.has(depend):
                errors.append("---"+info.name+"---")
                errors.append(tr("Mods_MissingDepends {id}") \
                        .format({id = depend}))
                continue;
            var depend_info = mod_info_list[depend];
            var min_version_matched = Utils.compare_version_string_ge( \
                    depend_info.version, versions[0]);
            var max_version_matched = versions.size() < 2 or not \
                    Utils.compare_version_string_ge(depend_info.version, \
                    versions[1])
            var matched = min_version_matched and max_version_matched;
            if not matched:
                var format_data = {id = depend, name = depend_info.name,
                    versionRange = versions[0] + " ~ "+ versions[1] \
                            if versions.size() > 1 else versions[0] + " +", 
                    currentVersion = depend_info.version};
                errors.append("---"+info.name+"---")
                errors.append(tr("Mods_DependsVersionMismatch {id}" \
                            + "{name} {versionRange} {currentVersion}") \
                        .format(format_data))
                continue;
            if not depend_info.enabled:
                errors.append("---"+info.name+"---")
                errors.append(tr("Mods_DependsNotEnabled {id} {name}") \
                        .format({id = depend, name = depend_info.name}));
                continue;
        var index = errors.size() - 1
        var detected = false
        for except in info.excepts:
            if mod_info_list.has(except) and mod_info_list[except].enabled:
                errors.append(tr("Mods_DetectedExcepts {id} {name}") \
                        .format({id = except, name = mod_info_list[except].name}));
                detected = true
        if detected:
            errors.insert(index, "---"+info.name+"---")
    return errors;

class __LoadListFinder:
    var depends_queue: Dictionary;
    var load_list: Array[String];
    
    func get_slove(list: Array[ModInfo]) -> Array[String]:
        depends_queue = {};
        load_list = []
        for info in list:
            var depends_loaded = true;
            for depend in info.depends.keys():
                if not load_list.has(depend):
                    depends_loaded = false;
                    if not depends_queue.has(depend):
                        depends_queue[depend] = [];
                    depends_queue[depend].append(info);
            if not depends_loaded: continue
            append(info)
        return load_list;
    
    func append(info: ModInfo) -> void:
        load_list.append(info.id);
        if depends_queue.has(info.id):
            for target_info in depends_queue[info.id]:
                var depends_loaded = true;
                for depend in target_info.depends.keys():
                    if not load_list.has(depend):
                        depends_loaded = false;
                        break;
                if not depends_loaded:
                    continue;
                append(target_info);

var __load_list_finder = __LoadListFinder.new();

var display_order: Array[String];

func load_mods() -> void:
    var enabled_list: Array[ModInfo] = []
    var disabled_list: Array[ModInfo] = []
    for info in mod_info_list.values():
        if info.enabled:
            enabled_list.append(info)
        else: disabled_list.append(info)
    var progress = Log.register_progress_tracker(100 * enabled_list.size(), "Mods_Load", logger.source)
    var load_list = __load_list_finder.get_slove(enabled_list);
    display_order = load_list
    disabled_list.sort_custom(func(a, b): return a.id < b.id);
    for info in disabled_list:
        display_order.append(info.id)
    for id in load_list:
        var info = mod_info_list[id];
        if info.main == "":
            progress.progress += 100
            continue
        progress.name = tr("Mods_Load_LoadResources {id} {name}") \
                .format({id = info.id, name = info.name});
        logger.info(progress.name)
        if info.file_path != "":
            ProjectSettings.load_resource_pack(info.file_path);
        progress.progress += 30
        var Main = load(info.main)
        var mod = Main.new(info);
        Vars.contents.current_loading_mod = mod;
        mod_inst_list[info.id] = mod;
        await load_mod_configs(mod);
        progress.progress += 15
        progress.name = tr("Mods_Load_Initialize {id} {name}") \
                .format({id = info.id, name = info.name});
        logger.info(progress.name)
        mod._mod_init();
        progress.progress += 25
        progress.name = tr("Mods_Load_LoadContents {id} {name}") \
                .format({id = info.id, name = info.name});
        logger.info(progress.name)
        await mod._load_contents();
        progress.progress += 30
    logger.info(tr_n("Mods_Load_LoadComplete {amount}", \
            "Mods_Load_LoadComplete_plural {amount}", load_list.size()) \
            .format({amount = load_list.size()}))
    progress.finish()

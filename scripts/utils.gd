extends Node

func parse_image_data(data: PackedByteArray, type: String) -> ImageTexture:
    var image = Image.new();
    match type:
        "jpg":
            image.load_jpg_from_buffer(data);
        "ktx":
            image.load_ktx_from_buffer(data);
        "png":
            image.load_png_from_buffer(data);
        "svg":
            image.load_svg_from_buffer(data);
        "tga":
            image.load_tga_from_buffer(data);
        "webp":
            image.load_webp_from_buffer(data);
        "bmp":
            image.load_bmp_from_buffer(data);
    return ImageTexture.create_from_image(image);

func compare_version_string_ge(v1: String, v2: String, use_gt = false) -> bool:
    var split1 = Array(v1.split("."))
    var split2 = Array(v2.split("."))
    while split1.size() != 0 && split2.size() != 0:
        var a1 = split1.pop_front().split("-")[0];
        var a2 = split2.pop_front().split("-")[0];
        if not use_gt and int(a1) >= int(a2) or use_gt and int(a1) > int(a2):
            return true;
    return false;

var loader_log_source;

func load_contents_async(header: String, contents_input: Array[String]) -> Array:
    if not loader_log_source:
        loader_log_source = Log.register_log_source(tr("Loader_LogSource"));
    var contents = contents_input.map(func(x): return header + x)
    var progress = Log.register_progress_source(1 * contents.size())
    var output = [];
    var removes = [];
    for content in contents:
        var error = ResourceLoader.load_threaded_request(content, "", true)
        if error:
            loader_log_source.error(tr("Loader_LoadFailed {path}") \
                .format({path = content}))
            removes.append(content);
            progress.call(1)
    while contents.size() != 0:
        for content in contents:
            var status = ResourceLoader.load_threaded_get_status(content)
            match status:
                ResourceLoader.ThreadLoadStatus.THREAD_LOAD_INVALID_RESOURCE:
                    loader_log_source.error(tr("Loader_LoadFailed {path}") \
                        .format({path = content}))
                    removes.append(content);
                    progress.call(1)
                ResourceLoader.ThreadLoadStatus.THREAD_LOAD_FAILED:
                    loader_log_source.error(tr("Loader_LoadFailed {path}") \
                        .format({path = content}))
                    ResourceLoader.load_threaded_get(content)
                    removes.append(content);
                    progress.call(1)
                ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
                    output.append(ResourceLoader.load_threaded_get(content))
                    removes.append(content);
                    progress.call(1)
        for content in removes:
            contents.remove_at(contents.find(content));
        removes = [];
        await get_tree().create_timer(0.001).timeout
    return output

func merge_translations(translation: Translation):
    var main_translation = TranslationServer.get_translation_object(translation.locale)
    for message in translation.get_message_list():
        main_translation.add_message(message, translation.get_message(message))

var token_strings = "23456789abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ"
func generate_token() -> String:
    var token = ""
    for _1 in range(32):
        token += token_strings[randi_range(0, token_strings.length() - 1)]
    return token;

func signal_dynamic_connect(obj: Object, from: Object, signal_name: StringName, callable: Callable):
    if from and from.is_connected(signal_name, callable):
        from.disconnect(signal_name, callable)
    if obj:
        obj.connect(signal_name, callable)

func load_data_with_version(stream: Stream, loaders: Array[Callable] = []) -> void:
    var version = stream.get_16();
    for loader in loaders:
        loader.call()

func save_data_with_version(stream: Stream, savers: Array[Callable] = []) -> void:
    stream.store_16(savers.size())
    for saver in savers:
        saver.call()

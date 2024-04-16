class_name AdapterConfig
extends Node

func _init(_invaild_constructor: AdapterConfig) -> void:
    push_error("Invalid constructor")

static var config_handlers: Dictionary = {}

"""
1. 传入名称和适配器生成配置
2. 传入名称适配器+配置解析配置
3. 传入配置进行序列化
"""

class ConfigHandler extends RefCounted:
    const UNAPPLICATABLE = -1
    const UNCONVERTABLE = -1

    func _get_type() -> String:
        return ""
    func get_type() -> String:
        return _get_type()

    func _get_applicatablity(type: String, config: Variant) -> int:
        return UNAPPLICATABLE
    func get_applicatablity(type: String, config: Variant) -> int:
        return _get_applicatablity(type, config)

    func _get_convertablity(target: String, config: Variant) -> int:
        return UNCONVERTABLE
    func get_convertablity(target: String, config: Variant) -> int:
        return _get_convertablity(target, config)

    func _convert(target: String, config: Variant) -> Variant:
        return null
    func convert(target: String, config: Variant) -> Variant:
        return _convert(target, config)

    func _generate_config(adapter: EntityAdapter) -> Variant:
        return null
    func generate_config(adapter: EntityAdapter, target: Dictionary):
        target[get_type()] = _generate_config(adapter)

    func call_with_config(source: Dictionary, target: Callable, args: Array) -> bool:
        var type = get_type()
        if type in source:
            var new_args = [source[type], type]
            new_args.append_array(args)
            target.callv(new_args)
            return true
        var max_applicatable = 0
        for t in source:
            var applicatablity = get_applicatablity(t, source[t])
            if applicatablity == UNAPPLICATABLE: continue
            if applicatablity < max_applicatable: continue
            max_applicatable = applicatablity
            type = t
        if type != get_type():
            var new_args = [source[type], type]
            new_args.append_array(args)
            target.callv(new_args)
            return true
        var max_convertablity = 0
        for t in source:
            var convertablity = AdapterConfig.config_handlers[t] \
                    .get_convertablity(get_type(), source[t])
            if convertablity == UNAPPLICATABLE: continue
            if convertablity < max_convertablity: continue
            max_convertablity = convertablity
            type = t
        if type != get_type():
            var converted = AdapterConfig.config_handlers[type] \
                    .convert(get_type(), source[type])
            var new_args = [converted, get_type()]
            new_args.append_array(args)
            target.callv(new_args)
            return true
        return false

    func _apply_config(config: Variant, type: String, adapter: EntityAdapter) -> void:
        pass
    func apply_config(adapter: EntityAdapter, source: Dictionary) -> void:
        call_with_config(source, _apply_config, [adapter])

    func _apply_shadow(config: Variant, type: String, targets: Dictionary) -> void:
        pass
    func apply_shadow(targets: Dictionary, source: Dictionary) -> void:
        call_with_config(source, _apply_config, [targets])

    func _save_data(config: Variant, stream: Stream) -> void:
        pass

    # TODO save_data load_data

# TODO static funcs


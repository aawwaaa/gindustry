class_name AdapterConfig
extends Node

func _init(_invaild_constructor: AdapterConfig) -> void:
    push_error("Invalid constructor")

"""
1. 传入名称和适配器生成配置
2. 传入名称适配器+配置解析配置
3. 传入配置进行序列化
"""

class ConfigMeta extends RefCounted:
    const UNAPPLICATABLE = -1

    func _get_type() -> String:
        return ""
    func get_type() -> String:
        return _get_type()

    func _get_applicatablity(type: String, config: Variant) -> int:
        return UNAPPLICATABLE
    func get_applicatablity(type: String, config: Variant) -> int:
        return _get_applicatablity(type, config)

    func _generate_config(adapter: EntityAdapter) -> Variant:
        return null
    func generate_config(adapter: EntityAdapter, target: Dictionary):
        target[get_type()] = _generate_config(adapter)

    func _apply_config(adapter: EntityAdapter, config: Variant, type: String) -> void:
        pass
    func apply_config(adapter: EntityAdapter, source: Dictionary) -> void:
        var type = get_type()
        if type in source:
            _apply_config(adapter, source[type], type)
        var max_applicatable = 0
        for t in source:
            var applicatablity = get_applicatablity(t, source[t])
            if applicatablity == UNAPPLICATABLE: continue
            if applicatablity < max_applicatable: continue
            max_applicatable = applicatablity
            type = t
        if type == get_type(): return
        _apply_config(adapter, source[type], type)

    # TODO save_data load_data

# TODO static funcs


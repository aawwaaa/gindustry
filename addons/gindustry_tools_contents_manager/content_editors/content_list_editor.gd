extends GindustryTools_ContentsManager_ContentEditor

func _show_editor() -> void:
    super._show_editor()

func _hide_editor() -> void:
    super._hide_editor()

func _load_content(content: Variant) -> void:
    super._load_content(content)

func _clean_up() -> void:
    super._clean_up()

func _applicatable(content: Variant) -> bool:
    return content is GindustryTools_ContentsManager_ContentsTree

func _add_element_for(content: Variant) -> void:
    pass
